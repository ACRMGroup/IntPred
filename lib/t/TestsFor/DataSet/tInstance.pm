package TestsFor::DataSet::Instance;
use Test::Class::Moose;
use DataSet::Instance;

sub supplyClass {
    return 'DataSet::Instance';
}

has 'patchDummy' => (
    isa => 'patch',
    is  => 'ro',
    default => sub { bless {}, 'patch' }, 
);

has 'class' => (
    isa => 'Str',
    is  => 'ro',
    lazy => 1,
    builder => 'supplyClass'
);

sub constructorArgs {
    my $test = shift;
    return (patch => $test->patchDummy);
}

sub test_constructor {
    my $test = shift;

    can_ok $test->class, 'new';
    isa_ok my $classInstance = $test->class->new($test->constructorArgs()),
        $test->class;
}

package TestsFor::DataSet::Instance::Model;
use Test::Class::Moose;
use ARFF;
use Carp;

extends 'TestsFor::DataSet::Instance';

sub supplyClass {
    return 'DataSet::Instance::Model';
}

has 'arff' => (
    is => 'ro',
    isa => 'ARFF',
    default => sub {ARFF::FileParser->new(file => "test.arff")->parse()},
);

sub test_setExpectedFeatures {
    my $test = shift;
    my $model = $test->class->new($test->constructorArgs());

    ok(! $model->listSetFeatures(),
       "Model has no features when initialized");
    
    $model->setExpectedFeatures();

    cmp_deeply([$model->listSetFeatures], [$model->listFeatures],
       "setExpectedFeatures should then initialize all features");
}

sub test_setExpectedFeaturesSubset {
    my $test = shift;
    my $model = $test->class->new($test->constructorArgs());

    my @featureSubset = qw(pho Hb class);
    $model->setExpectedFeatures(@featureSubset);

    cmp_deeply([$model->listSetFeatures], \@featureSubset,
           "setExpectedFeatures initializes the features passed to it")
}

sub test_constructModelFromArff {
    my $test = shift;
    isa_ok my $tModel = $test->class->new($test->arff()),
        $test->class();

    my @expectedFeatures = qw(id pro pho pln SS Hb fosta class);
    my @gotFeatures      = $tModel->listSetFeatures();
    cmp_bag(\@gotFeatures, \@expectedFeatures,
               "model has expected set features");
}

sub test_instancesFromArff {
    my $test   = shift;
    my $tModel = $test->class->new($test->arff());
    
    my @instances = $tModel->instancesFromArff($test->arff);
    is(scalar @instances, 4, "all instances mapped from arff");

    my $tInst = $instances[0];
    
    cmp_deeply({$tInst->getValueForFeatureHash()},
               _expValueForFeatureHref(),
               "first instance has correct features and values");
}
        
sub _expValueForFeatureHref {
    return {id    => '1a2y:C:100',
            pro   => '-0.197333',
            pho   => '-0.814082',
            pln   => '-0.590363',
            SS    => '-0.347633',
            Hb    => '1.359971',
            fosta => '-0.21583',
            class => 'I',
        };
}

1;
