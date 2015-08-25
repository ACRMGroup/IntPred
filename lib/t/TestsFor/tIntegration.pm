package TestsFor::Integration;
use Test::Class::Moose;
use Carp;
use Scalar::Util qw(looks_like_number);

sub testConfigFile {
    return "configFiles/testDataSetCreator.ini";
}

sub test_instanceFeatureValues {
    my $test = shift;

    my $testDataSetCreator
        = ConfigReader->new(testConfigFile())->createDataSetCreator();

    my @gotInstances = ();
    while (my $instance = $testDataSetCreator->nextInstance()) {
        push(@gotInstances, $instance);
    }
    @gotInstances = sort {$a->id() cmp $b->id()} @gotInstances;

    my @expInstances = expInstances();

    is(scalar @gotInstances, scalar @expInstances,
       "correct number of instances returned");
    
    ok(compareInstances(\@gotInstances, \@expInstances).
           "all instances have expected feature values\n");
}

sub expFeatureNames {
    return qw(patchID propensity hydrophobicity planarity secondary_str SSbonds
              Hbonds fosta_scorecons blast_scorecons intf_class);
}

sub expFeatures {
    return qw(id pro pho pln secStruct SS Hb fosta blast class);
}

sub expInstances {
    my $file = "expected.csv";
    open(my $IN, "<", $file) or die "Cannot open file $file, $!";

    my @feats = expFeatures();

    my @instances = ();

    # Skip header line
    my $line = <$IN>;
    
    while ($line = <$IN>) {
        chomp $line;
        my @values = split(",", $line);
        my %feat2Value = ();

        @feat2Value{@feats} = @values;

        my $instance = DataSet::Instance->new();
        while (my ($feat, $value) = each %feat2Value) {
            $instance->$feat($value);
        }
        push(@instances, $instance);
    }
    return sort {$a->id() cmp $b->id()} @instances;
}

sub expHeader {
    return join(",", expFeatureNames(), "\n");
}

sub compareInstances {
    my ($instAref1, $instAref2) = @_;

    print "WARNING: Only checking Hb feature is present (no value check), "
        . "as this deliberately differs\n";
    print "WARNING: Only checking blast and fosta features are present (no "
        . "value check), as values will change over time as databases change.\n";
    for (my $i = 0 ; $i < @{$instAref1} ; ++$i) {
        my $instA = $instAref1->[$i];
        my $instB = $instAref2->[$i];
        next if instanceCmp($instA, $instB, {Hb => 1, fosta => 1, blast => 1});
        croak "Instances at index $i do not match: $@";
    }
    return 1;
}

sub instanceCmp {
    my $iA          = shift;
    my $iB          = shift;
    my $ignoreValue = shift;

    foreach my $feat (expFeatures()) {
        my $pred = 'has_' . $feat;
        
        foreach my $inst ($iA, $iB) {
            croak "Instance " . $inst->id() . " does not have $feat feature!"
                if ! $inst->$pred;
            croak "Instance " . $inst->id() . " $feat feature is missing!"
                if $inst->$feat eq '?';
        }

        next if exists $ignoreValue->{$feat};
        
        if (looks_like_number($iA->$feat)) {
            croak "Feature values for $feat do not match! "
                . join(" vs. ", $iA->$feat, $iB->$feat)
                    if abs($iA->$feat - $iB->$feat) > 0.01;
        }
        else {
            croak "Feature values for $feat do not match! "
                . join(" vs. ", $iA->$feat, $iB->$feat)
                    if $iA->$feat ne $iB->$feat;
        }
    }
    return 1;
}

1;
