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
    PrintErrorPage("Control file does not exist: $ctrlFile") if(! -e $ctrlFile);    
    my $result = RunIntPredTest($ctrlFile, $ipbin);
#    my $result = RunIntPred($ctrlFile, $ipbin);
    PrintResultPage($result, $pdb);

    unlink $ctrlFile;
}

sub RunIntPredTest
{
    my ($ctrlFile, $ipbin) = @_;

    my $result = "DataSet::Creator::Master - new child DataSet::Creator::PDB - 1yqv
DataSet::Creator::PDB - 1yqv - new child DataSet::Creator::Complex - Target Chains: L Complex Chains: H, Y
NoA FOSTA scores obtained for 1yqvL: Some shiz
NoB FOSTA scores obtained for 1yqvL: NoC BLAST scores obtained for 1yqvL: 
NoD BLAST scores obtained for 1yqvL: Some shiz
DataSet::Creator::Complex - Target Chains: L Complex Chains: H, Y - new child DataSet::Creator::Chain - 1yqvL
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.98
DataSet::Creator::Patch - 1yqv:L.98 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.189
DataSet::Creator::Patch - 1yqv:L.189 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.26
DataSet::Creator::Patch - 1yqv:L.26 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.10
DataSet::Creator::Patch - 1yqv:L.10 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.87
DataSet::Creator::Patch - 1yqv:L.87 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.65
DataSet::Creator::Patch - 1yqv:L.65 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.158
DataSet::Creator::Patch - 1yqv:L.158 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.145
DataSet::Creator::Patch - 1yqv:L.145 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.17
DataSet::Creator::Patch - 1yqv:L.17 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.43
DataSet::Creator::Patch - 1yqv:L.43 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.107
DataSet::Creator::Patch - 1yqv:L.107 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.54
DataSet::Creator::Patch - 1yqv:L.54 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.14
DataSet::Creator::Patch - 1yqv:L.14 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.207
DataSet::Creator::Patch - 1yqv:L.207 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.68
DataSet::Creator::Patch - 1yqv:L.68 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.66
DataSet::Creator::Patch - 1yqv:L.66 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.56
DataSet::Creator::Patch - 1yqv:L.56 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.59
DataSet::Creator::Patch - 1yqv:L.59 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.95
DataSet::Creator::Patch - 1yqv:L.95 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.116
DataSet::Creator::Patch - 1yqv:L.116 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.149
DataSet::Creator::Patch - 1yqv:L.149 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.210
DataSet::Creator::Patch - 1yqv:L.210 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.208
DataSet::Creator::Patch - 1yqv:L.208 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.202
DataSet::Creator::Patch - 1yqv:L.202 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.44
DataSet::Creator::Patch - 1yqv:L.44 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.162
DataSet::Creator::Patch - 1yqv:L.162 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.0
DataSet::Creator::Patch - 1yqv:L.0 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.168
DataSet::Creator::Patch - 1yqv:L.168 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.100
DataSet::Creator::Patch - 1yqv:L.100 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.8
DataSet::Creator::Patch - 1yqv:L.8 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.31
DataSet::Creator::Patch - 1yqv:L.31 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.94
DataSet::Creator::Patch - 1yqv:L.94 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.49
DataSet::Creator::Patch - 1yqv:L.49 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.16
DataSet::Creator::Patch - 1yqv:L.16 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.70
DataSet::Creator::Patch - 1yqv:L.70 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.42
DataSet::Creator::Patch - 1yqv:L.42 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.127
DataSet::Creator::Patch - 1yqv:L.127 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.138
DataSet::Creator::Patch - 1yqv:L.138 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.163
DataSet::Creator::Patch - 1yqv:L.163 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.5
DataSet::Creator::Patch - 1yqv:L.5 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.20
DataSet::Creator::Patch - 1yqv:L.20 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.152
DataSet::Creator::Patch - 1yqv:L.152 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.121
DataSet::Creator::Patch - 1yqv:L.121 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.182
DataSet::Creator::Patch - 1yqv:L.182 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.124
DataSet::Creator::Patch - 1yqv:L.124 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.103
DataSet::Creator::Patch - 1yqv:L.103 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.92
DataSet::Creator::Patch - 1yqv:L.92 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.123
DataSet::Creator::Patch - 1yqv:L.123 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.40
DataSet::Creator::Patch - 1yqv:L.40 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.77
DataSet::Creator::Patch - 1yqv:L.77 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.157
DataSet::Creator::Patch - 1yqv:L.157 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.119
DataSet::Creator::Patch - 1yqv:L.119 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.50
DataSet::Creator::Patch - 1yqv:L.50 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.137
DataSet::Creator::Patch - 1yqv:L.137 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.142
DataSet::Creator::Patch - 1yqv:L.142 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.12
DataSet::Creator::Patch - 1yqv:L.12 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.180
DataSet::Creator::Patch - 1yqv:L.180 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.7
DataSet::Creator::Patch - 1yqv:L.7 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.169
DataSet::Creator::Patch - 1yqv:L.169 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.147
DataSet::Creator::Patch - 1yqv:L.147 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.109
DataSet::Creator::Patch - 1yqv:L.109 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.24
DataSet::Creator::Patch - 1yqv:L.24 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.112
DataSet::Creator::Patch - 1yqv:L.112 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.45
DataSet::Creator::Patch - 1yqv:L.45 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.188
DataSet::Creator::Patch - 1yqv:L.188 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.184
DataSet::Creator::Patch - 1yqv:L.184 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.165
DataSet::Creator::Patch - 1yqv:L.165 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.81
DataSet::Creator::Patch - 1yqv:L.81 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.212
DataSet::Creator::Patch - 1yqv:L.212 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.22
DataSet::Creator::Patch - 1yqv:L.22 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.110
DataSet::Creator::Patch - 1yqv:L.110 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.38
DataSet::Creator::Patch - 1yqv:L.38 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.27
DataSet::Creator::Patch - 1yqv:L.27 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.1
DataSet::Creator::Patch - 1yqv:L.1 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.76
DataSet::Creator::Patch - 1yqv:L.76 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.53
DataSet::Creator::Patch - 1yqv:L.53 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.203
DataSet::Creator::Patch - 1yqv:L.203 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.91
DataSet::Creator::Patch - 1yqv:L.91 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.206
DataSet::Creator::Patch - 1yqv:L.206 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.114
DataSet::Creator::Patch - 1yqv:L.114 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.9
DataSet::Creator::Patch - 1yqv:L.9 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.79
DataSet::Creator::Patch - 1yqv:L.79 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.170
DataSet::Creator::Patch - 1yqv:L.170 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.199
DataSet::Creator::Patch - 1yqv:L.199 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.211
DataSet::Creator::Patch - 1yqv:L.211 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.46
DataSet::Creator::Patch - 1yqv:L.46 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.39
DataSet::Creator::Patch - 1yqv:L.39 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.108
DataSet::Creator::Patch - 1yqv:L.108 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.154
DataSet::Creator::Patch - 1yqv:L.154 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.176
DataSet::Creator::Patch - 1yqv:L.176 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.29
DataSet::Creator::Patch - 1yqv:L.29 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.52
DataSet::Creator::Patch - 1yqv:L.52 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.153
DataSet::Creator::Patch - 1yqv:L.153 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.15
DataSet::Creator::Patch - 1yqv:L.15 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.190
DataSet::Creator::Patch - 1yqv:L.190 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.118
DataSet::Creator::Patch - 1yqv:L.118 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.183
DataSet::Creator::Patch - 1yqv:L.183 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.151
DataSet::Creator::Patch - 1yqv:L.151 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.69
DataSet::Creator::Patch - 1yqv:L.69 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.41
DataSet::Creator::Patch - 1yqv:L.41 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.156
DataSet::Creator::Patch - 1yqv:L.156 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.122
DataSet::Creator::Patch - 1yqv:L.122 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.187
DataSet::Creator::Patch - 1yqv:L.187 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.143
DataSet::Creator::Patch - 1yqv:L.143 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.80
DataSet::Creator::Patch - 1yqv:L.80 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.3
DataSet::Creator::Patch - 1yqv:L.3 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.67
DataSet::Creator::Patch - 1yqv:L.67 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.128
DataSet::Creator::Patch - 1yqv:L.128 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.201
DataSet::Creator::Patch - 1yqv:L.201 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.18
DataSet::Creator::Patch - 1yqv:L.18 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.135
DataSet::Creator::Patch - 1yqv:L.135 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.160
DataSet::Creator::Patch - 1yqv:L.160 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.93
DataSet::Creator::Patch - 1yqv:L.93 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.161
DataSet::Creator::Patch - 1yqv:L.161 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.60
DataSet::Creator::Patch - 1yqv:L.60 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.204
DataSet::Creator::Patch - 1yqv:L.204 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.126
DataSet::Creator::Patch - 1yqv:L.126 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.63
DataSet::Creator::Patch - 1yqv:L.63 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.167
DataSet::Creator::Patch - 1yqv:L.167 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.57
DataSet::Creator::Patch - 1yqv:L.57 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.205
DataSet::Creator::Patch - 1yqv:L.205 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.197
DataSet::Creator::Patch - 1yqv:L.197 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.200
DataSet::Creator::Patch - 1yqv:L.200 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.164
DataSet::Creator::Patch - 1yqv:L.164 - new child DataSet::Instance
DataSet::Creator::Chain - 1yqvL - new child DataSet::Creator::Patch - 1yqv:L.32
DataSet::Creator::Patch - 1yqv:L.32 - new child DataSet::Instance
Preparing data sets for testing ...
done
Running random forest ... done
1yqv:L:98: 0.782
1yqv:L:189: 0.427
1yqv:L:26: 0.295
1yqv:L:10: 0.249
1yqv:L:87: 0.336
1yqv:L:65: 0.264
1yqv:L:158: 0.306
1yqv:L:145: 0.346
1yqv:L:17: 0.305
1yqv:L:43: 0.383
1yqv:L:107: 0.428
1yqv:L:54: 0.239
1yqv:L:14: 0.322
1yqv:L:207: 0.618
1yqv:L:68: 0.233
1yqv:L:66: 0.32
1yqv:L:56: 0.119
1yqv:L:59: 0.304
1yqv:L:95: 0.743
1yqv:L:116: 0.669
1yqv:L:149: 0.411
1yqv:L:210: 0.33
1yqv:L:208: 0.207
1yqv:L:202: 0.372
1yqv:L:44: 0.423
1yqv:L:162: 0.521
1yqv:L:0: 0.544
1yqv:L:168: 0.409
1yqv:L:100: 0.01
1yqv:L:8: 0.301
1yqv:L:31: 0.262
1yqv:L:94: 0.72
1yqv:L:49: 0.133
1yqv:L:16: 0.34
1yqv:L:70: 0.291
1yqv:L:42: 0.427
1yqv:L:127: 0.395
1yqv:L:138: 0.338
1yqv:L:163: 0.257
1yqv:L:5: 0.08
1yqv:L:20: 0.364
1yqv:L:152: 0.36
1yqv:L:121: 0.204
1yqv:L:182: 0.365
1yqv:L:124: 0.327
1yqv:L:103: 0.298
1yqv:L:92: 0.6
1yqv:L:123: 0.335
1yqv:L:40: 0.354
1yqv:L:77: 0.319
1yqv:L:157: 0.291
1yqv:L:119: 0.155
1yqv:L:50: 0.03
1yqv:L:137: 0.355
1yqv:L:142: 0.107
1yqv:L:12: 0.396
1yqv:L:180: 0.383
1yqv:L:7: 0.133
1yqv:L:169: 0.423
1yqv:L:147: 0.354
1yqv:L:109: 0.406
1yqv:L:24: 0.257
1yqv:L:112: 0.329
1yqv:L:45: 0.355
1yqv:L:188: 0.391
1yqv:L:184: 0.424
1yqv:L:165: 0.292
1yqv:L:81: 0.322
1yqv:L:212: 0.357
1yqv:L:22: 0.224
1yqv:L:110: 0.427
1yqv:L:38: 0.432
1yqv:L:27: 0.523
1yqv:L:1: 0.621
1yqv:L:76: 0.329
1yqv:L:53: 0.251
1yqv:L:203: 0.312
1yqv:L:91: 0.649
1yqv:L:206: 0.337
1yqv:L:114: 0.686
1yqv:L:9: 0.514
1yqv:L:79: 0.243
1yqv:L:170: 0.356
1yqv:L:199: 0.437
1yqv:L:211: 0.41
1yqv:L:46: 0.052
1yqv:L:39: 0.419
1yqv:L:108: 0.426
1yqv:L:154: 0.297
1yqv:L:176: 0.538
1yqv:L:29: 0.54
1yqv:L:52: 0.297
1yqv:L:153: 0.42
1yqv:L:15: 0.383
1yqv:L:190: 0.348
1yqv:L:118: 0.004
1yqv:L:183: 0.4
1yqv:L:151: 0.418
1yqv:L:69: 0.33
1yqv:L:41: 0.417
1yqv:L:156: 0.184
1yqv:L:122: 0.387
1yqv:L:187: 0.426
1yqv:L:143: 0.39
1yqv:L:80: 0.407
1yqv:L:3: 0.11
1yqv:L:67: 0.31
1yqv:L:128: 0.43
1yqv:L:201: 0.27
1yqv:L:18: 0.315
1yqv:L:135: 0.003
1yqv:L:160: 0.003
1yqv:L:93: 0.549
1yqv:L:161: 0.205
1yqv:L:60: 0.213
1yqv:L:204: 0.263
1yqv:L:126: 0.427
1yqv:L:63: 0.33
1yqv:L:167: 0.393
1yqv:L:57: 0.23
1yqv:L:205: 0.288
1yqv:L:197: 0.343
1yqv:L:200: 0.38
1yqv:L:164: 0.358
1yqv:L:32: 0.148
Finished!";

    return($result);
}

sub RunIntPred
{
    my ($ctrlFile, $ipbin) = @_;
    my $result = `(cd $ipbin; export WEKA_HOME=/tmp/wekahome.$$; source ../setup.sh; ./runIntPred.pl $ctrlFile)`;
    return($result);
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
    my($msg, $pdb) = @_;

    $msg = Prettify($msg, $pdb);

    print <<__EOF;
<html>
<head>
<title>IntPred Result</title>
<style type='text/css'>
.noif { }
.if {color: red}
</style>
</head>
<body>
<h1>IntPred Result</h1>
$msg
</body>
</html>
__EOF
}

sub Prettify
{
    my($in, $pdb) = @_;
    my $out = '';

    my @lines = split(/\n/, $in);
    @lines = grep(!/^DataSet/, @lines);
    @lines = grep(!/^Preparing/, @lines);
    @lines = grep(!/^Running/, @lines);
    @lines = grep(!/^Finished/, @lines);
    @lines = grep(!/^done/, @lines);

    # Anything that isn't the results
    my @warnings = grep(!/^$pdb/, @lines);
    if(scalar(@warnings))
    {
        $out .= "<h2>Errors/Warnings</h2>\n";
        $out .= "<ul>\n";

        foreach my $warning (@warnings)
        {
            if(($warning =~ /FOSTA/) || ($warning =~ /BLAST/))
            {
                my $theWarning = $warning;
                if(($theWarning =~ /^(.*FOSTA.*?):/) ||
                   ($theWarning =~ /^(.*BLAST.*?):/))
                {
                    $out .= "<li>Warning: $1</li>\n";
                }
                if(($theWarning =~ /:\s(.*FOSTA.*?):/) ||
                   ($theWarning =~ /:\s(.*BLAST.*?):/))
                {
                    $out .= "<li>Warning: $1</li>\n";
                }
            }
            else
            {
                $out .= "<li>$warning</li>\n";
            }
        }

        $out .= "</ul>\n";
    }

    # The results
    @lines = grep(/^$pdb/, @lines);
    if(scalar(@lines))
    {
        $out .= "<h2>Results</h2>\n";
        $out .= "<table>\n";
        $out .= "<tr><th>PDB</th><th>Chain</th><th>Score</th><th>&nbsp;</th></tr>\n";
        my $data = '';
        foreach my $line (@lines)
        {
            my @fields = split(/\s+/, $line);
            my @parts  = split(/:/, $fields[0]);
            my $class  = 'noif';
            my $isIF   = '(Not interface)';
            if($fields[1] > 0.5)
            {
                $class = 'if';
                $isIF = '(Interface)';
            }
            $data .= "<tr class='$class'><td>$parts[0]</td><td>$parts[1]$parts[2]</td><td> $fields[1] </td><td>$isIF</td></tr>\n";
        }

        $data = `echo "$data" | sort -r -k 3 -n`;

        $out .= $data . "</table>";
    }

    return($out);
}

