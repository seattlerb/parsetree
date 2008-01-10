# -*- ruby -*-

require 'rubygems'
require 'hoe'

$: << "../../RubyInline/dev/lib"
require './lib/parse_tree.rb'

Hoe.new("ParseTree", ParseTree::VERSION) do |p|
  p.rubyforge_name = "parsetree"
  p.summary = "Extract and enumerate ruby parse trees."
  p.summary = p.paragraphs_of("README.txt", 2).join("\n\n")
  p.description = p.paragraphs_of("README.txt", 2..6, 8).join("\n\n")
  p.changes = p.paragraphs_of("History.txt", 0..2).join("\n\n")
  p.clean_globs << File.expand_path("~/.ruby_inline")
  p.extra_deps << ['RubyInline', '>= 3.6.0']
  p.spec_extras[:require_paths] = proc { |paths| paths << 'xtest' }
end

Hoe::RUBY_FLAGS.sub! /-I/, '-I../../RubyInline/dev/lib:test:'

desc 'Run in gdb'
task :debug do
  puts "RUN: r -d #{Hoe::RUBY_FLAGS} test/test_all.rb #{Hoe::FILTER}"
  sh "gdb ~/.multiruby/install/19/bin/ruby"
end

desc 'Run a very basic demo'
task :demo do
  sh "echo 1+1 | ruby #{Hoe::RUBY_FLAGS} ./bin/parse_tree_show -f"
end
