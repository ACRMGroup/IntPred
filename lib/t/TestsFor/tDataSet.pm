package TestsFor::DataSet;
use Test::Class::Moose;
use DataSet;
use DataSet::Instance;
use ARFF;

has 'class' => (default => 'DataSet', isa => 'Str', is => 'ro', lazy => 1);

sub constructorArgs {
    my $test = shift;

    return (instancesAref => [DataSet::Instance->new()],
            instanceModel =>  DataSet::Instance::Model->new());
}
    
sub test_constructor {
    my $test = shift;

    can_ok $test->class, 'new';
    isa_ok my $classInstance = $test->class->new($test->constructorArgs()),
        $test->class;
}

sub test_arffCompatibilization {
    my $test     = shift;
    my $tDataSet =  _getDataSetForTestingArffCompatibilization();
    
    $tDataSet->makeArffCompatible();
    
    my @expAttrNameAndType = _expAttrNameAndType();
    my @gotAttrNameAndType
        = map {$_->name(), $_->type()}
            $tDataSet->arff->getAttributeDescriptions();
    
    cmp_deeply(\@gotAttrNameAndType, \@expAttrNameAndType,
       "dataSet->arff has expected attributes after makeArffCompatible");
}

sub _expAttrNameAndType {
    return (qw(patchID          string
               propensity       numeric
               hydrophobicity   numeric
               planarity        numeric
               secondary_str=H  numeric
               secondary_str=EH numeric
               secondary_str=E  numeric
               secondary_str=C  numeric
               SSbonds          numeric
               Hbonds           numeric
               fosta_scorecons  numeric
               blast_scorecons  numeric),
            ('intf_class',   '{I,S}')); # Warning is thrown if comma in qw list
}

sub _getDataSetForTestingArffCompatibilization {
    my $testArff = ARFF::FileParser->new(file => "testDataSet.arff")->parse();
    return DataSet->new($testArff);
}

sub _getArffToStandardizeAgainst {
    return ARFF::FileParser->new(file => "train2StandAgainst.arff")->parse();
}

1;
