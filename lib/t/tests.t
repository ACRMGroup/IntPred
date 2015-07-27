#!/usr/bin/env perl
use lib ('..');
use Test::Class::Moose::Load qw(TestsFor);
use Test::Class::Moose::Runner;
Test::Class::Moose::Runner->new(test_classes => \@ARGV, jobs => 1)->runtests();
