package DataSet::CalcConservationScores;
use strict; 
use warnings;

use TCNUtil::MSA;
use pdb::BLAST;
use pdb::pdbsws;
use TCNPerlVars;
use TCNUtil::scorecons;
use Carp;
use UNIPROT;
use TCNUtil::FOSTA;

use TCNUtil::sequence;

sub getBLASTScoresForChain {
    my ($chain, $storedScoresDir, $eval, $hitMin, $hitMax) = @_;
    return getConsScores("BLAST", @_);
}

sub getFOSTAScoresForChain {
    my ($chain, $storedScoresDir, $hitMin) = @_;
    return getConsScores("FOSTA", @_);
}

sub getConsScores {
    my $scoreType = shift;
    my $chain = shift;
    my $storedScoresDir = shift;
    my %rSeq2consScores;

    my $previousAttempt = 0;
    
    if ($storedScoresDir) {
        my $success = eval {%rSeq2consScores = getStoredConsScores($storedScoresDir, $chain, $scoreType);
                        1};
        if (! $success) {
            if ($@ =~ /No attempt/) {
                # No attempt made previously, so we'll try below
            }
            else {
                croak "Something went wrong trying to get saved $scoreType scores: $@";
            }
        }
        else {
            $previousAttempt = 1;
        }
    }

    # Check for no previous attempt because hash will be empty
    # if there has been a previous attempt that didn't work
    # (and we don't want to repeat the failed process!)
    if (! %rSeq2consScores && ! $previousAttempt) {
        my $success = eval {
            if ($scoreType eq "BLAST") {
                %rSeq2consScores = BLAST($chain, @_);
            }
            else {
                %rSeq2consScores = FOSTA($chain, @_);
            }
            1;
        };
        _saveConsScores($storedScoresDir, $chain, $scoreType, \%rSeq2consScores)
            if $storedScoresDir;
        if (! $success) {
            croak $@;
        }
    }
    return %rSeq2consScores;
}

sub BLAST {
    my ($chain, $eval, $hitMin, $hitMax) = @_;
    
    # Get homologue sequences
    # Opts match Anja's originals
    my %arg = (evalue => $eval, opts => {-b => 2000, -v => 2000,
                                         -F => 'T'});
    
    my $blaster = pdb::BLAST::Factory->new(remote => 0,
                                           dbType => 'swsprot')->getBlaster(%arg);
    $blaster->setQuery($chain);
    $blaster->runBlast();
    
    my @hits = $blaster->reportHandler->getHits(reliable => 1);
    
    my @hitSeqs = ();
    my $hitCount = 0;
    
    foreach my $hit (@hits) {
	my $hitSeq = $blaster->reportHandler->swissProtSeqFromHit($hit);
        print "WARNING: Failed to get sequence for hit $hit, $@" && next
            if ! $hitSeq;
        
        push(@hitSeqs, $hitSeq);
        ++$hitCount;
        last if $hitCount == $hitMax;
    }

    printf "INFO: %s hit seqs obtained\n", scalar @hitSeqs;

    croak "Number of sequences returned by BLAST search does not reach minimum!"
        . " number returned = " . @hitSeqs . ", minimum = " . $hitMin
            if @hitSeqs < $hitMin;
    
    # Align homologue sequences and chain sequence
    # Flags and opts match Anja's originals
    my @muscleArg = (seqs  => [$chain, @hitSeqs],
                     flags => [qw(-quiet)],
                     opts  => {-maxiters => 100} );
    my $MSA   = MSA::Muscle::Factory->new(remote => 0)->getMuscle(@muscleArg);
    my $sCons = scorecons->new(targetSeqIndex => 0);
    $MSA->consScoreCalculator($sCons);
    my @consScores = $MSA->calculateConsScores();

    # Map from resSeq to consScores
    my %chainSeq2resSeq = $chain->map_chainSeq2resSeq();
    return map {$chainSeq2resSeq{$_ + 1} => $consScores[$_]}
        (0 .. @consScores - 1);
}

sub FOSTA {
    my $chain  = shift;
    my $hitMin = shift;

    my $findFFs = FOSTA::Factory->new(remote => 1)->getFOSTA();
    my $pdbsws  = pdb::pdbsws::Factory->new(remote => 1)->getpdbsws;
    
    # Avoid sending pqs codes (e.g. 1afs_1 and instead send the base PDB code)
    my ($pdbCode) = $chain->pdb_code =~ /_/ ? $chain->pdb_code =~ /(.*)_/
        : $chain->pdb_code;
    print "INFO: Getting ac for query chain " . $pdbCode . $chain->chain_id  . " ...\n";
    my @sprot_ac  = $pdbsws->getACsFromPDBCodeAndChainID($pdbCode,
                                                         $chain->chain_id);
    print "INFO: ac = @sprot_ac\n";
    croak "Chain is aligned to multiple swiss prot entries!\n" if @sprot_ac > 1;
    my $sprot_ac = $sprot_ac[0];
    my $FASTAStr = UNIPROT::GetFASTA($sprot_ac, -remote => 1);
    my $sprot_id = UNIPROT::parseIDFromFASTAStr($FASTAStr);
    
    print "INFO: Getting sequence for query, id=$sprot_id ...\n";
    my $spSeq    = sequence->new($FASTAStr);
    
    print "INFO: Getting FEP sequences ...\n";
    # get functionally equivalent protein sequences
    my @FEPseqs = $findFFs->getReliableFEPSequencesFromSwissProtID($sprot_id);
    printf "INFO: %d FEP sequences returned\n", scalar @FEPseqs;

    croak "Num. FEP sequences does not reach minimum!" if @FEPseqs < $hitMin;
    
    print "INFO: Doing FEP sequence alignment ...\n";
    my @muscleArg = (seqs => [$spSeq, @FEPseqs]);
    my $MSA = MSA::Muscle::Factory->new(remote => 0)->getMuscle(@muscleArg);

    print "INFO: Calculating conservation scores for query residues\n";
    $MSA->consScoreCalculator(scorecons->new(targetSeqIndex => 0));
    my @consScores = $MSA->calculateConsScores();
    return mapResSeq2conScore($pdbCode, $chain->chain_id(), $sprot_ac, \@consScores, $pdbsws); 
}

sub mapResSeq2conScore {
    my $pdbCode = shift;
    my $chainID = shift;
    my $sprot_ac       = shift;
    my $consScoresAref = shift;
    my $pdbsws         = shift;
    
    print "INFO: Mapping chain resSeqs to SwissProt numbering ...\n";
    # Get ChainResSeq -> SwissProtNum map
    my %resSeq2SprotNum
        = $pdbsws->mapResSeq2SwissProtNum($pdbCode,
                                          $chainID,
                                          $sprot_ac);
    
    print "INFO: Mapping SwissProt numbering to conservation scores ...\n";
    # Get SwissProtNum -> conservation scores map
    my %sprotNum2consScore = mapSprotNum2conScore(@{$consScoresAref});

    # Combine maps to map ChainResSeq -> scorecons
    my %resSeq2consScore
        = map {$_ => $sprotNum2consScore{$resSeq2SprotNum{$_}}}
            keys %resSeq2SprotNum;

    return %resSeq2consScore;
}

sub mapSprotNum2conScore {
    my @consScores = @_;
    
    # Simple map from consScore index -> consScore
    return map {$_ + 1 => $consScores[$_]} (0 .. @consScores - 1);
}

# TODO: add option of not including maps where residues are not the same
sub mapResSeq2SprotResNum {
    my $chain         = shift;
    my $chainSprotAC  = shift;
    my $pdbswsdbh     = shift;

    my $pdbCode = $chain->pdb_code();
    my $chainID = $chain->chain_id();
    
    #resid is resnum, pdbaa is 1-letter, resnam is 3-letter (both upper case)
    my $sql = "SELECT resid, pdbaa, ac, swsaa, swscount
               FROM alignment
               WHERE pdb = '$pdbCode'
               AND chain = '$chainID';";
    
    my $pdbswssth = $pdbswsdbh->prepare($sql);

    my %resSeq2SprotResNum = ();
    if($pdbswssth->execute){
        while (my ($pdbResSeq, $pdbRes, $sprotAC, $sprotRes, $sprotResNum)
                   = $pdbswssth->fetchrow_array){
            if ($sprotAC eq $chainSprotAC) {
                $resSeq2SprotResNum{$pdbResSeq} = $sprotResNum;
            }
        }
    }
    return %resSeq2SprotResNum;
}

sub getStoredConsScores {
    my ($dir, $chain, $scoreType) = @_;
    croak "scoreType must be 'FOSTA' or 'BLAST'"
        if ! ($scoreType eq 'BLAST' || $scoreType eq 'FOSTA');
    my $chainID = $chain->pdbID();
    my $scoreFile = "$dir/$scoreType/$chainID";
    if (-e $scoreFile) {
        return _readConsScoresFromFile($scoreFile);
    }
    else {
        croak "No attempt to calculate $scoreType scores previously";
    }
}

sub _readConsScoresFromFile {
    my ($scoreFile) = @_;
    open(my $IN, "<", $scoreFile) or die "Cannot open file $scoreFile, $!";
    my %rSeq2consScores = map {chomp $_; split(",", $_);} <$IN>;
    return %rSeq2consScores;
}

sub _saveConsScores {
    my($storedScoresDir, $chain, $scoreType, $scoresHref) = @_;
    my $outFile = "$storedScoresDir/$scoreType/" . $chain->pdbID();
    open(my $OUT, ">", $outFile) or die "Cannot open file $outFile, $!";
    while (my ($rSeq, $consScore) = each %{$scoresHref}) {
        print {$OUT} "$rSeq,$consScore\n";
    }
}

1;

__END__

=head1 NAME

IntPred::lib::calcConservationScores - Perl extension for blah blah blah

=head1 SYNOPSIS

   use IntPred::lib::calcConservationScores;
   blah blah blah

=head1 DESCRIPTION

Stub documentation for IntPred::lib::calcConservationScores, 

Blah blah blah.

=head2 EXPORT

None by default.

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Tom Northey, E<lt>zcbtfo4@acrm18E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Tom Northey

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
