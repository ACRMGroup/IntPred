#!/usr/bin/env perl
# 
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl calcBlastConservationScores.t'

# Test file created outside of h2xs framework.
# Run this like so: `perl calcBlastConservationScores.t'
#   Tom Northey <zcbtfo4@acrm18>     2015/04/26 17:43:01

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use lib ('..');
use Test::More qw( no_plan );
use Test::Exception;

BEGIN { use_ok( 'DataSet::CalcConservationScores' ); }

#########################

# Insert your test code below, the Test::More module is used here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $eval   = 1;
my $hitMin = 5;
my $hitMax = 10;

lives_ok {DataSet::CalcConservationScores::getBLASTScoresForChain(getTestChain(), "", $eval, $hitMin, $hitMax)}
    "BLAST";

lives_ok {DataSet::CalcConservationScores::getFOSTAScoresForChain(getTestChain(), "", $hitMin)}
    "FOSTA";

lives_ok {DataSet::CalcConservationScores::getBLASTScoresForChain(getTestChain(), "testConsScores", $eval, $hitMin, $hitMax)}
    "BLAST from saved consScores";

lives_ok {DataSet::CalcConservationScores::getFOSTAScoresForChain(getTestChain(), "testConsScores", $hitMin)}
    "FOSTA from saved consScores";

sub getTestChain {
    return chain->new(pdb_code => '1bzq', chain_id => 'A',
                      pdb_file => 'pdb1bzq.ent');
}
