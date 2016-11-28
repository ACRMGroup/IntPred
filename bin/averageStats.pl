#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
my $inputIsCSV;
GetOptions("c", \$inputIsCSV);

my %h = ();
my @csvValueArefs;
my @stats;
my @csvFields;

while (<>) {
    if ($inputIsCSV) {
        chomp $_;
        my @values = split(/,/, $_);
        if (! @csvFields) {
            @csvFields = @values;
            next;
        }
        for (my $i = 0 ; $i < @values ; ++$i) {
            push(@{$csvValueArefs[$i]}, $values[$i]);
        }
    }
    else {
        next unless /^(\w+):\s+([0-9.-]+)/;
        push(@stats, $1) if ! exists $h{$1};
        push(@{$h{$1}}, $2);
    }
}

if ($inputIsCSV) {
    my @averages;
    for (my $i = 0 ; $i < @csvValueArefs ; ++$i) {
        my @values = @{$csvValueArefs[$i]};
        my $total;
        my $avg;
        my $notNumber = grep {$_ !~ /^[0-9\.-]+$/} @values;
        unless ($notNumber) {
            map {$total += $_} @values;
            $avg = $total / @values;
        }
        push(@averages, $notNumber ? "?" : sprintf "%.4f", $avg);
    }
    print join(",", @csvFields) . "\n";
    print join(",", @averages)  . "\n";
}
else {
    foreach my $stat (@stats) {
        my $valueAref = $h{$stat};
        my $average = 0;
        map {$average += $_ / scalar @{$valueAref}} @{$valueAref};
        print "$stat: $average\n";
    }
}
