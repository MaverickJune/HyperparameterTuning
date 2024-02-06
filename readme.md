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

2. `example.py` serves as a demonstration of the format required to launch the script. Please review this file for guidance. You can directly launch the script with `example.py`.

3. There are two main ways to launch this script:
   - **Option 1:** By specifying individual hyperparameters:
     ```
     ./tuning_script.sh [--hyper_param=value] [--base_val=value] [--delta=value] [--mode=mode] [--num_iter=value] [--train_script=path]
     ```
   - **Option 2:** By specifying lists of hyperparameters and their corresponding values:
     ```
     ./tuning_script.sh [--hyper_param_list=[param1,param2,...]] [--val_list=[[val1,val2,...],[val3,val4,...],...]] [--train_script=path]
     ```
   For more detailed information on the script's options, simply run `./tuning_script.sh`.

4. For a real-life script example, see `train_muzo_resnet_modified.py`. Although not directly launchable through the script, it can be executed using "torchshelf". Pay special attention to the "line-added-start/end(x/2)" section for integration details.

5. The .txt file located in the results section contains actual experiment results generated with this bash script. It serves as a practical example of the script's output.

## Note
I hope you find this script useful for your hyperparameter tuning tasks!

