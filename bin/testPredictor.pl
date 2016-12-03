#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Main;
use ConfigReader;
use Getopt::Long;

my $modelFile;
my $trainingArff;
my $predictorTrainedOnStandardizedData = 0;
my $trainIsCompatible = 0;
my $configFile;
my $outCSV = "predictions.csv";

GetOptions('m=s', \$modelFile,
           'r=s', \$trainingArff,
           's', \$predictorTrainedOnStandardizedData,
           'i',   \$trainIsCompatible,
           'c=s', \$configFile,
           'o=s', \$outCSV);

my $cReader = $configFile ? ConfigReader->new($configFile)
    : ConfigReader->new();

# Use cmd-line specified model file if available
if ($modelFile) {
    if ($cReader->exists('Predictor', 'modelFile')) {
        $cReader->setval('Predictor', 'modelFile', $modelFile) 
    }
    else {
        $cReader->newval('Predictor', 'modelFile', $modelFile);
    }
}

if ($trainingArff) {
    if ($cReader->exists('TrainingSet', 'ARFF')) {
        $cReader->setval('TrainingSet', 'ARFF', $trainingArff) 
    }
    else {
        $cReader->newval('TrainingSet', 'ARFF', $trainingArff);
    }
}

if ($predictorTrainedOnStandardizedData) {
    if ($cReader->exists('Predictor', 'standardized')) {
        $cReader->setval('Predictor', 'standardized',
                         $predictorTrainedOnStandardizedData);
    }
    else {
        $cReader->newval('Predictor', 'standardized',
                         $predictorTrainedOnStandardizedData);
    }
}

@ARGV or Usage();
my $testArffFile = shift @ARGV;

open(my $OUT, ">", $outCSV) or die "Cannot open output csv file $outCSV, $!";

my $predictor = preparePredictor($testArffFile, $trainIsCompatible, $cReader);
$predictor->runPredictor();
my $outParser = $predictor->outputParser();
$predictor->outputParser->transformPredictionScores();

print "Printing output csv to $outCSV ...\n";
$predictor->outputParser->printCSVString($OUT);
print "Finished!\n";

sub preparePredictor {
    my ($testArffFile, $trainIsCompatible, $cReader) = @_;
    my $trainData = loadTrainingSet($trainIsCompatible, $cReader);
    my $testData  = loadTestSet($testArffFile);
    print "Loading predictor  ...\n";
    my $predictor  = $cReader->getPredictor();
    $predictor->trainingSet($trainData) if defined $trainData;
    $predictor->testSet($testData);
    return $predictor;
}

sub loadTrainingSet {
    my ($trainIsCompatible, $cReader) = @_;
    my $trainData;
    if ($cReader->exists('TrainingSet', 'ARFF')) {
        print "Loading training set ...\n";
        $trainData  = $cReader->getTrainingSet();
        $trainData->arffIsCompatible($trainIsCompatible);
    }
    return $trainData;
}

sub loadTestSet {
    my ($testArffFile) = @_;
    my $testArff = ARFF::FileParser->new(file => $testArffFile)->parse();
    print "Loading test data from arff ...\n";
    my $testData = DataSet->new(arff => $testArff);
    return $testData;
}


sub Usage {
    print <<EOF;
$0 [-c configFile] [-m modelFile] [-o outCSV] [-i -s] testARFF

opts
   -c : config.ini file. Model file and training arff can be specified here
        rather than using -m and -r opts.
   -r : training .arff file to standardise test set against (this implicitly
        sets -s)
   -s : test set will be standardised against supplied training set. Make
        you use this if your model was trained on a standardised data set!
   -i : specify that training .arff supplied is already compatible with IntPred
   -m : weka .model file.
   -o : output predictions CSV file. Default = out.csv

args
    testARFF : test set .arff file

EOF
    exit(1);
}
