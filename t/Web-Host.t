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
  ["\x{5000}.\x{5004}" => 'xn--rvq.xn--vvq', "\x{5000}.\x{5004}"],
  ["XN--RVQ" => "xn--rvq", "\x{5000}"],
  ['xn--abc-' => 'xn--abc-', 'abc'],
  ['xn--abc--' => 'xn--abc--', 'abc-'],
  ["\x{0938}\x{0902}\x{0917}\x{0920}\x{0928}" => "xn--i1b6b1a6a2e",
   "\x{0938}\x{0902}\x{0917}\x{0920}\x{0928}"],
) {
  my ($input, $output, $uoutput) = @$_;
  $uoutput = $output unless defined $uoutput;
  test {
    my $c = shift;
    my $host = Web::Host->parse_string ($input);
    isa_ok $host, 'Web::Host';
    ok $host->is_domain;
    ok ! $host->is_ip;
    ok ! $host->is_ipv4;
    ok ! $host->is_ipv6;
    is $host->stringify, $output;
    is $host->to_ascii, $output;
    is $host->TO_JSON, $output;
    is $host->to_unicode, $uoutput;
    ok $host->equals ($host);
    is $host->packed_addr, undef;
    is $host->text_addr, undef;
    done $c;
  } n => 12, name => 'domains';
}

for (
  ['50.0.5.1' => '50.0.5.1', "\x32\x00\x05\x01"],
  ['050.0000.24.4' => '40.0.24.4', "\x28\x00\x18\x04"],
  ['5234' => '0.0.20.114', "\x00\x00\x14\x72"],
) {
  my ($input, $output, $poutput) = @$_;
  test {
    my $c = shift;
    my $host = Web::Host->parse_string ($input);
    isa_ok $host, 'Web::Host';
    ok ! $host->is_domain;
    ok $host->is_ip;
    ok $host->is_ipv4;
    ok ! $host->is_ipv6;
    is $host->stringify, $output;
    is $host->to_ascii, $output;
    is $host->TO_JSON, $output;
    is $host->to_unicode, $output;
    is $host->text_addr, $output;
    ok $host->equals ($host);
    my $packed = $host->packed_addr;
    is $packed, $poutput;
    my $host2 = Web::Host->new_from_packed_addr ($packed);
    isa_ok $host2, 'Web::Host';
    ok $host2->is_ipv4;
    ok $host2->equals ($host);
    is $host2->stringify, $host->stringify;
    done $c;
  } n => 16, name => 'IPv4 addresses';
}

for (
  ['[::4]' => '[::4]',
   "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04"],
  ['[3:4:012e:0::4]' => '[3:4:12e::4]',
   "\x00\x03\x00\x04\x01\x2e\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04"],
  ['[0:123:45:67:89:ab:cd:ef]' => '[0:123:45:67:89:ab:cd:ef]',
   "\x00\x00\x01\x23\x00\x45\x00\x67\x00\x89\x00\xab\x00\xcd\x00\xef"],
) {
  my ($input, $output, $poutput) = @$_;
  test {
    my $c = shift;
    my $host = Web::Host->parse_string ($input);
    isa_ok $host, 'Web::Host';
    ok ! $host->is_domain;
    ok $host->is_ip;
    ok ! $host->is_ipv4;
    ok $host->is_ipv6;
    is $host->stringify, $output;
    is $host->to_ascii, $output;
    is $host->TO_JSON, $output;
    is $host->to_unicode, $output;
    is "[".$host->text_addr."]", $output;
    ok $host->equals ($host);
    my $packed = $host->packed_addr;
    is $packed, $poutput;
    my $host2 = Web::Host->new_from_packed_addr ($packed);
    isa_ok $host2, 'Web::Host';
    ok $host2->is_ipv6;
    ok $host2->equals ($host);
    is $host2->stringify, $host->stringify;
    done $c;
  } n => 16, name => 'IPv6 addresses';
}

for (
  ['::4'],
  ['ab:cd'],
  ["\x{5000}..\x{5001}"],
  ["xn--abc--\x{4e00}"],
  ["xn--abc--.\x{4e00}"],
  ["\x{0902}\x{0917}\x{0920}\x{0928}"],
) {
  my ($input) = @$_;
  test {
    my $c = shift;
    my $host = Web::Host->parse_string ($input);
    is $host, undef;
    done $c;
  } n => 1, name => 'invalid hosts';
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

test {
  my $c = shift;

  eval {
    Web::Host->new_from_packed_addr ("abcde")
  };
  like $@, qr{^Input is not a packed IP address};

  done $c;
} n => 1;

for (
  ['' => undef],
  ['hoge' => ['hoge', undef]],
  ['hoge:80' => ['hoge', 80]],
  ['Hoge:080' => ['hoge', 80]],
  ['foo.bar:443' => ['foo.bar', 443]],
  ['hoge/fuga:80' => undef],
  ['102.156.16.11' => ['102.156.16.11', undef]],
  ['[::001]' => ['[::1]', undef]],
  ['[::1]:1244' => ['[::1]', 1244]],
  ["\x{5000}\x{3002}abc:66" => ['xn--rvq.abc', 66]],
  ["\x{5000}\x{3e02}abc:66" => ['xn--abc-to5ct99f', 66]],
) {
  my ($input, $expected) = @$_;
  test {
    my $c = shift;
    my ($host, $port) = Web::Host->parse_hostport_string ($input);
    if (defined $expected) {
      isa_ok $host, 'Web::Host';
      is defined $host ? $host->to_ascii : undef, $expected->[0];
      is $port, $expected->[1];
    } else {
      is $host, undef;
      ok 1;
      is $port, undef;
    }
    done $c;
  } n => 3, name => ['parse_hostport_string', $input];
}

run_tests;

=head1 LICENSE

Copyright 2016-2017 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
