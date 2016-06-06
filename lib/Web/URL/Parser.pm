package Web::URL::Parser;
use strict;
use warnings;
our $VERSION = '1.0';
use Web::URL;

sub new ($) {
  return bless {}, $_[0];
} # new

sub parse_proxy_env ($$) {
  my $value = $_[1];
  $value = 'http://' . $value unless $value =~ m{^[A-Za-z][A-Za-z0-9+.-]*://};
  return Web::URL->parse_string ($value);
} # parse_proxy_env

1;

=head1 LICENSE

Copyright 2016 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
