package Predictor;
use Moose;
use DataSet;
use WEKAOutputParser;
use TCNUtil::WEKA;
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

has 'outputParser' => (
    is => 'rw',
    isa => 'WEKAOutputParser',
    lazy => 1,
    default => sub {WEKAOutputParser->new()},
);

sub trainPredictor {
    my $self = shift;
    croak "Not yet implemented!\n";
}

sub runPredictor {
    my $self = shift;
    $self->_prepareForTesting();
    print "Running random forest ... ";
    my $outputCSV = $self->randomForest->test();
    print "done\n";
    $self->outputParser->input($outputCSV);
}

sub assignPredictionScoresToTestSet {
    my $self = shift;
    $self->testSet->mapWEKAOutput($self->outputParser);
}

sub _prepareForTesting {
    my $self = shift;
    print "Preparing data sets for testing ...\n";
    $self->_prepareDataSets();
    $self->randomForest->testArff($self->testSet->arff);    
}

sub _prepareDataSets {
    my $self = shift;
    $self->trainingSet->makeArffCompatible();
    $self->testSet->makeArffCompatible();
    print "Standardizing test set ... ";
    $self->testSet->standardizeArffUsingRefArff($self->trainingSet->arff);
    print "done\n";
}

1;
