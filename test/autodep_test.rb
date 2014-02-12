require '../test/test_helper'
require 'test/unit'

class ReactiveInteger
  attr_accessor :i, :dep
  def initialize(i)
    @i = i
    @dep = Autodeps::Dependency.new
  end
  def change_to(i)
    if i != @i
      changed = true
    end
    @i = i
    if changed
      @dep.changed
    end
  end
  def value
    dep.depend
    @i
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
    a = ReactiveInteger.new(3)
    b = nil
    computation = Autodeps.autorun do |computation|
      b = a.value
    end
    assert_equal b,3

    a.change_to 5

    assert_equal b,5
  end

  def test_reactive_integer_add
    a = ReactiveInteger.new(3)
    b = ReactiveInteger.new(5)
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