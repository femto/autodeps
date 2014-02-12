module Autodeps
  class Computation
    attr_accessor :stopped, :invalidated, :first_run, :parent, :block, :recomputing
    def initialize(block, parent=nil)
      self.stopped = false;
          self.invalidated = false;
          self.first_run = true;

      self.parent = parent;
      self.block = block;
      self.recomputing = false;

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

      #var previous = Deps.currentComputation;
      #setCurrentComputation(self);
      #var previousInCompute = in_compute;

      in_compute = true;
      begin
        block.call(self)
      ensure

        in_compute = false;
      end
    end

    def recompute
      self.recomputing = true

      while (self.invalidated && !self.stopped)
          self.compute() rescue nil
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
      #we request an immediate flush because we don't have timeout



      if (! self.invalidated)
          # if we're currently in _recompute(), don't enqueue
      # ourselves, since we'll rerun immediately anyway.
      if (! self.recomputing && ! self.stopped)
        self.invalidated = true;
        Autodeps.add_pending_computation(self);
        require_flush();
      end



      # callbacks can't add callbacks, because
      #self.invalidated === true.
      end
    end
  end
end