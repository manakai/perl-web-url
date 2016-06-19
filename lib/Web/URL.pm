package Web::URL;
use strict;
use warnings;
our $VERSION = '1.0';
use Web::Host;
use Web::URL::_Defs;
use Web::URL::Canonicalize qw(serialize_parsed_url parse_url resolve_url canonicalize_parsed_url);
use Web::URL::Encoding qw(serialize_form_urlencoded);

sub parse_string ($$;$) {
  my $url = resolve_url $_[1], defined $_[2] ? $_[2] : parse_url 'about:blank';
  $url = canonicalize_parsed_url $url, undef;
  return undef if $url->{invalid};

  $url->{host_parsed} = Web::Host->parse_string ($url->{host})
      if defined $url->{host};
  return bless $url, $_[0];
} # parse_string

sub scheme ($) {
  return $_[0]->{scheme};
} # scheme

sub username ($) {
  return defined $_[0]->{user} ? $_[0]->{user} : '';
} # username

sub password ($) {
  return $_[0]->{password}; # or undef
} # password

sub host ($) {
  return $_[0]->{host_parsed}; # or undef
} # host

sub port ($) {
  return $_[0]->{port}; # or undef
} # port

sub hostport ($) {
  return undef unless defined $_[0]->{host};
  return $_[0]->{host} . (defined $_[0]->{port} ? ':' . $_[0]->{port} : '');
} # hostport

sub pathquery ($) {
  return $_[0]->{path} . (defined $_[0]->{query} ? '?' . $_[0]->{query} : '');
} # pathquery

sub query ($) {
  return $_[0]->{query}; # or undef
} # query

sub set_query_params ($$;%) {
  my ($self, $params, %args) = @_;
  if ($args{append}) {
    return unless keys %$params;
    if (defined $self->{query}) {
      $self->{query} .= '&' if length $self->{query};
    } else {
      $self->{query} = '';
    }
    $self->{query} .= serialize_form_urlencoded $params;
  } else {
    $self->{query} = serialize_form_urlencoded $params;
  }
} # set_query_params

sub clone ($) {
  # $_[0]->{host_parsed} is immutable
  return bless {%{$_[0]}}, ref $_[0];
} # clone

sub get_origin ($) {
  my $self = $_[0];
  require Web::Origin;
  my $origin_type = $Web::URL::_Defs->{origin}->{$self->{scheme}} || '';
  if ($origin_type eq 'hostport') {
    return Web::Origin->new_tuple
        ($self->{scheme}, $self->{host}, $self->{port});
  } elsif ($origin_type eq 'nested') {
    my $url = Web::URL->parse_string ($self->{path});
    return $url->get_origin if defined $url;
  }
  # XXX and implementation dependent schemes
  return Web::Origin->new_opaque;
} # get_origin

sub stringify ($) {
  return serialize_parsed_url $_[0];
} # stringify

sub originpath ($) {
  local $_[0]->{user} = undef;
  local $_[0]->{password} = undef;
  local $_[0]->{query} = undef;
  local $_[0]->{fragment} = undef;
  return serialize_parsed_url $_[0];
} # originpath

sub originpathquery ($) {
  local $_[0]->{user} = undef;
  local $_[0]->{password} = undef;
  local $_[0]->{fragment} = undef;
  return serialize_parsed_url $_[0];
} # originpathquery

sub stringify_without_fragment ($) {
  local $_[0]->{fragment} = undef;
  return serialize_parsed_url $_[0];
} # stringify_without_fragment

1;

=head1 LICENSE

Copyright 2016 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
