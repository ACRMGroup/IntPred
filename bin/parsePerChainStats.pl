#!/usr/bin/env perl
die "Supply a perChain stats file!" if ! @ARGV;
open(my $IN, "<", $ARGV[0]) or die "Cannot open file $ARGV[0], $!";

print "id,run,sens,spec,MCC,numResidues\n";
while (<$IN>) {
    if (/^([0-9].{4}).*run ([0-9]+)/) {
        print "$1,$2,";
    }
    elsif (/sensitivity: ([0-9.]+)/) {
        print "$1,";
    }
    elsif (/specificity: ([0-9.]+)/) {
        print "$1,";
    }
    elsif (/MCC: ([0-9.\-]+)/) {
        print "$1,";
    }
    elsif (/total: ([0-9]+)/) {
        print "$1\n";
    }
}
