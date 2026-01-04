library(tidyverse)
library(mikropml)

# Function to process pooled data for a specific dataset
process_dataset <- function(dataset_name, model_type = "l2_genus") {
  
  hp_file <- paste0("processed_data/", model_type, "_", dataset_name, "_hp.tsv")
  perf_file <- paste0("processed_data/", model_type, "_", dataset_name, "_performance.tsv")
  
  if(!file.exists(hp_file) || !file.exists(perf_file)) {
    warning(paste("Files not found for", model_type, dataset_name))
    return(NULL)
  }
  
  hp_data <- read_tsv(hp_file) %>%
    mutate(dataset = dataset_name, model = model_type)
  
  perf_data <- read_tsv(perf_file) %>%
    mutate(dataset = dataset_name, model = model_type)
  
  list(hp = hp_data, perf = perf_data)
}

# Process both datasets
miseq_data <- process_dataset("miseq")
nanopore_data <- process_dataset("nanopore")

# Plot hyperparameter performance (combining both datasets)
if(!is.null(miseq_data) && !is.null(nanopore_data)) {
  bind_rows(miseq_data$hp, nanopore_data$hp) %>%
    plot_hp_performance(lambda, AUC) +
    facet_wrap(~dataset)
}

# Top hyperparameters
if(!is.null(miseq_data)) {
  miseq_data$hp %>%
    group_by(alpha, lambda) %>%
    summarize(mean_AUC = mean(AUC), 
              lquartile = quantile(AUC, prob=0.25),
              uquartile = quantile(AUC, prob=0.75),
              .groups="drop") %>%
    top_n(n=3, mean_AUC) %>%
    print()
}

if(!is.null(nanopore_data)) {
  nanopore_data$hp %>%
    group_by(alpha, lambda) %>%
    summarize(mean_AUC = mean(AUC), 
              lquartile = quantile(AUC, prob=0.25),
              uquartile = quantile(AUC, prob=0.75),
              .groups="drop") %>%
    top_n(n=3, mean_AUC) %>%
    print()
}

# Performance comparison
if(!is.null(miseq_data) && !is.null(nanopore_data)) {
  bind_rows(miseq_data$perf, nanopore_data$perf) %>%
    select(seed, dataset, cv_metric_AUC, AUC) %>%
    pivot_longer(cols=-c(seed, dataset), names_to="metric", values_to="AUC") %>%
    ggplot(aes(x=metric, y=AUC, fill=dataset)) +
    geom_boxplot(position = position_dodge(width=0.8)) +
    labs(fill="Dataset")
}
