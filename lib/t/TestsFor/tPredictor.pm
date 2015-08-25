package TestsFor::Predictor;
use Test::Class::Moose;
use Predictor;
use TCNUtil::ARFF::FileParser;

use DataSet;

has 'class' => (default => 'Predictor', isa => 'Str', is => 'ro', lazy => 1);

sub constructorArgs {
    my $test = shift;
    return (trainingSet => _getTrainDataSet(), testSet => _getTestDataSet(),
            randomForest => _getRandomForest());
}
    
sub test_constructor {
    my $test = shift;
    can_ok $test->class, 'new';
    isa_ok my $classInstance = $test->class->new($test->constructorArgs()),
        $test->class;
}

sub test_getPredictionScoresForTestSet {
    my $test       = shift;
    my $tPredictor = $test->class->new(constructorArgs());
    
    lives_ok(sub {$tPredictor->getPredictionScoresForTestSet()},
       "getPredictionScoresForTestSet ran");
    
    cmp_deeply($tPredictor->testSet->instancesAref,
               array_each(methods(has_predScore => 1)),
               "All test set instances now have a predScore");

    cmp_deeply([map {$_->predScore} @{$tPredictor->testSet->instancesAref}],
               _getExpectedPredScores(),
               "And predScores match expected");
}

sub _getTestDataSet {
    return DataSet->new(ARFF::FileParser->new(file => "testPredictor.arff")->parse());
}

sub _getTrainDataSet {
    return DataSet->new(ARFF::FileParser->new(file => "train2StandAgainst.arff")->parse());
}

sub _getRandomForest {
    return WEKA::randomForest->new(model => "testWEKAModels/testPredictor.model");
}

sub _getExpectedPredScores {
    return [qw(0.369 0.303 0.407 0.345 0.417 0.458 0.447 0.414 0.393 0.41)];
}

1;
