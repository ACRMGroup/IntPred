#!/usr/bin/env perl

use strict;
use warnings;
use Carp;
use TCNPerlVars;
use TCNUtil::WEKA;
use TCNUtil::confusion_table;
use Getopt::Long;

use File::Basename;
use List::Compare;

# Get cmd-line options
my $balance     = 0;
my $numFolds    = 0;
my $labelDist   = 0.5;

unless ($labelDist < 1) {
    print "Label distribution must be < 1!\n";
    exit(1);
}

GetOptions("b",   \$balance,
           "d=s", \$labelDist,
           "k=i", \$numFolds);

# Get cmd-line args
@ARGV or Usage();
my $outputDir  = shift @ARGV;
my $inputArff  = shift @ARGV;
my $sshMachine = shift @ARGV;

# Prepare output directory and subdirectories
my ($arffDir, $modelsDir, $wekaOutDir) = prepareOutDir($outputDir);

# parse input arff to get arff header and a map of pdbID => [pdbID instance lines]
my ($arffHeader, %pdbID2dataLines) = parseArff($inputArff);

# Get map of testpdbID => [trainingpdbIDs]
my %test2trainpdbIDs = mapTest2TrainpdbIDs(keys %pdbID2dataLines);

my %pdbID2balancedLines = ();
if ($balance) {
    # Create balanced sets of lines for each pdbID
    foreach my $pdbID (keys %pdbID2dataLines) {
        my $ret = eval {$pdbID2balancedLines{$pdbID}
                            = balanceLines($pdbID2dataLines{$pdbID}, $labelDist);
                        1};
        if (! $ret) {
            print "WARNING: unable to balance pdbID $pdbID, skipping ...\n";
        }
    }
}

# If training dataset needs to be balanced, send balanced line arrays for
# partitioning. Otherwise, send unbalanced line arrays.
my $training = $balance ? \%pdbID2balancedLines : \%pdbID2dataLines;

print "Creating final output model\n";
outputFinalModel($modelsDir, $arffDir, $arffHeader,
                 map {@{$_}} values %{$training});

print "Creating byChain train and test sets\n";
# Map testpdbID => trainingInstanceLines  
my %testpdbID2trainingInstanceLines
    = mapTestpdbID2trainingInstanceLines($training, \%test2trainpdbIDs);

# Map testpdbID => [trainingInstanceLines, testInstanceLines]
my %pdbID2trainAndTestInstanceLinesArefs
    = mapPdbID2trainAndTestInstanceLinesArefs(\%testpdbID2trainingInstanceLines,
                                              \%pdbID2dataLines);
if ($numFolds) {
    # In returned hash, pdbIDs will be fold IDs
    %pdbID2trainAndTestInstanceLinesArefs
        = makeFolds($numFolds, %pdbID2trainAndTestInstanceLinesArefs);
}

print "Creating train and test .arffs\n";
# Create train and test .arff files
my @trainAndTestArefs  = createPartitionArffs($arffHeader, $arffDir,
                                              %pdbID2trainAndTestInstanceLinesArefs);

my @wekaOutputs = ();

my @partitionArgArefs = ();

# Create model names and file paths
foreach my $trainAndTestAref (@trainAndTestArefs) {
    my ($trainArff, $testArff) = @{$trainAndTestAref};

    my $baseName = basename($trainArff);
    
    $baseName =~ s/arff/model/;
    my $modelFile = "$modelsDir/$baseName";
    $baseName =~ s/model/out/;
    my $outFile   = "$wekaOutDir/$baseName";
    
    push(@partitionArgArefs, [$trainArff, $testArff, $modelFile, $outFile]);
}

my %arg = (partitionAref => \@partitionArgArefs,
           removeAttribute => 1,
           posLabel => 'I',
           negLabel => 'S',
           undefLabel => '?');

$arg{remoteMachine} = $sshMachine if $sshMachine;

my $rf = WEKA::randomForest::partitionCV->new(%arg);

print "Running by-chain cross-validation\n";
my @tables = $rf->run();

my $mergedTable = confusion_table::mergeTables(@tables);

$mergedTable->print_all();

### SUBROUTINES ################################################################
################################################################################

sub outputFinalModel {
    my $modelsDir  = shift;
    my $arffDir    = shift;
    my $arffHeader = shift;
    my @trainingInstanceLines = @_;
    
    my $arffTrainFile = "$arffDir/complete.train.arff";
    open(my $OUT, ">", $arffTrainFile)
        or die "Cannot open file $arffTrainFile, $!";
    print {$OUT} $arffHeader, "\n", @trainingInstanceLines;
    close $OUT;

    my $modelFile    = "$modelsDir/complete.train.model";
    my $randomForest = WEKA::randomForest->new(model => $modelFile,
                                               trainArff => $arffTrainFile,
                                               removeAttribute => 1);
    $randomForest->train();
}

sub makeFolds {
    my $numFolds = shift;
    my %pdbID2trainAndTestInstanceLinesArefs = @_;

    my @keys = keys %pdbID2trainAndTestInstanceLinesArefs;
    # Randomly shuffle keys
    fisher_yates_shuffle(\@keys);

    # Split keys into given number of folds
    my @folds = splitKeysIntoGroups($numFolds, @keys);

    my %foldNum2trainAndTestInstanceLinesAref = ();
    my $i = 0;
   
    foreach my $fold (@folds) {
        ++$i;
        
        my @pdbids = @{$fold};
        
        my @testSet
            = map {@{$pdbID2trainAndTestInstanceLinesArefs{$_}->[1]}} @pdbids;
        
        my @trainSet = getFoldTrainingSet(\@pdbids, %pdbID2trainAndTestInstanceLinesArefs);

        $foldNum2trainAndTestInstanceLinesAref{"fold$i"} = [\@trainSet, \@testSet];
    }
    return %foldNum2trainAndTestInstanceLinesAref;
}

sub splitKeysIntoGroups {
    my $numFolds = shift;
    my @keys     = @_;
    
    my @folds;
    my $foldSize = int (@keys / $numFolds) + 1;
    push @folds, [ splice @keys, 0, $foldSize ] while @keys;
    
    # If total number of folds is not a factor of total number of keys,
    # then final fold will not be as larger as the others.
    # If this is the case, then we want to distribute the keys in the last
    # fold across the other folds, to avoid having a final fold possibly
    # much smaller than the other
    if (@{$folds[-1]} < $foldSize) {
        my $finalFold = pop @folds;
        my $i = 0;
        while (@{$finalFold}) {
            $i = 0 if $i == @folds;
            push(@{$folds[$i]}, shift @{$finalFold});
            ++$i;
        }
    }
    return @folds;
}
    
sub getFoldTrainingSet {
    my $pdbidAref = shift;
    my %pdbID2trainAndTestInstanceLinesArefs = @_;

    # Each array is the training set, minus instances from key pdbid
    my @trainInstanceArefs
        = map {$pdbID2trainAndTestInstanceLinesArefs{$_}->[0]} @{$pdbidAref};

    # If there is a only one array of instances, we can just return this
    if (@trainInstanceArefs == 1) {
        return @{$trainInstanceArefs[0]};
    }
    else {
        my $listComp = List::Compare->new('--unsorted', @trainInstanceArefs);
        # The intersection of these arrays will be the training instances, minus
        # instances from all key pdbids
        my @intersection = $listComp->get_intersection();
        
        return @intersection;    
    }
}

sub fisher_yates_shuffle {
    my $array = shift;
    my $i = @{$array};
    while (--$i) {
        my $j = int rand( $i+1 );
        @$array[$i,$j] = @$array[$j,$i];
    }
}


sub createPartitionArffs {
    my $arffHeader = shift;
    my $arffDir    = shift;
    
    my %pdbID2partitionArefs = @_;

    my @arffFiles = ();

    my @trainAndTestArefs = ();
    
    foreach my $pdbID (keys %pdbID2partitionArefs) {

        my $partition = $pdbID2partitionArefs{$pdbID};
        my ($train, $test) = @{$partition};

        # Remove colon from pdbID to make filename cleaner
        $pdbID =~ s/://;
        
        my $arffTrainFile = "$arffDir/$pdbID.train.arff";
        my $arffTestFile  = "$arffDir/$pdbID.test.arff";

        my @fileAndLinesArefs
            = ([$arffTrainFile, $train], [$arffTestFile, $test]);

        my @trainAndTest = ();
        
        foreach my $fileAndLinesAref (@fileAndLinesArefs) {
            my $outFile = $fileAndLinesAref->[0];
            open(my $OUT, ">", $outFile)
            or die "Cannot open out file $outFile, $!\n";

            my $linesAref = $fileAndLinesAref->[1];
            print {$OUT} $arffHeader, "\n", @{$linesAref};
            close $OUT;
            push(@trainAndTest, $outFile);
        }
        push(@trainAndTestArefs, \@trainAndTest);
    }
    return @trainAndTestArefs;
}

sub balanceLines {
    my $lineAref  = shift;
    my $labelDist = shift;
    
    my @intfLines = grep {/,I$/} @{$lineAref};
    my @surfLines = grep {/,S$/} @{$lineAref};

    croak "No interface instances found!" if ! @intfLines;
    croak "No surface instances found!"   if ! @surfLines;
    
    my @balancedSurfLines = ();
            
    # Randomly pick surface lines untill you have a number equal to the number
    # of interface lines, i.e. balance the dataset!
    push @balancedSurfLines, splice @surfLines, rand @surfLines, 1
        while @balancedSurfLines / (@intfLines + @balancedSurfLines) < $labelDist && @surfLines;

    return [@intfLines, @balancedSurfLines];
}

sub mapTestpdbID2trainingInstanceLines {
    my $pdbID2dataLinesHref = shift;
    my $pdbID2partitionHref = shift;
    
    my %pdbID2partitionLineAref = ();

    foreach my $pdbID (keys %{$pdbID2partitionHref}) {
        my $partition = $pdbID2partitionHref->{$pdbID};
        my @lineArefs = ();
        foreach my $partitionID (@{$partition}) {
            if (exists $pdbID2dataLinesHref->{$partitionID}) {
                push(@lineArefs, $pdbID2dataLinesHref->{$partitionID});
            }
            else {
                print "WARNING: no partition found for $partitionID\n";
            }
        }
        # Collapse each array ref into array of lines
        my @lines = map { @{$_} } @lineArefs;
        $pdbID2partitionLineAref{$pdbID} = \@lines;
    }
    return %pdbID2partitionLineAref;
}

sub mapTest2TrainpdbIDs {
    my @pdbIDs = @_;

    my %test2trainpdbIDs = ();
    
    foreach my $pdbID (@pdbIDs) {
        my @trainpdbIDs = grep {$_ ne $pdbID} @pdbIDs;
        $test2trainpdbIDs{$pdbID} = \@trainpdbIDs;
    }
    return %test2trainpdbIDs;
}

sub createLOOpartitions {
    my %pdbID2dataLines = @_;
    
    my @lineArefs = (values %pdbID2dataLines);
    
    my %pdbID2partitionArefs = ();
    
    foreach my $pdbID (keys %pdbID2dataLines) {
        my $excludedAref = $pdbID2dataLines{$pdbID};
        
        my @partition = grep {$_ ne $excludedAref} @lineArefs;
        # Collapse each array ref into array of lines
        @partition = map { @{$_} } @partition;
        
        $pdbID2partitionArefs{$pdbID} = [\@partition, $excludedAref];
    }
    return %pdbID2partitionArefs;
}

sub mapPdbID2trainAndTestInstanceLinesArefs {
    my $testpdbID2trainingInstanceLinesHref = shift;
    my $pdbID2dataLinesHref = shift;

    my %pdbID2trainAndTestInstanceLinesArefs = ();

    foreach my $pdbID (keys %{$pdbID2dataLinesHref}) {
        # Remove unlabelled instances from training (unlabelled label = ?) 
        my @trainingLines
            =  grep {! /,\?$/} @{$testpdbID2trainingInstanceLinesHref->{$pdbID}};

        my @testLines = @{$pdbID2dataLinesHref->{$pdbID}};

        $pdbID2trainAndTestInstanceLinesArefs{$pdbID}
            = [\@trainingLines, \@testLines];
    }

    return %pdbID2trainAndTestInstanceLinesArefs;
}

sub parseArff {
    my $inputArff = shift;

    open(my $IN, "<", $inputArff)
        or die "Cannot open input file $inputArff, $!";

    my @headerLines = ();

    my $inData = 0;

    my %pdbID2dataLines = ();
    
    while (my $line = <$IN>) {
      
        if (! $inData) {
            push (@headerLines, $line);
            
            if ($line =~ /^\@data/){
                $inData = 1;
                next;
            }
        }
        elsif ($line =~ /^\s+$/) {
            # Avoid including white-space lines after @data line in data lines
            next;
        }
        else {
            my ($pdbID) = $line =~ /^(\S+:\S):/g;
            if (! exists $pdbID2dataLines{$pdbID}) {
                $pdbID2dataLines{$pdbID} = [$line]; 
            }
            else {
                push(@{$pdbID2dataLines{$pdbID}}, $line);
            }
        }
    }

    my $headerStr = join("", @headerLines);
    
    return($headerStr, %pdbID2dataLines);
}

sub prepareOutDir {
    my $outputDir = shift;

    print "Checking dirs ...\n";
    
    mkdir $outputDir if ! -d $outputDir;

    my $arffDir    = "$outputDir/arffs";
    mkdir $arffDir if ! -d $arffDir;
    
    my $modelsDir  = "$outputDir/models";
    mkdir $modelsDir if ! -d $modelsDir;
    
    my $wekaOutDir = "$outputDir/wekaOut";
    mkdir $wekaOutDir if ! -d $wekaOutDir;

    return($arffDir, $modelsDir, $wekaOutDir);
}

sub Usage {
    print <<EOF;
$0 -b -k INT outputDir inputArff sshMachine

If no sshMachine is supplied, then WEKA is run locally.

 -b : Balance training sets.
 -k : k-fold CV. If specified, this will split training and test sets into k
      sets for CV, rather than doing leave-one-out byChain CV.
}

byChainCV.pl allows you to perform by-chain cross validation on a data set of
patches. By-chain cross validation ensures that patches from a given chain do
not occur in training and test sets. For each chain in the data set, a training
set is created without patches from that chain. Patches from the excluded chain
are then used as a test set. The results from each test run are then collected
and performance metrics are output.

EOF
    exit(1);
}
