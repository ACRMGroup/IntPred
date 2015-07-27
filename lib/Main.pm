#!/acrm/usr/local/bin/perl
package Main;
use Moose;

use DataSet;
use DataSet::Instance;
use DataSet::Input;
use DataSet::Creator;
use DataSet::PropCalc;
use Predictor;

use Carp;

use Getopt::Long qw(GetOptionsFromArray);

sub processUserInput {
    my @optsAndArgs = @_;
    
    my $featureStr   = "";
    my $userLabFile;
    my $inputFormat  = "pdb";
    my $surfStatFile = ""; # Set defaults for these
    my $intfStatFile = ""; # stats files?
    my $patchDir     = "";
    
    GetOptionsFromArray(\@optsAndArgs,
                        "e=s" => \$featureStr,
                        "u=s" => \$userLabFile,
                        "f=s" => \$inputFormat,
                        "s=s" => \$surfStatFile,
                        "i=s" => \$intfStatFile,
                        "p=s" => \$patchDir);
    
    # Process user labels
    my $userLabelHref = readLabelsFile($userLabFile) if defined $userLabFile;
    
    # Feature string will always specify i (patch ID) at the start of the string
    # and c (class) at the end
    $featureStr = 'i' . $featureStr . 'c';
    
    # Get instance model for the features the user wants
    my $model = DataSet::Instance::Model->new($featureStr);

    # Add user labels to model
    $model->userLabels($userLabelHref) if defined $userLabelHref;
    
    # Add propensity calculator to model
    $model->propCalc(DataSet::PropCalc->new(intfStatFile => $intfStatFile,
                                            surfStatFile => $surfStatFile));
        
    # Add patch summary lines to model
    $model->pSummaries(readPatchDir($patchDir)) if defined $patchDir;
    
    # Get inputs from user-specified file
    my $inputFile = $optsAndArgs[0];
    croak "You must supply an input file!" if ! defined $inputFile;
    my @inputs = getInputsFromFile($inputFile, $inputFormat);

    return DataSet::Creator::Master->new(inputs => \@inputs, model => $model);
}

# TO create a dataSet, we parse user options and input, send these to
# a DataSet::Creator and then call DataSet::Creator->create to get
# our dataSet
sub createDataSet {
    
}



1;
