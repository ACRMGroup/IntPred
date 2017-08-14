package config;
#*************************************************************************
#
#   File:       config.pm
#
#   This file taken from github/ACRMGroup/perllib
#   
#   Version:    V1.1
#   Date:       11.11.16
#   Function:   Functions to read a config file
#   
#   Copyright:  (c) Dr. Andrew C. R. Martin, UCL, 2015-2016
#   Author:     Dr. Andrew C. R. Martin
#   Address:    Institute of Structural and Molecular Biology
#               Division of Biosciences
#               University College
#               Gower Street
#               London
#               WC1E 6BT
#   EMail:      andrew@bioinf.org.uk
#               
#*************************************************************************
#
#   This program is not in the public domain, but it may be copied
#   according to the conditions laid out in the accompanying file
#   COPYING.DOC
#
#   The code may be modified as required, but any modifications must be
#   documented so that the person responsible can be identified. If 
#   someone else breaks this code, I don't want to be blamed for code 
#   that does not work! 
#
#   The code may not be sold commercially or included as part of a 
#   commercial product except as described in the file COPYING.DOC.
#
#*************************************************************************
#
#   Description:
#   ============
#   Routines to read a BASH compatible configuration file
#
#*************************************************************************
#
#   Usage:
#   ======
#
#*************************************************************************
#
#   Revision History:
#   =================
#   V1.0  29.04.15  Original   By: ACRM
#   V1.1  11.11.16  Added functions for manipulating files (performing
#                   substitutions, etc.). Also supports commands within
#                   assignments (e.g. `pwd`)
#
#*************************************************************************
use utils;
use FindBin;

#*************************************************************************
#> %config = ReadConfig($filename)
#  -------------------------------
#  \param[in] $filename   Configuration file
#  \return                Hash of keys and values
#
#  Reads a configuration file returning a hash containing the keys and
#  values. 
#  The code looks first for the config file using the specified filename
#  (which may include a full path) and if that fails, looks in the 
#  directory in which the script lives.
#
#  The code ignores any optional 'export' keywords at the start
#  of a line for BASH compatibility. Configuration variables are set
#  using a line of the form
#     key = value
#  The spaces around the '=' are optional and the value may be contained
#  in double inverted commas
#
#  The value can contain a previously-set variable, but this must be
#  enclosed in {}. For example:
#     key = ${prevvalue}/value
#  Previously set values may be set within the confirguration file or
#  may be environment variables set elsewhere.
#
#  The value may also contain executable code in backticks so you 
#  can do things like:
#     file="`pwd`/logs/logfile.txt"
#  Note that variables are expanded before executable code is run
#
#  29.04.15 Original   By: ACRM
sub ReadConfig
{
    my($file) = @_;
    my %config = ();

    if(! -e $file)
    {
        $file = "$FindBin::Bin/$file";
        if(! -e $file)
        {
            utils::mydie("Config file does not exist: $file", 0);
        }
    }

    if(open(my $fp, '<', $file))
    {
        my $lineNum = 0;
        while(my $line = <$fp>)
        {
            $lineNum++;
            chomp $line;
            $line =~ s/\#.*//;        # Remove comments
            $line =~ s/^\s+//;        # Remove leading spaces
            $line =~ s/^export\s+//i; # Remove leading 'export'
            $line =~ s/\s+$//;        # Remove trailing spaces
            if(length($line))
            {
                if($line =~ /(.*)\s*=\s*(.*)/)
                {
                    my $key   = $1;
                    my $value = $2;
                    SetConfig(\%config, $key, $value, $lineNum);
                }
                else
                {
                    utils::mydie("Config file not in x=y format", $lineNum);
                }
            }
        }
        close $fp;
    }
    else
    {
        utils::mydie("Couldn't open file for reading: $file", 0);
    }

    return(%config);
}

#*************************************************************************
#> ExportConfig(%config)
#  ---------------------
#  \param[in]   %config   Configuration hash
#
#  Exports all values in the config file to the environment
#
#  29.04.15  Original   By: ACRM
#
sub ExportConfig
{
    my(%config) = @_;
    foreach my $key (keys %config)
    {
        $ENV{$key} = $config{$key};
    }
}

#*************************************************************************
#> SetConfig($hConfig, $key, $value, $lineNum)
#  -------------------------------------------
#  \param[out]   $hConfig    Reference to config hash
#  \param[in]    $key        Key in config hash
#  \param[in]    $value      Value in config hash
#  \param[in]    $lineNum    Line number of config file that is being
#                            read (or 0)
#
#  Sets a configuration value in the config hash. The code expands any
#  variables of the form ${variable} taking these first from previous
#  config settings and if this fails from environment variables
#
#  The code also allows executable programs within assignment.
#  For example PWD="`pwd`"
#  Note that variables are expanded before executable code is run
#
#  This routine is not normally used by calling code.
#
#  29.04.15 Original   By: ACRM
#  11.11.16 Added handling of `` commands
#
sub SetConfig
{
    my($hConfig, $key, $value, $lineNum) = @_;

    $value =~ s/^\"//;          # Remove inverted commas at the start
    $value =~ s/^\'//;
    $value =~ s/\"$//;          # Remove inverted commas at the end
    $value =~ s/\'$//;

    while($value =~ /(\${.*?})/) # Value contains a variable
    {
        my $subkey = $1;
        my $subval = '';
        $subkey =~ s/\${//;     # Remove ${
        $subkey =~ s/}//;       # Remove }
        if(!defined($$hConfig{$subkey}))
        {
            if(defined($ENV{$subkey}))
            {
                $subval = $ENV{$subkey};
            }
            else
            {
                utils::mydie("Value has not been defined in config file or environment: '$subkey'",
                             $lineNum);
            }
        }
        else
        {
            $subval = $$hConfig{$subkey};
        }
        $value =~ s/\${$subkey}/$subval/g;
    }

    while($value =~ /`(.*?)`/)  # Value contains a command
    {
        my $cmd    = $1;        # Extract the command
        my $result = `$cmd`;    # Run the command
        chomp $result;
        $value =~ s/`${cmd}`/$result/; # Substitute the command
    }

    $$hConfig{$key} = $value;
}

#*************************************************************************
#> ttSubstitute($inFile, $outFile, %config)
#  ----------------------------------------
#  Performs a Perl-Template-Toolkit style substitution of variables in
#  $inFile specified as [%variable%], writing to $outFile.
#  The variables to be substituted are stored in %config as
#     %config{variable} = value
#  This %config hash can be generated using config::ReadConfig()
#
#  11.11.16 Original   By: ACRM
sub ttSubstitute
{
    my($in, $out, %config) = @_;

    if(CheckOverwrite($out))
    {
        if(open(my $infp, '<', $in))
        {
            if(open(my $outfp, '>', $out))
            {
                while(<$infp>)
                {
                    s/\[\%(.*?)\%\]/$config{$1}/g;
                    print $outfp "$_";
                }
                close $outfp;
            }
            else
            {
                utils::mydie("Cannot write to $out. Configure failed.");
            }
        
            close $infp;
        }
        else
        {
            utils::mydie("$in does not exist. Configure failed.");
        }
    }
}


#*************************************************************************
#> linkfile($in, $out)
#  -------------------
#  linkfile() creates a symbolic link, but checks if the input file exists
#  first (and exits if it doesn't) and also checks if the output link or
#  file exists and sees if you wish to overwrite it
#
#  11.11.16 Original   By: ACRM
sub linkfile
{
    my($in, $out) = @_;
    if( ! -e $in )
    {
        utils::mydie("$in does not exist. Configure failed.");
    }

    if(CheckOverwrite($out))
    {
        `ln -s $in $out`;
    }
}


#*************************************************************************
#> $ok = CheckOverwrite($file)
#  ---------------------------
#  Checks if a file exists and whether you wish to overwrite it if it 
#  does. Returns a boolean to indicate whether it should be overwritten.
#
#  11.11.16 Original   By: ACRM
sub CheckOverwrite
{
    my($file) = @_;
    
    if( -e $file )
    {
        print "$file exists already. Overwrite? (Y/N)[Y]: ";
        my $yorn = <>;
        chomp $yorn;
        if(($yorn ne "n") && ($yorn ne "N"))
        {
            `\\rm -f $file`;
        }
    }

    return(!(-e $file));
}

1;
