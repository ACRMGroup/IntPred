package TestsFor::DataSet::Input;
use Test::Class::Moose;
use DataSet::Input;

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

1;
