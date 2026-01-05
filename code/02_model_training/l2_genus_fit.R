feature_select <- function(x){

  x %>%
    select(samples, taxonomy, rel_abund, given_probiotic, captive_wild)

}

approach <- "glmnet"

hyperparameter <- list(alpha = 0,
                       lambda = c(0.1, 1, 2, 3, 4, 5))
