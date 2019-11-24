use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib')->stringify;
use Test::More;
use Test::X1;
use Test::HTCT::Parser;
use JSON::PS;
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
  } n => 2, name => ['parse_proxy_env', $test->{data}->[0]];
};

for_each_test path (__FILE__)->parent->parent->child ('t_deps/tests/url/autolink/urlextraction.dat')->stringify, {
  data => {is_prefixed => 1},
}, sub ($) {
  my $test = shift;
  test {
    my $c = shift;
    my $parser = Web::URL::Parser->new;
    {
      my $result = $parser->split_by_urls ($test->{data}->[0]);
      my $got = perl2json_chars_for_record $result;
      my $expected = perl2json_chars_for_record json_chars2perl $test->{result}->[0];
      is $got, $expected;
    }
    {
      my $result = $parser->split_by_urls ($test->{data}->[0], lax => 1);
      my $got = perl2json_chars_for_record $result;
      my $expected = perl2json_chars_for_record json_chars2perl
          ($test->{'lax-result'}->[0] || $test->{result}->[0]);
      is $got, $expected, 'lax';
    }
    done $c;
  } n => 2, name => ['split_by_urls', $test->{data}->[0]];

  test {
    my $c = shift;
    my $parser = Web::URL::Parser->new;
    {
      my $result = $parser->text_to_autolinked_html ($test->{data}->[0]);
      my $expected = $test->{html}->[0];
      is $result, $expected;
    }
    {
      my $result = $parser->text_to_autolinked_html ($test->{data}->[0], lax => 1);
      my $expected = ($test->{'lax-html'}->[0] || $test->{html}->[0]);
      is $result, $expected, 'lax';
    }
    done $c;
  } n => 2, name => ['text_to_autolinked_html', $test->{data}->[0]];
};

run_tests;

=head1 LICENSE

Copyright 2016-2019 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
