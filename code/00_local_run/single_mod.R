# 1. Set working directory
setwd("/Users/emily/projects/research/parrot/mikropml_demo")

# 2. Load libraries
library(tidyverse)
library(mikropml)

# 3. Prepare data (one-time) - check if already processed
miseq_file <- "processed_data/composite_miseq.rds"
nanopore_file <- "processed_data/composite_nanopore.rds"

if (file.exists(miseq_file) && file.exists(nanopore_file)) {
  # Load pre-processed data (much faster!)
  cat("Loading pre-processed data from RDS files...\n")
  composite_miseq <- readRDS(miseq_file)
  composite_nanopore <- readRDS(nanopore_file)
  cat("✓ Data loaded successfully\n")
} else {
  # Process data if files don't exist
  cat("Processed data not found. Running data preparation...\n")
  source("code/01_data_prep/genus_process.R")
}

# 4. Load model configuration
source("code/02_model_training/l2_genus.R")

# 5. Select dataset and prepare features
composite_data <- composite_miseq
captive_wild_data <- composite_data %>%
  select(samples, taxonomy, rel_abund, captive_wild) %>%
  feature_select() %>%
  pivot_wider(names_from=taxonomy, values_from = rel_abund) %>%
  select(-samples) %>%
  select(captive_wild, everything())

# 6. Preprocess
captive_wild_preprocess <- preprocess_data(
  captive_wild_data,
  outcome_colname = "captive_wild"
)$dat_transformed

# 7. Train model

# Ensure the outcome is a clean factor with expected labels
captive_wild_preprocess$captive_wild <- factor(
  captive_wild_preprocess$captive_wild,
  levels = c("Captive", "Wild_free", "Wild_seized")
)

# Build groups vector as character (not factor), and trim any whitespace
groups_vec <- trimws(as.character(captive_wild_preprocess$captive_wild))

# Create stratified train indices: each class present in both train and test
set.seed(1)
train_inds <- mikropml::create_grouped_data_partition(
  groups = groups_vec,
  group_partitions = list(
    train = c("Captive", "Wild_free", "Wild_seized"),
    test  = c("Captive", "Wild_free", "Wild_seized")
  ),
  training_frac = 0.75
)

# Sanity check: all classes in both splits
table(groups_vec[train_inds])
table(groups_vec[-train_inds])

# Train using explicit indices (note: pass indices via training_frac)
model <- run_ml(
  dataset = captive_wild_preprocess,
  method = approach,
  outcome_colname = "captive_wild",
  training_frac = train_inds,     # <- indices, not a fraction
  kfold = 5,
  cv_times = 15,
  # Optionally provide groups to keep them together during CV if needed
  groups = groups_vec,
  find_feature_importance = TRUE,
  hyperparameters = hyperparameter,
  seed = 1
)

# Confirm test distribution
table(model$test_data$captive_wild)


# Sanity check: confirm all classes present in test split
table(model$test_data$captive_wild)

# 8. Inspect results
model$performance