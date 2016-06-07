use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib')->stringify;
use Test::More;
use Test::X1;
use Web::URL::Scheme;

for (
  [http => 80],
  [https => 443],
  [ftp => 21],
  [gopher => 70],
  [ws => 80],
  [wss => 443],
  [hoge => undef],
  [sip => undef],
  [mailto => undef],
  [HTTP => undef],
  [file => undef],
  ['' => undef],
  [undef, undef],
) {
  my ($scheme, $port) = @$_;
  test {
    my $c = shift;
    my $got = get_default_port $scheme;
    is $got, $port;
    done $c;
  } n => 1, name => ['get_default_port', $scheme];
}

run_tests;

=head1 LICENSE

Copyright 2011-2016 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
