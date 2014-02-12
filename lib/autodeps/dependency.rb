module Autodeps
  class Dependency
    attr_accessor :dependents
    def initialize
      @dependents = []
    end
    def depend(computation = Autodeps.current_computation)
      @dependents << computation
    end
  end
end