# Understanding the 8 Model Types

The pipeline runs **8 different model configurations**, which are combinations of:

## Dimensions:

1. **2 Machine Learning Methods:**
   - `l2` = L2 regularized logistic regression (glmnet)
   - `rf` = Random Forest

2. **2 Feature Sets:**
   - `genus` = Microbiome genus features only
   - `genus_fit` = Microbiome genus features + `given_probiotic` (probiotic status)

3. **2 Datasets:**
   - `miseq` = MiSeq sequencing data
   - `nanopore` = Nanopore sequencing data

## The 8 Model Types:

### L2 Regularized Logistic Regression Models:

1. **`l2_genus_miseq`**
   - Method: L2 regularized logistic regression
   - Features: Genus abundances only
   - Dataset: MiSeq
   - File: `processed_data/l2_genus_miseq_1.Rds` through `l2_genus_miseq_100.Rds`

2. **`l2_genus_nanopore`**
   - Method: L2 regularized logistic regression
   - Features: Genus abundances only
   - Dataset: Nanopore
   - File: `processed_data/l2_genus_nanopore_1.Rds` through `l2_genus_nanopore_100.Rds`

3. **`l2_genus_fit_miseq`**
   - Method: L2 regularized logistic regression
   - Features: Genus abundances + `given_probiotic` (probiotic status)
   - Dataset: MiSeq
   - File: `processed_data/l2_genus_fit_miseq_1.Rds` through `l2_genus_fit_miseq_100.Rds`

4. **`l2_genus_fit_nanopore`**
   - Method: L2 regularized logistic regression
   - Features: Genus abundances + `given_probiotic` (probiotic status)
   - Dataset: Nanopore
   - File: `processed_data/l2_genus_fit_nanopore_1.Rds` through `l2_genus_fit_nanopore_100.Rds`

### Random Forest Models:

5. **`rf_genus_miseq`**
   - Method: Random Forest
   - Features: Genus abundances only
   - Dataset: MiSeq
   - File: `processed_data/rf_genus_miseq_1.Rds` through `rf_genus_miseq_100.Rds`

6. **`rf_genus_nanopore`**
   - Method: Random Forest
   - Features: Genus abundances only
   - Dataset: Nanopore
   - File: `processed_data/rf_genus_nanopore_1.Rds` through `rf_genus_nanopore_100.Rds`

7. **`rf_genus_fit_miseq`**
   - Method: Random Forest
   - Features: Genus abundances + `given_probiotic` (probiotic status)
   - Dataset: MiSeq
   - File: `processed_data/rf_genus_fit_miseq_1.Rds` through `rf_genus_fit_miseq_100.Rds`

8. **`rf_genus_fit_nanopore`**
   - Method: Random Forest
   - Features: Genus abundances + `given_probiotic` (probiotic status)
   - Dataset: Nanopore
   - File: `processed_data/rf_genus_fit_nanopore_1.Rds` through `rf_genus_fit_nanopore_100.Rds`

## Why These Comparisons?

This design allows you to answer several questions:

1. **Which ML method works better?** (L2 vs Random Forest)
2. **Does probiotic status improve predictions?** (genus vs genus_fit)
3. **Which sequencing platform performs better?** (miseq vs nanopore)
4. **What's the best combination?** (e.g., RF + probiotic + nanopore)

## Output Files:

Each model type produces:
- **100 model files**: `*_1.Rds` through `*_100.Rds` (one per seed)
- **1 performance file**: `*_performance.tsv` (combined results from all 100 seeds)
- **1 hyperparameter file**: `*_hp.tsv` (hyperparameter tuning results)

## Total Models:

- 8 model types × 100 seeds = **800 individual model runs**
- Each run takes ~5-15 minutes
- Total time depends on parallelization

