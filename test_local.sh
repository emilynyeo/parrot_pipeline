#!/bin/bash
# Test script to run a single model locally before submitting to cluster
# This tests one seed for one model type on one dataset

# Set variables
SEED=1
MODEL_TYPE="l2_genus"  # Options: l2_genus, l2_genus_fit, rf_genus, rf_genus_fit
DATASET="miseq"  # Options: miseq, nanopore

# Create output directory if it doesn't exist
mkdir -p processed_data

# Set output file name
OUTPUT_FILE="processed_data/${MODEL_TYPE}_${DATASET}_${SEED}.Rds"
FEATURE_SCRIPT="code/02_model_training/${MODEL_TYPE}.R"

echo "Testing ${MODEL_TYPE} model on ${DATASET} dataset with seed ${SEED}"
echo "Output file: ${OUTPUT_FILE}"
echo "Feature script: ${FEATURE_SCRIPT}"

# Check if feature script exists
if [ ! -f "${FEATURE_SCRIPT}" ]; then
    echo "Error: Feature script not found: ${FEATURE_SCRIPT}"
    exit 1
fi

# Run the model
echo "Running model..."
./code/02_model_training/run_split.R "${OUTPUT_FILE}" "${FEATURE_SCRIPT}" "${DATASET}"

# Check if output was created
if [ -f "${OUTPUT_FILE}" ]; then
    echo "SUCCESS: Model file created: ${OUTPUT_FILE}"
    echo "You can inspect it in R with: readRDS('${OUTPUT_FILE}')"
else
    echo "ERROR: Model file was not created"
    exit 1
fi

