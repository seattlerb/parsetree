ParseTree
    http://www.zenspider.com/ZSS/Products/ParseTree/
    support@zenspider.com

** DESCRIPTION:
  
ParseTree is a C extension (using RubyInline) that extracts the parse
tree for an entire class or a specific method and returns it as a
s-expression (aka sexp) using ruby's arrays, strings, symbols, and
integers. 

As an example:

  def conditional1(arg1)
    if arg1 == 0 then
      return 1
    end
    return 0
  end

becomes:

  [:defn,
    "conditional1",
    [:scope,
     [:block,
      [:args, "arg1"],
      [:if,
       [:call, [:lvar, "arg1"], "==", [:array, [:lit, 0]]],
       [:return, [:lit, 1]],
       nil],
      [:return, [:lit, 0]]]]]

** FEATURES/PROBLEMS:
  
+ Uses RubyInline, so it just drops in.
+ Includes show.rb, which lets you quickly snoop code.
+ Includes abc.rb, which lets you get abc metrics on code.
	+ abc metrics = numbers of assignments, branches, and calls.
	+ whitespace independent metric for method complexity.
+ Only works on methods in classes/modules, not arbitrary code.
+ Does not work on the core classes, as they are not ruby (yet).

** SYNOPSYS:

  sexp_array = ParseTree.new.parse_tree(klass)

or:

  % ./parse_tree_show myfile.rb

or:

  % ./parse_tree_abc myfile.rb

** REQUIREMENTS:

+ RubyInline 3 or better.

** INSTALL:

+ sudo make install
	+ renames show.rb to parse_tree_show
	+ renames abc.rb to parse_tree_abc

** LICENSE:

(The MIT License)

Copyright (c) 2001-2004 Ryan Davis, Zen Spider Software

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
