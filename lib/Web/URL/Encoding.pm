package Web::URL::Encoding;
use strict;
use warnings;
our $VERSION = '3.0';
use Carp;
use Web::Encoding qw(encode_web_utf8 decode_web_utf8);

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

push @EXPORT, qw(percent_encode_c);
sub percent_encode_c ($) {
  my $s = encode_web_utf8 $_[0];
  $s =~ s/([^0-9A-Za-z._-])/sprintf '%%%02X', ord $1/ge;
  return $s;
} # percent_encode_c

push @EXPORT, qw(percent_decode_c);
sub percent_decode_c ($) {
  my $s = ''.$_[0];
  utf8::encode ($s) if utf8::is_utf8 ($s);
  $s =~ s/%([0-9A-Fa-f]{2})/pack 'C', hex $1/ge;
  return decode_web_utf8 $s;
} # percent_decode_c

push @EXPORT, qw(percent_decode_b);
sub percent_decode_b ($) {
  my $s = ''.$_[0];
  utf8::encode ($s) if utf8::is_utf8 ($s);
  $s =~ s/%([0-9A-Fa-f]{2})/pack 'C', hex $1/ge;
  return $s;
} # percent_decode_b

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
      (map { $n . '=' . _form_urlencoded_pe ($_ // '') } @$vs);
    } elsif (defined $vs) {
      ($n . '=' . _form_urlencoded_pe $vs);
    } else {
      ();
    }
  } sort { $a cmp $b } keys %$params;
} # serialize_form_urlencoded

## RFC 5849 3.6.
push @EXPORT, qw(oauth1_percent_encode_c);
sub oauth1_percent_encode_c ($) {
  my $s = encode_web_utf8 $_[0];
  $s =~ s/([^0-9A-Za-z._~-])/sprintf '%%%02X', ord $1/ge;
  return $s;
} # oauth1_percent_encode_c

## RFC 5849 3.6.
push @EXPORT, qw(oauth1_percent_encode_b);
sub oauth1_percent_encode_b ($) {
  my $s = ''.$_[0];
  $s =~ s/([^0-9A-Za-z._~-])/sprintf '%%%02X', ord $1/ge;
  return $s;
} # oauth1_percent_encode_b

1;

=head1 LICENSE

Copyright 2009-2013 Hatena <https://www.hatena.ne.jp/>.

Copyright 2014-2019 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
