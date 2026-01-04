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
auc_comparison %>%
  ggplot(aes(x=AUC, fill=condition, linetype=dataset)) +
  geom_density(alpha=0.5) +
  stat_summary(aes(x=0.8, y=AUC, xintercept = stat(y)),
               fun=mean, geom="vline") +
  labs(y="Density", linetype="Dataset") +
  scale_fill_manual(values = c("genus" = "gray", "genus_fit" = "dodgerblue"))

ggsave("figures/genus_fit_auc_comparison.tiff", width=6, height=4)

# Summary statistics
auc_comparison %>%
  group_by(condition, dataset) %>%
  summarize(mean_auc = mean(AUC), .groups="drop") %>%
  pivot_wider(names_from = condition, values_from=mean_auc) %>%
  mutate(diff = genus_fit - genus)

# Permutation test for miseq
if(!is.null(auc_comparison_miseq)) {
  p.value.miseq <- perm_p_value_cond(auc_comparison_miseq, "genus", "genus_fit")
  print(paste("MiSeq p-value:", p.value.miseq))
}

# Permutation test for nanopore
if(!is.null(auc_comparison_nanopore)) {
  p.value.nanopore <- perm_p_value_cond(auc_comparison_nanopore, "genus", "genus_fit")
  print(paste("Nanopore p-value:", p.value.nanopore))
}
