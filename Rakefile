# -*- ruby -*-

require 'rubygems'
require 'hoe'

Hoe.add_include_dirs("../../RubyInline/dev/lib",
                     "../../sexp_processor/3.2.0/lib",
                     "../../ZenTest/dev/lib",
                     "lib")

Hoe.plugin :seattlerb

Hoe.spec "ParseTree" do
  developer 'Ryan Davis', 'ryand-ruby@zenspider.com'

  clean_globs << File.expand_path("~/.ruby_inline")

  dependency 'RubyInline',     '~> 3.9.0'
  dependency 'sexp_processor', '~> 3.2.0'

  spec_extras[:require_paths] = proc { |paths| paths << 'test' }

  multiruby_skip << "1.9" << "trunk"
end

task :test => :clean

desc 'Run in gdb'
task :debug do
  puts "RUN: r -d #{Hoe::RUBY_FLAGS} test/test_all.rb #{Hoe::FILTER}"
  sh "gdb ~/.multiruby/install/19/bin/ruby"
end

desc 'Run a very basic demo'
task :demo do
  sh "echo 1+1 | ruby #{Hoe::RUBY_FLAGS} ./bin/parse_tree_show -f"
end
