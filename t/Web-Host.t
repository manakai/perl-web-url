use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib')->stringify;
use Test::More;
use Test::X1;
use Web::Host;

for (
  ['hoge' => 'hoge'],
  ['fdoo.bar' => 'fdoo.bar'],
  ['Fuga.ABC' => 'fuga.abc'],
  ['abc.d.' => 'abc.d.'],
  ['0120.abc.4' => '0120.abc.4'],
  ["\x{5000}.\x{5004}" => 'xn--rvq.xn--vvq'],
  ["XN--RVQ" => "xn--rvq"],
) {
  my ($input, $output) = @$_;
  test {
    my $c = shift;
    my $host = Web::Host->parse_string ($input);
    isa_ok $host, 'Web::Host';
    ok $host->is_domain;
    ok ! $host->is_ip;
    ok ! $host->is_ipv4;
    ok ! $host->is_ipv6;
    is $host->stringify, $output;
    ok $host->equals ($host);
    done $c;
  } n => 7;
}

for (
  ['50.0.5.1' => '50.0.5.1'],
  ['050.0000.24.4' => '40.0.24.4'],
  ['5234' => '0.0.20.114'],
) {
  my ($input, $output) = @$_;
  test {
    my $c = shift;
    my $host = Web::Host->parse_string ($input);
    isa_ok $host, 'Web::Host';
    ok ! $host->is_domain;
    ok $host->is_ip;
    ok $host->is_ipv4;
    ok ! $host->is_ipv6;
    is $host->stringify, $output;
    ok $host->equals ($host);
    done $c;
  } n => 7;
}

for (
  ['[::4]' => '[::4]'],
  ['[3:4:012:0::4]' => '[3:4:12::4]'],
) {
  my ($input, $output) = @$_;
  test {
    my $c = shift;
    my $host = Web::Host->parse_string ($input);
    isa_ok $host, 'Web::Host';
    ok ! $host->is_domain;
    ok $host->is_ip;
    ok ! $host->is_ipv4;
    ok $host->is_ipv6;
    is $host->stringify, $output;
    ok $host->equals ($host);
    done $c;
  } n => 7;
}

for (
  ['::4'],
  ['ab:cd'],
) {
  my ($input) = @$_;
  test {
    my $c = shift;
    my $host = Web::Host->parse_string ($input);
    is $host, undef;
    done $c;
  } n => 1;
}

test {
  my $c = shift;
  my $h1 = Web::Host->parse_string ("hoge");
  my $h2 = Web::Host->parse_string ("fuga");
  ok ! $h1->equals ($h2);
  ok ! $h2->equals ($h1);
  done $c;
} n => 2, name => 'equals';

test {
  my $c = shift;
  my $h1 = Web::Host->parse_string ("192.168.0.1");
  my $h2 = Web::Host->parse_string ("192.168.0.1.test");
  ok ! $h1->equals ($h2);
  ok ! $h2->equals ($h1);
  done $c;
} n => 2, name => 'equals';

test {
  my $c = shift;
  my $h1 = Web::Host->parse_string ("hoge");
  my $h2 = Web::Host->parse_string ("hoge");
  ok $h1->equals ($h2);
  ok $h2->equals ($h1);
  done $c;
} n => 2, name => 'equals';

test {
  my $c = shift;
  my $h1 = Web::Host->parse_string ("[::13]");
  my $h2 = Web::Host->parse_string ("[::13]");
  ok $h1->equals ($h2);
  ok $h2->equals ($h1);
  done $c;
} n => 2, name => 'equals';

test {
  my $c = shift;
  my $h1 = Web::Host->parse_string ("hoge.fuga.abc");
  my $h2 = Web::Host->parse_string ("fuga.abc");
  ok ! $h1->equals ($h2);
  ok ! $h2->equals ($h1);
  done $c;
} n => 2, name => 'equals';

run_tests;

=head1 LICENSE

Copyright 2016 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
