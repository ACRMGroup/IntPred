package Types;
use Moose::Util::TypeConstraints;
use Config::IniFiles;
use Carp;
use TCNUtil::types;

subtype 'IntPred::ArrayRefOfStrings',
    as 'ArrayRef[Str]';

subtype 'IntPred::StringContainingNewLine',
    as 'Str',
    where {$_ =~ /\n/xms};

subtype 'IntPred::pCentresHashRef',
    as 'HashRef';

coerce 'IntPred::pCentresHashRef',
    from 'Directory',
    via {my %h = _getPatchCentreHashFromDir($_); \%h};


coerce  'IntPred::ArrayRefOfStrings',
    from 'IntPred::StringContainingNewLine',
    via {[split(/(\n)/xms, $_)]},
    from 'FileReadable',
    via {open(my $IN, "<", $_) or die "Cannot open file $_, $!";
         my @array = grep {$_ !~ /^\s+$/} <$IN>;
         \@array;},
    from 'Str',
    via {[$_]};

class_type 'Config::IniFiles';
coerce 'Config::IniFiles',
    from 'FileReadable',
    via {croak "File $_ is empty! Config file must not be empty" if -z $_;
         Config::IniFiles->new(-file => $_)};

sub _getPatchCentreHashFromDir {
    my $dir = shift;
    my %h = ();
    opendir(my $DIR, $dir);
    while (my $file = readdir($DIR)) {
        next unless $file =~ /(.*)\.centres/;
        my $fPath = "$dir/$file";
        my $pdbCode = $1;
        open(my $IN, "<", $fPath) or die "Cannot open file $fPath!";
        while (my $line = <$IN>) {
            chomp $line;
            next if ! $line;
            my ($resID, $atomName) = split(/\s+/, $line);
            my ($chainID, $resSeq) = split(/\./,  $resID);
            push(@{$h{$pdbCode}->{$chainID}}, [$resSeq, $atomName]);
        }
        close $IN;
    }
    closedir $DIR;
    return %h;
}

1;
