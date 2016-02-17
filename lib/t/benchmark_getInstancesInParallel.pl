#!/usr/bin/env perl
use strict;
use warnings;
use lib ('..');
use DataSet::Creator;
use DataSet::Input;
use DataSet::Instance;
use IO::CaptureOutput qw(capture);
use Benchmark qw(:all);

timethese(1,
          {"woParallel" => '&withoutParallel',
           "wParallel"  => '&withParallel'}
      );


sub withParallel {
    my $creator = getCreator();
    $creator->parallel(1);
    runGetInstances($creator);
}

sub withoutParallel {
    my $creator = getCreator();
    $creator->parallel(0);
    runGetInstances($creator);
}

sub runGetInstances {
    my $creator = shift;
    my ($stdout, $stderr);
    capture{$creator->getInstances()} \$stdout, \$stderr;
    print $stderr if $stderr;
}

sub getCreator {
    return DataSet::Creator::Master->new(childInput => [getInputs()],
                                         model => getModel());
}

sub getInputs {
    my @pdbs = qw(1ors 1tpx 2wap 1bzq);
    print "Input = " . @pdbs . " pdb files\n";
    return map {
        DataSet::Input->new(inputFile => "pdb$_.ent", pdbCode => $_,
                            complexChainIDs => [ [ ['A'], ['B'] ] ] ) }
        @pdbs;
}

sub getModel {
    my $model = DataSet::Instance::Model->new(); 
    $model->setExpectedFeatures(qw(id pho pln SS Hb));
    return $model;
}
