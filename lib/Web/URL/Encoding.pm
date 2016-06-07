package Web::URL::Encoding;
use strict;
use warnings;
our $VERSION = '1.0';
use Carp;
use Web::Encoding qw(encode_web_utf8);

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

sub _form_urlencoded_pe ($) {
  my $s = encode_web_utf8 $_[0];
  $s =~ s/([^*\x2D-.0-9A-Z_a-z])/sprintf '%%%02X', ord $1/ge;
  $s =~ s/%20/\+/g;
  return $s;
} # _form_urlencoded_pe

push @EXPORT, qw(serialize_form_urlencoded);
sub serialize_form_urlencoded ($) {
  my $params = shift || {};
  return join '&', map {
    my $n = _form_urlencoded_pe $_;
    my $vs = $params->{$_};
    if (defined $vs and ref $vs eq 'ARRAY') {
      (map { $n . '=' . _form_urlencoded_pe $_ } grep { defined $_ } @$vs);
    } elsif (defined $vs) {
      ($n . '=' . _form_urlencoded_pe $vs);
    } else {
      ();
    }
  } sort { $a cmp $b } keys %$params;
} # serialize_form_urlencoded

1;

=head1 LICENSE

Copyright 2009-2013 Hatena <https://www.hatena.ne.jp/>.

Copyright 2014-2016 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
