package Predictor;
use Moose;
use DataSet;
use WEKA;
use Carp;

has 'trainingSet' => (
    is => 'rw',
    isa => 'DataSet',
);

has 'testSet' => (
    is => 'rw',
    isa => 'DataSet',
);

has 'randomForest' => (
    is => 'rw',
    isa => 'WEKA::randomForest',
    default => sub {WEKA::randomForest->new()},
    lazy => 1,
);

has 'predictionCSVStr' => (
    is => 'rw',
    isa => 'Str',
    builder => '_buildPredictionCSV',
    lazy => 1
);

sub trainPredictor {
    my $self = shift;

    croak "Not yet implemented!\n";
}

sub _buildPredictionCSV {
    my $self = shift;
    $self->_prepareForTesting();
    my $outputCSV = $self->randomForest->test();
    return $outputCSV;
}

sub getPredictionScoresForTestSet {
    my $self = shift;
    $self->testSet->mapWEKAOutput($self->predictionCSVStr());
}

sub _prepareForTesting {
    my $self = shift;
    
    $self->_prepareDataSets();
    $self->randomForest->testArff($self->testSet->arff);    
}

sub _prepareDataSets {
    my $self = shift;
    
    $self->trainingSet->makeArffCompatible();
    $self->testSet->makeArffCompatible();
    $self->testSet->standardizeArffUsingRefArff($self->trainingSet->arff);
}

1;
