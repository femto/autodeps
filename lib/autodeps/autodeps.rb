require 'logger'
module Autodeps
  class << self
    attr_accessor :logger
  end
  self.logger = Logger.new(STDOUT)
  @pending_computations = []
  @after_flush_callbacks = []
  @constructingComputation = false
  @active = false

  class << self
    attr_accessor :active
    def add_pending_computation(pending_computation)
      @pending_computations << pending_computation
    end

    def autorun(&block)
      raise 'Autodeps.autorun requires a block' if block.nil?

      @constructingComputation = true
      c = Computation.new(block, Autodeps.current_computation);

      #todo
      #if (Deps.active)
      #  Deps.onInvalidate(function () {
      #    c.stop();
      #  });

      return c
    end

    def nonreactive(f)
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
      if (! computation)
        if (! Deps.active)
          # Not in a reactive context.  Just call func, and don't start a
      # computation if there isn't one running already.
          return func.call();
        end

        # No running computation, so kick one off.  Since this computation
        # will be shared, avoid any association with the current computation
        # by using `Deps.nonreactive`.
        resultDep = Autodeps.Dependency.new;

        computation = Autodeps.nonreactive do
          return Autodeps.autorun do
            oldResult = curResult;
            curResult = func.call();
            if (! c.first_run)
              if (! (equals ? equals(curResult, oldResult) :
                     curResult == oldResult))
                resultDep.changed();
              end
            end
          end
        end
      end

      if (Autodeps.active)
        isNew = resultDep.depend();
        if (isNew)
          # For each new dependent, schedule a task for after that dependents
          # invalidation time and the subsequent flush. The task checks
          # whether the computation should be torn down.
          Autodeps.onInvalidate do
            if (resultDep && !resultDep.hasDependents())
              Deps.afterFlush do
                # use a second afterFlush to bump ourselves to the END of the
                # flush, after computation re-runs have had a chance to
                # re-establish their connections to our computation.
                Deps.afterFlush do
                  if (resultDep && !resultDep.hasDependents())
                    computation.stop();
                    computation = null;
                    resultDep = null;
                  end
                end
              end
            end
          end
        end
      end

      return curResult;
    end
    end

    def embox_value(value, equals=nil)

    end

    def current_computation
      Thread.current["Autodeps::current_computation"]
    end
    def current_computation=(computation)
      Thread.current["Autodeps::current_computation"] = computation
      self.active = !! computation;
    end
  end
end