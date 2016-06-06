use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib')->stringify;
use Test::More;
use Test::X1;
use Web::URL;

for (
  [q<http://hoge/fuga?abc#fee>, undef, q<http://hoge/fuga?abc#fee>],
  [q<../foha/gw#a%41br>, q<http://foo/bar/baz?aa>, q<http://foo/foha/gw#a%41br>],
  [q<ABOUT:Blank#a>, undef, q<about:Blank#a>],
  [q<HTTPS://FOO:013>, undef, q<https://foo:13/>],
  [q<http://hoge:fuga>, undef, undef],
  [q<http:hoge>, q<http://foo/bar>, q<http://foo/hoge>],
) {
  my ($input, $base, $expected) = @$_;
  test {
    my $c = shift;

    $base = Web::URL->parse_string ($base) if defined $base;
    my $url = Web::URL->parse_string ($input, $base);
    if (defined $expected) {
      isa_ok $url, 'Web::URL';
      is $url->stringify, $expected;
    } else {
      is $url, undef;
      ok 1;
    }

    done $c;
  } n => 2;
}

run_tests;

=head1 LICENSE

Copyright 2016 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
