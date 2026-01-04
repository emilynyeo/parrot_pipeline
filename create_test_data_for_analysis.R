#!/usr/bin/env Rscript
# Create minimal test data for testing analysis scripts
# This creates a few model files and performance files so analysis scripts can run

cat("Creating test data for analysis scripts...\n\n")

# Create directories
if (!dir.exists("processed_data")) dir.create("processed_data", recursive = TRUE)
if (!dir.exists("figures")) dir.create("figures", recursive = TRUE)

# Check if we already have some model files
existing_files <- list.files("processed_data", pattern = ".*_(miseq|nanopore)_\\d+\\.Rds", full.names = TRUE)
cat("Found", length(existing_files), "existing model files\n")

if (length(existing_files) < 3) {
  cat("\nYou need at least 2-3 model files to test analysis scripts.\n")
  cat("Creating test files by running a few seeds...\n\n")
  
  # Run a few seeds for rf_genus_miseq
  cat("Creating rf_genus_miseq models (seeds 1-3)...\n")
  for (seed in 1:3) {
    output_file <- paste0("processed_data/rf_genus_miseq_", seed, ".Rds")
    if (!file.exists(output_file)) {
      cat("  Running seed", seed, "...\n")
      system(paste0("./code/02_model_training/run_split.R ", 
                   output_file, " code/02_model_training/rf_genus.R miseq"))
    } else {
      cat("  Seed", seed, "already exists\n")
    }
  }
  
  # Create performance file
  cat("\nCreating performance file...\n")
  rds_files <- paste0("processed_data/rf_genus_miseq_", 1:3, ".Rds")
  if (all(file.exists(rds_files))) {
    system(paste("Rscript code/03_model_combination/combine_models.R", 
                paste(rds_files, collapse = " ")))
    cat("✓ Performance file created\n")
  }
} else {
  cat("✓ You have enough model files to test analysis scripts\n")
}

cat("\nTest data ready! Now run: Rscript test_analysis_scripts.R\n")

