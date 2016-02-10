#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Main;
use ConfigReader;
use Getopt::Long;

my $modelFile;

GetOptions('m=s', \$modelFile);

@ARGV or Usage();

my $configFile = shift @ARGV;
my $cReader    = ConfigReader->new($configFile);

# Use cmd-line specified model file if available
if ($modelFile) {
    if ($cReader->exists('Predictor', 'modelFile')) {
        $cReader->setval('Predictor', 'modelFile', $modelFile) 
    }
    else {
        $cReader->newval('Predictor', 'modelFile', $modelFile);
    }
}

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
