#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use ConfigReader;
use Getopt::Long;
my $configFile = "IntPred.config.ini";
GetOptions("c=s", \$configFile);

my $config = ConfigReader->new($configFile);

my $dSetCreator = $config->createDataSetCreator();
my $testData = $dSetCreator->getDataSet();

my $arffFile = "unstandardized-testset.arff";
open(my $ARFF, ">", $arffFile)
    or die "Cannot open file $arffFile, $!";
print {$ARFF} $testData->arff->arff2String();
