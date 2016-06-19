package Web::Host;
use strict;
use warnings;
our $VERSION = '1.0';
use Web::DomainName::Canonicalize qw(canonicalize_url_host);

sub parse_string ($$) {
  my $parsed = canonicalize_url_host $_[1]; # XXX
  if (defined $parsed) {
    if ($parsed =~ /\A\[/ and $parsed =~ /\]\z/) {
      return bless {ipv6 => substr $parsed, 1, -2 + length $parsed}, $_[0];
    } elsif ($parsed =~ /\A(?:[0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.(?:[0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.(?:[0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.(?:[0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\z/) {
      return bless {ipv4 => $parsed}, $_[0];
    } else {
      return bless {domain => $parsed}, $_[0];
    }
  } else {
    return undef;
  }
} # parse_string

sub is_ipv4 ($) { return defined $_[0]->{ipv4} }
sub is_ipv6 ($) { return defined $_[0]->{ipv6} }
sub is_ip ($) { return defined $_[0]->{ipv4} || defined $_[0]->{ipv6} }
sub is_domain ($) { return defined $_[0]->{domain} }

sub equals ($$) {
  return $_[0]->stringify eq $_[1]->stringify;
} # equals

sub stringify ($) {
  if (defined $_[0]->{ipv6}) {
    return '[' . $_[0]->{ipv6} . ']';
  } elsif (defined $_[0]->{ipv4}) {
    return $_[0]->{ipv4};
  } else {
    return $_[0]->{domain};
  }
} # stringify

1;

=head1 LICENSE

Copyright 2016 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
