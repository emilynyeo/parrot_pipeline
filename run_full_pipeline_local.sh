#!/bin/bash
# Script to run the full pipeline locally
# This will run all models (4 types × 2 datasets × 100 seeds = 800 models)
# WARNING: This will take a very long time! Consider running in smaller batches.

echo "=========================================="
echo "FULL PIPELINE - LOCAL EXECUTION"
echo "=========================================="
echo ""
echo "This will run:"
echo "  - 4 model types (l2_genus, l2_genus_fit, rf_genus, rf_genus_fit)"
echo "  - 2 datasets (miseq, nanopore)"
echo "  - 20 seeds each"
echo "  - Total: 160 model runs"
echo ""
echo "Estimated time:"
echo "  - Per model: ~1-3 minutes (with cv_times=20)"
echo "  - Total: ~13-40 hours if run sequentially"
echo "  - With parallel make (-j 4): ~4-13 hours"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

# Create output directory
mkdir -p processed_data
mkdir -p figures

# Number of parallel jobs per model type (adjust based on your CPU cores)
# Use fewer than your total cores to avoid overwhelming your system
# Recommended: 50-75% of your CPU cores
PARALLEL_JOBS=4

# Option: Run model types sequentially (one at a time) or in parallel
# Set to "sequential" to run one model type at a time (safer, slower)
#   - Within each model type, runs PARALLEL_JOBS models in parallel
#   - Max concurrent models = PARALLEL_JOBS (4 in this case)
# Set to "parallel" to run all 8 model types simultaneously (faster, uses more resources)
#   - Max concurrent models = PARALLEL_JOBS × 8 (32 in this case)
RUN_MODE="sequential"  # Running sequentially with 4 parallel jobs per model type

echo ""
echo "Configuration:"
echo "  Parallel jobs per model type: $PARALLEL_JOBS"
echo "  Run mode: $RUN_MODE"
if [ "$RUN_MODE" = "parallel" ]; then
    echo "  WARNING: This will run up to $((PARALLEL_JOBS * 8)) models simultaneously!"
    echo "  Make sure your system can handle this!"
fi
echo ""
echo "Checking if data is pre-processed..."
if [ ! -f "processed_data/composite_miseq.rds" ] || [ ! -f "processed_data/composite_nanopore.rds" ]; then
    echo "  Data files not found. Pre-processing data once (this may take a few minutes)..."
    echo "  This only needs to be done once."
    Rscript prepare_data_once.R
    if [ $? -ne 0 ]; then
        echo "ERROR: Data preparation failed!"
        exit 1
    fi
    echo ""
else
    echo "  ✓ Pre-processed data files found. Skipping data preparation."
    echo ""
fi

echo "Starting pipeline..."
echo "You can monitor progress by checking processed_data/ directory"
echo "Press Ctrl+C to stop (completed models will be saved)"
echo ""

if [ "$RUN_MODE" = "parallel" ]; then
    # Run all model types in parallel (each with PARALLEL_JOBS seeds running)
    make -j $PARALLEL_JOBS processed_data/l2_genus_miseq_performance.tsv &
    make -j $PARALLEL_JOBS processed_data/l2_genus_nanopore_performance.tsv &
    make -j $PARALLEL_JOBS processed_data/l2_genus_fit_miseq_performance.tsv &
    make -j $PARALLEL_JOBS processed_data/l2_genus_fit_nanopore_performance.tsv &
    make -j $PARALLEL_JOBS processed_data/rf_genus_miseq_performance.tsv &
    make -j $PARALLEL_JOBS processed_data/rf_genus_nanopore_performance.tsv &
    make -j $PARALLEL_JOBS processed_data/rf_genus_fit_miseq_performance.tsv &
    make -j $PARALLEL_JOBS processed_data/rf_genus_fit_nanopore_performance.tsv &
    
    # Wait for all background jobs to complete
    wait
else
    # Run model types sequentially (one at a time)
    echo "Running model types one at a time..."
    make -j $PARALLEL_JOBS processed_data/l2_genus_miseq_performance.tsv
    make -j $PARALLEL_JOBS processed_data/l2_genus_nanopore_performance.tsv
    make -j $PARALLEL_JOBS processed_data/l2_genus_fit_miseq_performance.tsv
    make -j $PARALLEL_JOBS processed_data/l2_genus_fit_nanopore_performance.tsv
    make -j $PARALLEL_JOBS processed_data/rf_genus_miseq_performance.tsv
    make -j $PARALLEL_JOBS processed_data/rf_genus_nanopore_performance.tsv
    make -j $PARALLEL_JOBS processed_data/rf_genus_fit_miseq_performance.tsv
    make -j $PARALLEL_JOBS processed_data/rf_genus_fit_nanopore_performance.tsv
fi

echo ""
echo "=========================================="
echo "All models completed!"
echo "=========================================="
echo ""
echo "Performance files created:"
ls -lh processed_data/*_performance.tsv
echo ""
echo "You can now run analysis scripts:"
echo "  Rscript code/04_analysis/plot_model_compare.R"
echo "  Rscript code/04_analysis/compare_genus_aucs.R"
echo "  Rscript code/04_analysis/build_rocs.R"

