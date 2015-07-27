package DataSet::FindFOSTAFEPs;

use strict;
use warnings;
use DBI;
use sequence;
use Carp;

sub getReliableFEPSequences {
    my $sprot_ac  = shift;
    my $fostadbh  = shift;
    my $pdbswsdbh = shift;
        
    my $sprot_id = eval {getSwissProtIDFromAC($pdbswsdbh, $sprot_ac)};
    croak "No SwissProtID returned for accession code $sprot_ac: $@"
        if ! $sprot_id;
    
    #query FOSTA for all FEPs of that sprot ID
    my @FEPIDs = eval {getFEPIDs($fostadbh, $sprot_id)};
    croak "No FEP IDs returned for SwissProt ID $sprot_id: $@"
        if ! @FEPIDs;
    
    return getSequences($pdbswsdbh, $fostadbh, $sprot_id, @FEPIDs);
}
            
# From a SwissProt id, finds FOSTA family id and family reliability.
# Reliabilility = 1 if reliable, 0 = unreliable.
sub getFOSTAFamIDAndReliability {
    my $fostadbh = shift;
    my $id       = shift;
    
    my $sql3 = "SELECT fd.unreliable, f.fosta_family
                FROM fosta_descriptions fd, feps f
                WHERE fd.id='$id'
                AND f.id='$id'";
    my ($unreliable, $family) = $fostadbh->selectrow_array($sql3);

    # Return reliability rather than unrelability
    my $reliable = $unreliable ? 0 : 1;
    
    return $reliable, $family;
}

# Uses pdbsws to find SwissProt ID that corresponds to passed SwissProt AC
sub getSwissProtIDFromAC {
    my $pdbswsdbh = shift;
    my $sprot_ac  = shift;
    
      my $sql = "SELECT i.id
                   FROM idac i, acac a
                   WHERE a.altac = '$sprot_ac'
                   AND i.ac = a.ac;";
    my $sprot_id = $pdbswsdbh->selectrow_array($sql);
    return $sprot_id;
}
OA
# returns database handle to pdbsws
sub getPDBSWSDBH {
    my $dbname2 = "pdbsws";
    my $dbserver2 = 'acrm8';
    my $datasource2 = "dbi:Pg:dbname=$dbname2;host=$dbserver2";
    my $pdbswsdbh;

    $pdbswsdbh = DBI->connect ($datasource2)
        || die "Cannot connect to $dbname2 database.\n";

    return $pdbswsdbh;
}

# returns database handle to fosta
sub getFOSTADBH {    
    my $dbname3 = "fosta";
    my $dbserver3 = 'acrm8.biochem.ucl.ac.uk';
    my $datasource3 = "dbi:Pg:dbname=$dbname3;host=$dbserver3";
    
    my $fostadbh = DBI->connect ($datasource3)
        || die "Cannot connect to $dbname3 database.\n";

    return $fostadbh;
}


#checks whether entry is unreliable for orthofind and finds functionally equivalent proteins (FEPs) for reliable query proteins
#returns array, first element is query id, others are its FEPs
sub getFEPIDs {
    my $fostadbh = shift;
    my $id       = shift;
    
    my @familyFEPIDs = ();  

    chomp $id;

    my ($reliable, $family) = getFOSTAFamIDAndReliability($fostadbh, $id);

    croak "No family id returned for id $id" if ! $family;
    croak "ID $id is not a reliable query"   if ! $reliable; 
    
    @familyFEPIDs = getFEPIDsFromFamID($fostadbh, $id, $family);
    
    if (! @familyFEPIDs){
        croak "No FEP IDs returned with family id $family, query id $id";
    }    
    
    return @familyFEPIDs;
}

sub getFEPIDsFromFamID {
    my $fostadbh = shift;
    my $id       = shift;
    my $family   = shift;
    
    #ask Lisa is this query OK
    my $sql4 = "SELECT id FROM feps
                WHERE fosta_family = '$family'
                AND id != '$id'
                AND NOT unreliable;";

    my @FEPIDs = ();
    
    my $fostasth = $fostadbh->prepare($sql4);
    if($fostasth->execute){
        while(my ($fep_id) = $fostasth->fetchrow_array){
            push (@FEPIDs, $fep_id);                        
        }
    }
    return @FEPIDs;
}    


#############################################
#for given id, puts acc, id and sequence in %seqs
sub getSequences {
    my $pdbswsdbh = shift;
    my $fostadbh  = shift;
    
    my @seq_ids = @_;
    my @seqs    = ();
    
    foreach my $seq_id (@seq_ids){
        my $seq = eval {getSequenceFromID($fostadbh, $pdbswsdbh, $seq_id)};
        next if ! $seq;
        push(@seqs, $seq);
    }
    return @seqs;
}

sub getACFromID {
    my $pdbswsdbh = shift;
    my $seq_id    = shift;
    
    my $acc_sql = "SELECT a.ac 
                   FROM idac i, acac a
                   WHERE i.id='$seq_id'
                   AND i.ac = a.altac";
    my $acc = $pdbswsdbh -> selectrow_array( $acc_sql );
    return $acc;
}

sub getSequenceFromID {
    my $fostadbh  = shift;
    my $pdbswsdbh = shift;
    my $seq_id    = shift;
    
    my $seqStr = getSequenceStrFromID($fostadbh, $seq_id);
    croak "No sequence string found for id $seq_id" if ! $seqStr;
    
    my $accessionCode  = getACFromID($pdbswsdbh, $seq_id);
    croak "No accession code found for id $seq_id" if ! $accessionCode;
    
    return sequence->new(string => $seqStr,
                         id => "$accessionCode|$seq_id")
}

sub getSequenceStrFromID {
    my $fostadbh = shift;
    my $seq_id   = shift;
    
    my $seq_sql = "SELECT sequence
                   FROM fosta_sequences
                   WHERE id='$seq_id'";
    my $seq = $fostadbh -> selectrow_array($seq_sql);
    return $seq;
}

1;
