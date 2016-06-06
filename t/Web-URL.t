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

for (
  [q<http://hoge/fuga/abc>, q<http://hoge>],
  [q<https://hoge/fuga/abc>, q<https://hoge>],
  [q<ftp://hoge/fuga/abc>, q<ftp://hoge>],
  [q<ws://hoge/fuga/abc>, q<ws://hoge>],
  [q<wss://hoge/fuga/abc>, q<wss://hoge>],
  [q<http://hoge:1521/fuga/abc>, q<http://hoge:1521>],
  [q<blob:http://hoge/foo>, q<http://hoge>],
  [q<blob:foo:bar>, q<null>],
  [q<blob:hoge://fuga/bar>, q<null>],
  [q<about:blank>, q<null>],
  [q<foo:bar:baz>, q<null>],
  [q<mailto:foo:bar:baz>, q<null>],
) {
  my ($input, $expected) = @$_;
  test {
    my $c = shift;
    my $url = Web::URL->parse_string ($input);
    my $origin = $url->get_origin;
    isa_ok $origin, 'Web::Origin';
    is $origin->to_ascii, $expected;

    my $origin2 = $url->get_origin;
    isnt $origin2, $origin;
    if ($expected eq 'null') {
      ok ! $origin->same_origin_as ($origin2);
    } else {
      ok $origin->same_origin_as ($origin2);
    }

    done $c;
  } n => 4;
}

for (
  [q<http://hoge/fuga>, 'http', '', undef, 'hoge', undef],
  [q<Http://hoge:052/fuga>, 'http', '', undef, 'hoge', 52],
  [q<httpS://fopo@hoge/fuga>, 'https', 'fopo', undef, 'hoge', undef],
  [q<http://ho:ge@/fuga>, 'http', 'ho', 'ge', '', undef],
  [q<htt:foo:bar@ga>, 'htt', '', undef, undef, undef],
  [qq<http://\x{5000}hoge/fuga>, 'http', '', undef, 'xn--hoge-pc7f', undef],
  [q<http://123.44.000.01/fuga>, 'http', '', undef, '123.44.0.1', undef],
) {
  my ($input, $scheme, $username, $password, $host, $port) = @$_;
  test {
    my $c = shift;
    my $url = Web::URL->parse_string ($input);
    is $url->scheme, $scheme;
    is $url->username, $username;
    is $url->password, $password;
    is $url->host, $host;
    is $url->port, $port;
    done $c;
  } n => 5, name => $input;
}

run_tests;

=head1 LICENSE

Copyright 2016 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
