# Workflow Documentation

## Overview

This repository contains a machine learning pipeline for analyzing microbiome data using the `mikropml` package. The pipeline trains multiple models (L2 regularized logistic regression and Random Forest) with different feature sets and evaluates their performance across 100 random seeds.

## Script Execution Order

### Phase 1: Data Preparation
1. **`code/01_data_prep/genus_process.R`** (sourced by other scripts)
   - Reads raw data files: `baxter.subsample.shared`, `baxter.cons.taxonomy`, `baxter.metadata.tsv`
   - Processes taxonomy data and creates a composite dataset
   - Creates outcome variables: `srn` (serrated/advanced adenoma or cancer) and `lesion`
   - **Note**: This script is sourced by other scripts, not run directly

### Phase 2: Model Training (Parallel Execution)

The following four model types are trained independently. Each runs 100 iterations with different seeds:

2. **`code/02_model_training/run_split.R`** + **`code/02_model_training/l2_genus.R`**
   - Trains L2 regularized logistic regression (glmnet) with genus features only
   - Creates: `processed_data/l2_genus_1.Rds` through `l2_genus_100.Rds`

3. **`code/02_model_training/run_split.R`** + **`code/02_model_training/l2_genus_fit.R`**
   - Trains L2 regularized logistic regression with genus + fit_result features
   - Creates: `processed_data/l2_genus_fit_1.Rds` through `l2_genus_fit_100.Rds`

4. **`code/02_model_training/run_split.R`** + **`code/02_model_training/rf_genus.R`**
   - Trains Random Forest with genus features only
   - Creates: `processed_data/rf_genus_1.Rds` through `rf_genus_100.Rds`

5. **`code/02_model_training/run_split.R`** + **`code/02_model_training/rf_genus_fit.R`**
   - Trains Random Forest with genus + fit_result features
   - Creates: `processed_data/rf_genus_fit_1.Rds` through `rf_genus_fit_100.Rds`

### Phase 3: Model Combination

6. **`code/03_model_combination/combine_models.R`** (run 4 times, once per model type)
   - Combines results from all 100 seeds for each model type
   - Creates performance and hyperparameter files:
     - `processed_data/l2_genus_performance.tsv` and `l2_genus_hp.tsv`
     - `processed_data/l2_genus_fit_performance.tsv` and `l2_genus_fit_hp.tsv`
     - `processed_data/rf_genus_performance.tsv` and `rf_genus_hp.tsv`
     - `processed_data/rf_genus_fit_performance.tsv` and `rf_genus_fit_hp.tsv`

### Phase 4: Analysis and Visualization (Optional)

7. **`code/04_analysis/plot_model_compare.R`**
   - Creates comparison plots of all models
   - Output: `figures/model_compare.png`

8. **`code/04_analysis/compare_genus_aucs.R`**
   - Compares AUC between genus-only and genus+fit models
   - Output: `figures/genus_fit_auc_comparison.tiff`

9. **`code/04_analysis/build_rocs.R`**
   - Builds ROC curves from model results
   - Output: `figures/roc_curve.tiff`

10. **`code/04_analysis/feature_importance.R`**
    - Analyzes feature importance and weights for L2 models
    - Outputs: `figures/l2_weights.tiff` and `figures/l2_feature_importance.tiff`

11. **`code/04_analysis/genus_by_genus_analysis.R`**
    - Performs statistical analysis on individual genera
    - Outputs: `figures/significant_genera.tiff` and `figures/roc_figure.tiff`

## Running on SLURM Cluster

### Prerequisites

1. **Download raw data** (if not already present):
   ```bash
   make raw_data/baxter.metadata.tsv
   ```
   This will download and extract the raw data files.

2. **Update SLURM scripts** with your email and account:
   - Edit `--mail-user=you@umich.edu` to your email in all scripts in `slurm/`
   - Edit `--account=pschloss1` to your SLURM account name in all scripts in `slurm/`

### Method 1: Using SLURM Array Jobs (Recommended)

The repository includes SLURM scripts in the `slurm/` directory that use array jobs to run all 100 seeds in parallel:

#### For L2 Genus Model:
```bash
sbatch slurm/l2_genus.slurm
```
This submits 100 array jobs (seeds 1-100) that each run:
```bash
make processed_data/l2_genus_$SEED.Rds
```

#### For L2 Genus + Fit Model:
```bash
sbatch slurm/l2_genus_fit.slurm
```

#### For RF Genus Model:
```bash
sbatch slurm/rf_genus.slurm
```

#### For RF Genus + Fit Model:
```bash
sbatch slurm/rf_genus_fit.slurm
```

**After all array jobs complete**, combine the results:
```bash
# For each model type, run combine_models.R with all Rds files
# This is typically done by running:
make processed_data/l2_genus_performance.tsv
make processed_data/l2_genus_fit_performance.tsv
make processed_data/rf_genus_performance.tsv
make processed_data/rf_genus_fit_performance.tsv
```

### Method 2: Using Makefile Directly

The Makefile orchestrates the entire pipeline. You can run:

```bash
# Run all L2 genus models (100 seeds)
make processed_data/l2_genus_performance.tsv

# Run all L2 genus+fit models (100 seeds)
make processed_data/l2_genus_fit_performance.tsv

# Run all RF genus models (100 seeds)
make processed_data/rf_genus_performance.tsv

# Run all RF genus+fit models (100 seeds)
make processed_data/rf_genus_fit_performance.tsv
```

**Note**: This will run sequentially unless you use parallel make:
```bash
make -j 16 processed_data/l2_genus_performance.tsv
```

### Method 3: Interactive Session

For testing or development, use the interactive SLURM session:

```bash
sbatch slurm/interactive.slurm
```

This gives you an interactive bash session on a compute node where you can run R scripts directly.

### Method 4: Single Job Submission

For running a single seed or testing:

```bash
sbatch slurm/single.slurm
```

Then manually run:
```bash
make processed_data/l2_genus_1.Rds
```

## SLURM Script Details

All SLURM scripts are located in the `slurm/` directory.

### Array Job Scripts (`slurm/l2_genus.slurm`, `slurm/l2_genus_fit.slurm`, etc.)
- **Array size**: 1-100 (100 parallel jobs)
- **Resources per job**: 1 CPU, 4GB RAM, 24 hours
- **Output**: `%x.o%A_%a` (script name, job ID, array task ID)

### Interactive Script (`slurm/interactive.slurm`)
- **Resources**: 1 CPU, 6GB RAM, 2 hours
- **Purpose**: Interactive development/testing

### Single Job Script (`slurm/single.slurm`)
- **Resources**: 16 CPUs, 64GB RAM (4GB per CPU), 2 hours
- **Purpose**: Running multiple seeds in parallel on a single node

## Complete Workflow Example

```bash
# 1. Download data (if needed)
make raw_data/baxter.metadata.tsv

# 2. Submit all model training jobs
sbatch slurm/l2_genus.slurm
sbatch slurm/l2_genus_fit.slurm
sbatch slurm/rf_genus.slurm
sbatch slurm/rf_genus_fit.slurm

# 3. Wait for all jobs to complete, then combine results
# (You can check job status with: squeue -u $USER)
make processed_data/l2_genus_performance.tsv
make processed_data/l2_genus_fit_performance.tsv
make processed_data/rf_genus_performance.tsv
make processed_data/rf_genus_fit_performance.tsv

# 4. Run analysis scripts (optional)
Rscript code/04_analysis/plot_model_compare.R
Rscript code/04_analysis/compare_genus_aucs.R
Rscript code/04_analysis/build_rocs.R
Rscript code/04_analysis/feature_importance.R
Rscript code/04_analysis/genus_by_genus_analysis.R
```

## File Dependencies

```
raw_data/
  ├── baxter.metadata.tsv
  ├── baxter.cons.taxonomy
  └── baxter.subsample.shared

code/
  ├── 01_data_prep/
  │   └── genus_process.R (sourced by others)
  ├── 02_model_training/
  │   ├── run_split.R (wrapper for model training)
  │   ├── l2_genus.R (model config)
  │   ├── l2_genus_fit.R (model config)
  │   ├── rf_genus.R (model config)
  │   └── rf_genus_fit.R (model config)
  ├── 03_model_combination/
  │   └── combine_models.R (combines results)
  └── 04_analysis/
      ├── plot_model_compare.R
      ├── compare_genus_aucs.R
      ├── build_rocs.R
      ├── feature_importance.R
      ├── genus_by_genus_analysis.R
      ├── get_pvalues.R
      ├── genus_ml.R
      ├── feature_importance_example.R
      └── process_pooled_data.R

slurm/
  ├── l2_genus.slurm
  ├── l2_genus_fit.slurm
  ├── rf_genus.slurm
  ├── rf_genus_fit.slurm
  ├── interactive.slurm
  ├── single.slurm
  └── array.slurm

processed_data/
  ├── l2_genus_1.Rds ... l2_genus_100.Rds
  ├── l2_genus_fit_1.Rds ... l2_genus_fit_100.Rds
  ├── rf_genus_1.Rds ... rf_genus_100.Rds
  ├── rf_genus_fit_1.Rds ... rf_genus_fit_100.Rds
  └── *_performance.tsv, *_hp.tsv (combined results)
```

## Notes

- Each model training run uses a different random seed (1-100) for reproducibility
- Models are trained with 5-fold cross-validation, 100 CV times, 80% training split
- Feature importance is calculated for all models
- The pipeline uses the `mikropml` R package for machine learning
- All SLURM scripts need to be customized with your email and account information

