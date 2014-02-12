module Autodeps
  @pending_computations = []
  @after_flush_callbacks = []
  @constructingComputation = false
  @active = false

  class << self
    attr_accessor :active
    def add_pending_computation(pendingComputation)
      @pending_computations << pendingComputation
    end

    def autorun(&block)
      raise 'Autodeps.autorun requires a block' if block.nil?

      @constructingComputation = true
      c = Computation.new(block, Autodeps.current_computation);

      return c
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

    def current_computation
      Thread.current["Autodeps::current_computation"]
    end
    def current_computation=(computation)
      Thread.current["Autodeps::current_computation"] = computation
      self.active = !! computation;
    end
  end
end