use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib')->stringify;
use Test::More;
use Test::X1;
use Web::Origin;
use Web::Host;

test {
  my $c = shift;

  my $opaque = Web::Origin->new_opaque;
  isa_ok $opaque, 'Web::Origin';
  ok $opaque->is_opaque;
  ok $opaque->same_origin_as ($opaque);
  ok $opaque->same_origin_domain_as ($opaque);
  is $opaque->to_ascii, 'null';

  my $opaque2 = Web::Origin->new_opaque;
  ok ! $opaque->same_origin_as ($opaque2);
  ok ! $opaque->same_origin_domain_as ($opaque2);

  done $c;
} n => 7, name => 'opaque origin';

for (
  ['https', '127.0.0.1', undef, q<https://127.0.0.1>],
  ['https', '[::]', undef, q<https://[::]>],
) {
  my ($scheme, $host, $port, $ascii) = @$_;
  test {
    my $c = shift;

    my $origin = Web::Origin->new_tuple ($scheme, $host, $port);
    isa_ok $origin, 'Web::Origin';
    ok ! $origin->is_opaque;
    ok $origin->same_origin_as ($origin);
    ok $origin->same_origin_domain_as ($origin);
    my $opaque = Web::Origin->new_opaque;
    ok not $origin->same_origin_as ($opaque);
    ok not $origin->same_origin_domain_as ($opaque);
    is $origin->to_ascii, $ascii;

    my $origin2 = Web::Origin->new_tuple ($scheme, $host, $port);
    eval {
      $origin2->set_domain (Web::Host->parse_string ($host));
    };
    like $@, qr{^The host is not a domain};
    ok $origin->same_origin_as ($origin2);
    ok $origin->same_origin_domain_as ($origin2);

    done $c;
  } n => 10, name => 'tuple origin';
}

for (
  ['http', 'hoge.fuga', undef, q<http://hoge.fuga>],
  ['http', 'hoge.fuga', 62, q<http://hoge.fuga:62>],
) {
  my ($scheme, $host, $port, $ascii) = @$_;
  test {
    my $c = shift;

    my $origin = Web::Origin->new_tuple ($scheme, $host, $port);
    isa_ok $origin, 'Web::Origin';
    ok ! $origin->is_opaque;
    ok $origin->same_origin_as ($origin);
    ok $origin->same_origin_domain_as ($origin);
    my $opaque = Web::Origin->new_opaque;
    ok not $origin->same_origin_as ($opaque);
    ok not $origin->same_origin_domain_as ($opaque);
    is $origin->to_ascii, $ascii;

    my $origin2 = Web::Origin->new_tuple ($scheme, $host, $port);
    $origin2->set_domain (Web::Host->parse_string ($host));
    ok $origin->same_origin_as ($origin2);
    ok ! $origin->same_origin_domain_as ($origin2);

    done $c;
  } n => 9, name => 'tuple origin';
}

test {
  my $c = shift;

  my $o1 = Web::Origin->new_tuple ('http', 'hjoge', undef);
  my $o2 = Web::Origin->new_tuple ('http', 'hjog2', undef);
  ok ! $o1->same_origin_as ($o2);
  ok ! $o1->same_origin_domain_as ($o2);

  done $c;
} n => 2;

test {
  my $c = shift;

  my $o1 = Web::Origin->new_tuple ('http', 'hjoge', undef);
  my $o2 = Web::Origin->new_tuple ('https', 'hjoge', undef);
  ok ! $o1->same_origin_as ($o2);
  ok ! $o1->same_origin_domain_as ($o2);

  done $c;
} n => 2;

test {
  my $c = shift;

  my $o1 = Web::Origin->new_tuple ('http', 'hjoge', undef);
  my $o2 = Web::Origin->new_tuple ('http', 'hjoge', 81);
  ok ! $o1->same_origin_as ($o2);
  ok ! $o1->same_origin_domain_as ($o2);

  $o1->set_domain (Web::Host->parse_string ('foo'));
  $o2->set_domain (Web::Host->parse_string ('foo'));
  ok ! $o1->same_origin_as ($o2);
  ok $o1->same_origin_domain_as ($o2);

  done $c;
} n => 4;

test {
  my $c = shift;

  my $o1 = Web::Origin->new_tuple ('http', 'hjoge', undef);
  my $o2 = Web::Origin->new_tuple ('https', 'hjoge', undef);
  ok ! $o1->same_origin_as ($o2);
  ok ! $o1->same_origin_domain_as ($o2);

  $o1->set_domain (Web::Host->parse_string ('foo'));
  $o2->set_domain (Web::Host->parse_string ('foo'));
  ok ! $o1->same_origin_as ($o2);
  ok ! $o1->same_origin_domain_as ($o2);

  done $c;
} n => 4;

run_tests;

=head1 LICENSE

Copyright 2016 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
