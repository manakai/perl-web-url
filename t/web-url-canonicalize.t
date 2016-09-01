use strict;
use warnings;
use Path::Tiny;
use lib path (__FILE__)->parent->parent->child ('lib')->stringify;
use lib glob path (__FILE__)->parent->parent->child ('modules', '*', 'lib')->stringify;
use lib glob path (__FILE__)->parent->parent->child ('t_deps', 'modules', '*', 'lib')->stringify;
use Test::X1;
use Test::More;
use Test::Differences;
use Test::HTCT::Parser;
use Web::URL::Canonicalize qw(
  url_to_canon_url url_to_canon_parsed_url
  parse_url resolve_url canonicalize_parsed_url serialize_parsed_url
);

use Data::Dumper;
{
  no warnings 'redefine';
  $Data::Dumper::Useqq = 1;
  sub Data::Dumper::qquote {
    my $s = shift;
    $s =~ s/([^\x20\x21-\x26\x28-\x5B\x5D-\x7E])/sprintf '\x{%02X}', ord $1/ge;
    return q<"> . $s . q<">;
  } # Data::Dumper::qquote
}

use Test::Builder;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

binmode STDOUT, ':encoding(utf8)';
binmode STDERR, ':encoding(utf8)';

my $data_d = path (__FILE__)->parent->parent->child ('t_deps/tests/url/parsing');
my $parse_data_f = $data_d->child ('parsing.dat');
my $resolve_data_f = $data_d->child ('resolving.dat');
my @decomps_data_f = grep {
  $_ ne $parse_data_f and $_ ne $resolve_data_f;
} $data_d->children (qr/^decomps-.+\.dat$/);

{
  for_each_test $parse_data_f->stringify, {
    data => {is_prefixed => 1},
    path => {is_prefixed => 1},
  }, sub ($) {
    my $test = shift;
    test {
      my $c = shift;
      my $result = {};
      for (qw(
        scheme user password host port path query fragment invalid
      )) {
        next unless $test->{$_};
        if (length $test->{$_}->[0]) {
          $result->{$_} = $test->{$_}->[0];
        } else {
          $result->{$_} = $test->{$_}->[1]->[0];
          $result->{$_} = '' unless defined $result->{$_};
        }
      }
      if (defined $result->{scheme}) {
        $result->{scheme_normalized} = $result->{scheme};
        $result->{scheme_normalized} =~ tr/A-Z/a-z/;
      }
      my $actual = parse_url $test->{data}->[0];
      delete $actual->{is_hierarchical};
#line 1 "_parse"
      eq_or_diff $actual, $result;
      done $c;
    } n => 1, name => ['parse', $parse_data_f, $test->{data}->[0]];
  }
}

for_each_test $resolve_data_f->stringify, {
  data => {is_prefixed => 1},
  path => {is_prefixed => 1},
}, sub ($) {
  my $test = shift;
  test {
    my $c = shift;
    my $result = {};
    for (qw(
      scheme user password host port path query fragment invalid
    )) {
      next unless $test->{$_};
      if (length $test->{$_}->[0]) {
        $result->{$_} = $test->{$_}->[0];
      } else {
        $result->{$_} = $test->{$_}->[1]->[0];
        $result->{$_} = '' unless defined $result->{$_};
      }
    }
    if (defined $result->{scheme}) {
      $result->{scheme_normalized} = $result->{scheme};
      $result->{scheme_normalized} =~ tr/A-Z/a-z/;
    }
    my $base_url = length $test->{base}->[0]
             ? $test->{base}->[0]
             : defined $test->{base}->[1]->[0]
                 ? $test->{base}->[1]->[0] : '';
    my $resolved_base_url = parse_url $base_url;
    my $actual = resolve_url $test->{data}->[0], $resolved_base_url;
    delete $actual->{is_hierarchical};
#line 1 "_resolve"
    eq_or_diff
        $actual, $result,
        $test->{data}->[0] . ' - ' . $base_url;
    done $c;
  } n => 1, name => 'resolve';
};

our $BROWSER = $ENV{TEST_BROWSER} || 'this';

sub __canon (@) {
  for my $f (@_) {
    for_each_test $f->stringify, {
      data => {is_prefixed => 1},
      path => {is_prefixed => 1},
    }, sub ($) {
      my $test = shift;
      test {
        my $c = shift;
        my $result = {};
        for (qw(
          scheme user password host port path query fragment invalid
          canon charset chrome-invalid chrome-canon chrome-host
          gecko-invalid gecko-not-invalid gecko-canon gecko-host
          ie-invalid ie-canon ie-host chrome-not-invalid
          gecko-not-invalid ie-not-invalid
        )) {
          next unless $test->{$_};

          if ($test->{$_ . 8}) {
            if (length $test->{$_ . 8}->[0]) {
              $result->{$_ . 8} = $test->{$_ . 8}->[0];
            } else {
              $result->{$_ . 8} = $test->{$_ . 8}->[1]->[0];
              $result->{$_ . 8} = '' unless defined $result->{$_ . 8};
            }
            $result->{$_} = $result->{$_ . 8};
            delete $result->{$_ . 8};
          } else {
            if (length $test->{$_}->[0]) {
              $result->{$_} = $test->{$_}->[0];
            } else {
              $result->{$_} = $test->{$_}->[1]->[0];
              $result->{$_} = '' unless defined $result->{$_};
            }
          }
        }
        if ($BROWSER eq 'chrome') {
          for my $key (qw(invalid canon host)) {
            if (defined $result->{'chrome-' . $key}) {
              $result->{$key} = $result->{'chrome-' . $key};
            }
          }
          delete $result->{invalid} if $result->{'chrome-not-invalid'};
        } elsif ($BROWSER eq 'gecko') {
          for my $key (qw(invalid canon host)) {
            if (defined $result->{'gecko-' . $key}) {
              $result->{$key} = $result->{'gecko-' . $key};
            }
          }
          delete $result->{invalid} if $result->{'gecko-not-invalid'};
        } elsif ($BROWSER eq 'ie') {
          for my $key (qw(invalid canon host)) {
            if (defined $result->{'ie-' . $key}) {
              $result->{$key} = $result->{'ie-' . $key};
            }
          }
          delete $result->{invalid} if $result->{'ie-not-invalid'};
        }
        delete $result->{$_} for qw(chrome-invalid chrome-canon chrome-host);
        delete $result->{$_} for qw(gecko-invalid gecko-canon gecko-host);
        delete $result->{$_} for qw(ie-invalid ie-canon ie-host);
        delete $result->{$_} for qw(chrome-not-invalid);
        delete $result->{$_} for qw(gecko-not-invalid ie-not-invalid);
        if ($result->{invalid}) {
          delete $result->{$_} for qw(canon scheme host path query fragment user password port);
        } else {
          delete $result->{invalid};
        }
        my $charset = delete $result->{charset};
        if (defined $result->{scheme}) {
          $result->{scheme_normalized} = $result->{scheme};
          $result->{scheme_normalized} =~ tr/A-Z/a-z/;
        }
        my $base_url = $test->{base} && length $test->{base}->[0]
             ? $test->{base}->[0]
             : defined $test->{base}->[1]->[0]
                 ? $test->{base}->[1]->[0] : '';
        $base_url = $test->{data}->[0] unless length $base_url;
        $result->{canon} = $test->{data}->[0]
            if not defined $result->{canon} and not $result->{invalid};
        my $resolved_base_url = parse_url $base_url;
        my $resolved_url = resolve_url $test->{data}->[0], $resolved_base_url;
        canonicalize_parsed_url $resolved_url, $charset;
        my $url = serialize_parsed_url $resolved_url;
        $resolved_url->{canon} = $url if defined $url;
        delete $resolved_url->{is_hierarchical};
        if (defined $resolved_url->{drive}) {
          $resolved_url->{path} = '/' . $resolved_url->{drive} . ':'
              . $resolved_url->{path};
          delete $resolved_url->{drive};
        }
        test {
#line 1 "_canon"
          eq_or_diff $resolved_url, $result;

          if ($BROWSER eq 'this' and defined $url) {
            my $resolved_url2 = resolve_url $url, $resolved_base_url;
            canonicalize_parsed_url $resolved_url2, $charset;
            my $url2 = serialize_parsed_url $resolved_url2;
#line 1 "_canon_idempotent"
            eq_or_diff $url2, $url, 'idempotency';
          }
        } $c, name => [$base_url, $charset];
        done $c;
      } name => ['canon', $f->stringify, $test->{name}->[0], $test->{data}->[0]];
    };
  } # $f
} # __canon

__canon @decomps_data_f;

  for my $test (
    [undef, undef, undef, undef],
    [q<http://foo/bar>, undef, undef, q<http://foo/bar>],
    [q<baz>, q<http://foo/bar>, undef, q<http://foo/baz>],
    [q<hoge>, q<mailto:foo>, undef, undef],
    [qq<abc\x{4e90}>, q<http://foo/>, undef, q<http://foo/abc%E4%BA%90>],
    [qq<??>, q<http://foo/>, undef, q<http://foo/??>],
    [qq<?\x{5050}>, q<http://hoge>, undef, q<http://hoge/?%E5%81%90>],
    [qq<?\x{5050}>, q<http://hoge>, 'utf-8', q<http://hoge/?%E5%81%90>],
    [qq<?\x{5050}>, q<http://hoge>, 'iso-8859-1', q<http://hoge/??>],
    [qq<?\x{5050}>, q<http://hoge>, 'euc-jp', q<http://hoge/?%D0%F4>],
    [q<#>, undef, undef, undef],
    [q<foo>, q<bar>, undef, undef],
    [q<data:foo#bar>, undef, undef, q<data:foo#bar>],
    [q<../../baz>, q<http://hoge/a/b/c/d/e/../../>, undef, q<http://hoge/a/baz>],
    [q<../../baz>, q<http://hoge/a/b/c/d/e/../..>, undef, q<http://hoge/a/b/baz>],
    [q<../../baz>, q<http://hoge/a/b/c/>, undef, q<http://hoge/a/baz>],
    [q<../../../abc>, q<file://c:/windows/>, undef, q<file:///c:/abc>],
    [q<../../../abc>, q<file:///c:/windows/>, undef, q<file:///abc>],
    [q<http://foo/bar/./baz/..>, undef, undef, q<http://foo/bar/>],
    [q<file://c:/windows\\>, undef, undef, q<file:///c:/windows/>],
    [q<file://c:/windows\\>, q<file:///>, undef, q<file:///c:/windows/>],
    [q<http://hoge/a/b/c/d/e/../..>, undef, undef, q<http://hoge/a/b/c/>],
    [q<http://hoge/a/b/c/d/e/../../>, undef, undef, q<http://hoge/a/b/c/>],
  ) {
    test {
      my $c = shift;
      my $canon = url_to_canon_url $test->[0], $test->[1], $test->[2];
      is $canon, $test->[3];
      done $c;
    } n => 1, name => 'url_to_canon_url';
  }

test {
  my $c = shift;
  my $canon = url_to_canon_parsed_url q<http://foo/bar?>;
  eq_or_diff $canon, {scheme => 'http', host => 'foo', path => q</bar>,
                      query => '', is_hierarchical => 1,
                      scheme_normalized => 'http'};
  done $c;
} n => 1, name => 'url_to_canon_parsed_url';

test {
  my $c = shift;
  my $base_url = parse_url q<http://foo/bar>;
  my $parsed = resolve_url undef, $base_url;
  eq_or_diff $parsed, {invalid => 1};
  done $c;
} n => 1, name => 'resolve_url undef input';

run_tests;

=head1 LICENSE

Copyright 2011-2016 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
