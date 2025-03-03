# SNP-file-conversion

## Description

This repository contains a script to converting a SNP file with undefined alleles to a file with REF and ALT alleles using a reference genome.

## Repository structure

1. `data/FP_SNPs.txt` was obtained from the [GAP website](http://www.ncbi.nlm.nih.gov/projects/gap/cgi-bin/GetZip.cgi?zip_name=GRAF_files.zip).
This file contains 10000 + 1000 SNPs for sex checking. This file was processed:

   - GRCh37 coordinates were removed;
   - colnames were replaced and renamed as «#CHROM<TAB>POS<TAB>ID<TAB>allele1<TAB>allele2»;
   - chr and rs prefixes were added;
   - chrX variants were removed.


2. `FP_SNPs_10k_GB38_twoAllelsFormat_definiteAlleles.tsv` was obtained using the following command:

        cut -f1,2,4- -d$'\t' FP_SNPs.txt | awk -F'\t' 'BEGIN {OFS=FS} {print $2, $3, $1, $4, $5}' | sed '1s/.*/#CHROM\tPOS\tID\tallele1\tallele2/' | awk 'NR==1 {print; next} {$1 = "chr" $1 } 1' OFS='\t' | awk 'NR==1 {print; next} {$3 = "rs" $3 } 1' OFS='\t' | awk 'NR==1 || $1 != "chr23"' > FP_SNPs_10k_GB38_twoAllelsFormat.tsv


3. The reference genome for the conversion was downloaded from [gdc.cancer.gov](https://api.gdc.cancer.gov/data/254f697d-310d-4d7d-a27b-27fbf767a834).
The genome was split into chromosomes and saved in the `sepChrs` folder using command:

         awk '
         /^>/ {
             if ($1 ~ /^>chr([1-9]|1[0-9]|2[0-2])$/) {
                 OUT="sepChrs/" substr($0, 2, match($0, " ") - 2) ".fa"
                 print ">" substr($1, 2) > OUT
             }
             else {
                 next
             }
         }
         !/^>/ {
             print > OUT
         }
         ' /Users/moonbee/Downloads/GRCh38.d1.vd1.fa

For .fai files creation, the container [Bio-container](https://github.com/EugeneShchoka/Bio-container) and `samtools v1.21` were used.
.fa files were loaded to the container and then processed using commands:

        docker build -t my-bio-container .
        docker run -v sepChrs/:/ref/GRCh38.d1.vd1_mainChr/sepChrs/ -it--rm my-bio-container

Inside the container, the following commands were executed:

        for chr in {1..22}; do samtools faidx /ref/GRCh38.d1.vd1_mainChr/sepChrs/chr${chr}.fa; done


4. `conversion_script.py` converts the `FP_SNPs_10k_GB38_twoAllelsFormat.tsv` file to `FP_SNPs_10k_GB38_twoAllelsFormat_definiteAlleles.tsv` file using the following command:

        python3 script.py -i input.tsv -o output.tsv -p path/to/sepChrs -l log_file.log

The script uses key/value pairs to pass arguments to the script. To show all available options, use the `-h` flag:

        python3 script.py -h

The script is executed in Docker container.


5. Docker container was taken from [Bio-container](https://github.com/EugeneShchoka/Bio-container) and modified to add python3 with pysam and execution of the script.
The container was built using the following commands:

        docker build -t my-bio-container .
        CONTAINER_ID=$(docker run -d my-bio-container)
        docker cp $CONTAINER_ID:/data/FP_SNPs_10k_GB38_twoAllelsFormat_definiteAlleles.tsv ./
        docker rm $CONTAINER_ID

6. `FP_SNPs_10k_GB38_twoAllelsFormat_definiteAlleles.tsv` file contains info about correct REF and ALT alleles.

7. `FP_SNPs_10k_GB38.log` file contains the log of the script execution time and includes the number of processed and skipped gene variants.