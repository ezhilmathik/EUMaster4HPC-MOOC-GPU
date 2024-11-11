#!/bin/bash -l                            
#SBATCH --nodes=1
#SBATCH --partition=gpu
#SBATCH --qos=default
#SBATCH --time 00:15:00
#SBATCH --account=p200301
#SBATCH --exclusive 

module load env/release/2023.1
module load OpenMPI/4.1.5-NVHPC-23.7-CUDA-12.2.0 # added 17/05/2024
export NVCC_APPEND_FLAGS='-allow-unsupported-compiler' # added 10/04/2024

#nvcc -arch compute_80 matrix-transpose-1.cu -o cu
#nvcc -arch compute_80 Matrix-Transpose-CUDA.cu -o cu-1
#nvc -fast -acc=gpu -Minfo=accel,all -gpu=cc80 Matrix-transpose-openacc.c -o op -lcudart
#nvcc -arch compute_80 cuda.cu -Xcompiler -fopenmp -o cu -lcudart
nvc++ -fast -cuda -mp=gpu -gpu=cc80 -o cu cuda.cu -lcudart 
nvc++ -fast -acc -acc=gpu -mp -Minfo=accel -gpu=cc80 openacc.cc -o acc -lcudart
nvc++ -fast -mp=gpu -gpu=cc80 -Minfo=accel -lcudart -o off openmp.cc
g++ check.cc -o file_check

# Input parameters range
start=10000
end=45000
step=5000

# Run each executable with the input range
for i in $(seq $start $step $end); do
    echo "Running ./cu with parameter $i"
    ./cu $i
    echo "Waiting for GPU to cool down to 39°C or below..."

    # Wait until the GPU temperature is 39°C or lower
    while true; do
        # Capture and clean the temperature output, ensuring it's an integer
        temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits | head -n 1 | tr -dc '0-9')

        # Verify that temp is not empty and is a valid integer before comparing
        if [ -n "$temp" ] && [ "$temp" -le 39 ]; then
            break
        fi
        sleep 30s  # Check every 30 seconds
    done
    echo

    echo "Running ./acc with parameter $i"
    ./acc $i
    echo "Waiting for GPU to cool down to 39°C or below..."

    while true; do
        temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits | head -n 1 | tr -dc '0-9')
        
        if [ -n "$temp" ] && [ "$temp" -le 39 ]; then
            break
        fi
        sleep 30s  # Check every 30 seconds
    done
    echo

    # Now add the ./off execution and cooldown process
    echo "Running ./off with parameter $i"
    ./off $i
    echo "Waiting for GPU to cool down to 39°C or below..."

    while true; do
        temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits | head -n 1 | tr -dc '0-9')
        
        if [ -n "$temp" ] && [ "$temp" -le 39 ]; then
            break
        fi
        sleep 30s  # Check every 30 seconds
    done
    echo

    # Compare output files from each executable
    ./file_check cuda_output.txt openacc_output.txt openmp_output.txt
    echo "------------- New iteration -----------"
    echo
done
