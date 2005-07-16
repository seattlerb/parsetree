RUBY?=ruby
RUBY_DEBUG?=
RUBY_FLAGS?=-w -Ilib:bin:../../RubyInline/dev
RUBY_LIB?=$(shell $(RUBY) -rrbconfig -e 'include Config; print CONFIG["sitelibdir"]')
PREFIX?=/usr/local

all test: FORCE
	$(RUBY) $(RUBY_DEBUG) $(RUBY_FLAGS) test/test_all.rb

# we only install test_sexp_processor.rb to help make ruby_to_c's
# subclass tests work.

docs:
	rdoc -d -I png --main SexpProcessor -x test_\* -x something.rb

install:
	install -m 0444 lib/parse_tree.rb lib/sexp_processor.rb lib/composite_sexp_processor.rb test/test_sexp_processor.rb $(RUBY_LIB)
	install -m 0555 bin/parse_tree_show bin/parse_tree_abc  $(PREFIX)/bin

uninstall:
	cd $(RUBY_LIB) && rm -f parse_tree.rb sexp_processor.rb composite_sexp_processor.rb test_sexp_processor.rb
	cd $(PREFIX)/bin && rm -f parse_tree_show parse_tree_abc

audit:
	ZenTest composite_sexp_processor.rb sexp_processor.rb test_all.rb test_composite_sexp_processor.rb test_sexp_processor.rb

clean:
	-find . -name \*~ | xargs rm
	-rm -fr diff diff.txt *.gem doc $$HOME/.ruby_inline

demo:
	echo 1+1 | $(RUBY) $(RUBY_FLAGS) ./bin/parse_tree_show -f

gem:
	ruby ParseTree.gemspec

FORCE:
