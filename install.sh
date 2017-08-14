### NOTE! You must run this as root OR have sudo permissions ###
TCNLIBVERSION=0.1
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

    sudo yes | $PERL -MCPAN -e shell <<EOF
install YAML
install CPAN
reload cpan
install Module::Build
o conf prefer_installer MB
o conf commit
EOF
fi

if promptUser "Install Perl dependencies including BioPerl?"; then
    sudo yes | $PERL -MCPAN -e shell <<EOF
install CPAN::Meta
install CPAN::Meta::YAML
install ExtUtils::CBuilder
install Module::Metadata
install Parse::CPAN::Meta
install Perl::OSType
install TAP::Harness
install version
EOF
    # Install other dependencies
    sudo $PERL ./installScripts/getperldeps.pl
    # Install BioPerl
    sudo $PERL ./installScripts/installBioperl.pl -perl=$PERL
fi

if promptUser "Download and install the IntPred model file?"; then
    # Download the WEKA model file
    ./installScripts/getIntPredModel.sh
fi

if promptUser "Install TCNlib and dependencies?"; then
   # TCNlib
    cd $H/packages
    tar xvf TCNlib-${TCNLIBVERSION}.tar.gz
    cd $H
    ./installScripts/fixTCNInstallDirs.sh TCNlib-${TCNLIBVERSION}
    cd $H/packages/TCNlib-${TCNLIBVERSION}
    ./setup.pl

    if promptUser "Download and install BLAST database?"; then
        ./setup-blastdb -f
    fi

    if promptUser "Install BiopTools?"; then
        cd $H/packages
        wget $BIOPTOOLSURL
        mv V${BIOPTOOLSVERSION}.tar.gz bioptools-${BIOPTOOLSVERSION}.tar.gz
        tar xvf bioptools-${BIOPTOOLSVERSION}.tar.gz
        cd $H/packages/bioptools-${BIOPTOOLSVERSION}/src
        ./makemake.pl -bioplib -prefix=${TCNlib}
        make
        make install
        cp -Rp libsrc/bioplib/data/* $TCNlib/data
    fi

    if promptUser "Run TCNlib installation tests?"; then
        cd $H/packages/TCNlib-${TCNLIBVERSION}
        ./runtests.pl  # This needs PyMol
        echo ""
        echo "*** Please note that the t/pdb/ViewPatch.t test will fail ***"
        echo "*** if you do not have PyMol installed.                   ***"
        echo ""
    fi
fi


