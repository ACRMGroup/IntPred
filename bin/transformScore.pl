#! /usr/bin/env perl
use strict;
use warnings;

while (<>) {
    if($_ =~ /,/ && $_ !~ /^inst/){
        chomp $_;
        my @fields = split(/,/);
        my $val = ($fields[4] - 0.5) * 2;
        if($fields[2] eq "2:S"){
            $val = - $val;
        }
        $fields[4] = $val;
        print join(",", @fields) . "\n";
    }
    else {
        print $_;
    }
}
