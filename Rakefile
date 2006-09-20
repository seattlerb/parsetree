# -*- ruby -*-

require 'rubygems'
require 'hoe'

$: << "../../RubyInline/dev"
require './lib/parse_tree.rb'

Hoe.new("ParseTree", ParseTree::VERSION) do |p|
  p.summary = "Extract and enumerate ruby parse trees."
  p.description = File.read("README.txt").split(/\n\n+/)[2]
  p.clean_globs << File.expand_path("~/.ruby_inline")
  p.extra_deps << ['RubyInline', '>= 3.2.0']
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
