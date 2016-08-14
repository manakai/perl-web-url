use strict;
use warnings;
use Path::Tiny;
use lib path (__FILE__)->parent->parent->child ('lib')->stringify;
use lib glob path (__FILE__)->parent->parent->child ('t_deps', 'modules', '*', 'lib')->stringify;
use Test::X1;
use Web::DomainName::IDNEnabled;
use Test::More;

test {
  my $c = shift;
  ok $Web::DomainName::IDNEnabled::VERSION;
  done $c;
} n => 1, name => 'version';

test {
  my $c = shift;
  ok $Web::DomainName::IDNEnabled::TLDs->{jp};
  ok !$Web::DomainName::IDNEnabled::TLDs->{arpa};
  done $c;
} n => 2, name => 'tlds';

run_tests;

=head1 LICENSE

Copyright 2011-2016 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
