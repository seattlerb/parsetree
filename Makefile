RUBY?=ruby
RUBY_FLAGS?=-w -Ilib
RUBY_LIB?=$(shell $(RUBY) -rrbconfig -e 'include Config; print CONFIG["sitelibdir"]')
PREFIX?=/usr/local

all test: FORCE
	$(RUBY) $(RUBY_FLAGS) test/test_all.rb

# we only install test_sexp_processor.rb to help make ruby_to_c's
# subclass tests work.

docs:
	rdoc -d -I png --main SexpProcessor -x test_\* -x something.rb

install:
	cp -f lib/parse_tree.rb lib/sexp_processor.rb lib/composite_sexp_processor.rb $(RUBY_LIB)
	cp -f test/test_sexp_processor.rb $(RUBY_LIB)
	cp -f bin/parse_tree_show $(PREFIX)/bin
	cp -f bin/parse_tree_abc  $(PREFIX)/bin
	chmod 444 $(RUBY_LIB)/parse_tree.rb $(RUBY_LIB)/sexp_processor.rb $(RUBY_LIB)/composite_sexp_processor.rb $(RUBY_LIB)/test_sexp_processor.rb
	chmod 555 $(PREFIX)/bin/parse_tree_show $(PREFIX)/bin/parse_tree_abc

uninstall:
	rm -f $(RUBY_LIB)/parse_tree.rb $(RUBY_LIB)/sexp_processor.rb $(RUBY_LIB)/composite_sexp_processor.rb $(RUBY_LIB)/test_sexp_processor.rb
	rm -f $(PREFIX)/bin/parse_tree_show $(PREFIX)/bin/parse_tree_abc

audit:
	ZenTest composite_sexp_processor.rb sexp_processor.rb test_all.rb test_composite_sexp_processor.rb test_sexp_processor.rb

clean:
	-find . -name \*~ | xargs rm
	-rm -f diff diff.txt
	-rm -r $$HOME/.ruby_inline
	-rm -r doc

demo:
	echo 1+1 | $(RUBY) $(RUBY_FLAGS) ./bin/parse_tree_show -f

gem:
	gem ParseTree.gemspec

FORCE:
