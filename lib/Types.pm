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

coerce  'IntPred::ArrayRefOfStrings',
    from 'IntPred::StringContainingNewLine',
    via {[split(/(\n)/xms, $_)]},
    from 'FileReadable',
    via {open(my $IN, "<", $_) or die "Cannot open file $_, $!"; [<$IN>];},
    from 'Str',
    via {[$_]};

class_type 'Config::IniFiles';
coerce 'Config::IniFiles',
    from 'FileReadable',
    via {croak "File $_ is empty! Config file must not be empty" if -z $_;
         Config::IniFiles->new(-file => $_)};

1;
