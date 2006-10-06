require 'test/unit/testcase'
require 'sexp_processor' # for deep_clone FIX
require 'unique'

class R2CTestCase < Test::Unit::TestCase

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
    
    "accessor" => {
      "Ruby"        => "attr_reader :accessor",
      "ParseTree"   => [:defn, :accessor, [:ivar, :@accessor]],
    },

    "accessor_equals" => {
      "Ruby"        => "attr_writer :accessor",
      "ParseTree"   => [:defn, :accessor=, [:attrset, :@accessor]],
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
    4end
  ensure
    5
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

# TODO: move all call tests here
    "call_arglist"  => {
      "Ruby"        => "puts(42)",
      "ParseTree"   => [:fcall,      :puts,  [:array,    [:lit, 42]]],
    },

    "call_attrasgn" => {
      "Ruby"        => "42.method=(y)",
      "ParseTree"   => [:attrasgn, [:lit, 42], :method=, [:array, [:lvar, :y]]],
    },

    "call_self" => {
      "Ruby"        => "self.method",
      "ParseTree" => [:call, [:self], :method],
    },

    "case_stmt" => {
      "Ruby"        => "def case_stmt
  var = 2
  result = \"\"
  case var
  when 1
    puts(\"something\")
    result = \"red\"
  when 2, 3
    result = \"yellow\"
  when 4
  else
    result = \"green\"
  end
  case result
  when \"red\"
    var = 1
  when \"yellow\"
    var = 2
  when \"green\"
    var = 3
  else
  end
  return result
end",
      "ParseTree" => [:defn, :case_stmt,
   [:scope,
    [:block,
     [:args],
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
      nil],
     [:return, [:lvar, :result]]]]],
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
      "Ruby"        => "if (42 == 0) then
  return 2
else
  if (42 < 0) then
    return 3
  else
    return 4
  end
end",
      "ParseTree"   => [:if,
        [:call, [:lit, 42], :==, [:array, [:lit, 0]]],
        [:return, [:lit, 2]],
        [:if,
          [:call, [:lit, 42], :<, [:array, [:lit, 0]]],
          [:return, [:lit, 3]],
          [:return, [:lit, 4]]]],
    },

    "defn_bmethod_added" => {
      "Ruby"        => "def bmethod_added(x)\n  (x + 1)\nend",
      "ParseTree"   => [:defn, :bmethod_added,
        [:bmethod,
          [:dasgn_curr, :x],
          [:call, [:dvar, :x], :+, [:array, [:lit, 1]]]]],
    },

    "defn_empty" => {
      "Ruby"        => "def empty\n  nil\nend",
      "ParseTree"   => [:defn, :empty, [:scope, [:block, [:args], [:nil]]]],
    },

    "defn_zarray" => {
      "Ruby"        => "def empty\n  a = []\n  return a\nend",
      "ParseTree"   => [:defn, :empty, [:scope, [:block, [:args], [:lasgn, :a, [:zarray]], [:return, [:lvar, :a]]]]],
    },

    "defn_or" => {
      "Ruby"        => "def |\n  nil\nend",
      "ParseTree"   => [:defn, :|, [:scope, [:block, [:args], [:nil]]]],
    },

    "defn_is_something" => {
      "Ruby"        => "def something?\n  nil\nend",
      "ParseTree"   => [:defn, :something?, [:scope, [:block, [:args], [:nil]]]],
    },

    "defn_fbody" => {
      "Ruby"        => "def aliased\n  puts(42)\nend",
      "ParseTree" => [:defn, :aliased,
                       [:fbody,
                       [:scope,
                         [:block,
                           [:args],
                           [:fcall, :puts, [:array, [:lit, 42]]]]]]],
    },

    "defn_optargs" => {
      "Ruby"        => "def x(a, *args)\n  p(a, args)\nend",
      "ParseTree" => [:defn, :x,
                      [:scope,
                       [:block,
                        [:args, :a, :"*args"],
                        [:fcall, :p,
                         [:array, [:lvar, :a], [:lvar, :args]]]]]],
    },

    "dmethod_added" => {
      "Ruby"        => "def dmethod_added\n  define_method(:bmethod_added) do |x|\n    (x + 1)\n  end\nend",
      "ParseTree"   => [:defn,
        :dmethod_added,
        [:dmethod,
          :bmethod_maker,
          [:scope,
            [:block,
              [:args],
              [:iter,
                [:fcall, :define_method, [:array, [:lit, :bmethod_added]]],
                [:dasgn_curr, :x],
                [:call, [:dvar, :x], :+, [:array, [:lit, 1]]]]]]]],
      "Ruby2Ruby" => "def dmethod_added(x)\n  (x + 1)\nend"
    },

    "global" => {
      "Ruby"        => "$stderr",
      "ParseTree"   =>  [:gvar, :$stderr],
    },

    "interpolated" => {
      "Ruby"        => "\"var is \#{argl}. So there.\"",
      "ParseTree"   => [:dstr,
        "var is ", [:lvar, :argl], [:str, ". So there."]],
    },

    "iter" => {
      "Ruby"        => "loop do end",
      "ParseTree"   => [:iter, [:fcall, :loop], nil],
    },

    "iteration2" => {
      "Ruby" => "arrays.each do |x|\n  puts(x)\nend",
      "ParseTree"   => [:iter,
        [:call, [:lvar, :arrays], :each],
        [:dasgn_curr, :x],
        [:fcall, :puts, [:array, [:dvar, :x]]]],
    },


    "iteration4" => {
      "Ruby"        => "1.upto(3) do |n|\n  puts(n.to_s)\nend",
      "ParseTree"   => [:iter,
        [:call, [:lit, 1], :upto, [:array, [:lit, 3]]],
        [:dasgn_curr, :n],
        [:fcall, :puts, [:array, [:call, [:dvar, :n], :to_s]]]],
    },

    "iteration5" => {
      "Ruby"        => "3.downto(1) do |n|\n  puts(n.to_s)\nend",
      "ParseTree"   => [:iter,
        [:call, [:lit, 3], :downto, [:array, [:lit, 1]]],
        [:dasgn_curr, :n],
        [:fcall, :puts, [:array, [:call, [:dvar, :n], :to_s]]]],
    },

    "iteration6" => {
      "Ruby"        => "while (argl >= 1) do\nputs(\"hello\")\nargl = (argl - 1)\n\nend",
      "ParseTree"   => [:while, [:call, [:lvar, :argl],
                        :>=, [:arglist, [:lit, 1]]], [:block,
                        [:call, nil, :puts, [:arglist, [:str, "hello"]]],
                        [:lasgn,
                          :argl,
                          [:call, [:lvar, :argl],
                            :-, [:arglist, [:lit, 1]]]]], true],
    },

    # TODO: this might still be too much
    "lasgn_call" => {
      "Ruby"        => "c = (2 + 3)",
      "ParseTree"   => [:lasgn, :c, [:call, [:lit, 2], :+, [:arglist, [:lit, 3]]]],
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

    "multi_args" => {
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
