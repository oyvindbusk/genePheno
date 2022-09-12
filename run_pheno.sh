# Check if file is present - and give warning
{
if [ -f bioMartPheno.bed ]; then
    clear
    echo "bioMartPheno.bed is already present!!  REMOVE BEFORE RUNNING ME AGAIN!"
    exit 0
fi
}

Rscript genPheno_hg37.r
dos2unix bioMartPheno.bed
bgzip bioMartPheno.bed
tabix -p bed bioMartPheno.bed.gz