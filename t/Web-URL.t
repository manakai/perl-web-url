use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib')->stringify;
use Test::More;
use Test::X1;
use Web::URL;

for (
  [q<http://hoge/fuga?abc#fee>, undef,
   q<http://hoge/fuga?abc#fee>, q<http://hoge/fuga?abc>,
   q<http://hoge/fuga>, q<http://hoge/fuga?abc>],
  [q<../foha/gw#a%41br>, q<http://foo/bar/baz?aa>,
   q<http://foo/foha/gw#a%41br>, q<http://foo/foha/gw>,
   q<http://foo/foha/gw>, q<http://foo/foha/gw>],
  [q<ABOU:Blank#a>, undef,
   q<abou:Blank#a>, q<abou:Blank>, q<abou:Blank>, q<abou:Blank>],
  [q<HTTPS://FOO:013>, undef,
   q<https://foo:13/>, q<https://foo:13/>,
   q<https://foo:13/>, q<https://foo:13/>],
  [q<http://hoge:fuga>, undef, undef, undef, undef, undef],
  [q<http:hoge>, q<http://foo/bar>,
   q<http://foo/hoge>, q<http://foo/hoge>,
   q<http://foo/hoge>, q<http://foo/hoge>],
) {
  my ($input, $base, $expected, $expected2, $expected3, $expected4) = @$_;
  test {
    my $c = shift;

    $base = Web::URL->parse_string ($base) if defined $base;
    my $url = Web::URL->parse_string ($input, $base);
    if (defined $expected) {
      isa_ok $url, 'Web::URL';
      is $url->originpath, $expected3;
      is $url->originpathquery, $expected4;
      is $url->stringify, $expected;
      is $url->stringify_without_fragment, $expected2;
    } else {
      is $url, undef;
      ok 1;
      ok 1;
      ok 1;
      ok 1;
    }

    done $c;
  } n => 5;
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
  [q<http://hoge/fuga>, 'http', '', undef, 'hoge', undef, '/fuga', undef,
   'hoge', '/fuga'],
  [q<Http://hoge:052/fuga>, 'http', '', undef, 'hoge', 52, '/fuga', undef,
   'hoge:52', '/fuga'],
  [q<httpS://fopo@hoge/fuga>, 'https', 'fopo', undef, 'hoge', undef, '/fuga', undef,
   'hoge', '/fuga'],
  [q<http://ho:ge@_/fuga>, 'http', 'ho', 'ge', '_', undef, '/fuga', undef,
   '_', '/fuga'],
  [q<htt:foo:bar@ga>, 'htt', '', undef, undef, undef, 'foo:bar@ga', undef,
   undef, 'foo:bar@ga'],
  [qq<http://\x{5000}hoge/fuga>, 'http', '', undef, 'xn--hoge-pc7f', undef, '/fuga', undef,
   'xn--hoge-pc7f', '/fuga'],
  [q<http://123.44.000.01/fuga>, 'http', '', undef, '123.44.0.1', undef, '/fuga', undef,
   '123.44.0.1', '/fuga'],
  [q<ftp://foo.bar>, 'ftp', '', undef, 'foo.bar', undef, '/', undef,
   'foo.bar', '/'],
  [q<ftp://foo.bar?ab%4a>, 'ftp', '', undef, 'foo.bar', undef, '/', 'ab%4a',
   'foo.bar', '/?ab%4a'],
  [q<ftp://foo.bar/abc?foo=bar>, 'ftp', '', undef, 'foo.bar', undef, '/abc', 'foo=bar',
   'foo.bar', '/abc?foo=bar'],
  [q<ftp://foo.bar/abc//xyz?foo=bar>, 'ftp', '', undef, 'foo.bar', undef, '/abc//xyz', 'foo=bar',
   'foo.bar', '/abc//xyz?foo=bar'],
  [q<ftp://foo.bar///abc///?foo=bar>, 'ftp', '', undef, 'foo.bar', undef, '///abc///', 'foo=bar',
   'foo.bar', '///abc///?foo=bar'],
  [q<xyz:>, 'xyz', '', undef, undef, undef, '', undef,
   undef, ''],
#XXX
#  [q<about:hoge?fuga#abc>, 'about', '', undef, 'hoge', 'fuga',
#   undef, 'hoge?fuga'],
) {
  my ($input, $scheme, $username, $password, $host, $port, $path, $query,
      $hostport, $pathquery) = @$_;
  test {
    my $c = shift;
    my $url = Web::URL->parse_string ($input);
    is $url->scheme, $scheme;
    is $url->username, $username;
    is $url->password, $password;
    if (defined $url->host) {
      is $url->host->stringify, $host;
    } else {
      is $url->host, undef;
    }
    is $url->port, $port;
    is $url->query, $query;
    is $url->hostport, $hostport;
    is $url->pathquery, $pathquery;
    done $c;
  } n => 8, name => $input;
}

test {
  my $c = shift;
  my $url = Web::URL->parse_string (q<http://foo.bar/baz/abc?a#x>);
  my $clone = $url->clone;
  isa_ok $clone, 'Web::URL';
  isnt $clone, $url;
  is $clone->stringify, 'http://foo.bar/baz/abc?a#x';
  $clone->set_query_params ({foo => 4});
  is $url->stringify, q<http://foo.bar/baz/abc?a#x>;
  is $clone->stringify, q<http://foo.bar/baz/abc?foo=4#x>;
  done $c;
} n => 5, name => 'clone';

test {
  my $c = shift;
  my $url = Web::URL->parse_string (q<http://foo.bar/baz/abc?a#x>);
  $url->set_query_params ({});
  is $url->stringify, q<http://foo.bar/baz/abc?#x>;
  done $c;
} n => 1, name => 'set_query_params';

test {
  my $c = shift;
  my $url = Web::URL->parse_string (q<http://foo.bar/baz/abc?a#x>);
  $url->set_query_params ({"\xFE +" => "\x{5000} +"});
  is $url->stringify, q<http://foo.bar/baz/abc?%C3%BE+%2B=%E5%80%80+%2B#x>;
  done $c;
} n => 1, name => 'set_query_params';

test {
  my $c = shift;
  my $url = Web::URL->parse_string (q<http://foo.bar/baz/abc?a#x>);
  $url->set_query_params ({}, append => 1);
  is $url->stringify, q<http://foo.bar/baz/abc?a#x>;
  done $c;
} n => 1, name => 'set_query_params';

test {
  my $c = shift;
  my $url = Web::URL->parse_string (q<http://foo.bar/baz/abc?a#x>);
  $url->set_query_params ({"\xFE +" => "\x{5000} +"}, append => 1);
  is $url->stringify, q<http://foo.bar/baz/abc?a&%C3%BE+%2B=%E5%80%80+%2B#x>;
  done $c;
} n => 1, name => 'set_query_params';

test {
  my $c = shift;
  my $url = Web::URL->parse_string (q<https://hoge.fuga.>);
  isa_ok $url->host, 'Web::Host';
  is $url->host->stringify, 'hoge.fuga.';
  ok $url->host->is_domain;
  done $c;
} n => 3, name => 'host';

test {
  my $c = shift;
  my $url = Web::URL->parse_string (q<https://[::]/foo>);
  isa_ok $url->host, 'Web::Host';
  is $url->host->stringify, '[::]';
  ok $url->host->is_ipv6;
  done $c;
} n => 3, name => 'host';

test {
  my $c = shift;
  my $url = Web::URL->parse_string (q<https://454>);
  isa_ok $url->host, 'Web::Host';
  is $url->host->stringify, '0.0.1.198';
  ok $url->host->is_ipv4;
  done $c;
} n => 3, name => 'host';

for my $url (qw(
  http://hoge https://hoge
)) {
  test {
    my $c = shift;
    my $url = Web::URL->parse_string ($url);
    ok $url->is_http_s;
    done $c;
  } n => 1;
}

for my $url (qw(
  ws://hoge wss://hoge about:blank ftp://foo unknown://foo javascript:a
)) {
  test {
    my $c = shift;
    my $url = Web::URL->parse_string ($url);
    ok ! $url->is_http_s;
    done $c;
  } n => 1;
}

run_tests;

=head1 LICENSE

Copyright 2016 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
