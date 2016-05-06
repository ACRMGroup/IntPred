#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;

my $noStats = 0;

GetOptions("n", \$noStats);

@ARGV or die "Please supply some run prediction csvs\n";

my %lineMap = ();

my $header;

foreach my $file (@ARGV) {
    my $runID;
    if ($file =~ /run(.*?)\./) {
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

        push(@{$lineMap{$chID}->{$runID}}, $line);
    }
}

my @outFiles;

foreach my $chID (keys %lineMap) {
    foreach my $run (keys %{$lineMap{$chID}}) {
        my $outFile = "$chID.run$run.csv";
	push(@outFiles, $outFile);
        open(my $OUT, ">", $outFile) or die "Cannot open file $outFile, $!";
        my @lines = @{$lineMap{$chID}->{$run}};
        print {$OUT} $header, @lines;
        close $OUT;
    }
}

print `calcStatsFromWEKAOutputCSV.pl -c -U ? S I @outFiles` unless $noStats;

 
