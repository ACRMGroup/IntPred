package TestsFor::ConfigReader;
use Test::Class::Moose;
use ConfigReader;
use DataSet::Instance;
use Carp;

sub dSetCreatorConfigFile {
    return "configFiles/testDataSetCreator.ini";
}

sub loadDataSetConfigFile {
    return "configFiles/loadDataSetConf.ini";
}

sub getPredictorConfigFile {
    return "configFiles/predictorConfigFile.ini";
}

has 'class' => (default => 'ConfigReader', isa => 'Str', is => 'ro', lazy => 1);
    
sub test_constructor {
    my $test = shift;
    can_ok $test->class, 'new';
    isa_ok my $classInstance = $test->class->new(dSetCreatorConfigFile()),
        $test->class;
}

sub test_getDataSet {
    my $self = shift;
    my $cReader = ConfigReader->new(loadDataSetConfigFile());

    my $trainSet = $cReader->getTrainingSet();
    isa_ok($trainSet, 'DataSet', "getTrainingSet returns a DataSet");
    my $testSet  = $cReader->getTestSet();
    isa_ok($testSet,  'DataSet', "getTrainingSet returns a DataSet");
}

sub test_getPredictor {
    my $self = shift;
    my $cReader = ConfigReader->new(getPredictorConfigFile());

    my $predictor = $cReader->getPredictor();
    isa_ok($predictor, 'Predictor', "getPredictor returns a Predictor");
}

sub test_createDataSetCreator {
    my $test = shift;

    my $tConfigReader   = $test->class->new(dSetCreatorConfigFile());
    my $tDataSetCreator = $tConfigReader->createDataSetCreator();  
    isa_ok($tDataSetCreator, 'DataSet::Creator::Master',
           'createDataSetCreator returns a DataSet::Creator::Master');

    my $tDataSet = $tDataSetCreator->getDataSet();
    isa_ok($tDataSetCreator, 'DataSet::Creator::Master',
           'and this DataSet::Creator can return a DataSet');
}

1;
