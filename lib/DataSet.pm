package DataSet;
use Moose;
use TCNUtil::types;
use WEKAOutputParser;
use Carp;
use TCNUtil::ARFF;

has 'instancesAref' => (
    isa      => 'ArrayRef[DataSet::Instance]',
    is       => 'rw',
    lazy     => 1,
    builder  => '_instancesArefFromArff'
);

has 'instanceModel'  => (
    isa      => 'DataSet::Instance::Model',
    is       => 'rw',
    lazy     => 1,
    builder  => '_instanceModelFromArff'
);

has 'arff' => (
    isa     => 'ARFF',
    is      => 'rw',
    builder => '_buildArff',
    predicate => 'has_arff',
    lazy    => 1,
);

has 'arffIsCompatible' => (
    isa => 'Bool',
    is  => 'rw',
    default => 0,
);

has 'lazyLoadArff' => (
    isa => 'Bool',
    is  => 'rw',
    default => 0,
);

has 'expectedTypeForAttribute' => (
    is => 'ro',
    isa => 'HashRef',
    lazy => 1,
    builder => '_buildExpectedTypeForAttribute',
);

sub makeArffCompatible {
    my $self = shift;
    return 1 if $self->arffIsCompatible();
    my $arff = $self->arff();
    while (my ($attrName, $attrType) = each %{$self->expectedTypeForAttribute}) {
        my $attrDesc = $arff->attributeDescriptionWithName($attrName);
        # Skip any attributes that are not present in the arff
        next if ! $attrDesc;
        $attrDesc->type($attrType);
    }
    # Convert secondary structure into four binary attributes
    my $secStructAttrName = "secondary_str";
    $arff->transAttributeWithNameToBinaryFromNominal($secStructAttrName);
    return $self->arffIsCompatible(1);
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

sub getInstanceLabels {
    my $self = shift;
    return map {$_->getLabel()} $self->getInstances();
}

sub writePatchFilesToDir {
    my $self         = shift;
    my $dir          = shift;
    my $groupByChain = shift;
    $groupByChain = 0 if ! defined $groupByChain;
    my %instancesForPDB = %{$self->_getGroupInstanceHref($groupByChain)};
    while (my ($pdbCode, $instanceAref) = each %instancesForPDB) {
        my $outFile = "$dir/" . $pdbCode . ".patches";
        open(my $OUT, ">", $outFile) or die "Cannot open file $outFile, $!";
        print {$OUT} map {$_->summary} @{$instanceAref};
        close  $OUT;
    }
}

sub _getGroupInstanceHref {
    my $self = shift;
    my $groupByChain = shift;
    my %hash = ();
    my $method = $groupByChain ? "getPDBID" : "getPDBCode";
    push(@{$hash{$_->$method}}, $_)
        foreach $self->getInstances();
    return \%hash;
}

sub mapWEKAOutput {
    my $self             = shift;
    my $wekaOutputParser = shift;
    $self->instanceModel->setExpectedFeatures("predScore");
    my @scores = $wekaOutputParser->getScores();
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

around 'BUILDARGS' => sub {
    my $orig  = shift;
    my $class = shift;
    if (@_ == 1 && ref $_[0] eq 'ARFF') {
        return $class->$orig(arff => $_[0]);
    }
    else {
        return $class->$orig(@_);
    }
};

sub BUILD {
    my $self = shift;
    my $args = shift;
    if($self->has_arff && ! $self->lazyLoadArff) {
        # Create instance model and instances now - this avoids problems when
        # instance model is created after a change to arff
        $self->instanceModel();
        $self->instancesAref();
    }
}

sub _instanceModelFromArff {
    my $self = shift;
    return DataSet::Instance::Model->new($self->arff);
}

sub _instancesArefFromArff {
    my $self = shift;
    return [$self->instanceModel->instancesFromArff($self->arff)];
}

sub _buildExpectedTypeForAttribute {
    return { patchID => 'string',
             propensity => 'numeric',
             secondary_str => '{H,EH,E,C}',
             hydrophobicity => 'numeric',
             planarity => 'numeric',
             SSbonds => 'numeric',
             Hbonds => 'numeric',
             rASA => 'numeric',
             tol => 'numeric',
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

    $self->_mapUnlabelledValues(@arffInstances);
    return ARFF->new(attributeDescriptions => \@attributeDescriptions,
                     instances             => \@arffInstances);
}

sub _mapUnlabelledValues {
    my $self          = shift;
    my @arffInstances = @_;
    map { $_->setValueForAttributeWithName('?', 'intf_class')
              if $_->getValueForAttributeWithName('intf_class') eq 'U' }
        @arffInstances;    
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

1;
