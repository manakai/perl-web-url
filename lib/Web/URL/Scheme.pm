package Web::URL::Scheme;
use strict;
use warnings;
our $VERSION = '1.0';
use Carp;
use Web::URL::_Defs;

our @EXPORT;

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

push @EXPORT, qw(get_default_port);
sub get_default_port ($) {
  return $Web::URL::_Defs->{default_port}->{$_[0]}; # or undef
} # get_default_port

1;

=head1 LICENSE

Copyright 2011-2016 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
