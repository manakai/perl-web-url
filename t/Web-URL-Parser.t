use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib')->stringify;
use Test::More;
use Test::X1;
use Web::URL::Parser;

for (
  ['hoge', 'http://hoge/'],
  ['hoge:145', 'http://hoge:145/'],
  ['http://hoge', 'http://hoge/'],
  ['HTTPS://hoge', 'https://hoge/'],
  ['foo:hoge', undef],
  ['hoge@fuga', 'http://hoge@fuga/'],
  ["\x{5000}", 'http://xn--rvq/'],
  ['about:blank#foo', undef],
  ['http://hoge/fu?faa', 'http://hoge/fu?faa'],
  ['socks4://foo.bar/baz#aa', 'socks4://foo.bar/baz#aa'],
  ['socks5://foo.bar:/baz#aa', 'socks5://foo.bar/baz#aa'],
  ['foo://bar/baz', 'foo://bar/baz'],
) {
  my ($input, $expected) = @$_;
  test {
    my $c = shift;
    my $parser = Web::URL::Parser->new;
    my $url = $parser->parse_proxy_env ($input);
    if (defined $expected) {
      isa_ok $url, 'Web::URL';
      is $url->stringify, $expected;
    } else {
      is $url, undef;
      ok 1;
    }
    done $c;
  } n => 2, name => $input;
}

run_tests;

=head1 LICENSE

Copyright 2016 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
