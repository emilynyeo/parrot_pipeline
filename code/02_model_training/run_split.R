#!/usr/bin/env Rscript

source("code/01_data_prep/genus_process.R")
library(mikropml)
library(tidyverse)

args <- commandArgs(trailingOnly = TRUE)
output_file <- args[1]
seed <- as.numeric(str_replace(output_file, ".*_(\\d*)\\.Rds", "\\1"))
feature_script <- args[2]
dataset_name <- args[3]  # "miseq" or "nanopore"

source(feature_script)

# Select the appropriate dataset
composite_data <- if(dataset_name == "miseq") {
  composite_miseq
} else if(dataset_name == "nanopore") {
  composite_nanopore
} else {
  stop("dataset_name must be 'miseq' or 'nanopore'")
}

captive_wild_data <- composite_data %>%
  select(samples, taxonomy, rel_abund, captive_wild) %>%
  feature_select() %>%
  pivot_wider(names_from=taxonomy, values_from = rel_abund) %>%
  select(-samples) %>%
  select(captive_wild, everything())

# remove correlated and low variance vars 
captive_wild_preprocess <- preprocess_data(captive_wild_data,
                                        outcome_colname = "captive_wild")$dat_transformed

model <- run_ml(captive_wild_preprocess,
       method=approach,
       outcome_colname = "captive_wild",
       kfold = 5,
       cv_times = 100,
       training_frac = 0.8,
			 find_feature_importance = TRUE,
       hyperparameters = hyperparameter,
       seed = seed)

saveRDS(model, file=output_file)
