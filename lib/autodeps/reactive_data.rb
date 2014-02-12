module Autodeps
  class ReactiveData
    attr_accessor :value, :dep
    def initialize(value)
      @value = value
      @dep = Autodeps::Dependency.new
    end
    def change_to(value)
      if value != @value
        changed = true
      end
      @value = value
      if changed
        @dep.changed
      end
    end
    def value
      dep.depend
      @value
    end
  end
end