IntPred
=======

## About

IntPred is a library for the prediction of protein-protein interface
sites from PDB structures. The library can be used to generate
features from PDB files, create datasets, train and/or test a learner
and generate prediction labels for unlabelled protein structures.

## Installation - Quick Guide

```
wget https://github.com/ACRMGroup/IntPred/archive/v0.5.tar.gz
tar xvf v0.5.tar.gz
cd IntPred-0.5
./install.pl
source ./setup.sh
```

## Installation

The install script assumes you are using *RedHat/CentOS/Fedora*. See
below if you are not.

You need to have `sudo` permissions or do the install as `root`.

You are recommended to update your operating system before attempting
an install with:

```yum update```

If you haven't previously used CPAN to install Perl modules, you may
need to do the following:

```sudo /usr/bin/perl -MCPAN -e shell```

Simply accept all the defaults, and when asked for a CPAN mirror, you
can select one from http://www.cpan.org/SITES.html - for example
ftp://mirror.ox.ac.uk/sites/www.cpan.org/

Then enter
```
o conf commit
quit
```



Simply run the `install.sh` script:

```./install.sh```

Simply press return to accept all defaults on the initial install.
When reinstalling you can skip some of the stages if needed.

The deault install will use the version of perl in `/usr/bin/perl`. If
you wish to use a different perl install then you should do:

```./install.sh /path/to/perl```

Now test the install with

```./runTests.sh```

See below for more details of what happens during the install.

## Running IntPred

1. First you need to set environment variables and add the bin
directory to your path:

```source ./setup.sh```

2. IntPred currently only works with files deposited in the PDB and is
designed to be able to be run on multiple PDB files in one go. This is done by creating a control file containing, in its simplest form a single line:

```pdb : chain : exclchain```

For example:

```1aut : C : L```

If this line is stored in `1autC.dat`, the program is then run by typing:

```
cd $INTPREDBIN
./runIntPred.pl /path/to/1autC.dat > /path/to/1autC.out
```

*Note that you must be in the $INTPREDBIN directory to run the program.*

This would predict on chain C of PDB file 1aut ignoring chain
L. `exclchain` may be blank if no chains are to be ignored.

For full details simply run:

```runIntPred.pl```


## What happens during the install...

1. `expat`, `wget`, `perl-CPAN`, `libxml2`, `libxml2-devel` and
`java-1.8.0-openjdk` are installed using `yum`. See below if you are
using a system other than RedHat/CentOS/Fedora.

2. CPAN is updated and the Module::Build module is installed. Other
Perl dependencies are then installed using CPAN including Moose and
the latest version of BioPerl.

3. The trained WEKA model for the predictor is downloaded.

4. The distribution includes
[TCNlib](https://github.com/northeyt/TCNlib) and this is unpacked,
installed and tested. This downloads a number of other necessary
packages. 


## I am not using *RedHat/CentOS/Fedora*. What do I do?

The only requirement for RedHat-style Linux is for the yum
installation tool. This is used only to install `expat`, `wget`,
`perl-CPAN`, `libxml2`, `libxml2-devel` and `java-1.8.0-openjdk`. If
you are using another Linux version then, from the install.sh script,
comment out the line:

```sudo yum -y install expat wget perl-CPAN libxml2 libxml2-devel java-1.8.0-openjdk```

Install these packages using your package manager (e.g. `apt-get`) and
then run the install script.

## Installation problems

If you get repeated errors during Perl CPAN installs along the lines of

```CPAN::Meta::Requirements not available at ...```

then you may need to install this module manually. Download and install with:

```
cd /var/tmp
wget http://www.cpan.org/authors/id/D/DA/DAGOLDEN/CPAN-Meta-Requirements-2.140.tar.gz
tar xvf CPAN-Meta-Requirements-2.140.tar.gz
cd CPAN-Meta-Requirements-2.140
perl Makefile.PL
make all
make test && sudo make install
```

then re-run `install.sh`

Note that all tests on TCNlib should pass (except the ones that
require PyMol if you don't have that installed). If they don't then
something has probably gone wrong with the Perl module installs. Check
for error messages and then use CPAN to install the missing modules;
if there have been problems with `CPAN-Meta-Requirements` then you
will probably have to do this one at a time checking the dependencies
manually.
