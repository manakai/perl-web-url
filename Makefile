HARUSAME = harusame
POD2HTML = pod2html --css "http://suika.fam.cx/www/style/html/pod.css" \
  --htmlroot "../.."
SED = sed
GIT = git

all: config/perl/libs.txt \
  doc/README.ja.html doc/README.en.html \
  lib/Web/URL/Canonicalize.html \
  lib/Web/IPAddr/Canonicalize.html \
  lib/Web/DomainName/Canonicalize.html \
  lib/Web/DomainName/IDNEnabled.html

## ------ Deps ------

WGET = wget

deps: pmbp-install

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

## ------ Documents ------

doc/README.en.html: doc/README.html.src
	$(HARUSAME) --lang en < $< > $@

doc/README.ja.html: doc/README.html.src
	$(HARUSAME) --lang ja < $< > $@

%.html: %.pod
	$(POD2HTML) $< | $(SED) -e 's/<link rev="made" href="mailto:[^"]\+" \/>/<link rel=author href="#author">/' > $@

lib/Web/DomainName/IDNEnabled.html: %.html: %.pm
	$(POD2HTML) $< | $(SED) -e 's/<link rev="made" href="mailto:[^"]\+" \/>/<link rel=author href="#author">/' > $@

## ------ Tests ------

PERL = ./perl

test: test-deps show-perl-version show-unicore-version test-main

test-deps: deps

show-perl-version:
	$(PERL) -v

show-unicore-version: config/perl/libs.txt
	echo "Unicode version of Perl is..."
	$(PERL) -e 'print [grep { -f $$_ } map { "$$_/unicore/version" } @INC]->[0]' | xargs cat

test-main:
	cd t && $(MAKE) test

## ------ Distribution ------

GENERATEPM = local/generatepm/bin/generate-pm-package
GENERATEPM_ = $(GENERATEPM) --generate-json

dist: generatepm
	mkdir -p dist
	$(GENERATEPM_) config/dist/web-domainname-canonicalize.pi dist
	$(GENERATEPM_) config/dist/web-domainname-idnenabled.pi dist
	$(GENERATEPM_) config/dist/web-domainname-punycode.pi dist
	$(GENERATEPM_) config/dist/web-ipaddr-canonicalize.pi dist
	$(GENERATEPM_) config/dist/web-url-canonicalize.pi dist

dist-wakaba-packages: local/wakaba-packages dist
	cp dist/*.json local/wakaba-packages/data/perl/
	cp dist/*.tar.gz local/wakaba-packages/perl/
	cd local/wakaba-packages && $(MAKE) all

local/wakaba-packages: always
	git clone "git@github.com:wakaba/packages.git" $@ || (cd $@ && git pull)
	cd $@ && git submodule update --init

## ------ Auto update of data ------

dataautoupdate:
	cd lib/Web/DomainName && $(MAKE) clean-for-update && $(MAKE) all
	git add lib/Web/DomainName/IDNEnabled.pm

always:

## License: Public Domain.
