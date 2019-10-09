# Sub-6 Predicts mmWave Beam-forming Vectors:
This is a Deep Learning (DL) solution that uses sub-6 GHz channels to predict top-n beams and link status of mmWave users.

# Requirements:

Essential:

1- MATLAB deep learning toolbox.

2- [DeepMIMO dataset](http://www.deepmimo.net/?i=1)

Optional:

1- NVIDIA GPU card.

2- CUDA toolkit.

3- cuDNN package.

# Running the codes:

The raw sub-6 and mmWave data files must be genherated first using [DeepMIMO dataset](http://www.deepmimo.net/?i=1). Refer to the notes at the beginning of main.m to learn more about how the raw data is structured. Once the data is ready, add the paths to the two data files to the fields: options.dataFile1 and options.dataFile2, and run the script. It will evantually generate a figure of the SNR versus top-1 and top-3 spectral efficiencies.

# Citation:

If you use these codes or a modified version of them, please cite the following work:

