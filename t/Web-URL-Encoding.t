use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib')->stringify;
use Test::More;
use Test::X1;
use Encode;
use Web::URL::Encoding;

sub _flagged ($) {
  my $s = $_[0];
  utf8::upgrade $s;
  die unless utf8::is_utf8 $s;
  return $s;
} # _flagged

for (
      [undef, '', '', ''],
      ['' => '', '', ''],
      ['abc' => 'abc', 'abc', 'abc'],
      [_flagged 'abc' => 'abc', 'abc', 'abc'],
      ["\xA1\xC8\x4E\x4B\x21\x0D" => '%A1%C8NK%21%0D', '%C2%A1%C3%88NK%21%0D', '%C2%A1%C3%88NK%21%0D'],
      ["http://abc/a+b?x(y)z~[*]" => 'http%3A%2F%2Fabc%2Fa%2Bb%3Fx%28y%29z%7E%5B%2A%5D', 'http%3A%2F%2Fabc%2Fa%2Bb%3Fx%28y%29z%7E%5B%2A%5D', 'http%3A%2F%2Fabc%2Fa%2Bb%3Fx%28y%29z~%5B%2A%5D'],
      ["\x{4e00}\xC1" => '%4E00%C1', '%E4%B8%80%C3%81', '%E4%B8%80%C3%81'],
      ["ab+cd" => 'ab%2Bcd', 'ab%2Bcd', 'ab%2Bcd'],
) {
  my ($input, $o1, $o2, $o3) = @$_;
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

    done $c;
  } n => 4;
}

for (
  [{}, ''],
  [{hoge => 41}, 'hoge=41'],
  [{abc => ['ab', '42']}, 'abc=ab&abc=42'],
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

Copyright 2016 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
