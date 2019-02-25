use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib')->stringify;
use Test::More;
use Test::X1;
use Web::URL::Encoding;

sub _flagged ($) {
  my $s = $_[0];
  utf8::upgrade $s;
  die unless utf8::is_utf8 $s;
  return $s;
} # _flagged

for (
      [undef, '', '', '', ''],
      ['' => '', '', '', ''],
      ['abc' => 'abc', 'abc', 'abc', 'abc'],
      [_flagged 'abc' => 'abc', 'abc', 'abc', 'abc'],
      ["\xA1\xC8\x4E\x4B\x21\x0D" => '%A1%C8NK%21%0D', '%C2%A1%C3%88NK%21%0D', '%C2%A1%C3%88NK%21%0D', '%A1%C8NK%21%0D'],
      ["http://abc/a+b?x(y)z~[*]" => 'http%3A%2F%2Fabc%2Fa%2Bb%3Fx%28y%29z%7E%5B%2A%5D', 'http%3A%2F%2Fabc%2Fa%2Bb%3Fx%28y%29z%7E%5B%2A%5D', 'http%3A%2F%2Fabc%2Fa%2Bb%3Fx%28y%29z~%5B%2A%5D', 'http%3A%2F%2Fabc%2Fa%2Bb%3Fx%28y%29z~%5B%2A%5D'],
      ["\x{4e00}\xC1" => '%4E00%C1', '%E4%B8%80%C3%81', '%E4%B8%80%C3%81', '%4E00%C1'],
      ["ab+cd" => 'ab%2Bcd', 'ab%2Bcd', 'ab%2Bcd', 'ab%2Bcd'],
) {
  my ($input, $o1, $o2, $o3, $o4) = @$_;
  test {
    my $c = shift;

    #my $s = percent_encode_b ($input);
    #is $s, $o1;
    #ok !utf8::is_utf8 ($s);

    my $t = percent_encode_c ($input);
    is $t, $o2;
    ok !utf8::is_utf8 ($t);

    my $u = oauth1_percent_encode_c ($input);
    is $u, $o3;
    ok !utf8::is_utf8 ($u);

    my $v = oauth1_percent_encode_b ($input);
    is $v, $o4;
    is !!utf8::is_utf8 ($v), !!utf8::is_utf8 ($input);

    done $c;
  } n => 6, name => 'encode';
}

for (
      [undef, '', ''],
      ['', '', ''],
      ['abc', 'abc', 'abc'],
      [_flagged 'abc', 'abc', 'abc'],
      ['%A1%C8NK%21%0D', "\xA1\xC8NK!\x0D", "\x{FFFD}\x{FFFD}NK!\x0D"],
      ['%C2%A1%C3%88NK%21%0D', "\xC2\xA1\xC3\x88NK!\x0D", "\xA1\xC8NK!\x0D"],
      ['http%3A%2F%2Fabc%2Fa%2Bb%3Fx%28y%29z~%5B%2A%5D', 'http://abc/a+b?x(y)z~[*]', 'http://abc/a+b?x(y)z~[*]'],
      ["\xA1\xC8\x4E\x4B\x21\x0D", "\xA1\xC8NK!\x0D", "\x{FFFD}\x{FFFD}NK!\x0D"],
      ["\x{4e00}\xC1", "\xE4\xB8\x80\xC3\x81", "\x{4e00}\xC1"],
      ['%4E00%C1', "\x4e00\xC1", "\x4e00\x{FFFD}"],
      ['%E4%B8%80%C3%81', "\xE4\xB8\x80\xC3\x81", "\x{4e00}\xC1"],
      [_flagged '%E4%B8%80%C3%81', "\xE4\xB8\x80\xC3\x81", "\x{4e00}\xC1"],
      ['ab+cd', 'ab+cd', 'ab+cd'],
) {
  my ($input, $x1, $x2) = @$_;
  no warnings 'uninitialized';
  test {
    my $c = shift;

    my $s = percent_decode_b ($input);
    is $s, $x1, join '/', '_pd', 'b', $input;
    ok !utf8::is_utf8 ($s);

    my $t = percent_decode_c ($input);
    is $t, $x2, join '/', '_pd', 'c', $input;

    done $c;
  } n => 3, name => 'decode';
}

for (
  [{}, ''],
  [{hoge => 41}, 'hoge=41'],
  [{abc => ['ab', '42']}, 'abc=ab&abc=42'],
  [{abc => [undef, '42']}, 'abc=&abc=42'],
  [{abc => [undef]}, 'abc='],
  [{"\x{500}" => "\x{504}"}, '%D4%80=%D4%84'],
  [{'' => ''}, '='],
  [{abc => ''}, 'abc='],
  [{'' => '0'}, '=0'],
  [{0 => 1}, '0=1'],
  [{'f+a%' => '$@[|]^'}, 'f%2Ba%25=%24%40%5B%7C%5D%5E'],
  [{' + +' => ' + +'}, '+%2B+%2B=+%2B+%2B'],
  [{"\x7F\x90" => "\x00"}, '%7F%C2%90=%00'],
  [{hoge => undef, 34 => undef, 1 => 2}, '1=2'],
) {
  my ($input, $expected) = @$_;
  test {
    my $c = shift;
    my $got = serialize_form_urlencoded $input;
    is $got, $expected;
    done $c;
  } n => 1, name => $input;
}

run_tests;

=head1 LICENSE

Copyright 2016-2019 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
