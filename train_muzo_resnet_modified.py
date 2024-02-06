from import_shelf import shelf
from shelf.trainers import adjust_learning_rate, train, train_zo_rge, train_zo_cge, validate
from shelf.dataloaders import get_MNIST_dataset, get_CIFAR10_dataset
from shelf.models.mutable import MutableResNet18

import torch
import torch.nn as nn
import torch.optim
import torch.utils.data

### line added start(1/2) ###
import argparse
parser = argparse.ArgumentParser(description='Example script to demonstrate argparse with default values.')

'''add any hyperparameter to tune here'''
parser.add_argument('--hyper_param', type=str, help='hyper parameter to tune', default='SMOOTHING')
parser.add_argument('--current_val', type=str, help='current hyper parameter value', default='0.005')
parser.add_argument('--hyper_param_list', type=str, help='list of hyperparameters to tune', default=[])
parser.add_argument('--val_list', type=str, help='list of current hyper parameter values', default=[])

'''get the usage type(do not modify this line)'''
parser.add_argument('--usage_type', type=int, help='1: single hyperparameter, 2: multiple hyperparameters', default=1)
args = parser.parse_args()
### line added end(1/2) ###

# hyperparameters
ModelClass = MutableResNet18

EPOCHS = 100 #tunable
BATCH_SIZE = 128
LEARNING_RATE = 0.01
MOMENTUM = 0.0
DAMPENING = 0
WEIGHT_DECAY = 5e-4
NESTEROV = False

now_growth = 8
TOTAL_GROWTH = 512

SMOOTHING = 5e-3 ## main var 1
NUM_QUERY = 8 ## main var 2
GROW_FREQ = 10 ## main var 3

### line added start(2/2) ###
if args.usage_type == 1:
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
    hl_tmp = args.hyper_param_list[1:-1]
    hyper_param_list = [s.strip() for s in hl_tmp.split(',')]
    vl_tmp = args.val_list[1:-1]
    val_list = [s.strip() for s in vl_tmp.split(',')]
    val_list = [float(v) for v in val_list]
    for i in range(len(hyper_param_list)):
        if hyper_param_list[i] == 'SMOOTHING':
            SMOOTHING = val_list[i]
        elif hyper_param_list[i] == 'NUM_QUERY':
            NUM_QUERY = int(val_list[i])
        elif hyper_param_list[i] == 'GROW_FREQ':
            GROW_FREQ = int(val_list[i])
        else:
            raise ValueError('Invalid hyper parameter')
### line added end(2/2) ###

NUM_CLASSES = 10

DEVICE = 'cuda'

# model, criterion, optimizer
# model_vgg = ModelClass(input_size=28, input_channel=1, num_output=NUM_CLASSES)
model_resnet = ModelClass(input_size=32, input_channel=3, num_output=NUM_CLASSES, shrink_ratio=now_growth/TOTAL_GROWTH)
model_resnet = model_resnet.cuda()
num_params = sum(p.numel() for p in model_resnet.parameters() if p.requires_grad)
print(model_resnet)
print(f'>> Number of parameters: {num_params}')

print('Hyperparameters:')
print(f'>> EPOCHS: {EPOCHS}')
print(f'>> BATCH_SIZE: {BATCH_SIZE}')
print(f'>> LEARNING_RATE: {LEARNING_RATE}')
print(f'>> SMOOTHING: {SMOOTHING}')
print(f'>> MOMENTUM: {MOMENTUM}')
print(f'>> DAMPENING: {DAMPENING}')
print(f'>> WEIGHT_DECAY: {WEIGHT_DECAY}')
print(f'>> NESTEROV: {NESTEROV}')
print(f'>> NUM_QUERY: {NUM_QUERY}')
print(f'>> NUM_CLASSES: {NUM_CLASSES}')
print(f'>> GROW_FREQ: {GROW_FREQ}')
print(f'>> DEVICE: {DEVICE}')

criterion = nn.CrossEntropyLoss()
optimizer = torch.optim.SGD(model_resnet.parameters(), LEARNING_RATE, momentum=MOMENTUM, dampening=DAMPENING, weight_decay=WEIGHT_DECAY, nesterov=NESTEROV)
# optimizer = torch.optim.Adam(model_vgg.parameters(), LR_PERTURB, weight_decay=WEIGHT_DECAY)

scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=EPOCHS, eta_min=1e-5)

best_val_acc = 0

# load dataset
# train_loader, val_loader = get_MNIST_dataset(batch_size=BATCH_SIZE)
train_loader, val_loader = get_CIFAR10_dataset(batch_size=BATCH_SIZE)


print(f'========== Train with ZO: {ModelClass.__name__} ==========')

for epoch in range(EPOCHS):
    epoch_lr = scheduler.get_last_lr()[0]

    # train for one epoch
    train_acc, train_loss = train_zo_rge(train_loader, model_resnet, criterion, optimizer, epoch, smoothing=SMOOTHING, query=NUM_QUERY)

    # evaluate on validation set
    val_acc, val_loss = validate(val_loader, model_resnet, criterion, epoch)

    # step scheduler
    scheduler.step()

    # print training/validation statistics
    print(
        'Epoch: {0}/{1}\t'
        'LR: {lr:.6f}\t'
        'Train Accuracy {train_acc:.3f}\t'
        'Train Loss {train_loss:.3f}\t'
        'Val Accuracy {val_acc:.3f}\t'
        'Val Loss {val_loss:.3f}'
        .format(
            epoch + 1, EPOCHS, lr=epoch_lr, train_acc=train_acc, train_loss=train_loss, val_acc=val_acc, val_loss=val_loss
        )
    )

    # record best validation accuracy
    if val_acc > best_val_acc:
        best_val_acc = val_acc

    if epoch % GROW_FREQ == GROW_FREQ - 1 and now_growth < TOTAL_GROWTH:
        now_growth += 1
        model_resnet.grow_tobe(now_growth / TOTAL_GROWTH)

        optimizer = torch.optim.SGD(model_resnet.parameters(), LEARNING_RATE, momentum=MOMENTUM, dampening=DAMPENING, weight_decay=WEIGHT_DECAY, nesterov=NESTEROV)
        scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=EPOCHS, eta_min=1e-5)
        for _ in range(epoch + 1):
            scheduler.step()

        num_params = sum(p.numel() for p in model_resnet.parameters() if p.requires_grad)
        print(f'grown to {num_params} parameters ({now_growth}/{TOTAL_GROWTH})')

    

# result
print(f'>> Best Validation Accuracy {best_val_acc:.3f}')
print('')

