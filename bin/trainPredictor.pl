#! /usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use ConfigReader;
use Getopt::Long;
use File::Basename;
use ARFF;
use WEKA;
use DataSet;
use Predictor;

my $modelFile;
GetOptions("m=s" => \$modelFile);

Usage() if ! @ARGV;
my $inputARFF = shift @ARGV;
$modelFile = getModelFile($inputARFF) if ! defined $modelFile;

my $trainingSet  = DataSet->new(ARFF::FileParser->new(file => $inputARFF)->parse());
my $randomForest = WEKA::randomForest->new(model => $modelFile);
my $predictor    = Predictor->new(trainingSet => $trainingSet,
				  randomForest => $randomForest);

$predictor->trainPredictor();

print "Model saved to file $modelFile\n";

sub getModelFile {
  my ($arffFile) = @_;
  my ($name, $path, $suffix) = fileparse($arffFile, ".arff");
  return ("$name.model");
}

sub Usage {
  print <<EOF;
$0 -m outModelFile inputARFF

 -m : Output .model file that WEKA model is written to. 
      If not supplied, the basename of the input arff is used.

This script trains a learner on the input arff file.

EOF
}
