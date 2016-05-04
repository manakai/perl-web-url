GIT = git

all:

clean: clean-json-ps
	rm -fr local/tlds.json

updatenightly: clean local/bin/pmbp.pl build
	git add lib
	curl https://gist.githubusercontent.com/wakaba/34a71d3137a52abb562d/raw/gistfile1.txt | sh
	git add modules t_deps/modules
	perl local/bin/pmbp.pl --update
	git add config

## ------ Deps ------

WGET = wget

deps: git-submodules pmbp-install

local/bin/pmbp.pl:
	mkdir -p local/bin
	$(WGET) -O $@ https://raw.github.com/wakaba/perl-setupenv/master/bin/pmbp.pl
pmbp-upgrade: local/bin/pmbp.pl
	perl local/bin/pmbp.pl --update-pmbp-pl
pmbp-update: pmbp-upgrade
	perl local/bin/pmbp.pl --update
pmbp-install: pmbp-upgrade
	perl local/bin/pmbp.pl --install \
            --create-perl-command-shortcut perl \
            --create-perl-command-shortcut prove

git-submodules:
	$(GIT) submodule update --init
json-ps: local/perl-latest/pm/lib/perl5/JSON/PS.pm
clean-json-ps:
	rm -fr local/perl-latest/pm/lib/perl5/JSON/PS.pm
local/perl-latest/pm/lib/perl5/JSON/PS.pm:
	mkdir -p local/perl-latest/pm/lib/perl5/JSON
	$(WGET) -O $@ https://raw.githubusercontent.com/wakaba/perl-json-ps/master/lib/JSON/PS.pm

deps-harusame: local/bin/pmbp.pl
	perl local/bin/pmbp.pl --install-perl-app https://github.com/wakaba/harusame

## ------ Build ------

build: deps json-ps deps-harusame \
  doc/README.ja.html doc/README.en.html

local/tlds.json:
	$(WGET) -O $@ https://raw.githubusercontent.com/manakai/data-web-defs/master/data/tlds.json

lib/Web/DomainName/IDNEnabled.pm: local/tlds.json bin/idnenabled.pl
	$(PERL) bin/idnenabled.pl > $@

## ------ Tests ------

PERL = ./perl

test: test-deps show-perl-version show-unicore-version test-main

test-deps: deps

show-perl-version:
	$(PERL) -v

show-unicore-version: deps
	echo "Unicode version of Perl is..."
	$(PERL) -e 'print [grep { -f $$_ } map { "$$_/unicore/version" } @INC]->[0]' | xargs cat

test-main:
	cd t && $(MAKE) test

always:

## License: Public Domain.
