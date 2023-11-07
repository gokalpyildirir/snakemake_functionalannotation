rule fastp_trim_run:
    input:
        read1 = "Illumina_reads/{sample}_R1_001.fastq.gz",
        read2 = "Illumina_reads/{sample}_R2_001.fastq.gz"
    output:
        tread1 = "Illumina_reads/trimmed/{sample}_R1_001_trimmed.fastq.gz",
        tread2 = "Illumina_reads/trimmed/{sample}_R2_001_trimmed.fastq.gz"
    threads: 10
    shell:
        "fastp -i {input.read1} -o {output.tread1} -I {input.read2} -O {output.tread2} -q 30 "
        "-w {threads} -j {wildcards.sample}.json -h {wildcards.sample}.html --detect_adapter_for_pe -V" 
    
rule bbnorm_run:
    input:
        tread1 = "Illumina_reads/trimmed/{sample}_R1_001_trimmed.fastq.gz",
        tread2 = "Illumina_reads/trimmed/{sample}_R2_001_trimmed.fastq.gz"
    output:
        bread1 = "Illumina_reads/bbnormed_krakened/{sample}_R1_bbnormed.fastq.gz",
        bread2 = "Illumina_reads/bbnormed_krakened/{sample}_R2_bbnormed.fastq.gz"
    shell:
        "bbnorm.sh in={input.tread1} in2={input.tread2} target=100 min=5 out={output.bread1} out2={output.bread2}"

rule kraken2_run:
    input:
        bread1 = "Illumina_reads/bbnormed_krakened/{sample}_R1_bbnormed.fastq.gz",
        bread2 = "Illumina_reads/bbnormed_krakened/{sample}_R2_bbnormed.fastq.gz"
    output:
        kread1 = "Illumina_reads/bbnormed_krakened/{sample}_R1_krakened.fastq.gz",
        kread2 = "Illumina_reads/bbnormed_krakened/{sample}_R2_krakened.fastq.gz"
    threads: 10
    shell:
        "kraken2 -db kraken2_standard_db --threads {threads} --unclassified-out Illumina_reads/bbnormed_krakened/{wildcards.sample}#_krakened.fastq.gz "
        "--gzip-compressed --paired {input.bread1} {input.bread2} --report {wildcards.sample}_report.txt"

rule spades_run:
    input:
        kread1 = "Illumina_reads/bbnormed_krakened/{sample}_R1_krakened.fastq.gz",
        kread2 = "Illumina_reads/bbnormed_krakened/{sample}_R2_krakened.fastq.gz"
    output:
        dirspades = "spades_assemblies/{sample}_assembly",
        scafspades = "spades_assemblies/{sample}_assembly/scaffolds.fasta"
    shell:
        "spades.py -1 {input.kread1} -2 {input.kread2} -o {output.dirspades}"

rule sizefilter_run:
    input:
        "spades_assemblies/{sample}_assembly/scaffolds.fasta"
    output:
        "spades_assemblies/scaffolds/{sample}_sizefiltered.scaffolds.fasta"
    shell:
        "seqkit -m 500 {input} > {output}"

rule busco_run:
    input:
        "spades_assemblies/scaffolds/{sample}_sizefiltered.scaffolds.fasta"
    output:
        dirbusco = "busco_results/{sample}_geno",
        result = "busco_results/{sample}_geno/short_summary.specific.fungi_odb10.{sample}.txt",
    shell:
        "busco -i {input} -o {output.dirbusco} -l ./fungi_odb10 -c 10 -m geno"

rule funannotate_sort_run:
    input:
        rules.sizefilter_run.output
    output:
        "funannotate/{sample}_sorted.scaffolds.fasta"
    shell:
        "funannotate sort -i {input} -o {output}"

rule funannotate_run:
    input:
        scaf = "funannotate/{sample}_sorted.scaffolds.fasta",
        rna = "funannotate/transcript_evidence/{sample}/trinity_out_dir.Trinity.fasta",
        prot = "funannotate/protein_evidence/{sample}/sequence.fasta"
    output:
        dir = "funannotate/{sample}_annotation"
    threads: 10
    shell:
        "funannotate predict -i {input.scaf} "
        "--transcript_evidence {input.rna} "
        "--protein_evidence {input.prot} $FUNANNOTATE_DB/uniprot_sprot.fasta "
        "-o {output.dir} --cpus {threads}"
