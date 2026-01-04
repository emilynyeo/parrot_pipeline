library(tidyverse)
library(ggtext)

# Function to process weights for a specific dataset
get_weights_dataset <- function(dataset_name){
  
  l2_files <- list.files(path="processed_data",
                         pattern=paste0("l2_genus_", dataset_name, "_\\d*\\.Rds"),
                         full.names=TRUE)
  
  if(length(l2_files) == 0) {
    warning(paste("No files found for dataset:", dataset_name))
    return(NULL)
  }
  
  get_weights <- function(file_name){
    
    model <- readRDS(file_name) %>%
      pluck("trained_model")
    
    coef(model$finalModel, model$bestTune$lambda) %>%
      as.matrix %>%
      as_tibble(rownames="feature") %>%
      rename(weight = `1`) %>%
      mutate(seed = str_replace(file_name,
                                paste0("processed_data/l2_genus_", dataset_name, "_(\\d*)\\.Rds"),
                                "\\1"),
             dataset = dataset_name)
    
  }
  
  map_dfr(l2_files, get_weights)
}

# Get weights for both datasets
l2_weights_miseq <- get_weights_dataset("miseq")
l2_weights_nanopore <- get_weights_dataset("nanopore")

l2_weights <- bind_rows(l2_weights_miseq, l2_weights_nanopore)

l2_weights %>%
  filter(feature != "(Intercept)") %>%
  group_by(feature, dataset) %>%
  summarize(median = median(weight),
            l_quartile = quantile(weight, prob=0.25),
            u_quartile = quantile(weight, prob=0.75),
            .groups="drop") %>%
  mutate(feature = str_replace(feature, "(.*)", "*\\1*"),
         feature = str_replace(feature, "(.*)_unclassified\\*", "Unclassified \\1*"),
         feature = str_replace(feature, "_(.*)\\*", "* \\1"),
         feature = fct_reorder(feature, median)) %>%
  filter(abs(median) > 0.01) %>%
  ggplot(aes(x=median, y=feature, xmin=l_quartile, xmax=u_quartile, color=dataset, shape=dataset)) +
  geom_vline(xintercept=0, color="gray") +
  geom_point(position = position_dodge(width=0.3)) +
  geom_linerange(position = position_dodge(width=0.3)) +
  labs(x="Weights", y=NULL, color="Dataset", shape="Dataset") +
  theme_classic() +
  theme(axis.text.y = element_markdown()) +
  scale_color_manual(values = c("miseq" = "dodgerblue", "nanopore" = "darkgreen"))
  
ggsave("figures/l2_weights.tiff", width=6, height=5)



# Function to process feature importance for a specific dataset
get_feature_importance_dataset <- function(dataset_name){
  
  l2_files <- list.files(path="processed_data",
                         pattern=paste0("l2_genus_", dataset_name, "_\\d*\\.Rds"),
                         full.names=TRUE)
  
  if(length(l2_files) == 0) {
    warning(paste("No files found for dataset:", dataset_name))
    return(NULL)
  }
  
  get_feature_importance <- function(file_name){
    
    feature_importance <- readRDS(file_name) %>%
      pluck("feature_importance") %>%
      as_tibble() %>%
      select(names, perf_metric, perf_metric_diff) %>%
      mutate(dataset = dataset_name)
    
  }
  
  map_dfr(l2_files, get_feature_importance)
}

# Get feature importance for both datasets
l2_feature_importance_miseq <- get_feature_importance_dataset("miseq")
l2_feature_importance_nanopore <- get_feature_importance_dataset("nanopore")

l2_feature_importance <- bind_rows(l2_feature_importance_miseq, l2_feature_importance_nanopore)


l2_feature_importance %>%
  rename(feature = names) %>%
  group_by(feature, dataset) %>%
  summarize(median = median(perf_metric_diff),
            l_quartile = quantile(perf_metric_diff, prob=0.25),
            u_quartile = quantile(perf_metric_diff, prob=0.75),
            .groups="drop") %>%
  mutate(feature = str_replace(feature, "(.*)", "*\\1*"),
         feature = str_replace(feature, "(.*)_unclassified\\*", "Unclassified \\1*"),
         feature = str_replace(feature, "_(.*)\\*", "* \\1"),
         feature = fct_reorder(feature, median)) %>%
  filter(median > 0.0025) %>%
  ggplot(aes(x=median, y=feature, xmin=l_quartile, xmax=u_quartile, color=dataset, shape=dataset)) +
  geom_point(position = position_dodge(width=0.3)) +
  geom_linerange(position = position_dodge(width=0.3)) +
  labs(x="Change in AUC when removed", y=NULL, color="Dataset", shape="Dataset") +
  theme_classic() +
  theme(axis.text.y = element_markdown()) +
  scale_color_manual(values = c("miseq" = "dodgerblue", "nanopore" = "darkgreen"))

ggsave("figures/l2_feature_importance.tiff", width=6, height=5)
