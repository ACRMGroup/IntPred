### NOTE! You must run this as root OR have sudo permissions ###
H=`pwd`
PERL=/usr/bin/perl
TCNLIBVERSION=0.1

# System preliminaries
if [ 'x' == 'x' ]; then
sudo yum -y install expat
sudo $PERL -MCPAN -e shell <<EOF
install CPAN
reload cpan
install Module::Build
o conf prefer_installer MB
o conf commit
EOF
fi

# Install BioPerl
sudo $PERL ./install-bioperl.pl -perl=$PERL

# TCNlib
cd packages
tar xvf TCNlib-${TCNLIBVERSION}.tar.gz
cd TCNlib-${TCNLIBVERSION}

./setup.pl
export TCNlib=`pwd`
export PERL5LIB="$TCNlib:$PERL5LIB"

./runtests.pl  # This needs PyMol

