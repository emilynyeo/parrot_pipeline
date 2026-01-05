#!/usr/bin/env Rscript
# Pre-process data once before running the pipeline
# This saves time and memory when running multiple models in parallel

cat("==========================================\n")
cat("PRE-PROCESSING DATA (One-Time Setup)\n")
cat("==========================================\n\n")

# Check if data already exists
miseq_file <- "processed_data/composite_miseq.rds"
nanopore_file <- "processed_data/composite_nanopore.rds"

if (file.exists(miseq_file) && file.exists(nanopore_file)) {
  cat("✓ Processed data files already exist:\n")
  cat("  -", miseq_file, "\n")
  cat("  -", nanopore_file, "\n")
  cat("\nSkipping data preparation. If you want to re-process, delete these files first.\n")
} else {
  cat("Processing data (this may take a few minutes)...\n")
  cat("This only needs to be done once.\n\n")
  
  source("code/01_data_prep/genus_process.R")
  
  cat("\n==========================================\n")
  cat("✓ Data preparation complete!\n")
  cat("You can now run the pipeline without re-processing data.\n")
  cat("==========================================\n")
}

