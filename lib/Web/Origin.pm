package Web::Origin;
use strict;
use warnings;
our $VERSION = '1.0';
use Carp qw(croak);
use Web::URL::Canonicalize qw(serialize_parsed_url);

sub new_opaque ($) {
  return bless {}, $_[0];
} # new_opaque

sub new_tuple ($$$$) {
  return bless {
    scheme => $_[1],
    host => $_[2],
    port => $_[3],
  }, $_[0];
} # new_tuple

sub is_opaque ($) {
  return not defined $_[0]->{scheme};
} # is_opaque

sub set_domain ($;$) {
  croak "The host is not a domain" unless $_[1]->is_domain;
  croak "Can't set domain of an opaque origin" unless defined $_[0]->{scheme};
  $_[0]->{domain} = $_[1];
} # set_domain

sub same_origin_as ($$) {
  if ($_[0]->is_opaque) {
    if ($_[1]->is_opaque) {
      return $_[0] eq $_[1];
    } else {
      return 0;
    }
  } else {
    if ($_[1]->is_opaque) {
      return 0;
    } else {
      return ($_[0]->{scheme} eq $_[1]->{scheme} and
              $_[0]->{host} eq $_[1]->{host} and
              ((not defined $_[0]->{port} and not defined $_[1]->{port}) or
               (defined $_[0]->{port} and defined $_[1]->{port} and
                $_[0]->{port} == $_[1]->{port})));
    }
  }
} # same_origin_as

sub same_origin_domain_as ($$) {
  if ($_[0]->is_opaque) {
    if ($_[1]->is_opaque) {
      return $_[0] eq $_[1];
    } else {
      return 0;
    }
  } else {
    if ($_[1]->is_opaque) {
      return 0;
    } else {
      if (defined $_[0]->{domain} and defined $_[1]->{domain}) {
        return ($_[0]->{scheme} eq $_[1]->{scheme} and
                $_[0]->{domain}->equals ($_[1]->{domain}));
      } elsif (not defined $_[0]->{domain} and not defined $_[1]->{domain}) {
        return ($_[0]->{scheme} eq $_[1]->{scheme} and
                $_[0]->{host} eq $_[1]->{host} and
                ((not defined $_[0]->{port} and not defined $_[1]->{port}) or
                 (defined $_[0]->{port} and defined $_[1]->{port} and
                  $_[0]->{port} == $_[1]->{port})));
      } else {
        return 0;
      }
    }
  }
} # same_origin_domain_as

sub to_ascii ($) {
  if ($_[0]->is_opaque) {
    return 'null';
  } else {
    return serialize_parsed_url $_[0];
  }
} # to_ascii

# XXX to_unicode

1;

=head1 LICENSE

Copyright 2016 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
