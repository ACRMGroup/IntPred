#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use ConfigReader;
use DataSet;
use Getopt::Long;

my $inputType = "pdb";
my $numProc = 1;
my $patchRadius = 14;
my $pCentreDir;

GetOptions("t=s" => \$inputType,
           "p=i" => \$numProc,
           "r=i" => \$patchRadius,
           "c=s" => \$pCentreDir);

@ARGV == 2 or Usage();
my $inputFile = shift @ARGV;
my $outDir = shift @ARGV;

my $config = ConfigReader->new();
$config->setFeatures("id");
$config->addTestSetInputFileAndFormat($inputFile, $inputType);
$config->newval(qw(DataSetCreation pCentreDir), $pCentreDir) if $pCentreDir;

my $dSetCreator = $config->createDataSetCreator();
$dSetCreator->maxProc($numProc);
$dSetCreator->model->patchRadius($patchRadius);

my $dSet = DataSet->new(instancesAref => [$dSetCreator->getInstances()]);
$dSet->writePatchFilesToDir($outDir, 1);

sub Usage {
    print <<EOF;
$0 [-t pqs|pdb|file] [-p INT] [-r INT] [-c DIR] inputFile outPatchDir
This script can be used to produce patch files from a IntPred-formatted
input file.

Opts
    -t Input format. Control how the input file is interpreted.
           pqs  = pqs codes
           pdb  = pdb codes
           file = file paths pointing towards pdb files

     -p Number of parallel processes to run.

     -r Patch radius

     -c Directory of patch .centres files that contain ids of patch centres to
        use, formatted as: ChainID.resSeq atomName eg. B.44 OE1

Args

    inputFile IntPred input formatted file

    outPatchDir directory for output .patch files

EOF
    exit(1);
}
