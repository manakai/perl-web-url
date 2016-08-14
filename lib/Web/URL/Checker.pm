package Web::URL::Checker;
use strict;
use warnings;
our $VERSION = '9.0';
use Web::Encoding;

# XXX URL Standard support

# XXX scheme-dependent conformance

sub new_from_string ($$) {
  return bless {value => $_[1]}, $_[0];
} # new_from_string

sub onerror ($;$) {
  if (@_ > 1) {
    $_[0]->{onerror} = $_[1];
  }
  return $_[0]->{onerror} ||= sub {
    my %args = @_;
    warn sprintf qq{"%s": %s (%s)\n},
        $args{value}, $args{type}, $args{level};
  };
} # onerror

sub _uri_scheme ($) {
  if ($_[0]->{value} =~ m!^([^/?#:]+):!) {
    return $1;
  } else {
    return undef;
  }
} # _uri_scheme

sub _uri_authority ($) {
  if ($_[0]->{value} =~ m!^(?:[^:/?#]+:)?(?://([^/?#]*))?!) {
    return $1;
  } else {
    return undef;
  }
} # _uri_authority

sub _uri_userinfo ($) {
  my $v = $_[0]->_uri_authority;
  if (defined $v and $v =~ /^([^@\[\]]*)\@/) {
    return $1;
  } else {
    return undef;
  }
} # _uri_userinfo

sub _uri_host ($) {
  my $v = $_[0]->_uri_authority;
  if (defined $v) {
    $v =~ s/^[^@\[\]]*\@//;
    $v =~ s/:[0-9]*\z//;
    return $v;
  } else {
    return undef;
  }
} # _uri_host

sub _uri_port ($) {
  my $v = $_[0]->_uri_authority;
  if (defined $v and $v =~ /:([0-9]*)\z/) {
    return $1;
  } else {
    return undef;
  }
} # _uri_port

sub _uri_path ($) {
  if ($_[0]->{value} =~ m!\A(?:[^:/?#]+:)?(?://[^/?#]*)?([^?#]*)!) {
    return $1;
  } else {
    die "No URI path";
  }
} # _uri_path

sub _uri_query ($) {
  if ($_[0]->{value} =~ m!^(?:[^:/?#]+:)?(?://[^/?#]*)?[^?#]*(?:\?([^#]*))?!s) {
    return $1;
  } else {
    return undef;
  }
} # _uri_query

sub _uri_fragment ($) {
  if ($_[0]->{value} =~ m!^(?:[^:/?#]+:)?(?://[^/?#]*)?[^?#]*(?:\?[^#]*)?(?:#(.*))?!s) {
    return $1;
  } else {
    return undef;
  }
} # _uri_fragment

*is_uri = \&is_uri_3986;

sub is_uri_3986 ($) {
  my $v = $_[0]->{value};

  ## Scheme
  return 0 unless $v =~ s/^[A-Za-z][A-Za-z0-9+.-]*://s;

  ## Fragment
  if ($v =~ s/#(.*)\z//s) {
    my $w = $1;
    return 0 unless $w =~ m{\A(?>[A-Za-z0-9._~!\$&'()*+,;=:\@/?-]|%[0-9A-Fa-f][0-9A-Fa-f])*\z};
  }

  ## Query
  if ($v =~ s/\?(.*)\z//s) {
    my $w = $1;
    return 0 unless $w =~ m{\A(?>[A-Za-z0-9._~!\$&'()*+,;=:\@/?-]|%[0-9A-Fa-f][0-9A-Fa-f])*\z};
  }

  ## Authority
  if ($v =~ s!^//([^/]*)!!s) {
    my $w = $1;
    $w =~ s/^(?>[A-Za-z0-9._~!\$&'()*+,;=:-]|%[0-9A-Fa-f][0-9A-Fa-f])*\@//os;
    $w =~ s/:[0-9]*\z//;
    if ($w =~ /^\[(.*)\]\z/s) {
      my $x = $1;
      unless ($x =~ /\A[vV][0-9A-Fa-f]+\.[A-Za-z0-9._~!\$&'()*+,;=:-]+\z/) {
        ## IPv6address
        my $isv6;
        my $ipv4 = qr/(?>0|1[0-9]{0,2}|2(?>[0-4][0-9]?|5[0-5]?|[6-9])?|[3-9][0-9]?)(?>\.(?>0|1[0-9]{0,2}|2(?>[0-4][0-9]?|5[0-5]?|[6-9])?|[3-9][0-9]?)){3}/;
        my $h16 = qr/[0-9A-Fa-f]{1,4}/;
        if ($x =~ s/(?:$ipv4|$h16)\z//o) {
          if ($x =~ /\A(?>$h16:){6}\z/o or
              $x =~ /\A::(?>$h16:){0,5}\z/o or
              $x =~ /\A${h16}::(?>$h16:){4}\z/o or
              $x =~ /\A$h16(?::$h16)?::(?>$h16:){3}\z/o or
              $x =~ /\A$h16(?::$h16){0,2}::(?>$h16:){2}\z/o or
              $x =~ /\A$h16(?::$h16){0,3}::$h16:\z/o or
              $x =~ /\A$h16(?::$h16){0,4}::\z/o) {
            $isv6 = 1;
          }
        } elsif ($x =~ s/$h16\z//o) {
          if ($x eq '' or $x =~ /\A$h16(?>:$h16){0,5}\z/o) {
            $isv6 = 1;
          }
        } elsif ($x =~ s/::\z//o) {
          if ($x eq '' or $x =~ /\A$h16(?>:$h16){0,6}\z/o) {
            $isv6 = 1;
          }
        }
        return 0 unless $isv6;
      }
    } else {
      return 0 unless $w =~ /\A(?>[A-Za-z0-9._~!\$&'()*+,;=-]|%[0-9A-Fa-f][0-9A-Fa-f])*\z/;
    }
  }
  
  ## Path
  return 0 unless $v =~ m{\A(?>[A-Za-z0-9._~!\$&'()*+,;=:\@/-]|%[0-9A-Fa-f][0-9A-Fa-f])*\z}s;
  
  return 1;
} # is_uri_3986

*is_relative_reference = \&is_relative_reference_3986;

sub is_relative_reference_3986 ($) {
  my $v = $_[0]->{value};

  ## No scheme
  return 0 if $v =~ s!^[^/?#]*:!!s;

  ## Fragment
  if ($v =~ s/#(.*)\z//s) {
    my $w = $1;
    return 0 unless $w =~ m{\A(?>[A-Za-z0-9._~!\$&'()*+,;=:\@/?-]|%[0-9A-Fa-f][0-9A-Fa-f])*\z};
  }

  ## Query
  if ($v =~ s/\?(.*)\z//s) {
    my $w = $1;
    return 0 unless $w =~ m{\A(?>[A-Za-z0-9._~!\$&'()*+,;=:\@/?-]|%[0-9A-Fa-f][0-9A-Fa-f])*\z};
  }

  ## Authority
  if ($v =~ s!^//([^/]*)!!s) {
    my $w = $1;
    $w =~ s/^(?>[A-Za-z0-9._~!\$&'()*+,;=:-]|%[0-9A-Fa-f][0-9A-Fa-f])*\@//os;
    $w =~ s/:[0-9]*\z//;
    if ($w =~ /^\[(.*)\]\z/s) {
      my $x = $1;
      unless ($x =~ /\A[vV][0-9A-Fa-f]+\.[A-Za-z0-9._~!\$&'()*+,;=:-]+\z/) {
        ## IPv6address
        my $isv6;
        my $ipv4 = qr/(?>0|1[0-9]{0,2}|2(?>[0-4][0-9]?|5[0-5]?|[6-9])?|[3-9][0-9]?)(?>\.(?>0|1[0-9]{0,2}|2(?>[0-4][0-9]?|5[0-5]?|[6-9])?|[3-9][0-9]?)){3}/;
        my $h16 = qr/[0-9A-Fa-f]{1,4}/;
        if ($x =~ s/(?:$ipv4|$h16)\z//o) {
          if ($x =~ /\A(?>$h16:){6}\z/o or
              $x =~ /\A::(?>$h16:){0,5}\z/o or
              $x =~ /\A${h16}::(?>$h16:){4}\z/o or
              $x =~ /\A$h16(?::$h16)?::(?>$h16:){3}\z/o or
              $x =~ /\A$h16(?::$h16){0,2}::(?>$h16:){2}\z/o or
              $x =~ /\A$h16(?::$h16){0,3}::$h16:\z/o or
              $x =~ /\A$h16(?::$h16){0,4}::\z/o) {
            $isv6 = 1;
          }
        } elsif ($x =~ s/$h16\z//o) {
          if ($x eq '' or $x =~ /\A$h16(?>:$h16){0,5}\z/o) {
            $isv6 = 1;
          }
        } elsif ($x =~ s/::\z//o) {
          if ($x eq '' or $x =~ /\A$h16(?>:$h16){0,6}\z/o) {
            $isv6 = 1;
          }
        }
        return 0 unless $isv6;
      }
    } else {
      return 0 unless $w =~ /\A(?>[A-Za-z0-9._~!\$&'()*+,;=-]|%[0-9A-Fa-f][0-9A-Fa-f])*\z/;
    }
  }

  ## Path
  return 0 unless $v =~ m{\A(?>[A-Za-z0-9._~!\$&'()*+,;=:\@/-]|%[0-9A-Fa-f][0-9A-Fa-f])*\z}s;

  return 1;
} # is_relative_reference_3986

*is_uri_reference = \&is_uri_reference_3986;

sub is_uri_reference_3986 ($) {
  return $_[0]->is_uri_3986 || $_[0]->is_relative_reference_3986;
} # is_uri_reference_3986

*is_absolute_uri = \&is_absolute_uri_3986;

sub is_absolute_uri_3986 ($) {
  return $_[0]->{value} !~ /#/ && $_[0]->is_uri_3986;
} # is_uri_reference_3986

sub is_empty_reference ($) {
  return $_[0]->{value} eq '';
} # is_empty_reference

*is_iri = \&is_iri_3987;

sub is_iri_3987 ($) {
  my $v = $_[0]->{value};

  ## |ucschar| except for:
  ## LRM, RLM, LRE, RLE, LRO, RLO, PDF
  ## U+200E, U+200F, U+202A - U+202E
  my $ucschar = qq{\x{00A0}-\x{200D}\x{2010}-\x{2029}\x{202F}-\x{D7FF}\x{F900}-\x{FDCF}\x{FDF0}-\x{FFEF}\x{10000}-\x{1FFFD}\x{20000}-\x{2FFFD}\x{30000}-\x{3FFFD}\x{40000}-\x{4FFFD}\x{50000}-\x{5FFFD}\x{60000}-\x{6FFFD}\x{70000}-\x{7FFFD}\x{80000}-\x{8FFFD}\x{90000}-\x{9FFFD}\x{A0000}-\x{AFFFD}\x{B0000}-\x{BFFFD}\x{C0000}-\x{CFFFD}\x{D0000}-\x{DFFFD}\x{E1000}-\x{EFFFD}};

  ## Scheme
  return 0 unless $v =~ s/^[A-Za-z][A-Za-z0-9+.-]*://s;
  
  ## Fragment
  if ($v =~ s/#(.*)\z//s) {
    my $w = $1;
    return 0 unless $w =~ m{\A(?>[A-Za-z0-9._~!\$&'()*+,;=:\@/?$ucschar-]|%[0-9A-Fa-f][0-9A-Fa-f])*\z}o;
  }

  ## Query
  if ($v =~ s/\?(.*)\z//s) {
    my $w = $1;
    return 0 unless $w =~ m{\A(?>[A-Za-z0-9._~!\$&'()*+,;=:\@/?$ucschar\x{E000}-\x{F8FF}\x{F0000}-\x{FFFFD}\x{100000}-\x{10FFFD}-]|%[0-9A-Fa-f][0-9A-Fa-f])*\z}o;
  }

  ## Authority
  if ($v =~ s!^//([^/]*)!!s) {
    my $w = $1;
    $w =~ s/^(?>[A-Za-z0-9._~!\$&'()*+,;=:$ucschar-]|%[0-9A-Fa-f][0-9A-Fa-f])*\@//os;
    $w =~ s/:[0-9]*\z//;
    if ($w =~ /^\[(.*)\]\z/s) {
      my $x = $1;
      unless ($x =~ /\A[vV][0-9A-Fa-f]+\.[A-Za-z0-9._~!\$&'()*+,;=:-]+\z/) {
        ## IPv6address
        my $isv6;
        my $ipv4 = qr/(?>0|1[0-9]{0,2}|2(?>[0-4][0-9]?|5[0-5]?|[6-9])?|[3-9][0-9]?)(?>\.(?>0|1[0-9]{0,2}|2(?>[0-4][0-9]?|5[0-5]?|[6-9])?|[3-9][0-9]?)){3}/;
        my $h16 = qr/[0-9A-Fa-f]{1,4}/;
        if ($x =~ s/(?:$ipv4|$h16)\z//o) {
          if ($x =~ /\A(?>$h16:){6}\z/o or
              $x =~ /\A::(?>$h16:){0,5}\z/o or
              $x =~ /\A${h16}::(?>$h16:){4}\z/o or
              $x =~ /\A$h16(?::$h16)?::(?>$h16:){3}\z/o or
              $x =~ /\A$h16(?::$h16){0,2}::(?>$h16:){2}\z/o or
              $x =~ /\A$h16(?::$h16){0,3}::$h16:\z/o or
              $x =~ /\A$h16(?::$h16){0,4}::\z/o) {
            $isv6 = 1;
          }
        } elsif ($x =~ s/$h16\z//o) {
          if ($x eq '' or $x =~ /\A$h16(?>:$h16){0,5}\z/o) {
            $isv6 = 1;
          }
        } elsif ($x =~ s/::\z//o) {
          if ($x eq '' or $x =~ /\A$h16(?>:$h16){0,6}\z/o) {
            $isv6 = 1;
          }
        }
        return 0 unless $isv6;
      }
    } else {
      return 0 unless $w =~ /\A(?>[A-Za-z0-9._~!\$&'()*+,;=$ucschar-]|%[0-9A-Fa-f][0-9A-Fa-f])*\z/o;
    }
  }

  ## Path
  return 0 unless $v =~ m{\A(?>[A-Za-z0-9._~!\$&'()*+,;=:\@/$ucschar-]|%[0-9A-Fa-f][0-9A-Fa-f])*\z}os;

  return 1;
} # is_iri_3987

*is_relative_iri_reference = \&is_relative_iri_reference_3987;

sub is_relative_iri_reference_3987 ($) {
  my $v = $_[0]->{value};

  ## |ucschar| except for:
  ## LRM, RLM, LRE, RLE, LRO, RLO, PDF
  ## U+200E, U+200F, U+202A - U+202E
  my $ucschar = qq{\x{00A0}-\x{200D}\x{2010}-\x{2029}\x{202F}-\x{D7FF}\x{F900}-\x{FDCF}\x{FDF0}-\x{FFEF}\x{10000}-\x{1FFFD}\x{20000}-\x{2FFFD}\x{30000}-\x{3FFFD}\x{40000}-\x{4FFFD}\x{50000}-\x{5FFFD}\x{60000}-\x{6FFFD}\x{70000}-\x{7FFFD}\x{80000}-\x{8FFFD}\x{90000}-\x{9FFFD}\x{A0000}-\x{AFFFD}\x{B0000}-\x{BFFFD}\x{C0000}-\x{CFFFD}\x{D0000}-\x{DFFFD}\x{E1000}-\x{EFFFD}};

  ## No scheme
  return 0 if $v =~ s!^[^/?#]*:!!s;

  ## Fragment
  if ($v =~ s/#(.*)\z//s) {
    my $w = $1;
    return 0 unless $w =~ m{\A(?>[A-Za-z0-9._~!\$&'()*+,;=:\@/?$ucschar-]|%[0-9A-Fa-f][0-9A-Fa-f])*\z}o;
  }

  ## Query
  if ($v =~ s/\?(.*)\z//s) {
    my $w = $1;
    return 0 unless $w =~ m{\A(?>[A-Za-z0-9._~!\$&'()*+,;=:\@/?$ucschar\x{E000}-\x{F8FF}\x{F0000}-\x{FFFFD}\x{100000}-\x{10FFFD}-]|%[0-9A-Fa-f][0-9A-Fa-f])*\z}o;
  }

  ## Authority
  if ($v =~ s!^//([^/]*)!!s) {
    my $w = $1;
    $w =~ s/^(?>[A-Za-z0-9._~!\$&'()*+,;=:$ucschar-]|%[0-9A-Fa-f][0-9A-Fa-f])*\@//os;
    $w =~ s/:[0-9]*\z//;
    if ($w =~ /^\[(.*)\]\z/s) {
      my $x = $1;
      unless ($x =~ /\A[vV][0-9A-Fa-f]+\.[A-Za-z0-9._~!\$&'()*+,;=:-]+\z/) {
        ## IPv6address
        my $isv6;
        my $ipv4 = qr/(?>0|1[0-9]{0,2}|2(?>[0-4][0-9]?|5[0-5]?|[6-9])?|[3-9][0-9]?)(?>\.(?>0|1[0-9]{0,2}|2(?>[0-4][0-9]?|5[0-5]?|[6-9])?|[3-9][0-9]?)){3}/;
        my $h16 = qr/[0-9A-Fa-f]{1,4}/;
        if ($x =~ s/(?:$ipv4|$h16)\z//o) {
          if ($x =~ /\A(?>$h16:){6}\z/o or
              $x =~ /\A::(?>$h16:){0,5}\z/o or
              $x =~ /\A${h16}::(?>$h16:){4}\z/o or
              $x =~ /\A$h16(?::$h16)?::(?>$h16:){3}\z/o or
              $x =~ /\A$h16(?::$h16){0,2}::(?>$h16:){2}\z/o or
              $x =~ /\A$h16(?::$h16){0,3}::$h16:\z/o or
              $x =~ /\A$h16(?::$h16){0,4}::\z/o) {
            $isv6 = 1;
          }
        } elsif ($x =~ s/$h16\z//o) {
          if ($x eq '' or $x =~ /\A$h16(?>:$h16){0,5}\z/o) {
            $isv6 = 1;
          }
        } elsif ($x =~ s/::\z//o) {
          if ($x eq '' or $x =~ /\A$h16(?>:$h16){0,6}\z/o) {
            $isv6 = 1;
          }
        }
        return 0 unless $isv6;
      }
    } else {
      return 0 unless $w =~ /\A(?>[A-Za-z0-9._~!\$&'()*+,;=$ucschar-]|%[0-9A-Fa-f][0-9A-Fa-f])*\z/o;
    }
  }

  ## Path
  return 0 unless $v =~ m{\A(?>[A-Za-z0-9._~!\$&'()*+,;=:\@/$ucschar-]|%[0-9A-Fa-f][0-9A-Fa-f])*\z}os;

  return 1;
} # is_relative_iri_reference_3987

*is_iri_reference = \&is_iri_reference_3987;

sub is_iri_reference_3987 ($) {
  return $_[0]->is_iri_3987 || $_[0]->is_relative_iri_reference_3987;
} # is_iri_reference_3987

*is_absolute_iri = \&is_absolute_iri_3987;

sub is_absolute_iri_3987 ($) {
  return $_[0]->{value} !~ /#/ && $_[0]->is_iri_3987;
} # is_absolute_iri_3987

sub get_uri_reference ($) {
  return $_[0]->get_uri_reference_3986;
} # get_uri_reference

sub get_uri_reference_3986 ($) {
  my $v = encode_web_utf8 $_[0]->{value};
  $v =~ s/([<>"{}|\\\^`\x00-\x20\x7E-\xFF])/sprintf '%%%02X', ord $1/ge;
  return $v;
} # get_uri_reference_3986

sub get_iri_reference ($) {
  return $_[0]->get_iri_reference_3987;
} # get_iri_reference

sub get_iri_reference_3987 ($) {
  my $v = encode_web_utf8 $_[0]->{value};
  $v =~ s{%([2-9A-Fa-f][0-9A-Fa-f])}
         {
           my $ch = hex $1;
           if ([
         # 0x0    0x1    0x2    0x3    0x4    0x5    0x6    0x7
         # 0x8    0x9    0xA    0xB    0xC    0xD    0xE    0xF
           1,  1,  1,  1,  1,  1,  1,  1, # 0x00
           1,  1,  1,  1,  1,  1,  1,  1, # 0x08
           1,  1,  1,  1,  1,  1,  1,  1, # 0x10
           1,  1,  1,  1,  1,  1,  1,  1, # 0x18
           1,  1,  1,  1,  1,  1,  1,  1, # 0x20
           1,  1,  1,  1,  1,  0,  0,  1, # 0x28
           0,  0,  0,  0,  0,  0,  0,  0, # 0x30
           0,  0,  1,  1,  1,  1,  1,  1, # 0x38
           1,  0,  0,  0,  0,  0,  0,  0, # 0x40
           0,  0,  0,  0,  0,  0,  0,  0, # 0x48
           0,  0,  0,  0,  0,  0,  0,  0, # 0x50
           0,  0,  0,  1,  1,  1,  1,  0, # 0x58
           1,  0,  0,  0,  0,  0,  0,  0, # 0x60
           0,  0,  0,  0,  0,  0,  0,  0, # 0x68
           0,  0,  0,  0,  0,  0,  0,  0, # 0x70
           0,  0,  0,  1,  1,  1,  0,  1, # 0x78
         # 0x0    0x1    0x2    0x3    0x4    0x5    0x6    0x7
         # 0x8    0x9    0xA    0xB    0xC    0xD    0xE    0xF
           ]->[$ch]) {
             # PERCENT SIGN, reserved, not-allowed in ASCII
             '%'.$1;
           } else {
             pack 'C', $ch;
           }
         }ge;
  $v =~ s{(
    [\xC2-\xDF][\x80-\xBF] |                          # UTF8-2
    [\xE0][\xA0-\xBF][\x80-\xBF] |
    [\xE1-\xEC][\x80-\xBF][\x80-\xBF] |
    [\xED][\x80-\x9F][\x80-\xBF] |
    [\xEE\xEF][\x80-\xBF][\x80-\xBF] |                # UTF8-3
    [\xF0][\x90-\xBF][\x80-\xBF][\x80-\xBF] |
    [\xF1-\xF3][\x80-\xBF][\x80-\xBF][\x80-\xBF] |
    [\xF4][\x80-\x8F][\x80-\xBF][\x80-\xBF] |           # UTF8-4
    [\x80-\xFF]
  )}{
    my $c = $1;
    if (length ($c) == 1) {
      $c =~ s/(.)/sprintf '%%%02X', ord $1/ge;
      $c;
    } else {
      my $ch = decode_web_utf8 $c;
      if ($ch =~ /^[\x{00A0}-\x{200D}\x{2010}-\x{2029}\x{202F}-\x{D7FF}\x{F900}-\x{FDCF}\x{FDF0}-\x{FFEF}\x{10000}-\x{1FFFD}\x{20000}-\x{2FFFD}\x{30000}-\x{3FFFD}\x{40000}-\x{4FFFD}\x{50000}-\x{5FFFD}\x{60000}-\x{6FFFD}\x{70000}-\x{7FFFD}\x{80000}-\x{8FFFD}\x{90000}-\x{9FFFD}\x{A0000}-\x{AFFFD}\x{B0000}-\x{BFFFD}\x{C0000}-\x{CFFFD}\x{D0000}-\x{DFFFD}\x{E1000}-\x{EFFFD}]/) {
        $c;
      } else {
        $c =~ s/([\x80-\xFF])/sprintf '%%%02X', ord $1/ge;
        $c;
      }
    }
  }gex;
  $v =~ s/([<>"{}|\\\^`\x00-\x20\x7F])/sprintf '%%%02X', ord $1/ge;
  return decode_web_utf8 $v;
} # get_iri_reference_3987

sub get_absolute_reference ($$;%) {
  #my ($self, $base, %opt) = @_;
  return shift->get_absolute_reference_3986 (@_);
} # get_absolute_reference

sub get_absolute_reference_3986 ($$%) {
  my ($self, $base, %opt) = @_;
  my $r;
  ## Decomposition
  my ($b_scheme, $b_auth, $b_path, $b_query, $b_frag);
  my ($r_scheme, $r_auth, $r_path, $r_query, $r_frag);

  if ($self->{value} =~ m!\A(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?\z!s) {
    ($r_scheme, $r_auth, $r_path, $r_query, $r_frag) = ($1, $2, $3, $4, $5);
  } else { # unlikely happen
    ($r_scheme, $r_auth, $r_path, $r_query, $r_frag)
        = (undef, undef, '', undef, undef);
  }
  if ($base =~ m!\A(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?\z!s) {
    ($b_scheme, $b_auth, $b_path, $b_query, $b_frag)
      = (defined $1 ? $1 : '', $2, $3, $4, $5);
  } else { # unlikely happen
    ($b_scheme, $b_auth, $b_path, $b_query, $b_frag)
        = ('', undef, '', undef, undef);
  }

  ## Merge
  my $path_merge = sub ($$) {
    my ($bpath, $rpath) = @_;
    if ($bpath eq '') {
      return '/'.$rpath;
    }
    $bpath =~ s/[^\/]*\z//;
    return $bpath . $rpath;
  }; # merge

  ## Removing Dot Segments
  my $remove_dot_segments = sub ($) {
    local $_ = shift;
    my $buf = '';
    L: while (length $_) {
      next L if s/^\.\.?\///;
      next L if s/^\/\.(?:\/|\z)/\//;
      if (s/^\/\.\.(\/|\z)/\//) {
        $buf =~ s/\/?[^\/]*$//;
        next L;
      }
      last Z if s/^\.\.?\z//;
      s/^(\/?[^\/]*)//;
      $buf .= $1;
    }
    return $buf;
  }; # remove_dot_segments

  ## Transformation
  my ($t_scheme, $t_auth, $t_path, $t_query, $t_frag);

  if ($opt{non_strict} and $r_scheme eq $b_scheme) {
    undef $r_scheme;
  }

  if (defined $r_scheme) {
    $t_scheme = $r_scheme;
    $t_auth   = $r_auth;
    $t_path   = $remove_dot_segments->($r_path);
    $t_query  = $r_query;
  } else {
    if (defined $r_auth) {
      $t_auth  = $r_auth;
      $t_path  = $remove_dot_segments->($r_path);
      $t_query = $r_query;
    } else {
      if ($r_path =~ /\A\z/) {
        $t_path = $b_path;
        if (defined $r_query) {
          $t_query = $r_query;
        } else {
          $t_query = $b_query;
        }
      } elsif ($r_path =~ /^\//) {
        $t_path  = $remove_dot_segments->($r_path);
        $t_query = $r_query;
      } else {
        $t_path  = $path_merge->($b_path, $r_path);
        $t_path  = $remove_dot_segments->($t_path);
        $t_query = $r_query;
      }
      $t_auth = $b_auth;
    }
    $t_scheme = $b_scheme;
  }
  $t_frag = $r_frag;

  ## -- Recomposition
  my $result  = ''                                      ;
  $result .=        $t_scheme . ':' if defined $t_scheme;
  $result .= '//' . $t_auth         if defined $t_auth  ;
  $result .=        $t_path                             ;
  $result .= '?'  . $t_query        if defined $t_query ;
  $result .= '#'  . $t_frag         if defined $t_frag  ;

  return $result;
} # get_absolute_reference_3986

sub get_absolute_reference_3987 ($$;%) {
  #my ($self, $base, %opt) = @_;
  return shift->get_absolute_reference_3986 (@_);
} # get_absolute_reference_3987

sub is_same_document_reference ($$) {
  #my ($self, $base) = @_;
  return $_[0]->is_same_document_reference_3986 ($_[1]);
} # is_same_document_reference

sub is_same_document_reference_3986 ($$;%) {
  my ($self, $base, %opt) = @_;
  if (substr ($self->{value}, 0, 1) eq '#') {
    return 1;
  } else {
    my $target = $self->get_absolute_reference_3986
        ($base, non_strict => $opt{non_strict});
    $target =~ s/#.*\z//;
    $base =~ s/#.*\z//;
    return ($target eq $base);
  }
} # is_same_document_reference_3986

sub get_relative_reference ($$) {
  my ($self, $base) = @_;
  my @base;
  if ($base =~ m!\A(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?\z!) {
    (@base) = (defined $1 ? $1 : '', $2, $3, $4, $5);
  } else { # unlikeley happen
    (@base) = ('', undef, '', undef, undef);
  }
  my @t;
  my $t = $self->get_absolute_reference ($base);
  if ($t =~ m!\A(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?\z!) {
    (@t) = (defined $1 ? $1 : '', $2, $3, $4, $5);
  } else { # unlikeley happen
    (@t) = ('', undef, '', undef, undef);
  }

  my @ref;
  R: {
    ## Scheme
    if ($base[0] ne $t[0]) {
      (@ref) = @t;
      last R;
    }

    ## Authority
    if (not defined $base[1] and not defined $t[1]) {
      (@ref) = @t;
      last R;
    } elsif (not defined $t[1]) {
      (@ref) = @t;
      last R;
    } elsif (not defined $base[1]) {
      (@ref) = @t;
      last R;
    } elsif ($base[1] ne $t[1]) {
      (@ref) = @t;
      last R;
    }
    ## NOTE: Avoid uncommon references.

    if (defined $t[4] and                                # fragment
        $t[2] eq $base[2] and                            # path
        ((not defined $t[3] and not defined $base[3]) or # query
         (defined $t[3] and defined $base[3] and $t[3] eq $base[3]))) {
      (@ref) = (undef, undef, '', undef, $t[4]);
      last R;
    }

    ## Path
    my @tpath = split m!/!, $t[2], -1;
    my @bpath = split m!/!, $base[2], -1;
    if (@tpath < 1 or @bpath < 1) {  ## No |/|
      (@ref) = @t;
      last R;
    }
    my $bpl;

    ## Removes common segments
    while (@tpath and @bpath and $tpath[0] eq $bpath[0]) {
      shift @tpath;
      $bpl = shift @bpath;
    }

    if (@tpath == 0) {
      if (@bpath == 0) { ## Avoid empty path for backward compatibility
        unshift @tpath, $bpl;
      } else {
        unshift @tpath, '..', $bpl;
      }
    } elsif (@bpath == 0) {
      unshift @tpath, $bpl;
    }

    unshift @tpath, ('..') x (@bpath - 1) if @bpath > 1;

    unshift @tpath, '.' if $tpath[0] eq '' or
                           $tpath[0] =~ /:/;

    (@ref) = (undef, undef, (join '/', @tpath), $t[3], $t[4]);
  } # R

  ## -- Recomposition
  my $result = ''                                   ;
  $result .=        $ref[0] . ':' if defined $ref[0];  # scheme;
  $result .= '//' . $ref[1]       if defined $ref[1];  # authority
  $result .=        $ref[2]                         ;  # path
  $result .= '?'  . $ref[3]       if defined $ref[3];  # query
  $result .= '#'  . $ref[4]       if defined $ref[4];  # fragment
  return $result;
} # get_relative_reference

our $DefaultPort = {
  http => 80,
};

my $ErrorLevels = {
  uri_fact => 'm',
  uri_lc_must => 'm', ## Non-RFC 2119 "must" (or fact)
  uri_lc_should => 'w', ## Non-RFC 2119 "should"
  uri_syntax => 'm',

  rdf_fact => 'm',
}; # $ErrorLevels

*check_iri = \&check_iri_3987;

sub check_iri_3987 ($) {
  my $self = $_[0];
  unless ($self->is_iri_3987) {
    $self->onerror->(type => 'syntax error:iri3987',
                     level => $ErrorLevels->{uri_syntax},
                     value => $self->{value});
  }
  $self->check_iri_reference_3987;
} # check_iri

*check_iri_reference = \&check_iri_reference_3987;

sub check_iri_reference_3987 ($) {
  my $self = $_[0];

  ## RFC 3987 4.1.
  unless ($self->is_iri_reference_3987) {
    $self->onerror->(type => 'syntax error:iriref3987',
                     level => $ErrorLevels->{uri_syntax},
                     value => $self->{value});
    ## MUST (NOTE: A requirement for bidi IRIs.)
  }
  
  ## RFC 3986 2.1., 6.2.2.1., RFC 3987 5.3.2.1.
  pos ($self->{value}) = 0;
  while ($self->{value} =~ /%([a-f][0-9A-Fa-f]|[0-9A-F][a-f])/g) {
    $self->onerror->(type => 'URL:lowercase hexadecimal digit',
                     level => $ErrorLevels->{uri_lc_should},
                     value => $self->{value},
                     pos_start => $-[0], pos_end => $+[0]);
    ## shoult not
  }
  
  ## RFC 3986 2.2.
  ## URI producing applications should percent-encode ... reserved ...
  ## unless ... allowed by the URI scheme .... --- This is not testable.

  ## RFC 3986 2.3., 6.2.2.2., RFC 3987 5.3.2.3.
  pos ($self->{value}) = 0;
  while ($self->{value} =~ /%(2[DdEe]|4[1-9A-Fa-f]|5[AaFf]|6[1-9A-Fa-f]|7[AaEe])/g) {
    $self->onerror->(type => 'URL:percent-encoded unreserved',
                     level => $ErrorLevels->{uri_lc_should},
                     value => $self->{value},
                     pos_start => $-[0], pos_end => $+[0]);
    ## should
    ## should
  }

  ## RFC 3986 2.4.
  ## ... "%" ... must be percent-encoded as "%25" ...
  ## --- Either syntax error or undetectable if followed by two hexadecimals

  ## RFC 3986 3.1., 6.2.2.1., RFC 3987 5.3.2.1.
  my $scheme = $self->_uri_scheme;
  my $scheme_canon;
  if (defined $scheme) {
    $scheme_canon = encode_web_utf8 $scheme;
    $scheme_canon =~ s/%([0-9A-Fa-f][0-9A-Fa-f])/pack 'C', hex $1/ge;
    if ($scheme_canon =~ tr/A-Z/a-z/) {
      $self->onerror->(type => 'URL:uppercase scheme name',
                       level => $ErrorLevels->{uri_lc_should},
                       value => $scheme, value_mark => qr/[A-Z]+/);
      ## should
    }
  }

  ## Note that nothing prevent a conforming URI (if there is one)
  ## using an unregistered URI scheme...

  ## RFC 3986 3.2.1., 7.5.
  my $ui = $self->_uri_userinfo;
  if (defined $ui and $ui =~ /:/) {
    $self->onerror->(type => 'URL:password',
                     level => $ErrorLevels->{uri_lc_should},
                     value => $ui);
    # deprecated, should be considered an error
  }

  ## RFC 3986 3.2.2., 6.2.2.1., RFC 3987 5.3.2.1.
  my $host = $self->_uri_host;
  if (defined $host) {
    if ($host =~ /^\[([vV][0-9A-Fa-f]+)\./) {
      $self->onerror->(type => 'URL:address format',
                       level => 'w',
                       text => $1,
                       value => $host, pos_start => $-[1], pos_end => $+[1]);
      ## NOTE: No conformance creteria is defined for new address format,
      ## nor is any standardization process.
   }
    my $hostnp = $host;
    $hostnp =~ s/%([0-9A-Fa-f][0-9A-Fa-f])//g;
    if ($hostnp =~ /[A-Z]/) {
      $self->onerror->(type => 'URL:uppercase host',
                       level => $ErrorLevels->{uri_lc_should},
                       value => $hostnp, value_mark => qr/[A-Z]+/);
      ## should
    }
    
    if ($host =~ /^\[/) {
      #
    } else {
      my $host_np = encode_web_utf8 $host;
      $host_np =~ s/%([0-9A-Fa-f][0-9A-Fa-f])/pack 'C', hex $1/ge;

      if ($host_np eq '') {
        ## NOTE: Although not explicitly mentioned, an empty host
        ## should be considered as an exception for the recommendation
        ## that a host "should" be a DNS name.
      } elsif ($host_np !~ /\A(?>[A-Za-z0-9](?>[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)(?>\.(?>[A-Za-z0-9](?>[A-Za-z0-9-]{0,61}[A-Za-z0-9])?))*\.?\z/) {
        $self->onerror->(type => 'URL:non-DNS host',
                         level => $ErrorLevels->{uri_lc_should},
                         value => $host_np);
        ## should
        ## should be IDNA encoding if wish to maximize interoperability
      } elsif (length $host > 255) {
        ## NOTE: This length might be incorrect if there were percent-encoded
        ## UTF-8 bytes; however, the above condition catches all non-ASCII.
        $self->onerror->(type => 'URL:long host',
                         level => $ErrorLevels->{uri_lc_should},
                         value => $host_np,
                         pos_start => 256, pos_end => length $host);
        ## should
      }
      
      ## FQDN should be followed by "." if necessary --- untestable
      
      ## must be UTF-8
      unless ($host_np =~ /\A(?>
          [\x00-\x7F] |
          [\xC2-\xDF][\x80-\xBF] |                          # UTF8-2
          [\xE0][\xA0-\xBF][\x80-\xBF] |
          [\xE1-\xEC][\x80-\xBF][\x80-\xBF] |
          [\xED][\x80-\x9F][\x80-\xBF] |
          [\xEE\xEF][\x80-\xBF][\x80-\xBF] |                # UTF8-3
          [\xF0][\x90-\xBF][\x80-\xBF][\x80-\xBF] |
          [\xF1-\xF3][\x80-\xBF][\x80-\xBF][\x80-\xBF] |
          [\xF4][\x80-\x8F][\x80-\xBF][\x80-\xBF]           # UTF8-4
      )*\z/x) {
        $self->onerror->(type => 'URL:non UTF-8 host',
                         level => $ErrorLevels->{uri_lc_must},
                         value => $host); # not $host_np
        # must
      }
    }
  }

  ## RFC 3986 3.2., 3.2.3., 6.2.3., RFC 3987 5.3.3.
  my $port = $self->_uri_port;
  if (defined $port) {
    if ($port =~ /\A([0-9]+)\z/) {
      if ($DefaultPort->{$scheme_canon} == $1) {
        $self->onerror->(type => 'URL:default port',
                         level => $ErrorLevels->{uri_lc_should},
                         value => $port);
        ## should
      }
    } elsif ($port eq '') {
      $self->onerror->(type => 'URL:empty port',
                       level => $ErrorLevels->{uri_lc_should},
                       value => $self->_uri_authority,
                       value_mark_end => 1);
      ## should
    }
  }

  ## RFC 3986 3.4.
  ## ... says that "/" or "?" in query might be problematic for old
  ## implementations, but also suggest that for readability
  ## percent-encoding might not be good idea.  It provides no
  ## recommendation on this issue.  Therefore, we do no check for this
  ## matter.

  ## RFC 3986 3.5.
  ## ... says again that "/" or "?" in fragment might be problematic,
  ## without any recommendation. 
  ## We again left this unchecked.

  ## RFC 3986 4.4.
  ## Authors should not assume ... different, though equivalent, 
  ## URI will (or will not) be interpreted as a same-document reference ...
  ## This is not testable.

  ## RFC 3986 5.4.2.
  ## "scheme:relative" should be avoided
  ## This is not testable without scheme specific information.

  ## RFC 3986 6.2.2.3., RFC 3987 5.3.2.4.
  my $path = $self->_uri_path;
  if (defined $scheme) {
    if (
        $path =~ m!/\.\./! or
        $path =~ m!/\./! or
        $path =~ m!/\.\.\z! or
        $path =~ m!/\.\z! or
        $path =~ m!\A\.\./! or
        $path =~ m!\A\./! or
        $path eq '.,' or
        $path eq '.'
       ) {
      $self->onerror->(type => 'URL:dot-segment',
                       level => $ErrorLevels->{uri_lc_should},
                       value => $path,
                       value_mark => qr[(?<=/)\.\.?(?=/|\z)|\A\.\.?(?=/|\z)]);
      ## should
    }
  }

  ## RFC 3986 6.2.3., RFC 3987 5.3.3.
  my $authority = $self->_uri_authority;
  if (defined $authority) {
    if ($path eq '') {
      $self->onerror->(type => 'URL:empty path', 
                       level => $ErrorLevels->{uri_lc_should},
                       value => $self->{value}, value_mark_end => 1);
      ## should
    }
  }

  ## RFC 3986 6.2.3., RFC 3987 5.3.3.
  ## Scheme dependent default authority should be omitted
  
  ## RFC 3986 6.2.3., RFC 3987 5.3.3.
  if (defined $host and $host eq '' and
      (defined $ui or defined $port)) {
    $self->onerror->(type => 'URL:empty host',
                     level => $ErrorLevels->{uri_lc_should},
                     value => $authority,
                     pos_start => defined $ui ? 1 + length $ui : 0,
                     pos_end => defined $ui ? 1 + length $ui : 0);
    ## should # when empty authority is allowed
  }

  ## RFC 3986 7.5.
  ## should not ... username or password that is intended to be secret
  ## This is not testable.

  ## RFC 3987 4.1.
  ## MUST be in full logical order
  ## This is not testable.

  ## RFC 3987 4.1., 6.4.
  ## URI scheme dependent syntax
  ## MUST
  ## TODO

  ## RFC 3987 4.2.
  ## iuserinfo, ireg-name, isegment, isegment-nz, isegment-nz-nc, iquery, ifragment
  ## SHOULD NOT use both rtl and ltr characters
  ## SHOULD start with rtl if using rtl characters
  ## TODO

  ## RFC 3987 5.3.2.2. 
  ## SHOULD be NFC
  ## NFKC may avoid even more problems
  ## TODO

  ## RFC 3987 5.3.3.
  ## IDN (ireg-name or elsewhere) SHOULD be validated by ToASCII(UseSTD3ASCIIRules, AllowUnassigned)
  ## SHOULD be normalized by Nameprep
  ## TODO

  ## TODO: If it is a relative reference, then resolve and then check against scheme dependent requirements
} # check_iri_reference

sub check_rdf_uri_reference ($) {
  my $self = $_[0];
  pos ($self->{value}) = 0;

  if ($self->{value} =~ /[\x00-\x1F\x7F-\x9F]/) {
    $self->onerror->(type => 'syntax error:rdfuriref',
                     level => $ErrorLevels->{rdf_fact},
                     value => $self->{value},
                     position => $-[0]);
  }

  my $ascii_uri = $self->get_uri_reference_3986; # same as RDF spec's one
  $ascii_uri = (ref $self)->new_from_string ($ascii_uri);

  unless ($ascii_uri->is_uri) { ## TODO: is_uri_2396 should be used.
    $self->onerror->(#type => 'syntax error:uri2396',
                     type => 'syntax error:uri3986',
                     level => $ErrorLevels->{uri_fact},
                     value => $ascii_uri->{value});
  }

  ## TODO: Check against RFC 2396.
  #Whatpm::URIChecker->check_iri_reference ($_[1], $_[2], $_[3]);
} # check_rdf_uri_reference

1;

=head1 LICENSE

Copyright 2006-2013 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Portions of this module are derived from the example parser (April 7,
2004) available at
<http://www.gbiv.com/protocols/uri/rev-2002/uri_test.pl> that is
placed in the Public Domain by Roy T. Fielding and Day Software, Inc.

=back
