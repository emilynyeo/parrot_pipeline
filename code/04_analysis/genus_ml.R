source("code/01_data_prep/genus_process.R")
library(mikropml)
library(furrr)

#plan("sequential") # serial processing, not parallel!
#plan("multicore")  # doesnt work with windows or Rstudio
plan("multisession")

# Use miseq dataset (can change to composite_nanopore if needed)
captive_wild_genus_data <- composite_miseq %>%
  select(samples, taxonomy, rel_abund, captive_wild) %>%
  pivot_wider(names_from=taxonomy, values_from = rel_abund) %>%
  select(-samples) %>%
  select(captive_wild, everything())

captive_wild_genus_preprocess <- preprocess_data(captive_wild_genus_data,
                                        outcome_colname = "captive_wild")$dat_transformed

test_hp <- list(alpha = 0, 
                lambda = c(0.1, 1, 2, 3, 4, 5, 10))

get_captive_wild_genus_results <- function(seed){
  
  run_ml(captive_wild_genus_preprocess,
       method="glmnet",
       outcome_colname = "captive_wild",
       kfold = 5,
       cv_times = 100,
       training_frac = 0.8,
       hyperparameters = test_hp, 
       seed = seed,
       find_feature_importance = TRUE)

}

library(tictoc)
tic()
iterative_run_ml_results <- future_map(1:100, get_captive_wild_genus_results,
                                       .options = furrr_options(seed=TRUE))
toc()


performance <- iterative_run_ml_results %>%
  map(pluck, "trained_model") %>%
  combine_hp_performance()

plot_hp_performance(performance$dat, lambda, AUC)

performance$dat %>%
  group_by(alpha, lambda) %>%
  summarize(mean_AUC = mean(AUC), 
            lquartile = quantile(AUC, prob=0.25),
            uquartile = quantile(AUC, prob=0.75),
            .groups="drop") %>%
  top_n(n=3, mean_AUC)

feature_importance <- iterative_run_ml_results %>%
  map_dfr(pluck, "feature_importance")

feature_importance %>% 
  ggplot(aes(perf_metric_diff, names)) +
  geom_boxplot() +
  labs(x = 'Difference in AUROC', y = '') +
  theme_bw()
  

plan("sequential")
