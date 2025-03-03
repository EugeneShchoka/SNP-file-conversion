import csv
import sys
import os
import argparse
import pysam
import logging
from datetime import datetime

parser = argparse.ArgumentParser(
    description='Convert vcf to identify REF and ALT alleles'
)

parser.add_argument(
    "-i", "--input", required=True, help="Input vcf file tsv format"
)

parser.add_argument(
    "-o", "--output", required=True, help="Output vcf file tsv format with definite alleles"
)

parser.add_argument(
    "-p", "--path", required=True, help="Path to reference genome splitted by chr[1-22,M,X,Y]"
)

parser.add_argument(
    "-l", "--log", required=True, help="Log file"
)

args = parser.parse_args()

file = args.input
output = args.output
ref_folder = args.path
log_file = args.log

logging.basicConfig(
    filename=log_file,
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)

start_time = datetime.now()
logging.info(f"Conversion script started at {start_time}")


def get_ref_allele(chrom, pos):
    ref_file = f"{ref_folder}/{chrom}.fa"

    if not os.path.exists(ref_file):
        logging.error(f"Reference file {ref_file} does not exist.")
        sys.exit(1)

    try:
        fasta = pysam.FastaFile(ref_file)
        ref_allele = fasta.fetch(chrom, pos - 1, pos)
        logging.info(f"Reference allele for {chrom}:{pos} is {ref_allele}")
        return ref_allele
    except:
        logging.error(f"Error fetching reference allele for {chrom}:{pos}")
        sys.exit(1)


if not os.path.exists(file):
    logging.error(f"Input file {file} does not exist.")
    sys.exit(1)

with open(output, 'w') as out_file, open(file, 'r') as input_file:
    reader = csv.reader(input_file, delimiter="\t")
    writer = csv.writer(out_file, delimiter="\t")

    # write header to output file as #CHROM<TAB>POS<TAB>ID<TAB>REF<TAB>ALT
    writer.writerow(['#CHROM', 'POS', 'ID', 'REF', 'ALT'])

    header = next(reader, None)
    if header != ['#CHROM', 'POS', 'ID', 'allele1', 'allele2']:
        logging.error(
            "Wrong header format, required: '#CHROM', 'POS', 'ID', 'allele1', 'allele2'"
        )
        sys.exit(1)

    processed = 0
    skipped = 0

    for row in reader:
        chrom = row[0]
        pos = int(row[1])
        id = row[2]
        allele1 = row[3]
        allele2 = row[4]

        ref = get_ref_allele(chrom, pos)

        if ref == "N":
            skipped += 1
            continue

        if ref == allele2:
            allele1, allele2 = allele2, allele1

        writer.writerow([chrom, pos, id, allele1, allele2])
        processed += 1

    logging.info(f"Processed {processed} rows, skipped {skipped} rows")

end_time = datetime.now()
execution_time = end_time - start_time
logging.info(f"Conversion script finished at {end_time}, execution time: {execution_time}")
