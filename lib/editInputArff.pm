package IntPred::lib::editInputArff;

use strict; 
use warnings;

use Carp;


sub getLinesFromArffFile {
    my $file = shift;

    open(my $IN, "<", $file) or die "Cannot open file $file, $!";

    my @lines = ();

    my $reachedHeader = 0;
    
    while (my $line = <$IN>) {

        if ($line =~ /^@data/) {
            $reachedHeader = 1;
            next;
        }
        elsif ($reachedHeader) {
            next if $line =~ /^\n$/;
            push(@lines, $line);
        }
    }
    return @lines;
}

sub getArffHeader {
    my $inputArff = shift;

    open(my $ARFF, "<", $inputArff) or die "Cannot open file $inputArff, $!";

    my @headerLines = ();

    while (my $line = <$ARFF>) {
        push(@headerLines, $line);
        last if $line =~ /^@data/;
    }
    close $ARFF;

    return @headerLines;
}

sub parseArffLine {
    my $line = shift;

    my @attributes = split(/,/, $line);

    return @attributes;
}



1;
__END__

=head1 NAME

IntPred::lib::editInputArff - Perl extension for blah blah blah

=head1 SYNOPSIS

   use IntPred::lib::editInputArff;
   blah blah blah

=head1 DESCRIPTION

Stub documentation for IntPred::lib::editInputArff, 

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
