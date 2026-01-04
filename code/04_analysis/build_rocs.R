library(tidyverse)
library(rlang)

get_sens_spec_lookup <- function(data, outcome_levels){
  
  total <- data %>%
    count(observed) %>%
    pivot_wider(names_from=observed, values_from=n)
  
  # Get the positive class (first level) and negative class
  # For multi-class, we'll use one-vs-rest approach with first class as positive
  positive_class <- outcome_levels[1]
  negative_classes <- outcome_levels[-1]
  
  # Get the probability column for the positive class
  prob_col <- sym(positive_class)
  
  data %>%
    arrange(desc(!!prob_col)) %>%
    mutate(is_positive = (observed == positive_class),
           tp = cumsum(is_positive),
           fp = cumsum(!is_positive),
           total_positive = sum(observed == positive_class),
           total_negative = sum(observed %in% negative_classes),
           sensitivity = tp / total_positive,
           fpr = fp / total_negative,
           specificity = 1-fpr) %>%
    select(sensitivity, specificity, fpr)

}

get_sensitivity <- function(x, data){
  
  data %>%
    filter(specificity - x >= 0) %>%
    top_n(sensitivity, n=1) %>%
    mutate(specificity = x, fpr = 1-x) %>%
    distinct()
  
}

get_pooled_sens_spec <- function(file_name, specificity){

  model <- readRDS(file_name)
  
  prob <- predict(model$trained_model, model$test_data, type="prob")
  observed <- model$test_data$captive_wild
  
  # Get outcome levels from the model
  outcome_levels <- levels(observed)
  if(is.null(outcome_levels)) {
    outcome_levels <- unique(observed) %>% sort()
  }
  
  # Create a data frame with probabilities and observed
  prob_obs <- bind_cols(prob, observed = observed) %>%
    select(all_of(outcome_levels), observed)
  
  sens_spec_lookup <- get_sens_spec_lookup(prob_obs, outcome_levels)

  map_dfr(specificity, get_sensitivity, sens_spec_lookup) %>%
    mutate(model = str_replace(file_name,
                               "processed_data/(.*)_\\d*.Rds",
                               "\\1"))

}


specificity <- seq(0, 1, 0.01)

# Update pattern to match new file naming (e.g., l2_genus_miseq_1.Rds or l2_genus_nanopore_1.Rds)
# get_pooled_sens_spec("processed_data/l2_genus_miseq_1.Rds", specificity)

pooled_sens_spec <- list.files(path="processed_data",
           pattern=".*_(miseq|nanopore)_\\d*\\.Rds",
           full.names=TRUE) %>%
  map_dfr(get_pooled_sens_spec, specificity)

pooled_sens_spec %>%
  group_by(model, specificity) %>%
  summarize(lquartile = quantile(sensitivity, prob=0.25),
            uquartile = quantile(sensitivity, prob=0.75),
            sensitivity = median(sensitivity),
            .groups="drop") %>%
  ggplot(aes(x=1-specificity, y=sensitivity,
             ymin=lquartile, ymax=uquartile))+
  geom_ribbon(alpha=0.25, aes(fill=model)) +
  geom_step(aes(color=model)) +
  theme_classic() +
  theme(legend.position = c(0.8, 0.2))

ggsave("figures/roc_curve.tiff", width=5, height=5)
