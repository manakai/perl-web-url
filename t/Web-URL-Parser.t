use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib')->stringify;
use Test::More;
use Test::X1;
use Test::HTCT::Parser;
use Web::URL::Parser;

for_each_test path (__FILE__)->parent->parent->child ('t_deps/tests/url/proxyenv/proxyenv.dat')->stringify, {
  data => {is_prefixed => 1},
  url => {is_prefixed => 1},
}, sub ($) {
  my $test = shift;
  test {
    my $c = shift;
    my $parser = Web::URL::Parser->new;
    my $url = $parser->parse_proxy_env ($test->{data}->[0]);
    if ($test->{invalid}) {
      is $url, undef;
      ok 1;
    } else {
      isa_ok $url, 'Web::URL';
      is $url->stringify, $test->{url}->[0];
    }
    done $c;
  } n => 2, name => $test->{data}->[0];
};

run_tests;

=head1 LICENSE

Copyright 2016-2018 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
