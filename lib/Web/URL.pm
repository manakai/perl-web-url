package Web::URL;
use strict;
use warnings;
our $VERSION = '1.0';
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

sub stringify ($) {
  return serialize_parsed_url $_[0];
} # stringify

1;

=head1 LICENSE

Copyright 2016 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
