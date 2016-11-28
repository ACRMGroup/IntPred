#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;

my $t = 0.5;
GetOptions("t=s", \$t);

@ARGV or die "Supply a value file and an arff file\n";

my $valueFile = shift @ARGV;
my $arffFile  = shift @ARGV;

open(my $IN, "<", $valueFile) or die "Cannot open file $valueFile, $!";
my %valueForInstance = map {chomp $_; $_ =~ /(.*):(.*)/; $1 => $2} <$IN>;
close $IN;

open($IN, "<", $arffFile) or die "Cannot open file $arffFile, $!";
while (my $line = <$IN>) {
    if ($line =~ /^@/ || $line =~ /^\s*$/) {
        print $line;
        next;
    }
    chomp $line;

    my @fields = split(/,/, $line);
    my $id     = $fields[0];
    pop @fields;
    my $value = $valueForInstance{$id};
    my $newLabel
        = $value == 0 ? "S"
        : $value > $t ? "I"
        : "?";
    print join(",", @fields, $newLabel) . "\n";
}
