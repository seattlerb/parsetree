RUBY?=ruby
RUBY_FLAGS?=-w -I.
RUBY_LIB?=$(shell $(RUBY) -rrbconfig -e 'include Config; print CONFIG["sitelibdir"]')
PREFIX?=/usr/local

all test:
	$(RUBY) $(RUBY_FLAGS) test_parse_tree.rb

install:
	cp -f parse_tree.rb $(RUBY_LIB)
	cp -f show.rb $(PREFIX)/bin/parse_tree_show
	cp -f abc.rb $(PREFIX)/bin/parse_tree_abc
	chmod 444 $(RUBY_LIB)/parse_tree.rb
	chmod 555 $(PREFIX)/bin/parse_tree_show $(PREFIX)/bin/parse_tree_abc

uninstall:
	rm -f $(RUBY_LIB)/parse_tree.rb
	rm -f $(PREFIX)/bin/parse_tree_show $(PREFIX)/bin/parse_tree_abc

clean:
	rm -f *~ diff.txt
