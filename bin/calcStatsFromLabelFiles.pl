#!/usr/bin/env perl
use strict;
use warnings;
use TCNUtil::confusion_table;
use Carp;

@ARGV == 2 or Usage();

my $valueFile = shift @ARGV;
my $predFile  = shift @ARGV;

open(my $IN, "<", $valueFile) or die "Cannot open file $valueFile, $!";
my %id2Value = map {chomp $_;
                    my ($pdbCode, $chainID, $resSeq, $label) = split(/:/, $_);
                    $pdbCode = uc($pdbCode);
                    "$pdbCode:$chainID:$resSeq" => $label} <$IN>;
close $IN;

open($IN, "<", $predFile) or die "Cannot open file $predFile, $!";
my %id2Pred  = map {chomp $_;
                    my ($pdbCode, $chainID, $resSeq, $label) = split(/:/, $_);
                    $pdbCode = uc($pdbCode);
                    "$pdbCode:$chainID:$resSeq" => $label} <$IN>;
close $IN;

my %pdb2Table = ();

while (my ($id, $value) = each %id2Value) {
    my ($pdb) = $id =~ /(.*?):/;
    if (! exists $id2Pred{$id}) {
        print {*STDERR} "No pred label for residue $id!\n";
        next;
    }
    my $obj = bless {id => $id}, "id";
    $pdb2Table{$pdb} = confusion_table->new(item_class => "id") if ! exists $pdb2Table{$pdb};
    $pdb2Table{$pdb}->add_datum(datum->new(object => $obj, prediction => $id2Pred{$id},
                                           value => $value));
}

my $outCSVHeader;
my @fields;

while (my ($pdb, $table) = each %pdb2Table) {
    if (! $outCSVHeader) {
        @fields = ("pdb", $table->metrics_array);
        $outCSVHeader = join(",", @fields);
        print $outCSVHeader . "\n";
    }
    my %valueForField = $table->hash_all(printable => 1);    
    my @metrics = map {$valueForField{$_}} @fields[1..$#fields];
    print join(",", ($pdb, @metrics)) . "\n";
}

sub Usage {
    print <<EOF;
$0 value-file pred-file
EOF
    exit(1);
}
