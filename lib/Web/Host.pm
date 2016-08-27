package Web::Host;
use strict;
use warnings;
our $VERSION = '1.0';
use Carp qw(croak);
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

sub new_from_packed_addr ($$) {
  if (length $_[1] == 4) {
    my $self = $_[0]->parse_string (sprintf '%d.%d.%d.%d', unpack 'C4', $_[1]);
    $self->{packed_addr} = $_[1];
    return $self;
  } elsif (length $_[1] == 16) {
    my $ip = sprintf "[%x:%x:%x:%x:%x:%x:%x:%x]",
        unpack "n8", $_[1];
    my $self = $_[0]->parse_string ($ip);
    $self->{packed_addr} = $_[1];
    return $self;
  } else {
    croak "Input is not a packed IP address";
  }
} # new_from_packed_addr

sub is_ipv4 ($) { return defined $_[0]->{ipv4} }
sub is_ipv6 ($) { return defined $_[0]->{ipv6} }
sub is_ip ($) { return defined $_[0]->{ipv4} || defined $_[0]->{ipv6} }
sub is_domain ($) { return defined $_[0]->{domain} }

sub packed_addr ($) {
  return $_[0]->{packed_addr} if defined $_[0]->{packed_addr};
  if (defined $_[0]->{ipv4}) {
    return $_[0]->{packed_addr} = pack 'C4', split /\./, $_[0]->{ipv4};
  } elsif (defined $_[0]->{ipv6}) {
    my ($h, $l) = split /::/, $_[0]->{ipv6};
    my @h = map { hex $_ } split /:/, $h;
    my @l = defined $l ? map { hex $_ } split /:/, $l : ();
    return $_[0]->{packed_addr} = pack 'n*', @h, (0) x (8 - @h - @l), @l;
  }
  return undef;
} # packed_addr

sub text_addr ($) {
  if (defined $_[0]->{ipv6}) {
    return $_[0]->{ipv6};
  } elsif (defined $_[0]->{ipv4}) {
    return $_[0]->{ipv4};
  } else {
    return undef;
  }
} # text_addr

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