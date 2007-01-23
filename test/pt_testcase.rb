require 'test/unit/testcase'
require 'sexp_processor' # for deep_clone
require 'unique'

class Examples
  attr_reader :reader
  attr_writer :writer

  def a_method(x); x+1; end
  alias an_alias a_method

  define_method(:unsplatted) do |x|
    x + 1
  end

  define_method :splatted do |*args|
    y = args.first
    y + 42
  end

  define_method :dmethod_added, instance_method(:a_method) if RUBY_VERSION < "1.9"
end

class ParseTreeTestCase < Test::Unit::TestCase

  attr_accessor :processor # to be defined by subclass

  def self.testcase_order; @@testcase_order; end
  def self.testcases; @@testcases; end

  def setup
    super
    @processor = nil
    Unique.reset
  end

  def self.add_test name, data, klass = self.name[4..-1]
    name = name.to_s
    klass = klass.to_s
    if testcases.has_key? name then
      if testcases[name].has_key? klass then
        warn "testcase #{klass}##{name} already has data"
      else
        testcases[name][klass] = data
      end
    else
      warn "testcase #{name} does not exist"
    end
  end

  def self.unsupported_tests *tests
    tests.flatten.each do |name|
      add_test name, :unsupported
    end
  end

  @@testcase_order = %w(Ruby ParseTree)

  @@testcases = {

    "alias"  => {
      "Ruby"        => "class X\n  alias :y :x\nend",
      "ParseTree"   => [:class, :X, nil,
                        [:scope, [:alias, [:lit, :y], [:lit, :x]]]],
      "Ruby2Ruby"   => "class X\n  alias_method :y, :x\nend",
    },

    "and"  => {
      "Ruby"        => "(a and b)",
      "ParseTree"   => [:and, [:vcall, :a], [:vcall, :b]],
    },

    "argscat"  => {
      "Ruby"        => "a = b, c, *d",
      "ParseTree"   => [:lasgn, :a,
                        [:svalue,
                         [:argscat,
                          [:array, [:vcall, :b], [:vcall, :c]],
                          [:vcall, :d]]]],
    },

    "argspush"  => {
      "Ruby"        => "a[*b] = c",
      "ParseTree"   => [:attrasgn,
                        [:vcall, :a],
                        :[]=,
                        [:argspush, [:splat, [:vcall, :b]], [:vcall, :c]]],
    },

    "array"  => {
      "Ruby"        => "[1, :b, \"c\"]",
      "ParseTree"   => [:array, [:lit, 1], [:lit, :b], [:str, "c"]],
    },

    "attrasgn" => {
      "Ruby"        => "y = 0\n42.method = y\n",
      "ParseTree"   => [:block,
                        [:lasgn, :y, [:lit, 0]],
                        [:attrasgn, [:lit, 42], :method=, [:array, [:lvar, :y]]]],
    },

    "attrasgn_index_equals" => {
      "Ruby"        => "a[42] = 24",
      "ParseTree"   => [:attrasgn, [:vcall, :a], :[]=, [:array, [:lit, 42], [:lit, 24]]],
    },

    "attrset" => {
      "Ruby"        => [Examples, :writer=],
      "ParseTree"   => [:defn, :writer=, [:attrset, :@writer]],
      "Ruby2Ruby"   => "attr_writer :writer"
    },

    "back_ref"  => {
      "Ruby"        => "[$&, $`, $', $+]",
      "ParseTree"   => [:array,
                        [:back_ref, :&],
                        [:back_ref, "`".intern], # symbol was fucking up emacs
                        [:back_ref, "'".intern], # s->e
                        [:back_ref, :+]],
    },

    "begin"  => {
      "Ruby"        => "begin\n  (1 + 1)\nend",
      "ParseTree"   => [:begin, [:call, [:lit, 1], :+, [:array, [:lit, 1]]]],
    },

    "block_pass"  => {
      "Ruby"        => "a(&b)",
      "ParseTree"   => [:block_pass, [:vcall, :b], [:fcall, :a]],
    },

    "block_pass_omgwtf" => {
      "Ruby" => "define_attr_method(:x, :sequence_name, &Proc.new { |*args| nil })",
      "ParseTree" => [:block_pass,
                      [:iter,
                       [:call, [:const, :Proc], :new],
                       [:masgn, [:dasgn_curr, :args]],
                       [:nil]],
                      [:fcall, :define_attr_method,
                       [:array, [:lit, :x], [:lit, :sequence_name]]]],
    },

    "block_pass_splat" => {
      "Ruby" => "def blah(*args, &block)\n  other(*args, &block)\nend",
      "ParseTree" => [:defn, :blah,
                      [:scope,
                       [:block,
                        [:args, "*args".intern],
                        [:block_arg, :block],
                        [:block_pass,
                         [:lvar, :block],
                         [:fcall, :other, [:splat, [:lvar, :args]]]]]]],
    },

    "bmethod"  => {
      "Ruby"        => [Examples, :unsplatted],
      "ParseTree"   => [:defn,
                        :unsplatted,
                        [:bmethod,
                         [:dasgn_curr, :x],
                         [:call, [:dvar, :x], "+".intern, [:array, [:lit, 1]]]]],
      "Ruby2Ruby"   => "def unsplatted(x)\n  (x + 1)\nend"
    },

    "bmethod_splat" => {
      "Ruby" => [Examples, :splatted],
      "ParseTree" => [:defn, :splatted,
                      [:bmethod,
                       [:masgn, [:dasgn_curr, :args]],
                       [:block,
                        [:dasgn_curr, :y],
                        [:dasgn_curr, :y, [:call, [:dvar, :args], :first]],
                        [:call, [:dvar, :y], :+, [:array, [:lit, 42]]]]]],
      "Ruby2Ruby" => "def splatted(*args)\n  y = args.first\n  (y + 42)\nend",
    },

    "break"  => {
      "Ruby"        => "loop { break if true }",
      "ParseTree"   => [:iter,
                        [:fcall, :loop], nil, [:if, [:true], [:break], nil]],
    },

    "break_arg"  => {
      "Ruby"        => "loop { break 42 if true }",
      "ParseTree"   => [:iter,
                        [:fcall, :loop], nil,
                        [:if, [:true], [:break, [:lit, 42]], nil]],
    },

    "call" => {
      "Ruby"        => "self.method",
      "ParseTree" => [:call, [:self], :method],
    },

    "call_arglist"  => {
      "Ruby"        => "puts(42)",
      "ParseTree"   => [:fcall, :puts, [:array, [:lit, 42]]],
    },

    "call_index" => { # see attrasgn_index_equals for opposite
      "Ruby"        => "a[42]",
      "ParseTree"   => [:call, [:vcall, :a], :[], [:array, [:lit, 42]]],
    },

    "case" => {
      "Ruby"        => "var = 2\nresult = \"\"\ncase var\nwhen 1 then\n  puts(\"something\")\n  result = \"red\"\nwhen 2, 3 then\n  result = \"yellow\"\nwhen 4 then\n  # do nothing\nelse\n  result = \"green\"\nend\ncase result\nwhen \"red\" then\n  var = 1\nwhen \"yellow\" then\n  var = 2\nwhen \"green\" then\n  var = 3\nelse\n  # do nothing\nend\n",
      "ParseTree" => [:block,
                      [:lasgn, :var, [:lit, 2]],
                      [:lasgn, :result, [:str, ""]],
                      [:case,
                       [:lvar, :var],
                       [:when,
                        [:array, [:lit, 1]],
                        [:block,
                         [:fcall, :puts, [:array, [:str, "something"]]],
                         [:lasgn, :result, [:str, "red"]]]],
                       [:when,
                        [:array, [:lit, 2], [:lit, 3]],
                        [:lasgn, :result, [:str, "yellow"]]],
                       [:when, [:array, [:lit, 4]], nil],
                       [:lasgn, :result, [:str, "green"]]],
                      [:case,
                       [:lvar, :result],
                       [:when, [:array, [:str, "red"]],
                        [:lasgn, :var, [:lit, 1]]],
                       [:when, [:array, [:str, "yellow"]],
                        [:lasgn, :var, [:lit, 2]]],
                       [:when, [:array, [:str, "green"]],
                        [:lasgn, :var, [:lit, 3]]],
                       nil]]
    },

    "case_nested" => {
      "Ruby"        => "var1 = 1\nvar2 = 2\nresult = nil\ncase var1\nwhen 1 then\n  case var2\n  when 1 then\n    result = 1\n  when 2 then\n    result = 2\n  else\n    result = 3\n  end\nwhen 2 then\n  case var2\n  when 1 then\n    result = 4\n  when 2 then\n    result = 5\n  else\n    result = 6\n  end\nelse\n  result = 7\nend\n",
      "ParseTree" => [:block,
                      [:lasgn, :var1, [:lit, 1]],
                      [:lasgn, :var2, [:lit, 2]],
                      [:lasgn, :result, [:nil]],
                      [:case,
                       [:lvar, :var1],
                       [:when, [:array, [:lit, 1]],
                        [:case,
                         [:lvar, :var2],
                         [:when, [:array, [:lit, 1]],
                          [:lasgn, :result, [:lit, 1]]],
                         [:when, [:array, [:lit, 2]],
                          [:lasgn, :result, [:lit, 2]]],
                         [:lasgn, :result, [:lit, 3]]]],
                       [:when, [:array, [:lit, 2]],
                        [:case,
                         [:lvar, :var2],
                         [:when, [:array, [:lit, 1]],
                          [:lasgn, :result, [:lit, 4]]],
                         [:when, [:array, [:lit, 2]],
                          [:lasgn, :result, [:lit, 5]]],
                         [:lasgn, :result, [:lit, 6]]]],
                       [:lasgn, :result, [:lit, 7]]]]
    },

    "case_no_expr" => { # TODO: nested
      "Ruby" => "case\nwhen 1 then\n  :a\nwhen 2 then\n  :b\nelse\n  :c\nend",
      "ParseTree" => [:case, nil,
                      [:when,
                       [:array, [:lit, 1]],
                       [:lit, :a]],
                      [:when,
                       [:array, [:lit, 2]], [:lit, :b]],
                      [:lit, :c]],
    },

    "cdecl"  => {
      "Ruby"        => "X = 42",
      "ParseTree"   => [:cdecl, :X, [:lit, 42]],
    },

    "class_plain"  => {
      "Ruby"        => "class X\n  puts((1 + 1))\n  def blah\n    puts(\"hello\")\n  end\nend",
      "ParseTree"   => [:class,
                        :X,
                        nil,
                        [:scope,
                         [:block,
                          [:fcall, :puts, [:array, [:call, [:lit, 1], :+, [:array, [:lit, 1]]]]],
                          [:defn,
                           :blah,
                           [:scope,
                            [:block,
                             [:args],
                             [:fcall, :puts, [:array, [:str, "hello"]]]]]]]]],
    },

    "class_super_object"  => {
      "Ruby"        => "class X < Object\nend",
      "ParseTree"   => [:class,
                        :X,
                        [:const, :Object],
                        [:scope]],
    },

    "class_super_array"  => {
      "Ruby"        => "class X < Array\nend",
      "ParseTree"   => [:class,
                        :X,
                        [:const, :Array],
                        [:scope]],
    },

    "class_super_expr"  => {
      "Ruby"        => "class X < expr\nend",
      "ParseTree"   => [:class,
                        :X,
                        [:vcall, :expr],
                        [:scope]],
    },

    "colon2"  => {
      "Ruby"        => "X::Y",
      "ParseTree"   => [:colon2, [:const, :X], :Y],
    },

    "colon3"  => {
      "Ruby"        => "::X",
      "ParseTree"   => [:colon3, :X],
    },

    "conditional1" => { # TODO: rename
      "Ruby"        => "return 1 if (42 == 0)",
      "ParseTree"   => [:if,
                        [:call, [:lit, 42], :==, [:array, [:lit, 0]]],
                        [:return, [:lit, 1]],
                        nil],
    },

    "conditional2" => { # TODO: remove
      "Ruby"        => "return 2 unless (42 == 0)",
      "ParseTree"   => [:if,
                        [:call, [:lit, 42], :==, [:array, [:lit, 0]]],
                        nil,
                        [:return, [:lit, 2]]],
    },

    "conditional3" => {
      "Ruby"        => "if (42 == 0) then\n  return 3\nelse\n  return 4\nend",
      "ParseTree"   => [:if, [:call, [:lit, 42], :==, [:array, [:lit, 0]]],
                        [:return, [:lit, 3]],
                        [:return, [:lit, 4]]],
    },

    "conditional4" => {
      "Ruby"        => "if (42 == 0) then\n  return 2\nelsif (42 < 0) then\n  return 3\nelse\n  return 4\nend",
      "ParseTree"   => [:if,
                        [:call, [:lit, 42], :==, [:array, [:lit, 0]]],
                        [:return, [:lit, 2]],
                        [:if,
                         [:call, [:lit, 42], :<, [:array, [:lit, 0]]],
                         [:return, [:lit, 3]],
                         [:return, [:lit, 4]]]],
      "Ruby2Ruby"   => "if (42 == 0) then\n  return 2\nelse\n  if (42 < 0) then\n    return 3\n  else\n    return 4\n  end\nend",
    },

    "conditional5" => {
      "Ruby"       => "return if false unless true",
      "ParseTree"  => [:if, [:true], nil, [:if, [:false], [:return], nil]],
    },

    "const"  => {
      "Ruby"        => "X",
      "ParseTree"   => [:const, :X],
    },

    "cvar"  => {
      "Ruby"        => "@@x",
      "ParseTree"   => [:cvar, :@@x],
    },

    "cvasgn"  => {
      "Ruby"        => "def x\n  @@blah = 1\nend",
      "ParseTree"   => [:defn, :x,
                        [:scope,
                         [:block, [:args], [:cvasgn, :@@blah, [:lit, 1]]]]]
    },

    "cvdecl"  => {
      "Ruby"        => "class X\n  @@blah = 1\nend",
      "ParseTree"   => [:class, :X, nil,
                        [:scope, [:cvdecl, :@@blah, [:lit, 1]]]],
    },

    "dasgn"  => {
      "Ruby"        => "a.each { |x| b.each { |y| x = (x + 1) } }",
      "ParseTree"   => [:iter,
                        [:call, [:vcall, :a], :each],
                        [:dasgn_curr, :x],
                        [:iter,
                         [:call, [:vcall, :b], :each],
                         [:dasgn_curr, :y],
                         [:dasgn, :x,
                          [:call, [:dvar, :x], :+, [:array, [:lit, 1]]]]]],
    },

    "dasgn_curr" => {
      "Ruby"        => "data.each do |x, y|\n  a = 1\n  b = a\n  b = a = x\nend",
      "ParseTree"   => [:iter,
                        [:call, [:vcall, :data], :each],
                        [:masgn, [:array, [:dasgn_curr, :x], [:dasgn_curr, :y]]],
                        [:block,
                         [:dasgn_curr, :a, [:dasgn_curr, :b]],
                         [:dasgn_curr, :a, [:lit, 1]],
                         [:dasgn_curr, :b, [:dvar, :a]],
                         [:dasgn_curr, :b, [:dasgn_curr, :a, [:dvar, :x]]]]],
    },

    "defined"  => {
      "Ruby"        => "defined? $x",
      "ParseTree"   => [:defined, [:gvar, :$x]],
    },

    "defn_args" => {
      "Ruby"      => "def x(a, b = 42, \*c, &d)\n  p(a, b, c, d)\nend",
      "ParseTree" => [:defn, :x,
                      [:scope,
                       [:block,
                        [:args, :a, :b, "*c".intern, # s->e
                         [:block, [:lasgn, :b, [:lit, 42]]]],
                         [:block_arg, :d],
                        [:fcall, :p,
                         [:array, [:lvar, :a], [:lvar, :b],
                          [:lvar, :c], [:lvar, :d]]]]]]
    },

    "defn_empty" => {
      "Ruby"        => "def empty\n  # do nothing\nend",
      "ParseTree"   => [:defn, :empty, [:scope, [:block, [:args], [:nil]]]],
    },

    "defn_is_something" => {
      "Ruby"        => "def something?\n  # do nothing\nend",
      "ParseTree"   => [:defn, :something?, [:scope, [:block, [:args], [:nil]]]],
    },

# TODO:
#   add_test("defn_optargs",
#            s(:defn, :x,
#              s(:args, :a, "*args".intern),
#              s(:scope,
#                s(:block,
#                  s(:call, nil, :p,
#                    s(:arglist, s(:lvar, :a), s(:lvar, :args)))))))

    "defn_or" => {
      "Ruby"        => "def |(o)\n  # do nothing\nend",
      "ParseTree"   => [:defn, :|, [:scope, [:block, [:args, :o], [:nil]]]],
    },

    "defn_rescue" => {
      "Ruby" => "def blah\n    42\n  rescue\n    24\nend",
      "ParseTree" => [:defn, :blah,
                      [:scope, [:block, [:args],
                                [:rescue,
                                 [:lit, 42],
                                 [:resbody, nil, [:lit, 24]]]]]],
    },

    "defn_zarray" => { # tests memory allocation for returns
      "Ruby"        => "def zarray\n  a = []\n  return a\nend",
      "ParseTree"   => [:defn, :zarray,
                        [:scope,
                         [:block, [:args],
                          [:lasgn, :a, [:zarray]], [:return, [:lvar, :a]]]]],
    },

    "defs" => {
      "Ruby"      => "def self.x(y)\n  (y + 1)\nend",
      "ParseTree" => [:defs, [:self], :x,
                      [:scope,
                       [:block,
                        [:args, :y],
                        [:call, [:lvar, :y], :+, [:array, [:lit, 1]]]]]],
    },

    "dmethod" => {
      "Ruby"        => [Examples, :dmethod_added],
      "ParseTree"   => [:defn,
                        :dmethod_added,
                        [:dmethod,
                         :a_method,
                         [:scope,
                          [:block,
                           [:args, :x],
                           [:call, [:lvar, :x], :+, [:array, [:lit, 1]]]]]]],
      "Ruby2Ruby" => "def dmethod_added(x)\n  (x + 1)\nend"
    },

    "dot2"  => {
      "Ruby"        => "(a..b)",
      "ParseTree"   => [:dot2, [:vcall, :a], [:vcall, :b]],
    },

    "dot3"  => {
      "Ruby"        => "(a...b)",
      "ParseTree"   => [:dot3, [:vcall, :a], [:vcall, :b]],
    },

    "dregx"  => {
      "Ruby"        => "/x#\{(1 + 1)}y/",
      "ParseTree"   => [:dregx, "x",
                        [:call, [:lit, 1], :+, [:array, [:lit, 1]]], [:str, "y"]],
    },

    "dregx_once"  => {
      "Ruby"        => "/x#\{(1 + 1)}y/o",
      "ParseTree"   => [:dregx_once, "x",
                        [:call, [:lit, 1], :+, [:array, [:lit, 1]]], [:str, "y"]],
    },

    "dstr" => {
      "Ruby"        => "argl = 1\n\"x#\{argl}y\"\n",
      "ParseTree"   => [:block,
                        [:lasgn, :argl, [:lit, 1]],
                        [:dstr, "x", [:lvar, :argl],
                         [:str, "y"]]],
    },

    "dsym"  => {
      "Ruby"        => ":\"x#\{(1 + 1)}y\"",
      "ParseTree"   => [:dsym, "x",
                        [:call, [:lit, 1], :+, [:array, [:lit, 1]]], [:str, "y"]],
    },

    "dxstr" => {
      "Ruby"        => "t = 5\n`touch #\{t}`\n",
      "ParseTree"   => [:block,
                        [:lasgn, :t, [:lit, 5]],
                        [:dxstr, 'touch ', [:lvar, :t]]],
    },

    "ensure" => {
      "Ruby"        => "begin
  (1 + 1)
rescue SyntaxError => e1
  2
rescue Exception => e2
  3
else
  4
ensure
  5
end",
      "ParseTree"   => [:begin,
                        [:ensure,
                         [:rescue,
                          [:call, [:lit, 1], :+, [:array, [:lit, 1]]],
                          [:resbody,
                           [:array, [:const, :SyntaxError]],
                           [:block, [:lasgn, :e1, [:gvar, :$!]], [:lit, 2]],
                           [:resbody,
                            [:array, [:const, :Exception]],
                            [:block, [:lasgn, :e2, [:gvar, :$!]], [:lit, 3]]]],
                          [:lit, 4]],
                         [:lit, 5]]],
    },

    "false" => {
      "Ruby"      => "false",
      "ParseTree" => [:false],
    },

    "fbody" => {
      "Ruby"      => [Examples, :an_alias],
      "ParseTree" => [:defn, :an_alias,
                      [:fbody,
                       [:scope,
                        [:block,
                         [:args, :x],
                         [:call, [:lvar, :x], :+, [:array, [:lit, 1]]]]]]],
      "Ruby2Ruby" => "def an_alias(x)\n  (x + 1)\nend"
    },

    "fcall"  => {
      "Ruby"        => "p(4)",
      "ParseTree"   => [:fcall, :p, [:array, [:lit, 4]]],
    },

    "flip2"  => {
      "Ruby"        => "x = if ((i % 4) == 0)..((i % 3) == 0) then\n  i\nelse\n  nil\nend",
      "ParseTree"   => [:lasgn,
                        :x,
                        [:if,
                         [:flip2,
                          [:call,
                           [:call, [:vcall, :i], :%, [:array, [:lit, 4]]],
                           :==,
                           [:array, [:lit, 0]]],
                          [:call,
                           [:call, [:vcall, :i], :%, [:array, [:lit, 3]]],
                           :==,
                           [:array, [:lit, 0]]]],
                         [:vcall, :i],
                         [:nil]]],
    },

    "flip3"  => {
      "Ruby"        => "x = if ((i % 4) == 0)...((i % 3) == 0) then\n  i\nelse\n  nil\nend",
      "ParseTree"   => [:lasgn,
                        :x,
                        [:if,
                         [:flip3,
                          [:call,
                           [:call, [:vcall, :i], :%, [:array, [:lit, 4]]],
                           :==,
                           [:array, [:lit, 0]]],
                          [:call,
                           [:call, [:vcall, :i], :%, [:array, [:lit, 3]]],
                           :==,
                           [:array, [:lit, 0]]]],
                         [:vcall, :i],
                         [:nil]]],
    },

    "for"  => {
      "Ruby"        => "for o in ary\n  puts(o)\nend\n",
      "ParseTree"   => [:for, [:vcall, :ary], [:lasgn, :o],
                        [:fcall, :puts, [:array, [:lvar, :o]]]],
    },

    "gasgn"  => {
      "Ruby"        => "$x = 42",
      "ParseTree"   => [:gasgn, :$x, [:lit, 42]],
    },

    "global" => {
      "Ruby"        => "$stderr",
      "ParseTree"   =>  [:gvar, :$stderr],
    },

    "gvar"  => {
      "Ruby"        => "$x",
      "ParseTree"   => [:gvar, :$x],
    },

    "hash"  => {
      "Ruby"        => "{ 1 => 2, 3 => 4 }",
      "ParseTree"   => [:hash, [:lit, 1], [:lit, 2], [:lit, 3], [:lit, 4]],
    },

    "iasgn"  => {
      "Ruby"        => "@a = 4",
      "ParseTree"   => [:iasgn, :@a, [:lit, 4]],
    },

    "iteration1" => {
      "Ruby"        => "loop { }",
      "ParseTree"   => [:iter, [:fcall, :loop], nil],
    },

    "iteration2" => {
      "Ruby" => "array = [1, 2, 3]\narray.each { |x| puts(x.to_s) }\n",
      "ParseTree"   => [:block,
                        [:lasgn, :array,
                         [:array, [:lit, 1], [:lit, 2], [:lit, 3]]],
                        [:iter,
                         [:call, [:lvar, :array], :each],
                         [:dasgn_curr, :x],
                         [:fcall, :puts, [:array, [:call, [:dvar, :x], :to_s]]]]],
    },

    "iteration3" => {
      "Ruby"        => "1.upto(3) { |n| puts(n.to_s) }",
      "ParseTree"   => [:iter,
                        [:call, [:lit, 1], :upto, [:array, [:lit, 3]]],
                        [:dasgn_curr, :n],
                        [:fcall, :puts, [:array, [:call, [:dvar, :n], :to_s]]]],
    },

    "iteration4" => {
      "Ruby"        => "3.downto(1) { |n| puts(n.to_s) }",
      "ParseTree"   => [:iter,
                        [:call, [:lit, 3], :downto, [:array, [:lit, 1]]],
                        [:dasgn_curr, :n],
                        [:fcall, :puts, [:array, [:call, [:dvar, :n], :to_s]]]],
    },

    "iteration5" => {
      "Ruby"        => "argl = 10\nwhile (argl >= 1) do\n  puts(\"hello\")\n  argl = (argl - 1)\nend\n",
      "ParseTree"   => [:block,
                        [:lasgn, :argl, [:lit, 10]],
                        [:while,
                         [:call, [:lvar, :argl], ">=".intern, [:array, [:lit, 1]]],
                         [:block,
                          [:fcall, :puts, [:array, [:str, "hello"]]],
                          [:lasgn,
                           :argl,
                           [:call, [:lvar, :argl],
                            "-".intern, [:array, [:lit, 1]]]]], true]],
    },

    "iteration6" => {
      "Ruby"      => "array1 = [1, 2, 3]\narray2 = [4, 5, 6, 7]\narray1.each do |x|\n  array2.each do |y|\n    puts(x.to_s)\n    puts(y.to_s)\n  end\nend\n",
      "ParseTree" => [:block,
                      [:lasgn, :array1,
                       [:array, [:lit, 1], [:lit, 2], [:lit, 3]]],
                      [:lasgn, :array2,
                       [:array, [:lit, 4], [:lit, 5], [:lit, 6], [:lit, 7]]],
                      [:iter,
                       [:call,
                        [:lvar, :array1], :each],
                       [:dasgn_curr, :x],
                       [:iter,
                        [:call,
                         [:lvar, :array2], :each],
                        [:dasgn_curr, :y],
                        [:block,
                         [:fcall, :puts,
                          [:array, [:call, [:dvar, :x], :to_s]]],
                         [:fcall, :puts,
                          [:array, [:call, [:dvar, :y], :to_s]]]]]]],
    },

    "ivar" => {
      "Ruby"        => [Examples, :reader],
      "ParseTree"   => [:defn, :reader, [:ivar, :@reader]],
      "Ruby2Ruby"   => "attr_reader :reader"
    },

    "lasgn_array" => {
      "Ruby"        => "var = [\"foo\", \"bar\"]",
      "ParseTree"   => [:lasgn, :var, [:array,
                                       [:str, "foo"],
                                       [:str, "bar"]]],
    },

    "lasgn_call" => {
      "Ruby"        => "c = (2 + 3)",
      "ParseTree"   => [:lasgn, :c, [:call, [:lit, 2], :+, [:array, [:lit, 3]]]],
    },

    "lit_bool_false" => {
      "Ruby"        => "false",
      "ParseTree"   => [:false],
    },

    "lit_bool_true" => {
      "Ruby"        => "true",
      "ParseTree"   => [:true],
    },

    "lit_float" => {
      "Ruby"        => "1.1",
      "ParseTree"   => [:lit, 1.1],
    },

    "lit_long" => {
      "Ruby"        => "1",
      "ParseTree"   => [:lit, 1],
    },

    "lit_range2" => {
      "Ruby"        => "(1..10)",
      "ParseTree"   => [:lit, 1..10],
    },

    "lit_range3" => {
      "Ruby"        => "(1...10)",
      "ParseTree"   => [:lit, 1...10],
    },

    "lit_regexp" => {
      "Ruby"        => "/x/",
      "ParseTree"   => [:lit, /x/],
    },

    "lit_str" => {
      "Ruby"        => "\"x\"",
      "ParseTree"   => [:str, "x"],
    },

    "lit_sym" => {
      "Ruby"        => ":x",
      "ParseTree"   => [:lit, :x],
    },

    "masgn"  => {
      "Ruby"        => "a, b = c, d",
      "ParseTree"   => [:masgn,
                        [:array, [:lasgn, :a], [:lasgn, :b]],
                        [:array,  [:vcall, :c], [:vcall, :d]]],
    },

    "masgn_iasgn"  => {
      "Ruby"        => "a, @b = c, d",
      "ParseTree"   => [:masgn,
                        [:array, [:lasgn, :a], [:iasgn, "@b".intern]],
                        [:array,  [:vcall, :c], [:vcall, :d]]],
    },

    "masgn_attrasgn"  => {
      "Ruby"        => "a, b.c = d, e",
      "ParseTree"   => [:masgn,
                         [:array, [:lasgn, :a], [:attrasgn, [:vcall, :b], :c=]],
                         [:array, [:vcall, :d], [:vcall, :e]]],
    },

    "masgn_splat"  => {
      "Ruby"        => "a, b, *c = d, e, f, g",
      "ParseTree"   => [:masgn,
                        [:array, [:lasgn, :a], [:lasgn, :b]],
                        [:lasgn, :c],
                        [:array,
                         [:vcall, :d], [:vcall, :e],
                         [:vcall, :f], [:vcall, :g]]]
    },


    "match"  => {
      "Ruby"        => "1 if /x/",
      "ParseTree"   => [:if, [:match, [:lit, /x/]], [:lit, 1], nil],
    },

    "match2" => {
      "Ruby"        => "/x/ =~ \"blah\"",
      "ParseTree"   => [:match2, [:lit, /x/], [:str, "blah"]],
    },

    "match3" => {
      "Ruby"        => "\"blah\" =~ /x/",
      "ParseTree"   => [:match3, [:lit, /x/], [:str, "blah"]],
    },

    "module"  => {
      "Ruby"        => "module X\n  def y\n    # do nothing\n  end\nend",
      "ParseTree"   => [:module, :X,
                        [:scope,
                         [:defn, :y, [:scope, [:block, [:args], [:nil]]]]]],
    },

    "next"  => {
      "Ruby"        => "loop { next if false }",
      "ParseTree"   => [:iter,
                        [:fcall, :loop],
                        nil,
                        [:if, [:false], [:next], nil]],
    },

    "not"  => {
      "Ruby"        => "(not true)",
      "ParseTree"   => [:not, [:true]],
    },

    "nth_ref"  => {
      "Ruby"        => "$1",
      "ParseTree"   => [:nth_ref, 1],
    },

    "op_asgn1" => {
      "Ruby"        => "b = []\nb[1] ||= 10\nb[2] &&= 11\nb[3] += 12\n",
      "ParseTree"   => [:block,
                        [:lasgn, :b, [:zarray]],
                        [:op_asgn1, [:lvar, :b],
                         [:array, [:lit, 1]], "||".intern, [:lit, 10]], # s->e
                        [:op_asgn1, [:lvar, :b],
                         [:array, [:lit, 2]], "&&".intern, [:lit, 11]], # s->e
                        [:op_asgn1, [:lvar, :b],
                         [:array, [:lit, 3]], :+, [:lit, 12]]],
    },

    "op_asgn2" => {
      "Ruby"        => "s = Struct.new(:var)\nc = s.new(nil)\nc.var ||= 20\nc.var &&= 21\nc.var += 22\nc.d.e.f ||= 42\n",
      "ParseTree"   => [:block,
                        [:lasgn, :s,
                         [:call, [:const, :Struct],
                          :new, [:array, [:lit, :var]]]],
                        [:lasgn, :c,
                         [:call, [:lvar, :s], :new, [:array, [:nil]]]],

                        [:op_asgn2, [:lvar, :c], :var=, "||".intern, # s->e
                         [:lit, 20]],
                        [:op_asgn2, [:lvar, :c], :var=, "&&".intern, # s->e
                         [:lit, 21]],
                        [:op_asgn2, [:lvar, :c], :var=, :+, [:lit, 22]],

                        [:op_asgn2,
                         [:call,
                          [:call, [:lvar, :c], :d], :e], :f=, "||".intern,
                         [:lit, 42]]],
    },

    "op_asgn_and" => {
      "Ruby"        => "a = 0\na &&= 2\n",
      "ParseTree"   => [:block,
                        [:lasgn, :a, [:lit, 0]],
                        [:op_asgn_and, [:lvar, :a], [:lasgn, :a, [:lit, 2]]]],
    },

    "op_asgn_or" => {
      "Ruby"        => "a = 0\na ||= 1\n",
      "ParseTree"   => [:block,
                        [:lasgn, :a, [:lit, 0]],
                        [:op_asgn_or, [:lvar, :a], [:lasgn, :a, [:lit, 1]]]],
    },

    "or"  => {
      "Ruby"        => "(a or b)",
      "ParseTree"   => [:or, [:vcall, :a], [:vcall, :b]],
    },

    "postexe"  => {
      "Ruby"        => "END { 1 }",
      "ParseTree"   => [:iter, [:postexe], nil, [:lit, 1]],
    },

    "proc_args" => {
      "Ruby" => "proc { |x| (x + 1) }",
      "ParseTree" => [:iter,
                      [:fcall, :proc],
                      [:dasgn_curr, :x],
                      [:call, [:dvar, :x], :+, [:array, [:lit, 1]]]],
    },

    "proc_no_args" => {
      "Ruby" => "proc { (x + 1) }",
      "ParseTree" => [:iter,
                      [:fcall, :proc],
                      nil,
                      [:call, [:vcall, :x], :+, [:array, [:lit, 1]]]],
    },

    "redo"  => {
      "Ruby"        => "loop { redo if false }",
      "ParseTree"   => [:iter,
                        [:fcall, :loop], nil, [:if, [:false], [:redo], nil]],
    },

    "rescue"  => {
      "Ruby"        => "blah rescue nil",
      "ParseTree"   => [:rescue, [:vcall, :blah], [:resbody, nil, [:nil]]],
    },

    "rescue_block_body"  => {
      "Ruby"        => "begin\n  blah\nrescue\n  nil\nend\n",
      "ParseTree"   => [:begin, [:rescue, [:vcall, :blah], [:resbody, nil, [:nil]]]],
    },

    "rescue_block_nada"  => {
      "Ruby"        => "begin\n  blah\nrescue\n  # do nothing\nend\n",
      "ParseTree"   => [:begin, [:rescue, [:vcall, :blah], [:resbody, nil]]]
    },

    "rescue_exceptions"  => {
      "Ruby"        => "begin\n  blah\nrescue RuntimeError => r\n  # do nothing\nend\n",
      "ParseTree"   => [:begin,
                        [:rescue,
                         [:vcall, :blah],
                         [:resbody,
                          [:array, [:const, :RuntimeError]],
                          [:lasgn, :r, [:gvar, :$!]]]]],
    },

    "retry"  => {
      "Ruby"        => "retry",
      "ParseTree"   => [:retry],
    },

    "sclass"  => {
      "Ruby"        => "class << self\n  42\nend",
      "ParseTree"   => [:sclass, [:self], [:scope, [:lit, 42]]],
    },

    "splat"  => {
      "Ruby"        => "a(*b)",
      "ParseTree"   => [:fcall, :a, [:splat, [:vcall, :b]]],
    },

    # TODO: all supers need to pass args
    "super"  => {
      "Ruby"        => "def x\n  super(4)\nend",
      "ParseTree"   => [:defn, :x,
                        [:scope,
                         [:block,
                          [:args],
                          [:super, [:array, [:lit, 4]]]]]],
    },

    "super_multi"  => {
      "Ruby"        => "def x\n  super(4, 2, 1)\nend",
      "ParseTree"   => [:defn, :x,
                        [:scope,
                         [:block,
                          [:args],
                          [:super, [:array, [:lit, 4], [:lit, 2], [:lit, 1]]]]]],
    },

    "svalue"  => {
      "Ruby"        => "a = *b",
      "ParseTree"   => [:lasgn, :a, [:svalue, [:splat, [:vcall, :b]]]],
    },

    "to_ary"  => {
      "Ruby"        => "a, b = c",
      "ParseTree"   => [:masgn,
                        [:array, [:lasgn, :a], [:lasgn, :b]],
                        [:to_ary, [:vcall, :c]]],
    },

    "true" => {
      "Ruby"      => "true",
      "ParseTree" => [:true],
    },

    "undef"  => {
      "Ruby"        => "undef :x",
      "ParseTree"   => [:undef, [:lit, :x]],
    },

    "undef_multi"  => {
      "Ruby"        => "undef :x, :y, :z",
      "ParseTree"   => [:block,
                        [:undef, [:lit, :x]],
                        [:undef, [:lit, :y]],
                        [:undef, [:lit, :z]]],
      "Ruby2Ruby"   => "undef :x\nundef :y\nundef :z\n",
    },

    "until_post"  => {
      "Ruby"        => "begin\n  (1 + 1)\nend until false",
      "ParseTree"   => [:until, [:false],
                        [:call, [:lit, 1], :+, [:array, [:lit, 1]]], false],
    },

    "until_pre"  => {
      "Ruby"        => "until false do\n  (1 + 1)\nend",
      "ParseTree"   => [:until, [:false],
                        [:call, [:lit, 1], :+, [:array, [:lit, 1]]], true],
    },

    "valias"  => {
      "Ruby"        => "alias $y $x",
      "ParseTree"   => [:valias, :$y, :$x],
    },

    "vcall" => {
      "Ruby"        => "method",
      "ParseTree"   => [:vcall, :method],
    },

    "while_pre" => {
      "Ruby"        => "while false do\n  (1 + 1)\nend",
      "ParseTree"   => [:while, [:false],
                        [:call, [:lit, 1], :+, [:array, [:lit, 1]]], true],
    },

    "while_pre_nil" => {
      "Ruby"        => "while false do\nend",
      "ParseTree"   => [:while, [:false], nil, true],
    },

    "while_post" => {
      "Ruby"        => "begin\n  (1 + 1)\nend while false",
      "ParseTree"   => [:while, [:false],
                        [:call, [:lit, 1], :+, [:array, [:lit, 1]]], false],
    },

    "xstr" => {
      "Ruby"        => "`touch 5`",
      "ParseTree"   => [:xstr, 'touch 5'],
    },

    "yield"  => {
      "Ruby"        => "yield",
      "ParseTree"   => [:yield],
    },

    "yield_arg"  => {
      "Ruby"        => "yield(42)",
      "ParseTree"   => [:yield, [:lit, 42]],
    },

    "yield_args"  => {
      "Ruby"        => "yield(42, 24)",
      "ParseTree"   => [:yield, [:array, [:lit, 42], [:lit, 24]]],
    },

    "zarray" => {
      "Ruby"        => "a = []",
      "ParseTree"   => [:lasgn, :a, [:zarray]],
    },

    "zsuper"  => {
      "Ruby"        => "def x\n  super\nend",
      "ParseTree"   => [:defn, :x, [:scope, [:block, [:args], [:zsuper]]]],
    },
  }

#   def test_audit_nodes
#     # TODO: audit @@testcases.keys against node list - do two way audit, rename everything
#     nodes = ParseTree::NODE_NAMES.map { |s| s.to_s }.sort
#     tested = @@testcases.keys.map { |s| s.to_s }.sort
#     if processor.respond_to? :unsupported then
#       nodes -= processor.unsupported
#     else
#       SexpProcessor.new.unsupported
#       # HACK
#       nodes -= [:alloca, :argspush, :cfunc, :cref, :evstr, :ifunc, :last, :memo, :newline, :opt_n, :method].map { |s| s.to_s }
#     end

#     untested = nodes-tested

#     puts
#     p :untested_nodes => untested, :extra_nodes => tested-nodes

#     untested.each do |node|
#       puts %(
#     "#{node}"  => {
#       "Ruby"        => "XXX",
#       "ParseTree"   => [],
#     },
# )
#     end

#     flunk
#   end

  def self.previous(key, extra=0)
    idx = @@testcase_order.index(key)-1-extra
    case key
    when "RubyToRubyC" then
      idx -= 1
    end
    @@testcase_order[idx]
  end

#   # lets us used unprocessed :self outside of tests, called when subclassed
#   def self.clone_same
#     @@testcases.each do |node, data|
#       data.each do |key, val|
#         if val == :same then
#           prev_key = self.previous(key)
#           data[key] = data[prev_key].deep_clone
#         end
#       end
#     end
#   end

  def self.inherited(c)
    output_name = c.name.to_s.sub(/^Test/, '')
    raise "Unknown class #{c}" unless @@testcase_order.include? output_name

    input_name = self.previous(output_name)

    @@testcases.each do |node, data|
      next if [:skip, :unsupported].include? data[input_name]
      next if data[output_name] == :skip

      c.send(:define_method, "test_#{node}".intern) do
        flunk "Processor is nil" if processor.nil?
        assert data.has_key?(input_name), "Unknown input data"
        unless data.has_key?(output_name) then
          $stderr.puts "add_test(#{node.inspect}, :same)"
        end
        assert data.has_key?(output_name), "Missing test data: #{self.class} #{node}"
        input = data[input_name].deep_clone

        expected = if data[output_name] == :same then
                     input
                   else
                     data[output_name]
                   end.deep_clone

        case expected
        when :unsupported then
          assert_raises(UnsupportedNodeError) do
            processor.process(input)
          end
        else
          extra_expected = []
          extra_input = []

          _, expected, extra_expected = *expected if Array === expected and expected.first == :defx
          _, input, extra_input = *input if Array === input and input.first == :defx

          debug = input.deep_clone
          assert_equal expected, processor.process(input), "failed on input: #{debug.inspect}"
          extra_input.each do |input| processor.process(input) end
          extra = processor.extra_methods rescue []
          assert_equal extra_expected, extra
        end
      end
    end
  end

  undef_method :default_test
end
