library(tidyverse)
library(broom)
library(ggtext)

set.seed(19760620)

cat("[genus_process.R] Starting data preparation...\n")

data_dir <- "/Users/emily/projects/research/parrot_project/MelissaAnalysis"
output_dir <- "/Users/emily/projects/research/parrot/mikropml_demo/processed_data/"

# taxonomy table 
cat("[genus_process.R] Step 1/6: Loading and processing taxonomy data...\n")
taxonomy <- read.csv(file.path(data_dir, "00_sequence_data/JVB3218_16S/JVB3218-16S-esv-data.csv")) %>% 
  rename_all(tolower) %>% 
  # remove chloroplasts & mitochondria
  filter(!(family == "Mitochondria" | order == "chloroplast")) %>% 
  mutate(across(kingdom:species, ~ na_if(., ""))) %>%   # treat "" as NA
  mutate(across(kingdom:species, ~ replace_na(., "unclassified"))) %>%
  unite(taxonomy, kingdom:species, sep = ";", remove = FALSE) %>% 
  mutate(taxonomy = str_replace_all(taxonomy, " ", "_"),
         taxonomy = str_replace_all(taxonomy, "\\[|\\]", ""), 
         taxonomy = str_replace(taxonomy, ";unclassified", "_unclassified"),
         taxonomy = str_replace_all(taxonomy, ";unclassified", ""),
         taxonomy = str_replace_all(taxonomy, ";$", ""),
         taxonomy = str_replace_all(taxonomy, ".*;", "")) %>% 
  select(esvid, taxonomy)
cat("  ✓ Taxonomy processed:", nrow(taxonomy), "ESVs\n")

# NANOPORE AND MISEQ from original runs 
cat("[genus_process.R] Step 2/6: Loading and processing read data (this may take a moment)...\n")
shared <- read.csv(file.path(data_dir, "00_sequence_data/JVB3218_16S/JVB3218-16S-read-data.csv")) %>% 
  rename_with(~ gsub("^s0", "S0", .)) %>% 
  select(-starts_with(c("S082895", "S082806","TestId","sequence",
                        "Kingdom","Phylum","Class","Order","Family",
                        "Genus","Species","X..species"))) %>% 
  filter(rowSums(across(where(is.numeric))) > 0) %>%
  rename(percent_match = `X..match`) %>%
  pivot_longer(-ESVId, names_to = "samples", values_to = "count") %>% 
  rename_all(tolower)
cat("  ✓ Read data processed:", nrow(shared), "rows\n")

# meta
cat("[genus_process.R] Step 3/6: Loading metadata files...\n")
samples_16 <- read.csv(file.path(data_dir, "00_sequence_data/JVB3218_16S/JVB3218-samples.csv")) 
meta1 <- read.csv(file.path(data_dir, "00_metadata/ParrotFecalSampleMetadata_SerialIDs_McKenzie.csv"))
addmeta <- read.csv(file.path(data_dir, "00_metadata/additional_info_seizures.csv"))
allBirdESVs <- read_csv(file.path(data_dir, "00_metadata/allBirdESVs.csv")) # remove birds
cat("  ✓ Metadata files loaded\n") 

cat("[genus_process.R] Step 4/6: Processing and joining metadata...\n")
meta_file  <- left_join(meta1, addmeta) %>%
  unite(serial.prefix, serial.number, sep="", col="SampleId", remove=FALSE) %>%
  select(SampleId, everything()) %>% 
  rename_all(tolower) %>%
  rename(samples = sampleid) %>%
  rename_with(~ str_replace_all(.x, "\\.", "_")) %>% 
  mutate(across(where(is.character), ~ str_replace_all(.x, " ", "_"))) %>% 
  filter(samples != "S082895") %>% 
  filter(samples != "S082806") %>% 
  # std date collected
  mutate(date_collected_std = parse_date_time(
      date_collected, orders = c("dmy", "dmY", "mdy", "d-b-Y", "d-B-Y"),
      quiet = TRUE) %>% as.Date(),
    collected_day   = day(date_collected_std),
    collected_month = month(date_collected_std),
    collected_year  = year(date_collected_std)) %>%
  # std seized date 
  mutate(seized_date_std = dmy(seized_date, quiet = TRUE),
         time_since_seizure = date_collected_std - seized_date_std) %>% 
  mutate(captive_wild = factor(captive_wild),
         captive_wild = fct_recode(captive_wild,
      Captive = "Captive",
      Wild_free = "Wild,_free_ranging",
      Wild_seized = "Wild,_seized_from_traffickers"))
cat("  ✓ Metadata processed:", nrow(meta_file), "samples\n")

# Combined miseq
cat("[genus_process.R] Step 5/6: Creating composite_miseq dataset (joining and aggregating)...\n")
composite_miseq <- inner_join(shared, taxonomy, by = "esvid") %>% 
  filter(str_detect(samples, "^S0") & str_detect(samples, "\\.1$")) %>% 
  mutate(samples = gsub("\\.[1]$", "", samples)) %>% 
  filter(!esvid %in% allBirdESVs$ESVId) %>% # remove bird esvs
  group_by(samples, taxonomy) %>% 
  summarise(count = sum(count), .groups = "drop") %>% 
  group_by(samples) %>% 
  mutate(rel_abund = count/sum(count)) %>% 
  ungroup() %>%
  group_by(taxonomy) %>%
  mutate(two_count_perc = 100 * sum(
         count > 2, na.rm = TRUE) / n_distinct(samples),
         ten_count_perc = 100 * sum(
         count > 10, na.rm = TRUE) / n_distinct(samples)) %>%
  ungroup() %>% 
  select(-count) %>%
  inner_join(., meta_file, by="samples")
cat("  ✓ composite_miseq created:", nrow(composite_miseq), "rows\n")

  # Combined nano 
cat("[genus_process.R] Step 6/6: Creating composite_nanopore dataset (joining and aggregating)...\n")
composite_nanopore <- inner_join(shared, taxonomy, by = "esvid") %>% 
  filter(str_detect(samples, "^S0") & str_detect(samples, "\\.2$")) %>% 
  mutate(samples = gsub("\\.[2]$", "", samples)) %>% 
  filter(!esvid %in% allBirdESVs$ESVId) %>% # remove bird esvs
  group_by(samples, taxonomy) %>% 
  summarise(count = sum(count), .groups = "drop") %>% 
  group_by(samples) %>% 
  mutate(rel_abund = count/sum(count)) %>% 
  ungroup() %>%
  group_by(taxonomy) %>%
  mutate(two_count_perc = 100 * sum(
    count > 2, na.rm = TRUE) / n_distinct(samples),
    ten_count_perc = 100 * sum(
    count > 10, na.rm = TRUE) / n_distinct(samples)) %>%
  ungroup() %>% 
  select(-count) %>%
  inner_join(., meta_file, by="samples")
cat("  ✓ composite_nanopore created:", nrow(composite_nanopore), "rows\n")

cat("[genus_process.R] Saving datasets to RDS files...\n")
saveRDS(composite_miseq, file = file.path(output_dir, "composite_miseq.rds"))
saveRDS(composite_nanopore, file = file.path(output_dir, "composite_nanopore.rds"))
cat("[genus_process.R] ✓ Data preparation complete!\n\n")