#!/usr/bin/env perl
use strict;
use warnings;
use lib ("/home/bsm3/zcbtfo4/scripts/lib/IntPred/lib");
use ConfigReader;
use Getopt::Long;

my $configFile;
my $outARFF;

GetOptions("c=s" => \$configFile,
           "o=s" => \$outARFF);

@ARGV or Usage();
my $testArff = shift @ARGV;

my $config = ConfigReader->new(defined $configFile ? $configFile : "IntPred.config.ini");
$config->exists("TestSet", "ARFF") ? $config->setval("TestSet", "ARFF", $testArff)
    : $config->newval("TestSet", "ARFF", $testArff);

my $testSet  = $config->getTestSet();
$testSet->makeArffCompatible();
my $trainSet = $config->getTrainingSet();
$trainSet->makeArffCompatible();

$testSet->standardizeArffUsingRefArff($trainSet->arff->arff2File());

$outARFF = "prepared-testset.arff" if ! defined $outARFF;
open(my $ARFF, ">", $outARFF)
    or die "Cannot open file $outARFF, $!";
print {$ARFF} $testSet->arff->arff2String();

sub Usage {
    print <<EOF;
$0 -c FILE -o FILE unstandardized-arff

Opts:
    -c : config file. Default = IntPred.config.ini
    -o : output standardized .arff file. 
EOF
    exit(1);
}
