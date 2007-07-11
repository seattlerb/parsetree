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
    @expect = s(:defn, :writer=, s(:args), s(:attrset, :@writer))

    doit
  end

  def test_rewrite_defn_block_arg
    @insert = s(:defn, :blah,
                s(:scope,
                  s(:block,
                    s(:args, "*args".intern),
                    s(:block_arg, :block),
                    s(:block_pass,
                      s(:lvar, :block),
                      s(:fcall, :other, s(:splat, s(:lvar, :args)))))))
    @expect = s(:defn, :blah,
                s(:args, "*args".intern, s(:block_arg, :block)),
                s(:scope,
                  s(:block,
                    s(:block_pass,
                      s(:lvar, :block),
                      s(:call, nil, :other,
                        s(:arglist, s(:splat, s(:lvar, :args))))))))

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

  def test_rewrite_defn_bmethod_noargs
    @insert = s(:defn, :bmethod_noargs,
                s(:bmethod,
                  nil,
                  s(:call, s(:vcall, :x), "+".intern, s(:array, s(:lit, 1)))))
    @expect = s(:defn, :bmethod_noargs,
                s(:args),
                s(:scope,
                  s(:block,
                    s(:call, s(:call, nil, :x, s(:arglist)),
                      "+".intern, s(:array, s(:lit, 1))))))

    doit
  end

  def test_rewrite_defn_bmethod_splat
    @insert = s(:defn, :group,
                s(:bmethod,
                  s(:masgn, s(:dasgn_curr, :params)),
                  s(:lit, 42)))
    @expect = s(:defn, :group,
                s(:args, :"*params"),
                s(:scope,
                  s(:block, s(:lit, 42))))

    doit
  end

  def test_rewrite_defn_define_method
    @insert = s(:defn, :splatted,
                s(:bmethod,
                  s(:masgn, s(:dasgn_curr, :args)),
                  s(:block,
                    s(:dasgn_curr, :y, s(:call, s(:dvar, :args), :first)),
                    s(:call, s(:dvar, :y), :+, s(:array, s(:lit, 42))))))
    @expect = s(:defn, :splatted,
                s(:args, :"*args"),
                s(:scope,
                  s(:block,
                    s(:dasgn_curr, :y, s(:call, s(:lvar, :args), :first)),
                    s(:call, s(:lvar, :y), :+, s(:array, s(:lit, 42))))))

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
                :dmethod_added,
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

  def test_rewrite_fbody
    @insert = s(:fbody,
                s(:scope,
                  s(:block,
                    s(:args, :x),
                    s(:call, s(:lvar, :x), :+, s(:array, s(:lit, 1))))))
    @expect = s(:scope,
                s(:block,
                  s(:args, :x),
                  s(:call, s(:lvar, :x), :+, s(:array, s(:lit, 1)))))

    doit
  end

  def test_rewrite_defn_ivar
    @insert = s(:defn, :reader, s(:ivar, :@reader))
    @expect = s(:defn, :reader, s(:args), s(:ivar, :@reader))

    doit
  end

  def test_rewrite_vcall
    @insert = s(:vcall, :puts)
    @expect = s(:call, nil, :puts, s(:arglist))

    doit
  end

  def test_rewrite_fcall
    @insert = s(:fcall,     :puts, s(:array, s(:lit, :blah)))
    @expect = s(:call, nil, :puts, s(:arglist, s(:lit, :blah)))

    doit
  end

  def test_rewrite_fcall_loop
    @insert = s(:iter, s(:fcall, :loop), nil)
    @expect = s(:iter, s(:call, nil, :loop, s(:arglist)), nil)

    doit
  end

end
