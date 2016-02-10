#!/usr/bin/env perl
use strict;
use warnings;

my %h = ();
my @stats;
while (<>) {
    next unless /^(\w+):\s+([0-9.-]+)/;
    push(@stats, $1) if ! exists $h{$1};
    push(@{$h{$1}}, $2);
}

foreach my $stat (@stats) {
    my $valueAref = $h{$stat};
    my $average = 0;
    map {$average += $_ / scalar @{$valueAref}} @{$valueAref};
    print "$stat: $average\n";
}
