package Web::URL::Parser;
use strict;
use warnings;
no warnings 'utf8';
our $VERSION = '2.0';
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
  ## <https://chars.suikawiki.org/set?expr=%24unicode%3Acode-points+-+%5B%5Cu0000-%5Cu00A0%5CuFF00-%5CuFF0F\u00AB\u00BB%E3%80%81%E3%80%82%5D+-+%24unicode%3AWhite_Space%20-%20$unicode:Open_Punctuation%20-%20$unicode:Close_Punctuation>
  my $nonascii = qq[\xA1-\xAA\xAC-\xBA\xBC-\x{0F39}\x{0F3E}-\x{167F}\x{1681}-\x{169A}\x{169D}-\x{1FFF}\x{200B}-\x{2019}\x{201B}-\x{201D}\x{201F}-\x{2027}\x{202A}-\x{202E}\x{2030}-\x{2044}\x{2047}-\x{205E}\x{2060}-\x{207C}\x{207F}-\x{208C}\x{208F}-\x{2307}\x{230C}-\x{2328}\x{232B}-\x{2767}\x{2776}-\x{27C4}\x{27C7}-\x{27E5}\x{27F0}-\x{2982}\x{2999}-\x{29D7}\x{29DC}-\x{29FB}\x{29FE}-\x{2E21}\x{2E2A}-\x{2E41}\x{2E43}-\x{2FFF}\x{3003}-\x{3007}\x{3012}-\x{3013}\x{301C}\x{3020}-\x{FD3D}\x{FD40}-\x{FE16}\x{FE19}-\x{FE34}\x{FE45}-\x{FE46}\x{FE49}-\x{FE58}\x{FE5F}-\x{FEFF}\x{FF10}-\x{FF3A}\x{FF3C}\x{FF3E}-\x{FF5A}\x{FF5C}\x{FF5E}\x{FF61}\x{FF64}-\x{10FFFF}];
  my $chars = qq[0-9A-Za-z._\@:=~$nonascii-];
  # $unicode:Open_Punctuation - [\u005B\u007B]
  my $Open = qq{[\x28\x{0F3A}\x{0F3C}\x{169B}\x{201A}\x{201E}\x{2045}\x{207D}\x{208D}\x{2308}\x{230A}\x{2329}\x{2768}\x{276A}\x{276C}\x{276E}\x{2770}\x{2772}\x{2774}\x{27C5}\x{27E6}\x{27E8}\x{27EA}\x{27EC}\x{27EE}\x{2983}\x{2985}\x{2987}\x{2989}\x{298B}\x{298D}\x{298F}\x{2991}\x{2993}\x{2995}\x{2997}\x{29D8}\x{29DA}\x{29FC}\x{2E22}\x{2E24}\x{2E26}\x{2E28}\x{2E42}\x{3008}\x{300A}\x{300C}\x{300E}\x{3010}\x{3014}\x{3016}\x{3018}\x{301A}\x{301D}\x{FD3F}\x{FE17}\x{FE35}\x{FE37}\x{FE39}\x{FE3B}\x{FE3D}\x{FE3F}\x{FE41}\x{FE43}\x{FE47}\x{FE59}\x{FE5B}\x{FE5D}\x{FF08}\x{FF3B}\x{FF5B}\x{FF5F}\x{FF62}]};
  # $unicode:Close_Punctuation - [\u005D\u007D]
  my $Close = qq{[\x29\x{0F3B}\x{0F3D}\x{169C}\x{2046}\x{207E}\x{208E}\x{2309}\x{230B}\x{232A}\x{2769}\x{276B}\x{276D}\x{276F}\x{2771}\x{2773}\x{2775}\x{27C6}\x{27E7}\x{27E9}\x{27EB}\x{27ED}\x{27EF}\x{2984}\x{2986}\x{2988}\x{298A}\x{298C}\x{298E}\x{2990}\x{2992}\x{2994}\x{2996}\x{2998}\x{29D9}\x{29DB}\x{29FD}\x{2E23}\x{2E25}\x{2E27}\x{2E29}\x{3009}\x{300B}\x{300D}\x{300F}\x{3011}\x{3015}\x{3017}\x{3019}\x{301B}\x{301E}-\x{301F}\x{FD3E}\x{FE18}\x{FE36}\x{FE38}\x{FE3A}\x{FE3C}\x{FE3E}\x{FE40}\x{FE42}\x{FE44}\x{FE48}\x{FE5A}\x{FE5C}\x{FE5E}\x{FF09}\x{FF3D}\x{FF5D}\x{FF60}\x{FF63}]};
  use utf8;
  my $Pattern = qr{(?:[%$chars]*\@)?(?:[0-9A-Za-z._%０-９Ａ-Ｚａ-ｚ．$nonascii-]+[.．][0-9A-Za-z._%０-９Ａ-Ｚａ-ｚ．$nonascii-]*[0-9A-Za-z_%０-９Ａ-Ｚａ-ｚ]|\[[0-9:]+\])(?::[0-9]*|)(?:[/／](?>[%/$chars]|${Open}[%/$chars]*$Close)*|)(?:\?(?>[%&;$chars]|${Open}[%&;$chars]*$Close)*|)(?:\#(?>[%&;!$chars]|${Open}[%&l!$chars]*$Close)*|)(?<![.:])};
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

{
  sub _htescape ($) {
    my $s = $_[0];
    $s =~ s/&/&amp;/g;
    $s =~ s/</&lt;/g;
    $s =~ s/"/&quot;/g;
    return $s;
  } # _htescape

  sub text_to_autolinked_html ($$;%) {
    my $self = shift;
    return join '', map {
      if (defined $_->[1] and $_->[1] =~ m{^[Hh][Tt][Tt][Pp][Ss]?://}) {
        sprintf '<a href="%s" class=url-link>%s</a>',
            _htescape $_->[1],
            _htescape $_->[0];
      } else {
        _htescape $_->[0];
      }
    } @{$self->split_by_urls (@_)};
  } # text_to_autolinked_html
}

1;

=head1 LICENSE

Copyright 2016-2019 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
