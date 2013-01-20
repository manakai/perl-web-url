use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;
use lib glob file (__FILE__)->dir->parent->subdir ('t_deps', 'modules', '*', 'lib')->stringify;
use Test::X1;
use Test::More;
use Web::DomainName::Punycode;
use Encode;

my $SupportLong = 1;


  for my $test (
    [undef, undef],
    ['', ''],
    ['-', '--'],
    ['123', '123-'],
    ['abcdef' => 'abcdef-'],
    ['AbcDef' => 'AbcDef-'],
    ["\x{1000}ab" => 'ab-ezj'],
    ["x\x{4000}\x{1000}" => 'x-1qg7797a'],
    ['a-b-', 'a-b--'],
    ['-abc', '-abc-'],
    ["\x{1000}", 'nid'],
    [(encode 'utf-8', "\x{1000}"), 'aa30a'],
    ['xn--abcc', 'xn--abcc-'],
    ["\x{61}\x{1F62}\x{03B9}\x{62}" => 'ab-09b734z'],
    ["\x{61}\x{1F62}\x{62}" => 'ab-ymt'],
    ['a' x 1000, ('a' x 1000) . '-'],
    ["\x{1000}" . ('a' x 1000), ('a' x 1000) . '-2o653a'],
    ['a' x 10000, $SupportLong ? ('a' x 10000) . '-' : undef],
    ["\x{1000}" . ('a' x 10000), $SupportLong ? ('a' x 10000) . '-xc9053a' : undef],
  ) {
    test {
      my $c = shift;
      my $out = encode_punycode $test->[0];
      is $out, $test->[1];
      done $c;
    } n => 1, name => ['encode_punycode', substr $test->[0], 0, 10];
  }

  for my $test (
    [undef, undef],
    ['', ''],
    ['1234', undef],
    ['nid', "\x{1000}"],
    ['aa30a', "\x{E1}\x{80}\x{80}"],
    ['xn--nid', "\x{0460}xn-"],
    ['abcdef-', 'abcdef'],
    ['-', undef], # Spec is unclear for this case
    ['--', '-'],
    ['---', '--'],
    ['-> $1.00 <--', '-> $1.00 <-'],
    ["\x{1000}", undef],
    ["\x{1000}-", undef],
    ["-\x{1000}", undef],
    ["-abc\x{1000}xyz", undef],
    ['--abcde', "\x{82}\x{80}\x{81}-\x{80}\x{82}"],
    ['ab-09b734z' => "\x{61}\x{1F62}\x{03B9}\x{62}"],
    ['ab-ymt' => "\x{61}\x{1F62}\x{62}"],
    [('a' x 1000) . '-', ('a' x 1000)],
    [('a' x 1000) . '-2o653a', "\x{1000}" . ('a' x 1000)],
    ["\x{1000}" . ('a' x 1000), undef],
    [('a' x 10000) . '-', $SupportLong ? ('a' x 10000) : undef],
    ["\x{1000}" . ('a' x 10000), undef],
  ) {
    test {
      my $c = shift;
      my $out = decode_punycode $test->[0];
      is $out, $test->[1];
      done $c;
    } n => 1, name => ['decode_punycode', substr $test->[0], 0, 10];
  }

run_tests;

=head1 LICENSE

Copyright 2011-2013 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
