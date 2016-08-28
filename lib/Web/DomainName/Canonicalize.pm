package Web::DomainName::Canonicalize;
use strict;
use warnings;
no warnings 'utf8';
our $VERSION = '1.0';
use Carp;
use Web::Encoding;
use Web::Encoding::Normalization;
use Unicode::Stringprep;
use Web::IPAddr::Canonicalize;
use Web::DomainName::Punycode qw(encode_punycode);

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

*_nameprep_mapping = Unicode::Stringprep->new
    (3.2,
     [\@Unicode::Stringprep::Mapping::B1,
      \@Unicode::Stringprep::Mapping::B2],
     '',
     [],
     0, 0);
*_nameprep_prohibited = Unicode::Stringprep->new
    (3.2,
     [],
     '',
     [\@Unicode::Stringprep::Prohibited::C12,
      \@Unicode::Stringprep::Prohibited::C22,
      \@Unicode::Stringprep::Prohibited::C3,
      \@Unicode::Stringprep::Prohibited::C4,
      \@Unicode::Stringprep::Prohibited::C5,
      \@Unicode::Stringprep::Prohibited::C6,
      \@Unicode::Stringprep::Prohibited::C7,
      \@Unicode::Stringprep::Prohibited::C8,
      \@Unicode::Stringprep::Prohibited::C9],
     0, 0);
*_nameprep_unassigned = Unicode::Stringprep->new
    (3.2,
     [],
     '',
     [],
     0, 1);

sub _nameprep ($) {
  my $label = $_[0];
  local $@;
  
  $label =~ tr{\x{2F868}\x{2F874}\x{2F91F}\x{2F95F}\x{2F9BF}}
      {\x{36FC}\x{5F53}\x{243AB}\x{7AEE}\x{45D7}};
  $label = _nameprep_mapping ($label);
  return undef if $label =~ m{[\x{2488}-\x{249B}\x{2024}-\x{2026}]};

  my $has_unassigned = not eval { _nameprep_unassigned ($label); 1 };
  $label = to_nfkc ($label);
  if ($has_unassigned) {
    $label = _nameprep_mapping ($label);
    $label = to_nfkc $label;
  }
  
  return undef if not eval { _nameprep_prohibited ($label); 1 };
  return $label;
} # _nameprep

sub canonicalize_domain_name ($) {
  my $s = $_[0];
  return undef unless defined $s;

  my $need_punycode = $s =~ /[^\x00-\x7F]/;

  $s = _nameprep $s;
  return undef unless defined $s;

  $s =~ tr/\x{3002}\x{FF0E}\x{FF61}/.../;

  my $has_root_dot = $s =~ s/[.]\z//;

  my @label = split /\./, $s, -1;
  @label = ('') unless @label;

  if ($need_punycode) {
    @label = map {
        my $label = $_;

        if ($label =~ /[^\x00-\x7F]/) {
          return undef if $label =~ /^xn--/;
          $label = encode_punycode $label;
          return undef unless defined $label;
          $label = 'xn--' . $label;
          return undef if length $label > 63;
        } else {
          return undef if $label eq '';
          return undef if length $label > 63;
        }
        $label;
    } @label;
  }

  push @label, '' if $has_root_dot;
  $s = join '.', @label;
  
  return $s;
} # canonicalize_domain_name

sub canonicalize_url_host ($;%) {
  my ($s, %args) = @_;
  return undef unless defined $s;

  ## Spec: <https://url.spec.whatwg.org/#host-parsing>.

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
  # XXX domain to ASCII
  $s = canonicalize_domain_name $s;

  ## 4.
  return undef unless defined $s;

  ## 5.
  return undef if not $args{is_file} and $s =~ /[:?\x40]/; # XXX
  if ($s =~ /[\x00\x09\x0A\x0D\x20\x23\x25\x2F\x5B\x5C\x5D]/) {
    # XXX syntax violation
    return undef;
  }

  # XXX
  if ($args{is_file}) {
    $s =~ s{([\x00-\x2A\x2C\x2F\x3B-\x3F\x5C\x5E\x60\x7B-\x7D\x7F])}{
      sprintf '%%%02X', ord $1;
    }ge;
    return $s;
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

  # XXX
  $s =~ s{([\x01-\x08\x0B\x0C\x0E-\x1F\x21\x22\x24\x26-\x2A\x2C\x3B-\x3E\x5E\x60\x7B-\x7D\x7F])}{
    sprintf '%%%02X', ord $1;
  }ge;

  ## 8.
  # XXX domain to Unicode, if Unicode flag is true
  return $s;
} # canonicalize_url_host

1;

=head1 LICENSE

Copyright 2011-2016 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
