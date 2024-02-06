# Hyperparameter Tuning

## Description
Hyperparameter Searching Automation using a bash script.

## Installation Instructions
To get started, you'll need to install the required Python package. Run the following command:

pip install argparse


## Usage
This script is designed to be straightforward to use, with detailed instructions available via the `--help` option. Below are the steps to utilize this script effectively:

1. For a comprehensive list of options and usage instructions, execute:
   ```
   ./tuning_script.sh --help
   ```
2. `example.py` serves as a demonstration of the format required to launch the script. Please review this file for guidance. You can directly launch the script with `example.py`.

3. There are two main ways to launch this script:
   - **Option 1:** By specifying individual hyperparameters:
     ```
     ./tuning_script.sh --hyper_param=value --base_val=value --delta=value --mode=mode --num_iter=value --train_script=path
     ```
   - **Option 2:** By specifying lists of hyperparameters and their corresponding values:
     ```
     ./tuning_script.sh --hyper_param_list=[param1,param2,...] --val_list=[[val1,val2,...],[val3,val4,...],...] --train_script=path
     ```
   - **Real Usage Examples** 
     ```
     ./tuning_script.sh --hyper_param=SMOOTHING --base_val=1 --delta=2 --mode=2 --num_iter=10 --train_script=example.py
     ```
     ```
     ./tuning_script.sh --hyper_param_list=[SMOOTHING,NUM_QUERY] --val_list=[[1,2],[3,4]] --train_script=example.py
     ```
   For more detailed information on the script's options, simply run `./tuning_script.sh`.
4. All the test results will be stored in a subdirectory `./result`. If `./result` doesn't exist, it will automatically be created.

## Note
I hope you find this script useful for your hyperparameter tuning tasks!

