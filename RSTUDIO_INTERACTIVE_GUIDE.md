# Running Scripts Interactively in RStudio

This guide shows you how to run the model training and analysis scripts line-by-line in RStudio for interactive exploration and debugging.

## Prerequisites

1. **Set Working Directory**
   ```r
   setwd("/Users/emily/projects/research/parrot/mikropml_demo")
   ```

2. **Load Required Libraries**
   ```r
   library(tidyverse)
   library(mikropml)
   library(broom)
   library(ggtext)
   library(rlang)
   ```

3. **Verify Data Files Exist**
   The scripts expect data in:
   - `/Users/emily/projects/research/parrot_project/MelissaAnalysis/`

---

## Part 1: Data Preparation (One-Time Setup)

Run this once to create the processed datasets. This is what `genus_process.R` does:

```r
# Source the data preparation script
source("code/01_data_prep/genus_process.R")
```

This will:
- Load and process taxonomy data
- Load read data (miseq and nanopore)
- Load and join metadata
- Create `composite_miseq` and `composite_nanopore` datasets
- Save them to `processed_data/composite_miseq.rds` and `processed_data/composite_nanopore.rds`

# After running, you can verify:
str(composite_miseq)
str(composite_nanopore)
```

**Note:** If you've already run the pipeline, you can skip this and load the saved data:
```r
composite_miseq <- readRDS("processed_data/composite_miseq.rds")
composite_nanopore <- readRDS("processed_data/composite_nanopore.rds")
```

---

## Part 2: Model Training (Interactive)

### Step-by-Step Model Training

Here's how to run a model training script interactively, breaking down what `run_split.R` does:

#### Example 1: L2 Genus Model (MiSeq dataset, seed = 1)

```r
# 1. Source the data preparation (if not already done)
source("code/01_data_prep/genus_process.R")

# 2. Load mikropml
library(mikropml)

# 3. Source the feature selection script (defines feature_select() and hyperparameters)
source("code/02_model_training/l2_genus.R")
# This sets:
#   - feature_select() function
#   - approach = "glmnet"
#   - hyperparameter = list(alpha = 0, lambda = c(0.1, 1, 2, 3, 4, 5))

# 4. Select dataset
dataset_name <- "miseq"  # or "nanopore"
composite_data <- if(dataset_name == "miseq") {
  composite_miseq
} else {
  composite_nanopore
}

# 5. Set seed
seed <- 1

# 6. Prepare features
captive_wild_data <- composite_data %>%
  select(samples, taxonomy, rel_abund, captive_wild) %>%
  feature_select() %>%  # This function is defined in l2_genus.R
  pivot_wider(names_from=taxonomy, values_from = rel_abund) %>%
  select(-samples) %>%
  select(captive_wild, everything())

# 7. Preprocess data (remove correlated and low variance variables)
captive_wild_preprocess <- preprocess_data(
  captive_wild_data,
  outcome_colname = "captive_wild"
)$dat_transformed

# 8. Train the model
model <- run_ml(
  captive_wild_preprocess,
  method = approach,  # "glmnet" from l2_genus.R
  outcome_colname = "captive_wild",
  kfold = 5,
  cv_times = 20,
  training_frac = 0.8,
  find_feature_importance = TRUE,
  hyperparameters = hyperparameter,  # From l2_genus.R
  seed = seed
)

# 9. Save the model
output_file <- "processed_data/l2_genus_miseq_1.Rds"
saveRDS(model, file = output_file)

# 10. Inspect the model
str(model)
model$performance
model$trained_model
```

#### Example 2: Random Forest Model (Nanopore dataset, seed = 1)

```r
# Same steps, but use rf_genus.R instead
source("code/02_model_training/rf_genus.R")
# This sets:
#   - approach = "rf"
#   - hyperparameter = list(mtry = c(2, 4, 8, 17, 34))

dataset_name <- "nanopore"
composite_data <- composite_nanopore
seed <- 1

captive_wild_data <- composite_data %>%
  select(samples, taxonomy, rel_abund, captive_wild) %>%
  feature_select() %>%
  pivot_wider(names_from=taxonomy, values_from = rel_abund) %>%
  select(-samples) %>%
  select(captive_wild, everything())

captive_wild_preprocess <- preprocess_data(
  captive_wild_data,
  outcome_colname = "captive_wild"
)$dat_transformed

model <- run_ml(
  captive_wild_preprocess,
  method = approach,  # "rf"
  outcome_colname = "captive_wild",
  kfold = 5,
  cv_times = 20,
  training_frac = 0.8,
  find_feature_importance = TRUE,
  hyperparameters = hyperparameter,
  seed = seed
)

saveRDS(model, file = "processed_data/rf_genus_nanopore_1.Rds")
```

#### Example 3: L2 Genus Fit Model (includes given_probiotic)

```r
# Use l2_genus_fit.R which includes given_probiotic in feature selection
source("code/02_model_training/l2_genus_fit.R")

dataset_name <- "miseq"
composite_data <- composite_miseq
seed <- 1

# Note: This includes given_probiotic in the feature selection
captive_wild_data <- composite_data %>%
  select(samples, taxonomy, rel_abund, given_probiotic, captive_wild) %>%
  feature_select() %>%  # From l2_genus_fit.R - includes given_probiotic
  pivot_wider(names_from=taxonomy, values_from = rel_abund) %>%
  select(-samples) %>%
  select(captive_wild, everything())

# Rest is the same...
captive_wild_preprocess <- preprocess_data(
  captive_wild_data,
  outcome_colname = "captive_wild"
)$dat_transformed

model <- run_ml(
  captive_wild_preprocess,
  method = approach,
  outcome_colname = "captive_wild",
  kfold = 5,
  cv_times = 20,
  training_frac = 0.8,
  find_feature_importance = TRUE,
  hyperparameters = hyperparameter,
  seed = seed
)

saveRDS(model, file = "processed_data/l2_genus_fit_miseq_1.Rds")
```

### Inspecting Models Interactively

```r
# Load a saved model
model <- readRDS("processed_data/l2_genus_miseq_1.Rds")

# Check performance metrics
model$performance
# Look for: AUC, cv_metric_AUC, etc.

# Check hyperparameters used
model$trained_model$bestTune

# Check feature importance (if calculated)
model$feature_importance

# Check test data predictions
predictions <- predict(model$trained_model, model$test_data, type = "prob")
head(predictions)

# Check actual vs predicted
table(model$test_data$captive_wild, 
      predict(model$trained_model, model$test_data))
```

---

## Part 3: Model Combination (Creating Performance Files)

After training multiple models (e.g., seeds 1-10), combine them:

```r
# Load the combine script
source("code/03_model_combination/combine_models.R")

# Or run it directly with file list
rds_files <- paste0("processed_data/l2_genus_miseq_", 1:10, ".Rds")
# Make sure files exist
rds_files <- rds_files[file.exists(rds_files)]

# Run combine_models.R with these files
# (The script reads command line args, so you'd need to modify it or run via command line)
# Or manually combine:

library(tidyverse)

# Read all model files
models <- map(rds_files, readRDS)

# Extract performance
performance <- map_dfr(models, ~ .x$performance) %>%
  mutate(seed = 1:length(models))

# Save
write_tsv(performance, "processed_data/l2_genus_miseq_performance.tsv")
```

---

## Part 4: Analysis Scripts (Interactive)

### 4.1: Model Comparison Plot

```r
library(tidyverse)

# Function to read performance files
read_performance <- function(file_name) {
  read_tsv(file_name) %>%
    mutate(method = str_replace(file_name, ".*/(.*)_performance.tsv", "\\1"),
           dataset = if_else(str_detect(method, "_miseq"), "MiSeq",
                           if_else(str_detect(method, "_nanopore"), "Nanopore", "Unknown")),
           method = str_replace(method, "_(miseq|nanopore)", ""))
}

# Read all performance files
performance_data <- list.files(
  path = "processed_data",
  pattern = "performance.tsv",
  full.names = TRUE
) %>%
  map_dfr(., read_performance) %>%
  select(method, dataset, cv_metric_AUC, AUC) %>%
  rename(training = cv_metric_AUC, testing = AUC) %>%
  pivot_longer(cols = c(training, testing), 
               names_to = "training_testing",
               values_to = "AUC") %>%
  mutate(
    training_testing = factor(training_testing, levels = c('training', "testing")),
    model = str_replace(method, "_genus.*", ""),
    model = if_else(model == "l2", "L2 Regularized\nLogistic Regression", "Random Forest"),
    method = if_else(str_detect(method, "fit"), "genus+fit", "genus"),
    dataset = factor(dataset, levels = c("MiSeq", "Nanopore"))
  )

# Create plot
p <- performance_data %>%
  ggplot(aes(x = method, y = AUC, color = training_testing, shape = dataset)) +
  geom_hline(yintercept = 0.65, color = "gray", linetype = "dashed") +
  facet_wrap(~model, nrow = 1, scales = "free_x", strip.position = "bottom") +
  stat_summary(
    fun.data = median_hilow,
    fun.args = list(conf.int = 0.5),
    geom = "pointrange",
    position = position_dodge(width = 0.5),
    aes(group = interaction(training_testing, dataset))
  ) +
  lims(y = c(0.5, 1)) +
  labs(x = NULL, y = "Area under the receiver\noperator characteristic curve", shape = "Dataset") +
  scale_color_manual(
    name = NULL,
    breaks = c("training", "testing"),
    labels = c("Training", "Testing"),
    values = c("gray", "dodgerblue")
  ) +
  scale_shape_manual(values = c(16, 17)) +
  theme_classic() +
  theme(strip.placement = "outside", strip.background = element_blank())

print(p)
ggsave("figures/model_compare.png", width = 7, height = 4)
```

### 4.2: Compare Genus vs Genus+Fit AUCs

```r
library(tidyverse)
source('code/04_analysis/get_pvalues.R')

# Function to compare genus vs genus_fit for a specific dataset
compare_genus_fit <- function(dataset_name) {
  genus_file <- paste0("processed_data/l2_genus_", dataset_name, "_performance.tsv")
  genus_fit_file <- paste0("processed_data/l2_genus_fit_", dataset_name, "_performance.tsv")
  
  if(!file.exists(genus_file) || !file.exists(genus_fit_file)) {
    warning(paste("Files not found for dataset:", dataset_name))
    return(NULL)
  }
  
  genus <- read_tsv(genus_file) %>%
    mutate(condition = "genus", dataset = dataset_name)
  
  genus_fit <- read_tsv(genus_fit_file) %>%
    mutate(condition = "genus_fit", dataset = dataset_name)
  
  bind_rows(genus, genus_fit) %>%
    select(condition, dataset, AUC)
}

# Compare for both datasets
auc_comparison_miseq <- compare_genus_fit("miseq")
auc_comparison_nanopore <- compare_genus_fit("nanopore")

auc_comparison <- bind_rows(auc_comparison_miseq, auc_comparison_nanopore)

# Plot comparison
p <- auc_comparison %>%
  ggplot(aes(x = AUC, fill = condition, linetype = dataset)) +
  geom_density(alpha = 0.5) +
  stat_summary(aes(x = 0.8, y = AUC, xintercept = stat(y)),
               fun = mean, geom = "vline") +
  labs(y = "Density", linetype = "Dataset") +
  scale_fill_manual(values = c("genus" = "gray", "genus_fit" = "dodgerblue"))

print(p)
ggsave("figures/genus_fit_auc_comparison.tiff", width = 6, height = 4)

# Summary statistics
auc_comparison %>%
  group_by(condition, dataset) %>%
  summarize(mean_auc = mean(AUC), .groups = "drop") %>%
  pivot_wider(names_from = condition, values_from = mean_auc) %>%
  mutate(diff = genus_fit - genus)

# Permutation tests
if(!is.null(auc_comparison_miseq)) {
  p.value.miseq <- perm_p_value_cond(auc_comparison_miseq, "genus", "genus_fit")
  print(paste("MiSeq p-value:", p.value.miseq))
}

if(!is.null(auc_comparison_nanopore)) {
  p.value.nanopore <- perm_p_value_cond(auc_comparison_nanopore, "genus", "genus_fit")
  print(paste("Nanopore p-value:", p.value.nanopore))
}
```

### 4.3: Build ROC Curves

```r
library(tidyverse)
library(rlang)

# Helper functions (from build_rocs.R)
get_sens_spec_lookup <- function(data, outcome_levels) {
  total <- data %>%
    count(observed) %>%
    pivot_wider(names_from = observed, values_from = n)
  
  positive_class <- outcome_levels[1]
  negative_classes <- outcome_levels[-1]
  
  prob_col <- sym(positive_class)
  
  data %>%
    arrange(desc(!!prob_col)) %>%
    mutate(
      is_positive = (observed == positive_class),
      tp = cumsum(is_positive),
      fp = cumsum(!is_positive),
      total_positive = sum(observed == positive_class),
      total_negative = sum(observed %in% negative_classes),
      sensitivity = tp / total_positive,
      fpr = fp / total_negative,
      specificity = 1 - fpr
    ) %>%
    select(sensitivity, specificity, fpr)
}

get_sensitivity <- function(x, data) {
  data %>%
    filter(specificity - x >= 0) %>%
    top_n(sensitivity, n = 1) %>%
    mutate(specificity = x, fpr = 1 - x) %>%
    distinct()
}

get_pooled_sens_spec <- function(file_name, specificity) {
  model <- readRDS(file_name)
  
  prob <- predict(model$trained_model, model$test_data, type = "prob")
  observed <- model$test_data$captive_wild
  
  outcome_levels <- levels(observed)
  if(is.null(outcome_levels)) {
    outcome_levels <- unique(observed) %>% sort()
  }
  
  prob_obs <- bind_cols(prob, observed = observed) %>%
    select(all_of(outcome_levels), observed)
  
  sens_spec_lookup <- get_sens_spec_lookup(prob_obs, outcome_levels)
  
  map_dfr(specificity, get_sensitivity, sens_spec_lookup) %>%
    mutate(model = str_replace(file_name,
                               "processed_data/(.*)_\\d*.Rds",
                               "\\1"))
}

# Calculate ROC curves
specificity <- seq(0, 1, 0.01)

pooled_sens_spec <- list.files(
  path = "processed_data",
  pattern = ".*_(miseq|nanopore)_\\d*\\.Rds",
  full.names = TRUE
) %>%
  map_dfr(get_pooled_sens_spec, specificity)

# Plot
p <- pooled_sens_spec %>%
  group_by(model, specificity) %>%
  summarize(
    lquartile = quantile(sensitivity, prob = 0.25),
    uquartile = quantile(sensitivity, prob = 0.75),
    sensitivity = median(sensitivity),
    .groups = "drop"
  ) %>%
  ggplot(aes(x = 1 - specificity, y = sensitivity,
             ymin = lquartile, ymax = uquartile)) +
  geom_ribbon(alpha = 0.25, aes(fill = model)) +
  geom_step(aes(color = model)) +
  theme_classic() +
  theme(legend.position = c(0.8, 0.2))

print(p)
ggsave("figures/roc_curve.tiff", width = 5, height = 5)
```

### 4.4: Feature Importance Analysis

```r
library(tidyverse)
library(ggtext)

# Function to get weights for a dataset
get_weights_dataset <- function(dataset_name) {
  l2_files <- list.files(
    path = "processed_data",
    pattern = paste0("l2_genus_", dataset_name, "_\\d*\\.Rds"),
    full.names = TRUE
  )
  
  if(length(l2_files) == 0) {
    warning(paste("No files found for dataset:", dataset_name))
    return(NULL)
  }
  
  get_weights <- function(file_name) {
    model <- readRDS(file_name) %>%
      pluck("trained_model")
    
    coef(model$finalModel, model$bestTune$lambda) %>%
      as.matrix %>%
      as_tibble(rownames = "feature") %>%
      rename(weight = `1`) %>%
      mutate(
        seed = str_replace(file_name,
                          paste0("processed_data/l2_genus_", dataset_name, "_(\\d*)\\.Rds"),
                          "\\1"),
        dataset = dataset_name
      )
  }
  
  map_dfr(l2_files, get_weights)
}

# Get weights for both datasets
l2_weights_miseq <- get_weights_dataset("miseq")
l2_weights_nanopore <- get_weights_dataset("nanopore")

l2_weights <- bind_rows(l2_weights_miseq, l2_weights_nanopore)

# Plot weights
p <- l2_weights %>%
  filter(feature != "(Intercept)") %>%
  group_by(feature, dataset) %>%
  summarize(
    median = median(weight),
    l_quartile = quantile(weight, prob = 0.25),
    u_quartile = quantile(weight, prob = 0.75),
    .groups = "drop"
  ) %>%
  mutate(
    feature = str_replace(feature, "(.*)", "*\\1*"),
    feature = str_replace(feature, "(.*)_unclassified\\*", "Unclassified \\1*"),
    feature = str_replace(feature, "_(.*)\\*", "* \\1"),
    feature = fct_reorder(feature, median)
  ) %>%
  filter(abs(median) > 0.01) %>%
  ggplot(aes(x = median, y = feature, xmin = l_quartile, xmax = u_quartile, 
             color = dataset, shape = dataset)) +
  geom_vline(xintercept = 0, color = "gray") +
  geom_point(position = position_dodge(width = 0.3)) +
  geom_linerange(position = position_dodge(width = 0.3)) +
  labs(x = "Weights", y = NULL, color = "Dataset", shape = "Dataset") +
  theme_classic() +
  theme(axis.text.y = element_markdown()) +
  scale_color_manual(values = c("miseq" = "dodgerblue", "nanopore" = "darkgreen"))

print(p)
ggsave("figures/l2_weights.tiff", width = 6, height = 5)

# Feature importance (permutation-based)
get_feature_importance_dataset <- function(dataset_name) {
  l2_files <- list.files(
    path = "processed_data",
    pattern = paste0("l2_genus_", dataset_name, "_\\d*\\.Rds"),
    full.names = TRUE
  )
  
  if(length(l2_files) == 0) {
    warning(paste("No files found for dataset:", dataset_name))
    return(NULL)
  }
  
  get_feature_importance <- function(file_name) {
    feature_importance <- readRDS(file_name) %>%
      pluck("feature_importance") %>%
      as_tibble() %>%
      select(names, perf_metric, perf_metric_diff) %>%
      mutate(dataset = dataset_name)
  }
  
  map_dfr(l2_files, get_feature_importance)
}

l2_feature_importance_miseq <- get_feature_importance_dataset("miseq")
l2_feature_importance_nanopore <- get_feature_importance_dataset("nanopore")

l2_feature_importance <- bind_rows(l2_feature_importance_miseq, l2_feature_importance_nanopore)

# Plot feature importance
p <- l2_feature_importance %>%
  rename(feature = names) %>%
  group_by(feature, dataset) %>%
  summarize(
    median = median(perf_metric_diff),
    l_quartile = quantile(perf_metric_diff, prob = 0.25),
    u_quartile = quantile(perf_metric_diff, prob = 0.75),
    .groups = "drop"
  ) %>%
  mutate(
    feature = str_replace(feature, "(.*)", "*\\1*"),
    feature = str_replace(feature, "(.*)_unclassified\\*", "Unclassified \\1*"),
    feature = str_replace(feature, "_(.*)\\*", "* \\1"),
    feature = fct_reorder(feature, median)
  ) %>%
  filter(median > 0.0025) %>%
  ggplot(aes(x = median, y = feature, xmin = l_quartile, xmax = u_quartile, 
             color = dataset, shape = dataset)) +
  geom_point(position = position_dodge(width = 0.3)) +
  geom_linerange(position = position_dodge(width = 0.3)) +
  labs(x = "Change in AUC when removed", y = NULL, color = "Dataset", shape = "Dataset") +
  theme_classic() +
  theme(axis.text.y = element_markdown()) +
  scale_color_manual(values = c("miseq" = "dodgerblue", "nanopore" = "darkgreen"))

print(p)
ggsave("figures/l2_feature_importance.tiff", width = 6, height = 5)
```

---

## Tips for Interactive Use

1. **Set Working Directory First**: Always start with `setwd()` to ensure relative paths work
2. **Check Data Exists**: Before running models, verify `composite_miseq` and `composite_nanopore` exist
3. **Start Small**: Test with `cv_times = 5` or `cv_times = 10` instead of 20 for faster iteration
4. **Inspect Intermediate Steps**: Check `captive_wild_data` and `captive_wild_preprocess` to understand data transformations
5. **Save Frequently**: Save models and intermediate results as you go
6. **Use RStudio's Environment Pane**: Keep track of objects in your workspace
7. **Debugging**: Use `browser()` or set breakpoints to step through code

---

## Quick Reference: Model Types

| Script | Model Type | Features | Approach |
|--------|-----------|----------|----------|
| `l2_genus.R` | L2 Regularized | genus only | glmnet |
| `l2_genus_fit.R` | L2 Regularized | genus + given_probiotic | glmnet |
| `rf_genus.R` | Random Forest | genus only | rf |
| `rf_genus_fit.R` | Random Forest | genus + given_probiotic | rf |

---

## Troubleshooting

- **"object 'composite_miseq' not found"**: Run `source("code/01_data_prep/genus_process.R")` first
- **"could not find function 'feature_select'"**: Source the appropriate model script (e.g., `l2_genus.R`)
- **Memory errors**: Reduce `cv_times` or use a smaller dataset subset
- **Package errors**: Install missing packages with `install.packages()`

