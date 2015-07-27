package DataSet;
use Moose;
use types;
use WEKAOutputParser;
use Carp;
use ARFF;

has 'instancesAref' => (
    isa      => 'ArrayRef[DataSet::Instance]',
    is       => 'rw',
    required => 1,
);

has 'instanceModel'  => (
    isa      => 'DataSet::Instance::Model',
    is       => 'rw',
    required => 1,
);

has 'arff' => (
    isa     => 'ARFF',
    is      => 'rw',
    builder => '_buildArff',
    lazy    => 1,
);

has 'expectedTypeForAttribute' => (
    is => 'ro',
    isa => 'HashRef',
    lazy => 1,
    builder => '_buildExpectedTypeForAttribute',
);

around 'BUILDARGS' => sub {
    my $orig  = shift;
    my $class = shift;
    
    if (@_ == 1 && ref $_[0] eq 'ARFF') {
        return $class->$orig(_buildArgsFromArff($_[0]));
    }
    else {
        return $class->$orig(@_);
    }
};

sub _buildArgsFromArff {
    my $arff = shift;

    my $model = DataSet::Instance::Model->new($arff);
    my @instances = $model->instancesFromArff($arff);

    return (instanceModel => $model, instancesAref => \@instances);
}

sub _buildExpectedTypeForAttribute {
    return { patchID => 'string',
             propensity => 'numeric',
             secondary_str => '{H,EH,E,C}',
             hydrophobicity => 'numeric',
             planarity => 'numeric',
             SSbonds => 'numeric',
             Hbonds => 'numeric',
             fosta_scorecons => 'numeric',
             blast_scorecons => 'numeric',
             intf_class => '{I,S}' };
}

sub _buildArff {
    my $self = shift;
    
    my @attributeNames
        = map {$self->instanceModel->attributeNameForFeature($_)}
            @{$self->instanceModel->orderedFeatures()};

    my $typeForAttr = $self->expectedTypeForAttribute();
    my @attributeDescriptions
        = map {ARFF::AttributeDescription->new(name => $_,
                                               type => $typeForAttr->{$_})}
            @attributeNames;
    
    my @arffInstances
        = map {$self->_dataSetInstance2ARFFInstance($_, @attributeDescriptions)}
            @{$self->instancesAref()};
    
    return ARFF->new(attributeDescriptions => \@attributeDescriptions,
                     instances             => \@arffInstances);
}

sub _dataSetInstance2ARFFInstance {
    my $self = shift;
    my $dSetInstance = shift;
    my @attributeDescriptions = @_;

    my @attributes = ();
    
    for (my $i = 0 ; $i < @attributeDescriptions ; ++$i) {
        my $attrDesc = $attributeDescriptions[$i];
        my $feature  = $self->instanceModel->orderedFeatures->[$i];
        push(@attributes, ARFF::Attribute->new(description => $attrDesc,
                                               value => $dSetInstance->$feature));
    }
    my $arffInst = ARFF::Instance->new();
    $arffInst->addAttributes(@attributes);
    return $arffInst;
}

sub makeArffCompatible {
    my $self = shift;
    my $arff = $self->arff();
    
    while (my ($attrName, $attrType) = each %{$self->expectedTypeForAttribute}) {
        $arff->attributeDescriptionWithName($attrName)->type($attrType);
    }
    
    # Convert secondary structure into four binary attributes
    my $secStructAttrName = "secondary_str";
    $arff->transAttributeWithNameToBinaryFromNominal($secStructAttrName);
}

sub standardizeArffUsingRefArff {
    my $self    = shift;
    my $refArff = shift;

    $self->arff->standardize($refArff);
}

sub getInstances {
    my $self = shift;
    return @{$self->instancesAref};
}

sub writePatchFilesToDir {
    my $self = shift;
    my $dir  = shift;
    
    my %instancesForPDB = ();
    push(@{$instancesForPDB{[split(":", $_->id)]->[0]}}, $_)
        foreach $self->getInstances();

    while (my ($pdbCode, $instanceAref) = each %instancesForPDB) {
        my $outFile = "$dir/" . $pdbCode . ".patches";
        open(my $OUT, ">", $outFile) or die "Cannot open file $outFile, $!";
        print {$OUT} map {$_->summary} @{$instanceAref};
        close  $OUT;
    }
}

sub mapWEKAOutput {
    my $self       = shift;
    my $wekaOutput = shift;

    $self->instanceModel->setExpectedFeatures("predScore");
    my @scores
        = WEKAOutputParser->new(input => $wekaOutput)->getTransformedScores();
    $self->_mapScoresToInstances(@scores);
}

sub _mapScoresToInstances {
    my $self   = shift;
    my @scores = @_;

    croak "There are not the same amount of scores as there are instances!"
        if @scores != @{$self->instancesAref};
    
    for (my $i = 0 ; $i < @scores ; ++$i) {
        $self->instancesAref->[$i]->predScore($scores[$i]);
    }
}

1;
