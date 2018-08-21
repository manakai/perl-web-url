package Web::URL::Parser;
use strict;
use warnings;
our $VERSION = '1.0';
use Web::URL;

sub new ($) {
  return bless {}, $_[0];
} # new

sub parse_proxy_env ($$) {
  my $value = $_[1];
  $value = 'http://' . $value unless $value =~ m{^[A-Za-z][A-Za-z0-9+.-]*://};
  return Web::URL->parse_string ($value);
} # parse_proxy_env

{
  ## <https://chars.suikawiki.org/set?expr=%24unicode%3Acode-points+-+%5B%5Cu0000-%5Cu00A0%5CuFF00-%5CuFF0F\u00AB\u00BB%E3%80%81%E3%80%82%5D+-+%24unicode%3AWhite_Space>
  my $nonascii = qq[\xA1-\xAA\xAC-\xBA\xBC-\x{167F}\x{1681}-\x{1FFF}\x{200B}-\x{2027}\x{202A}-\x{202E}\x{2030}-\x{205E}\x{2060}-\x{2FFF}\x{3003}-\x{FEFF}\x{FF10}-\x{10FFFF}];
  my $chars = qq[0-9A-Za-z._:=~$nonascii-];
  use utf8;
  my $Pattern = qr{(?:[%$chars]*\@)?(?:[0-9A-Za-z._%０-９Ａ-Ｚａ-ｚ．$nonascii]+[.．][0-9A-Za-z._%０-９Ａ-Ｚａ-ｚ．$nonascii-]*[0-9A-Za-z_%０-９Ａ-Ｚａ-ｚ]|\[[0-9:]+\])(?::[0-9]*|)(?:[/／](?>[%/$chars]|\([%/$chars]*\))*|)(?:\?(?>[%&;$chars]|\([%&;$chars]*\))*|)(?:\#(?>[%&;!$chars]|\([%&l!$chars]*\))*|)(?<![.:])};
  my $AllHTTPSScheme = qr{[HhＨｈ]?[TtＴｔ][TtＴｔ][PpＰｐ][SsＳｓ]};
  my $AllHTTPScheme = qr{[HhＨｈ]?[TtＴｔ][TtＴｔ][PpＰｐ]};
  my $MinScheme = qr{[HhＨｈ][TtＴｔ][TtＴｔ][PpＰｐ][SsＳｓ]?};
  my $MaxScheme = qr{(?:[HhＨｈ][TtＴｔ][TtＴｔ][PpＰｐ][SsＳｓ]?|ttps?)};
  my $Colon = qr{[:：][/／][/／]};
  my $EnclosedURL = qr{[Hh][Tt][Tt][Pp][Ss]?://[\x21\x23-\x3B\x3D\x3F-\x7E$nonascii]+};
  sub split_by_urls ($$;%) {
    my (undef, undef, %args) = @_;
    my $scheme = $args{lax} ? $MaxScheme : $MinScheme;
    return [map {
      if (m{\A$scheme$Colon$Pattern\z}) {
        my $x = $_;
        $x =~ s{^$AllHTTPSScheme$Colon}{https://}o;
        $x =~ s{^$AllHTTPScheme$Colon}{http://}o;
        [$_, $x];
      } elsif (m{\A<(?:URL:|)([Hh][Tt][Tt][Pp][Ss]?://.+)>\z}) {
        [$_, $1];
      } elsif (length) {
        [$_];
      } else {
        ();
      }
    } split m{((?<![A-Za-z0-9])$scheme$Colon$Pattern|<(?:URL:|)$EnclosedURL>)}, $_[1]];
  } # split_by_urls
}

1;

=head1 LICENSE

Copyright 2016-2018 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
