#!/usr/bin/env perl
use strict;
use warnings;

@ARGV or die "Please supply some prediction csvs\n";

my %linesForChainID = ();

my $addRunCol = 0;

my $header;

foreach my $file (@ARGV) {
    my $runID;
    if ($file =~ /run(.*?)[.-]/) {
        $addRunCol = 1;
        $runID = $1; 
    }
    
    open(my $IN, "<", $file) or die "Cannot open file $file, $!";

    my $reachedData = 0;
    while (my $line = <$IN>) {
        if ($line =~ /^inst#/) {
            $reachedData = 1;
            $header = $line;
            next;
        }

        next unless $reachedData;
        
        next if $line eq $header;
        my $pID = [split(/,/, $line)]->[5];
        my ($chID) = $pID =~ /(.*):/;
        $chID =~ s/://;

        if (defined $runID) {
            chomp $line;
            $line = "$line,$runID\n";
        }
        push(@{$linesForChainID{$chID}}, $line);
    }
}

if ($addRunCol) {
    chomp $header;
    $header = "$header,run\n";
}

foreach my $chID (keys %linesForChainID) {
    my $outFile = "$chID.csv";
    open(my $OUT, ">", $outFile) or die "Cannot open file $outFile, $!";
    print {$OUT} $header, @{$linesForChainID{$chID}};
}

 
