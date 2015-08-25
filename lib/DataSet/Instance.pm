package DataSet::Instance;
use Moose;
use Moose::Util::TypeConstraints;
use overload '""' => 'stringify';

### Attributes #################################################################
################################################################################

has 'resIDs' => (
    is  => 'rw',
    isa => 'ArrayRef',
);

has 'resNames' => (
    is  => 'rw',
    isa => 'ArrayRef'
);

has 'summary' => (
    is => 'rw',
    isa => 'Str',
);

sub _numFeatures {
    return qw(pro pho pln SS Hb blast fosta predScore);
}

sub _strFeatures {
    return qw(secStruct id class);
}

sub listFeatures {
    my $self = shift;
    return ($self->_numFeatures(), $self->_strFeatures());
}

subtype 'MissingValue',
    as 'Str',
    where {$_ eq '?'};

foreach my $numFeat (_numFeatures()) {
    has $numFeat => (
        isa => 'Num | MissingValue',
        is  => 'rw',
        predicate => 'has_' . $numFeat,
    );
}

foreach my $strFeat (_strFeatures()) {
    has $strFeat => (
        isa => 'Str',
        is  => 'rw',
        predicate => 'has_' . $strFeat
    );
}

### Methods ####################################################################
################################################################################

sub listSetFeatures {
    my $self = shift;

    # Only return those features that have their predicate set to true
    my @setFeatures = ();

    foreach my $feat ($self->listFeatures()) {
        my $pred = "has_$feat";
        push(@setFeatures, $feat) if $self->$pred;
    }
    return @setFeatures;
}

sub getValueForFeatureHash {
    my $self = shift;
    return map {$_ => $self->$_} $self->listSetFeatures();
}

sub string {
    my $self = shift;
    my @orderedFeatures = @_ ? @_ : $self->listSetFeatures;
    
    join(",", map {$self->$_} @orderedFeatures);
}

sub stringify {
    my $self = shift;
    return "DataSet::Instance";
}

################################# END OF CLASS #################################
################################################################################

package DataSet::Instance::Model;
use Moose;
extends 'DataSet::Instance';

use Carp;
use TCNUtil::ARFF;

### Class Attributes ###########################################################
################################################################################

use MooseX::ClassAttribute;

class_has 'flag2Feature' => (
    isa => 'HashRef',
    is  => 'ro',
    lazy => 1,
    default => \&_buildFlag2Feature
);

class_has 'feature2Attribute' => (
    isa => 'HashRef',
    is  => 'ro',
    lazy    => 1,
    default => \&_buildFeature2Attribute,
);

class_has 'attribute2Feature' => (
    isa => 'HashRef',
    is  => 'rw',
    lazy => 1,
    default => \&_buildAttribute2Feature,
);


### Class Attribute Builders ###################################################
################################################################################

sub _buildAttribute2Feature {
    # Reverse hash
    return {map {DataSet::Instance::Model->feature2Attribute->{$_} => $_}
                keys %{DataSet::Instance::Model->feature2Attribute}};
}

sub _buildFeature2Attribute {
    return {id        => 'patchID',
            pro       => 'propensity',
            pho       => 'hydrophobicity',
            pln       => 'planarity',
            secStruct => 'secondary_str',
            SS        => 'SSbonds',
            Hb        => 'Hbonds',
            fosta     => 'fosta_scorecons',
            blast     => 'blast_scorecons',
            class     => 'intf_class'};
}

sub _buildFlag2Feature {
    return {p => 'pro',
            o => 'pho',
            l => 'pln',
            s => 'SS',
            h => 'Hb',
            b => 'blast',
            f => 'fosta',
            t => 'secStruct',
            c => 'class',
            i => 'id'};
}

no MooseX::ClassAttribute;

### Attributes #################################################################
################################################################################

has 'patchRadius' => (
    isa => 'Num',
    is  => 'rw',
    default => 14
);

has 'secStructThresh' => (
    isa => 'Num',
    is => 'rw',
    default => 0.20
);

has 'labelThreshold' => (
    isa => 'Num',
    is  => 'rw',
    default => 0.5,
);

has 'FOSTAHitMin' => (
    isa => 'Int',
    is  => 'rw',
    default => 10,
);

has 'BLASTHitMin' => (
    isa => 'Int',
    is  => 'rw',
    default => 10,
);

has 'BLASTHitMax' => (
    isa => 'Int',
    is  => 'rw',
    default => 200,
);

has 'propCalc' => (
    is => 'rw',
    isa => 'DataSet::PropCalc',
    predicate => 'hasPropCalc'
);

has 'pSummaries' => (
    is => 'rw',
    isa => 'HashRef',
    predicate => 'haspSummaries',
);

has 'userLabels' => (
    is => 'rw',
    isa => 'HashRef',
    predicate => 'hasUserLabels',
);

has 'featureStr' => (
    is => 'rw',
    isa => 'Str',
    predicate => 'hasFeatureStr',
);

has 'orderedFeatures' => (
    isa => 'ArrayRef[Str]',
    is  => 'rw',
    lazy => 1,
    builder => '_buildOrderedFeatures',
    predicate => 'has_orderedFeatures'
);

### Builders ###################################################################
################################################################################

around 'BUILDARGS' => sub  {
    my $orig  = shift;
    my $class = shift;
    
    if (@_ == 1) {
        return $class->$orig(_processSingleConstructorArg($_[0]));
    }
    else {
        return $class->$orig(@_);
    }
};

sub _processSingleConstructorArg {
    my $arg = shift;

    if (! ref $arg) {
        # Assume that passed string is a featureStr
        return (featureStr => $arg);       
    }
    elsif (ref $arg eq 'ARFF') {
        return (_constructorArgsFromArff($arg));
    }
    else {
        return $arg;
    }
}

# TO get Instance::Model constructor args from arff, we map each arff attribute
# to its corresponding Instance feature and then return these features
sub _constructorArgsFromArff {
    my $arff = shift;

    my @features = map {DataSet::Instance::Model->attribute2Feature->{$_->name}}
        $arff->getAttributeDescriptions();
    
    return (orderedFeatures => \@features);
}

sub BUILD {
    my $self = shift;

    if ($self->hasFeatureStr) {
        $self->setExpectedFeatures($self->parseFeatureString());
    }
    elsif ($self->has_orderedFeatures) {
        $self->setExpectedFeatures(@{$self->orderedFeatures})
    }
}

sub _buildOrderedFeatures {
    my $self = shift;

    return $self->hasFeatureStr ? $self->model->parseFeatureString()
        : croak "Instance::Model - tried to build orderedFeatures, "
            . "but no feature string has been assigned!";
}

### Methods ####################################################################
################################################################################

sub featureForAttributeName {
    my $self     = shift;
    my $attrName = shift;
    
    return DataSet::Instance::Model->attribute2Feature->{$attrName};
}

sub attributeNameForFeature {
    my $self    = shift;
    my $feature = shift;
    return DataSet::Instance::Model->feature2Attribute->{$feature};
}

sub setExpectedFeatures {
    my $self = shift;
    my @expFeatures = @_;
    
    @expFeatures = $self->listFeatures() if ! @expFeatures;
    
    foreach my $feat (@expFeatures) {
        $self->$feat('0');
    }
    return 1;
}

sub parseFeatureString {
    my $self = shift;
    map {$self->flag2Feature->{$_}} split('', $self->featureStr);
}

sub instancesFromArff {
    my $self = shift;
    my $arff = shift;
    
    map {DataSet::Instance->new($self->_mapArffInstance($_))}
        $arff->allInstances();
}

sub _mapArffInstance {
    my $self         = shift;
    my $arffInstance = shift;
    # Get instance attributes and values, then map attribute names to feature
    # names.
    my %valueForAttributeName = $arffInstance->getHashOfAttributeNameToValue();

    map {$self->featureForAttributeName($_) => $valueForAttributeName{$_}}
        keys %valueForAttributeName;
}

__PACKAGE__->meta()->make_immutable();

1;
