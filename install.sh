### NOTE! You must run this as root OR have sudo permissions ###
TCNLIBVERSION=0.1.2
BIOPTOOLSVERSION=1.4

if [ "TEST" == "TEST$1" ]; then
    PERL=/usr/bin/perl
else
    PERL=$1
fi

H=`pwd`
BIOPTOOLSURL="https://github.com/ACRMGroup/bioptools/archive/V${BIOPTOOLSVERSION}.tar.gz"

mkdir -p $H/data/consScores/FOSTA
mkdir -p $H/data/consScores/BLAST
mkdir -p $H/packages/TCNlib-${TCNLIBVERSION}/data/pdb-cache

promptUser()
{
    echo -n "$1 (y/n)[y]: "
    local yorn
    read yorn
    if [ "TEST" == "TEST$yorn" ] || [ $yorn == 'y' ] || [ $yorn == 'Y' ]; then
        return 0
    fi
    return 1
}

export TCNlib=$H/packages/TCNlib-${TCNLIBVERSION}
export PERL5LIB=$TCNlib/lib:$PERL5LIB
export DATADIR=$TCNlib/data
echo "export TCNlib=$H/packages/TCNlib-${TCNLIBVERSION}" >  $H/setup.sh
echo "export PERL5LIB=\$TCNlib/lib:\$PERL5LIB"           >> $H/setup.sh
echo "export DATADIR=\$TCNlib/data"                      >> $H/setup.sh
echo "export INTPREDBIN=$H/bin"                          >> $H/setup.sh
echo "export PATH=$INTPREDBIN:\$PATH"                    >> $H/setup.sh


# System preliminaries
if promptUser "Install system files and update CPAN?"; then
    ##########################################################
    ### Comment this out if you have installed expat using ###
    ### another package manager (i.e. you don't have yum)  ###
    ##########################################################
    sudo yum -y install expat wget perl-CPAN libxml2 libxml2-devel java-1.8.0-openjdk
    sudo yum -y install perl-YAML perl-Test-YAML-Valid perl-Module-Build perl-IO-CaptureOutput
    sudo yum -y install perl-Devel-Peek

    
    #    yes | sudo $PERL -MCPAN -e shell <<EOF
    #force install CPAN
    #reload cpan
    #force install YAML
    #force install Test::YAML
    #force install Module::Build
    #o conf prefer_installer MB
    #o conf commit
    #EOF
fi

if promptUser "Install Perl dependencies including BioPerl (for the Perl you are using)?"; then
    yes | sudo $PERL -MCPAN -e shell <<EOF
force install CPAN::Meta::Requirements
force install Math::VectorReal
force install Parallel::ForkManager
force install IO::CaptureOutput
force install XML::Simple
force install Statistics::PCA
force install XML::DOM
force install TryCatch
force install Test::MockObject::Extends
force install Math::MatrixReal
force install MooseX::ClassAttribute
force install Moose
force install Config::IniFiles
force install MooseX:Aliases
force install Test::Class::Moose
force install Test::Output
force install Test::NoWarnings
force install CPAN::Meta
force install CPAN::Meta::YAML
force install ExtUtils::CBuilder
force install Module::Metadata
force install Parse::CPAN::Meta
force install Perl::OSType
force install TAP::Harness
force install version
force install List::Util
force install List::MoreUtils
force install HTML::Entities 
force install File::Sort
EOF

    #force install Bio::Cluster::SequenceFamily
    #force install Bio::FeatureIO
    #force install Bio::Tools::Run::StandAloneBlast

    # Install other dependencies
    sudo $PERL ./installScripts/getperldeps.pl
    # Install BioPerl
    sudo $PERL ./installScripts/installBioperl.pl -perl=$PERL
fi

if promptUser "Download and install the IntPred model file? (Required for a new install)"; then
    # Download the WEKA model file
### CHECKME
    ./installScripts/getIntPredModel.sh
fi

if promptUser "Install TCNlib and dependencies? (Required for a new install)"; then
   # TCNlib
    cd $H/packages
    tar xvf TCNlib-${TCNLIBVERSION}.tar.gz
    cd $H
    ./installScripts/fixTCNInstallDirs.sh TCNlib-${TCNLIBVERSION}
    cd $H/packages/TCNlib-${TCNLIBVERSION}
    ./getexternalpackages
    ./getperldeps.pl
    $PERL ./setup.pl -perl=$PERL

    if promptUser "Download and install BLAST database? (Required for a new install)"; then
        ./setup-blastdb -f
    fi

    if promptUser "Install BiopTools? (Required for a new install)"; then
        cd $H/packages
        wget $BIOPTOOLSURL
        mv V${BIOPTOOLSVERSION}.tar.gz bioptools-${BIOPTOOLSVERSION}.tar.gz
        tar xvf bioptools-${BIOPTOOLSVERSION}.tar.gz
        cd $H/packages/bioptools-${BIOPTOOLSVERSION}/src
        $PERL ./makemake.pl -bioplib -prefix=${TCNlib}
        make
        make install
        cp -Rp libsrc/bioplib/data/* $TCNlib/data
    fi

    if promptUser "Run TCNlib installation tests?"; then
        cd $H/packages/TCNlib-${TCNLIBVERSION}
        $PERL ./runtests.pl  # This needs PyMol
        echo ""
        echo "*** Please note that the t/pdb/ViewPatch.t test will fail ***"
        echo "*** if you do not have PyMol installed.                   ***"
        echo ""
    fi
fi


## t/MSA.t .......................... 5/? align unsuccessful - remote run returned error cdoe 1 at t/MSA.t line 68.
## # Looks like your test exited with 2 just after 5.
## t/MSA.t .......................... Dubious, test returned 2 (wstat 512, 0x200)
## All 5 subtests passed 
## 
## 
## 
## t/pdb/BLAST.t .................... 1/? 
## #   Failed test 'use pdb::BLAST;'
## #   at t/pdb/BLAST.t line 27.
## #     Tried to use 'pdb::BLAST'.
## #     Error:  Can't locate Bio/Tools/Run/RemoteBlast.pm in @INC (you may need to install the Bio::Tools::Run::RemoteBlast module) (@INC contains: /disk1/home/amartin/git/www.bioinf.org.uk/intpred/packages/TCNlib-0.1.2/lib /home/amartin/git/www.bioinf.org.uk/intpred/packages/TCNlib-0.1.2/lib /home/amartin/scripts/lib /usr/local/lib64/perl5 /usr/local/share/perl5 /usr/lib64/perl5/vendor_perl /usr/share/perl5/vendor_perl /usr/lib64/perl5 /usr/share/perl5) at /disk1/home/amartin/git/www.bioinf.org.uk/intpred/packages/TCNlib-0.1.2/lib/pdb/BLAST.pm line 170.
## # BEGIN failed--compilation aborted at /disk1/home/amartin/git/www.bioinf.org.uk/intpred/packages/TCNlib-0.1.2/lib/pdb/BLAST.pm line 170.
## # Compilation failed in require at t/pdb/BLAST.t line 27.
## # BEGIN failed--compilation aborted at t/pdb/BLAST.t line 27.
## Can't locate object method "blastallExec" via package "pdb::BLAST::Local" at /disk1/home/amartin/git/www.bioinf.org.uk/intpred/packages/TCNlib-0.1.2/lib/pdb/BLAST.pm line 147.
## # Looks like your test exited with 255 just after 2.
## t/pdb/BLAST.t .................... Dubious, test returned 255 (wstat 65280, 0xff00)
## Failed 1/2 subtests 

## cd /home/amartin/git/www.bioinf.org.uk/intpred/packages/TCNlib-0.1.2/t/pdb
## perl BLAST.t 
