# -*- ruby -*-

require 'rubygems'
$: << "./lib"
require 'parse_tree'

spec = Gem::Specification.new do |s|

  s.name = 'ParseTree'
  s.version = ParseTree::VERSION
  s.summary = "Extract and enumerate ruby parse trees."

  paragraphs = File.read("README.txt").split(/\n\n+/)
  s.description = paragraphs[2]
  puts "Description = #{s.description}"

  s.requirements << "RubyInline."
  s.files = IO.readlines("Manifest.txt").map {|f| f.chomp }
  p s.files

  s.require_path = 'lib' 
  s.autorequire = 'parse_tree'

  s.bindir = "bin"
  s.executables = s.files.grep(Regexp.new(s.bindir)) { |f| File.basename(f) }
  p s.bindir
  p s.executables

  s.has_rdoc = true
  s.test_suite_file = "test/test_all.rb"

  s.author = "Ryan Davis"
  s.email = "ryand-ruby@zenspider.com"
  s.homepage = "http://www.zenspider.com/ZSS/Products/ParseTree/"
  s.rubyforge_project = "parsetree"
end

if $0 == __FILE__
  Gem.manage_gems
  Gem::Builder.new(spec).build
end
