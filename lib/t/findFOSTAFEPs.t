#!/usr/bin/env perl
# 
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl findFOSTAFEPs.t'

# Test file created outside of h2xs framework.
# Run this like so: `perl findFOSTAFEPs.t'
#   Tom Northey <zcbtfo4@acrm18>     2015/04/24 12:10:32

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use strict;
use warnings;
use lib ('..');
use Test::More qw( no_plan );
use Test::Deep;
BEGIN { use_ok( 'DataSet::FindFOSTAFEPs' ); }

#########################

# Insert your test code below, the Test::More module is used here so read
# its man page ( perldoc Test::More ) for help writing this test script.

subtest "test database handles" => sub {
    my $testObj = DataSet::FindFOSTAFEPs->new();
    is(ref $testObj->PDBSWSDBH, "DBI::db", "PDBSWSDH is a database handle");
    
    is(ref $testObj->FOSTADBH,  "DBI::db", "FOSTADBH is a database handle");
};

subtest "test getSwissProtIDFromAC" => sub {
    my $testObj = DataSet::FindFOSTAFEPs->new();
    my $testAC = "P12345";
    my $expID  = "AATM_RABIT";
    is($testObj->getSwissProtIDFromAC($testAC), $expID,
       "getSwissProtIDFromAC returns correct id");
};

subtest "test getFOSTAFamIDAndReliability" => sub {
    my $testObj = DataSet::FindFOSTAFEPs->new();
    my $testReliableID = "CNTD1_HUMAN";
    cmp_deeply([$testObj->getFOSTAFamIDAndReliability($testReliableID)], [1, 13],
               "getFOSTAFamIDAndReliability returns reliable family id");
    
    my $testUnRelID = "CF211_XENTR";
    cmp_deeply([$testObj->getFOSTAFamIDAndReliability($testUnRelID)], [0, 18591],
               "getFOSTAFamIDAndReliability returns unreliable family id");
};

subtest "test getFEPIDsFromFamID" => sub {
    my $testObj = DataSet::FindFOSTAFEPs->new();
    my $famID = "CNTD1_HUMAN";
    cmp_deeply([$testObj->getFEPIDsFromFamID($famID, 13)], ["CNTD1_MOUSE"],
               "getFEPIDsFromFamID returns correct FEPIDs");
};

subtest "test getSequenceFromID" => sub {
    my $testObj = DataSet::FindFOSTAFEPs->new();
    my $famID = "CNTD1_HUMAN";
    my $gotSeq  = $testObj->getSequenceFromID($famID);
    is($gotSeq->string(), expSeqStr(), "getSequenceFromID retuns sequence ok");
};

subtest "test getACFromID" => sub {
    my $testObj = DataSet::FindFOSTAFEPs->new();
    my $famID = "CNTD1_HUMAN";
    my $expAC = "Q8N815";
    is($testObj->getACFromID($famID), $expAC,
       "getACFromID returns correct AC");
};

subtest "test getSequences" => sub {
    my $testObj = DataSet::FindFOSTAFEPs->new();
    my $famID = "CNTD1_HUMAN";    
    cmp_deeply([$testObj->getSequences($famID)],
               array_each(isa("sequence")), "getSequences returns sequence objects");
};

sub expSeqStr {
    my $seq = <<EOF;
MDGPMRPRSASLVDFQFGVVATETIEDALLHLAQQNEQAVREASGRLGRFREPQIVEFVFLLSEQWCLEKSVSYQAVEIL
ERFMVKQAENICRQATIQPRDNKRESQNWRALKQQLVNKFTLRLVSCVQLASKLSFRNKIISNITVLNFLQALGYLHTKE
ELLESELDVLKSLNFRINLPTPLAYVETLLEVLGYNGCLVPAMRLHATCLTLLDLVYLLHEPIYESLLRASIENSTPSQL
QGEKFTSVKEDFMLLAVGIIAASAFIQNHECWSQVVGHLQSITGIALASIAEFSYAILTHGVGANTPGRQQSIPPHLAAR
ALKTVASSNT
EOF

    $seq =~ s/\s//gxms;
    return $seq;
}
