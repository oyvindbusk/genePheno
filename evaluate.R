library(tidyverse)
library(fs)

# Hent ut antall prøver:
numsamples <- length(list.files(path="./bams", pattern="*.bam", full.names=TRUE, recursive=FALSE))

# Funksjon for ï¿½ ekstrahere panelnavn
g = function(g) {
  s <- tail(strsplit(g, "/")[[1]],n=1)
  s <- gsub(".regions.bed","", s)
  gsub(".thresholds.bed","", s)
}

# Iterer results-mappen og lag en liste med alle panel-bedene
panelfiles <- list.files(path="./results", pattern="*thresholds.bed", full.names=TRUE, recursive=FALSE)

# Mosdepth må være kjørt først - angi resultatmappen:
data_dir <- "/illumina/analysis/dev/2022/mfahls/panelevaluator/results"

# hent parameter til col_types og col_names
c_t <- "ciic"
c_n <- c("chrom", "start", "end", "region")
for(i in 1:numsamples) {
  c_n[length(c_n) + 1] <- as.character(i)
  c_t <- paste(c_t,"n", sep = "")
}

# Slår sammen alle prøvene til en tabell med en rad pr region hvor dekningen pr prøve står radvis - mean bakerst
regions <- fs::dir_ls(data_dir, regexp = "ns\\.bed$") %>% 
  map_dfr(read_delim, delim="\t",.id = "source", col_names = c_n, col_types=c_t) %>% 
  mutate(source = map_chr( source, g), mean = rowMeans(select(.,c("1":as.character(numsamples)))))
  
# Lager en ny tabell thresholds som har en kolonne size som beskriver hvor stort område som har mindre dekning enn mean
thresholds <- fs::dir_ls(data_dir, regexp = "ds\\.bed$") %>% 
  map_dfr(read_delim, delim="\t",.id = "source",skip=1, col_names = c_n, col_types = c_t) %>% 
  mutate(source = map_chr( source, g), mean = rowMeans(select(.,c("1":as.character(numsamples))))) %>% 
  mutate(size = abs(end-start)) %>% 
  mutate(diff = abs(size-mean))

# Itererer og printer for alle panelene.

file = "validate_out.txt"

# Tøm fil først:
write.table(file=file, "Dekning for paneler:", sep="\t", row.names=FALSE, col.names = FALSE, append = FALSE)

for(i in 1:length(panelfiles)) {
  
  # Regions below 20 print
  write.table(as.character(g(panelfiles[i])), file=file, sep="\t", row.names=FALSE, col.names = FALSE,append = TRUE) 
  write.table("Region med mindre enn 20 i gjennomsnittsdekning:", file=file,sep="\t", row.names=FALSE, col.names = FALSE,append = TRUE) 
  regions %>% 
    filter(source == g(panelfiles[i])) %>% 
    filter(mean < 20) %>% 
    select(-source, -("1":as.character(numsamples))) %>% 
    write.table(file=file , sep="\t", row.names=FALSE,col.names = FALSE, append = TRUE)  
  
  # Regions below 1X print
  write.table("Region som inneholder baser med 1X eller mindre:",file=file, sep="\t", row.names=FALSE, col.names = FALSE, append = TRUE)
  thresholds %>% 
    filter(diff != 0) %>% 
    select(-source, -("1":as.character(numsamples)),-mean) %>% 
    write.table(file=file , sep="\t", row.names=FALSE, col.names = FALSE, append = TRUE)
}


