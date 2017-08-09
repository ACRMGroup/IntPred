#!/usr/bin/perl

use strict;

my %config=ReadConfig('config.cfg');
linkfile($config{'menu'},   'menu.tt', 1);
linkfile($config{'header'}, 'header.tt', 1);
linkfile($config{'footer'}, 'footer.tt', 1);
#linkfile($config{'menu'},   'kabat/menu.tt');
#linkfile($config{'header'}, 'kabat/header.tt');
#linkfile($config{'footer'}, 'kabat/footer.tt');

ttSubstitute('Makefile.tpl', 'Makefile', %config);

# MakeDir($config{'httpdhome'} . "/


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
                mydie("Cannot write to $out. Configure failed.");
            }
        
            close $infp;
        }
        else
        {
            mydie("$in does not exist. Configure failed.");
        }
    }
}


#*************************************************************************
#> linkfile($in, $out, $force)
#  ---------------------------
#  linkfile() creates a symbolic link, but - unless $force is set - checks
#  if the input file exists first (and exits if it doesn't) and also 
#  checks if the output link or file exists and sees if you wish to 
#  overwrite it
#
#  11.11.16 Original   By: ACRM
#  09.08.17 Added $force
sub linkfile
{
    my($in, $out, $force) = @_;
    if(!$force && (! -e $in ))
    {
        mydie("$in does not exist. Configure failed.");
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
    
    if(( -e $file ) || ( -l $file ))
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
#  The value can contain a previously-set variable, but this must be
#  enclosed in {}. For example:
#     key = ${prevvalue}/value
#  Previously set values may be set within the confirguration file or
#  may be environment variables set elsewhere.
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
            mydie("Config file does not exist: $file", 0);
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
                    mydie("Config file not in x=y format", $lineNum);
                }
            }
        }
        close $fp;
    }
    else
    {
        mydie("Couldn't open file for reading: $file", 0);
    }

    return(%config);
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
#  config settings and if this fails from environment variables.
#
#  The code also allows executable programs within assignment.
#  For example PWD="`pwd`"
#
#  This routine is not normally used by calling code.
#
#  29.04.15 Original   By: ACRM
#  16.11.16 Added `exe` support
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
                mydie("Value has not been defined in config file or environment: '$subkey'",
                             $lineNum);
            }
        }
        else
        {
            $subval = $$hConfig{$subkey};
        }
        $value =~ s/\${$subkey}/$subval/g;
    }

    while($value =~ /`(.*?)`/)
    {
        my $exe    = $1;
        my $result = `$exe`;
        chomp $result;
        $value =~ s/`$exe`/$result/;
    }

    $$hConfig{$key} = $value;
}


#*************************************************************************
# Prints a message ($string) with an optional line number ($line) and 
# exits the program
sub mydie
{
    my($string, $line) = @_;
    print STDERR "$string";
    if($line)
    {
        print STDERR " at line $line";
    }
    print "\n";
    exit 1;
}

