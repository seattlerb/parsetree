#!/usr/local/bin/ruby -w

require 'tmpdir'
dir = Dir.mktmpdir "parsetree."
ENV['INLINEDIR'] = dir
MiniTest::Unit.after_tests do
  require 'fileutils'
  FileUtils.rm_rf dir
end

require 'rubygems'
require 'minitest/autorun'
require 'parse_tree'
require 'pt_testcase'
require 'test/something'

module Mod1
  define_method :mod_method do
  end
end

module Mod2
  include Mod1
end

class ClassInclude
  include Mod2
end

class SomethingWithInitialize
  def initialize; end # this method is private
  protected
  def protected_meth; end
end

class RawParseTree
  def process(input, verbose = nil) # TODO: remove

    test_method = caller[0][/\`(.*)\'/, 1]
    verbose = test_method =~ /mri_verbose_flag/ ? true : nil

    # um. kinda stupid, but cleaner
    case input
    when Array then
      ParseTree.translate(*input)
    else
      self.parse_tree_for_string(input, '(string)', 1, verbose).first
    end
  end
end

class ParseTreeTestCase
  @@testcase_order = %w(Ruby RawParseTree ParseTree)

  add_tests("alias",
            "RawParseTree" => [:class, :X, nil,
                               [:scope, [:alias, [:lit, :y], [:lit, :x]]]])

  add_tests("alias_ugh",
            "RawParseTree" => [:class, :X, nil,
                               [:scope, [:alias, [:lit, :y], [:lit, :x]]]])

  add_tests("and",
            "RawParseTree" => [:and, [:vcall, :a], [:vcall, :b]])

  add_tests("argscat_inside",
            "RawParseTree" => [:lasgn, :a,
                               [:argscat,
                                [:array, [:vcall, :b]], [:vcall, :c]]])

  add_tests("argscat_svalue",
            "RawParseTree" => [:lasgn, :a,
                               [:svalue,
                                [:argscat,
                                 [:array, [:vcall, :b], [:vcall, :c]],
                                 [:vcall, :d]]]])

  add_tests("argspush",
            "RawParseTree" => [:attrasgn,
                               [:vcall, :a],
                               :[]=,
                               [:argspush,
                                [:splat,
                                 [:vcall, :b]],
                                [:vcall, :c]]])

  add_tests("array",
            "RawParseTree" => [:array, [:lit, 1], [:lit, :b], [:str, "c"]])

  add_tests("array_pct_W",
            "RawParseTree" => [:array, [:str, "a"], [:str, "b"], [:str, "c"]])

  add_tests("array_pct_W_dstr",
            "RawParseTree" => [:array,
                               [:str, "a"],
                               [:dstr, "", [:evstr, [:ivar, :@b]]],
                               [:str, "c"]])

  add_tests("array_pct_w",
            "RawParseTree" => [:array, [:str, "a"], [:str, "b"], [:str, "c"]])

  add_tests("array_pct_w_dstr",
            "RawParseTree" => [:array,
                               [:str, "a"],
                               [:str, "#\{@b}"],
                               [:str, "c"]]) # TODO: huh?

  add_tests("attrasgn",
            "RawParseTree" => [:block,
                               [:lasgn, :y, [:lit, 0]],
                               [:attrasgn, [:lit, 42], :method=,
                                [:array, [:lvar, :y]]]])

  add_tests("attrasgn_index_equals",
            "RawParseTree" => [:attrasgn, [:vcall, :a], :[]=,
                               [:array, [:lit, 42], [:lit, 24]]])

  add_tests("attrasgn_index_equals_space",
            "RawParseTree" => [:block,
                               [:lasgn, :a, [:zarray]],
                               [:attrasgn, [:lvar, :a], :[]=,
                                [:array, [:lit, 42], [:lit, 24]]]])

  add_tests("attrset",
            "RawParseTree" => [:defn, :writer=, [:attrset, :@writer]])

  add_tests("back_ref",
            "RawParseTree" => [:array,
                               [:back_ref, :&],
                               [:back_ref, :"`"],
                               [:back_ref, :"'"],
                               [:back_ref, :+]])

  add_tests("begin",
            "RawParseTree" => [:call, [:lit, 1], :+, [:array, [:lit, 1]]])

  add_tests("begin_def",
            "RawParseTree" => [:defn, :m, [:scope, [:block, [:args], [:nil]]]])

  add_tests("begin_rescue_ensure",
            "RawParseTree" => [:ensure,
                               [:rescue,
                                [:vcall, :a],
                                [:resbody, nil]],
                               [:nil]])

  add_tests("begin_rescue_ensure_all_empty",
            "RawParseTree" => [:ensure,
                               [:rescue,
                                [:resbody, nil]],
                               [:nil]])

  add_tests("begin_rescue_twice",
            "RawParseTree" => [:block,
                               [:rescue,
                                [:vcall, :a],
                                [:resbody, nil,
                                 [:lasgn, :mes, [:gvar, :$!]]]],
                               [:rescue,
                                [:vcall, :b],
                                [:resbody, nil,
                                 [:lasgn, :mes, [:gvar, :$!]]]]])

  add_tests("begin_rescue_twice_mri_verbose_flag",
            "RawParseTree" => [:block,
                               [:rescue,                # no begin
                                [:vcall, :a],
                                [:resbody, nil,
                                 [:lasgn, :mes, [:gvar, :$!]]]],
                               [:rescue,
                                [:vcall, :b],
                                [:resbody, nil,
                                 [:lasgn, :mes, [:gvar, :$!]]]]])

  add_tests("block_attrasgn",
            "RawParseTree" => [:defs, [:self], :setup,
                               [:scope,
                                [:block,
                                 [:args, :ctx],
                                 [:lasgn, :bind, [:vcall, :allocate]],
                                 [:attrasgn, [:lvar, :bind], :context=,
                                  [:array, [:lvar, :ctx]]],
                                 [:return, [:lvar, :bind]]]]])


  add_tests("block_lasgn",
            "RawParseTree" => [:lasgn, :x,
                               [:block,
                                [:lasgn, :y, [:lit, 1]],
                                [:call, [:lvar, :y], :+, [:array, [:lit, 2]]]]])

  add_tests("block_mystery_block",
            "RawParseTree" => [:iter,
                               [:fcall, :a, [:array, [:vcall, :b]]],
                               nil,
                               [:if,
                                [:vcall, :b],
                                [:true],
                                [:block,
                                 [:dasgn_curr, :c, [:false]],
                                 [:iter,
                                  [:fcall, :d],
                                  [:dasgn_curr, :x],
                                  [:dasgn, :c, [:true]]],
                                 [:dvar, :c]]]])

  add_tests("block_pass_args_and_splat",
            "RawParseTree" => [:defn, :blah,
                               [:scope,
                                [:block,
                                 [:args, :"*args"],
                                 [:block_arg, :block],
                                 [:block_pass,
                                  [:lvar, :block],
                                  [:fcall, :other,
                                   [:argscat,
                                    [:array, [:lit, 42]], [:lvar, :args]]]]]]])

  add_tests("block_pass_call_0",
            "RawParseTree" => [:block_pass,
                               [:vcall, :c], [:call, [:vcall, :a], :b]])

  add_tests("block_pass_call_1",
            "RawParseTree" => [:block_pass,
                               [:vcall, :c],
                               [:call, [:vcall, :a], :b, [:array, [:lit, 4]]]])

  add_tests("block_pass_call_n",
            "RawParseTree" => [:block_pass,
                               [:vcall, :c],
                               [:call, [:vcall, :a], :b,
                                [:array, [:lit, 1], [:lit, 2], [:lit, 3]]]])

  add_tests("block_pass_fcall_0",
            "RawParseTree" => [:block_pass, [:vcall, :b], [:fcall, :a]])

  add_tests("block_pass_fcall_1",
            "RawParseTree" => [:block_pass,
                               [:vcall, :b],
                               [:fcall, :a, [:array, [:lit, 4]]]])

  add_tests("block_pass_fcall_n",
            "RawParseTree" => [:block_pass,
                               [:vcall, :b],
                               [:fcall, :a,
                                [:array, [:lit, 1], [:lit, 2], [:lit, 3]]]])

  add_tests("block_pass_omgwtf",
            "RawParseTree" => [:block_pass,
                               [:iter,
                                [:call, [:const, :Proc], :new],
                                [:masgn, nil, [:dasgn_curr, :args], nil],
                                [:nil]],
                               [:fcall, :define_attr_method,
                                [:array, [:lit, :x], [:lit, :sequence_name]]]])

  add_tests("block_pass_splat",
            "RawParseTree" => [:defn, :blah,
                               [:scope,
                                [:block,
                                 [:args, :"*args"],
                                 [:block_arg, :block],
                                 [:block_pass,
                                  [:lvar, :block],
                                  [:fcall, :other,
                                   [:splat, [:lvar, :args]]]]]]])

  add_tests("block_pass_thingy",
            "RawParseTree" => [:block_pass,
                               [:vcall, :block],
                               [:call, [:vcall, :r], :read_body,
                                [:array, [:vcall, :dest]]]])

  add_tests("lambda_args_star",
            "RawParseTree" => [:iter,
                               [:fcall, :lambda],
                               [:masgn, nil, [:dasgn_curr, :star], nil],
                               [:dvar, :star]])

  add_tests("lambda_args_anon_star", # FIX: think this is wrong
            "RawParseTree" => [:iter,
                               [:fcall, :lambda],
                               [:masgn, nil, [:splat], nil],
                               [:nil]])

  add_tests("lambda_args_anon_star_block", # FIX: think this is wrong
            "RawParseTree" => [:iter,
                               [:fcall, :lambda],
                               [:block_pass,
                                [:dasgn_curr, :block],
                                [:masgn, nil, [:splat], nil]],
                               [:dvar, :block]])

  add_tests("lambda_args_block",
            "RawParseTree" => [:iter,
                               [:fcall, :lambda],
                               [:block_pass, [:dasgn_curr, :block]],
                               [:dvar, :block]])

  add_tests("lambda_args_norm_anon_star", # FIX: think this is wrong
            "RawParseTree" => [:iter,
                               [:fcall, :lambda],
                               [:masgn,
                                [:array, [:dasgn_curr, :a]], [:splat], nil],
                               [:dvar, :a]])

  add_tests("lambda_args_norm_anon_star_block", # FIX: think this is wrong
            "RawParseTree" => [:iter,
                               [:fcall, :lambda],
                               [:block_pass,
                                [:dasgn_curr, :block],
                                [:masgn,
                                 [:array, [:dasgn_curr, :a]], [:splat], nil]],
                               [:dvar, :block]])

  add_tests("lambda_args_norm_block", # FIX: think this is wrong
            "RawParseTree" => [:iter,
                               [:fcall, :lambda],
                               [:block_pass,
                                [:dasgn_curr, :block],
                                [:masgn,
                                 [:array, [:dasgn_curr, :a]], nil, nil]],
                               [:dvar, :block]])

  add_tests("lambda_args_norm_comma", # FIX: think this is wrong
            "RawParseTree" => [:iter,
                               [:fcall, :lambda],
                               [:masgn, [:array, [:dasgn_curr, :a]], nil, nil],
                               [:dvar, :a]])

  add_tests("lambda_args_norm_comma2", # FIX: think this is wrong
            "RawParseTree" => [:iter,
                               [:fcall, :lambda],
                               [:masgn,
                                [:array, [:dasgn_curr, :a], [:dasgn_curr, :b]],
                                nil, nil],
                               [:dvar, :a]])

  add_tests("lambda_args_norm_star",
            "RawParseTree" => [:iter,
                               [:fcall, :lambda],
                               [:masgn,
                                [:array, [:dasgn_curr, :a]],
                                [:dasgn_curr, :star], nil],
                               [:dvar, :star]])

  add_tests("lambda_args_norm_star_block",
            "RawParseTree" => [:iter,
                               [:fcall, :lambda],
                               [:block_pass,
                                [:dasgn_curr, :block],
                                [:masgn,
                                 [:array, [:dasgn_curr, :a]],
                                 [:dasgn_curr, :star], nil]],
                               [:dvar, :block]])

  add_tests("lambda_args_star_block",
            "RawParseTree" => [:iter,
                               [:fcall, :lambda],
                               [:block_pass,
                                [:dasgn_curr, :block],
                                [:masgn, nil, [:dasgn_curr, :star], nil]],
                               [:dvar, :block]])

  add_tests("block_stmt_after",
            "RawParseTree" => [:defn, :f,
                               [:scope,
                                [:block,
                                 [:args],
                                 [:rescue,
                                  [:vcall, :b],
                                  [:resbody, nil, [:vcall, :c]]],
                                 [:vcall, :d]]]])

  add_tests("block_stmt_after_mri_verbose_flag",
            "RawParseTree" => [:defn, :f,
                               [:scope,
                                [:block,
                                 [:args],
                                 [:rescue,              # no begin
                                  [:vcall, :b],
                                  [:resbody, nil, [:vcall, :c]]],
                                 [:vcall, :d]]]])

  add_tests("block_stmt_before",
            "RawParseTree" => [:defn, :f,
                               [:scope,
                                [:block,
                                 [:args],
                                 [:vcall, :a],
                                 [:rescue, [:vcall, :b],
                                  [:resbody, nil, [:vcall, :c]]]]]])

  copy_test_case "block_stmt_before", "RawParseTree"

  add_tests("block_stmt_both",
            "RawParseTree" => [:defn, :f,
                               [:scope,
                                [:block,
                                 [:args],
                                 [:vcall, :a],
                                 [:rescue,
                                  [:vcall, :b],
                                  [:resbody,
                                   nil,
                                   [:vcall, :c]]],
                                 [:vcall, :d]]]])

  add_tests("block_stmt_both_mri_verbose_flag",
            "RawParseTree" => [:defn, :f,
                               [:scope,
                                [:block,
                                 [:args],
                                 [:vcall, :a],
                                 [:rescue,              # no begin
                                  [:vcall, :b],
                                  [:resbody,
                                   nil,
                                   [:vcall, :c]]],
                                 [:vcall, :d]]]])

  add_tests("bmethod",
            "RawParseTree" => [:defn, :unsplatted,
                               [:bmethod,
                                [:dasgn_curr, :x],
                                [:call, [:dvar, :x], :+, [:array, [:lit, 1]]]]])

  add_tests("bmethod_noargs",
            "RawParseTree" => [:defn, :bmethod_noargs,
                               [:bmethod,
                                nil,
                                [:call,
                                 [:vcall, :x], :"+", [:array, [:lit, 1]]]]])

  add_tests("bmethod_splat",
            "RawParseTree" => [:defn, :splatted,
                               [:bmethod,
                                [:masgn, nil, [:dasgn_curr, :args], nil],
                                [:block,
                                 [:dasgn_curr, :y,
                                  [:call, [:dvar, :args], :first]],
                                 [:call, [:dvar, :y], :+,
                                  [:array, [:lit, 42]]]]]])

  add_tests("break",
            "RawParseTree" => [:iter,
                               [:fcall, :loop], nil,
                               [:if, [:true], [:break], nil]])

  add_tests("break_arg",
            "RawParseTree" => [:iter,
                               [:fcall, :loop], nil,
                               [:if, [:true], [:break, [:lit, 42]], nil]])

  add_tests("call",
            "RawParseTree" => [:call, [:self], :method])

  add_tests("call_arglist",
            "RawParseTree" => [:call, [:vcall, :o], :puts,
                               [:array, [:lit, 42]]])

  add_tests("call_no_space_symbol",
            "RawParseTree" => [:fcall, :foo, [:array, [:lit, :bar]]])

  add_tests("ternary_symbol_no_spaces",
            "RawParseTree" => [:if, [:lit, 1], [:lit, :x], [:lit, 1]])

  add_tests("ternary_nil_no_space",
            "RawParseTree" => [:if, [:lit, 1], [:nil], [:lit, 1]])

  add_tests("call_arglist_hash",
            "RawParseTree" => [:call,
                               [:vcall, :o], :m,
                               [:array,
                                [:hash,
                                 [:lit, :a], [:lit, 1],
                                 [:lit, :b], [:lit, 2]]]])

  add_tests("call_arglist_norm_hash",
            "RawParseTree" => [:call,
                               [:vcall, :o], :m,
                               [:array,
                                [:lit, 42],
                                [:hash,
                                 [:lit, :a], [:lit, 1],
                                 [:lit, :b], [:lit, 2]]]])

  add_tests("call_arglist_norm_hash_splat",
            "RawParseTree" => [:call,
                               [:vcall, :o], :m,
                               [:argscat,
                                [:array,
                                 [:lit, 42],
                                 [:hash,
                                  [:lit, :a], [:lit, 1],
                                  [:lit, :b], [:lit, 2]]],
                                [:vcall, :c]]])

  add_tests("call_arglist_space",
            "RawParseTree" => [:fcall, :a,
                               [:array, [:lit, 1], [:lit, 2], [:lit, 3]]])

  add_tests("call_command",
            "RawParseTree" => [:call, [:lit, 1], :b, [:array, [:vcall, :c]]])

  add_tests("call_expr",
            "RawParseTree" => [:call,
                               [:lasgn, :v,
                                [:call, [:lit, 1], :+, [:array, [:lit, 1]]]],
                               :zero?])

  add_tests("call_index",
            "RawParseTree" => [:block,
                               [:lasgn, :a, [:zarray]],
                               [:call, [:lvar, :a], :[], [:array, [:lit, 42]]]])

  add_tests("call_index_no_args",
            "RawParseTree" => [:call, [:vcall, :a], :[]])

  add_tests("call_index_space",
            "RawParseTree" => [:block,
                               [:lasgn, :a, [:zarray]],
                               [:call, [:lvar, :a], :[], [:array, [:lit, 42]]]])

  add_tests("call_unary_neg",
            "RawParseTree" => [:call,
                               [:call, [:lit, 2], :**, [:array, [:lit, 31]]],
                               :-@])

  add_tests("case",
            "RawParseTree" => [:block,
                               [:lasgn, :var, [:lit, 2]],
                               [:lasgn, :result, [:str, ""]],
                               [:case,
                                [:lvar, :var],
                                [:when,
                                 [:array, [:lit, 1]],
                                 [:block,
                                  [:fcall, :puts,
                                   [:array, [:str, "something"]]],
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
                                nil]])

  add_tests("case_nested",
            "RawParseTree" => [:block,
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
                                [:lasgn, :result, [:lit, 7]]]])

  add_tests("case_nested_inner_no_expr",
            "RawParseTree" => [:case, [:vcall, :a],
                               [:when, [:array, [:vcall, :b]],
                                [:case, nil,
                                 [:when,
                                  [:array, [:and, [:vcall, :d], [:vcall, :e]]],
                                  [:vcall, :f]],
                                 nil]],
                               nil])

  add_tests("case_no_expr",
            "RawParseTree" => [:case, nil,
                               [:when,
                                [:array,
                                 [:call, [:vcall, :a], :==,
                                  [:array, [:lit, 1]]]],
                                [:lit, :a]],
                               [:when,
                                [:array,
                                 [:call, [:vcall, :a], :==,
                                  [:array, [:lit, 2]]]],
                                [:lit, :b]],
                               [:lit, :c]])

  add_tests("case_splat",
            "RawParseTree" => [:case, [:vcall, :a],
                               [:when,
                                [:array,
                                 [:lit, :b], [:when, [:vcall, :c], nil]], # wtf?
                                [:vcall, :d]],
                               [:vcall, :e]])

  add_tests("cdecl",
            "RawParseTree" => [:cdecl, :X, [:lit, 42]])

  add_tests("class_plain",
            "RawParseTree" => [:class,
                               :X,
                               nil,
                               [:scope,
                                [:block,
                                 [:fcall, :puts,
                                  [:array,
                                   [:call, [:lit, 1], :+,
                                    [:array, [:lit, 1]]]]],
                                 [:defn, :blah,
                                  [:scope,
                                   [:block,
                                    [:args],
                                    [:fcall, :puts,
                                     [:array, [:str, "hello"]]]]]]]]])

  add_tests("class_scoped",
            "RawParseTree" => [:class, [:colon2, [:const, :X], :Y], nil,
                               [:scope, [:vcall, :c]]])

  add_tests("class_scoped3",
            "RawParseTree" => [:class, [:colon3, :Y], nil,
                               [:scope, [:vcall, :c]]])

  add_tests("class_super_array",
            "RawParseTree" => [:class,
                               :X,
                               [:const, :Array],
                               [:scope]])

  add_tests("class_super_expr",
            "RawParseTree" => [:class,
                               :X,
                               [:vcall, :expr],
                               [:scope]])

  add_tests("class_super_object",
            "RawParseTree" => [:class,
                               :X,
                               [:const, :Object],
                               [:scope]])

  add_tests("colon2",
            "RawParseTree" => [:colon2, [:const, :X], :Y])

  add_tests("colon3",
            "RawParseTree" => [:colon3, :X])

  add_tests("const",
            "RawParseTree" => [:const, :X])

  add_tests("constX",
            "RawParseTree" => [:cdecl, :X, [:lit, 1]])

  add_tests("constY",
            "RawParseTree" => [:cdecl, [:colon3, :X], [:lit, 1]])

  add_tests("constZ",
            "RawParseTree" => [:cdecl, [:colon2, [:const, :X], :Y], [:lit, 1]])

  add_tests("cvar",
            "RawParseTree" => [:cvar, :@@x])

  add_tests("cvasgn",
            "RawParseTree" => [:defn, :x,
                               [:scope,
                                [:block, [:args],
                                 [:cvasgn, :@@blah, [:lit, 1]]]]])

  add_tests("cvasgn_cls_method",
            "RawParseTree" => [:defs, [:self], :quiet_mode=,
                               [:scope,
                                [:block,
                                 [:args, :boolean],
                                 [:cvasgn, :@@quiet_mode, [:lvar, :boolean]]]]])

  add_tests("cvdecl",
            "RawParseTree" => [:class, :X, nil,
                               [:scope, [:cvdecl, :@@blah, [:lit, 1]]]])

  add_tests("dasgn_0",
            "RawParseTree" => [:iter,
                               [:call, [:vcall, :a], :each],
                               [:dasgn_curr, :x],
                               [:if, [:true],
                                [:iter,
                                 [:call, [:vcall, :b], :each],
                                 [:dasgn_curr, :y],
                                 [:dasgn, :x,
                                  [:call, [:dvar, :x], :+,
                                   [:array, [:lit, 1]]]]],
                                nil]])

  add_tests("dasgn_1",
            "RawParseTree" => [:iter,
                               [:call, [:vcall, :a], :each],
                               [:dasgn_curr, :x],
                               [:if, [:true],
                                [:iter,
                                 [:call, [:vcall, :b], :each],
                                 [:dasgn_curr, :y],
                                 [:dasgn_curr, :c,
                                  [:call, [:dvar, :c], :+,
                                   [:array, [:lit, 1]]]]],
                                nil]])

  add_tests("dasgn_2",
            "RawParseTree" => [:iter,
                               [:call, [:vcall, :a], :each],
                               [:dasgn_curr, :x],
                               [:if, [:true],
                                [:block,
                                 [:dasgn_curr, :c, [:lit, 0]],
                                 [:iter,
                                  [:call, [:vcall, :b], :each],
                                  [:dasgn_curr, :y],
                                  [:dasgn, :c,
                                   [:call, [:dvar, :c], :+,
                                    [:array, [:lit, 1]]]]]],
                                nil]])

  add_tests("dasgn_curr",
            "RawParseTree" => [:iter,
                               [:call, [:vcall, :data], :each],
                               [:masgn,
                                [:array, [:dasgn_curr, :x], [:dasgn_curr, :y]],
                                nil, nil],
                               [:block,
                                [:dasgn_curr, :a, [:lit, 1]],
                                [:dasgn_curr, :b, [:dvar, :a]],
                                [:dasgn_curr, :b,
                                 [:dasgn_curr, :a, [:dvar, :x]]]]])

  add_tests("dasgn_icky",
            "RawParseTree" => [:iter,
                               [:fcall, :a],
                               nil,
                               [:block,
                                [:dasgn_curr, :v, [:nil]],
                                [:iter,
                                 [:fcall, :assert_block,
                                  [:array, [:vcall, :full_message]]],
                                 nil,
                                 [:rescue,
                                  [:yield],
                                  [:resbody,
                                   [:array, [:const, :Exception]],
                                   [:block,
                                    [:dasgn, :v,
                                     [:gvar, :$!]], [:break]]]]]]])

  add_tests("dasgn_mixed",
            "RawParseTree" => [:block,
                               [:lasgn, :t, [:lit, 0]],
                               [:iter,
                                [:call, [:vcall, :ns], :each],
                                [:dasgn_curr, :n],
                                [:lasgn, :t,
                                 [:call, [:lvar, :t], :+,
                                  [:array, [:dvar, :n]]]]]])

  add_tests("defined",
            "RawParseTree" => [:defined, [:gvar, :$x]])

  # TODO: make all the defn_args* p their arglist
  add_tests("defn_args_block",
            "RawParseTree" => [:defn, :f,
                               [:scope,
                                [:block,
                                 [:args],
                                 [:block_arg, :block],
                                 [:nil]]]])

  add_tests("defn_args_mand",
            "RawParseTree" => [:defn, :f,
                               [:scope,
                                [:block,
                               [:args, :mand],
                                 [:nil]]]])

  add_tests("defn_args_mand_block",
            "RawParseTree" => [:defn, :f,
                               [:scope,
                                [:block,
                                 [:args, :mand],
                                 [:block_arg, :block],
                                 [:nil]]]])

  add_tests("defn_args_mand_opt",
            "RawParseTree" => [:defn, :f,
                               [:scope,
                                [:block,
                               [:args, :mand, :opt,
                                [:block,
                                 [:lasgn, :opt, [:lit, 42]]]],
                                 [:nil]]]])

  add_tests("defn_args_mand_opt_block",
            "RawParseTree" => [:defn, :f,
                               [:scope,
                                [:block,
                                 [:args, :mand, :opt,
                                  [:block,
                                   [:lasgn, :opt, [:lit, 42]]]],
                                 [:block_arg, :block],
                                 [:nil]]]])

  add_tests("defn_args_mand_opt_splat",
            "RawParseTree" => [:defn, :f,
                               [:scope,
                                [:block,
                               [:args, :mand, :opt, :"*rest",
                                [:block,
                                 [:lasgn, :opt, [:lit, 42]]]],
                                 [:nil]]]])

  add_tests("defn_args_mand_opt_splat_block",
            "RawParseTree" => [:defn, :f,
                               [:scope,
                                [:block,
                                 [:args, :mand, :opt, :"*rest",
                                  [:block,
                                   [:lasgn, :opt, [:lit, 42]]]],
                                 [:block_arg, :block],
                                 [:nil]]]])

  add_tests("defn_args_mand_opt_splat_no_name",
            "RawParseTree" => [:defn, :x,
                               [:scope,
                                [:block,
                                 [:args, :a, :b, :"*",
                                  [:block, [:lasgn, :b, [:lit, 42]]]],
                                 [:nil]]]])

  add_tests("defn_args_mand_splat",
            "RawParseTree" => [:defn, :f,
                               [:scope,
                                [:block,
                               [:args, :mand, :"*rest"],
                                 [:nil]]]])

  add_tests("defn_args_mand_splat_block",
            "RawParseTree" => [:defn, :f,
                               [:scope,
                                [:block,
                                 [:args, :mand, :"*rest"],
                                 [:block_arg, :block],
                                 [:nil]]]])

  add_tests("defn_args_mand_splat_no_name",
            "RawParseTree" => [:defn, :x,
                               [:scope,
                                [:block,
                                 [:args, :a, :"*args"],
                                 [:fcall, :p,
                                  [:array, [:lvar, :a], [:lvar, :args]]]]]])

  add_tests("defn_args_none",
            "RawParseTree" => [:defn, :empty,
                               [:scope, [:block, [:args], [:nil]]]])

  add_tests("defn_args_opt",
            "RawParseTree" => [:defn, :f,
                               [:scope,
                                [:block,
                               [:args, :opt,
                                [:block,
                                 [:lasgn, :opt, [:lit, 42]]]],
                                 [:nil]]]])

  add_tests("defn_args_opt_block",
            "RawParseTree" => [:defn, :f,
                               [:scope,
                                [:block,
                                 [:args, :opt,
                                  [:block,
                                   [:lasgn, :opt, [:lit, 42]]]],
                                 [:block_arg, :block],
                                 [:nil]]]])

  add_tests("defn_args_opt_splat",
            "RawParseTree" => [:defn, :f,
                               [:scope,
                                [:block,
                                 [:args, :opt, :"*rest",
                                  [:block,
                                   [:lasgn, :opt, [:lit, 42]]]],
                                 [:nil]]]])

  add_tests("defn_args_opt_splat_block",
            "RawParseTree" => [:defn, :f,
                               [:scope,
                                [:block,
                                 [:args, :opt, :"*rest",
                                  [:block,
                                   [:lasgn, :opt, [:lit, 42]]]],
                                 [:block_arg, :block],
                                 [:nil]]]])

  add_tests("defn_args_opt_splat_no_name",
            "RawParseTree" => [:defn, :x,
                               [:scope,
                                [:block,
                                 [:args, :b, :"*",
                                  [:block, [:lasgn, :b, [:lit, 42]]]],
                                 [:nil]]]])

  add_tests("defn_args_splat",
            "RawParseTree" => [:defn, :f,
                               [:scope,
                                [:block,
                                 [:args, :"*rest"],
                                 [:nil]]]])

  add_tests("defn_args_splat_no_name",
            "RawParseTree" => [:defn, :x,
                               [:scope,
                                [:block,
                                 [:args, :"*"],
                                 [:nil]]]])

  add_tests("defn_or",
            "RawParseTree" => [:defn, :|,
                               [:scope, [:block, [:args, :o], [:nil]]]])

  add_tests("defn_rescue",
            "RawParseTree" => [:defn, :eql?,
                               [:scope,
                                [:block,
                                 [:args, :resource],
                                 [:rescue,
                                  [:call,
                                   [:call, [:self], :uuid],
                                   :==,
                                   [:array,
                                    [:call, [:lvar, :resource], :uuid]]],
                                  [:resbody, nil, [:false]]]]]])

  add_tests("defn_rescue_mri_verbose_flag",
            "RawParseTree" => [:defn, :eql?,
                               [:scope,
                                [:block,
                                 [:args, :resource],
                                 [:rescue,
                                  [:call,
                                   [:call, [:self], :uuid],
                                   :==,
                                   [:array,
                                    [:call, [:lvar, :resource], :uuid]]],
                                  [:resbody, nil, [:false]]]]]])

  add_tests("defn_something_eh",
            "RawParseTree" => [:defn, :something?,
                               [:scope, [:block, [:args], [:nil]]]])

  add_tests("defn_splat_no_name",
            "RawParseTree" => [:defn, :x,
                               [:scope,
                                [:block,
                                 [:args, :a, :"*"],
                                 [:fcall, :p,
                                  [:array, [:lvar, :a]]]]]])

  add_tests("defn_zarray",
            "RawParseTree" => [:defn, :zarray,
                               [:scope,
                                [:block, [:args],
                                 [:lasgn, :a, [:zarray]],
                                 [:return, [:lvar, :a]]]]])

  add_tests("defs",
            "RawParseTree" => [:defs, [:self], :x,
                               [:scope,
                                [:block,
                                 [:args, :y],
                                 [:call, [:lvar, :y], :+,
                                  [:array, [:lit, 1]]]]]])

  add_tests("defs_empty",
            "RawParseTree" => [:defs, [:self], :empty,
                               [:scope, [:args]]])

  add_tests("defs_empty_args",
            "RawParseTree" => [:defs, [:self], :empty,
                               [:scope, [:args, :*]]])

  add_tests("defs_expr_wtf",
            "RawParseTree" => [:defs,
                               [:call, [:vcall, :a], :b],
                               :empty,
                               [:scope, [:args, :*]]])

  add_tests("dmethod",
            "RawParseTree" => [:defn, :dmethod_added,
                               [:dmethod,
                                :a_method,
                                [:scope,
                                 [:block,
                                  [:args, :x],
                                  [:call, [:lvar, :x], :+,
                                   [:array, [:lit, 1]]]]]]])

  add_tests("dot2",
            "RawParseTree" => [:dot2, [:vcall, :a], [:vcall, :b]])

  add_tests("dot3",
            "RawParseTree" => [:dot3, [:vcall, :a], [:vcall, :b]])

  add_tests("dregx",
            "RawParseTree" => [:dregx, "x",
                               [:evstr,
                                [:call, [:lit, 1], :+, [:array, [:lit, 1]]]],
                               [:str, "y"]])

  add_tests("dregx_interp",
            "RawParseTree" => [:dregx, '', [:evstr, [:ivar, :@rakefile]]])

  add_tests("dregx_interp_empty",
            "RawParseTree" => [:dregx, 'a', [:evstr], [:str, "b"]])

  add_tests("dregx_n",
            "RawParseTree" => [:dregx, '', [:evstr, [:lit, 1]], /x/n.options])

  add_tests("dregx_once",
            "RawParseTree" => [:dregx_once, "x",
                               [:evstr,
                                [:call, [:lit, 1], :+, [:array, [:lit, 1]]]],
                               [:str, "y"]])

  add_tests("dregx_once_n_interp",
            "RawParseTree" => [:dregx_once, '',
                               [:evstr, [:const, :IAC]],
                               [:evstr, [:const, :SB]], /x/n.options])

  add_tests("dstr",
            "RawParseTree" => [:block,
                               [:lasgn, :argl, [:lit, 1]],
                               [:dstr, "x", [:evstr, [:lvar, :argl]],
                                [:str, "y"]]])

  add_tests("dstr_2",
            "RawParseTree" =>   [:block,
                                 [:lasgn, :argl, [:lit, 1]],
                                 [:dstr,
                                  "x",
                                  [:evstr,
                                   [:call, [:str, "%.2f"], :%,
                                    [:array, [:lit, 3.14159]]]],
                                  [:str, "y"]]])

  add_tests("dstr_3",
            "RawParseTree" =>   [:block,
                                 [:lasgn, :max, [:lit, 2]],
                                 [:lasgn, :argl, [:lit, 1]],
                                 [:dstr, "x",
                                  [:evstr,
                                   [:call,
                                    [:dstr, "%.",
                                     [:evstr, [:lvar, :max]],
                                     [:str, "f"]],
                                    :%,
                                    [:array, [:lit, 3.14159]]]],
                                  [:str, "y"]]])

  add_tests("dstr_concat",
            "RawParseTree" => [:dstr,
                               "",
                               [:evstr, [:lit, 22]],
                               [:str, "aa"],
                               [:str, "cd"],
                               [:evstr, [:lit, 44]],
                               [:str, "55"],
                               [:evstr, [:lit, 66]]])

  add_tests("dstr_gross",
            "RawParseTree" => [:dstr, "a ",
                               [:evstr, [:gvar, :$global]],
                               [:str, " b "],
                               [:evstr, [:ivar, :@ivar]],
                               [:str, " c "],
                               [:evstr, [:cvar, :@@cvar]],
                               [:str, " d"]])

  add_tests("dstr_heredoc_expand",
            "RawParseTree" => [:dstr, "  blah\n",
                               [:evstr, [:call, [:lit, 1], :+,
                                         [:array, [:lit, 1]]]],
                               [:str, "blah\n"]])

  add_tests("dstr_heredoc_windoze_sucks",
            "RawParseTree" => [:dstr,
                               'def test_',
                               [:evstr, [:vcall, :action]],
                               [:str, "_valid_feed\n"]])

  add_tests("dstr_heredoc_yet_again",
            "RawParseTree" => [:dstr, "s1 '",
                               [:evstr, [:const, :RUBY_PLATFORM]],
                               [:str, "' s2\n"],
                               [:str, "(string)"],
                               [:str, "\n"]])

  add_tests("dstr_nest",
            "RawParseTree" => [:dstr, "before [",
                               [:evstr, [:vcall, :nest]], [:str, "] after"]])

  add_tests("dstr_str_lit_start",
            "RawParseTree" => [:dstr,
                               "blah(string):",
                               [:evstr, [:lit, 1]],
                               [:str, ": warning: "],
                               [:evstr, [:call, [:gvar, :$!], :message]],
                               [:str, " ("],
                               [:evstr, [:call, [:gvar, :$!], :class]],
                               [:str, ")"]])

  add_tests("dstr_the_revenge",
            "RawParseTree" => [:dstr,
                               "before ",
                               [:evstr, [:vcall, :from]],
                               [:str, " middle "],
                               [:evstr, [:vcall, :to]],
                               [:str, " ("],
                               [:str, "(string)"],
                               [:str, ":"],
                               [:evstr, [:lit, 1]],
                               [:str, ")"]])

  add_tests("dsym",
            "RawParseTree" => [:dsym, "x",
                               [:evstr, [:call, [:lit, 1], :+,
                                         [:array, [:lit, 1]]]], [:str, "y"]])

  add_tests("dxstr",
            "RawParseTree" => [:block,
                               [:lasgn, :t, [:lit, 5]],
                               [:dxstr, 'touch ', [:evstr, [:lvar, :t]]]])

  add_tests("ensure",
            "RawParseTree" => [:ensure,
                               [:rescue,
                                [:call, [:lit, 1], :+, [:array, [:lit, 1]]],
                                [:resbody,
                                 [:array, [:const, :SyntaxError]],
                                 [:block,
                                  [:lasgn, :e1, [:gvar, :$!]], [:lit, 2]],
                                 [:resbody,
                                  [:array, [:const, :Exception]],
                                  [:block,
                                   [:lasgn, :e2, [:gvar, :$!]], [:lit, 3]]]],
                                [:lit, 4]],
                               [:lit, 5]])

  add_tests("false",
            "RawParseTree" => [:false])

  add_tests("fbody",
            "RawParseTree" => [:defn, :an_alias,
                               [:fbody,
                                [:scope,
                                 [:block,
                                  [:args, :x],
                                  [:call, [:lvar, :x], :+,
                                   [:array, [:lit, 1]]]]]]])

  add_tests("fcall_arglist",
            "RawParseTree" => [:fcall, :m, [:array, [:lit, 42]]])

  add_tests("fcall_arglist_hash",
            "RawParseTree" => [:fcall, :m,
                               [:array,
                                [:hash,
                                 [:lit, :a], [:lit, 1],
                                 [:lit, :b], [:lit, 2]]]])

  add_tests("fcall_arglist_norm_hash",
            "RawParseTree" => [:fcall, :m,
                               [:array,
                                [:lit, 42],
                                [:hash,
                                 [:lit, :a], [:lit, 1],
                                 [:lit, :b], [:lit, 2]]]])

  add_tests("fcall_arglist_norm_hash_splat",
            "RawParseTree" => [:fcall, :m,
                               [:argscat,
                                [:array,
                                 [:lit, 42],
                                 [:hash,
                                  [:lit, :a], [:lit, 1],
                                  [:lit, :b], [:lit, 2]]],
                                [:vcall, :c]]])

  add_tests("fcall_block",
            "RawParseTree" => [:iter,
                               [:fcall, :a, [:array, [:lit, :b]]], nil,
                               [:lit, :c]])

  add_tests("fcall_index_space",
            "RawParseTree" => [:fcall, :a, [:array, [:array, [:lit, 42]]]])

  add_tests("fcall_keyword",
            "RawParseTree" => [:if, [:fcall, :block_given?], [:lit, 42], nil])

  add_tests("fcall_inside_parens",
            "RawParseTree" => [:fcall, :a, [:array, [:vcall, :b], [:vcall, :c]]])

  add_tests("flip2",
            "RawParseTree" => [:lasgn,
                               :x,
                               [:if,
                                [:flip2,
                                 [:call,
                                  [:call, [:vcall, :i], :%,
                                   [:array, [:lit, 4]]],
                                  :==,
                                  [:array, [:lit, 0]]],
                                 [:call,
                                  [:call, [:vcall, :i], :%,
                                   [:array, [:lit, 3]]],
                                  :==,
                                  [:array, [:lit, 0]]]],
                                [:vcall, :i],
                                [:nil]]])

  add_tests("flip2_method",
            "RawParseTree" => [:if,
                               [:flip2,
                                [:call, [:lit, 1], :==,
                                 [:array, [:gvar, :$.]]],
                                [:call, [:lit, 2], :a?,
                                 [:array, [:vcall, :b]]]],
                               [:nil],
                               nil])

  add_tests("flip3",
            "RawParseTree" => [:lasgn,
                               :x,
                               [:if,
                                [:flip3,
                                 [:call,
                                  [:call, [:vcall, :i], :%,
                                   [:array, [:lit, 4]]],
                                  :==,
                                  [:array, [:lit, 0]]],
                                 [:call,
                                  [:call, [:vcall, :i], :%,
                                   [:array, [:lit, 3]]],
                                  :==,
                                  [:array, [:lit, 0]]]],
                                [:vcall, :i],
                                [:nil]]])

  add_tests("for",
            "RawParseTree" => [:for,
                               [:vcall, :ary],
                               [:lasgn, :o],
                               [:fcall, :puts, [:array, [:lvar, :o]]]])

  add_tests("for_no_body",
            "RawParseTree" => [:for,
                               [:dot2, [:lit, 0], [:vcall, :max]],
                               [:lasgn, :i]])

  add_tests("gasgn",
            "RawParseTree" => [:gasgn, :$x, [:lit, 42]])

  add_tests("global",
            "RawParseTree" =>  [:gvar, :$stderr])

  add_tests("gvar",
            "RawParseTree" => [:gvar, :$x])

  add_tests("gvar_underscore",
            "RawParseTree" => [:gvar, :$_])

  add_tests("gvar_underscore_blah",
            "RawParseTree" => [:gvar, :$__blah])

  add_tests("hash",
            "RawParseTree" => [:hash,
                               [:lit, 1], [:lit, 2],
                               [:lit, 3], [:lit, 4]])

  add_tests("hash_rescue",
            "RawParseTree" => [:hash,
                               [:lit, 1],
                               [:rescue,
                                [:lit, 2],
                                [:resbody, nil, [:lit, 3]]]])

  add_tests("iasgn",
            "RawParseTree" => [:iasgn, :@a, [:lit, 4]])

  add_tests("if_block_condition",
            "RawParseTree" => [:if,
                               [:block,
                                [:lasgn, :x, [:lit, 5]],
                                [:call,
                                 [:lvar, :x],
                                 :+,
                                 [:array, [:lit, 1]]]],
                               [:nil],
                               nil])

  add_tests("if_lasgn_short",
            "RawParseTree" => [:if,
                               [:lasgn, :x,
                                [:call, [:vcall, :obj], :x]],
                               [:call,
                                [:lvar, :x], :do_it],
                               nil])

  add_tests("if_nested",
            "RawParseTree" => [:if, [:true], nil,
                               [:if, [:false], [:return], nil]])

  add_tests("if_post",
            "RawParseTree" => [:if, [:vcall, :b], [:vcall, :a], nil])

  add_tests("if_post_not",
            "RawParseTree" => [:if, [:vcall, :b], nil, [:vcall, :a]])

  add_tests("if_pre",
            "RawParseTree" => [:if, [:vcall, :b], [:vcall, :a], nil])

  add_tests("if_pre_not",
            "RawParseTree" => [:if, [:vcall, :b], nil, [:vcall, :a]])

  add_tests("iter_call_arglist_space",
            "RawParseTree" => [:iter,
                               [:fcall, :a, [:array, [:lit, 1]]],
                               [:dasgn_curr, :c],
                               [:vcall, :d]])

  add_tests("iter_dasgn_curr_dasgn_madness",
            "RawParseTree" => [:iter,
                               [:call, [:vcall, :as], :each],
                               [:dasgn_curr, :a],
                               [:dasgn_curr,
                                :b,
                                [:call,
                                 [:dvar, :b],
                                 :+,
                                 [:array,
                                  [:call, [:dvar, :a], :b,
                                   [:array, [:false]]]]]]])

  add_tests("iter_downto",
            "RawParseTree" => [:iter,
                               [:call, [:lit, 3], :downto, [:array, [:lit, 1]]],
                               [:dasgn_curr, :n],
                               [:fcall, :puts,
                                [:array, [:call, [:dvar, :n], :to_s]]]])

  add_tests("iter_each_lvar",
            "RawParseTree" => [:block,
                               [:lasgn, :array,
                                [:array, [:lit, 1], [:lit, 2], [:lit, 3]]],
                               [:iter,
                                [:call, [:lvar, :array], :each],
                                [:dasgn_curr, :x],
                                [:fcall, :puts,
                                 [:array, [:call, [:dvar, :x], :to_s]]]]])

  add_tests("iter_each_nested",
            "RawParseTree" => [:block,
                               [:lasgn, :array1,
                                [:array, [:lit, 1], [:lit, 2], [:lit, 3]]],
                               [:lasgn, :array2,
                                [:array,
                                 [:lit, 4], [:lit, 5], [:lit, 6], [:lit, 7]]],
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
                                   [:array, [:call, [:dvar, :y], :to_s]]]]]]])

  add_tests("iter_loop_empty",
            "RawParseTree" => [:iter, [:fcall, :loop], nil])

  add_tests("iter_masgn_2",
            "RawParseTree" => [:iter,
                               [:fcall, :a],
                               [:masgn,
                                [:array, [:dasgn_curr, :b], [:dasgn_curr, :c]],
                                nil, nil],
                               [:fcall, :p, [:array, [:dvar, :c]]]])

  add_tests("iter_masgn_args_splat",
            "RawParseTree" => [:iter,
                               [:fcall, :a],
                               [:masgn,
                                [:array, [:dasgn_curr, :b], [:dasgn_curr, :c]],
                                [:dasgn_curr, :d], nil],
                               [:fcall, :p, [:array, [:dvar, :c]]]])

  add_tests("iter_masgn_args_splat_no_name",
            "RawParseTree" => [:iter,
                               [:fcall, :a],
                               [:masgn,
                                [:array, [:dasgn_curr, :b], [:dasgn_curr, :c]],
                                [:splat], nil],
                               [:fcall, :p, [:array, [:dvar, :c]]]])

  add_tests("iter_masgn_splat",
            "RawParseTree" => [:iter,
                               [:fcall, :a],
                               [:masgn, nil, [:dasgn_curr, :c], nil],
                               [:fcall, :p, [:array, [:dvar, :c]]]])

  add_tests("iter_masgn_splat_no_name",
            "RawParseTree" => [:iter,
                               [:fcall, :a],
                               [:masgn, nil, [:splat], nil],
                               [:fcall, :p, [:array, [:vcall, :c]]]])

  add_tests("iter_shadowed_var",
            "RawParseTree" => [:iter,
                               [:fcall, :a],
                               [:dasgn_curr, :x],
                               [:iter,
                                [:fcall, :b],
                                [:dasgn, :x],
                                [:fcall, :puts, [:array, [:dvar, :x]]]]])

  add_tests("iter_upto",
            "RawParseTree" => [:iter,
                               [:call, [:lit, 1], :upto, [:array, [:lit, 3]]],
                               [:dasgn_curr, :n],
                               [:fcall, :puts,
                                [:array, [:call, [:dvar, :n], :to_s]]]])

  add_tests("iter_while",
            "RawParseTree" => [:block,
                               [:lasgn, :argl, [:lit, 10]],
                               [:while,
                                [:call, [:lvar, :argl], :">=",
                                 [:array, [:lit, 1]]],
                                [:block,
                                 [:fcall, :puts, [:array, [:str, "hello"]]],
                                 [:lasgn,
                                  :argl,
                                  [:call, [:lvar, :argl],
                                   :"-", [:array, [:lit, 1]]]]], true]])

  add_tests("ivar",
            "RawParseTree" => [:defn, :reader, [:ivar, :@reader]])

  add_tests("lasgn_array",
            "RawParseTree" => [:lasgn, :var,
                               [:array,
                                [:str, "foo"],
                                [:str, "bar"]]])

  add_tests("lasgn_call",
            "RawParseTree" => [:lasgn, :c, [:call, [:lit, 2], :+,
                                            [:array, [:lit, 3]]]])

  add_tests("lit_bool_false",
            "RawParseTree" => [:false])

  add_tests("lit_bool_true",
            "RawParseTree" => [:true])

  add_tests("lit_float",
            "RawParseTree" => [:lit, 1.1])

  add_tests("lit_long",
            "RawParseTree" => [:lit, 1])

  add_tests("lit_long_negative",
            "RawParseTree" => [:lit, -1])

  add_tests("lit_range2",
            "RawParseTree" => [:lit, 1..10])

  add_tests("lit_range3",
            "RawParseTree" => [:lit, 1...10])

# TODO: discuss and decide which lit we like
#   it "converts a regexp to an sexp" do
#     "/blah/".to_sexp.should == s(:regex, "blah", 0)
#     "/blah/i".to_sexp.should == s(:regex, "blah", 1)
#     "/blah/u".to_sexp.should == s(:regex, "blah", 64)
#   end

  add_tests("lit_regexp",
            "RawParseTree" => [:lit, /x/])

  add_tests("lit_regexp_i_wwtt",
            "RawParseTree" => [:call, [:vcall, :str], :split,
                               [:array, [:lit, //i]]])

  add_tests("lit_regexp_n",
            "RawParseTree" => [:lit, /x/n])

  add_tests("lit_regexp_once",
            "RawParseTree" => [:lit, /x/])

  add_tests("lit_sym",
            "RawParseTree" => [:lit, :x])

  add_tests("lit_sym_splat",
            "RawParseTree" => [:lit, :"*args"])

  add_tests("lvar_def_boundary",
            "RawParseTree" => [:block,
                               [:lasgn, :b, [:lit, 42]],
                               [:defn, :a,
                                [:scope,
                                 [:block,
                                  [:args],
                                  [:iter,
                                   [:fcall, :c],
                                   nil,
                                   [:rescue,
                                    [:vcall, :do_stuff],
                                    [:resbody,
                                     [:array, [:const, :RuntimeError]],
                                     [:block,
                                      [:dasgn_curr, :b, [:gvar, :$!]],
                                      [:fcall, :puts,
                                       [:array, [:dvar, :b]]]]]]]]]]])

  add_tests("masgn",
            "RawParseTree" => [:masgn,
                               [:array, [:lasgn, :a], [:lasgn, :b]], nil,
                               [:array,  [:vcall, :c], [:vcall, :d]]])

  add_tests("masgn_argscat",
            "RawParseTree" => [:masgn,
                               [:array, [:lasgn, :a], [:lasgn, :b]],
                               [:lasgn, :c],
                               [:argscat,
                                [:array, [:lit, 1], [:lit, 2]],
                                [:array, [:lit, 3], [:lit, 4]]]])

  add_tests("masgn_attrasgn",
            "RawParseTree" => [:masgn,
                               [:array, [:lasgn, :a],
                                [:attrasgn, [:vcall, :b], :c=]], nil,
                               [:array, [:vcall, :d], [:vcall, :e]]])

  add_tests("masgn_attrasgn_array_rhs",
            "RawParseTree" => [:masgn,
                                [:array,
                                  [:attrasgn, [:vcall, :a], :b=],
                                  [:attrasgn, [:vcall, :a], :c=],
                                  [:lasgn, :_]], nil,
                                [:to_ary, [:vcall, :q]]])

  add_tests("masgn_attrasgn_idx",
            "RawParseTree" => [:block,
                               [:masgn,
                                [:array,
                                 [:lasgn, :a], [:lasgn, :i], [:lasgn, :j]], nil,
                                [:array, [:zarray], [:lit, 1], [:lit, 2]]],
                               [:masgn,
                                [:array,
                                 [:attrasgn,
                                  [:lvar, :a], :[]=, [:array, [:lvar, :i]]],
                                 [:attrasgn,
                                  [:lvar, :a], :[]=, [:array, [:lvar, :j]]]],
                                nil,
                                [:array,
                                 [:call, [:lvar, :a], :[],
                                  [:array, [:lvar, :j]]],
                                 [:call, [:lvar, :a], :[],
                                  [:array, [:lvar, :i]]]]]])

  add_tests("masgn_cdecl",
            "RawParseTree" => [:masgn,
                               [:array, [:cdecl, :A], [:cdecl, :B],
                                [:cdecl, :C]], nil,
                               [:array, [:lit, 1], [:lit, 2], [:lit, 3]]])


  add_tests("masgn_iasgn",
            "RawParseTree" => [:masgn,
                               [:array, [:lasgn, :a], [:iasgn, :"@b"]], nil,
                               [:array,  [:vcall, :c], [:vcall, :d]]])

  add_tests("masgn_masgn",
            "RawParseTree" => [:masgn,
                               [:array,
                                [:lasgn, :a],
                                [:masgn,
                                 [:array,
                                  [:lasgn, :b],
                                  [:lasgn, :c]], nil, nil]],
                               nil,
                               [:to_ary,
                                [:array,
                                 [:lit, 1],
                                 [:array,
                                  [:lit, 2],
                                  [:lit, 3]]]]])

  add_tests("masgn_splat_lhs",
            "RawParseTree" => [:masgn,
                               [:array, [:lasgn, :a], [:lasgn, :b]],
                               [:lasgn, :c],
                               [:array,
                                [:vcall, :d], [:vcall, :e],
                                [:vcall, :f], [:vcall, :g]]])

  add_tests("masgn_splat_rhs_1",
            "RawParseTree" => [:masgn,
                               [:array, [:lasgn, :a], [:lasgn, :b]],
                               nil,
                               [:splat, [:vcall, :c]]])

  add_tests("masgn_splat_rhs_n",
            "RawParseTree" => [:masgn,
                               [:array, [:lasgn, :a], [:lasgn, :b]],
                               nil,
                               [:argscat,
                                [:array, [:vcall, :c], [:vcall, :d]],
                                [:vcall, :e]]])

  add_tests("masgn_splat_no_name_to_ary",
            "RawParseTree" => [:masgn,
                               [:array, [:lasgn, :a], [:lasgn, :b]],
                               [:splat],
                               [:to_ary, [:vcall, :c]]])

  add_tests("masgn_splat_no_name_trailing",
            "RawParseTree" => [:masgn,
                               [:array, [:lasgn, :a], [:lasgn, :b]], nil,
                               [:to_ary, [:vcall, :c]]]) # TODO: check this is right

  add_tests("masgn_splat_to_ary",
            "RawParseTree" => [:masgn,
                               [:array, [:lasgn, :a], [:lasgn, :b]],
                               [:lasgn, :c],
                               [:to_ary, [:vcall, :d]]])

  add_tests("masgn_splat_to_ary2",
            "RawParseTree" => [:masgn,
                               [:array, [:lasgn, :a], [:lasgn, :b]],
                               [:lasgn, :c],
                               [:to_ary,
                                [:call, [:vcall, :d], :e,
                                 [:array, [:str, 'f']]]]])

  add_tests("match",
            "RawParseTree" => [:if, [:match, [:lit, /x/]], [:lit, 1], nil])

  add_tests("match2",
            "RawParseTree" => [:match2, [:lit, /x/], [:str, "blah"]])

  add_tests("match3",
            "RawParseTree" => [:match3, [:lit, /x/], [:str, "blah"]])

  add_tests("module",
            "RawParseTree" => [:module, :X,
                               [:scope,
                                [:defn, :y,
                                 [:scope, [:block, [:args], [:nil]]]]]])

  add_tests("module_scoped",
            "RawParseTree" => [:module, [:colon2, [:const, :X], :Y],
                               [:scope, [:vcall, :c]]])

  add_tests("module_scoped3",
            "RawParseTree" => [:module, [:colon3, :Y], [:scope, [:vcall, :c]]])

  add_tests("next",
            "RawParseTree" => [:iter,
                               [:fcall, :loop],
                               nil,
                               [:if, [:false], [:next], nil]])

  add_tests("next_arg",
            "RawParseTree" => [:iter,
                               [:fcall, :loop],
                               nil,
                               [:if, [:false], [:next, [:lit, 42]], nil]])

  add_tests("not",
            "RawParseTree" => [:not, [:true]])

  add_tests("nth_ref",
            "RawParseTree" => [:nth_ref, 1])

  add_tests("op_asgn1",
            "RawParseTree" => [:block,
                               [:lasgn, :b, [:zarray]],
                               [:op_asgn1, [:lvar, :b],
                                [:array, [:lit, 1]], :"||", [:lit, 10]],
                               [:op_asgn1, [:lvar, :b],
                                [:array, [:lit, 2]], :"&&", [:lit, 11]],
                               [:op_asgn1, [:lvar, :b],
                                [:array, [:lit, 3]], :+, [:lit, 12]]])

  add_tests("op_asgn1_ivar",
            "RawParseTree" => [:block,
                               [:iasgn, :@b, [:zarray]],
                               [:op_asgn1, [:ivar, :@b],
                                [:array, [:lit, 1]], :"||", [:lit, 10]],
                               [:op_asgn1, [:ivar, :@b],
                                [:array, [:lit, 2]], :"&&", [:lit, 11]],
                               [:op_asgn1, [:ivar, :@b],
                                [:array, [:lit, 3]], :+, [:lit, 12]]])

  add_tests("op_asgn2",
            "RawParseTree" => [:block,
                               [:lasgn, :s,
                                [:call, [:const, :Struct],
                                 :new, [:array, [:lit, :var]]]],
                               [:lasgn, :c,
                                [:call, [:lvar, :s], :new, [:array, [:nil]]]],

                               [:op_asgn2, [:lvar, :c], :var=, :"||",
                                [:lit, 20]],
                               [:op_asgn2, [:lvar, :c], :var=, :"&&",
                                [:lit, 21]],
                               [:op_asgn2, [:lvar, :c], :var=, :+, [:lit, 22]],

                               [:op_asgn2,
                                [:call,
                                 [:call, [:lvar, :c], :d], :e], :f=, :"||",
                                [:lit, 42]]])

  add_tests("op_asgn2_self",
            "RawParseTree" => [:op_asgn2, [:self], :"Bag=", :"||",
                               [:call, [:const, :Bag], :new]])

  add_tests("op_asgn_and",
            "RawParseTree" => [:block,
                               [:lasgn, :a, [:lit, 0]],
                               [:op_asgn_and,
                                [:lvar, :a], [:lasgn, :a, [:lit, 2]]]])

  add_tests("op_asgn_and_ivar2",
            "RawParseTree" => [:op_asgn_and,
                               [:ivar, :@fetcher],
                               [:iasgn,
                                :@fetcher,
                                [:fcall,
                                 :new,
                                 [:array,
                                  [:call,
                                   [:call, [:const, :Gem], :configuration],
                                   :[],
                                   [:array, [:lit, :http_proxy]]]]]]])

  add_tests("op_asgn_or",
            "RawParseTree" => [:block,
                               [:lasgn, :a, [:lit, 0]],
                               [:op_asgn_or,
                                [:lvar, :a], [:lasgn, :a, [:lit, 1]]]])

  add_tests("op_asgn_or_block",
            "RawParseTree" => [:op_asgn_or,
                               [:lvar, :a],
                               [:lasgn, :a,
                                [:rescue,
                                 [:vcall, :b],
                                 [:resbody, nil, [:vcall, :c]]]]])

  add_tests("op_asgn_or_ivar",
            "RawParseTree" => [:op_asgn_or,
                               [:ivar, :@v],
                               [:iasgn, :@v, [:hash]]])

  add_tests("op_asgn_or_ivar2",
            "RawParseTree" => [:op_asgn_or,
                               [:ivar, :@fetcher],
                               [:iasgn,
                                :@fetcher,
                                [:fcall,
                                 :new,
                                 [:array,
                                  [:call,
                                   [:call, [:const, :Gem], :configuration],
                                   :[],
                                   [:array, [:lit, :http_proxy]]]]]]])

  add_tests("or",
            "RawParseTree" => [:or, [:vcall, :a], [:vcall, :b]])

  add_tests("or_big",
            "RawParseTree" => [:or,
                               [:or,  [:vcall, :a], [:vcall, :b]],
                               [:and, [:vcall, :c], [:vcall, :d]]])

  add_tests("or_big2",
            "RawParseTree" => [:or,
                               [:or,  [:vcall, :a], [:vcall, :b]],
                               [:and, [:vcall, :c], [:vcall, :d]]])

  add_tests("parse_floats_as_args",
            "RawParseTree" => [:defn, :x,
                               [:scope,
                                [:block,
                                 [:args, :a, :b,
                                  [:block,
                                   [:lasgn, :a, [:lit, 0.0]],
                                   [:lasgn, :b, [:lit, 0.0]]]],
                                 [:call, [:lvar, :a], :+,
                                  [:array, [:lvar, :b]]]]]])

  add_tests("postexe",
            "RawParseTree" => [:iter, [:postexe], nil, [:lit, 1]])

  add_tests("proc_args_0",
            "RawParseTree" => [:iter,
                               [:fcall, :proc],
                               0,
                               [:call, [:vcall, :x], :+, [:array, [:lit, 1]]]])

  add_tests("proc_args_1",
            "RawParseTree" => [:iter,
                               [:fcall, :proc],
                               [:dasgn_curr, :x],
                               [:call, [:dvar, :x], :+, [:array, [:lit, 1]]]])

  add_tests("proc_args_2",
            "RawParseTree" => [:iter,
                               [:fcall, :proc],
                               [:masgn, [:array,
                                         [:dasgn_curr, :x],
                                         [:dasgn_curr, :y]], nil, nil],
                               [:call, [:dvar, :x], :+, [:array, [:dvar, :y]]]])

  add_tests("proc_args_no",
            "RawParseTree" => [:iter,
                               [:fcall, :proc],
                               nil,
                               [:call, [:vcall, :x], :+, [:array, [:lit, 1]]]])

  add_tests("redo",
            "RawParseTree" => [:iter,
                               [:fcall, :loop], nil,
                               [:if, [:false], [:redo], nil]])

  # TODO: need a resbody w/ multiple classes and a splat

  add_tests("rescue",
            "RawParseTree" => [:rescue,
                               [:vcall, :blah], [:resbody, nil, [:nil]]])

  add_tests("rescue_block_body",
            "RawParseTree" => [:rescue,
                               [:vcall, :a],
                               [:resbody, nil,
                                [:block,
                                 [:lasgn, :e, [:gvar, :$!]],
                                 [:vcall, :c],
                                 [:vcall, :d]]]])

  add_tests("rescue_block_body_3",
            "RawParseTree" => [:rescue,
                               [:vcall, :a],
                               [:resbody, [:array, [:const, :A]],
                                [:vcall, :b],
                                [:resbody, [:array, [:const, :B]],
                                 [:vcall, :c],
                                 [:resbody, [:array, [:const, :C]],
                                  [:vcall, :d]]]]])

  add_tests("rescue_block_body_ivar",
            "RawParseTree" => [:rescue,
                               [:vcall, :a],
                               [:resbody, nil,
                                [:block,
                                 [:iasgn, :@e, [:gvar, :$!]],
                                 [:vcall, :c],
                                 [:vcall, :d]]]])

  add_tests("rescue_block_nada",
            "RawParseTree" => [:rescue, [:vcall, :blah], [:resbody, nil]])

  add_tests("rescue_exceptions",
            "RawParseTree" => [:rescue,
                               [:vcall, :blah],
                               [:resbody,
                                [:array, [:const, :RuntimeError]],
                                [:lasgn, :r, [:gvar, :$!]]]])


  add_tests("rescue_iasgn_var_empty",
            "RawParseTree" => [:rescue,
                               [:lit, 1],
                               [:resbody, nil, [:iasgn, :@e, [:gvar, :$!]]]])

  add_tests("rescue_lasgn",
            "RawParseTree" => [:rescue,
                               [:lit, 1],
                               [:resbody, nil, [:lasgn, :var, [:lit, 2]]]])

  add_tests("rescue_lasgn_var",
            "RawParseTree" => [:rescue,
                               [:lit, 1],
                               [:resbody, nil,
                                [:block,
                                 [:lasgn, :e, [:gvar, :$!]],
                                 [:lasgn, :var, [:lit, 2]]]]])

  add_tests("rescue_lasgn_var_empty",
            "RawParseTree" => [:rescue,
                               [:lit, 1],
                               [:resbody, nil, [:lasgn, :e, [:gvar, :$!]]]])

  add_tests("retry",
            "RawParseTree" => [:retry])

  add_tests("return_0",
            "RawParseTree" => [:return])

  add_tests("return_1",
            "RawParseTree" => [:return, [:lit, 1]])

  add_tests("return_1_splatted",
            "RawParseTree" => [:return, [:svalue, [:splat, [:lit, 1]]]])

  add_tests("return_n",
            "RawParseTree" => [:return, [:array,
                                         [:lit, 1], [:lit, 2], [:lit, 3]]])

  add_tests("sclass",
            "RawParseTree" => [:sclass, [:self], [:scope, [:lit, 42]]])

  add_tests("sclass_trailing_class",
            "RawParseTree" => [:class, :A, nil,
                               [:scope,
                                [:block,
                                 [:sclass, [:self], [:scope, [:vcall, :a]]],
                                 [:class, :B, nil, [:scope]]]]])

  add_tests("splat",
            "RawParseTree" => [:defn, :x,
                               [:scope,
                                [:block,
                                 [:args, :"*b"],
                                 [:fcall, :a, [:splat, [:lvar, :b]]]]]])

  add_tests("splat_array",
            "RawParseTree" => [:splat, [:array, [:lit, 1]]])

  add_tests("splat_break",
            "RawParseTree" => [:break, [:svalue, [:splat, [:array, [:lit, 1]]]]])

  add_tests("splat_break_array",
            "RawParseTree" => [:break, [:splat, [:array, [:lit, 1]]]])

  add_tests("splat_fcall",
            "RawParseTree" => [:fcall, :meth,
                               [:splat, [:array, [:lit, 1]]]])

  add_tests("splat_fcall_array",
            "RawParseTree" => [:fcall, :meth,
                               [:array, [:splat, [:array, [:lit, 1]]]]])

  add_tests("splat_lasgn",
            "RawParseTree" => [:lasgn, :x, [:svalue, [:splat, [:array, [:lit, 1]]]]])

  add_tests("splat_lasgn_array",
            "RawParseTree" => [:lasgn, :x, [:splat, [:array, [:lit, 1]]]])

  add_tests("splat_lit_1",
            "RawParseTree" => [:splat, [:lit, 1]]) # UGH - damn MRI

  add_tests("splat_lit_n",
            "RawParseTree" => [:argscat, [:array, [:lit, 1]], [:lit, 2]])

  add_tests("splat_next",
            "RawParseTree" => [:next, [:svalue, [:splat, [:array, [:lit, 1]]]]])

  add_tests("splat_next_array",
            "RawParseTree" => [:next, [:splat, [:array, [:lit, 1]]]])

  add_tests("splat_return",
            "RawParseTree" => [:return, [:svalue, [:splat, [:array, [:lit, 1]]]]])

  add_tests("splat_return_array",
            "RawParseTree" => [:return, [:splat, [:array, [:lit, 1]]]])

  add_tests("splat_super",
            "RawParseTree" => [:super, [:splat, [:array, [:lit, 1]]]])

  add_tests("splat_super_array",
            "RawParseTree" => [:super, [:array, [:splat, [:array, [:lit, 1]]]]])

  add_tests("splat_yield",
            "RawParseTree" => [:yield, [:splat, [:array, [:lit, 1]]]])

  add_tests("splat_yield_array",
            "RawParseTree" => [:yield, [:splat, [:array, [:lit, 1]]], true])

  add_tests("str",
            "RawParseTree" => [:str, "x"])

  add_tests("str_concat_newline",
            "RawParseTree" => [:str, "before after"])

  add_tests("str_concat_space",
            "RawParseTree" => [:str, "before after"])

  add_tests("str_heredoc",
            "RawParseTree" => [:str, "  blah\nblah\n"])

  add_tests("str_heredoc_call",
            "RawParseTree" => [:call, [:str, "  blah\nblah\n"], :strip])

  add_tests("str_heredoc_double",
            "RawParseTree" => [:lasgn, :a,
                               [:call,
                                [:lvar, :a],
                                :+,
                                [:array,
                                 [:call,
                                  [:call, [:str, "  first\n"], :+,
                                   [:array, [:vcall, :b]]],
                                  :+,
                                  [:array, [:str, "  second\n"]]]]]])

  add_tests("str_heredoc_empty", # yes... tarded
            "RawParseTree" => [:str, ""])

  add_tests("str_heredoc_indent",
            "RawParseTree" => [:str, "  blah\nblah\n\n"])

  add_tests("str_interp_file",
            "RawParseTree" => [:str, "file = (string)\n"])

  add_tests("structure_extra_block_for_dvar_scoping",
            "RawParseTree" => [:iter,
                               [:call, [:vcall, :a], :b],
                               [:masgn, [:array,
                                         [:dasgn_curr, :c],
                                         [:dasgn_curr, :d]], nil, nil],
                               [:if,
                                [:call, [:vcall, :e], :f,
                                 [:array, [:dvar, :c]]],
                                nil,
                                [:block,
                                 [:dasgn_curr, :g, [:false]],
                                 [:iter,
                                  [:call, [:dvar, :d], :h],
                                  [:masgn, [:array,
                                            [:dasgn_curr, :x],
                                            [:dasgn_curr, :i]], nil, nil],
                                  [:dasgn, :g, [:true]]]]]])

  add_tests("structure_remove_begin_1",
            "RawParseTree" => [:call, [:vcall, :a], :<<,
                               [:array, [:rescue, [:vcall, :b],
                                         [:resbody, nil, [:vcall, :c]]]]])

  add_tests("structure_remove_begin_2",
            "RawParseTree" => [:block,
                               [:lasgn,
                                :a,
                                [:if, [:vcall, :c],
                                 [:rescue,
                                  [:vcall, :b],
                                  [:resbody, nil, [:nil]]],
                                 nil]],
                               [:lvar, :a]])

  add_tests("structure_unused_literal_wwtt",
            "RawParseTree" => [:module, :Graffle, [:scope]])

  add_tests("super_0",
            "RawParseTree" => [:defn, :x,
                               [:scope,
                                [:block, [:args], [:super]]]])

  add_tests("super_1",
            "RawParseTree" => [:defn, :x,
                               [:scope,
                                [:block,
                                 [:args],
                                 [:super, [:array, [:lit, 4]]]]]])

  add_tests("super_1_array",
            "RawParseTree" => [:defn, :x,
                               [:scope,
                                [:block,
                                 [:args],
                                 [:super,
                                  [:array,
                                   [:array, [:lit, 24], [:lit, 42]]]]]]])

  add_tests("super_block_pass",
            "RawParseTree" => [:block_pass,
                               [:vcall, :b], [:super, [:array, [:vcall, :a]]]])

  add_tests("super_block_splat",
            "RawParseTree" => [:super,
                               [:argscat,
                                [:array, [:vcall, :a]],
                                [:vcall, :b]]])

  add_tests("super_n",
            "RawParseTree" => [:defn, :x,
                               [:scope,
                                [:block,
                                 [:args],
                                 [:super, [:array, [:lit, 24], [:lit, 42]]]]]])

  add_tests("svalue",
            "RawParseTree" => [:lasgn, :a, [:svalue, [:splat, [:vcall, :b]]]])

  add_tests("to_ary",
            "RawParseTree" => [:masgn,
                               [:array, [:lasgn, :a], [:lasgn, :b]], nil,
                               [:to_ary, [:vcall, :c]]])

  add_tests("true",
            "RawParseTree" => [:true])

  add_tests("undef",
            "RawParseTree" => [:undef, [:lit, :x]])

  add_tests("undef_2",
            "RawParseTree" => [:block,
                               [:undef, [:lit, :x]],
                               [:undef, [:lit, :y]]])

  add_tests("undef_3",
            "RawParseTree" => [:block,
                               [:undef, [:lit, :x]],
                               [:undef, [:lit, :y]],
                               [:undef, [:lit, :z]]])

  add_tests("undef_block_1",
            "RawParseTree" => [:block,
                               [:vcall, :f1],
                               [:undef, [:lit, :x]]])

  add_tests("undef_block_2",
            "RawParseTree" => [:block,
                               [:vcall, :f1],
                               [:block,
                                [:undef, [:lit, :x]],
                                [:undef, [:lit, :y]],
                               ]])

  add_tests("undef_block_3",
            "RawParseTree" => [:block,
                               [:vcall, :f1],
                               [:block,
                                [:undef, [:lit, :x]],
                                [:undef, [:lit, :y]],
                                [:undef, [:lit, :z]],
                               ]])

  add_tests("undef_block_3_post",
            "RawParseTree" => [:block,
                               [:undef, [:lit, :x]],
                               [:undef, [:lit, :y]],
                               [:undef, [:lit, :z]],
                               [:vcall, :f2]])

  add_tests("undef_block_wtf",
            "RawParseTree" => [:block,
                               [:vcall, :f1],
                               [:block,
                                [:undef, [:lit, :x]],
                                [:undef, [:lit, :y]],
                                [:undef, [:lit, :z]]],
                               [:vcall, :f2]])


  add_tests("unless_post",
            "RawParseTree" => [:if, [:vcall, :b], nil, [:vcall, :a]])

  add_tests("unless_post_not",
            "RawParseTree" => [:if, [:vcall, :b], [:vcall, :a], nil])

  add_tests("unless_pre",
            "RawParseTree" => [:if, [:vcall, :b], nil, [:vcall, :a]])

  add_tests("unless_pre_not",
            "RawParseTree" => [:if, [:vcall, :b], [:vcall, :a], nil])

  add_tests("until_post",
            "RawParseTree" => [:until, [:false],
                               [:call, [:lit, 1], :+,
                                [:array, [:lit, 1]]], false])

  add_tests("until_post_not",
            "RawParseTree" => [:while, [:true],
                               [:call, [:lit, 1], :+,
                                [:array, [:lit, 1]]], false])

  add_tests("until_pre",
            "RawParseTree" => [:until, [:false],
                               [:call, [:lit, 1], :+,
                                [:array, [:lit, 1]]], true])

  add_tests("until_pre_mod",
            "RawParseTree" => [:until, [:false],
                               [:call, [:lit, 1], :+,
                                [:array, [:lit, 1]]], true])

  add_tests("until_pre_not",
            "RawParseTree" => [:while, [:true],
                               [:call, [:lit, 1], :+,
                                [:array, [:lit, 1]]], true])

  add_tests("until_pre_not_mod",
            "RawParseTree" => [:while, [:true],
                               [:call, [:lit, 1], :+,
                                [:array, [:lit, 1]]], true])

  add_tests("valias",
            "RawParseTree" => [:valias, :$y, :$x])

  add_tests("vcall",
            "RawParseTree" => [:vcall, :method])

  add_tests("while_post",
            "RawParseTree" => [:while, [:false],
                               [:call, [:lit, 1], :+,
                                [:array, [:lit, 1]]], false])

  add_tests("while_post2",
            "RawParseTree" => [:while, [:false],
                               [:block,
                                [:call, [:lit, 1], :+, [:array, [:lit, 2]]],
                                [:call, [:lit, 3], :+, [:array, [:lit, 4]]]],
                               false])

  add_tests("while_post_not",
            "RawParseTree" => [:until, [:true],
                               [:call, [:lit, 1], :+,
                                [:array, [:lit, 1]]], false])

  add_tests("while_pre",
            "RawParseTree" => [:while, [:false],
                               [:call, [:lit, 1], :+,
                                [:array, [:lit, 1]]], true])

  add_tests("while_pre_mod",
            "RawParseTree" => [:while, [:false],
                               [:call, [:lit, 1], :+,
                                [:array, [:lit, 1]]], true]) # FIX can be one liner

  add_tests("while_pre_nil",
            "RawParseTree" => [:while, [:false], nil, true])

  add_tests("while_pre_not",
            "RawParseTree" => [:until, [:true],
                               [:call, [:lit, 1], :+,
                                [:array, [:lit, 1]]], true])

  add_tests("while_pre_not_mod",
            "RawParseTree" => [:until, [:true],
                               [:call, [:lit, 1], :+,
                                [:array, [:lit, 1]]], true]) # FIX

  add_tests("xstr",
            "RawParseTree" => [:xstr, 'touch 5'])

  add_tests("yield_0",
            "RawParseTree" => [:yield])

  add_tests("yield_1",
            "RawParseTree" => [:yield, [:lit, 42]])

  add_tests("yield_array_0",
            "RawParseTree" => [:yield, [:zarray], true])

  add_tests("yield_array_1",
            "RawParseTree" => [:yield, [:array, [:lit, 42]], true])

  add_tests("yield_array_n",
            "RawParseTree" => [:yield, [:array, [:lit, 42], [:lit, 24]], true])

  add_tests("yield_n",
            "RawParseTree" => [:yield, [:array, [:lit, 42], [:lit, 24]]])

  add_tests("zarray",
            "RawParseTree" => [:lasgn, :a, [:zarray]])

  add_tests("zsuper",
            "RawParseTree" => [:defn, :x,
                               [:scope, [:block, [:args], [:zsuper]]]])

  add_18tests("iter_args_ivar",
              "RawParseTree" => [:iter,
                                 [:fcall, :a],
                                 [:iasgn, :@a],
                                 [:lit, 42]])

  add_18tests("iter_masgn_args_ivar",
              "RawParseTree" => [:iter,
                                 [:fcall, :a],
                                 [:masgn,
                                  [:array, [:dasgn_curr, :a], [:iasgn, :@b]],
                                  nil, nil],
                                 [:lit, 42]])

  add_18tests("str_question_control",
              "RawParseTree" => [:lit, 129])

  add_18tests("str_question_escape",
              "RawParseTree" => [:lit, 10])

  add_18tests("str_question_literal",
              "RawParseTree" => [:lit, 97])
end

class TestRawParseTree < ParseTreeTestCase
  def setup
    super
    @processor = RawParseTree.new(false)
  end

  def test_parse_tree_for_string_with_newlines
    @processor = RawParseTree.new(true)
    actual   = @processor.parse_tree_for_string "1 +\n nil", 'test.rb', 5
    expected = [[:newline, 6, "test.rb",
                 [:call, [:lit, 1], :+, [:array, [:nil]]]]]

    assert_equal expected, actual
  end

  def test_class_initialize
    expected = [[:class, :SomethingWithInitialize, [:const, :Object],
      [:defn, :initialize, [:scope, [:block, [:args], [:nil]]]],
      [:defn, :protected_meth, [:scope, [:block, [:args], [:nil]]]],
    ]]
    tree = @processor.parse_tree SomethingWithInitialize
    assert_equal expected, tree
  end

  def test_class_translate_string
    str = "class A; def a; end; end"

    sexp = ParseTree.translate str

    expected = [:class, :A, nil,
                 [:scope,
                   [:defn, :a, [:scope, [:block, [:args], [:nil]]]]]]

    assert_equal expected, sexp
  end

  def test_class_translate_string_method
    str = "class A; def a; end; def b; end; end"

    sexp = ParseTree.translate str, :a

    expected = [:defn, :a, [:scope, [:block, [:args], [:nil]]]]

    assert_equal expected, sexp
  end

  def test_parse_tree_for_string
    actual   = @processor.parse_tree_for_string '1 + nil', '(string)', 1
    expected = [[:call, [:lit, 1], :+, [:array, [:nil]]]]

    assert_equal expected, actual
  end

  def test_parse_tree_for_str
    actual   = @processor.parse_tree_for_str '1 + nil', '(string)', 1
    expected = [[:call, [:lit, 1], :+, [:array, [:nil]]]]

    assert_equal expected, actual
  end

  @@self_classmethod = [:defs,
                        [:self], :classmethod,
                        [:scope,
                         [:block,
                          [:args],
                          [:call, [:lit, 1], :+, [:array, [:lit, 1]]]]]]

  @@missing = [nil]

  @@opt_args = [:defn, :opt_args,
                [:scope,
                 [:block,
                  [:args, :arg1, :arg2, :"*args",
                   [:block, [:lasgn, :arg2, [:lit, 42]]]],
                  [:lasgn, :arg3,
                   [:call,
                    [:call,
                     [:lvar, :arg1],
                     :*,
                     [:array, [:lvar, :arg2]]],
                    :*,
                    [:array, [:lit, 7]]]],
                  [:fcall, :puts, [:array, [:call, [:lvar, :arg3], :to_s]]],
                  [:return,
                   [:str, "foo"]]]]]

  @@multi_args = [:defn, :multi_args,
                  [:scope,
                   [:block,
                    [:args, :arg1, :arg2],
                    [:lasgn, :arg3,
                     [:call,
                      [:call,
                       [:lvar, :arg1],
                       :*,
                       [:array, [:lvar, :arg2]]],
                      :*,
                      [:array, [:lit, 7]]]],
                    [:fcall, :puts, [:array, [:call, [:lvar, :arg3], :to_s]]],
                    [:return,
                     [:str, "foo"]]]]]

  @@unknown_args = [:defn, :unknown_args,
                    [:scope,
                     [:block,
                      [:args, :arg1, :arg2],
                      [:return, [:lvar, :arg1]]]]]

  @@bbegin = [:defn, :bbegin,
              [:scope,
               [:block,
                [:args],
                [:ensure,
                 [:rescue,
                  [:lit, 1],
                  [:resbody,
                   [:array, [:const, :SyntaxError]],
                   [:block, [:lasgn, :e1, [:gvar, :$!]], [:lit, 2]],
                   [:resbody,
                    [:array, [:const, :Exception]],
                    [:block, [:lasgn, :e2, [:gvar, :$!]], [:lit, 3]]]],
                  [:lit, 4]],
                 [:lit, 5]]]]]

  @@bbegin_no_exception = [:defn, :bbegin_no_exception,
                           [:scope,
                            [:block,
                             [:args],
                             [:rescue,
                              [:lit, 5],
                              [:resbody, nil, [:lit, 6]]]]]]

  @@determine_args = [:defn, :determine_args,
                      [:scope,
                       [:block,
                        [:args],
                        [:call,
                         [:lit, 5],
                         :==,
                         [:array,
                          [:fcall,
                           :unknown_args,
                           [:array, [:lit, 4], [:str, "known"]]]]]]]]

  @@attrasgn = [:defn,
                :attrasgn,
                [:scope,
                 [:block,
                  [:args],
                  [:attrasgn, [:lit, 42], :method=, [:array, [:vcall, :y]]],
                  [:attrasgn,
                   [:self],
                   :type=,
                   [:array, [:call, [:vcall, :other], :type]]]]]]

  @@__all = [:class, :Something, [:const, :Object]]

  Something.instance_methods(false).sort.each do |meth|
    if class_variables.include?("@@#{meth}") then
      @@__all << eval("@@#{meth}")
      eval "def test_#{meth}; assert_equal @@#{meth}, @processor.parse_tree_for_method(Something, :#{meth}, false, false); end"
    else
      eval "def test_#{meth}; flunk \"You haven't added @@#{meth} yet\"; end"
    end
  end

  Something.singleton_methods.sort.each do |meth|
    next if meth =~ /yaml/ # rubygems introduced a bug
    if class_variables.include?("@@self_#{meth}") then
      @@__all << eval("@@self_#{meth}")
      eval "def test_self_#{meth}; assert_equal @@self_#{meth}, @processor.parse_tree_for_method(Something, :#{meth}, true); end"
    else
      eval "def test_self_#{meth}; flunk \"You haven't added @@self_#{meth} yet\"; end"
    end
  end

  def test_missing
    assert_equal(@@missing,
                 @processor.parse_tree_for_method(Something, :missing),
                 "Must return #{@@missing.inspect} for missing methods")
  end

  def test_whole_class
    assert_equal([@@__all],
                 @processor.parse_tree(Something),
                 "Must return a lot of shit")
  end

  def test_process_modules
    exp = [[:module, :Mod1, [:defn, :mod_method, [:bmethod, nil]]]]
    assert_equal exp, @processor.parse_tree(Mod1)

    exp = [[:module, :Mod2, [:fcall, :include, [:array, [:const, :Mod1]]]]]
    assert_equal exp, @processor.parse_tree(Mod2)

    exp = [[:class, :ClassInclude, [:const, :Object],
            [:fcall, :include, [:array, [:const, :Mod2]]]]]
    assert_equal exp, @processor.parse_tree(ClassInclude)
  end
end

class TestParseTree < ParseTreeTestCase
  def setup
    super
    @processor = ParseTree.new(false)
  end

  def test_process_string
    actual   = @processor.process '1 + nil'
    expected = s(:call, s(:lit, 1), :+, s(:arglist, s(:nil)))

    assert_equal expected, actual

    actual   = @processor.process 'puts 42'
    expected = s(:call, nil, :puts, s(:arglist, s(:lit, 42)))

    assert_equal expected, actual
  end

  def test_process_string_newlines
    @processor = ParseTree.new(true)
    actual   = @processor.process "1 +\n nil", false, 'test.rb', 5
    expected = s(:newline, 6, "test.rb",
                 s(:call, s(:lit, 1), :+, s(:arglist, s(:nil))))

    assert_equal expected, actual
  end

  # TODO: test_process_proc ?
  # TODO: test_process_method ?
  # TODO: test_process_class ?
  # TODO: test_process_module ?

end
