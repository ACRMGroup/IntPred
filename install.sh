### NOTE! You must run this as root OR have sudo permissions ###
H=`pwd`

# System preliminaries
if [ 'x' == 'y' ]; then
sudo yum -y install perl-App-cpanminus expat
sudo perl -MCPAN -e shell <<EOF
install CPAN
reload cpan
install Module::Build
o conf prefer_installer MB
o conf commit
EOF
sudo cpanm Bio::Perl
fi


# TCNlib
cd packages
unzip TCNlib-master.zip
cd TCNlib-master

# Temp fix until Tom has fixed it!a
sed 's/www.bioinf.org.uk\/intpred\/packages/www.bioinf.org.uk\/intpred\/src\/packages/' getexternalpackages > foo
mv foo getexternalpackages
chmod +x getexternalpackages

./setup.pl
./runtests.pl
# This needs PyMol

