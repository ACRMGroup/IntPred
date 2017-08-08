# >>> Still need to install SwissProt <<< #


IntPred
=======

## About

IntPred is a library for the prediction of protein-protein interface
sites from PDB structures. The library can be used to generate
features from PDB files, create datasets, train and/or test a learner
and generate prediction labels for unlabelled protein structures.

## Installation

The install script assumes you are using *RedHat/CentOS/Fedora*. See
below if you are not.

You need to have `sudo` permissions or do the install as `root`.

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

```runIntPred.pl 1autC.dat```

This would predict on chain C of PDB file 1aut ignoring chain
L. `exclchain` may be blank if no chains are to be ignored.

For full details simply run:

```runIntPred.pl```


## What happens during the install...

1. `expat` and `wget` are installed using `yum`. See below if you are
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
installation tool. This is used only to install `expat` and `wget`. If
you are using another Linux version, then install `expat` and `wget`
using your package manager (e.g. `apt-get`) and comment out the line:

```sudo yum -y install expat wget```
