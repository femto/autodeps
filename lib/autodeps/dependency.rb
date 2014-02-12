module Autodeps
  class Dependency
    attr_accessor :dependents
    def initialize
      @dependents = []
    end
    def depend(computation = Autodeps.current_computation)
      @dependents << computation if !@dependents.include?(computation)
    end

    def tmp_flush
      @dependents.each do |computation|
        computation.invalidate
      end
    end
  end
end