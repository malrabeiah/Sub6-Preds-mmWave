# Sub-6 Predicts mmWave Beam-forming Vectors:
This is an implementation of the Deep Learning (DL) solution that uses sub-6 GHz channels to predict top-n beams of mmWave users. With the approperiate modifications and given the right dataset, it could also be used to generate all the figures in [Deep Learning for mmWave Beam and Blockage Prediction Using Sub-6GHz Channels](https://ieeexplore.ieee.org/document/9121328).

# Requirements:

Essential:

1- MATLAB deep learning toolbox.

2- [DeepMIMO dataset](https://deepmimo.net/)

Optional:

1- NVIDIA GPU card.

2- CUDA toolkit.

3- cuDNN package.

# Running Instructions:

1- Generate the datasets using scenarios [O1_28](https://deepmimo.net/scenarios/o1-scenario/) and [O1_3p5](https://deepmimo.net/scenarios/o1-scenario/) in the DeepMIMO dataset. Use the parameters listed in Table.1, Section VII-B of [the paper](https://ieeexplore.ieee.org/document/9121328).

2- Prepare two MATLAB structures, one for sub-6GHz data and the other for 28GHz. Please refer to the comments at the beginning of main.m for more information on the data structures.

3- Assign the paths to the two MATLAB structures to the two parameters: options.dataFile1 and options.dataFile2 in the beginning of main.m.

4- Run main.m to get the figure 4-b in the paper.

REMARK: Transmit power range is defined in tx_power in main.m.

# Citation:

If you use these codes or a modified version of them, please cite the following work:
```
@ARTICLE{Alrabeiah2020,
  author={Alrabeiah, Muhammad and Alkhateeb, Ahmed},
  journal={IEEE Transactions on Communications}, 
  title={Deep Learning for mmWave Beam and Blockage Prediction Using Sub-6 GHz Channels}, 
  year={2020},
  volume={68},
  number={9},
  pages={5504-5518},
  doi={10.1109/TCOMM.2020.3003670}}
```

# License:

This code package is licensed under a [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License](https://creativecommons.org/licenses/by-nc-sa/4.0/)

