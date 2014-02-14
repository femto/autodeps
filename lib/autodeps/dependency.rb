module Autodeps
  class Dependency
    attr_accessor :dependents
    def initialize
      @dependents = ThreadSafe::Array.new
    end
    def depend(computation = Autodeps.current_computation)

      if (!computation)
        return false if (!Autodeps.active)
        computation = Deps.current_computation;
      end
      if !@dependents.include?(computation)
        @dependents << computation
        #computation.onInvalidate(function () {
        #  delete self._dependentsById[id];
        #});
        return true
      else
        return false;
      end

    end

    def changed
      @dependents.each do |computation|
        computation.invalidate
      end
    end
  end
end