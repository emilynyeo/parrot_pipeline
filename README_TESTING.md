# Testing Your Pipeline Locally

Before running the full pipeline on the cluster, you should test locally to verify everything works. Here are several ways to test:

## Quick Mock Run (Recommended First Step)

This runs a minimal test that verifies all components work without intensive computation:

```bash
Rscript test_mock_run.R
```

This will:
- ✓ Check all required files exist
- ✓ Load and verify data
- ✓ Test preprocessing
- ✓ Run a minimal model (cv_times=2, kfold=3) just to verify setup
- ✓ Test file creation
- ✓ Report any errors

**Time:** ~1-2 minutes per model type

## Single Model Test (More Complete)

Test a single model with reduced cross-validation:

```bash
# Test L2 genus model on miseq
./test_local.sh

# Or modify test_local.sh to test different models:
# Change MODEL_TYPE to: l2_genus, l2_genus_fit, rf_genus, or rf_genus_fit
# Change DATASET to: miseq or nanopore
```

Or use the R version:

```bash
Rscript test_local.R
```

**Time:** ~5-10 minutes (uses cv_times=10 instead of 100)

## Using Makefile for Single Seeds

Test individual seeds using the Makefile:

```bash
# Test a single seed for miseq
make processed_data/l2_genus_miseq_1.Rds

# Test a single seed for nanopore  
make processed_data/l2_genus_nanopore_1.Rds

# Test different model types
make processed_data/rf_genus_miseq_1.Rds
make processed_data/l2_genus_fit_miseq_1.Rds
```

**Time:** ~10-15 minutes per seed (full cv_times=100)

## Testing Model Combination

After you have a few model files, test the combination script:

```bash
# Create a few test models first (seeds 1-3)
make processed_data/l2_genus_miseq_1.Rds
make processed_data/l2_genus_miseq_2.Rds
make processed_data/l2_genus_miseq_3.Rds

# Test combining them
Rscript code/03_model_combination/combine_models.R \
  processed_data/l2_genus_miseq_1.Rds \
  processed_data/l2_genus_miseq_2.Rds \
  processed_data/l2_genus_miseq_3.Rds
```

## Testing Analysis Scripts

Once you have some model results, test the analysis scripts:

```bash
# Make sure you have performance files first
# Then test individual analysis scripts
Rscript code/04_analysis/plot_model_compare.R
Rscript code/04_analysis/compare_genus_aucs.R
```

## Recommended Testing Workflow

1. **First**: Run `test_mock_run.R` to verify basic setup
   ```bash
   Rscript test_mock_run.R
   ```

2. **Second**: Test one complete model run locally
   ```bash
   make processed_data/l2_genus_miseq_1.Rds
   ```

3. **Third**: Verify the output looks correct
   ```r
   # In R
   model <- readRDS("processed_data/l2_genus_miseq_1.Rds")
   str(model)
   model$performance
   ```

4. **Fourth**: Test model combination with a few seeds
   ```bash
   make processed_data/l2_genus_miseq_1.Rds
   make processed_data/l2_genus_miseq_2.Rds
   make processed_data/l2_genus_miseq_3.Rds
   make processed_data/l2_genus_miseq_performance.tsv
   ```

5. **Finally**: If all tests pass, submit to cluster!

## Troubleshooting

### Common Issues:

1. **"composite_miseq not found"**
   - Make sure `genus_process.R` runs successfully
   - Check that your data files are in the correct location

2. **"captive_wild column not found"**
   - Verify your metadata has the `captive_wild` column
   - Check that `genus_process.R` creates it correctly

3. **"Feature script not found"**
   - Verify feature scripts exist in `code/02_model_training/`
   - Check file names match exactly

4. **Memory issues**
   - Reduce dataset size for testing
   - Use fewer features in feature_select()

5. **Package errors**
   - Install missing packages: `install.packages(c("mikropml", "tidyverse"))`

## What to Check Before Cluster Submission

- [ ] Mock run completes without errors
- [ ] At least one model file can be created locally
- [ ] Model file can be read back and has expected structure
- [ ] Model combination script works
- [ ] Output file names match expected patterns
- [ ] All required R packages are available
- [ ] Data files are accessible from cluster paths

