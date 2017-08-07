### NOTE! You must run this as root OR have sudo permissions ###
TCNLIBVERSION=0.1

if [ "TEST" == "TEST$1" ]; then
  PERL=/usr/bin/perl
else
  PERL=$1
fi

H=`pwd`

# System preliminaries
if [ 'x' == 'y' ]; then
##########################################################
### Comment this out if you have installed expat using ###
### another package manager (i.e. you don't have yum)  ###
##########################################################
sudo yum -y install expat

sudo $PERL -MCPAN -e shell <<EOF
install CPAN
reload cpan
install Module::Build
o conf prefer_installer MB
o conf commit
EOF
fi

# Install other dependencies
sudo $PERL ./installScripts/getperldeps.pl
# Install BioPerl
sudo $PERL ./installScripts/installBioperl.pl -perl=$PERL
# Download the WEKA model file
./installScripts/getIntPredModel.sh

# TCNlib
cd packages
tar xvf TCNlib-${TCNLIBVERSION}.tar.gz
cd TCNlib-${TCNLIBVERSION}

./setup.pl
export TCNlib=`pwd`
export PERL5LIB="$TCNlib:$PERL5LIB"

./runtests.pl  # This needs PyMol

