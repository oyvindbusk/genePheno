# Check if file is present - and give warning
{
if [ -f bioMartPheno.bed.gz ]; then
    clear
    echo "bioMartPheno.bed is already present!!  REMOVE BEFORE RUNNING ME AGAIN!"
    exit 0
fi
}

docker run -it --rm -v $PWD:/outdir genopheno /bin/bash -c "Rscript scriptdir/genPheno_hg37.r"
#dos2unix bioMartPheno.bed
bgzip bioMartPheno.bed
tabix -p bed bioMartPheno.bed.gz
