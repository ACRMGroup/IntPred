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

sub BLAST {
    my $chain  = shift;
    my $eval   = shift;
    my $hitMin = shift;
    my $hitMax = shift;

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
        my $hitSeq = eval {$blaster->reportHandler->swissProtSeqFromHit($hit)};
        print "Failed to get sequence for hit $hit, $@" && next
            if ! $hitSeq;
        
        push(@hitSeqs, $hitSeq);
        ++$hitCount;
        last if $hitCount == $hitMax;
    }

    print scalar @hitSeqs, " hit seqs obtained\n";

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
   
    my @scorecons = $MSA->calculateConsScores();
    
    my %chainSeq2resSeq = $chain->map_chainSeq2resSeq();
    # Map from resSeq to scorecons
    return map {$chainSeq2resSeq{$_ + 1} => $scorecons[$_]}
        (0 .. @scorecons - 1);
}

sub FOSTA {
    my $chain  = shift;
    my $hitMin = shift;

    my $findFFs = FOSTA::Factory->new(remote => 1)->getFOSTA();
    my $pdbsws  = pdb::pdbsws::Factory->new(remote => 1)->getpdbsws;
    
    print "Getting ac for query chain ...\n";
    # get SwissProt AC for chain
    my @sprot_ac  = $pdbsws->getACsFromPDBCodeAndChainID($chain->pdb_code,
                                                         $chain->chain_id);
    croak "Chain is aligned to multiple swiss prot entries!\n" if @sprot_ac > 1;
    my $sprot_ac = $sprot_ac[0];
    my $FASTAStr = UNIPROT::GetFASTA($sprot_ac, -remote => 1);
    my $sprot_id = UNIPROT::parseIDFromFASTAStr($FASTAStr);
    
    print "Getting query SwissProt sequence...\n";
    my $spSeq    = sequence->new($FASTAStr);
    
    print "Getting FEP sequences ...\n";
    # get functionally equivalent protein sequences
    my @FEPseqs = $findFFs->getReliableFEPSequencesFromSwissProtID($sprot_id);
    print scalar @FEPseqs . " FEP sequences returned\n";

    croak "Num. FEP sequences does not reach minimum!" if @FEPseqs < $hitMin;
    
    print "Doing FEP sequence alignment ...\n";
    my @muscleArg = (seqs => [$spSeq, @FEPseqs]);
    my $MSA = MSA::Muscle::Factory->new(remote => 0)->getMuscle(@muscleArg);

    print "Calculating conservation scores for query residues\n";
    $MSA->consScoreCalculator(scorecons->new(targetSeqIndex => 0));
    my @consScores = $MSA->calculateConsScores();

    return mapResSeq2conScore($chain, $sprot_ac, \@consScores, $pdbsws); 
}

sub mapResSeq2conScore {
    my $chain          = shift;
    my $sprot_ac       = shift;
    my $consScoresAref = shift;
    my $pdbsws         = shift;
    
    print "Mapping chain resSeqs to SwissProt numbering ...\n";
    # Get ChainResSeq -> SwissProtNum map
    my %resSeq2SprotNum
        = $pdbsws->mapResSeq2SwissProtNum($chain->pdb_code,
                                         $chain->chain_id,
                                         $sprot_ac);
    
    print "Mapping SwissProt numbering to conservation scores ...\n";
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
