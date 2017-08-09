#!/usr/bin/perl

use CGI;
use config;

my $cgi = new CGI;
my $pdb = $cgi->param('pdb');
my $chain = $cgi->param('chain');
%::config = config::ReadConfig('config.cfg');

print $cgi->header();

if(!CheckPDBExists($pdb, $chain))
{
    PrintErrorPage($pdb, $chain);
    exit 0;
}
else
{
    PrintSuccessPage($pdb, $chain);
}

sub PrintSuccessPage
{
    my($pdb, $chain) = @_;

    print <<__EOF;
<html>
<head>
<title>IntPred Success</title>
</head>
<body>
<h1>Success!</h1>
<p>PDB file $pdb exists!</p>
</body>
</html>
__EOF
}

sub PrintErrorPage
{
    my($pdb, $chain) = @_;

    print <<__EOF;
<html>
<head>
<title>IntPred Error</title>
</head>
<body>
<h1>Error</h1>
<p>PDB file $pdb not found, or chain $chain does not exist.</p>
</body>
</html>
__EOF
}

sub CheckPDBExists
{
    my($pdb, $chain) = @_;
    my $pdbfile = $::config{'pdbdir'} . "/" . 
                  $::config{'pdbprep'} . $pdb . $::config{'pdbext'};

    if( -e $pdbfile )
    {
        ### TODO: Needs to check the chain too!!!!
        return(1);
    }

    return(0);
}
