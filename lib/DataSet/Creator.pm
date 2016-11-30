package DataSet::Creator;
use Moose;
use Carp;

has 'parent' => (
    is => 'rw',
    predicate => 'has_parent',
);

has 'child' => (
    is => 'rw',
    lazy => 1,
    builder => 'nextChild',
);

has 'childInput' => (
    is => 'rw',
    isa => 'ArrayRef',
);

has '_iter' => (
    traits => ['Counter'],
    is => 'rw',
    isa => 'Num',
    handles => {_inc_iter => 'inc'},
    default => 0,
);

has 'childClass' => (
    is => 'rw',
    isa => 'Str',
    lazy => 1,
    builder => 'buildChildClass',
);

has 'model' => (
    is => 'rw',
    isa => 'DataSet::Instance::Model',
    lazy => 1,
    builder => 'modelFromParent',
    required => 1,
);

sub calcAvgScoreFromResNames {
    my $self = shift;
    my $inst = shift;
    my $resName2ScoreHref = shift;
    
    my $total = 0;
    map {$total += $resName2ScoreHref->{$_}} @{$inst->resNames};
    return $total / scalar @{$inst->resNames};    
}

sub calcAvgScoreFromResIDs {
    my $self = shift;
    my $inst = shift;
    my $resID2ScoreHref = shift;
    
    my $total = 0;
    map {confess "$self: $_ is not in resID2ScoreHref" if ! exists $resID2ScoreHref->{$_};
         $total += $resID2ScoreHref->{$_}} @{$inst->resIDs};
    return $total / scalar @{$inst->resIDs};
}

sub calcAvgScoreFromPDBResIDs {
    my $self = shift;
    my $inst = shift;
    my $pdbResID2ScoreHref = shift;
    
    my $total = 0;
    map {confess "$self: $_ is not in pdbResID2ScoreHref" if ! exists $pdbResID2ScoreHref->{$_};
         $total += $pdbResID2ScoreHref->{$_}}
        map {my $resID = $_; $resID =~ s/\./:/;
             join(":", $inst->getPDBCode(), $resID)} @{$inst->resIDs};
    return $total / scalar @{$inst->resIDs};
}

sub nextInstance {
    my $self = shift;
    
    # Child will = 0 when are there no more children left to get instances from
    return 0 if ! $self->child();
    
    if (! $self->child->can("nextInstance")){
        # If child cannot do nextInstance, then it is an instance itself
        my $instance = $self->child();
        $self->addFeatures($instance) if $self->can("addFeatures");

        # An instance has no children so set child to 0 - this ensures that next
        # time nextInstance is run, it will move on to nextChild
        $self->child(0);
        return $instance;
    }
    elsif (my $instance = $self->child->nextInstance()) {
        # Get next instance from child
        $self->addFeatures($instance) if $self->can("addFeatures");
        return $instance;
    }
    else {
        # Assign next child, then run nextInstance again to get next child
        $self->child($self->nextChild());
        return $self->nextInstance();
    }
}

sub allChildren {
    my $self = shift;
    my @children = ();
    while (my $child = $self->nextChild()) {
        push(@children, $child);
    }
    return @children;
}

sub nextChild {
    my $self = shift;

    return 0 if $self->_iter >= @{$self->childInput};

    # If child is in instance, then no arguments need to be sent
    my @arg = $self->childClass eq 'DataSet::Instance' ? ()
        : ($self->childInput->[$self->_iter], parent => $self);
    
    my $child = $self->childClass->new(@arg);

    print "$self - new child $child\n";
    $self->_inc_iter();
    return $child;
}

sub modelFromParent {
    my $self = shift;
    if ($self->has_parent) {
        $self->model($self->parent->model());
    }
    else {
        confess "Could not get model from parent: "
            . ! $self->has_parent ? "parent has not been set"
                : "parent does not have a model";
    }
}

package DataSet::Creator::Master;
use Moose;
use MooseX::Aliases;
use DataSet::Input;
use Carp;
use Parallel::ForkManager;
use Storable;

extends 'DataSet::Creator';
use overload '""' => 'stringify';

has 'inputs' => (
    isa => 'ArrayRef[DataSet::Input]',
    is  => 'rw',
    alias => 'childInput'
);

has 'maxProc' => (
    is => 'rw',
    isa => 'Int',
    default => 1,
);

sub buildChildClass {
    return "DataSet::Creator::PDB";
}

sub addFeatures {
    my $self  = shift;
}

sub getDataSet {
    my $self = shift;
    return DataSet->new(instancesAref => [$self->getInstances()],
                        instanceModel => $self->model());
}

sub getInstances {
    my $self = shift;
    my @instances = ();
    if ($self->maxProc > 1) {
        @instances = $self->_getInstancesInParallel();
    }
    else {
        while (my $instance = $self->nextInstance()) {
            push(@instances, $instance);
        }
    }
    return @instances;
}

sub _getInstancesInParallel {
    my $self = shift;
    my @children = $self->allChildren();
    my @childOutFiles = $self->_getTmpFilesForChildren(@children); 
    my $pm = Parallel::ForkManager->new($self->maxProc);
    for (my $i = 0 ; $i < @children ; ++$i) {
        my $pid = $pm->start and next;
        my $child = $children[$i];
        my @instances = ();
        while (my $instance = $child->nextInstance()) {
            push(@instances, $instance);
        }
        store \@instances, $childOutFiles[$i];
        $pm->finish;
    }
    $pm->wait_all_children;
    my @instances = $self->_retrieveInstancesFromChildFiles(@childOutFiles);
    return @instances;
}

sub _getTmpFilesForChildren {
    my $self     = shift;
    my @children = @_;
    my $pID      = $$;
    return map {"/tmp/$pID" . "child$_.instancesAref"} 0 .. @children - 1;
}

sub _retrieveInstancesFromChildFiles {
    my $self          = shift;
    my @childOutFiles = @_;
    my @instances     = map {@{retrieve($_)}} @childOutFiles;
    $self->_removeFiles(@childOutFiles);
    return @instances;
}

sub _removeFiles {
    my $self = shift;
    map {unlink($_)} @_; 
}

sub stringify {
    my $self  = shift;
    return "DataSet::Creator::Master";
}

package DataSet::Creator::PDB;
use Moose;
use MooseX::Aliases;
use TCNUtil::types;

extends 'DataSet::Creator';
use overload '""' => 'stringify';

has 'complexChainIDs' => (
    isa => 'ArrayRef',
    is  => 'rw',
    alias => 'childInput'
);

has 'pdb' => (
    isa => 'pdb',
    is  => 'rw',
);

sub buildChildClass {
    return 'DataSet::Creator::Complex'
}

# This allows constructor arguments to be taken from an input object
around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    
    if (ref $_[0] eq 'DataSet::Input') {
        my $input = shift;
        my @arg = _getArgFromInput($input);
        return $class->$orig(@arg, @_);
    }
    else {
        return $class->$orig(@_);
    }
};

sub stringify {
    my $self = shift;

    return "DataSet::Creator::PDB - " . $self->pdb->pdb_code();
}

sub _getArgFromInput {
    my $input = shift;

    my $pdb = pdb->new(pdb_file => $input->inputFile,
                       het_atom_cleanup => 1);
    $pdb->pdb_code($input->pdbCode) if $input->has_pdbCode();
    
    return (pdb => $pdb, complexChainIDs => $input->complexChainIDs);
}

package DataSet::Creator::Complex;
use Moose;
use MooseX::Aliases;
use Moose::Util::TypeConstraints;
use pdb::solv;
use Carp;

extends 'DataSet::Creator';

use overload '""' => 'stringify';

has 'complexResID2RelASAHref' => (
    isa     => 'HashRef',
    is      => 'rw',
    lazy    => 1,
    builder => 'buildComplexResID2RelASAHref'
);

has 'complexChains' => (
    isa      => 'ArrayRef[chain]',
    is       => 'rw',
    default => sub { [] },
);

has 'targetChains' => (
    isa   => 'ArrayRef[chain]',
    is    => 'rw',
    alias => 'childInput',
    default => sub { [] }, 
);

subtype 'HashOfResIDs',
    as 'HashRef';

coerce 'HashOfResIDs',
    from 'ArrayRef[Str]',
    via { my %h = map {$_ => 1} @{$_}; \%h };

has 'interfaceResidues' => (
    isa => 'HashOfResIDs',
    is  => 'rw',
    coerce => 1,
    lazy => 1,
    builder => 'getInterfaceResidues'
);

sub buildChildClass {
    return "DataSet::Creator::Chain";
}

# This allows constructor arguments to be taken from a complexChainAref
around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    
    if (ref $_[0] eq 'ARRAY') {
        my $complexChainIDAref = shift;
        my %arg = @_;
        
        my %extraArg = _getArgFromPDBAndComplexChainAref($arg{parent}->pdb(),
                                                         $complexChainIDAref);
        return $class->$orig(%extraArg, %arg);
    }
    else {
        return $class->$orig(@_);
    }
};

sub _getArgFromPDBAndComplexChainAref {
    my $pdb = shift;
    my $complexChainIDAref = shift;

    my %arg = ();
    
    my @targetChainIDs  = @{$complexChainIDAref->[0]};
    my @targetChains    = $pdb->create_chains(@targetChainIDs);
    $arg{targetChains} = \@targetChains;
    
    my @complexChainIDs = @{$complexChainIDAref->[1]};
    $arg{complexChains}
        = [$pdb->create_chains(@complexChainIDs)] if @complexChainIDs;
    
    return %arg;
}

sub getInterfaceResidues {
    my $self = shift;

    my @interfaceResidues = ();
    
    if ($self->model->hasInterfaceResIDs) {
        foreach my $chain (@{$self->targetChains}) {
            croak "Target chain " . $chain->pdbID . " has no interface residues"
                . " as specified by the user."
                if ! exists $self->model->interfaceResIDs->{$chain->pdbID};

            push(@interfaceResidues,
                 @{$self->model->interfaceResIDs->{$chain->pdbID}});
        }
    }
    else {
        my $r2A  = $self->complexResID2RelASAHref();
        my @interfaceResidues = ();
        foreach my $chain (@{$self->targetChains}) {
            push(@interfaceResidues, $chain->getInterfaceResidues($r2A));
        }
    }
    return \@interfaceResidues;
}

    
sub buildComplexResID2RelASAHref {
    my $self = shift;

    my @atoms
        = map { @{$_->atom_array} }
            @{$self->targetChains}, @{$self->complexChains};
    
    my $asurf = pdb::solv->new(input => \@atoms);
    $asurf->getOutput();
    return $asurf->resid2RelASAHref();
}

sub addFeatures {
    my $self = shift;
    my $inst = shift;

    # Get class label
    $inst->class($self->getClassLabelFor($inst));
}

sub getClassLabelFor {
    my $self     = shift;
    my $instance = shift;

    if ($self->model->hasUserLabels) {
        return $self->model->userLabels->{$instance->id};
    }
    else {
        return $self->calculateClassLabelFor($instance);
    }
}

sub calculateClassLabelFor {
    my $self    = shift;
    my $inst    = shift;
    
    my $iResIDs = $self->interfaceResidues();
    
    $self->child->chain->read_ASA() if ! $self->child->chain->has_read_ASA();
    
    my $id2ASA  = $self->child->chain->resid2RelASAHref();
    my $tASA    = 0;
    my $iASA    = 0;
    
    map {$tASA += $id2ASA->{$_}->{allAtoms};
         $iASA += $id2ASA->{$_}->{allAtoms} if exists $iResIDs->{$_}} @{$inst->resIDs()};

    return $iASA == 0 ? 'S'
        : $iASA / $tASA > $self->model->labelThreshold ? 'I'
            : 'U';
}

sub stringify {
    my $self = shift;

    my $string = "DataSet::Creator::Complex - Target Chains: "
        . join(",", map {$_->chain_id()} @{$self->targetChains()});

    $string .= " Complex Chains: "
        . join(", ", map {$_->chain_id()} @{$self->complexChains()})
            if @{$self->complexChains()};
    
    return $string;
}

package DataSet::Creator::Chain;
use Moose;
use MooseX::Aliases;
use pdb::automatic_patches;
use DataSet::CalcConservationScores;

use overload '""' => 'stringify';

extends 'DataSet::Creator';

has 'chain' => (
    is => 'rw',
    isa => 'chain',
);

has 'resID2FOSTAScore' => (
    isa => 'HashRef',
    is  => 'rw',
    lazy => 1,
    builder => 'buildResID2FOSTAScore'
);

has 'FOSTAErr' => (
    isa => 'Str',
    is  => 'rw',
    predicate => 'hasFOSTAErr'
);

has 'resID2BLASTScore' => (
    isa => 'HashRef',
    is  => 'rw',
    lazy => 1,
    builder => 'buildResID2BLASTScore'
);

has 'BLASTErr' => (
    isa => 'Str',
    is  => 'rw',
    predicate => 'hasBLASTErr',
);

has 'resID2secStruct' => (
    isa => 'HashRef',
    is  => 'rw',
    lazy => 1,
    builder => 'buildResID2SecStruct',
);

has 'patches' => (
    is => 'rw',
    isa => 'ArrayRef[patch]',
    alias => 'childInput',
    lazy => 1,
    builder => 'buildPatches'
);

has 'consScoresDir', => (
    is => 'rw',
    predicate => 'has_consScoresDir',
);


around 'BUILDARGS' => sub {
    my $orig  = shift;
    my $class = shift;
    
    if (ref $_[0] eq 'chain') {
        my $chain = shift;
        return $class->$orig(chain => $chain, @_);
    }
    else {
        return $class->$orig(@_);
    }
};

sub BUILD {
    my $self  = shift;
    my $chain = $self->chain();
    
    $chain->labelppHbondedAtoms() if $self->model->has_Hb;
    $chain->labelSSbondedAtoms()  if $self->model->has_SS;
    
    # These attributes are called to run their corresponding builder methods.
    # This ensures that if they do fail, then DataSet::Creator::Chain error
    # attributes are set to be investigated during DataSet::Creator::Chain
    # addFeatures method.
    $self->resID2FOSTAScore()     if $self->model->has_fosta;
    $self->resID2BLASTScore()     if $self->model->has_blast;
}

sub buildPatches {
    my $self = shift;
    
    if ($self->model->haspSummaries) {
        my $pdbID = $self->chain->pdb_code . $self->chain->chain_id;
        # Build patches from summary lines
        return [ map {patch->new(parent_pdb => $self->chain, summary => $_)}
                     @{$self->model->pSummaries->{$pdbID}} ];
    }
    else {
        my $ap = automatic_patches->new(
            pdb_object => $self->chain,              patch_type => 'normal',
            radius     => $self->model->patchRadius, ASA_type   => 'ASAb',
            build_patches_from_parent => 1 );
        return [$ap->get_patches($self->_getGetPatchesArgs())];
    }
}

sub _getGetPatchesArgs {
    my $self = shift;
    my %arg = ();
    if ($self->model->haspCentres) {
        my $pdbCode = $self->chain->pdb_code;
        my $chainID = $self->chain->chain_id;
        my $resSeqAndAtomNameArefs = $self->model->pCentres->{$pdbCode}->{$chainID};
        my @patchCentres = map {$self->chain->getAtomFromResSeqAndAtomName(@{$_})}
            $self->_filterOutNoCAResSeqs($resSeqAndAtomNameArefs);
        
        $arg{patch_centres} = \@patchCentres;
    }
    return %arg;
}

sub _filterOutNoCAResSeqs {
    my $self = shift;
    my $resSeqAndAtomNameArefs = shift;
    return grep {$self->chain->doesResSeqHaveCA($_->[0])} @{$resSeqAndAtomNameArefs};
}

sub buildChildClass {
    return "DataSet::Creator::Patch";
}

sub buildResID2FOSTAScore {
    my $self = shift;

    my %rSeq2FScore
        = eval {DataSet::CalcConservationScores::getFOSTAScoresForChain(
            $self->chain,
            $self->model->has_consScoresDir ? $self->model->consScoresDir : "",
            $self->model->FOSTAHitMin)};

    if(! %rSeq2FScore){
	print "No FOSTA scores obtained for " . $self->chain->pdbID();
	if($@ =~ /Error code -1/){
	    print ": chain is not assigned to a FOSTA family\n";
	}
	else{
	    print $@;
	}
	$self->FOSTAErr($@);
	return {};
    }
    # Return ref to hash where keys are ResIDs (ChainID.resSeq)
    return {map {$self->chain->chain_id . ".$_" => $rSeq2FScore{$_}}
                keys %rSeq2FScore}
}

sub buildResID2BLASTScore {
    my $self = shift;
    
    my %rSeq2BScore
        = eval {DataSet::CalcConservationScores::getBLASTScoresForChain(
            $self->chain,
            $self->model->has_consScoresDir ? $self->model->consScoresDir : "",
            0.01, # e-value
            $self->model->BLASTHitMin,
            $self->model->BLASTHitMax)};

    if(! %rSeq2BScore){
	print "No BLAST scores obtained for " . $self->chain->pdbID() 
	    . ": " . $@ . "\n";
	$self->BLASTErr($@);
	return {};
    }
   
    # Return ref to hash where keys are ResIDs (ChainID.resSeq)
    return {map {$self->chain->chain_id . ".$_" => $rSeq2BScore{$_}}
                keys %rSeq2BScore};    
}

sub addFeatures {
    my $self  = shift;
    my $inst  = shift;
   
    # Calculate patch propensity
    $inst->pro($self->getPatchPropensity($inst)) if $self->model->has_pro;
    
    # Calculate Secondary Structure
    $inst->secStruct($self->getPatchSecStructStr($inst)) if $self->model->has_secStruct;

    # Calculate FOSTA scores. 
    $inst->fosta($self->getFOSTAScore($inst)) if $self->model->has_fosta;
    
    # Calculate BLAST scores. Set to missing value '?' if BLAST failed.
    $inst->blast($self->hasBLASTErr ? '?'
                     : $self->calcAvgScoreFromResIDs($inst,
                                                     $self->resID2BLASTScore))
        if $self->model->has_blast;
    
    # Calculate patch rASA
    $inst->rASA($self->getPatchrASA($inst)) if $self->model->has_rASA();

    # Calculate patch tolerance score
    $inst->tol($self->getTolerance($inst)) if $self->model->has_tol;
}

sub getTolerance {
    my $self = shift;
    my $inst = shift;
    my $tol = eval {$self->calcAvgScoreFromPDBResIDs($inst, $self->model->pdbResID2TolLabel)};
    return defined $tol ? $tol : '?'; 
}

sub getFOSTAScore {
    my $self = shift;
    my $inst = shift;
    if ($self->hasFOSTAErr) {
        # Set to missing value '?' if FOSTA failed.
        return '?'
    }
    else {
        # Sometimes not all of a chain seq is aligned with a pdbsws entry and
        # therefore not all residues have a FOSTA score. For patches including
        # those residues, return missing value
        my $fostaScore
            = eval {$self->calcAvgScoreFromResIDs($inst, $self->resID2FOSTAScore)};
        return defined $fostaScore ? $fostaScore : '?';
    }
}

sub getPatchrASA {
    my $self = shift;
    my $inst = shift;
    $self->chain->read_ASA() if ! $self->chain->has_read_ASA();
    my $id2ASA = $self->chain->resid2RelASAHref();
    my $total = 0;
    map {$total += $id2ASA->{$_}->{allAtoms}} @{$inst->resIDs};
    return $total / scalar @{$inst->resIDs};
}

sub getPatchPropensity {
    my $self  = shift;
    my $inst  = shift;
    my $chain = $self->chain();

    $chain->read_ASA() if ! $chain->has_read_ASA();
    
    my $propCalc = $self->model->propCalc;

    my $total = 0;
    my $numResidues = scalar @{$inst->resIDs};
    
    foreach my $resID (@{$inst->resIDs}) {        
        my $asa = 0;
        map {$asa += $_->ASAb if $_->has_ASAb}
            values %{$chain->resid_index->{$resID}};
        my $resScore
            = $propCalc->getResidueScore($chain->getResNames($resID), $asa);

        $total += $resScore / $numResidues;
    }
    return $total;
}

sub getPatchSecStructStr {
    my $self  = shift;
    my $inst = shift;
    my $resID2SecStruct = $self->chain->resID2secStructHref;

    my @secStructLabels
        = map {$resID2SecStruct->{$_}} @{$inst->resIDs()};
    
    my $secStructStr = "";

    my $fracSheet = (scalar grep {/e/i} @secStructLabels) / @secStructLabels;
    my $fracHelix = (scalar grep {/h/i} @secStructLabels) / @secStructLabels;

    $secStructStr .= "E" if $fracSheet > $self->model->secStructThresh;
    $secStructStr .= "H" if $fracHelix > $self->model->secStructThresh;
    $secStructStr .= "C" if ! $secStructStr;

    return $secStructStr;
}

sub stringify {
    my $self = shift;
    return 'DataSet::Creator::Chain - ' . $self->chain->pdb_code . $self->chain->chain_id();
};

package DataSet::Creator::Patch;
use Moose;
use MooseX::Aliases;
extends 'DataSet::Creator';

use overload '""' => 'stringify';

has 'patch' => (
    is => 'rw',
    isa => 'patch',
    predicate => 'has_patch'
);

has 'childInput' => (
    is  => 'ro',
    isa => 'ArrayRef',
    default => sub { [[]] },
);

sub buildChildClass {
    return 'DataSet::Instance';
}

around 'BUILDARGS' => sub {
    my $orig  = shift;
    my $class = shift;
    
    if (ref $_[0] eq 'patch') {
        my $patch = shift;
        return $class->$orig(patch => $patch, @_);
    }
    else {
        return $class->$orig(@_);
    }
};

sub addFeatures {
    my $self = shift;
    my $inst = shift;

    if ($self->has_patch()) {
        my $p = $self->patch();

        # resIDs, resNames and summary are all needed by parent Creators
        $inst->resIDs([$p->getResIDs(include_missing => 0)]);
        $inst->resNames([$p->getResNames($p->getResIDs)]);
        $inst->summary($p->summary);
        
        $inst->id(getPatchID($p))
            if $self->model->has_id;
        $inst->pho($p->calcAverageHydrophobicity)
            if $self->model->has_pho;
        $inst->pln($p->planarity)
            if $self->model->has_pln;
        $inst->SS(getNumSSBonds($p))
            if $self->model->has_SS;
        $inst->Hb(getNumHbonds($p))
            if $self->model->has_Hb;
    }
}

sub getPatchID {
    my $patch = shift;

    my $id = join(":", ($patch->pdb_code, $patch->central_atom->chainID,
                        $patch->central_atom->resSeq));
    return $patch->central_atom->has_iCode ? $id . $patch->central_atom->iCode()
        : $id;
}

sub getNumSSBonds {
    my $patch = shift;

    my $resCount = scalar $patch->getResIDs();
    my $bndCount = scalar grep {$_->has_SSbond} @{$patch->atom_array};
    
    return $bndCount / $resCount;
}

sub getNumHbonds {
    my $patch = shift;

    my $resCount = scalar $patch->getResIDs();
    my $bndCount = scalar grep {$_->has_HbDonor || $_->has_HbAcceptor}
        @{$patch->atom_array};
    
    return $bndCount / $resCount;
}

sub stringify {
    my $self = shift;
    my $patch = $self->patch();
    return "DataSet::Creator::Patch - $patch";
}

1;

__END__

=head1 NAME

DataSet::Creator.pm - A set of Moose classes for creating an IntPred dataset
from a set of user inputs.

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

TODO
