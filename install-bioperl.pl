#!/usr/bin/perl
# Script to install the latest version of BioPerl
# This pads each element of a version number with zeros TO THE RIGHT.
# This works at present but may not in future!
#
# 07.08.17 By: ACRM
#----------------------------------------------------------------------
use strict;

my $bplatest = FindLatestBioPerl();

print "\nThe latest version of the main BioPerl package is:\n";
print "$bplatest\n";

print "\nDo you wish to install this version? (y/n)[y]: ";
my $yorn=<>;
chomp $yorn;
$yorn = substr("\L$yorn", 0, 1);
if(($yorn eq 'y') || ($yorn eq ''))
{
   my $bpinfo = `echo "force install $bplatest" | perl -MCPAN -e shell`;
   print $bpinfo;
}

#----------------------------------------------------------------------
# Finds the latest BioPerl in CPAN
# 07.08.17 Original   By: ACRM
sub FindLatestBioPerl
{
    my $bpinfo = `echo "d /bioperl/" | perl -MCPAN -e shell`;
    print "\nCPAN revealed the following for BioPerl:\n";
    print "$bpinfo\n";

    my @packages = ();
    my @versions = ();
    my @lines = split(/\n/, $bpinfo);
    foreach my $line (@lines)
    {
        my @fields = split(/\s+/, $line);
        foreach my $field (@fields)
        {
            if($field =~ /\/BioPerl-(\d.*)\.tar.gz/)
            {
                push(@packages, $field);
                push(@versions, $1);
            }
        }
    }

    my $bestVersion = "0.0.0";
    my $bestItem    = (-1);
    for(my $versionItem=0; $versionItem<scalar(@versions); $versionItem++)
    {
        if(IsNewer($versions[$versionItem], $bestVersion))
        {
            $bestVersion = $versions[$versionItem];
            $bestItem    = $versionItem;
        }
    }

    return($packages[$bestItem]);
}

#----------------------------------------------------------------------
# Tests whether $thisVers is newer than $bestVers. Each part of a 
# version number is padded with zeros to the right - this works at
# present but may not be the right thing to do in future!
#
# 07.08.17 Original   By: ACRM
sub IsNewer
{
    my($thisVers, $bestVers) = @_;

    my @bestParts = split(/\./, $bestVers);
    my @thisParts = split(/\./, $thisVers);

    my $numParts = (scalar(@bestParts) > scalar(@thisParts)) ? 
        scalar(@bestParts) : scalar(@thisParts);

    for(my $i=0; $i<$numParts; $i++)
    {
        my $cmpVal = CmpNum($thisParts[$i], $bestParts[$i]);
        if($cmpVal < 0)
        {
            return(0);
        }
        elsif($cmpVal > 0)
        {
            return(1);
        }
    }
    return(0);
}

#----------------------------------------------------------------------
# Pads $num1 and $num2 with zeros to the right - so if you are comparing
# 007001 with 6 you end up comparing 007001 with 600000
# If $num1 >  $num2 returns +1
#    $num1 <  $num2 returns -1
#    $num1 == $num2 returns 0
# 07.08.17 Original   By: ACRM
sub CmpNum
{
    my($num1, $num2) = @_;

    my $len1 = length("$num1");
    my $len2 = length("$num2");
    my $maxLen = ($len1 > $len2) ? $len1 : $len2;
    my $padLen1 = $maxLen - $len1;
    my $padLen2 = $maxLen - $len2;

    for(my $i=0; $i<$padLen1; $i++) { $num1 .= "0"; }
    for(my $i=0; $i<$padLen2; $i++) { $num2 .= "0"; }

    if($num1 > $num2) 
    { 
        return(1); 
    }
    elsif($num1 < $num2)
    {
        return(-1);
    }

    return(0);
}
