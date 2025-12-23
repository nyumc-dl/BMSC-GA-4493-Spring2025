#!/bin/bash

##############################################################################
# HPC Execution Script for Lab 9 Notebooks
# Usage: sbatch run_notebooks.sh
#
# This script runs all corrected notebooks using the dpath_env environment
# on an HPC node with GPU access.
##############################################################################

#SBATCH --job-name=lab9_notebooks
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=04:00:00
#SBATCH --gres=gpu:1
#SBATCH --partition=gpu
#SBATCH --output=lab9_notebooks_%j.log

# Set error handling
set -e

# Print job info
echo "=========================================="
echo "Lab 9 Notebook Execution on HPC"
echo "=========================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Node: $SLURM_NODELIST"
echo "GPU: $CUDA_VISIBLE_DEVICES"
echo "Time: $(date)"
echo "=========================================="

# Source the conda environment
source /gpfs/data/tsirigoslab/home/dpath_env/bin/activate dpath_env

echo "Environment activated: $CONDA_DEFAULT_ENV"
python --version
nvidia-smi

# Set working directory
NOTEBOOK_DIR="/Users/nikolas/Desktop/Projects/TA/BMSC-GA-4493-Spring2025/labs/lab9"
RESULTS_DIR="${NOTEBOOK_DIR}/results_${SLURM_JOB_ID}"
mkdir -p "$RESULTS_DIR"

echo ""
echo "Working directory: $NOTEBOOK_DIR"
echo "Results will be saved to: $RESULTS_DIR"
echo ""

# Function to run a notebook
run_notebook() {
    local notebook=$1
    local output=$2

    echo "-------------------------------------------"
    echo "Running: $notebook"
    echo "Output: $output"
    echo "-------------------------------------------"

    python -m jupyter nbconvert --to notebook --execute \
        --ExecutePreprocessor.timeout=3600 \
        --output="$output" \
        "$notebook"

    if [ $? -eq 0 ]; then
        echo "✓ $notebook completed successfully"
    else
        echo "✗ $notebook failed"
        return 1
    fi
    echo ""
}

# Run each notebook
FAILED=0

# 1. Barlow Twins
run_notebook \
    "$NOTEBOOK_DIR/250403_Barlow_twins_example.ipynb" \
    "$RESULTS_DIR/250403_Barlow_twins_example.ipynb" || FAILED=$((FAILED+1))

# 2. CLIP
run_notebook \
    "$NOTEBOOK_DIR/250403_CLIP_exapple.ipynb" \
    "$RESULTS_DIR/250403_CLIP_exapple.ipynb" || FAILED=$((FAILED+1))

# 3. Distillation (moderate runtime)
run_notebook \
    "$NOTEBOOK_DIR/250403_DistillationExample.ipynb" \
    "$RESULTS_DIR/250403_DistillationExample.ipynb" || FAILED=$((FAILED+1))

# 4. DINOv2 (requires images directory)
if [ -d "$NOTEBOOK_DIR/images" ]; then
    run_notebook \
        "$NOTEBOOK_DIR/250403_DINOv2_viz.ipynb" \
        "$RESULTS_DIR/250403_DINOv2_viz.ipynb" || FAILED=$((FAILED+1))
else
    echo "⚠ Skipping DINOv2 - images directory not found"
fi

# 5. MAE
run_notebook \
    "$NOTEBOOK_DIR/250403_MAE_Example.ipynb" \
    "$RESULTS_DIR/250403_MAE_Example.ipynb" || FAILED=$((FAILED+1))

# 6. ESM2
run_notebook \
    "$NOTEBOOK_DIR/250403_ESMv2_example.ipynb" \
    "$RESULTS_DIR/250403_ESMv2_example.ipynb" || FAILED=$((FAILED+1))

# 7. RNA Foundation Models (requires paths to exist)
if [ -f "/gpfs/home/nk4167/RNA-FM_pretrained.pth" ] && \
   [ -d "/gpfs/home/nk4167/RNA-FM" ]; then
    run_notebook \
        "$NOTEBOOK_DIR/250403_RNA_foundation_models.ipynb" \
        "$RESULTS_DIR/250403_RNA_foundation_models.ipynb" || FAILED=$((FAILED+1))
else
    echo "⚠ Skipping RNA-FM - required model/files not found at expected paths"
fi

# 8. HE Example (requires TCGA API access and tiatoolbox)
if command -v -v tiatoolbox &> /dev/null || python -c "import tiatoolbox" 2>/dev/null; then
    run_notebook \
        "$NOTEBOOK_DIR/250403_HE_example.ipynb" \
        "$RESULTS_DIR/250403_HE_example.ipynb" || FAILED=$((FAILED+1))
else
    echo "⚠ Skipping HE Example - tiatoolbox not installed"
fi

# Summary
echo ""
echo "=========================================="
echo "Execution Summary"
echo "=========================================="
echo "Total failures: $FAILED"
echo "Results saved to: $RESULTS_DIR"
echo "Log file: lab9_notebooks_${SLURM_JOB_ID}.log"
echo "Time completed: $(date)"
echo "=========================================="

if [ $FAILED -gt 0 ]; then
    echo "⚠ Some notebooks failed to execute"
    exit 1
else
    echo "✓ All available notebooks executed successfully"
    exit 0
fi
