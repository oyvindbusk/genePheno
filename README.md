# genePheno
## Scripts to make the biomartPheno-file used in annotation of our data

### How to run:
```sh




```
Rscript genPheno.r
dos2unix bioMartPheno.bed
bgzip bioMartPheno.bed
tabix -p bed bioMartPheno.bed.gz

And then I use the following settings in vcfanno to annotate:
[[annotation]]
file="bioMartPheno.bed.gz"
columns = [5]
ops=["self"]
names=["Pheno_GENE"]