#!/usr/local/bin/ruby

$TESTING = true

require 'test/unit' if $0 == __FILE__ unless defined? $ZENTEST and $ZENTEST
require 'test/unit/testcase'
require 'sexp'
require 'sexp_processor'
require 'unified_ruby'

class TestUnifier < SexpProcessor
  include UnifiedRuby
end

# TODO:
#
# 1) DONE [vf]call => call
# 2) DONE defn scope block args -> defn args scope block
# 3) DONE [bd]method/fbody => defn
# 4) rescue cleanup
# 5) defs x -> defn self.x # ON HOLD
# 6) ? :block_arg into args list?

class TestUnifiedRuby < Test::Unit::TestCase
  def setup
    @sp = TestUnifier.new
    @sp.require_empty = false
  end

  def doit
    assert_equal @expect, @sp.process(@insert)
  end

  def test_rewrite_defn
    @insert = s(:defn, :x, s(:scope, s(:block, s(:args), s(:nil))))
    @expect = s(:defn, :x, s(:args), s(:scope, s(:block, s(:nil))))

    doit
  end

  def test_rewrite_defn_attr
    @insert = s(:defn, :writer=, s(:attrset, :@writer))
    @expect = @insert.deep_clone

    doit
  end

  def test_rewrite_defn_bmethod
    @insert = s(:defn,
               :unsplatted,
               s(:bmethod,
                s(:dasgn_curr, :x),
                s(:call, s(:dvar, :x), :+, s(:array, s(:lit, 1)))))
    @expect = s(:defn,
               :unsplatted,
               s(:args, :x),
               s(:scope,
                s(:block,
                 s(:call, s(:lvar, :x), :+, s(:array, s(:lit, 1))))))

    doit
  end

  def test_rewrite_defn_dmethod
    @insert = s(:defn,
               :dmethod_added,
               s(:dmethod,
                :a_method,
                s(:scope,
                 s(:block,
                  s(:args, :x),
                  s(:call, s(:lvar, :x), :+, s(:array, s(:lit, 1)))))))
    @expect = s(:defn,
               :a_method,
               s(:args, :x),
               s(:scope,
                s(:block,
                 s(:call, s(:lvar, :x), :+, s(:array, s(:lit, 1))))))

    doit
  end

  def test_rewrite_defn_fbody
    @insert = s(:defn, :an_alias,
               s(:fbody,
                s(:scope,
                 s(:block,
                  s(:args, :x),
                  s(:call, s(:lvar, :x), :+, s(:array, s(:lit, 1)))))))
    @expect = s(:defn, :an_alias,
                s(:args, :x),
                s(:scope,
                 s(:block,
                  s(:call, s(:lvar, :x), :+, s(:array, s(:lit, 1))))))

    doit
  end

#   def test_rewrite_defs
#     insert = s(:defs, :puts)
#     expect = s(:call, nil, :puts, nil)
#     result = @sp.process insert

#     assert_equal expect, result
#   end

  def test_rewrite_vcall
    @insert = s(:vcall, :puts)
    @expect = s(:call, nil, :puts, nil)

    doit
  end

  def test_rewrite_fcall
    @insert = s(:fcall, :puts, s(:array, s(:lit, :blah)))
    @expect = s(:call, nil, :puts, s(:arglist, s(:lit, :blah)))

    doit
  end
end
