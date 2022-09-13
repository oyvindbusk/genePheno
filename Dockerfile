FROM r-base
LABEL maintainer="oyvindbusk@gmail.com"
LABEL version="0.1"
LABEL description="Docker Image for biomart getting phenotype"

# Disable Prompt During Packages Installation
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && apt-get install -y \
  curl \
  tabix \
  libcurl4-openssl-dev \
  g++ \
  libbz2-dev \
  liblzma-dev \
  make \
  tar \
  tcl \
  tcllib \
  unzip \
  wget \
  zlib1g-dev \
  libssl-dev \
  libxml2-dev

RUN Rscript -e 'install.packages("BiocManager", repos="https://cloud.r-project.org", dep=T)'
RUN Rscript -e 'BiocManager::install(c("biomaRt"))'
RUN Rscript -e 'install.packages("tidyverse", repos="https://cloud.r-project.org", dep=T)'

RUN mkdir -p /scriptdir/
COPY genPheno_hg37.r /scriptdir/genPheno_hg37.r