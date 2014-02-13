require '../test/test_helper'
require 'test/unit'



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
    a = Autodeps::ReactiveData.new(3)
    b = nil
    computation = Autodeps.autorun do |computation|
      b = a.value
    end
    assert_equal b,3

    a.change_to 5

    assert_equal b,5
  end

  def test_reactive_integer_add
    a = Autodeps::ReactiveData.new(3)
    b = Autodeps::ReactiveData.new(5)
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

  def test_exception
    a = Autodeps::ReactiveData.new(3)
    b = Autodeps::ReactiveData.new(5)
    c = nil
    computation = nil
    begin
       Autodeps.autorun do |_computation|
         computation = _computation
        c = a.value + b.value
        dd
      end
    rescue
    end
    p computation
    #assert_equal c,8
    #
    #a.change_to 5
    #
    #assert_equal c,10
    #
    #b.change_to 15
    #
    #assert_equal c,20
  end
end