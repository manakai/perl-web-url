package Web::URL;
use strict;
use warnings;
our $VERSION = '1.0';
use Web::URL::_Defs;
use Web::URL::Canonicalize qw(serialize_parsed_url parse_url resolve_url canonicalize_parsed_url);

sub parse_string ($$;$) {
  my $url = resolve_url $_[1], defined $_[2] ? $_[2] : parse_url 'about:blank';
  $url = canonicalize_parsed_url $url, undef;
  return undef if $url->{invalid};

  #if ($url->{is_hierarchical}) {
  #  $url->{path} = [split m{/}, $url->{path}, -1];
  #  shift @{$url->{path}};
  #} else {
  #  $url->{path} = [$url->{path}];
  #}

  return bless $url, $_[0];
} # parse_string

sub scheme ($) {
  return $_[0]->{scheme};
} # scheme

sub host ($) {
  return $_[0]->{host}; # or undef
} # host

sub port ($) {
  return $_[0]->{port}; # or undef
} # port

sub username ($) {
  return defined $_[0]->{user} ? $_[0]->{user} : '';
} # username

sub password ($) {
  return $_[0]->{password}; # or undef
} # password

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

1;

=head1 LICENSE

Copyright 2016 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
