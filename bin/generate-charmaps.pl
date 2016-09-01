use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
use Data::Dumper;

my $root_path = path (__FILE__)->parent->parent;

my $Data = {};

sub d ($) {
  return join '', map { chr hex $_ } split / /, $_[0];
} # d

{
  my $path = $root_path->child ('local/maps.json');
  my $json = json_bytes2perl $path->slurp;
  my $mapping = $json->{maps}->{'uts46:mapping'} or die;
  for my $from (keys %{$mapping->{char_to_empty}}) {
    my $to = $mapping->{char_to_empty}->{$from};
    $Data->{d $from} = d $to;
  }
  for my $from (keys %{$mapping->{char_to_char}}) {
    my $to = $mapping->{char_to_char}->{$from};
    $Data->{d $from} = d $to;
  }
  for my $from (keys %{$mapping->{char_to_seq}}) {
    my $to = $mapping->{char_to_seq}->{$from};
    $Data->{d $from} = d $to;
  }
}

$Data::Dumper::Sortkeys = 1;
print '$Web::DomainName::Canonicalize::IDNAMapped =';
print Dumper $Data;

## License: Public Domain.
