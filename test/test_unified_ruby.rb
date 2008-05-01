#!/usr/local/bin/ruby -w

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

  def test_call_args
    @insert = s(:call, s(:lit, 42), :y, s(:array, s(:lit, 24)))
    @expect = s(:call, s(:lit, 42), :y, s(:arglist, s(:lit, 24)))

    doit
  end

  def test_call_array_args
    @insert = s(:call, s(:lit, 42), :y, s(:array))
    @expect = s(:call, s(:lit, 42), :y, s(:arglist))

    doit
  end

  def test_call_no_args
    @insert = s(:call, s(:lit, 42), :y)
    @expect = s(:call, s(:lit, 42), :y, s(:arglist))

    doit
  end

  def test_rewrite_bmethod
    @insert = s(:bmethod,
                s(:dasgn_curr, :x),
                s(:call, s(:dvar, :x), :+, s(:array, s(:lit, 1))))
    @expect = s(:scope,
                s(:block,
                  s(:args, :x),
                  s(:call, s(:lvar, :x), :+, s(:arglist, s(:lit, 1)))))

    doit
  end

  # [:proc, [:masgn, [:array, [:dasgn_curr, :x], [:dasgn_curr, :y]]]]

  # proc { |x,y| x + y }
  # =
  # s(:iter,
  #  s(:fcall, :proc),
  #  s(:masgn, s(:array, s(:dasgn_curr, :x), s(:dasgn_curr, :y))),
  #  s(:call, s(:dvar, :x), :+, s(:array, s(:dvar, :y))))

  def test_rewrite_bmethod_noargs
    @insert = s(:bmethod,
                nil,
                s(:call, s(:vcall, :x), :+, s(:array, s(:lit, 1))))
    @expect = s(:scope,
                s(:block,
                  s(:args),
                  s(:call, s(:call, nil, :x, s(:arglist)),
                    :+, s(:arglist, s(:lit, 1)))))

    doit
  end

  def test_rewrite_bmethod_splat
    @insert = s(:bmethod,
                s(:masgn, s(:dasgn_curr, :params)),
                s(:lit, 42))
    @expect = s(:scope,
                s(:block,
                  s(:args, :"*params"),
                  s(:lit, 42)))

    doit
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
                        s(:splat, s(:lvar, :args)))))))

    doit
  end

  def test_rewrite_defn_bmethod_alias
    @insert = s(:defn, :group,
                s(:fbody,
                  s(:bmethod,
                    s(:masgn, s(:dasgn_curr, :params)),
                    s(:block,
                      s(:lit, 42)))))
    @expect = s(:defn, :group,
                s(:args, :"*params"),
                s(:scope,
                  s(:block, s(:lit, 42))))

    doit
  end

  def test_rewrite_defn_ivar
    @insert = s(:defn, :reader, s(:ivar, :@reader))
    @expect = s(:defn, :reader, s(:args), s(:ivar, :@reader))

    doit
  end

  def test_rewrite_defs
    @insert = s(:defs, s(:self), :meth, s(:scope, s(:block, s(:args), s(:true))))
    @expect = s(:defs, s(:self), :meth, s(:args), s(:scope, s(:block, s(:true))))

    doit
  end

  def test_rewrite_dmethod
    @insert = s(:dmethod,
                :a_method,
                s(:scope,
                  s(:block,
                    s(:args, :x),
                    s(:lit, 42))))
    @expect = s(:scope,
                s(:block,
                  s(:args, :x),
                  s(:lit, 42)))

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

  def test_rewrite_fcall_splat
    @insert = s(:fcall, :method, s(:splat, s(:vcall, :a)))
    @expect = s(:call, nil, :method, s(:splat, s(:call, nil, :a, s(:arglist))))
    doit
  end

  # TODO: think about flattening out to 1 resbody only
  def test_rewrite_resbody
    @insert = s(:resbody,
                s(:array, s(:const, :SyntaxError)),
                s(:block, s(:lasgn, :e1, s(:gvar, :$!)), s(:lit, 2)),
                s(:resbody,
                  s(:array, s(:const, :Exception)),
                  s(:block, s(:lasgn, :e2, s(:gvar, :$!)), s(:lit, 3))))

    @expect = s(:resbody,
                s(:array, s(:const, :SyntaxError), s(:lasgn, :e1, s(:gvar, :$!))),
                s(:block, s(:lit, 2)),
                s(:resbody,
                  s(:array, s(:const, :Exception), s(:lasgn, :e2, s(:gvar, :$!))),
                  s(:block, s(:lit, 3))))

    doit
  end

  def test_rewrite_resbody_empty
    # begin require 'rubygems'; rescue LoadError; end
    @insert = s(:begin,
                s(:rescue,
                  s(:fcall, :require, s(:array, s(:str, "rubygems"))),
                  s(:resbody, s(:array, s(:const, :LoadError)))))
    @expect = s(:begin,
                s(:rescue,
                  s(:call, nil, :require, s(:arglist, s(:str, "rubygems"))),
                  s(:resbody, s(:array, s(:const, :LoadError)), nil)))

    doit
  end

  def test_rewrite_resbody_lasgn
    @insert = s(:resbody,
                s(:array, s(:const, :SyntaxError)),
                s(:lasgn, :e1, s(:gvar, :$!)),
                s(:resbody,
                  s(:array, s(:const, :Exception)),
                  s(:block, s(:lasgn, :e2, s(:gvar, :$!)), s(:lit, 3))))

    @expect = s(:resbody,
                s(:array, s(:const, :SyntaxError), s(:lasgn, :e1, s(:gvar, :$!))),
                nil,
                s(:resbody,
                  s(:array, s(:const, :Exception), s(:lasgn, :e2, s(:gvar, :$!))),
                  s(:block, s(:lit, 3))))

    doit
  end

  def test_rewrite_vcall
    @insert = s(:vcall, :puts)
    @expect = s(:call, nil, :puts, s(:arglist))

    doit
  end
end
