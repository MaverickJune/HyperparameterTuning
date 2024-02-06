'''example script to demonstrate hyperparameter tuning with tuning_script.sh'''
'''modify you python script for model training in this format'''
import argparse

parser = argparse.ArgumentParser(description='Example script to demonstrate argparse with default values.')

################### do not modifiy here ####################
parser.add_argument('--hyper_param', type=str, help='hyper parameter to tune', default='SMOOTHING')
parser.add_argument('--current_val', type=str, help='current hyper parameter value', default='0.005')
parser.add_argument('--hyper_param_list', type=str, help='list of hyperparameters to tune', default=[])
parser.add_argument('--val_list', type=str, help='list of current hyper parameter values', default=[])

'''get the usage type(do not modify this line)'''
parser.add_argument('--usage_type', type=int, help='1: single hyperparameter, 2: multiple hyperparameters', default=1)

args = parser.parse_args()
############################################################

# example hyperparameters(your model's hyperparmeters goes here)
SMOOTHING = 5e-3
NUM_QUERY = 8
GROW_FREQ = 10

if args.usage_type == 1: # change to your hyperparameters!
    '''parse the command line'''
    if args.hyper_param == 'SMOOTHING':
        SMOOTHING = float(args.current_val)
    elif args.hyper_param == 'NUM_QUERY':
        NUM_QUERY = int(args.current_val)
    elif args.hyper_param == 'GROW_FREQ':
        GROW_FREQ = int(args.current_val)
    else:
        raise ValueError('Invalid hyper parameter')
else:
    ################### do not modifiy here ####################
    hl_tmp = args.hyper_param_list[1:-1]
    hyper_param_list = [s.strip() for s in hl_tmp.split(',')]
    vl_tmp = args.val_list[1:-1]
    val_list = [s.strip() for s in vl_tmp.split(',')]
    val_list = [float(v) for v in val_list]
    ############################################################
    for i in range(len(hyper_param_list)): # change to your hyperparameters!
        if hyper_param_list[i] == 'SMOOTHING':
            SMOOTHING = val_list[i]
        elif hyper_param_list[i] == 'NUM_QUERY':
            NUM_QUERY = int(val_list[i])
        elif hyper_param_list[i] == 'GROW_FREQ':
            GROW_FREQ = int(val_list[i])
        else:
            raise ValueError('Invalid hyper parameter')

# example model training(your model training goes here)               
print(f'SMOOTHING:{SMOOTHING} NUM_QUERY:{NUM_QUERY} GROW_FREQ:{GROW_FREQ}')

