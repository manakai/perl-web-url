GIT = git
WGET = wget
CURL = curl

all:

clean: clean-json-ps
	rm -fr local/*.json

updatenightly: clean local/bin/pmbp.pl build
	git add lib
	curl https://gist.githubusercontent.com/wakaba/34a71d3137a52abb562d/raw/gistfile1.txt | sh
	git add modules t_deps/modules
	perl local/bin/pmbp.pl --update
	git add config
	$(CURL) -sSLf https://raw.githubusercontent.com/wakaba/ciconfig/master/ciconfig | RUN_GIT=1 REMOVE_UNUSED=1 perl

## ------ Deps ------

PERL = ./perl
PERLT = $(PERL)
PROVE = ./prove

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

## ------ Build ------

build: deps json-ps build-main

build-main: lib/Web/DomainName/IDNEnabled.pm lib/Web/URL/_Defs.pm \
    lib/Web/DomainName/_CharClasses.pm lib/Web/DomainName/_CharMaps.pm

local/tlds.json:
	$(WGET) -O $@ https://raw.githubusercontent.com/manakai/data-web-defs/master/data/tlds.json
local/url-schemes.json:
	$(WGET) -O $@ https://raw.githubusercontent.com/manakai/data-web-defs/master/data/url-schemes.json

lib/Web/DomainName/IDNEnabled.pm: bin/idnenabled.pl local/tlds.json
	$(PERLT) $< > $@
lib/Web/URL/_Defs.pm: bin/generate-url-defs.pl local/url-schemes.json
	$(PERLT) $< > $@

lib/Web/DomainName/_CharClasses.pm:
	echo 'package Web::DomainName::Canonicalize;' > $@;
	$(CURL) -f -l https://chars.suikawiki.org/set/perlrevars?item=InDisallowed=%24uts46%3Adisallowed >> $@
	$(CURL) -f -l https://chars.suikawiki.org/set/perlrevars?item=InDeviation=%24uts46%3Adeviation >> $@
	$(CURL) -f -l https://chars.suikawiki.org/set/perlrevars?item=InIgnoredOrMapped=%24uts46%3Aignored%7C%24uts46%3Amapped%7C%24uts46%3Adisallowed_STD3_mapped >> $@
	$(CURL) -f -l https://chars.suikawiki.org/set/perlrevars?item=InBadLabel=-%24uts46%3Avalid%7C%5B%2E%5D-%24uts46%3Adisallowed_STD3_valid%20-%24uts46%3Adisallowed_STD3_mapped >> $@
	$(CURL) -f -l https://chars.suikawiki.org/set/perlrevars?item=InBadLabelStart=%24unicode%3AM >> $@
	echo '1;' >> $@
	$(PERL) -c $@

local/maps.json:
	$(WGET) -O $@ https://raw.githubusercontent.com/manakai/data-chars/master/data/maps.json
lib/Web/DomainName/_CharMaps.pm: bin/generate-charmaps.pl local/maps.json
	$(PERL) $< > $@

## ------ Tests ------

test: test-deps show-perl-version show-unicore-version test-main

test-deps: deps json-ps

show-perl-version:
	$(PERL) -v

show-unicore-version: deps
	echo "Unicode version of Perl is..."
	$(PERL) -e 'print [grep { -f $$_ } map { "$$_/unicore/version" } @INC]->[0]' | xargs cat

test-main:
	$(PROVE) t/*.t

always:

## License: Public Domain.
