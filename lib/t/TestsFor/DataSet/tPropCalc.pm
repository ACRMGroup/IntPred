package TestsFor::DataSet::PropCalc;
use Test::Class::Moose;
use DataSet::PropCalc;
use TCNUtil::types;

has 'class'        => (is => 'ro', isa => 'Str',
                       default => sub {'DataSet::PropCalc'});
has 'testSurfFile' => (is => 'ro', isa => 'FileReadable',
                       default => sub {'nonepi.stats'});
has 'testIntfFile' => (is => 'ro', isa => 'FileReadable',
                       default => sub {'epi.stats'});

sub constructorArgs {
    my $test = shift;
    return (surfStatFile => $test->testSurfFile,
            intfStatFile => $test->testIntfFile);
}

sub test_constructor {
    my $test = shift;

    isa_ok($test->class->new(), $test->class());
}

sub test_typeHrefs {
    my $test      = shift;
    my $tPropCalc = $test->class->new($test->constructorArgs());

    isa_ok($tPropCalc->intfHref, 'HASH', "intfHref");
    isa_ok($tPropCalc->surfHref, 'HASH', "surfHref");
}

sub test_surfMean {
    my $test = shift;
    my $tPropCalc = $test->class->new($test->constructorArgs());

    isa_ok($tPropCalc->surfMeanHref, 'HASH', "surfMean")
}

sub test_lnPartHref {
    my $test = shift;
    my $tPropCalc = $test->class->new($test->constructorArgs());

    isa_ok($tPropCalc->lnPartHref, 'HASH', "lnPartHref");
}

sub test_getResidueScore {
    my $test = shift;
    my $tPropCalc = $test->class->new($test->constructorArgs());

    is($tPropCalc->getResidueScore('ASP', 10), -0.00178734954708363,
       "getResidueScore ok");
}

1;
