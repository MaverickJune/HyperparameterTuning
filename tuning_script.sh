#!/bin/bash

chmod +x tuning_script.sh

# Define the base directory you want to add to the PYTHONPATH
BASE_DIR=$(pwd)

# Convert the base directory to an absolute path and remove trailing slashes
BASE_DIR=$(realpath "$BASE_DIR" | sed 's:/*$::')

# Function to check if a path is in PYTHONPATH
is_path_in_pythonpath() {
    case ":$PYTHONPATH:" in
        *":$1:"*) true ;;
        *) false ;;
    esac
}

# Initialize NEW_PYTHON_PATH with the base directory if it's not already in PYTHONPATH
if ! is_path_in_pythonpath "$BASE_DIR"; then
    NEW_PYTHON_PATH="$BASE_DIR"
else
    NEW_PYTHON_PATH=""
fi

# Iterate over all directories within the base directory
while IFS= read -r -d '' d; do
    # Convert each directory to an absolute path and remove trailing slashes
    d=$(realpath "$d" | sed 's:/*$::')
    # If the directory is not already in PYTHONPATH, add it to NEW_PYTHON_PATH
    if ! is_path_in_pythonpath "$d"; then
        # Avoid adding an initial colon if NEW_PYTHON_PATH is empty
        if [ -z "$NEW_PYTHON_PATH" ]; then
            NEW_PYTHON_PATH="$d"
        else
            NEW_PYTHON_PATH="$NEW_PYTHON_PATH:$d"
        fi
    fi
done < <(find "$BASE_DIR" -type d -print0)

# Update PYTHONPATH with NEW_PYTHON_PATH if it's not empty
if [ -n "$NEW_PYTHON_PATH" ]; then
    if [ -z "$PYTHONPATH" ]; then
        export PYTHONPATH="$NEW_PYTHON_PATH"
    else
        export PYTHONPATH="$PYTHONPATH:$NEW_PYTHON_PATH"
    fi
fi

# Initialize variables
hyper_param=""
base_val=""
delta=""
mode=""
num_iter=""
train_script=""
hyper_param_list=()
hpl_print=""
val_list=()
vl_print=""

# Function to parse list
parse_list() {
    local input_string="$1"
    input_string="${input_string#[}"  # Remove leading '['
    input_string="${input_string%]}"  # Remove trailing ']'
    IFS=',' read -r -a array <<< "$input_string"
    echo "${array[@]}"
}


# Function to parse nested lists
parse_nested_list() {
    local input_string="$1"

    # Check if the input string is empty or not provided
    if [ -z "$input_string" ]; then
        echo "Error: Input string is empty or not provided."
        return 1
    fi

    # Replace nested list separators with a unique delimiter (e.g., @@@)
    input_string="${input_string//],[/]@@@[}"
    input_string="${input_string//[[/[}"
    input_string="${input_string//]]/]}"

    # Remove square brackets and split the input_string into an array using '@@@' as a delimiter
    input_string="${input_string//[\[\]]/}"
    IFS='@@@' read -r -a array <<< "$input_string"

    # Output the nested array
    echo "${array[@]}"
}

# Verify that each element of val_list has the same length
validate_val_list_lengths() {
    local lengths=() # Array to hold lengths of each sublist
    for val in "${val_list[@]}"; do
        # Assuming val is a string representation of a list, you might need to convert it to an array or directly count elements
        IFS=',' read -r -a temp <<< "$val"
        lengths+=("${#temp[@]}")
    done

    # Now check if all lengths are the same
    local first_length=${lengths[0]}
    for length in "${lengths[@]}"; do
        if [[ "$length" -ne "$first_length" ]]; then
            echo "Error: Not all elements in val_list have the same length."
            exit 1
        fi
    done
}

# Function to display usage and exit
usage() {
    echo ""
    echo "Usage 1: $0 --hyper_param=value --base_val=value --delta=value --mode=mode --num_iter=value --train_script=path"
    echo "Usage 2: $0 --hyper_param_list=[param1,param2,...] --val_list=[[val1,val2,...],[val3,val4,...],...]] --train_script=path"
    echo "This script tunes a given hyperparameter by incrementing its value over a number of iterations and logs the results(Usage 1)"
    echo "This script tunes given list of hyperparameters by iterating over the lists of values and logs the results(Usage 2)"
    echo ""
    echo "Available hyperparameters to tune:"
    echo "  SMOOTHING(base value : 5e-3) - The value of epsilon for zeroth-order gradient estimation"
    echo "  NUM_QUERY(base value : 512) - The number of queries to make to guess the gradient"
    echo "  GROW_FREQ(base value : 10) - How frequently will you grow the size of the model?"
    echo "  add whatever hyperparameters you want to tune!"
    echo ""
    echo "Description of the arguments(Usage 1):"
    echo "  --hyper_param=value : The hyperparameter to tune"
    echo "  --base_val=value : The initial value of the hyperparameter"
    echo "  --delta=value : The amount to increment/multiplication the hyperparameter value by in each iteration"
    echo "  --mode=mode : The mode of tuning. Either 'increment(1)' or 'multiplication(2)'"
    echo "  --num_iter=value : The number of iterations to run"
    echo "  --train_script=path : The path to the training script"
    echo ""
    echo "Description of the arguments(Usage 2):"
    echo "  --hyper_param_list=[param1,param2,...] : The list of hyperparameters to tune"
    echo "  --val_list=[[val1,val2,...],[val3,val4,...],...] : The list of lists of values for each hyperparameter"
    echo "  --train_script=path : The path to the training script"
    echo ""
    exit 1
}

# Parse command-line arguments
for arg in "$@"; do
    case $arg in
        -h|--help)
            usage
            ;;
        --hyper_param=*)
            hyper_param="${arg#*=}"
            shift
            ;;
        --base_val=*)
            base_val="${arg#*=}"
            shift
            ;;
        --delta=*)
            delta="${arg#*=}"
            shift
            ;;
        --mode=*)
            mode="${arg#*=}"
            shift
            ;;
        --num_iter=*)
            num_iter="${arg#*=}"
            shift
            ;;
        --train_script=*)
            train_script="${arg#*=}"
            shift
            ;;
        --hyper_param_list=*)
            hyper_param_list="${arg#*=}"
            hpl_print=$hyper_param_list
            IFS=' ' read -r -a hyper_param_list <<< "$(parse_list "$hyper_param_list")"
            shift
            ;;
        --val_list=*)
            val_list="${arg#*=}"
            vl_print=$val_list
            IFS=' ' read -r -a val_list <<< "$(parse_nested_list "$val_list")"
            shift
            ;;
        *)
            echo "Unknown option: $arg"
            exit 1
            ;;
    esac
done

# Validate required parameters for Usage 2
if [ ${#hyper_param_list[@]} -gt 0 ]; then
    if [ ${#val_list[@]} -eq 0 ]; then
        echo "Error: When --hyper_param_list is used, --val_list must also be provided and not be empty."
        exit 1
    fi
    if [ ${#hyper_param_list[@]} != ${#val_list[@]} ]; then
        echo "Error: The number of hyperparameters and the number of value lists must be the same."
        exit 1
    fi
    # Validate the lengths of the value lists
    validate_val_list_lengths
fi

# Check if required arguments are provided, 
# if not, display usage and exit
if ([ -z "$hyper_param" ] || [ -z "$base_val" ] || [ -z "$delta" ] || [ -z "$num_iter" ] || [ -z "$train_script" ] || [ -z "$mode" ]); then
    if ([ -z "$hyper_param_list" ] || [ -z "$val_list" ] || [ -z "$train_script" ]); then
        echo "Error: Missing required arguments."
        usage
    fi
else
    # Verify the mode(check validity of mode)
    if [ "$mode" -ne 1 ] && [ "$mode" -ne 2 ]; then
    echo "Error: mode is neither 1 nor 2"
    exit 1
    fi
fi

usage_type=1
# verify the usage type
if [ -n "$hyper_param_list" ]; then
    usage_type=2
else
    usage_type=1
fi

# Generate result file name based on today's date, hyper parameter name
today=$(date +%Y-%m-%d_%H-%M-%S)
result_dir="./result"  # Define the directory to store result files
if [ $usage_type -eq 1 ]; then
    result_file="${result_dir}/${today}_${hyper_param}.txt"
else
    result_file="${result_dir}/${today}"
    for param in "${hyper_param_list[@]}"; do
        result_file="${result_file}_${param}"
    done
    result_file="${result_file}.txt"
fi

# Check if the result directory exists, if not, create it
if [ ! -d "$result_dir" ]; then
    mkdir -p "$result_dir"
fi

# Create or clear the result file and add metadata
echo "Script Metadata:" > $result_file
if [ $usage_type -eq 1 ]; then
    echo "hyper_param=$hyper_param" >> $result_file
    echo "base_val=$base_val" >> $result_file
    echo "delta=$delta" >> $result_file
    echo "mode=$mode" >> $result_file
    echo "num_iter=$num_iter" >> $result_file
    echo "train_script=$train_script" >> $result_file
    echo "result_file=$result_file" >> $result_file
    echo "" >> $result_file
    # Initialize hyper parameter value
    base_val=$(awk "BEGIN {print $base_val}")
    delta=$(awk "BEGIN {print $delta}")
    current_val=$base_val
else
    echo "hyper_param_list=$hpl_print" >> $result_file
    echo "val_list=$vl_print" >> $result_file
    echo "train_script=$train_script" >> $result_file
    echo "" >> $result_file
fi

# Loop for the specified number of iterations(Usage 1)
# iterate all over the provided lists(Usage 2)
if [ $usage_type -eq 1 ]; then
    for (( i=0; i<num_iter; i++ )); do
        echo "Iteration $(($i + 1)): $hyper_param = $current_val" >> $result_file
        echo "Iteration $(($i + 1)): $hyper_param = $current_val"
        # Run the training script with the current value of the hyperparameter
        python $train_script --hyper_param=$hyper_param --current_val=$current_val --usage_type=$usage_type >> $result_file
        
        # Increment(or multiply) the hyperparameter value by delta for the next iteration
        if [ $mode -eq 1 ]; then
            current_val=$(echo "$current_val + $delta" | bc)
        else
            current_val=$(echo "$current_val * $delta" | bc)
        fi
    done
else
    # reshape the val_list to appropriate format
    reshaped_val_list=()
    read -r -a val_list_zero <<< "$(parse_list "${val_list[0]}")"
    row_length=${#val_list_zero[@]}
    for (( j=0; j<${#val_list_zero[@]}; j++ )); do
        tmp=()
        for (( i=0; i<${#val_list[@]}; i++ )); do
            read -r -a val_list_each <<< "$(parse_list "${val_list[$i]}")"
            tmp+=("${val_list_each[$j]}")
        done
        reshaped_val_list+=("${tmp[@]}")
    done

    eff_idx=0
    # pass it to python script
    for (( i=0; i<row_length; i++ )); do
        hpl_arg="["
        for param in "${hyper_param_list[@]}"; do
            hpl_arg="${hpl_arg}${param},"
        done
        hpl_arg="${hpl_arg%?}"
        hpl_arg="${hpl_arg}]"
        rvl_arg="["
        info_str="Iteration $(($i + 1)):"
        tmp=0
        for (( j=0; j<${#hyper_param_list[@]}; j++ )); do
            tmp=$(echo "$eff_idx + $j" | bc)
            info_str="${info_str} ${hyper_param_list[$j]} = ${reshaped_val_list[$tmp]}"
            rvl_arg="${rvl_arg}${reshaped_val_list[$tmp]},"
        done
        eff_idx=$(echo "$eff_idx + ${#hyper_param_list[@]}" | bc)
        echo $info_str >> $result_file
        echo $info_str
        rvl_arg="${rvl_arg%?}"
        rvl_arg="${rvl_arg}]"

        python $train_script --hyper_param_list=$hpl_arg --val_list=$rvl_arg --usage_type=$usage_type >> $result_file
        echo "" >> $result_file
    done
fi
