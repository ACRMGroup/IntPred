#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Main;
use ConfigReader;
use Getopt::Long;

@ARGV or Usage();

my $configFile = shift @ARGV;
my $cReader    = ConfigReader->new($configFile);
my $predictor  = $cReader->getPredictor();

my $trainData  = $cReader->getTrainingSet();

my $testArffFile = shift @ARGV;
my $testArff     = ARFF::FileParser->new(file => $testArffFile)->parse();
my $testData     = DataSet->new($testArff);

$predictor->trainingSet($trainData);
$predictor->testSet($testData);
print $predictor->predictionCSVStr();

sub Usage {
    print <<EOF;
$0 configFile testARFF
EOF
    exit(1);
}
