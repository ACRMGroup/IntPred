package WEKAOutputParser;
use Moose;
use Carp;
use Moose::Util::TypeConstraints;
use Types;

has 'input' => (
    is => 'rw',
    isa => 'IntPred::ArrayRefOfStrings',
    coerce => 1,
);

has 'hasTransformedPredictionScores' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
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
    my $reachedHeader = 0;
    foreach my $line (@{$self->input}) {
        if (! $reachedHeader) {
            $reachedHeader = 1 if $line =~ /^inst#/;
            next;
        }
        my $infoAref = $self->parseCSVLine($line);
        my ($patchID, $value, $prediction, $score) = @{$infoAref}; 
        $map{$patchID}
            = {value => $value, prediction => $prediction,
               score => $score};
    }
    return %map;
}

sub transformPredictionScores {
    my $self = shift;
    return 1 if $self->hasTransformedPredictionScores();
    my $reachedHeader = 0;
    for (my $i = 0 ; $i < @{$self->input} ; ++$i) {
        my $line = $self->input->[$i];
        if (! $reachedHeader) {
            $reachedHeader = 1 if $line =~ /^inst#/;
            next;
        }
        next if $line =~ /^\s*$/xms;
        $self->input->[$i] = $self->transformScoreInLine($line);
    }
    $self->hasTransformedPredictionScores(1);
}

sub getCSVString {
    my $self = shift;
    return join("", @{$self->input});
}

sub printCSVString {
    my $self = shift;
    my $FH   = shift;
    print {$FH} @{$self->input};
}

sub getScores {
    my $self = shift;
    my @scores = ();
    $self->transformPredictionScores();
    my $reachedHeader = 0;
    for (my $i = 0 ; $i < @{$self->input} ; ++$i) {
        my $line = $self->input->[$i];
        if (! $reachedHeader) {
            $reachedHeader = 1 if $line =~ /^inst#/;
            next;
        }
        next if $line =~ /^\s*$/xms;
        push(@scores, $self->getScoreFromLine($line));
    }
    return @scores;
}

sub getScoreFromLine {
    my $self = shift;
    my $line = shift;
    return $self->parseCSVLine($line)->[3];
}

sub transformScoreInLine {
    my $self = shift;
    my $line = shift;
    my $predictionInfoAref = $self->parseCSVLine($line);
    my $predictedLabel     = $predictionInfoAref->[2];
    my $score              = $predictionInfoAref->[3];
    $predictionInfoAref->[3] = $self->_transformScore($predictedLabel, $score);
    return $self->reformCSVLineFromInfoAref($predictionInfoAref);
}

sub reformCSVLineFromInfoAref {
    my $self = shift;
    my $infoAref = shift;
    my ($patchID, $value, $prediction, $score, $inst) = @{$infoAref};
    return join(",", ($inst, $value, $prediction, "", $score, $patchID));
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
    return $label eq '2:S' ? $score - 0.5 : $score;
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
    return [$patchID, $value, $prediction, $score, $inst];
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
