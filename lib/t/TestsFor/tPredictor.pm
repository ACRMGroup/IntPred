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

    $tPredictor->runPredictor();
    lives_ok(sub {$tPredictor->assignPredictionScoresToTestSet()},
       "assignPredictionScoresToTestSet ran");
    
    cmp_deeply($tPredictor->testSet->instancesAref,
               array_each(methods(has_predScore => 1)),
               "All test set instances now have a predScore");

    cmp_deeply([map {$_->predScore} @{$tPredictor->testSet->instancesAref}],
               _getExpectedPredScores(),
               "And predScores match expected");
}

sub test_trainPredictor {
    my $test       = shift;
    my $tPredictor = $test->class->new(constructorArgs());
    _remove_test_trainPredictor_modelFile();
    $tPredictor->randomForest(WEKA::randomForest->new(model => _get_test_trainPredictor_modelFile()));
    ok($tPredictor->trainPredictor(), "trainPredictor runs ok");
    ok($tPredictor->runPredictor(), 
       "runPredictor can be run on trained predictor");
    _remove_test_trainPredictor_modelFile();
}

sub _remove_test_trainPredictor_modelFile {
    my $modelFile = _get_test_trainPredictor_modelFile();
    unlink($modelFile) if -e $modelFile;
}

sub _get_test_trainPredictor_modelFile {
    return ("testWEKAModels/test_trainPredictor.model");
}
   
sub _getTestDataSet {
    return DataSet->new(ARFF::FileParser->new(file => "testPredictor.arff")->parse());
}

sub _getTrainDataSet {
    return DataSet->new(ARFF::FileParser->new(file => "training_set.arff")->parse());
}

sub _getRandomForest {
    return WEKA::randomForest->new(model => "testWEKAModels/testPredictor.model");
}

sub _getExpectedPredScores {
    return [qw(0.42 0.26 0.47 0.447 0.465 0.48 0.48 0.471 0.48 0.49)];
}

1;
