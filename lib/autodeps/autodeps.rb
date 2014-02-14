require 'logger'
module Autodeps
  class << self
    attr_accessor :logger
  end
  self.logger = Logger.new(STDOUT)
  @pending_computations = ThreadSafe::Array.new
  @after_flush_callbacks = ThreadSafe::Array.new
  @constructingComputation = false


  class << self
    attr_accessor :active
    def add_pending_computation(pending_computation)
      @pending_computations << pending_computation
    end

    def autorun(&block)
      raise 'Autodeps.autorun requires a block' if block.nil?

      @constructingComputation = true
      c = Computation.new(block, Autodeps.current_computation);


      if (Autodeps.active)
        Autodeps.on_invalidate do
          c.stop();
        end
      end

      return c
    end

    def nonreactive(&f)
      previous = self.current_computation;
      self.current_computation = nil;
      begin
        f.call()
      ensure
        self.current_computation = previous;
      end
    end

    def flush

      #if (inFlush)
      #  throw new Error("Can't call Deps.flush while flushing");
      #
      #  if (inCompute)
      #    throw new Error("Can't flush inside Deps.autorun");

      @inFlush = true
      @willFlush = true


      while (@pending_computations.length > 0 ||
          @after_flush_callbacks.length > 0) do

          #recompute all pending computations
        comps = @pending_computations;
        @pending_computations = [];

        comps.each do |comp|
          comp.recompute();

        #if (afterFlushCallbacks.length) {
        #    // call one afterFlush callback, which may
        #// invalidate more computations
        #var func = afterFlushCallbacks.shift();
        #try {
        #  func();
        #} catch (e) {
        #    _debugFunc()("Exception from Deps afterFlush function:",
        #    e.stack || e.message);
        #}
        end
      end

      inFlush = false;
      willFlush = false;

    end

    def on_invalidate(&f)
      if (! Autodeps.active)
        raise "AutoDeps.on_invalidate requires a currentComputation"
      end

        Autodeps.current_computation.on_invalidate(f);
    end

    def isolateValue(equals=nil, &f)
      raise "must define a block in isolateValue" unless f
      if (!Autodeps.active)
        return f.call();
      end

      result_dep = Autodeps::Dependency.new;
      orig_result = nil
      Autodeps.autorun do |c|
        result = f.call();
        if (c.first_run)
          orig_result = result;
        elsif (!(equals ? equals(result, orig_result) :
            result == orig_result))
          result_dep.changed();
        end
      end
      result_dep.depend();

      return orig_result;
    end

    def embox(equals=nil, &func)
      raise "must define a block in embox" unless func


      curResult = nil;
      #There's one shared Dependency and Computation for all callers of

      # our box function.  It gets kicked off if necessary, and when
      # there are no more dependents, it gets stopped to avoid leaking
      # memory.
      resultDep = nil;
      computation = nil;

      return proc do
        if (!computation)
          if (!Autodeps.active)
            # Not in a reactive context.  Just call func, and don't start a
            # computation if there isn't one running already.
            break func.call();
          end

          # No running computation, so kick one off.  Since this computation
          # will be shared, avoid any association with the current computation
          # by using `Deps.nonreactive`.
          resultDep = Autodeps::Dependency.new;

          computation = Autodeps.nonreactive do
            break Autodeps.autorun do |c|
              oldResult = curResult;
              curResult = func.call();
              if (!c.first_run)
                if (!(equals ? equals.call(curResult, oldResult) :
                    curResult == oldResult))
                  resultDep.changed();
                end
              end
            end
          end
        end

        if (Autodeps.active)
          is_new = resultDep.depend();
          if (is_new)
            # For each new dependent, schedule a task for after that dependents
            # invalidation time and the subsequent flush. The task checks
            # whether the computation should be torn down.
            Autodeps.on_invalidate do
              if (resultDep && !resultDep.hasDependents())
                Autodeps.afterFlush do
                  # use a second afterFlush to bump ourselves to the END of the
                  # flush, after computation re-runs have had a chance to
                  # re-establish their connections to our computation.
                  Autodeps.afterFlush do
                    if (resultDep && !resultDep.hasDependents())
                      computation.stop();
                      computation = nil;
                      resultDep = nil;
                    end
                  end
                end
              end
            end
          end
        end

        curResult
      end
    end

    def embox_value(value, equals=nil)
       raise "embox_value on a direct value not implemented"
    end

    def active
      Thread.current["Autodeps::active"]
    end

    def active= (active)
      Thread.current["Autodeps::active"] = active
    end

    def current_computation
      Thread.current["Autodeps::current_computation"]
    end
    def current_computation= (computation)
      Thread.current["Autodeps::current_computation"] = computation
      self.active = !! computation;
    end
  end
end