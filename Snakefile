configfile: "config.yaml"


# Comment out the following rule for the second step of the workflow.
# Uncomment the next rule.
rule all:
    input:
        expand(
            "funannotate/{sample}_annotation/predict_results",
            sample=config["samples"],
        ),
        expand("busco_results/{sample}_geno", sample=config["samples"]),
        expand("busco_results/{sample}_prot", sample=config["samples"]),


# Comment out the following rule for the first step of the workflow:
# rule all:
#     input:
#         expand(
#             "funannotate/{sample}_annotation/annotate_results",
#             sample=config["samples"],
#         )


rule fastp_trim_run:
    input:
        "Illumina_reads/",
    output:
        "spades_run.yaml",
    script:
        "scripts/fastp_trim.sh"


rule spades_run:
    input:
        "spades_run.yaml",
    output:
        dirspades="spades_assemblies/{sample}_assembly",
        scafspades="spades_assemblies/{sample}_assembly/scaffolds.fasta",
    shell:
        "spades.py --dataset {input} -o {output.dirspades}"


rule sizefilter_run:
    input:
        "spades_assemblies/{sample}_assembly/scaffolds.fasta",
    output:
        "spades_assemblies/scaffolds/{sample}_sizefiltered.scaffolds.fasta",
    shell:
        "seqkit -m 500 {input} > {output}"


rule busco_run:
    input:
        "spades_assemblies/scaffolds/{sample}_sizefiltered.scaffolds.fasta",
    output:
        dirbusco="busco_results/{sample}_geno",
        result="busco_results/{sample}_geno/short_summary.specific.fungi_odb10.{sample}.txt",
    params:
        buscodb=config["busco_odb_path"],
    threads: config["threads"]
    shell:
        "busco -i {input} -o {output.dirbusco} -l {params.buscodb} -c 10 -m geno"


rule funannotate_sort_run:
    input:
        rules.sizefilter_run.output,
    output:
        "funannotate/{sample}_sorted.scaffolds.fasta",
    shell:
        "funannotate sort -i {input} -o {output}"


rule funannotate_run:
    input:
        "funannotate/{sample}_sorted.scaffolds.fasta",
    output:
        dir_predict="funannotate/{sample}_annotation/predict_results",
    params:
        dir="funannotate/{sample}_annotation",
        species=config["species"],
        rna=config["trinity_ev"],
        prot=config["protein_ev"],
        buscoid=config["busco_odb_id"],
    threads: config["threads"]
    shell:
        "funannotate predict -i {input} "
        "--species '{params.species}' "
        "--transcript_evidence {params.rna} "
        "--protein_evidence {params.prot} $FUNANNOTATE_DB/uniprot_sprot.fasta "
        "-o {params.dir} --cpus {threads} "
        "--busco_db {params.buscoid}"


rule buscoprot_run:
    input:
        "funannotate/{sample}_annotation/predict_results/",
    output:
        dirbusco="busco_results/{sample}_prot",
        result="busco_results/{sample}_prot/short_summary.specific.fungi_odb10.{sample}.txt",
    threads: config["threads"]
    params:
        uspecies=config["underlined_species"],
        buscodb=config["busco_odb_path"],
    shell:
        "busco -i {input}/{params.uspecies}.proteins.fa -o {output.dirbusco} -l {params.buscodb} -c {threads} -m protein"


rule funcpredict_run:
    input:
        rules.funannotate_run.output.dir_predict,
    output:
        "funannotate/{sample}_annotation/annotate_results",
    params:
        iprscan=config["iprscan_xml"],
        buscoid=config["busco_odb_id"],
    threads: config["threads"]
    shell:
        "funannotate annotate -i {input} "
        "--species 'Acaulospora delicata' "
        "--iprscan {params.iprscan} "
        "--cpus {threads} --busco_db {params.buscoid} --force"
