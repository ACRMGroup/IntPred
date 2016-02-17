package TestsFor::DataSet::Input;
use Test::Class::Moose;
use DataSet::Input;
use DataSet::Creator;
use DataSet::Instance;

has 'class' => (
   isa => 'Str',
   is  => 'ro',
   default => 'DataSet::Input',
);

sub constructorArgs {
    return (inputFile => 'pdb2wap.ent', pdbCode => '2wap',
            complexChainIDs => [ [['A'], ['B']] ]);
}

sub test_constructor {
    my $test = shift;
    can_ok $test->class, 'new';
    isa_ok my $classInstance = $test->class->new($test->constructorArgs()),
        $test->class;
}

sub test_from_pqs_line {
    my $test = shift;
    my $line = "1ndm : A,B";
    isa_ok my $classInstance = $test->class->new($line, "pqs"), $test->class;
    $classInstance->pdbGetFile->pqsdir("."); # Allows test pqs file to be found
    my $tCreator
        = DataSet::Creator::Master->new(model => _getInstanceModel(),
                                        inputs => [$classInstance]);
    ok($tCreator->nextInstance(),
       "creator with pqs input type can return instance ok");
}

sub _getInstanceModel {
    my $pSummaries = {"1ndmA" => ["<patch A.127> A:119"]};
    return DataSet::Instance::Model->new(pSummaries => $pSummaries);
}

1;
