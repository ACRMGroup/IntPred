#!/usr/bin/env perl -w
# mergeWEKAOutputCSVs.pl --- merge multiple WEKA output CSVs into one
# Author: Tom Northey <zcbtfo4@acrm18>
# Created: 24 Mar 2015
# Version: 0.01

use warnings;
use strict;
use Carp;
use IntPred::lib::WEKAOutputParser;

my @CSVs = @ARGV;

my $header = eval {WEKAOutputParser->new($CSVs[0])->getCSVHeader()};
croak "Error trying to parse CSV $CSVs[0]:" . $@ if ! $header;

my @alLines = ();
foreach my $CSV (@CSVs) {
    my @lines = WEKAOutputParser->new($CSV)->getLinesFromCSVFile();
    push(@alLines, @lines);
}

print $header, @alLines;

__END__
