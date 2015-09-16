use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

my $root_path = path (__FILE__)->parent->parent;

my $path = $root_path->child ('local/tlds.json');
my $data = json_bytes2perl $path->slurp;
my @tld = grep { $data->{tlds}->{$_}->{mozilla_idn_whitelist} } keys %{$data->{tlds}};

print q{package Web::DomainName::IDNEnabled;
our $VERSION = '2.0';

## This module is automatically generated.  Don't edit!

$TLDs =
};

print Dumper {map { $_ => 1 } @tld};

print q{

=head1 LICENSE

Copyright 2011-2015 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

};
