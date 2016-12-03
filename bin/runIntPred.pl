#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Main;
use ConfigReader;
use Getopt::Long;

my $inFileFormat   = "pdb";
GetOptions("f=s" => \$inFileFormat);
my $inFile = @ARGV[0] or die "You must supply an input file!";

my $configReader   = _getConfigReader();
$rConfig->addInputFileAndFormat($inFile, $inFileFormat);

my $predictor      = $rConfig->createPredictor();
my $testData       = $rConfig->createDataSetCreator()->getDataSet();
$predictor->testSet($testData);
$predictor->getPredictionScoresForTestSet();

print $testData->summary();

sub _getConfigReader {
    my $configFile     = "$FindBin::Bin/../data/runGeneralPred.ini";
    return ConfigReader->new($configFile);
}
