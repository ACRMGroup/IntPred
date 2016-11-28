#!/usr/bin/env perl
use strict;
use warnings;

my %h = ();

while (<>) {
    my @fields = split(/,/, $_);
    my $patchID = $fields[0];
    my ($pdb, $chainID) = $patchID =~ /(.*?):(.*?):(.*?)/;
    next if ! (defined $pdb && defined $chainID);
    $h{$pdb}->{$chainID} = 1;    
}

while (my ($pdb, $chainHref) = each %h) {
    print "$pdb : " . join(",", sort keys %{$chainHref}) . "\n";
}
