#!/usr/bin/env perl
use lib ('..');
use Test::Class::Moose::Load qw(TestsFor);
use Test::Class::Moose::Runner;
use Getopt::Long;
my $numJobs = 1;
GetOptions("j=i", \$numJobs);
Test::Class::Moose::Runner->new(test_classes => \@ARGV, jobs => $numJobs)->runtests();
