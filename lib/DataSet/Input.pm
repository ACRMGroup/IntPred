package DataSet::Input;
use Moose;
use TCNUtil::types;
use Moose::Util::TypeConstraints;
use pdb::get_files;
use Carp;

has 'inputFile' => (
    isa => 'FileReadable',
    is  => 'rw',
    builder => 'fileFromPDBCode',
    lazy => 1,
);

sub fileFromPDBCode {
    my $self = shift;

    croak "input: pdbCode must be assigned!"
        if ! $self->has_pdbCode();
    
    my $getFile = pdb::get_files->new(pdb_code => $self->pdbCode);
    croak "Need to implement finding other pdb file types!"
        if $self->pdbType ne 'pdb';

    return $getFile->pdb_file;
}

has 'pdbCode' => (
    isa => 'Str',
    is  => 'rw',
    predicate => 'has_pdbCode'
);

has 'pdbType' => (
    is => 'rw',
    isa => enum([qw[pdb pqs pisa]]),
    default => 'pdb',
    lazy => 1
);

has 'complexChainIDs' => (
    isa => 'ArrayRef',
    is  => 'rw',
    lazy => 1,
    handles => {
        addComplex => 'push',
    },
    default => sub {[]},
);

has 'pdb2pSummaries' => (
     is => 'rw',
     isa => 'HashRef',
     predicate => 'hasPdb2pSummaries',
);

has 'patchID2Label' => (
    is => 'rw',
    isa => 'HashRef',
    predicate => 'patchID2Label',
);

# This BUILDARGS deals with creating an input from a formatted line.
# This will occur when an input is constructed like so
#  input->new($line, $idRead)
#
# Expected line format id:targetChainIDs:complexedChainIDs
# where chainIDs are comma-separated. Multiple chain pairs can be listed.
# Whitespace is ignored
# e.g. 2wap : A:B   : C,D:E,F
#      1wps : B:
#      1jcl : A:-A  : 
# In the second example no complexed chain ids are been given, only targets.
# In the third example, '-' is used to indicate a negation. This will result
# in all chains except A being assigned to complex.
# The first id field will be read according to the idRead setting.
# If idRead = 'file' then id will be treated as a file path. Otherwise, it
# will be treated as a pdb code that can be used to find a pdb file locally.
# According to the idRead, different pdb file types can be found.
# Valid types so far = pdb, pisa, pqs

around 'BUILDARGS' => sub {
    my $orig = shift;
    my $class = shift;
    
    if (@_ == 2 && ! (ref $_[0] || ref $_[0])) { 
        my $line   = $_[0];
        my $idRead = $_[1];

        my %arg = ();
        
        $line =~ s/\s//g;          # Remove whitespace
        $line =~ s/-(?=[^,])/-,/g; # Add comma after negation to make parsing easier
        
        # Split line into an id and a hash of chain pairs
        # Hash makes dealing with the pairs easier later
        my ($id, @chainPairs) = split(":", $line);
        # Initalize input according to how id should be read
        if ($idRead eq 'file') {
            $arg{inputFile} = $id;
        }
        else {
            $arg{pdbCode} = $id;
            $arg{pdbType} = $idRead;
        }
        
        if (@chainPairs == 1) {
            my @tChains = split(",", $chainPairs[0]);
            push(@{$arg{complexChainIDs}}, [\@tChains, []]);
        }
        else {
            my %chainPairs = @chainPairs;
            $arg{complexChainIDs} = [];
            while (my ($tChainStr, $cChainStr) = each %chainPairs) {
                my @tChains = split(",", $tChainStr);
                my @cChains = defined $cChainStr ? split(",", $cChainStr) : ();
                push(@{$arg{complexChainIDs}}, [\@tChains, \@cChains]);
            }
        }
        return $class->$orig(%arg);
    }
    else {
        $class->$orig(@_);
    }
};

1;

