# Sub-6 Predicts mmWave Beam-forming Vectors:
This is a Deep Learning (DL) solution that uses sub-6 GHz channels to predict top-n beams and link status of mmWave users. See [Deep Learning for mmWave Beam and Blockage Prediction Using Sub-6GHz Channels](https://arxiv.org/abs/1910.02900)

# Requirements:

Essential:

1- MATLAB deep learning toolbox.

2- [DeepMIMO dataset](http://www.deepmimo.net/?i=1)

Optional:

1- NVIDIA GPU card.

2- CUDA toolkit.

3- cuDNN package.

# Running Instructions:

The raw sub-6 and mmWave data files must be generated first using [DeepMIMO dataset](http://www.deepmimo.net/?i=1). Refer to the notes at the beginning of main.m to learn more about how the raw data is structured. Once the data is ready, add the paths to the two data files to the fields: options.dataFile1 and options.dataFile2, and run the script. It will evantually generate a figure of the top-1 and top-3 spectral efficiencies versus SNR.

1- Generate the datasets using the scenarios O1_28 and O1_3p5 from DeepMIMO. Use the parameters illustrated in Table.1 in Section VII-B of [the paper](“https://arxiv.org/abs/1910.02900”).

2- Prepare two MATLAB structures, one for the sub-6GHz data and the other for 28GHz. Please refer to the comments at the beginning of main.m for more information on the data structures.

3- Assign the paths to the two MATLAB structures to the two parameters: options.dataFile1 and options.dataFile2 in the beginning of main.m.

4- Run main.m to get the figure 4-b in the paper.

REMARKs:
. Transmit power range is defined in tx_power in main.m.

# Citation:

If you use these codes or a modified version of them, please cite the following work:
```
@ARTICLE{2019arXiv191002900A,
       author = {{Alrabeiah}, Muhammad and {Alkhateeb}, Ahmed},
        title = "{Deep Learning for mmWave Beam and Blockage Prediction Using Sub-6GHz Channels}",
      journal = {arXiv e-prints},
     keywords = {Computer Science - Information Theory, Electrical Engineering and Systems Science - Signal Processing},
         year = "2019",
        month = "Oct",
          eid = {arXiv:1910.02900},
        pages = {arXiv:1910.02900},
archivePrefix = {arXiv},
       eprint = {1910.02900},
 primaryClass = {cs.IT},
       adsurl = {https://ui.adsabs.harvard.edu/abs/2019arXiv191002900A},
      adsnote = {Provided by the SAO/NASA Astrophysics Data System}
}
```

# License:

This code package is licensed under a [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License](https://creativecommons.org/licenses/by-nc-sa/4.0/)

