module Autodeps
  class Computation
    attr_accessor :stopped, :invalidated, :first_run, :parent, :block, :recomputing,:_on_invalidate_callbacks
    def initialize(block, parent=nil)
      self.stopped = false;
          self.invalidated = false;
          self.first_run = true;

      self.parent = parent;
      self.block = block;
      self.recomputing = false;
      self._on_invalidate_callbacks = ThreadSafe::Array.new

      errored = true;
      begin
        self.compute();
        errored = false;
      rescue => e
          raise e
      ensure
        self.first_run = false;
        self.stop() if errored
      end
    end

    def compute
      self.invalidated = false;

      previous = Autodeps.current_computation;
      Autodeps.current_computation = self;

      in_compute = true;
      begin
        block.call(self)
      #rescue => e
      #  Autodeps.logger.error(e.message) if Autodeps.logger
      #  Autodeps.logger.error(e.backtrace.join("\n")) if Autodeps.logger
      ensure
        Autodeps.current_computation = previous;
        in_compute = false;
      end
    end

    def recompute
      self.recomputing = true

      while (self.invalidated && !self.stopped)
        begin
          self.compute()
        rescue => e
          Autodeps.logger.error(e.message) if Autodeps.logger
          Autodeps.logger.error(e.backtrace.join("\n")) if Autodeps.logger
        end
      end

      self.recomputing = false;
    end

    def stop
      if (! self.stopped)
            self.stopped = true;
            self.invalidate();
      end
    end

    def require_flush
      Autodeps::flush
    end

    def invalidate
      ##we request an immediate flush because we don't have timeout



      if (! self.invalidated)
        # if we're currently in _recompute(), don't enqueue
        # ourselves, since we'll rerun immediately anyway.

        self.invalidated = true;
        self._on_invalidate_callbacks.each do |f|
          f.call(); #// already bound with self as argument
        end
        self._on_invalidate_callbacks = ThreadSafe::Array.new;

        if (! self.recomputing && ! self.stopped)
          self.invalidated = true;

          Autodeps.add_pending_computation(self);
          require_flush();
        end

      # callbacks can't add callbacks, because
      #self.invalidated === true.


      end
    end

    def on_invalidate(f)
        raise ("on_invalidate requires a block") unless f;

        g = proc do
          Autodeps.nonreactive do
            f.call(self);
          end
        end

        if (self.invalidated)
          g();
        else
          self._on_invalidate_callbacks.push(g);
        end
    end
  end
end