use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
use Data::Dumper;

my $root_path = path (__FILE__)->parent->parent;
my $json_path = $root_path->child ('local/url-schemes.json');

my $json = json_bytes2perl $json_path->slurp;

my $Defs = {};

for my $scheme (keys %$json) {
  my $port = $json->{$scheme}->{'default-port'};
  $Defs->{default_port}->{$scheme} = $port if defined $port;
}

$Data::Dumper::Sortkeys = 1;
my $dumped = Dumper $Defs;
$dumped =~ s/\$VAR1/\$Web::URL::_Defs/;
print "$dumped;";

## License: Public Domain.
