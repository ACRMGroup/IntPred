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

echo "export TCNlib=$H/packages/TCNlib-${TCNLIBVERSION}" >  $H/setup.sh
echo "export PERL5LIB=$TCNlib/lib:$PERL5LIB"             >> $H/setup.sh
echo "export DATADIR=$TCNlib/data"                       >> $H/setup.sh
export TCNlib=$H/packages/TCNlib-${TCNLIBVERSION}
export PERL5LIB=$TCNlib/lib:$PERL5LIB
export DATADIR=$TCNlib/data


# System preliminaries
if promptUser "Install system files and update CPAN?"; then
    ##########################################################
    ### Comment this out if you have installed expat using ###
    ### another package manager (i.e. you don't have yum)  ###
    ##########################################################
    sudo yum -y install expat wget libxml2 libxml2-devel

    sudo $PERL -MCPAN -e shell <<EOF
install CPAN
reload cpan
install Module::Build
o conf prefer_installer MB
o conf commit
EOF
fi

if promptUser "Install Perl dependencies including BioPerl?"; then
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
    fi
fi


exit

/disk1/home/amartin/git/IntPred/packages/TCNlib-0.1/bin/chaincontacts
/disk1/home/amartin/git/IntPred/packages/TCNlib-0.1/data/kyte.hpb
