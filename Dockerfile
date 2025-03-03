FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    zlib1g-dev \
    libbz2-dev \
    liblzma-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libdeflate-dev \
    libncurses5-dev \
    autoconf \
    automake \
    make \
    gcc \
    wget \
    curl \
	bzip2 \
    libtool \
    pkg-config \
    g++ \
    python3 \
    python3-pip \
	&& rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --upgrade pip

RUN pip install pysam

ENV SOFT=/soft
RUN mkdir -p $SOFT

# samtools 1.21 (12.09.2024)
ENV SAMTOOLS_INSTALL_DIR=$SOFT/samtools-1.21
ENV PATH=$SAMTOOLS_INSTALL_DIR/bin:$PATH

RUN mkdir -p $SAMTOOLS_INSTALL_DIR && cd $SOFT && \
	wget https://github.com/samtools/samtools/releases/download/1.21/samtools-1.21.tar.bz2 && \
	tar xvjf samtools-1.21.tar.bz2 && \
    rm samtools-1.21.tar.bz2 && \
	cd samtools-1.21 && \
	./configure --prefix=$SAMTOOLS_INSTALL_DIR && \
	make -j$(nproc) && \
	make install

# BCFtools 1.21 (12.09.2024)
ENV BCFTOOLS_INSTALL_DIR=$SOFT/bcftools-1.21
ENV PATH=$BCFTOOLS_INSTALL_DIR/bin:$PATH

RUN mkdir -p $BCFTOOLS_INSTALL_DIR && cd $SOFT && \
    wget https://github.com/samtools/bcftools/releases/download/1.21/bcftools-1.21.tar.bz2 && \
	tar xvjf bcftools-1.21.tar.bz2 && \
	rm bcftools-1.21.tar.bz2 && \
	cd bcftools-1.21 && \
	./configure --prefix=$BCFTOOLS_INSTALL_DIR && \
	make -j$(nproc) && \
	make install

# VCFtools 0.1.16 (02.08.2018)
ENV VCF_TOOLS_INSTALL_DIR=$SOFT/vcftools-0.1.16
ENV PATH=$VCF_TOOLS_INSTALL_DIR/bin:$PATH

RUN mkdir -p $VCF_TOOLS_INSTALL_DIR && cd $SOFT && \
    wget https://github.com/vcftools/vcftools/releases/download/v0.1.16/vcftools-0.1.16.tar.gz && \
	tar xzvf vcftools-0.1.16.tar.gz && \
	rm vcftools-0.1.16.tar.gz && \
	cd vcftools-0.1.16 && \
	./configure --prefix=$VCF_TOOLS_INSTALL_DIR && \
	make -j$(nproc) && \
	make install

ENV CODE=/code
RUN mkdir -p $CODE

ENV DATA=/data
RUN mkdir -p $DATA

ENV FASTA=/ref/GRCh38.d1.vd1_mainChr/sepChrs
RUN mkdir -p $FASTA

# Copy the script and data to the container
COPY conversion_script.py /code/script.py
COPY FP_SNPs_10k_GB38_twoAllelsFormat.tsv /data
COPY sepChrs/ /ref/GRCh38.d1.vd1_mainChr/sepChrs

RUN chmod +x /code/script.py

RUN python3 /code/script.py -i /data/FP_SNPs_10k_GB38_twoAllelsFormat.tsv -o /data/FP_SNPs_10k_GB38_definiteAlleles.tsv -p ref/GRCh38.d1.vd1_mainChr/sepChrs/ -l /data/FP_SNPs_10k_GB38.log
