package ConfigReader;
use Moose;

use DataSet;
use DataSet::Creator;
use DataSet::Instance;
use DataSet::Input;
use DataSet::PropCalc;
use Predictor;
use Types;

use Config::IniFiles;
use File::Basename;
use File::Spec;
use Carp;
    
has 'config' => (
    is       => 'rw',
    isa      => 'Config::IniFiles',
    required => 1,
    coerce   => 1,
    handles  => [qw(val exists newval setval)],
);

around 'val' => sub {
    my $orig  = shift;
    my $class = shift;
    confess "Value for section $_[0], parameter $_[1] is not defined!"
        if ! $class->exists(@_);
    return $class->$orig(@_);
};

around 'BUILDARGS' => sub {
    my $orig  = shift;
    my $class = shift;

    if (! @_){
        $class->$orig(config => Config::IniFiles->new());
    }
    elsif (@_ == 1) {
        $class->$orig(config => $_[0]);
    }
    else {
        $class->$orig(@_);
    }
};

sub getPredictor {
    my $self = shift;
    my $pred = Predictor->new();
    $pred->randomForest->model($self->getModelFile());
    return $pred;
}

sub createDataSetCreator {
    my $self = shift;
    my $creator
        = DataSet::Creator::Master->new(
            model   => $self->createInstanceModel(),
            inputs  => [$self->createInputs()],
        );
    return $creator;
}

sub createInstanceModel {
    my $self = shift;

    my $model
        = DataSet::Instance::Model->new(
            orderedFeatures => [$self->getFeatures()]
        );

    $model->propCalc($self->createPropCalc())
        if grep {/^pro$/} $self->getFeatures();
    
    $model->userLabels($self->readLabelsFile())
        if $self->exists(qw(TestSet labelsFile));

    $model->pSummaries($self->readPatchDir())
        if $self->exists(qw(TestSet patchDir));

    $model->pCentres($self->val(qw(DataSetCreation pCentreDir)))
        if $self->exists(qw(DataSetCreation pCentreDir));

    $model->interfaceResIDs($self->readInterfaceResIDsFile)
        if $self->exists(qw(DataSetCreation interfaceResIDsFile));
    
    return $model;
}

sub createPropCalc {
    my $self = shift;
    return DataSet::PropCalc->new(intfStatFile => $self->getIntfStatFile(),
                                  surfStatFile => $self->getSurfStatFile());
}

sub addTestSetInputFileAndFormat {
    my $self = shift;
    my ($inFile, $format) = @_;
    # Make sure that input file is an absolute path
    my $inFileAbsPath = File::Spec->rel2abs($inFile);
    $self->newval(qw(TestSet inFile), $inFileAbsPath);
    $self->newval(qw(TestSet inFileFormat), $format);
}

sub createInputs {
    my $self = shift;
    my $inputFile  = $self->_getPathForVal(qw(TestSet inFile));
    my $fileFormat = $self->val(qw(TestSet inFileFormat));

    open(my $IN, "<", $inputFile) or die "Cannot open file $inputFile, $!";    
    return map {DataSet::Input->new($_, $fileFormat)} <$IN>;
}

sub getSurfStatFile {
    my $self = shift;
    return $self->_getPathForVal(qw(DataSetCreation surfStatFile));
}

sub getIntfStatFile {
    my $self = shift;
    return $self->_getPathForVal(qw(DataSetCreation intfStatFile));
}

sub getModelFile {
    my $self = shift;
    return $self->_getPathForVal(qw(Predictor modelFile))
}

sub getTrainingSet {
    my $self = shift;
    my $arff = $self->getArffForSet("TrainingSet");
    return DataSet->new(arff => $arff, lazyLoadArff => 1);
}

sub getTestSet {
    my $self = shift;
    my $arff = $self->getArffForSet("TestSet");
    return DataSet->new(arff =>$arff);
}

sub getArffForSet {
    my $self = shift;
    my $type = shift;
    my $arffFile = $self->_getPathForVal($type, "ARFF");
    return ARFF::FileParser->new(file => $arffFile)->parse();
}

sub getTrainingSetARFF {
    my $self = shift;
    return $self->_getPathForVal(qw(TrainingSet ARFF))
}

sub setFeatures {
    my $self = shift;
    my @features = @_;
    $self->newval(qw(DataSetCreation features), @features);
}

sub getFeatures {
    my $self     = shift;
    my @features = $self->val(qw(DataSetCreation features));
    return @features;
}

sub _getPathForVal {
    my $self = shift;
    my ($section, $parameter)  = @_;
    my $value = $self->val($section, $parameter);
    return File::Spec->file_name_is_absolute($value) || -l $value ? $value
        : $self->_getConfigDir() . "/" . $value;
}

sub _getConfigDir {
    my $self = shift;
    confess "config has no file name! Was a config file supplied?"
        if ! $self->config->GetFileName;
    my ($fName, $configDir, $suffix) = fileparse($self->config->GetFileName);
    return $configDir;
}

sub readLabelsFile {
    my $self       = shift;
    my $labelsFile = $self->_getPathForVal(qw(TestSet labelsFile)); 
    open(my $IN, "<", $labelsFile) or die "Cannot open file $labelsFile, $!";
    my %pID2label = ();
    while (my $line = <$IN>) {
        chomp $line;
        # example line = 2wap:A:102:I
        my ($patchID, $label) = $line =~ /(.*):(.*)/g; # matches last :
        $pID2label{$patchID} = $label;
    }
    return \%pID2label;
}

sub readInterfaceResIDsFile {
    my $self = shift;
    my $interfaceResIDsFile = $self->_getPathForVal(qw(DataSetCreation interfaceResIDsFile));
    my %pdb2InterfaceResIDAref = ();
    open(my $IN, "<", $interfaceResIDsFile)
        or die "Cannot open file $interfaceResIDsFile, $!";
    while (my $line = <$IN>) {
        chomp $line;
        # example line = 2wap:A:102
        my ($pdbCode, $chainID, $resSeq) = split(/:/, $line);
        push(@{$pdb2InterfaceResIDAref{"$pdbCode$chainID"}}, "chainID.$resSeq");
    }
    return \%pdb2InterfaceResIDAref;    
}

sub readPatchDir {
    my $self     = shift;
    my $patchDir = $self->_getPathForVal(qw(TestSet patchDir));
    my %pdbID2pSummaries = ();
    opendir(my $DIR, $patchDir) or die "Cannot open patch dir $patchDir, $!";
    while (my $fName = readdir($DIR)) {
        next if $fName =~ /^\./; # Skip . and ..
        my $file = "$patchDir/$fName";
        open(my $IN, "<", $file) or die "Cannot open file $file, $!";

        my ($pdbID) = $fName =~ /(\S+)\.patches/g;
        
        $pdbID2pSummaries{$pdbID}
            = [map {chomp $_; $_} <$IN>]; # Remove new-lines
    }
    return \%pdbID2pSummaries;
}

1;
