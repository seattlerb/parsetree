#!/usr/local/bin/ruby

$TESTING = true

require 'test/unit' if $0 == __FILE__ unless defined? $ZENTEST and $ZENTEST
require 'test/unit/testcase'
require 'sexp_processor'
require 'unified_ruby'

class TestUnifier < SexpProcessor
  include UnifiedRuby
end

# TODO:
#
# 1) DONE [vf]call => call
# 2) defs x -> defn self.x
# 3) [bd]method/fbody => defn
# 4) defn scope block args -> defn args scope block
# 5) rescue cleanup

class TestUnifiedRuby < Test::Unit::TestCase
  def setup
    @sp = TestUnifier.new
    @sp.require_empty = false
  end

  def test_rewrite_vcall
    insert = s(:vcall, :puts)
    expect = s(:call, nil, :puts, nil)
    result = @sp.process insert

    assert_equal expect, result
  end

  def test_rewrite_fcall
    insert = s(:fcall, :puts, s(:array, s(:lit, :blah)))
    expect = s(:call, nil, :puts, s(:arglist, s(:lit, :blah)))
    result = @sp.process insert

    assert_equal expect, result
  end
end
