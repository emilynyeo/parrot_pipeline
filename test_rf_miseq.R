#!/usr/bin/env Rscript
# Quick test script for RF on miseq only
# This is a wrapper that sets the test parameters and runs test_mock_run.R

# Override test parameters
TEST_MODELS <- c("rf_genus")
TEST_DATASETS <- c("miseq")
SEED <- 1

# Source the main test script logic
source("test_mock_run.R")

