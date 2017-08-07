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

This will use the version of perl in `/usr/bin/perl`. If you wish to
use a different perl install then you should do:

```./install.sh /path/to/perl```

Now test the install with

```./runTests.sh```


## What happens during the install...

1. `expat` is installed using `yum`. See below if you are using a
system other than RedHat/CentOS/Fedora.

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
installation tool. This is used only to install `expat`. If you are
using another Linux version, then install `expat` using your package
manager (e.g. `apt-get`) and comment out the line:

```sudo yum -y install expat```