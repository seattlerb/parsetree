require 'test/unit/testcase'
require 'sexp_processor' # for deep_clone FIX
require 'unique'

class ParseTreeTestCase < Test::Unit::TestCase

  attr_accessor :processor # to be defined by subclass

  def self.testcase_order; @@testcase_order; end
  def self.testcases; @@testcases; end

  def setup
    super
    @processor = nil
    Unique.reset
  end

  @@testcase_order = %w(Ruby ParseTree)

  @@testcases = {
    
# TODO: needs eval
#     "accessor" => {
#       "Ruby"        => "attr_reader :accessor",
#       "ParseTree"   => [:defn, :accessor, [:ivar, :@accessor]],
#     },

# TODO: needs eval
#     "accessor_equals" => {
#       "Ruby"        => "attr_writer :accessor",
#       "ParseTree"   => [:defn, :accessor=, [:attrset, :@accessor]],
#     },
    
# TODO: needs eval
#     "alias"  => {
#       "Ruby"        => "XXX",
#       "ParseTree"   => [],
#     },

# TODO: no clue how to make
#     "alloca"  => {
#       "Ruby"        => "XXX",
#       "ParseTree"   => [],
#     },

# TODO: no clue how to make - supposedly through op_asgn but not showing
#     "argscat"  => {
#       "Ruby"        => "XXX",
#       "ParseTree"   => [],
#     },

# TODO: no clue how to make
#     "argspush"  => {
#       "Ruby"        => "XXX",
#       "ParseTree"   => [],
#     },

    "back_ref"  => {
      "Ruby"        => "[$&, $`, $', $+]",
      "ParseTree"   => [:array,
                        [:back_ref, :&],
                        [:back_ref, :"`"],
                        [:back_ref, :"'"],
                        [:back_ref, :+]],
    },

#     "bmethod"  => {
#       "Ruby"        => "XXX",
#       "ParseTree"   => [],
#     },

    "bools" => {
      "Ruby"      => "def bools(arg1)
  if arg1.nil? then
    return false
  else
    return true
  end
end",
      "ParseTree" => [:defn, :bools,
        [:scope,
          [:block,
            [:args, :arg1],
            [:if,
              [:call, [:lvar, :arg1], "nil?".intern], # emacs is freakin'
              [:return, [:false]],
              [:return, [:true]]]]]],
    },

    "break"  => {
      "Ruby"        => "loop do\n  if true then\n    break\n  end\nend",
      "ParseTree"   => [:iter,
                        [:fcall, :loop], nil, [:if, [:true], [:break], nil]],
    },

    "break_arg"  => {
      "Ruby"        => "loop do\n  if true then\n    break 42\n  end\nend",
      "ParseTree"   => [:iter,
                        [:fcall, :loop], nil,
                        [:if, [:true], [:break, [:lit, 42]], nil]],
    },

# TODO: move all call tests here
    "call_arglist"  => {
      "Ruby"        => "puts(42)",
      "ParseTree"   => [:fcall, :puts,  [:array,    [:lit, 42]]],
    },

    "call_attrasgn" => {
      "Ruby"        => "y = 0\n42.method=(y)\n",
      "ParseTree"   => [:block,
                        [:lasgn, :y, [:lit, 0]],
                        [:attrasgn, [:lit, 42], :method=, [:array, [:lvar, :y]]]],
    },

    "call_self" => {
      "Ruby"        => "self.method",
      "ParseTree" => [:call, [:self], :method],
    },

    "case_stmt" => {
      "Ruby"        => 'var = 2
result = ""
case var
when 1 then
  puts("something")
  result = "red"
when 2, 3 then
  result = "yellow"
when 4 then
  # do nothing
else
  result = "green"
end
case result
when "red" then
  var = 1
when "yellow" then
  var = 2
when "green" then
  var = 3
else
  # do nothing
end
',
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
      [:when, [:array, [:str, "red"]], [:lasgn, :var, [:lit, 1]]],
      [:when, [:array, [:str, "yellow"]], [:lasgn, :var, [:lit, 2]]],
      [:when, [:array, [:str, "green"]], [:lasgn, :var, [:lit, 3]]],
      nil]]
   },

    "cdecl"  => {
      "Ruby"        => "X = 42",
      "ParseTree"   => [:cdecl, :X, [:lit, 42]],
    },

# TODO: no clue
#     "cfunc"  => {
#       "Ruby"        => "XXX",
#       "ParseTree"   => [],
#     },

    "colon3"  => {
      "Ruby"        => "::X",
      "ParseTree"   => [:colon3, :X],
    },

    "conditional1" => {
      "Ruby"        => "if (42 == 0) then\n  return 1\nend",
      "ParseTree"   => [:if, [:call, [:lit, 42], :==, [:array, [:lit, 0]]], [:return, [:lit, 1]], nil],
    },

    "conditional2" => {
      "Ruby"        => "unless (42 == 0) then\n  return 2\nend",
      "ParseTree"   => [:if, [:call, [:lit, 42], :==, [:array, [:lit, 0]]], nil, [:return, [:lit, 2]]],
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
    },

# TODO: no clue
#     "cref"  => {
#       "Ruby"        => "XXX",
#       "ParseTree"   => [],
#     },

    "cvar"  => {
      "Ruby"        => "@@x",
      "ParseTree"   => [:cvar, :@@x],
    },

# TODO: no clue
#     "cvasgn"  => {
#       "Ruby"        => "XXX",
#       "ParseTree"   => [],
#     },

# TODO: no clue
#     "cvdecl"  => {
#       "Ruby"        => "XXX",
#       "ParseTree"   => [],
#     },

    "dasgn"  => {
      "Ruby"        => "a.each do |x|\n  b.each do |y|\n    x = (x + 1)\n  end\nend",
      "ParseTree"   => [:iter,
  [:call, [:vcall, :a], :each],
  [:dasgn_curr, :x],
  [:iter,
   [:call, [:vcall, :b], :each],
   [:dasgn_curr, :y],
   [:dasgn, :x, [:call, [:dvar, :x], :+, [:array, [:lit, 1]]]]]],
    },

    "defined"  => {
      "Ruby"        => "defined? $x",
      "ParseTree"   => [:defined, [:gvar, :$x]],
    },

    "defn_bbegin" => {
      "Ruby"        => "def bbegin
  begin
    (1 + 1)
  rescue SyntaxError
    e1 = $!
    2
  rescue Exception
    e2 = $!
    3
  else
    4
  ensure
    5
  end
end",
     "ParseTree"   => [:defn, :bbegin,
       [:scope,
         [:block,
           [:args],
           [:begin,
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
               [:lit, 5]]]]]],
    },

# FIX
#     "defn_bmethod_added" => {
#       "Ruby"        => "def bmethod_added(x)\n  (x + 1)\nend",
#       "ParseTree"   => [:defn, :bmethod_added,
#         [:bmethod,
#           [:dasgn_curr, :x],
#           [:call, [:dvar, :x], :+, [:array, [:lit, 1]]]]],
#     },

    "defn_empty" => {
      "Ruby"        => "def empty\n  # do nothing\nend",
      "ParseTree"   => [:defn, :empty, [:scope, [:block, [:args], [:nil]]]],
    },

# FIX
#     "defn_fbody" => {
#       "Ruby"        => "def x; puts 42; end; alias_method :aliased, :x",
#       "ParseTree" => [:defn, :aliased,
#                        [:fbody,
#                        [:scope,
#                          [:block,
#                            [:args],
#                            [:fcall, :puts, [:array, [:lit, 42]]]]]]],
#     },

    "defn_is_something" => {
      "Ruby"        => "def something?\n  # do nothing\nend",
      "ParseTree"   => [:defn, :something?, [:scope, [:block, [:args], [:nil]]]],
    },

    "defn_multi_args" => {
      "Ruby"        => "def multi_args(arg1, arg2)\n  arg3 = ((arg1 * arg2) * 7)\n  puts(arg3.to_s)\n  return \"foo\"\nend",
      "ParseTree"   => [:defn, :multi_args,
        [:scope,
          [:block,
            [:args, :arg1, :arg2],
            [:lasgn,
              :arg3,
              [:call,
                [:call, [:lvar, :arg1], :*, [:array, [:lvar, :arg2]]],
                :*,
                [:array, [:lit, 7]]]],
            [:fcall, :puts, [:array, [:call, [:lvar, :arg3], :to_s]]],
            [:return, [:str, "foo"]]]]],
    },
 
    "defn_optargs" => {
      "Ruby"      => "def x(a, *args)\n  p(a, args)\nend",
      "ParseTree" => [:defn, :x,
                      [:scope,
                       [:block,
                        [:args, :a, :"*args"],
                        [:fcall, :p,
                         [:array, [:lvar, :a], [:lvar, :args]]]]]],
    },

    "defn_or" => {
      "Ruby"        => "def |\n  # do nothing\nend",
      "ParseTree"   => [:defn, :|, [:scope, [:block, [:args], [:nil]]]],
    },

    "defn_zarray" => { # TODO: what does this give us?
      "Ruby"        => "def empty\n  a = []\n  return a\nend",
      "ParseTree"   => [:defn, :empty, [:scope, [:block, [:args], [:lasgn, :a, [:zarray]], [:return, [:lvar, :a]]]]],
    },

    "defs" => {
      "Ruby"      => "def self.x(y)\n  (y + 1)\nend",
      "ParseTree" => [:defs, [:self], :x,
                      [:scope,
                       [:block,
                        [:args, :y],
                        [:call, [:lvar, :y], :+, [:array, [:lit, 1]]]]]],
    },

#     "dmethod_added" => {
#       "Ruby"        => "def dmethod_added\n  define_method(:bmethod_added) do |x|\n    (x + 1)\n  end\nend",
#       "ParseTree"   => [:defn,
#         :dmethod_added,
#         [:dmethod,
#           :bmethod_maker,
#           [:scope,
#             [:block,
#               [:args],
#               [:iter,
#                 [:fcall, :define_method, [:array, [:lit, :bmethod_added]]],
#                 [:dasgn_curr, :x],
#                 [:call, [:dvar, :x], :+, [:array, [:lit, 1]]]]]]]],
#       "Ruby2Ruby" => "def dmethod_added(x)\n  (x + 1)\nend"
#     },

    "dregx"  => {
      "Ruby"        => "/x#\{(1 + 1)}y/",
      "ParseTree"   => [:dregx, "x", [:call, [:lit, 1], :+, [:array, [:lit, 1]]], [:str, "y"]],
    },

    "dregx_once"  => {
      "Ruby"        => "/x#\{(1 + 1)}y/o",
      "ParseTree"   => [:dregx_once, "x", [:call, [:lit, 1], :+, [:array, [:lit, 1]]], [:str, "y"]],
    },

    "dstr" => {
      "Ruby"        => "argl = 1\n\"var is #\{argl}. So there.\"\n",
      "ParseTree"   => [:block,
        [:lasgn, :argl, [:lit, 1]],
        [:dstr, "var is ", [:lvar, :argl], [:str, ". So there."]]],
    },

    "dsym"  => {
      "Ruby"        => ":\"x#\{(1 + 1)}y\"",
      "ParseTree"   => [:dsym, "x", [:call, [:lit, 1], :+, [:array, [:lit, 1]]], [:str, "y"]],
    },

    "dxstr" => {
      "Ruby"        => "t = 5\n`touch #\{t}`\n",
      "ParseTree"   => [:block,
        [:lasgn, :t, [:lit, 5]],
        [:dxstr, 'touch ', [:lvar, :t]]],
    },
 
# TODO: no clue
#     "evstr"  => {
#       "Ruby"        => "XXX",
#       "ParseTree"   => [],
#     },

# TODO: no clue
#     "fbody"  => {
#       "Ruby"        => "XXX",
#       "ParseTree"   => [],
#     },

    "flip2"  => {
      "Ruby"        => "if \"a\"..\"z\" then\n  42\nend",
      "ParseTree"   => [:if, [:flip2, [:str, "a"], [:str, "z"]], [:lit, 42], nil],
    },

    "flip3"  => {
      "Ruby"        => "if \"a\"...\"z\" then\n  42\nend",
      "ParseTree"   => [:if, [:flip3, [:str, "a"], [:str, "z"]], [:lit, 42], nil],
    },

    "gasgn"  => {
      "Ruby"        => "$x = 42",
      "ParseTree"   => [:gasgn, :$x, [:lit, 42]],
    },

    "global" => {
      "Ruby"        => "$stderr",
      "ParseTree"   =>  [:gvar, :$stderr],
    },

    "hash"  => {
      "Ruby"        => "{ 1 => 2, 3 => 4 }",
      "ParseTree"   => [:hash, [:lit, 1], [:lit, 2], [:lit, 3], [:lit, 4]],
    },

# TODO: no clue how to make
#     "ifunc"  => {
#       "Ruby"        => "XXX",
#       "ParseTree"   => [],
#     },

    "iteration1" => {
      "Ruby"        => "loop do end",
      "ParseTree"   => [:iter, [:fcall, :loop], nil],
    },

    "iteration2" => {
      "Ruby" => "array = [1, 2, 3]\narray.each do |x|\n  puts(x.to_s)\nend\n",
      "ParseTree"   => [:block,
                        [:lasgn, :array,
                         [:array, [:lit, 1], [:lit, 2], [:lit, 3]]],
                        [:iter,
                         [:call, [:lvar, :array], :each],
                         [:dasgn_curr, :x],
                         [:fcall, :puts, [:array, [:call, [:dvar, :x], :to_s]]]]],
    },

    "iteration3" => {
      "Ruby"        => "1.upto(3) do |n|\n  puts(n.to_s)\nend",
      "ParseTree"   => [:iter,
        [:call, [:lit, 1], :upto, [:array, [:lit, 3]]],
        [:dasgn_curr, :n],
        [:fcall, :puts, [:array, [:call, [:dvar, :n], :to_s]]]],
    },

    "iteration4" => {
      "Ruby"        => "3.downto(1) do |n|\n  puts(n.to_s)\nend",
      "ParseTree"   => [:iter,
        [:call, [:lit, 3], :downto, [:array, [:lit, 1]]],
        [:dasgn_curr, :n],
        [:fcall, :puts, [:array, [:call, [:dvar, :n], :to_s]]]],
    },

    "iteration5" => {
      "Ruby"        => "argl = 10\nwhile (argl >= 1) do\n  puts(\"hello\")\n  argl = (argl - 1)\nend\n",
      "ParseTree"   => [:block,
                        [:lasgn, :argl, [:lit, 10]],
                        [:while, [:call, [:lvar, :argl],
                        :>=, [:array, [:lit, 1]]], [:block,
                        [:fcall, :puts, [:array, [:str, "hello"]]],
                        [:lasgn,
                          :argl,
                          [:call, [:lvar, :argl],
                            :-, [:array, [:lit, 1]]]]], true]],
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

    # TODO: this might still be too much
    "lasgn_call" => {
      "Ruby"        => "c = (2 + 3)",
      "ParseTree"   => [:lasgn, :c, [:call, [:lit, 2], :+, [:array, [:lit, 3]]]],
    },

    "lasgn_array" => {
      "Ruby"        => "var = [\"foo\", \"bar\"]",
      "ParseTree"   => [:lasgn, :var, [:array,
                                         [:str, "foo"],
                                         [:str, "bar"]]],
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

    "lit_sym" => {
      "Ruby"        => ":x",
      "ParseTree"   => [:lit, :x],
    },

    "lit_str" => {
      "Ruby"        => "\"x\"",
      "ParseTree"   => [:str, "x"],
    },

# TODO: no clue
#     "match"  => {
#       "Ruby"        => "XXX",
#       "ParseTree"   => [],
#     },

    "match2" => {
      "Ruby"        => "/x/ =~ \"blah\"",
      "ParseTree"   => [:match2, [:lit, /x/], [:str, "blah"]],
    },

    "match3" => {
      "Ruby"        => "\"blah\" =~ /x/",
      "ParseTree"   => [:match3, [:lit, /x/], [:str, "blah"]],
    },

# TODO: no clue
#     "memo"  => {
#       "Ruby"        => "XXX",
#       "ParseTree"   => [],
#     },

# TODO: no clue
#     "method"  => {
#       "Ruby"        => "XXX",
#       "ParseTree"   => [],
#     },

# TODO: no clue
#     "newline"  => {
#       "Ruby"        => "XXX",
#       "ParseTree"   => [],
#     },

    "next"  => {
      "Ruby"        => "loop do\n  if false then\n    next\n  end\nend",
      "ParseTree"   => [:iter, [:fcall, :loop], nil, [:if, [:false], [:next], nil]],
    },

    "nth_ref"  => {
      "Ruby"        => "$1",
      "ParseTree"   => [:nth_ref, 1],
    },

    "op_asgn1" => {
      "Ruby"        => "b = []\nb[1] ||= 10\nb[2] &&= 11\nb[3] += 12\n",
      "ParseTree"   => [:block,
                  [:lasgn, :b, [:zarray]],

                 [:op_asgn1, [:lvar, :b], [:array, [:lit, 1]], :"||", [:lit, 10]],
                 [:op_asgn1, [:lvar, :b], [:array, [:lit, 2]], :"&&", [:lit, 11]],
                 [:op_asgn1, [:lvar, :b], [:array, [:lit, 3]], :+, [:lit, 12]]],
    },

    "op_asgn2" => {
      "Ruby"        => "s = Struct.new(:var)\nc = s.new(nil)\nc.var ||= 20\nc.var &&= 21\nc.var += 22\nc.d.e.f ||= 42\n",
      "ParseTree"   => [:block,
                 [:lasgn, :s, [:call, [:const, :Struct], :new, [:array, [:lit, :var]]]],
                 [:lasgn, :c, [:call, [:lvar, :s], :new, [:array, [:nil]]]],
               
                 [:op_asgn2, [:lvar, :c], :var=, :"||", [:lit, 20]],
                 [:op_asgn2, [:lvar, :c], :var=, :"&&", [:lit, 21]],
                 [:op_asgn2, [:lvar, :c], :var=, :+, [:lit, 22]],
               
                 [:op_asgn2, [:call, [:call, [:lvar, :c], :d], :e], :f=, :"||", [:lit, 42]]],
    },

    "op_asgn_andor" => {
      "Ruby"        => "a = 0\na ||= 1\na &&= 2\n",
      "ParseTree"   => [:block,
                 [:lasgn, :a, [:lit, 0]],
                 [:op_asgn_or, [:lvar, :a], [:lasgn, :a, [:lit, 1]]],
                 [:op_asgn_and, [:lvar, :a], [:lasgn, :a, [:lit, 2]]]],
    },

# TODO: no clue
#     "opt_n"  => {
#       "Ruby"        => "XXX",
#       "ParseTree"   => [],
#     },

    "postexe"  => {
      "Ruby"        => "END {\n  1\n}",
      "ParseTree"   => [:iter, [:postexe], nil, [:lit, 1]],
    },

    "redo"  => {
      "Ruby"        => "loop do\n  if false then\n    redo\n  end\nend",
      "ParseTree"   => [:iter, [:fcall, :loop], nil, [:if, [:false], [:redo], nil]],
    },

    "sclass"  => {
      "Ruby"        => "class << self\n  42\nend",
      "ParseTree"   => [:sclass, [:self], [:scope, [:lit, 42]]],
    },

# FIX: causes bus error
#     "undef"  => {
#       "Ruby"        => "undef :x",
#       "ParseTree"   => [:undef, :x],
#     },

    "valias"  => {
      "Ruby"        => "alias $y $x",
      "ParseTree"   => [:valias, :$y, :$x],
    },

    "vcall" => {
      "Ruby"        => "method",
      "ParseTree"   => [:vcall, :method],
    },

    "whiles" => {
      "Ruby"        => "def whiles\n  while false do\n    puts(\"false\")\n  end\n  begin\n    puts(\"true\")\n  end while false\nend",
      "ParseTree"   => [:defn,
        :whiles,
        [:scope,
          [:block,
            [:args],
            [:while, [:false],
              [:fcall, :puts, [:array, [:str, "false"]]], true],
            [:while, [:false],
              [:fcall, :puts, [:array, [:str, "true"]]], false]]]],
    },

    "xstr" => {
      "Ruby"        => "`touch 5`",
      "ParseTree"   => [:xstr, 'touch 5'],
    },

    "zarray" => {
      "Ruby"        => "a = []",
      "ParseTree"   => [:lasgn, :a, [:zarray]],
    },
  }

  def self.previous(key)
    idx = @@testcase_order.index(key)-1
    case key
    when "RubyToRubyC" then
      idx -= 1
    end
    @@testcase_order[idx]
  end

  # lets us used unprocessed :self outside of tests, called when subclassed
  def self.clone_same
    @@testcases.each do |node, data|
      data.each do |key, val|
        if val == :same then
          prev_key = self.previous(key)
          data[key] = data[prev_key].deep_clone
        end
      end
    end
  end

  def self.inherited(c)
    self.clone_same

    output_name = c.name.to_s.sub(/^Test/, '')
    raise "Unknown class #{c}" unless @@testcase_order.include? output_name

    input_name = self.previous(output_name)

    @@testcases.each do |node, data|
      next if data[input_name] == :skip
      next if data[output_name] == :skip

      c.send(:define_method, "test_#{node}".intern) do
        flunk "Processor is nil" if processor.nil?
        assert data.has_key?(input_name), "Unknown input data"
        assert data.has_key?(output_name), "Unknown expected data"
        input = data[input_name].deep_clone
        expected = data[output_name].deep_clone

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
          
          assert_equal expected, processor.process(input)
          extra_input.each do |input| processor.process(input) end
          extra = processor.extra_methods rescue []
          assert_equal extra_expected, extra
        end
      end
    end
  end

  def test_stoopid
    # do nothing - shuts up empty test class requirement
  end

end
