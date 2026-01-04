.SECONDARY:

SEEDS = $(shell seq 1 1 100)

# L2 Genus - Miseq
L2_GENUS_MISEQ_RDS = $(patsubst %,processed_data/l2_genus_miseq_%.Rds,$(SEEDS))

$(L2_GENUS_MISEQ_RDS) : code/02_model_training/run_split.R code/01_data_prep/genus_process.R\
																code/02_model_training/l2_genus.R
	./code/02_model_training/run_split.R $@ code/02_model_training/l2_genus.R miseq

processed_data/l2_genus_miseq_performance.tsv : code/03_model_combination/combine_models.R $(L2_GENUS_MISEQ_RDS)
	$^

# L2 Genus - Nanopore
L2_GENUS_NANOPORE_RDS = $(patsubst %,processed_data/l2_genus_nanopore_%.Rds,$(SEEDS))

$(L2_GENUS_NANOPORE_RDS) : code/02_model_training/run_split.R code/01_data_prep/genus_process.R\
																code/02_model_training/l2_genus.R
	./code/02_model_training/run_split.R $@ code/02_model_training/l2_genus.R nanopore

processed_data/l2_genus_nanopore_performance.tsv : code/03_model_combination/combine_models.R $(L2_GENUS_NANOPORE_RDS)
	$^

# L2 Genus Fit - Miseq
L2_GENUS_FIT_MISEQ_RDS = $(patsubst %,processed_data/l2_genus_fit_miseq_%.Rds,$(SEEDS))

$(L2_GENUS_FIT_MISEQ_RDS) : code/02_model_training/run_split.R code/01_data_prep/genus_process.R\
											code/02_model_training/l2_genus_fit.R
	./code/02_model_training/run_split.R $@ code/02_model_training/l2_genus_fit.R miseq

processed_data/l2_genus_fit_miseq_performance.tsv : code/03_model_combination/combine_models.R\
											$(L2_GENUS_FIT_MISEQ_RDS)
	$^

# L2 Genus Fit - Nanopore
L2_GENUS_FIT_NANOPORE_RDS = $(patsubst %,processed_data/l2_genus_fit_nanopore_%.Rds,$(SEEDS))

$(L2_GENUS_FIT_NANOPORE_RDS) : code/02_model_training/run_split.R code/01_data_prep/genus_process.R\
											code/02_model_training/l2_genus_fit.R
	./code/02_model_training/run_split.R $@ code/02_model_training/l2_genus_fit.R nanopore

processed_data/l2_genus_fit_nanopore_performance.tsv : code/03_model_combination/combine_models.R\
											$(L2_GENUS_FIT_NANOPORE_RDS)
	$^

# RF Genus - Miseq
RF_GENUS_MISEQ_RDS = $(patsubst %,processed_data/rf_genus_miseq_%.Rds,$(SEEDS))

$(RF_GENUS_MISEQ_RDS) : code/02_model_training/run_split.R code/01_data_prep/genus_process.R\
																code/02_model_training/rf_genus.R
	./code/02_model_training/run_split.R $@ code/02_model_training/rf_genus.R miseq

processed_data/rf_genus_miseq_performance.tsv : code/03_model_combination/combine_models.R $(RF_GENUS_MISEQ_RDS)
	$^

# RF Genus - Nanopore
RF_GENUS_NANOPORE_RDS = $(patsubst %,processed_data/rf_genus_nanopore_%.Rds,$(SEEDS))

$(RF_GENUS_NANOPORE_RDS) : code/02_model_training/run_split.R code/01_data_prep/genus_process.R\
																code/02_model_training/rf_genus.R
	./code/02_model_training/run_split.R $@ code/02_model_training/rf_genus.R nanopore

processed_data/rf_genus_nanopore_performance.tsv : code/03_model_combination/combine_models.R $(RF_GENUS_NANOPORE_RDS)
	$^

# RF Genus Fit - Miseq
RF_GENUS_FIT_MISEQ_RDS = $(patsubst %,processed_data/rf_genus_fit_miseq_%.Rds,$(SEEDS))

$(RF_GENUS_FIT_MISEQ_RDS) : code/02_model_training/run_split.R code/01_data_prep/genus_process.R\
																code/02_model_training/rf_genus_fit.R
	./code/02_model_training/run_split.R $@ code/02_model_training/rf_genus_fit.R miseq

processed_data/rf_genus_fit_miseq_performance.tsv : code/03_model_combination/combine_models.R\
										$(RF_GENUS_FIT_MISEQ_RDS)
	$^

# RF Genus Fit - Nanopore
RF_GENUS_FIT_NANOPORE_RDS = $(patsubst %,processed_data/rf_genus_fit_nanopore_%.Rds,$(SEEDS))

$(RF_GENUS_FIT_NANOPORE_RDS) : code/02_model_training/run_split.R code/01_data_prep/genus_process.R\
																code/02_model_training/rf_genus_fit.R
	./code/02_model_training/run_split.R $@ code/02_model_training/rf_genus_fit.R nanopore

processed_data/rf_genus_fit_nanopore_performance.tsv : code/03_model_combination/combine_models.R\
										$(RF_GENUS_FIT_NANOPORE_RDS)
	$^
