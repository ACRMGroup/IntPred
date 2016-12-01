#!/usr/bin/env perl
use strict;
use warnings;
use lib ('..');
use Test::Class::Moose::Load qw(TestsFor);
use Test::Class::Moose::Runner;
use Getopt::Long;
my $numJobs = 1;
my $includeRE;

GetOptions("j=i", \$numJobs,
           "i=s", \$includeRE);
my %arg = (test_classes => \@ARGV);
$arg{jobs} = $numJobs if defined $numJobs && $numJobs > 1;
$arg{include} = qr/$includeRE/ if defined $includeRE;

Test::Class::Moose::Runner->new(%arg)->runtests();
