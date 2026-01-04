#!/usr/bin/env Rscript
# Test script for analysis scripts
# This creates minimal test data and runs the analysis scripts to verify they work

cat(paste(rep("=", 60), collapse=""), "\n")
cat("ANALYSIS SCRIPTS TEST\n")
cat(paste(rep("=", 60), collapse=""), "\n\n")

# Create test directory for figures
if (!dir.exists("figures")) {
  dir.create("figures", recursive = TRUE)
  cat("Created figures/ directory\n")
}

# Check if we have any model files to work with
cat("\nChecking for existing model files...\n")
miseq_files <- list.files("processed_data", pattern = ".*_miseq_\\d+\\.Rds", full.names = TRUE)
nanopore_files <- list.files("processed_data", pattern = ".*_nanopore_\\d+\\.Rds", full.names = TRUE)

cat("  Found", length(miseq_files), "miseq model files\n")
cat("  Found", length(nanopore_files), "nanopore model files\n")

# Check for performance files
perf_files <- list.files("processed_data", pattern = ".*_performance\\.tsv", full.names = TRUE)
cat("  Found", length(perf_files), "performance files\n\n")

# Function to check if required files exist
check_requirements <- function(script_name) {
  requirements <- list()
  
  if (basename(script_name) == "plot_model_compare.R") {
    perf_files <- list.files("processed_data", pattern = ".*_performance\\.tsv", full.names = TRUE)
    requirements$files <- perf_files
    requirements$met <- length(perf_files) > 0
    requirements$message <- if (requirements$met) {
      paste("Found", length(perf_files), "performance files")
    } else {
      "Need at least one *_performance.tsv file"
    }
  } else if (basename(script_name) == "compare_genus_aucs.R") {
    l2_genus_miseq <- file.exists("processed_data/l2_genus_miseq_performance.tsv")
    l2_genus_fit_miseq <- file.exists("processed_data/l2_genus_fit_miseq_performance.tsv")
    requirements$met <- l2_genus_miseq && l2_genus_fit_miseq
    requirements$message <- if (requirements$met) {
      "Found required l2_genus and l2_genus_fit performance files"
    } else {
      "Need l2_genus_*_performance.tsv and l2_genus_fit_*_performance.tsv files"
    }
  } else if (basename(script_name) == "build_rocs.R") {
    model_files <- list.files("processed_data", pattern = ".*_(miseq|nanopore)_\\d+\\.Rds", full.names = TRUE)
    requirements$files <- model_files
    requirements$met <- length(model_files) > 0
    requirements$message <- if (requirements$met) {
      paste("Found", length(model_files), "model files")
    } else {
      "Need at least one model Rds file"
    }
  } else if (basename(script_name) == "feature_importance.R") {
    l2_files <- list.files("processed_data", pattern = "l2_genus_.*_\\d+\\.Rds", full.names = TRUE)
    requirements$files <- l2_files
    requirements$met <- length(l2_files) > 0
    requirements$message <- if (requirements$met) {
      paste("Found", length(l2_files), "l2_genus model files")
    } else {
      "Need l2_genus_*_*.Rds files"
    }
  } else if (basename(script_name) == "genus_by_genus_analysis.R") {
    # This one just needs the data to be loadable
    requirements$met <- TRUE
    requirements$message <- "Requires genus_process.R to load data"
  } else {
    requirements$met <- TRUE
    requirements$message <- "Unknown requirements"
  }
  
  return(requirements)
}

# Function to test an analysis script
test_analysis_script <- function(script_name, description, requirements_info) {
  cat("\n", paste(rep("-", 60), collapse=""), "\n")
  cat("Testing:", description, "\n")
  cat("Script:", script_name, "\n")
  cat(paste(rep("-", 60), collapse=""), "\n")
  
  # Check requirements
  req <- check_requirements(script_name)
  cat("Requirements:", req$message, "\n")
  
  if (!req$met) {
    cat("⚠ SKIPPED: Missing required files\n")
    return(list(success = FALSE, script = script_name, error = "Missing required files", skipped = TRUE))
  }
  
  tryCatch({
    # Source the script
    source(script_name)
    cat("✓ Script completed without errors\n")
    return(list(success = TRUE, script = script_name))
  }, error = function(e) {
    cat("✗ ERROR:", e$message, "\n")
    return(list(success = FALSE, script = script_name, error = e$message))
  })
}

# List of analysis scripts to test
analysis_scripts <- list(
  list(
    script = "code/04_analysis/plot_model_compare.R",
    description = "plot_model_compare.R - Model comparison plots",
    requires = "performance.tsv files"
  ),
  list(
    script = "code/04_analysis/compare_genus_aucs.R",
    description = "compare_genus_aucs.R - Genus vs genus+fit AUC comparison",
    requires = "l2_genus_*_performance.tsv and l2_genus_fit_*_performance.tsv files"
  ),
  list(
    script = "code/04_analysis/build_rocs.R",
    description = "build_rocs.R - ROC curve generation",
    requires = "model Rds files"
  ),
  list(
    script = "code/04_analysis/feature_importance.R",
    description = "feature_importance.R - Feature importance analysis",
    requires = "l2_genus_*_*.Rds files"
  ),
  list(
    script = "code/04_analysis/genus_by_genus_analysis.R",
    description = "genus_by_genus_analysis.R - Genus-level statistical analysis",
    requires = "composite data (loaded via genus_process.R)"
  )
)

# Test each script
results <- list()
for (analysis in analysis_scripts) {
  if (file.exists(analysis$script)) {
    result <- test_analysis_script(analysis$script, analysis$description, analysis$requires)
    results[[analysis$script]] <- result
  } else {
    cat("\n⚠ Script not found:", analysis$script, "\n")
    results[[analysis$script]] <- list(success = FALSE, error = "File not found")
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
  cat("✓ ALL ANALYSIS SCRIPTS WORKED!\n\n")
  cat("Check the figures/ directory for output:\n")
  figure_files <- list.files("figures", full.names = TRUE)
  if (length(figure_files) > 0) {
    for (f in figure_files) {
      cat("  -", f, "\n")
    }
  } else {
    cat("  (No figure files created - scripts may need model/performance files)\n")
  }
} else {
  cat("✗ SOME SCRIPTS FAILED OR WERE SKIPPED:\n\n")
  skipped <- 0
  failed <- 0
  for (name in names(results)) {
    if (!results[[name]]$success) {
      if (!is.null(results[[name]]$skipped) && results[[name]]$skipped) {
        cat("  ⚠", basename(name), ": SKIPPED -", results[[name]]$error, "\n")
        skipped <- skipped + 1
      } else {
        cat("  ✗", basename(name), ":", results[[name]]$error, "\n")
        failed <- failed + 1
      }
    }
  }
  cat("\n")
  if (skipped > 0) {
    cat("To test skipped scripts, create the required files:\n")
    cat("  - Performance files: make processed_data/rf_genus_miseq_performance.tsv\n")
    cat("  - Model files: make processed_data/rf_genus_miseq_1.Rds (for multiple seeds)\n")
    cat("  - Or run: Rscript create_test_data_for_analysis.R\n")
  }
  if (failed > 0) {
    cat("Failed scripts need to be fixed (check error messages above).\n")
  }
}

cat("\n", paste(rep("=", 60), collapse=""), "\n")

