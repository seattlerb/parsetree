RUBY?=ruby
RUBY_FLAGS?=-w -I.
RUBY_LIB?=$(shell $(RUBY) -rrbconfig -e 'include Config; print CONFIG["sitelibdir"]')
PREFIX?=/usr/local

all test:
	$(RUBY) $(RUBY_FLAGS) test_all.rb

# we only install test_sexp_processor.rb to help make ruby_to_c's
# subclass tests work.

install:
	cp -f parse_tree.rb test_sexp_processor.rb sexp_processor.rb composite_sexp_processor.rb $(RUBY_LIB)
	cp -f show.rb $(PREFIX)/bin/parse_tree_show
	cp -f abc.rb $(PREFIX)/bin/parse_tree_abc
	chmod 444 $(RUBY_LIB)/parse_tree.rb $(RUBY_LIB)/sexp_processor.rb $(RUBY_LIB)/composite_sexp_processor.rb $(RUBY_LIB)/test_sexp_processor.rb
	chmod 555 $(PREFIX)/bin/parse_tree_show $(PREFIX)/bin/parse_tree_abc

uninstall:
	rm -f $(RUBY_LIB)/parse_tree.rb $(RUBY_LIB)/sexp_processor.rb $(RUBY_LIB)/composite_sexp_processor.rb $(RUBY_LIB)/test_sexp_processor.rb
	rm -f $(PREFIX)/bin/parse_tree_show $(PREFIX)/bin/parse_tree_abc

clean:
	rm -f *~ diff.txt
