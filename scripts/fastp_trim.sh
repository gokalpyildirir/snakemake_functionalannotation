#!/bin/bash
cd ../Illumina_reads && mkdir trimmed_reads qc && echo "Starting the read trimming now."
for f1 in *_R1.fastq.gz
do
    f2=${f1%%_R1.fastq.gz}"_R2.fastq.gz"
    j=${f1%%_R1.fastq.gz}".json"
    h=${f1%%_R1.fastq.gz}".html"
    fastp -i $f1 -I $f2 \
    -o "trimmed_reads/trimmed_"$f1 -O "trimmed_reads/trimmed_"$f2 \
    -q 30 -w 16 -j "qc/"$j -h "qc/"$h --detect_adapter_for_pe -V
done
cd trimmed_reads && echo "Starting the bbnorm.sh normalization now."
for ff1 in trimmed_*_R1.fastq.gz
do
    ff2=${ff1%%_R1.fastq.gz}"_R2.fastq.gz"
    bbnorm.sh in=$ff1 in2=$ff2 target=100 min=5 out="bbnormed_"$ff1 out2="bbnormed_"$ff2
done
echo "Starting the Kraken2 contamination filtering now. "
# You need to change the Kraken2 db path here
for fff1 in bbnormed_trimmed_*_R1.fastq.gz
do
    fff2=${fff1%%_R1.fastq.gz}"_R2.fastq.gz"
    readkraken=${fff1%%_R1.fastq.gz}"#_krakened.fastq.gz"
    reportkraken=${fff1%%_R1.fastq.gz}"_report.txt"
    kraken2 -db kraken2_standard_db --threads 16 --unclassified-out $readkraken \
    --gzip-compressed --paired $fff1 $fff2 --report ../qc/$reportkraken
done
cd ../../scripts
python3 spades_yaml_maker.py && echo "Spades YAML file created! "
