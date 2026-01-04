#!/usr/bin/env Rscript
# R script to test the pipeline locally
# This tests a single seed for one model type on one dataset

# Set test parameters
SEED <- 1
MODEL_TYPE <- "l2_genus"  # Options: l2_genus, l2_genus_fit, rf_genus, rf_genus_fit
DATASET <- "miseq"  # Options: miseq, nanopore

# Set paths
output_file <- paste0("processed_data/", MODEL_TYPE, "_", DATASET, "_", SEED, ".Rds")
feature_script <- paste0("code/02_model_training/", MODEL_TYPE, ".R")

cat("Testing", MODEL_TYPE, "model on", DATASET, "dataset with seed", SEED, "\n")
cat("Output file:", output_file, "\n")
cat("Feature script:", feature_script, "\n\n")

# Check if feature script exists
if (!file.exists(feature_script)) {
  stop("Error: Feature script not found: ", feature_script)
}

# Create output directory if it doesn't exist
if (!dir.exists("processed_data")) {
  dir.create("processed_data", recursive = TRUE)
}

# Source the run_split script logic
source("code/01_data_prep/genus_process.R")
library(mikropml)
library(tidyverse)

source(feature_script)

# Select the appropriate dataset
composite_data <- if(DATASET == "miseq") {
  composite_miseq
} else if(DATASET == "nanopore") {
  composite_nanopore
} else {
  stop("DATASET must be 'miseq' or 'nanopore'")
}

cat("Dataset loaded:", nrow(composite_data), "rows\n")
cat("Outcome variable levels:", levels(composite_data$captive_wild), "\n\n")

captive_wild_data <- composite_data %>%
  select(samples, taxonomy, rel_abund, captive_wild) %>%
  feature_select() %>%
  pivot_wider(names_from=taxonomy, values_from = rel_abund) %>%
  select(-samples) %>%
  select(captive_wild, everything())

cat("Data prepared:", nrow(captive_wild_data), "samples,", ncol(captive_wild_data), "features\n\n")

# Preprocess
cat("Preprocessing data...\n")
captive_wild_preprocess <- preprocess_data(captive_wild_data,
                                        outcome_colname = "captive_wild")$dat_transformed

cat("Preprocessed data:", nrow(captive_wild_preprocess), "samples,", ncol(captive_wild_preprocess), "features\n\n")

# Run model (with reduced cv_times for faster testing)
cat("Running model (this may take a few minutes)...\n")
model <- run_ml(captive_wild_preprocess,
       method=approach,
       outcome_colname = "captive_wild",
       kfold = 5,
       cv_times = 10,  # Reduced from 100 for faster testing
       training_frac = 0.8,
       find_feature_importance = TRUE,
       hyperparameters = hyperparameter,
       seed = SEED)

cat("\nModel training complete!\n")
cat("Test AUC:", model$performance$AUC, "\n")
cat("CV metric AUC:", model$performance$cv_metric_AUC, "\n\n")

# Save model
saveRDS(model, file=output_file)
cat("Model saved to:", output_file, "\n")
cat("SUCCESS: Test completed successfully!\n")

