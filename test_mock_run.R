#!/usr/bin/env Rscript
# Mock run script to test the pipeline without intensive computation
# This verifies data loading, preprocessing, and model setup work correctly
# but uses minimal cross-validation to make it fast

cat(paste(rep("=", 60), collapse=""), "\n")
cat("MOCK RUN TEST - Verifying pipeline setup\n")
cat(paste(rep("=", 60), collapse=""), "\n\n")

# Test parameters - modify these to test specific models/datasets
# Options for TEST_MODELS: "l2_genus", "l2_genus_fit", "rf_genus", "rf_genus_fit"
# Options for TEST_DATASETS: "miseq", "nanopore"
TEST_MODELS <- c("rf_genus")  # Test only random forest can change to other models
TEST_DATASETS <- c("miseq")   # Test only miseq dataset can change to nanopore 
SEED <- 1

# Track results
results <- list()
errors <- list()

# Load data ONCE at the beginning (this is the slow part)
cat("\nLoading data (this may take 1-3 minutes depending on data size)...\n")
cat("  Sourcing genus_process.R...\n")
cat("  NOTE: Data processing (joins, filtering, etc.) may take time - this is normal!\n")
start_time <- Sys.time()
source("code/01_data_prep/genus_process.R")
elapsed <- round(as.numeric(Sys.time() - start_time, units="secs"), 1)
cat("✓ Data prep script loaded (took", elapsed, "seconds)\n")

# Load required libraries once
if (!require(mikropml, quietly = TRUE)) {
  stop("mikropml package not installed. Install with: install.packages('mikropml')")
}
if (!require(tidyverse, quietly = TRUE)) {
  stop("tidyverse package not installed. Install with: install.packages('tidyverse')")
}
cat("✓ Required libraries loaded\n\n")

# Function to test a single model
test_model <- function(model_type, dataset) {
  
  cat("\n", paste(rep("-", 60), collapse=""), "\n")
  cat("Testing:", model_type, "on", dataset, "dataset\n")
  cat(paste(rep("-", 60), collapse=""), "\n")
  
  tryCatch({
    # 1. Check feature script exists
    feature_script <- paste0("code/02_model_training/", model_type, ".R")
    if (!file.exists(feature_script)) {
      stop("Feature script not found: ", feature_script)
    }
    cat("✓ Feature script found:", feature_script, "\n")
    
    # 3. Check dataset exists
    composite_data <- if(dataset == "miseq") {
      if (!exists("composite_miseq")) stop("composite_miseq not found")
      composite_miseq
    } else {
      if (!exists("composite_nanopore")) stop("composite_nanopore not found")
      composite_nanopore
    }
    cat("✓ Dataset loaded:", nrow(composite_data), "rows\n")
    
    # 4. Check outcome variable
    if (!"captive_wild" %in% names(composite_data)) {
      stop("captive_wild column not found in dataset")
    }
    cat("✓ Outcome variable found:", length(unique(composite_data$captive_wild)), "levels\n")
    cat("  Levels:", paste(levels(composite_data$captive_wild), collapse=", "), "\n")
    
    # 2. Source feature script (libraries already loaded globally)
    source(feature_script)
    if (!exists("feature_select")) {
      stop("feature_select function not defined in feature script")
    }
    if (!exists("approach")) {
      stop("approach variable not defined in feature script")
    }
    if (!exists("hyperparameter")) {
      stop("hyperparameter variable not defined in feature script")
    }
    cat("✓ Feature script loaded\n")
    cat("  Approach:", approach, "\n")
    cat("  Hyperparameters:", paste(names(hyperparameter), collapse=", "), "\n")
    
    # 3. Test feature selection
    cat("Testing feature selection...\n")
    selected_data <- composite_data %>%
      select(samples, taxonomy, rel_abund, captive_wild) %>%
      feature_select()
    cat("✓ Feature selection works\n")
    cat("  Selected columns:", paste(names(selected_data), collapse=", "), "\n")
    
    # 4. Test data preparation
    cat("Preparing data (pivoting to wide format)...\n")
    captive_wild_data <- composite_data %>%
      select(samples, taxonomy, rel_abund, captive_wild) %>%
      feature_select() %>%
      pivot_wider(names_from=taxonomy, values_from = rel_abund) %>%
      select(-samples) %>%
      select(captive_wild, everything())
    
    cat("✓ Data prepared:", nrow(captive_wild_data), "samples,", ncol(captive_wild_data), "features\n")
    
    # 5. Test preprocessing
    cat("Preprocessing data (removing correlated/low variance features)...\n")
    captive_wild_preprocess <- preprocess_data(captive_wild_data,
                                              outcome_colname = "captive_wild")$dat_transformed
    cat("✓ Preprocessing complete:", nrow(captive_wild_preprocess), "samples,", 
        ncol(captive_wild_preprocess), "features\n")
    
    # 6. Test model setup with MINIMAL cv_times (just to verify it works)
    cat("Running minimal model training (cv_times=2, kfold=3)...\n")
    cat("  This may take 30-90 seconds per model...\n")
    
    model <- run_ml(captive_wild_preprocess,
                   method=approach,
                   outcome_colname = "captive_wild",
                   kfold = 3,        # Reduced from 5
                   cv_times = 2,     # Minimal - just to verify it works
                   training_frac = 0.8,
                   find_feature_importance = FALSE,  # Skip for speed
                   hyperparameters = hyperparameter,
                   seed = SEED)
    
    cat("✓ Model training successful!\n")
    
    # Display available performance metrics (handle multi-class outcomes)
    perf <- model$performance
    if (!is.null(perf)) {
      cat("  Available performance metrics:", paste(names(perf), collapse=", "), "\n")
      if ("AUC" %in% names(perf) && is.numeric(perf$AUC)) {
        cat("  Test AUC:", round(perf$AUC, 4), "\n")
      } else if ("Accuracy" %in% names(perf) && is.numeric(perf$Accuracy)) {
        cat("  Test Accuracy:", round(perf$Accuracy, 4), "\n")
      }
      if ("cv_metric_AUC" %in% names(perf) && is.numeric(perf$cv_metric_AUC)) {
        cat("  CV metric AUC:", round(perf$cv_metric_AUC, 4), "\n")
      } else if ("cv_metric_Accuracy" %in% names(perf) && is.numeric(perf$cv_metric_Accuracy)) {
        cat("  CV metric Accuracy:", round(perf$cv_metric_Accuracy, 4), "\n")
      }
    }
    
    # 7. Test output file creation
    output_file <- paste0("processed_data/", model_type, "_", dataset, "_", SEED, ".Rds")
    if (!dir.exists("processed_data")) {
      dir.create("processed_data", recursive = TRUE)
    }
    saveRDS(model, file=output_file)
    if (file.exists(output_file)) {
      cat("✓ Output file created:", output_file, "\n")
      cat("  File saved at:", normalizePath(output_file), "\n")
      # Option to keep the file for inspection - comment out the next 2 lines to keep it
      # file.remove(output_file)
      # cat("  (test file removed)\n")
    }
    
    # Get performance metric (prefer AUC, fall back to Accuracy for multi-class)
    perf_metric <- if (!is.null(model$performance$AUC) && is.numeric(model$performance$AUC)) {
      model$performance$AUC
    } else if (!is.null(model$performance$Accuracy) && is.numeric(model$performance$Accuracy)) {
      model$performance$Accuracy
    } else {
      NA
    }
    
    return(list(
      success = TRUE,
      model_type = model_type,
      dataset = dataset,
      n_samples = nrow(captive_wild_preprocess),
      n_features = ncol(captive_wild_preprocess),
      test_metric = perf_metric
    ))
    
  }, error = function(e) {
    cat("✗ ERROR:", e$message, "\n")
    return(list(
      success = FALSE,
      model_type = model_type,
      dataset = dataset,
      error = e$message
    ))
  })
}

# Run tests
cat("\nStarting mock run tests...\n\n")

for (dataset in TEST_DATASETS) {
  for (model_type in TEST_MODELS) {
    result <- test_model(model_type, dataset)
    results[[paste(model_type, dataset, sep="_")]] <- result
    if (!result$success) {
      errors[[paste(model_type, dataset, sep="_")]] <- result$error
    }
  }
}

# Summary
cat("\n", paste(rep("=", 60), collapse=""), "\n")
cat("TEST SUMMARY\n")
cat(paste(rep("=", 60), collapse=""), "\n\n")

successful <- sum(sapply(results, function(x) x$success))
total <- length(results)

cat("Successful tests:", successful, "/", total, "\n\n")

if (successful == total) {
  cat("✓ ALL TESTS PASSED! Your pipeline is ready to run.\n\n")
  cat("You can now run the full pipeline with:\n")
  cat("  - Makefile: make processed_data/l2_genus_miseq_performance.tsv\n")
  cat("  - SLURM: sbatch slurm/l2_genus_miseq.slurm\n")
  cat("  - Direct: ./code/02_model_training/run_split.R <output_file> <feature_script> <dataset>\n")
} else {
  cat("✗ SOME TESTS FAILED. Please fix the following errors:\n\n")
  for (name in names(errors)) {
    cat("  ", name, ":", errors[[name]], "\n")
  }
}

cat("\n", paste(rep("=", 60), collapse=""), "\n")

