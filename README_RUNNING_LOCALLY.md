# Running the Full Pipeline Locally

## Overview

The full pipeline runs **800 models total**:
- 4 model types: `l2_genus`, `l2_genus_fit`, `rf_genus`, `rf_genus_fit`
- 2 datasets: `miseq`, `nanopore`
- 100 seeds each

**Estimated time**: 3-8 days if run sequentially, or 8-25 hours with 8 parallel jobs

## Option 1: Run Everything (Full Pipeline)

### Using the helper script:
```bash
chmod +x run_full_pipeline_local.sh
./run_full_pipeline_local.sh
```

This will:
- Run all 800 models in parallel (8 jobs at a time by default)
- Create all performance files automatically
- Take several hours to days depending on your system

### Using Makefile directly:
```bash
# Run all models for one dataset/model type
make -j 8 processed_data/l2_genus_miseq_performance.tsv

# Or run all at once (will use lots of resources)
make -j 8 processed_data/l2_genus_miseq_performance.tsv \
         processed_data/l2_genus_nanopore_performance.tsv \
         processed_data/l2_genus_fit_miseq_performance.tsv \
         processed_data/l2_genus_fit_nanopore_performance.tsv \
         processed_data/rf_genus_miseq_performance.tsv \
         processed_data/rf_genus_nanopore_performance.tsv \
         processed_data/rf_genus_fit_miseq_performance.tsv \
         processed_data/rf_genus_fit_nanopore_performance.tsv
```

## Option 2: Run a Subset First (Recommended)

Test with a smaller number of seeds:

```bash
chmod +x run_pipeline_subset.sh
# Edit the script to set MODEL_TYPE, DATASET, SEED_START, SEED_END
./run_pipeline_subset.sh
```

Or manually:
```bash
# Run just seeds 1-10 for one model type
for SEED in {1..10}; do
  make processed_data/rf_genus_miseq_${SEED}.Rds
done

# Then combine them
Rscript code/03_model_combination/combine_models.R \
  processed_data/rf_genus_miseq_{1..10}.Rds
```

## Option 3: Run One Model Type at a Time

Run each model type separately to spread the work over time:

```bash
# Day 1: L2 genus models
make -j 8 processed_data/l2_genus_miseq_performance.tsv
make -j 8 processed_data/l2_genus_nanopore_performance.tsv

# Day 2: L2 genus + probiotic models
make -j 8 processed_data/l2_genus_fit_miseq_performance.tsv
make -j 8 processed_data/l2_genus_fit_nanopore_performance.tsv

# Day 3: RF genus models
make -j 8 processed_data/rf_genus_miseq_performance.tsv
make -j 8 processed_data/rf_genus_nanopore_performance.tsv

# Day 4: RF genus + probiotic models
make -j 8 processed_data/rf_genus_fit_miseq_performance.tsv
make -j 8 processed_data/rf_genus_fit_nanopore_performance.tsv
```

## Monitoring Progress

### Check how many models are done:
```bash
# Count completed models
ls processed_data/*_miseq_*.Rds | wc -l
ls processed_data/*_nanopore_*.Rds | wc -l

# See latest files
ls -lt processed_data/*.Rds | head -10
```

### Check system resources:
```bash
# Monitor CPU and memory usage
top
# or
htop  # if installed
```

### Check for errors:
```bash
# Look for any failed runs (files that are too small or corrupted)
find processed_data -name "*.Rds" -size -1k
```

## Performance Tips

1. **Adjust parallel jobs**: Edit `run_full_pipeline_local.sh` and change `PARALLEL_JOBS=8` to match your CPU cores (use 50-75% of available cores)

2. **Run overnight**: Start the full pipeline before leaving for the day

3. **Monitor disk space**: Each model file is ~1-5 MB, so 800 models = ~800 MB - 4 GB

4. **Use `nohup` for long runs**:
   ```bash
   nohup ./run_full_pipeline_local.sh > pipeline.log 2>&1 &
   ```

5. **Check logs**: If using nohup, monitor progress:
   ```bash
   tail -f pipeline.log
   ```

## Stopping and Resuming

- **To stop**: Press Ctrl+C (or kill the process)
- **Already completed models won't be rerun** (Makefile checks timestamps)
- **To resume**: Just run the same command again - it will skip completed models

## After All Models Complete

Once all performance files are created, run the analysis scripts:

```bash
# Generate comparison plots
Rscript code/04_analysis/plot_model_compare.R

# Compare genus vs genus+probiotic
Rscript code/04_analysis/compare_genus_aucs.R

# Build ROC curves
Rscript code/04_analysis/build_rocs.R

# Feature importance
Rscript code/04_analysis/feature_importance.R
```

## Quick Start (Recommended First Step)

Before running everything, test with a small subset:

```bash
# Run 5 seeds for one model type
for SEED in {1..5}; do
  make processed_data/rf_genus_miseq_${SEED}.Rds
done

# Combine and check results
Rscript code/03_model_combination/combine_models.R \
  processed_data/rf_genus_miseq_{1..5}.Rds

# Check the performance file
head processed_data/rf_genus_miseq_performance.tsv
```

If this works, you're ready to run the full pipeline!

