# Code Directory Structure

This directory is organized by workflow phase to make it clear which scripts belong to which stage of the analysis pipeline.

## Directory Organization

### `01_data_prep/`
**Phase 1: Data Preparation**
- `genus_process.R` - Processes raw microbiome data files and creates composite dataset
  - This script is sourced by other scripts, not run directly

### `02_model_training/`
**Phase 2: Model Training**
- `run_split.R` - Main wrapper script that runs model training with different seeds
- `l2_genus.R` - Configuration for L2 regularized logistic regression (genus features only)
- `l2_genus_fit.R` - Configuration for L2 regularized logistic regression (genus + given_probiotic)
- `rf_genus.R` - Configuration for Random Forest (genus features only)
- `rf_genus_fit.R` - Configuration for Random Forest (genus + given_probiotic)

### `03_model_combination/`
**Phase 3: Model Combination**
- `combine_models.R` - Combines results from multiple seeds into performance and hyperparameter files

### `04_analysis/`
**Phase 4: Analysis and Visualization**
- `plot_model_compare.R` - Creates comparison plots of all models
- `compare_genus_aucs.R` - Compares AUC between genus-only and genus+fit models
- `build_rocs.R` - Builds ROC curves from model results
- `feature_importance.R` - Analyzes feature importance and weights for L2 models
- `genus_by_genus_analysis.R` - Performs statistical analysis on individual genera
- `get_pvalues.R` - Helper functions for calculating p-values
- `genus_ml.R` - Example script for running ML models interactively
- `feature_importance_example.R` - Example script for feature importance analysis
- `process_pooled_data.R` - Processes pooled model data

## Usage

Scripts are typically run via the Makefile or SLURM scripts (located in `../slurm/`). See `../WORKFLOW.md` for detailed execution instructions.

