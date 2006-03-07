require 'rbconfig'
require 'rake/rdoctask'

PREFIX = ENV['PREFIX'] || Config::CONFIG['prefix']
RUBYLIB = Config::CONFIG['sitelibdir']
RUBY_DEBUG = ENV['RUBY_DEBUG']
RUBY_FLAGS = ENV['RUBY_FLAGS'] || "-w -Ilib#{File::PATH_SEPARATOR}bin#{File::PATH_SEPARATOR}../../RubyInline/dev"
FILTER = ENV['FILTER']

LIB_FILES = %w(composite_sexp_processor.rb parse_tree.rb sexp.rb sexp_processor.rb)
TEST_FILES = %w(test_sexp_processor.rb)
BIN_FILES = %w(parse_tree_abc parse_tree_show parse_tree_deps)

task :default => :test

task :test do
  ruby "#{RUBY_FLAGS} test/test_all.rb #{FILTER}"
end

# we only install test_sexp_processor.rb to help make ruby_to_c's
# subclass tests work.

Rake::RDocTask.new(:docs) do |rd|
  rd.main = "SexpProcessor"
  rd.rdoc_files.include('./**/*').exclude('something.rb').exclude('test_*')
  rd.options << '-d'
  rd.options << '-Ipng'
end

task :install do
  [
   ['lib', LIB_FILES, RUBYLIB, 0444],
   ['test', TEST_FILES, RUBYLIB, 0444],
   ['bin', BIN_FILES, File.join(PREFIX, 'bin'), 0555]
  ].each do |dir, list, dest, mode|
    Dir.chdir dir do
      list.each do |f|
        install f, dest, :mode => mode
      end
    end
  end
end

task :uninstall do
  Dir.chdir RUBYLIB do
    rm_f LIB_FILES
    rm_f TEST_FILES
  end
  Dir.chdir File.join(PREFIX, 'bin') do
    rm_f BIN_FILES
  end
end

task :audit do
  sh "ZenTest -Ilib#{File::PATH_SEPARATOR}test #{LIB_FILES.collect{|e| File.join('lib', e)}.join(' ')} test/test_all.rb"
  # test_composite_sexp_processor.rb test_sexp_processor.rb
end

task :clean do
  Dir['**/*~'].each{|e| rm_f e}
  rm_rf %w(diff diff.txt demo.rb).concat(Dir['*.gem']).concat([File.join(ENV['HOME'], '.ruby_inline')])
end

task :demo do
  verbose(false){sh "echo 1+1 | ruby #{RUBY_FLAGS} ./bin/parse_tree_show -f"}
end

task :gem do
  ruby "ParseTree.gemspec"
end
