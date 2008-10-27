#!/usr/local/bin/ruby -w

$TESTING = true

require 'test/unit' if $0 == __FILE__ unless defined? $ZENTEST and $ZENTEST
require 'test/unit/testcase'
require 'sexp'
require 'sexp_processor'
require 'unified_ruby'

class TestUnifier < Test::Unit::TestCase
  def test_process_bmethod
    u = Unifier.new

    raw = [:defn, :myproc3,
           [:bmethod,
            [:masgn, [:array,
                      [:dasgn_curr, :a],
                      [:dasgn_curr, :b],
                      [:dasgn_curr, :c]],
             nil, nil]]]

    s = s(:defn, :myproc3,
          s(:args, :a, :b, :c),
          s(:scope, s(:block)))

    assert_equal s, u.process(raw)
  end
end
