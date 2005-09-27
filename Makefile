RUBY?=ruby
RUBY_DEBUG?=
RUBY_FLAGS?=-w -Ilib:bin:../../RubyInline/dev
RUBY_LIB?=$(shell $(RUBY) -rrbconfig -e 'include Config; print CONFIG["sitelibdir"]')
PREFIX?=/usr/local
FILTER?=

LIB_FILES= \
	composite_sexp_processor.rb \
	parse_tree.rb \
	sexp.rb \
	sexp_processor.rb \
	$(END)

TEST_FILES= \
	test_sexp_processor.rb \
	$(END)

BIN_FILES= \
	parse_tree_abc \
	parse_tree_show \
	parse_tree_deps \
	$(END)

all test: FORCE
	$(RUBY) $(RUBY_DEBUG) $(RUBY_FLAGS) test/test_all.rb $(FILTER)

# we only install test_sexp_processor.rb to help make ruby_to_c's
# subclass tests work.

docs:
	rdoc -d -I png --main SexpProcessor -x test_\* -x something.rb

install:
	cd lib  && install -m 0444 $(LIB_FILES)  $(RUBY_LIB)
	cd test && install -m 0444 $(TEST_FILES) $(RUBY_LIB)
	cd bin  && install -m 0555 $(BIN_FILES)  $(PREFIX)/bin

uninstall:
	cd $(RUBY_LIB)   && rm -f $(LIB_FILES) $(TEST_FILES)
	cd $(PREFIX)/bin && rm -f $(BIN_FILES)

audit:
	ZenTest -I=lib:test $(addprefix lib/,$(LIB_FILES)) test/test_all.rb
# test_composite_sexp_processor.rb test_sexp_processor.rb

clean:
	-find . -name \*~ | xargs rm
	-rm -fr diff diff.txt *.gem doc $$HOME/.ruby_inline

demo:
	echo 1+1 | $(RUBY) $(RUBY_FLAGS) ./bin/parse_tree_show -f

gem:
	ruby ParseTree.gemspec

FORCE:
