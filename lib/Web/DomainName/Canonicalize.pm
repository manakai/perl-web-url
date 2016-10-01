package Web::DomainName::Canonicalize;
use strict;
use warnings;
no warnings 'utf8';
our $VERSION = '2.0';
use Carp;
use Web::Encoding;
use Web::Encoding::Normalization;
use Web::IPAddr::Canonicalize;
use Web::DomainName::Punycode;

use Web::DomainName::_CharClasses;
use Web::DomainName::_CharMaps;
our $IDNAMapped;

our @EXPORT = qw(
  canonicalize_domain_name
  canonicalize_url_host
);

sub import ($;@) {
  my $from_class = shift;
  my ($to_class, $file, $line) = caller;
  no strict 'refs';
  for (@_ ? @_ : @{$from_class . '::EXPORT'}) {
    my $code = $from_class->can ($_)
        or croak qq{"$_" is not exported by the $from_class module at $file line $line};
    *{$to_class . '::' . $_} = $code;
  }
} # import

sub _valid_label ($$) {
  my ($transitional, $label) = @_;

  unless (is_nfc $label) {
    return 0;
  }

  if ($label =~ /\A-/ or $label =~ /-\z/ or $label =~ /\A..--/s) {
    return 0;
  }

  if ($label =~ /\p{InBadLabel}/) {
    return 0;
  }

  if ($label =~ /\A\p{InBadLabelStart}/) {
    return 0;
  }

  if ($transitional and $label =~ /\p{InDeviation}/) {
    return 0;
  }

  return 1;
} # _valid_label

sub _uts46 ($$$) {
  my ($s, $transitional, $to_ascii) = @_;

  if ($to_ascii and not $s =~ /[^\x00-\x7F]/) { ## Willful violation to UTS #46
    $s =~ tr/A-Z/a-z/; ## ASCII case-insensitive
    return $s;
  }

  ## Map - disallowed
  while ($s =~ /\p{InDisallowed}/g) {
    # XXX syntax violation
    return undef if $to_ascii;
  }

  ## Map - ignored, mapped
  {
    no warnings 'uninitialized';
    $s =~ s/(\p{InIgnoredOrMapped})/$IDNAMapped->{$1}/g;
  }

  ## Map - deviation
  if ($transitional) {
    $s =~ s/(\p{InDeviation})/$IDNAMapped->{$1}/g;
  }

  ## Normalize
  $s = to_nfc $s;

    ## Break
    my @s = split /\./, $s, -1;

    ## Convert/validate
    for my $label (@s) {
      if ($label =~ /^xn--/) {
        my $result = decode_punycode substr $label, 4;
        if (defined $result) {
          $label = $result;
          unless (_valid_label 0, $label) {
            # XXX syntax violation
            return undef if $to_ascii;
          }
        } else {
          # XXX syntax violation
          return undef if $to_ascii;
        }
      } else {
        unless (_valid_label $transitional, $label) {
          # XXX syntax violation
          return undef if $to_ascii;
        }
      }

      if ($to_ascii and $label =~ /[^\x00-\x7F]/) {
        $label = 'xn--' . encode_punycode $label;
      }

      ## Willful violation to URL Standard
      return undef if length $label > 63;
    } # $label

    ## Not in the spec
    for (@s[0..($#s-1)]) {
      if ($_ eq '') {
        # XXX syntax violation
        return undef;
      }
    }

    return join '.', @s;
} # _uts46

sub _domain_to_unicode ($) {
  ## UTS #46 ToUnicode + URL Standard domain to Unicode
  return _uts46 $_[0], ! 'transitional', ! 'to_ascii';
} # _domain_to_unicode

sub _domain_to_ascii ($) {
  ## UTS #46 ToASCII + URL Standard domain to ASCII
  return _uts46 $_[0], 'transitional', 'to_ascii';
} # _domain_to_ascii

*canonicalize_domain_name = \&canonicalize_url_host;

sub _canonicalize_url_host_for_file ($;%) {
  my $s = $_[0];

  ## 2.
  $s = encode_web_utf8 $s;
  $s =~ s{%([0-9A-Fa-f]{2})}{pack 'C', hex $1}ge;
  $s = decode_web_utf8_no_bom $s;

  ## 3.
  $s = _domain_to_ascii $s;

  ## 4.
  return undef unless defined $s;

  ## 5.
  if ($s =~ /[\x00\x09\x0A\x0D\x20\x23\x25\x2F\x5B\x5C\x5D]/) {
    # XXX syntax violation
    return undef;
  }

  $s =~ s{([\x01-\x08\x0B\x0C\x0E-\x1F\x21\x22\x24\x26-\x2A\x2C\x3B-\x3F\x5E\x60\x7B-\x7D\x7F])}{
    sprintf '%%%02X', ord $1;
  }ge;

  return $s;
} # _canonicalize_url_host_for_file

## Spec: <https://url.spec.whatwg.org/#host-parsing>.
sub _host_parser_to_ascii ($) {
  my $s = $_[0];

  ## 1.
  if ($s =~ /\A\[/) {
    ## 1.1.
    unless ($s =~ /\]\z/) {
      ## XXX syntax violation
      return undef;
    }

    ## 1.2.
    my $t = canonicalize_ipv6_addr substr $s, 1, -2 + length $s;
    return '[' . $t . ']' if defined $t;
    return undef;
  }

  ## 2.
  $s = encode_web_utf8 $s;
  $s =~ s{%([0-9A-Fa-f]{2})}{pack 'C', hex $1}ge;
  $s = decode_web_utf8_no_bom $s;

  ## 3.
  $s = _domain_to_ascii $s;

  ## 4.
  return undef unless defined $s;

  ## 5.
  if ($s =~ /[\x00\x09\x0A\x0D\x20\x23\x25\x2F:?\x40\x5B\x5C\x5D]/) {
    # XXX syntax violation
    return undef;
  }

  ## 6., 7.
  my $ipv4 = Web::IPAddr::Canonicalize::_parse_ipv4_addr $s;
  if (defined $ipv4) {
    unless (ref $ipv4) { # An IPv4 address
      return $ipv4;
    }
  } else { # failure
    return undef;
  }

  ## 8. is for toUnicode.

  return $s;
} # _host_parser_to_ascii

sub canonicalize_url_host ($;%) {
  my ($s, %args) = @_;
  return undef unless defined $s;

  if ($args{is_file}) {
    return _canonicalize_url_host_for_file $s;
  }

  $s = _host_parser_to_ascii ($s);
  return undef unless defined $s;

  # XXX
  $s =~ s{([\x01-\x08\x0B\x0C\x0E-\x1F\x21\x22\x24\x26-\x2A\x2C\x3B-\x3E\x5E\x60\x7B-\x7D\x7F])}{
    sprintf '%%%02X', ord $1;
  }ge;

  return $s;
} # canonicalize_url_host

1;

=head1 LICENSE

Copyright 2011-2016 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
