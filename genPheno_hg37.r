if (!requireNamespace("BiocManager", quietly = TRUE)) {
    install.packages("BiocManager", repos="https://cran.uib.no/")
}

if(!require(biomaRt)){
  BiocManager::install("biomaRt")
}

if(!require(tidyverse)){
    install.packages("tidyverse", repos="https://cran.uib.no/")  
}

library(tidyverse)
library(biomaRt)

# Set ensembl - Note that grch37 is used:
ensembl = useMart(biomart="ENSEMBL_MART_ENSEMBL", path="/biomart/martservice", dataset="hsapiens_gene_ensembl")
# Get genes with phenotype_description
results <- getBM(attributes= c("chromosome_name","start_position","end_position", "hgnc_symbol", "phenotype_description"), mart=ensembl)
# Convert to tibble
t_results <- as_tibble(results) %>% na_if("")
# Group and combine the phenotypes into one column
grouped_t_results <- t_results %>%
  drop_na(phenotype_description) %>%
  mutate(phenotype_description = str_replace_all(phenotype_description, " ", "_")) %>%
  group_by(chromosome_name, start_position, end_position, hgnc_symbol) %>%
  mutate(phenotype = paste0(phenotype_description, collapse = "||")) %>%
  summarise(phenotype = first(phenotype)) %>% 
  ungroup()
  

# Change col order
# Filter away funny chromosomes
# Sort
grouped_t_results_reorderd <- grouped_t_results %>%
  dplyr::select(chromosome_name, start_position, end_position, hgnc_symbol, phenotype) %>%
  filter(!str_detect(chromosome_name, "PATCH"), !str_detect(chromosome_name, "HSCHR"), !str_detect(chromosome_name, "GL000"))  %>%
  arrange(chromosome_name, start_position)

# Write to file
dir <- "/outdir"
write.table(grouped_t_results_reorderd,
    file.path(dir, "bioMartPheno.bed"),
    sep="\t",
    quote=FALSE,
    col.names=FALSE,
    row.names=FALSE)
