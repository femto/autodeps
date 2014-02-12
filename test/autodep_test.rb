require '../test/test_helper'
require 'test/unit'
class AutoDepsTest < Test::Unit::TestCase
  def test_first
    Autodeps.autorun do |computation|
      puts "ok"
      computation.invalidate()
    end
    #computation.invalidate()

  end
end