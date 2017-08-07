H=`pwd`

# System preliminaries
sudo yum -y install perl-App-cpanminus expat
sudo perl -MCPAN -e shell <<EOF
install CPAN
reload cpan
install Module::Build
o conf prefer_installer MB
o conf commit
EOF
sudo cpanm Bio::Perl

# TCNlib
cd packages
unzip TCNlib-master.zip
cd TCNlib-master
