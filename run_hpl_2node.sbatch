#!/bin/bash
#SBATCH --job-name=hpl_2gpu_1node_NSYS
#SBATCH --partition=h100
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=2
#SBATCH --gres=gpu:h100:2
#SBATCH --cpus-per-task=4
#SBATCH --mem=256G
#SBATCH --time=00:30:00
#SBATCH --output=hpl_nsys_%j_rank%t.log


module load gcc/14.2.0-cuda-jeua
module load apptainer/1.4.1-zviq
module load cuda/12.2.2-rs3n


CONTAINER_IMAGE="hpc-benchmarks.sif"
export CONTAINER_IMAGE


NSYS_LIB_PATH="/opt/spack/opt/spack/linux-sapphirerapids/cuda-12.2.2-rs3noqbjgt3jj5timyefv5ov5zui6y7h/nsight-systems-2023.2.3/target-linux-x64"
export NSYS_LIB_PATH

# --- Environment Variables ---
export APPTAINERENV_OMP_NUM_THREADS=1
export APPTAINERENV_MKL_NUM_THREADS=1
export APPTAINERENV_OPENBLAS_NUM_THREADS=1
export APPTAINERENV_HPL_USE_NVSHMEM=1
export APPTAINERENV_HPL_FCT_COMM_POLICY=0
export APPTAINERENV_HPL_P2P_AS_BCAST=1
export APPTAINERENV_HPL_NVSHMEM_SWAP=0
export APPTAINERENV_HPL_CHUNK_SIZE_NBS=32
export APPTAINERENV_HPL_CTA_PER_FCT=32
export APPTAINERENV_HPL_FCT_CHUNK_SIZE=32
export APPTAINERENV_HPL_DIST_TRSM_FLAG=1
export APPTAINERENV_HPL_WARMUP_MPI=1
export APPTAINERENV_HPL_CUSOLVER_MP_TESTS=0
export APPTAINERENV_HPL_ALLOC_HUGEPAGES=1

# --- EXECUTION ---
# remove CPU_AFFINITY variable and --cpu-affinity / --mem-affinity flags
# let slurm handle the binding for now

srun \
    --output="hpl_nsys_%j_rank%t.log" \
    sh -c "
nsys profile \
      -t cuda,nvtx,osrt,mpi,cublas \
      --cuda-memory-usage=true \
      --mpi-impl=openmpi \
      --sample=none \
      --force-overwrite=true \
      -o hpl_profile_\${SLURM_JOBID}_rank\${SLURM_PROCID} \
  apptainer exec --nv \
      -B \$PWD:/data \
      -B \${NSYS_LIB_PATH} \
      -B /tmp \
      \${CONTAINER_IMAGE} \
  /workspace/hpl.sh \
    --dat /data/HPL.dat \
    --no-multinode
"