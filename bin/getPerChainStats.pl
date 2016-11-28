#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;

my $noStats = 0;
my $byPDB = 0;

GetOptions("n", \$noStats,
           "p", \$byPDB);

@ARGV or Usage();

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
        my ($pdb)  = $pID =~ /(.*?):/;
        my ($chID) = $pID =~ /(.*):/;
        $chID =~ s/://;

        push(@{$lineMap{$byPDB ? $pdb : $chID}->{$runID}}, $line);
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

sub Usage {
    print <<EOF;
$0 -p -n prediction-csvs

Opts:
    -p group predictions by pdb, rather than chain.
    -n do not output stats.

This script will split prediction csvs into their component
chains (or pdbs). Summary stats will also be output if desired.
EOF
    exit(1);
}
