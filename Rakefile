# -*- ruby -*-

require 'rubygems'
require 'hoe'

$: << "../../RubyInline/dev"
require './lib/parse_tree.rb'

Hoe.new("ParseTree", ParseTree::VERSION) do |p|
  p.rubyforge_name = "parsetree"
  p.summary = "Extract and enumerate ruby parse trees."
  p.summary = p.paragraphs_of("README.txt", 2).join("\n\n")
  p.description = p.paragraphs_of("README.txt", 2..6, 8).join("\n\n")
  p.changes = p.paragraphs_of("History.txt", 0..2).join("\n\n")
  p.clean_globs << File.expand_path("~/.ruby_inline")
  p.extra_deps << ['RubyInline', '>= 3.6.0']
  p.spec_extras[:require_paths] = proc { |paths| paths << 'test' }
end

desc 'Run against ruby 1.9 (from a multiruby install) with -d.'
task :test19 do
  sh "~/.multiruby/install/1_9/bin/ruby -d #{Hoe::RUBY_FLAGS} test/test_all.rb #{Hoe::FILTER}"
end

desc 'Run in gdb'
task :debug do
  puts "RUN: r -d #{Hoe::RUBY_FLAGS} test/test_all.rb #{Hoe::FILTER}"
  sh "gdb ~/.multiruby/install/19/bin/ruby"
end

desc 'Run a very basic demo'
task :demo do
  sh "echo 1+1 | ruby #{Hoe::RUBY_FLAGS} ./bin/parse_tree_show -f"
end

desc 'Show what tests are not sorted'
task :sort do
  begin
    sh "pgrep '^    \\\"(\\w+)' test/pt_testcase.rb | cut -f 2 -d\\\" > x"
    sh "sort x > y"
    sh "diff x y"

    sh 'for f in lib/*.rb; do echo $f; grep "^ *def " $f | grep -v sort=skip > x; sort x > y; echo $f; echo; diff x y; done'
    sh 'for f in test/test_*.rb; do echo $f; grep "^ *def.test_" $f > x; sort x > y; echo $f; echo; diff x y; done'
  ensure
    sh 'rm -f x y'
  end
end
