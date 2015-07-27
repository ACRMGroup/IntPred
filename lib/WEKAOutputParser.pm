package WEKAOutputParser;
use Moose;
use Carp;
use Moose::Util::TypeConstraints;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Types;

has 'input' => (
    is => 'rw',
    isa => 'IntPred::ArrayRefOfStrings',
    required => 1,
    coerce => 1,
);

has 'transformPredictionScores' => (
    is => 'rw',
    isa => 'Bool',
    default => 1,
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if (@_ == 1 && !ref $_[0]) {
        return $class->$orig(input => $_[0]);
    }
    else {
        return $class->$orig(@_);
    }
};

sub mapPatchID2PredInfoHref {
    my $self = shift;

    my %map = ();

    foreach my $line ($self->getLinesFromCSVFile()) {
        my $infoAref = $self->parseCSVLine($line);
        my ($patchID, $value, $prediction, $score) = @{$infoAref}; 
        $map{$patchID}
            = {value => $value, prediction => $prediction,
               score => $self->getTransformedScoreFromLine($line)};
    }
    return %map;
}

sub getTransformedScores {
    my $self = shift;
    
    return map {$self->getTransformedScoreFromLine($_)}
        $self->getLinesFromCSVFile();
}

sub getTransformedScoreFromLine {
    my $self = shift;
    my $line = shift;
    
    my $predictionInfoAref = $self->parseCSVLine($line);
    my $predictedLabel     = $predictionInfoAref->[2];
    my $score              = $predictionInfoAref->[3];

    return $self->_transformScore($predictedLabel, $score);
}

sub _transformScore {
    my $self = shift;
    my ($label, $score) = @_;
    
    return $self->transformPredictionScores && $label eq '2:S' ? $score - 0.5
        : $score;
}

sub getLinesFromCSVFile {
    my $self = shift;
    
    my @csvLines = ();

    my $reachedHeader = 0;
    
    foreach my $line (@{$self->input}) {
        if (! $reachedHeader) {
            $reachedHeader = 1 if $line =~ /^inst#/;
            next;
        }
        next if $line =~ /^\s*$/xms;
        push(@csvLines, $line);
    }
    return @csvLines;
}

sub getCSVHeader {
    my $self = shift;
    
    foreach my $line (@{$self->input}) {
        if ($line =~ /^inst#/){
            return $line;
        }
    }
    croak "Did not parse header from CSV!";
}

sub parseCSVLine {
    my $self = shift;
    my $line = shift;
    
    chomp $line;
    my ($inst, $value, $prediction, $err, $score, $patchID) = split(",", $line);
    return [$patchID, $value, $prediction, $score];
}


1;
__END__

=head1 NAME

IntPred::lib::wekaOutputParser - Perl extension for blah blah blah

=head1 SYNOPSIS

   use IntPred::lib::wekaOutputParser;
   blah blah blah

=head1 DESCRIPTION

Stub documentation for IntPred::lib::wekaOutputParser, 

Blah blah blah.

=head2 EXPORT

None by default.

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Tom Northey, E<lt>zcbtfo4@acrm18E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Tom Northey

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
