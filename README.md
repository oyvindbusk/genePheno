# genePheno
## Scripts to make the biomartPheno-file used in annotation of our data

### Dependencies:
* docker
* bgzip
* tabix

### Build the docker image like this (when standing in the project directory)
```sh
docker build -t genopheno .
```

### How to run:
```sh
sh run_pheno.sh
```
This creates a file biomartPheno that contains phenotypes for most genes. Multiple phenotypes are separated by ||. This file is used in our pipeline to annotate phenotypes on genes.

### Example:
An example output file can be found in the example-folder