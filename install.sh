### NOTE! You must run this as root OR have sudo permissions ###
H=`pwd`
PERLDIR=/usr/bin
PERL=$PERLDIR/perl
CPANM=$PERLDIR/cpanm
TCNLIBVERSION=0.1

# System preliminaries
if [ 'x' == 'y' ]; then
sudo curl -L https://cpanmin.us | $PERL - --sudo App::cpanminus
if [ ! -x $CPANM ]; then
   sudo cp /usr/local/bin/cpanm $CPANM
fi
sudo yum -y install expat
sudo $PERL -MCPAN -e shell <<EOF
install CPAN
reload cpan
install Module::Build
o conf prefer_installer MB
o conf commit
EOF
sudo $CPANM Bio::Perl
fi


# TCNlib
cd packages
tar xvf TCNlib-${TCNLIBVERSION}.tar.gz
cd TCNlib-${TCNLIBVERSION}

./setup.pl
export TCNlib=`pwd`
export PERL5LIB="$TCNlib:$PERL5LIB"
./runtests.pl
# This needs PyMol

