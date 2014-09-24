Web::URL::Canonicalize - Perl URL Canonicalizer
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* Perl modules

- Web::URL::Canonicalize (lib/Web/URL/Canonicalize.pm)
- Web::DomainName::Canonicalize (lib/Web/DomainName/Canonicalize.pm)
- Web::DomainName::IDNEnabled (lib/Web/DomainName/IDNEnabled.pm)
- Web::IPAddr::Canonicalize (lib/IPAddr/Canonicalize.pm)

* Spec

- sketch/spec.txt

* Tests

- t/data/*.dat - URL canonicalization tests
- t/data/generated/*.dat - IDN in URL canonicalization tests

- t/*.t - Test harnesses for Perl modules
- t/browsers/*.html - Test harnesses for testing your browser

** Test results of browsers

- URL canonicalization tests (about 5000)
-- <http://suika.fam.cx/gate/test-results/list/url-canon-20110731/all>
- Query character encoding tests (28)
-- <http://suika.fam.cx/gate/test-results/list/url-canon-20110731-charsets/all>
- IDN canonicalization tests (about 14000)
-- <http://suika.fam.cx/gate/test-results/list/url-canon-20110731-idn/all>

* Distribution

Latest version of these files are available from Git repositories:

- <https://github.com/manakai/perl-web-url>

* Author

Wakaba <wakaba@suikawiki.org>.

* License

You can use, modify, or distribute these files.  See license terms for
these files for more information.
