#!/usr/bin/env perl
# addClusterMetric.pl --- 
# Author: Tom Northey <zcbtfo4@acrm18>
# Created: 19 Mar 2015

use warnings;
use strict;
use pdb::pdb;
use arff;
use IntPred::lib::wekaOutputParser;
use Getopt::Long;

# Distance threshold for finding positively predicted neighbours
my $distance;
GetOptions("d=i" => \$distance);
$distance = 14 if ! $distance;

my $inputArffFile = shift @ARGV;
my $inputCSVFile  = shift @ARGV;

Usage() if ! ($inputCSVFile && $inputCSVFile);

my $inputArff = arff->new(file => $inputArffFile, idAttributeIndex => 'first',
                          classAttributeIndex => 'last');

my @chainAndPatchCentreResSeqs = getChainsAndPatchCentreResSeqs($inputArff);
my %pdbID2pPredResSeqs = getPositivePredResSeqs($inputCSVFile);

my %patchID2neighbourDist = ();

foreach my $chainAndPatchCentreResSeqAref (@chainAndPatchCentreResSeqs) {
    my $chain = $chainAndPatchCentreResSeqAref->[0];
    my @patchCentreResSeqs = @{$chainAndPatchCentreResSeqAref->[1]};
    
    my $pdbID = join(":", ($chain->pdb_code, $chain->chain_id));
    my @posPredResSeqs = @{$pdbID2pPredResSeqs{$pdbID}};
    
    my @posPredResSeqXYZs = map {getResSeqXYZ($chain, $_)} @posPredResSeqs;
    
    foreach my $resSeq (@patchCentreResSeqs) {
        my $xyz = getResSeqXYZ($chain, $resSeq);
        my $numNeighbours = numNeighboursWithinDistance($distance, $xyz,
                                                        @posPredResSeqXYZs);
        
        my $patchID = join(":", $pdbID, $resSeq);
        $patchID2neighbourDist{$patchID} = $numNeighbours;
    }
}

$inputArff->addAttributeAndValuesToInstances("pPredDist numeric",
                                        \%patchID2neighbourDist);

print $inputArff->arff2String;

sub numNeighboursWithinDistance {
    my $distance = shift;
    my $xyz = shift;
    my @neighbourXYZs = @_;
    
    my @squaredDistances = getSquaredDistances($xyz, @neighbourXYZs);

    my $squaredDistance = $distance ** 2;
    my @withinDistance = grep {$_ < $squaredDistance} @squaredDistances;

    return scalar @withinDistance;
}

# Currently not being used
sub findNearestNeighbourSquaredDistance {
    my $xyz = shift;
    my @neighbourXYZs = @_;

    my @squaredDistances = getSquaredDistances($xyz, @neighbourXYZs);

    my @sortedDistances = sort {$a <=> $b} @squaredDistances;

    return $sortedDistances[0];
}

sub getSquaredDistances {
    my $xyz = shift;
    my @neighbourXYZs = @_;
    
    my @squaredDistances = map {squaredDistance($xyz, $_)} @neighbourXYZs;

    # Remove any distances = 0 - this is the distance between the co-ordinate
    # and itself!
    @squaredDistances = grep {$_ != 0} @squaredDistances;
    
    return @squaredDistances;
}

sub squaredDistance {
    my $xyz1 = shift;
    my $xyz2 = shift;

    my @deltas = map {($xyz1->[$_] - $xyz2->[$_])**2} (0 .. 2);

    my $sum = 0;
    $sum += $_ foreach @deltas;

    return $sum;
}

sub getResSeqXYZ {
    my $chain = shift;
    my $resSeq = shift;

    my @XYZ = ();

    my $atom = $chain->atom_index->{$chain->chain_id}->{$resSeq}->{CA};
    foreach my $coord (qw(x y z)) {
        push (@XYZ, $atom->$coord);
    }
    return \@XYZ;
}

sub patchCentre2NearestNeighbourDistance {
    my $chain = shift;
    my @resIDs = @_;
    
    my @distanceMatrix = ();

    # Construct distance matrix
    for (my $i = 0 ; $i < @resIDs ; ++$i) {
        for (my $j = 0 ; $j < @resIDs ; ++$j) {
            $distanceMatrix[$i][$j] = 999999 if $i == $j;
            
            if (! defined $distanceMatrix[$i][$j]) {
                my @Calphas = map {$chain->resid_index->{$_}->{CA}}
                    ($resIDs[$i], $resIDs[$j]);
                
                my $distance = $chain->squaredDistance(@Calphas);

                # Distance is obviously symmetrical, so assign distance to i,j
                # and j,i
                $distanceMatrix[$i][$j] = $distance;
                $distanceMatrix[$j][$i] = $distance;
            }
        }
    }

    my %resID2ShortestDistance = ();

    # Find shortest distance for each residue
    for (my $i = 0 ; $i < @resIDs ; ++$i) {
        my $shortestDistance = [sort {$a <=> $b} @{$distanceMatrix[$i]}]->[0];

        my $resID = $resIDs[$i];

        $resID2ShortestDistance{$resID} = $shortestDistance;
    }
    
    return %resID2ShortestDistance;
}

sub getPositivePredResSeqs {
    my $inputCSV = shift;

    my @lines = map {IntPred::lib::wekaOutputParser::parseCSVLine($_)}
        IntPred::lib::wekaOutputParser::getLinesFromCSVFile($inputCSV);

    # Get patch ids for those patches that are predicted positive (i.e. intf)
    my @posPredPatchIDs = map {$_->[0]} grep {$_->[2] eq '1:I'} @lines;

    my %pdbID2pCentreResSeqs = ();

    # Hash patch centre residues by pdbIDs
    foreach my $patchID (@posPredPatchIDs) {
        # example instance id: 1bgx:T:536
        my $pdbID = substr($patchID, 0, 6);
        my $resSeq = substr($patchID, 7);

        if (exists $pdbID2pCentreResSeqs{$pdbID}) {
            push(@{$pdbID2pCentreResSeqs{$pdbID}}, $resSeq);
        }
        else {
            $pdbID2pCentreResSeqs{$pdbID} = [$resSeq];
        }
    }
    return %pdbID2pCentreResSeqs;
}

sub getChainsAndPatchCentreResSeqs {
    my $inputArff = shift;

    my %pdbID2pCentreResSeqs = ();
    
    # Hash patch centre residues by pdbIDs
    foreach my $instance (@{$inputArff->instances}) {
        # example instance id: 1bgx:T:536
        my $pdbID = substr($instance->id, 0, 6);
        my $resSeq = substr($instance->id, 7);

        if (exists $pdbID2pCentreResSeqs{$pdbID}) {
            push(@{$pdbID2pCentreResSeqs{$pdbID}}, $resSeq);
        }
        else {
            $pdbID2pCentreResSeqs{$pdbID} = [$resSeq];
        }
    }

    my @chainAndpCentreResSeqs = ();
    
    # Create chain objects from pdbIDs
    foreach my $pdbID (keys %pdbID2pCentreResSeqs) {
        my $pdbCode = substr($pdbID, 0, 4);
        my $chainID = substr($pdbID, 5, 1);
        my $chain = chain->new(pdb_code => $pdbCode, chain_id => $chainID);

        push(@chainAndpCentreResSeqs, [$chain, $pdbID2pCentreResSeqs{$pdbID}]);
    }
    return @chainAndpCentreResSeqs;
}

sub Usage {
    print <<EOF;
$0 -d INT arffFile CSVFie

Opts:
  -d: specify the distance threshold (ang) for finding positively predicted
      neighbours. DEFAULT = 14
Args:
  arffFile: the dataset .arff file that you want to add a cluster metric to
  CSVFile:  the weka output .csv file that contains prediction labels that are
            used to calculate the cluster metric. 
EOF
    exit(1);
}
