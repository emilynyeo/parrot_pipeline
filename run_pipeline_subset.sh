#!/bin/bash
# Script to run a subset of the pipeline locally
# Useful for testing or running smaller batches

echo "=========================================="
echo "PIPELINE SUBSET - LOCAL EXECUTION"
echo "=========================================="
echo ""

# Configuration - modify these
MODEL_TYPE="rf_genus"  # Options: l2_genus, l2_genus_fit, rf_genus, rf_genus_fit
DATASET="miseq"        # Options: miseq, nanopore
SEED_START=1           # First seed to run
SEED_END=10            # Last seed to run (inclusive)
PARALLEL_JOBS=3        # Number of parallel jobs

echo "Configuration:"
echo "  Model: $MODEL_TYPE"
echo "  Dataset: $DATASET"
echo "  Seeds: $SEED_START to $SEED_END"
echo "  Parallel jobs: $PARALLEL_JOBS"
echo ""

read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

# Create output directory
mkdir -p processed_data

echo ""
echo "Running models..."

# Run models for the specified seed range
for SEED in $(seq $SEED_START $SEED_END); do
    OUTPUT_FILE="processed_data/${MODEL_TYPE}_${DATASET}_${SEED}.Rds"
    FEATURE_SCRIPT="code/02_model_training/${MODEL_TYPE}.R"
    
    echo "Running seed $SEED..."
    ./code/02_model_training/run_split.R "$OUTPUT_FILE" "$FEATURE_SCRIPT" "$DATASET" &
    
    # Limit number of parallel jobs
    if (( $(jobs -r | wc -l) >= $PARALLEL_JOBS )); then
        wait -n  # Wait for one job to finish
    fi
done

# Wait for remaining jobs
wait

echo ""
echo "=========================================="
echo "Models completed!"
echo "=========================================="
echo ""
echo "Created files:"
ls -lh processed_data/${MODEL_TYPE}_${DATASET}_*.Rds | tail -5
echo ""
echo "To combine results, run:"
echo "  Rscript code/03_model_combination/combine_models.R processed_data/${MODEL_TYPE}_${DATASET}_{$SEED_START..$SEED_END}.Rds"

