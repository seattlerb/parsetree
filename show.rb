#!/usr/local/bin/ruby -w

require 'pp'
require 'parse_tree'

old_classes = []
ObjectSpace.each_object(Module) do |klass|
  old_classes << klass
end

unless ARGV.empty? then
  ARGV.each do |name|
    if name == "-" then
      eval $stdin.read
    else
      require name
    end
  end
else
  eval $stdin.read
end

new_classes = []
ObjectSpace.each_object(Module) do |klass|
  new_classes << klass
end

new_classes -= old_classes

new_classes.each do |klass|
  pp ParseTree.new.parse_tree(klass)
end
