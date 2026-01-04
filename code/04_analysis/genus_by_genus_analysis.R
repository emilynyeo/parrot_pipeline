source("code/01_data_prep/genus_process.R")
library(purrr)
library(broom)
library(ggtext)

# Analyze miseq dataset (can change to composite_nanopore if needed)
sig_genera <- composite_miseq %>%
  nest(data = -taxonomy) %>%
  mutate(test = map(.x=data, ~wilcox.test(rel_abund~captive_wild, data=.x) %>% tidy)) %>%
  unnest(test) %>% 
  mutate(p.adjust = p.adjust(p.value, method="BH")) %>%
  filter(p.adjust < 0.05) %>%
  select(taxonomy, p.adjust)


composite_miseq %>%
  inner_join(sig_genera, by="taxonomy") %>%
  mutate(rel_abund = 100 * (rel_abund + 1/20000),
         taxonomy = str_replace(taxonomy, "(.*)", "*\\1*"),
         taxonomy = str_replace(taxonomy, "\\*(.*)_unclassified\\*",
                                "Unclassified<br>*\\1*"),
         captive_wild = factor(captive_wild)) %>%
  ggplot(aes(x=rel_abund, y=taxonomy, color=captive_wild, fill=captive_wild)) +
  geom_vline(xintercept = 100/10530, size=0.5, color="gray") +
  geom_jitter(position = position_jitterdodge(dodge.width = 0.8,
                                              jitter.width = 0.5),
              shape=21) +
  stat_summary(fun.data = median_hilow, fun.args = list(conf.int=0.5),
               geom="pointrange",
               position = position_dodge(width=0.8),
               color="black", show.legend = FALSE) +
  scale_x_log10() +
  scale_color_manual(NULL, 
                     values = c("gray", "dodgerblue", "darkgreen"),
                     labels = levels(composite_miseq$captive_wild)) +
  scale_fill_manual(NULL, 
                     values = c("gray", "dodgerblue", "darkgreen"),
                     labels = levels(composite_miseq$captive_wild)) +
  labs(x= "Relative abundance (%)", y=NULL) +
  theme_classic() +
  theme(
    axis.text.y = element_markdown()
  )

ggsave("figures/significant_genera.tiff", width=6, height=4)

get_sens_spec <- function(threshold, score, actual, direction, positive_class = NULL){
  
  # threshold <- 100
  # score <- test$score
  # actual <- test$captive_wild (factor with 3 levels)
  # direction <- "greaterthan"
  # positive_class <- "Captive" (optional, defaults to first level)
  
  # Convert multi-class to binary if needed
  if(is.factor(actual) && length(levels(actual)) > 2) {
    if(is.null(positive_class)) {
      positive_class <- levels(actual)[1]  # Default to first level
    }
    actual_binary <- (actual == positive_class)
  } else if(is.factor(actual)) {
    # Already binary factor
    if(is.null(positive_class)) {
      positive_class <- levels(actual)[1]
    }
    actual_binary <- (actual == positive_class)
  } else {
    # Already logical/binary
    actual_binary <- actual
  }
  
  predicted <- if(direction == "greaterthan") {
    score > threshold 
    } else {
      score < threshold
    }
  
  tp <- sum(predicted & actual_binary)
  tn <- sum(!predicted & !actual_binary)
  fp <- sum(predicted & !actual_binary)
  fn <- sum(!predicted & actual_binary)  
  
  specificity <- tn / (tn + fp)
  sensitivity <- tp / (tp + fn)
  
  # Handle division by zero
  if(is.nan(specificity)) specificity <- 0
  if(is.nan(sensitivity)) sensitivity <- 0
  
  tibble("specificity" = specificity, "sensitivity" = sensitivity)
}

get_roc_data <- function(x, direction, outcome_var, positive_class = NULL){
  
  # x <- test
  # direction <- "greaterthan"
  # outcome_var <- "captive_wild"
  # positive_class <- "Captive" (optional)
  
  thresholds <- unique(x$score) %>% sort()
  
  map_dfr(.x=thresholds, ~get_sens_spec(.x, x$score, x[[outcome_var]], direction, positive_class)) %>%
    rbind(c(specificity = 0, sensitivity = 1))
  
}

# get_sens_spec(100, test$score, test$captive_wild, "greaterthan")
# get_roc_data(test, "greaterthan", "captive_wild")

roc_data <- composite_miseq %>%
  inner_join(sig_genera, by="taxonomy") %>%
  select(samples, taxonomy, rel_abund, fit_result, captive_wild) %>%
  pivot_wider(names_from=taxonomy, values_from=rel_abund) %>%
  pivot_longer(cols=-c(samples, captive_wild), names_to="metric", values_to="score") %>%
  # filter(metric == "fit_result") %>%
  nest(data = -metric) %>%
  mutate(direction = if_else(metric == "Lachnospiraceae_unclassified",
                             "lessthan","greaterthan")) %>%
  # Use "Captive" as positive class for ROC (can change to other levels if needed)
  mutate(roc_data = map2(.x = data, .y=direction, ~get_roc_data(.x, .y, "captive_wild", positive_class = "Captive"))) %>%
  unnest(roc_data) %>%
  select(metric, specificity, sensitivity)

roc_data %>%
  ggplot(aes(x=1-specificity, y=sensitivity, color=metric)) +
  geom_line() +
  geom_abline(slope = 1, intercept = 0, color="gray") +
  theme_classic()

ggsave("figures/roc_figure.tiff", width=6, height=4)
