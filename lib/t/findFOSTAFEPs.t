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

my $testPdbSwsDbh = DataSet::FindFOSTAFEPs::getPDBSWSDBH();
is(ref $testPdbSwsDbh, "DBI::db", "getPDBSWSDH returns databse handle");

my $testFostaDbh = DataSet::FindFOSTAFEPs::getFOSTADBH();
is(ref $testFostaDbh, "DBI::db", "getFOSTADBH returns database handle");

my $testAC = "P12345";
my $expID  = "AATM_RABIT";
is(DataSet::FindFOSTAFEPs::getSwissProtIDFromAC($testPdbSwsDbh, $testAC), $expID,
   "getSwissProtIDFromAC returns correct id");

my $testReliableID = "CNTD1_HUMAN";
cmp_deeply([DataSet::FindFOSTAFEPs::getFOSTAFamIDAndReliability($testFostaDbh,
                                                       $testReliableID)],
           [1, 13], "getFOSTAFamIDAndReliability returns reliable family id");

my $testUnRelID = "CF211_XENTR";
cmp_deeply([DataSet::FindFOSTAFEPs::getFOSTAFamIDAndReliability($testFostaDbh,
                                                       $testUnRelID)],
           [0, 18591], "getFOSTAFamIDAndReliability returns unreliable family id");

cmp_deeply([DataSet::FindFOSTAFEPs::getFEPIDsFromFamID($testFostaDbh,
                                              $testReliableID, 13)],
           ["CNTD1_MOUSE"], "getFEPIDsFromFamID returns correct FEPIDs");

my $gotSeq = DataSet::FindFOSTAFEPs::getSequenceFromID($testFostaDbh,
                                                       $testPdbSwsDbh,
                                                       $testReliableID);
is($gotSeq->string(), expSeqStr(), "getSequenceFromID retuns sequence ok");

my $expAC = "Q8N815";
is(DataSet::FindFOSTAFEPs::getACFromID($testPdbSwsDbh, $testReliableID), $expAC,
   "getACFromID returns correct AC");

cmp_deeply([DataSet::FindFOSTAFEPs::getSequences($testPdbSwsDbh, $testFostaDbh,
                                        $testReliableID)],
           array_each(isa("sequence")), "getSequences returns sequence objects");

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
