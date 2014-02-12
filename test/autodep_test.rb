require '../test/test_helper'
require 'test/unit'

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

class AutoDepsTest < Test::Unit::TestCase
  def test_invalidate
    a = 3
    b = nil
    computation = Autodeps.autorun do |computation|
      b = a
    end
    assert_equal b,a

    a = 5
    computation.invalidate
    assert_equal b,a

  end

  def test_reactive_integer
    a = ReactiveData.new(3)
    b = nil
    computation = Autodeps.autorun do |computation|
      b = a.value
    end
    assert_equal b,3

    a.change_to 5

    assert_equal b,5
  end

  def test_reactive_integer_add
    a = ReactiveData.new(3)
    b = ReactiveData.new(5)
    c = nil
    computation = Autodeps.autorun do |computation|
      c = a.value + b.value
    end
    assert_equal c,8

    a.change_to 5

    assert_equal c,10

    b.change_to 15

    assert_equal c,20
  end
end