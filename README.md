# About

IntPred is a library for the prediction of protein-protein interface sites from PDB structures. The library can be used to generate features from PDB files, create datasets, train and/or test a learner and generate prediction labels for unlabelled protein structures.

# Set-up

1. IntPred relies on [TCNlib](https://github.com/northeyt/TCNlib). Setting up TCNlib and its dependencies is most of the work.

2. Run `getperldeps.pl` to check for perl dependencies and install any that are missing.

3. Run `runTests.sh`.

To run the main IntPred predictor, you need the WEKA model file. Run `getIntPredModel.sh` to grab this and decompress it.