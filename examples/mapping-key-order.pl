#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use YAML::PP;
use Data::Dumper;
use Tie::IxHash;

my $ypp = YAML::PP->new;
my $yaml = <<'EOM';
x: 1
t: 2
r: 3
m: 4
a: 5
b: 6
c: 7
EOM

my $schema = $ypp->schema;
$schema->add_map_resolver(
    tag => 'tag:yaml.org,2002:map',
    on_create => sub {
        my %hash;
        tie(%hash, 'Tie::IxHash');
        return \%hash;
    },
);
my $data = $ypp->load_string($yaml);
say "Result:";
for my $key (keys %$data) {
    say "$key: $data->{ $key }";
}
