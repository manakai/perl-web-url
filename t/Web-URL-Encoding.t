use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib')->stringify;
use Test::More;
use Test::X1;
use Web::URL::Encoding;

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
