#!/usr/bin/env perl
use strict;
use warnings;
use lib ("/home/bsm3/zcbtfo4/scripts/lib/IntPred/lib");
use ConfigReader;
use Getopt::Long;

my $configFile;

GetOptions("c=s" => \$configFile);

@ARGV or die "Please supply an unstandardized test set .arff";
my $testArff = shift @ARGV;

my $config = ConfigReader->new(defined $configFile ? $configFile : "IntPred.config.ini");
$config->exists("TestSet", "ARFF") ? $config->setval("TestSet", "ARFF", $testArff)
    : $config->newval("TestSet", "ARFF", $testArff);

my $testSet  = $config->getTestSet();
$testSet->makeArffCompatible();
my $trainSet = $config->getTrainingSet();
$trainSet->makeArffCompatible();

$testSet->standardizeArffUsingRefArff($trainSet->arff->arff2File());

my $outArff = "prepared-testset.arff";
open(my $ARFF, ">", $outArff)
    or die "Cannot open file $outArff, $!";
print {$ARFF} $testSet->arff->arff2String();
