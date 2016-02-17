package CreatorTester;
use Moose::Role;
use Test::More;
use pdb;

has 'class' => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    builder => 'supplyClass'
);

has 'pdbCode' => (is => 'ro', isa => 'Str', default => sub {'2wap'}, lazy => 1);
has 'chainID' => (is => 'ro', isa => 'Str', default => sub {'A'},    lazy => 1);

has 'chain' => (
    isa => 'chain',
    is  => 'ro',
    lazy => 1,
    builder => 'buildChain',
);

sub buildChain {
    my $self = shift;
    return chain->new(pdb_file => 'pdb2wap.ent', pdb_code => $self->pdbCode,
                      chain_id => $self->chainID,);
}

has 'pSummaries' => (isa => 'HashRef', is => 'ro', lazy => 1,
                     builder => 'buildpSummaries');

sub buildpSummaries {
    my $self = shift;
    my $pdbID = $self->pdbCode . $self->chainID;
    my $pSummaries = {$pdbID => ["<patch A.103> A:101 A:102 A:103"]};
}

has 'patch' => (
    isa => 'patch',
    is  => 'ro',
    lazy => 1,
    builder => 'buildTestPatch'
);

sub buildTestPatch {
    my $self = shift;
    
    return patch->new(summary => "<patch A.103> A:101 A:102 A:103",
                      parent_pdb => $self->chain);
}

sub test_child {
    my $test = shift;
    my $testObj = $test->class->new($test->constructorArgs());

    isa_ok($testObj->nextChild, $testObj->childClass,
           $test->class . "->nextChild returns a " . $testObj->childClass);

    is($testObj->nextChild, 0,
       "and then returns 0 when there are no children left.");
}

sub test_nextInstance {
    my $test      = shift;
    my $testObj   = $test->class->new($test->constructorArgs());
    
    isa_ok($testObj->nextInstance, 'DataSet::Instance',
           $test->class . "->nextInstance returns a instance");

    is($testObj->nextInstance, 0,
       "and then returns 0 when there are no instances left.");
}

package TestsFor::DataSet::Creator::Patch;
use Test::Class::Moose;
with 'CreatorTester';

use DataSet::Creator;

sub constructorArgs {
    my $test = shift;
    return (patch => $test->patch, model => DataSet::Instance::Model->new());
}

sub supplyClass {
    return 'DataSet::Creator::Patch'
}

sub test_features {
    my $test = shift;
    my $pProc = $test->class->new($test->constructorArgs());
    $pProc->model->setExpectedFeatures(qw(id pho pln SS Hb));

    my $inst = $pProc->nextInstance();

    is($inst->id, "2wap:A:103", "Patch ID added to instance");
    is(sprintf("%.3f", $inst->pho), -0.167, "Patch hydropho added to instance");
    is(sprintf("%.3f", $inst->pln),  0.923, "Patch planarity added to instance");
    is($inst->SS, 0, "Patch SS bonds added to instance");
    is($inst->Hb, 0, "Patch Hb bonds added to instance");
}

package TestsFor::DataSet::Creator::Chain;
use Test::Class::Moose;

with 'CreatorTester';

use DataSet::Creator;

sub supplyClass {
    return 'DataSet::Creator::Chain';
}

sub propCalcConstructorArgs {
    return (intfStatFile => 'epi.stats', surfStatFile => 'nonepi.stats');
}

sub constructorArgs {
    my $test = shift;

    my $pCalc = DataSet::PropCalc->new(propCalcConstructorArgs());
    
    return (chain => $test->chain,
            model => DataSet::Instance::Model->new(propCalc => $pCalc,
                                                   pSummaries => $test->pSummaries));
}

sub noFOSTAConstructorArgs {
    my $test = shift;

    my $chain      = chain->new(pdb_file => 'pdb1a14.ent', chain_id => 'N');
    my $pSummaries = {'1a14N' => ["<patch N.234> N:82 N:83 N:84 N:85 N:86"]};

    return (chain => $chain,
            model => DataSet::Instance::Model->new(fosta => 0,
                                                   pSummaries => $pSummaries));
}

sub noBLASTConstructorArgs {
    my $test = shift;

    my $chain      = chain->new(pdb_file => 'pdb1ors.ent', chain_id => 'C');
    my $pSummaries = {'1orsC' => ["<patch C.89> C:72 C:73 C:76"]};

    return (chain => $chain,
            model => DataSet::Instance::Model->new(blast => 0,
                                                   pSummaries => $pSummaries));
}

sub test_missingValues {
    my $test   = shift;
    my $chProc = $test->class->new($test->noFOSTAConstructorArgs());

    my $inst = $chProc->nextInstance();
    is($inst->fosta, '?', "missing fosta value ok");

    $chProc = $test->class->new($test->noBLASTConstructorArgs);
    $inst = $chProc->nextInstance();
    is($inst->blast, '?', "missing blast value ok");
}

sub test_resID2conScoreBuilds {
    my $test = shift;
    my $chProc = $test->class->new($test->constructorArgs());

    # First check that builders that run calcConservationScores run ok
    $chProc->model->FOSTAHitMin(4);
    $chProc->resID2FOSTAScore();
    ok(! $chProc->FOSTAErr(), "resID2FOSTAScore build ok")
        or diag explain $chProc->FOSTAErr();

    $chProc->model->BLASTHitMax(10); # Make hitMax small to speed up testing
    $chProc->resID2BLASTScore();
    ok(! $chProc->BLASTErr(), "resID2BLASTScore build ok")
        or diag explain $chProc->BLASTErr();
    
    # Then check that conservation scores are properly assigned to instance
    $chProc->model->setExpectedFeatures("blast", "fosta");
    _setConScoreMaps($chProc);
    my $inst = $chProc->nextInstance();

    is(sprintf($inst->blast()), 1, "blast feature added ok");
    is(sprintf($inst->fosta()), 1, "fosta feature added ok");
}

sub _setConScoreMaps {
    my $chProc = shift;
    foreach my $consScore (qw(FOSTAScore BLASTScore)) {
        my $map = "resID2$consScore";
        $chProc->$map({'A.101' => 1, 'A.102' => 1, 'A.103' => 1});
    }
}

sub test_features {
    my $test = shift;
    my $chProc = $test->class->new($test->constructorArgs());
    $chProc->model->setExpectedFeatures(qw(secStruct pro));
    my $inst = $chProc->nextInstance();
    
    is($inst->secStruct, "H", "secStruct added to instance");

    my $expPro = 0.0615;
    ok($inst->pro() - $expPro < 0.0001, "propensity feature added ok");
}

package TestsFor::DataSet::Creator::Complex;
use Test::Class::Moose;
with 'CreatorTester';

use DataSet::Creator;

sub supplyClass {
    return 'DataSet::Creator::Complex';
}

has 'complexChain' => (
    isa => 'chain',
    is => 'ro',
    lazy => 1,
    builder => 'buildComplexChain',
);

# Complex chain is required to test interfaceResidue builder
sub buildComplexChain {
    my $self  = shift;
    my $chain = $self->buildChain();
    $chain->chain_id('B');
    return $chain;
}
    
sub constructorArgs {
    my $test = shift;
    return (targetChains  => [$test->chain],
            complexChains => [$test->complexChain],
            model => DataSet::Instance::Model->new(pSummaries => $test->pSummaries));
}

# This tests interfaceResidues builder, getInterfaceResidues
sub test_interfaceResidues {
    my $test = shift;
    my $cProc = $test->class->new($test->constructorArgs());

    ok($cProc->interfaceResidues, "interfaceResidues ok");
}

sub test_features {
    my $test   = shift;
    my $cProc = $test->class->new($test->constructorArgs());
    $cProc->interfaceResidues(["A.101", "A.102", "A.103"]);
    $cProc->model->setExpectedFeatures("class");
    my $inst = $cProc->nextInstance();
    
    is($inst->class, "I", "class label added to instance");
}

package TestsFor::DataSet::Creator::PDB;
use Test::Class::Moose;
with 'CreatorTester';

use DataSet::Creator;
use pdb;

sub supplyClass {
    return 'DataSet::Creator::PDB';
}

sub constructorArgs {
    my $test = shift;
    return (pdb => pdb->new(pdb_file => "pdb2wap.ent", pdb_code => '2wap'),
            model => DataSet::Instance::Model->new(pSummaries => $test->pSummaries),
            complexChainIDs => [ [['A'],[]] ]
        );
}

package TestsFor::DataSet::Creator::Master;
use Test::Class::Moose;
with 'CreatorTester';

use DataSet::Creator;
use DataSet::Input;

sub inputConstructorArgs {   
    return (inputFile => 'pdb2wap.ent', pdbCode => '2wap',
            complexChainIDs => [ [['A'], ['B']] ]);
}

sub constructorArgs {
    my $test = shift;
    
    return (childInput => [DataSet::Input->new(inputConstructorArgs)],
            model => DataSet::Instance::Model->new(pSummaries => $test->pSummaries));
}

sub supplyClass {
    return 'DataSet::Creator::Master';
}

sub testParallelInputConstructorArgs {
    return map {
        DataSet::Input->new(inputFile => "pdb$_.ent", pdbCode => $_,
                            complexChainIDs => [ [ ['A'], ['B'] ] ] ) }
        qw(1ors 1tpx 2wap);
}

sub test_instanceInParallel {
    my $test = shift;
    my $testCreator
        = $test->class->new(childInput => [$test->testParallelInputConstructorArgs()],
                            model => DataSet::Instance::Model->new());
    $testCreator->maxProc(2);
    my $classTest = all(isa"DataSet::Instance");
    cmp_deeply([$testCreator->getInstances()], array_each($classTest));
}

1;
