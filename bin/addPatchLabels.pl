#!/usr/bin/env perl -w
# addPatchLabels.pl --- adds patch labels from a .labels file to a WEKA output .csv
# Author: Tom Northey <zcbtfo4@acrm18>
# Created: 21 Jan 2015
# Version: 0.01

use warnings;
use strict;
use Carp;
use Getopt::Long;

use FindBin;
use lib "$FindBin::Bin/../lib";
use WEKAOutputParser;

### MAIN #######################################################################
################################################################################

my $unlabelled2Intf = 0;
my $removedUnlabelled = 0;

GetOptions("i" => \$unlabelled2Intf,
           "r" => \$removedUnlabelled);

my $labelsFile = shift @ARGV;
my $inputCSV   = shift @ARGV;

Usage() if ! ($labelsFile && $inputCSV);

my %patchID2Label = parseLabelsFile($labelsFile);

# Convert unlabelled to whichever label the user chosen. If removeUnlabelled
# has been chosen, skip this step - unlabelled patches will be 'removed' by
# not printing them later.
processUnlabelled(\%patchID2Label, $unlabelled2Intf) if ! $removedUnlabelled;

my $parser = WEKAOutputParser->new($inputCSV);
my @csvLines = $parser->getLinesFromCSVFile($inputCSV);
my @infoArefs
    = map {$parser->parseCSVLine($_)} @csvLines;

ammendValues(\@infoArefs, \%patchID2Label);

my $header = $parser->getCSVHeader();
printCSV($header, \@infoArefs, $removedUnlabelled);

### SUBROUTINES ################################################################
################################################################################

sub processUnlabelled {
    my $patchID2LabelHref = shift;
    my $unlabelled2Intf = shift;
    
    my $replacement = $unlabelled2Intf ? "1:I" : "2:S";
    
    foreach my $patchID (keys %{$patchID2LabelHref}) {
        if ($patchID2LabelHref->{$patchID} eq '3:U') {
            $patchID2LabelHref->{$patchID} = $replacement;
        }
    }
}

sub printCSV {
    my $header = shift;
    my $arrayOfInfoArefs = shift;
    my $removedUnlabelled = shift;
    
    print $header;
    
    my $inst = 0;
    foreach my $infoAref (@{$arrayOfInfoArefs}) {

        ++$inst;
        
        my ($patchID, $value, $prediction, $score) = @{$infoAref};

        
        if (! defined $value) {
            print {*STDERR} "printCSV: Value for $patchID (inst $inst) "
                . " is not defined! Skipping...\n";
            next;
        }
        elsif ($value eq '3:U' && $removedUnlabelled) {
            print {*STDERR} "printCSV: set to skip unlablled instances: "
                . "skipping instance $inst...\n";
            next;
        }
        
        my $error = $value eq $prediction ? '' : '+';

        my $line
            = join(",", ($inst, $value, $prediction, $error, $score, $patchID))
                . "\n";

        print $line;
    }
}

sub ammendValues {
    my $arrayOfInfoArefs = shift;
    my $patchID2LabelHref = shift;

    foreach my $infoAref (@{$arrayOfInfoArefs}) {
        my $patchID = $infoAref->[0];
        my $label = $patchID2LabelHref->{$patchID};

        # Replace label with true label
        $infoAref->[1] = $label;
    }
}

sub parseLabelsFile {
    my $intputFile = shift;
    
    open(my $IN, "<", $intputFile) or die "Cannot open file $intputFile, $!";

    my %patchID2Label = ();
    
    while (my $line = <$IN>) {
        chomp $line;

        my @fields = split(":", $line);
        my $label = pop @fields;

        $label = $label eq 'I' ? '1:I'
            : $label eq 'S' ? '2:S'
                : $label eq 'U' ? '3:U'
                    : croak "Unrecognized label '$label'!";
        
        my $patchID = join(":", @fields);

        $patchID2Label{$patchID} = $label;
    }

    return %patchID2Label;
}

sub Usage {
    print <<EOF;
$0 labelsFile WEKAoutCSV

This script edits a given WEKA output CSV file by replacing value labels with
those in the supplied labels file. This is primarily to add value labels to
a test set, post prediction, and decide what is done with those patches that
are unlabelled.

EOF
    exit(1)
}

__END__
