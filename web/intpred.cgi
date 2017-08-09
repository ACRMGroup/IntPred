#!/usr/bin/perl

use CGI;
use config;

main();

sub main
{
    my $cgi = new CGI;
    my $pdb = $cgi->param('pdb');
    my $chain = $cgi->param('chain');
    %::config = config::ReadConfig('config.cfg');

    $pdb = "\L$pdb";

    my $pdbfile = $::config{'pdbdir'} . "/" . 
                  $::config{'pdbprep'} . $pdb . $::config{'pdbext'};
    my $ipbin   = $::config{'ipbin'};

    print $cgi->header();

    if(! -e $pdbfile)
    {
        PrintErrorPage("PDB file '$pdb' does not exist.");
        exit 0; 
   }

    my @chains = GetPDBChainList($pdbfile);
    if(! grep /^$chain$/, @chains)
    {
        PrintErrorPage("PDB file '$pdb' does not contain chain '$chain'.");
        exit 0;
    }

    my $ctrlFile = WriteControlFile($pdb, $chain, @chains);
    RunIntPred($ctrlFile, $ipbin);
#    unlink $ctrlFile;
}

sub RunIntPred
{
    my ($ctrlFile, $ipbin) = @_;

    PrintErrorPage("Control file does not exist: $ctrlFile") if(! -e $ctrlFile);    

    my $result = `(cd $ipbin; export WEKA_HOME=/tmp/wekahome.$$; source ../setup.sh; ./runIntPred.pl $ctrlFile)`;
    PrintResultPage("$result");
}

sub WriteControlFile
{
    my ($pdb, $chain, @chains) = @_;
    my $ctrlFile = "/var/tmp/intpred.dat." . $$ . time();
    if(open(my $fp, '>', $ctrlFile))
    {
        printf $fp "$pdb : $chain : ";
        my $printed = 0;
        foreach my $notChain (@chains)
        {
            if($notChain ne $chain)
            {
                print $fp ',' if($printed);
                print $fp $notChain;
                $printed = 1;
            }
        }
        print $fp "\n";
        close $fp;
    }
    else
    {
        PrintErrorPage("Internal error - Could not write temporary file: $ctrlFile.");
    }
    return($ctrlFile);
}

sub GetPDBChainList
{
    my($pdbfile)  = @_;
    my %chainhash = ();

    if(open(my $fp, '<', $pdbfile))
    {
        while(<$fp>)
        {
            if(/^ATOM  /)
            {
                my $chain = substr($_, 21, 1);
                $chainhash{$chain} = 1;
            }
        }
        close $fp;
    }

    return(keys %chainhash)
}



sub PrintErrorPage
{
    my($msg) = @_;

    print <<__EOF;
<html>
<head>
<title>IntPred Error</title>
</head>
<body>
<h1>IntPred Error</h1>
<p>$msg</p>
</body>
</html>
__EOF
}

sub PrintResultPage
{
    my($msg) = @_;

    print <<__EOF;
<html>
<head>
<title>IntPred Result</title>
</head>
<body>
<h1>IntPred Result</h1>
<pre>
$msg
</pre>
</body>
</html>
__EOF
}

