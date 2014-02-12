module Autodeps
  @pendingComputations = []
  @afterFlushCallbacks = []
  @constructingComputation = false

  class << self
    def add_pendingComputation(pendingComputation)
      @pendingComputations << pendingComputation
    end

    def autorun(&block)
      raise 'Autodeps.autorun requires a block' if block.nil?

      @constructingComputation = true
      c = Computation.new(block);

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


      while (@pendingComputations.length > 0 ||
          @afterFlushCallbacks.length > 0) do

          #recompute all pending computations
        comps = @pendingComputations;
        @pendingComputations = [];

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
  end
end