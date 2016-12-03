#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Main;
use ConfigReader;
use Getopt::Long;
use Carp;

my $inFileFormat   = "pdb";
my $help = 0;

GetOptions("f=s" => \$inFileFormat,
           "h"   => \$help);
Usage() and exit(0) if $help;
print "You must supply an input file!" and Usage() and exit(1)
    if ! @ARGV;

my $inFile = $ARGV[0];
my $rConfig   = _getConfigReader();
$rConfig->addTestSetInputFileAndFormat($inFile, $inFileFormat);

my $predictor = $rConfig->getPredictor();
my $testData  = $rConfig->createDataSetCreator()->getDataSet();
$predictor->testSet($testData);
$predictor->runPredictor();
$predictor->assignPredictionScoresToTestSet();

print map {$_->id . ": " . $_->predScore . "\n"} @{$testData->instancesAref()};

print "Finished!\n";

sub _getConfigReader {
    my $configFile     = "$FindBin::Bin/../config/runIntPred.ini";
    return ConfigReader->new($configFile);
}

sub Usage {
    print <<EOF;
$0 [-f pdb|pqs|file] input_file

opts

 -f : Format of the input file. Default = pdb. This sets what IntPred
      expects the identifiers of the input file to be: pdb code, pqs codes
      or file names.
args

 input_file : input file following the IntPred input format (see below).

runIntPred.pl runs the main IntPred model on the given input file. The input
file is expected to be in the following format

  structure_id : targetChainID : complexChainID

where structure id is the PDB code, PQS code or file name of the structure,
targetChainID is the ID of the chain you want to make predictions on,
complexChainID is the ID of the chain it makes an interface with (that you
don't want predictions on). e.g.

  1afv : A : L

Complex chains are optional and you can list multiple chains of either by
separating IDs with commas, e.g.

  1afv : A
  1afv : A   : L,H
  1afv : H,L : A 

you can also list multiple complexes for a structure by using colons

  1afv : A : H,L : B : K,M
  1afv : A :     : B : K,M

note the use of two colons in the case of one input having target chain(s)
only.

To specify that the complex chains should be all of those except the target
chain(s), put a minus sign at the beginning of the list of complex chains

  1afv : A   : -A
  1afv : A,B : -A,B
EOF
}    
