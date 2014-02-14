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

  def test_isolation
    a = Autodeps::ReactiveData.new(3)
    b = Autodeps::ReactiveData.new(5)
    c = nil
    count = 0
    computation = nil
    result = nil
      Autodeps.autorun do ###1
        count += 1
        result = Autodeps.isolateValue do ###2
          a.value >= 3
        end
      end
    assert_equal true, result
    assert_equal 1, count #the ###1 blocks gets run first_time
    a.change_to 5
    assert_equal true, result
    assert_equal 1, count #the ###1 blocks doesn't gets run again because ###2's value doesn't change, the isolateValue call isolates it
    a.change_to 2
    assert_equal false, result
    assert_equal 2, count #the ###1 blocks gets run again, because the isolated block's value changes

  end

  def test_embox
    a = Autodeps::ReactiveData.new(3)
    b = Autodeps::ReactiveData.new(5)
    c = nil
    count = 0

    inner = proc do
      a.value
      count += 1
    end

    outter = Autodeps.embox do
      inner.call
    end

    Autodeps.autorun do ###1
      inner.call
    end
    Autodeps.autorun do ###1
      inner.call
    end
    assert_equal 2, count


    a.change_to 4
    assert_equal 4, count
  end

  def test_embox1
    a = Autodeps::ReactiveData.new(3)
    b = Autodeps::ReactiveData.new(5)
    c = nil
    count = 0

    inner = proc do
      a.value
      count += 1
    end

    outter = Autodeps.embox do
      inner.call
    end

    Autodeps.autorun do ###1
      outter.call
    end
    Autodeps.autorun do ###1
      outter.call
    end
    assert_equal 1, count


    a.change_to 4
    assert_equal 2, count
  end

  def test_nested_computation
    a = Autodeps::ReactiveData.new(3)
    b = Autodeps::ReactiveData.new(5)

    count_1 = 0
    count_2 = 0
    compuation1 = nil
    compuation2 = nil

    compuation1 = Autodeps.autorun do ###1
      a.value
      count_1 += 1
      compuation2 = Autodeps.autorun do ###1
        b.value
        count_2 += 1
      end
    end
    assert_equal 1, count_1
    assert_equal 1, count_2
    tmp_compuation1 = compuation1
    tmp_compuation2 = compuation2
    b.change_to 2

    assert_equal 1, count_1
    assert_equal 2, count_2
    assert_equal tmp_compuation1, compuation1
    assert_equal tmp_compuation2, compuation2

    a.change_to 15
    assert_equal 2, count_1
    assert_equal 3, count_2
    assert_equal tmp_compuation1, compuation1
    assert_not_equal tmp_compuation2, compuation2


  end

  def test_thread
    a = Autodeps::ReactiveData.new(3)
    b = Autodeps::ReactiveData.new(5)
    c = nil
    computation = Autodeps.autorun do |computation|
      c = a.value + b.value
    end
    assert_equal c,8

    thread = Thread.new do
     a.change_to 5
    end
    thread.join
    assert_equal c,10

    thread = Thread.new do
      b.change_to 15
    end
    thread.join
    assert_equal c,20
  end

  def test_active
    a = Autodeps::ReactiveData.new(3)
    b = Autodeps::ReactiveData.new(5)
    c = nil
    computation = Autodeps.autorun do |computation|
      c = a.value + b.value
    end
    assert_equal c,8


    thread = Thread.new do
      assert_equal nil, Autodeps.active
    end
    thread.join

  end


end