package DataSet::PropCalc;

use strict;
use warnings;
use Moose;
use types;

foreach my $type qw(intf surf) {
    has $type . 'StatFile' => (
        is => 'rw',
        isa => 'FileReadable',
    );

    has $type . 'Href' => (
        is => 'rw',
        isa => 'HashRef',
        builder => 'build_' . $type . 'Href',
        lazy => 1,
    );
}

has 'surfMeanHref' => (
    is => 'rw',
    isa => 'HashRef',
    lazy => 1,
    builder => 'build_surfMean',
);

has 'lnPartHref' => (
    is => 'rw',
    isa => 'HashRef',
    lazy => 1,
    builder => 'build_lnPartHref'
);

sub build_lnPartHref {
    my $self = shift;

    my %ln = ();
    
    foreach my $res (keys %{$self->intfHref}) {
        my $a      = $self->intfHref->{$res} / $self->surfHref->{$res};
        my $lnProp = log($a);
        $ln{$res}  = $lnProp;
    }
    return \%ln;
}

sub build_surfMean {
    my $self = shift;

    my $file = $self->surfStatFile();
    open(my $IN, "<", $file) or die "Cannot open file $file, $!";

    my %surfMean = ();
    
    while (my $line = <$IN>) {
        $line = lc($line);
        if ($line =~ /\[type:sum:count:mean\](.*)/){
            my ($aa_type, $ASAsum, $aa_count, $ASAmean) = split(/:/, $1);
            
            $ASAmean =~ s/\s+//g;
            $surfMean{$aa_type} = $ASAmean;
        }
    }
    return \%surfMean;
}

sub build_intfHref {
    my $self = shift;
    return $self->statHashFromFile($self->intfStatFile)
}

sub build_surfHref {
    my $self = shift;
    return $self->statHashFromFile($self->surfStatFile);
}

sub statHashFromFile {
    my $self = shift;
    my $file = shift;
    
    my %averages = ();
    my $total = 0;

    open(my $FH, "<", $file) or die "Cannot open file $file, $!";

    while (my $line = <$FH>) {
        chomp $line;
        $line = lc($line);
        
        if ($line =~ /total ASA for the dataset is\s(\S+)\./i){
            $total = $1;
        }
        elsif ($line =~ /\[type:sum:count:mean\](.*)/) {
            my ($aa_type, $ASAsum, $aa_count, $ASAmean) = split(/:/, $1);
            
            $ASAsum =~ s/\s+//g;
            $averages{$aa_type} = $ASAsum;
        }
    }
    close($FH);
    
    foreach my $k (keys %averages){
        $averages{$k} /= $total;
    }
    return \%averages;
}

sub getResidueScore {
    my $self    = shift;
    my $resName = shift;
    my $resASA  = shift;

    $resName = lc $resName;

    return $self->lnPartHref->{$resName}
        * ($resASA / $self->surfMeanHref->{$resName});
}
1;
