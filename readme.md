# Hyperparameter Tuning

## Description
Hyperparameter Searching Automation using a bash script.

## Installation Instructions
To get started, you'll need to install the required Python package. Run the following command:

pip install argparse


## Usage
This script is designed to be straightforward to use, with detailed instructions available via the `--help` option. Below are the steps to utilize this script effectively:

1. For a comprehensive list of options and usage instructions, execute:

./tuning_script.sh --help

2. To understand the format required to launch the script, please refer to `example.py`. This example demonstrates how to properly set up your Python file for use with the script.

3. There are two ways to launch this script:
   1. ./tuning_script.sh [--hyper_param=value] [--base_val=value] [--delta=value] [--mode=mode] [--num_iter=value] [--train_script=path]
   2. ./tuning_script.sh [--hyper_param_list=[param1,param2,...]] [--val_list=[[val1,val2,...],[val3,val4,...],...]] [--train_script=path]
   for more information, just run ./tuning_script.sh

4. For a real-life application of this script, see `train_muzo_resnet_modified.py`. Although this file is not directly executable (but can be executed with `torchshelf`), it serves as an excellent example of how to integrate the script into your workflow. Pay special attention to the "added codeline(x/2)" section for modifications specific to this use case.

5. The results of your experiments will be saved in a `.txt` file within the result section, showcasing the practical outcomes achieved with this bash script.

Enjoy optimizing your machine learning models with our Hyperparameter Tuning script!

