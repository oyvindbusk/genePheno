#!/usr/bin/env nextflow

// Run like: 
// nextflow run run_mosdepth.nf -c run_mosdepth.config
// Generates mosdepth output for QC

params.panels   = "/illumina/analysis/prod_pipeline/refs/interval_files/filtexlister/2022/**.BED"
params.bams     = "./bams/*.bam"
params.bais     = "./bams/*.bai"
// params.twistbed = '/illumina/runs_diag/prod_pipeline/refs/interval_files/twist/Twist_Exome_plus_RefSeq_Gencode_targets_Hg19.liftover.bed'
params.twistbed = '/illumina/analysis/prod_pipeline/refs/interval_files/twist/TWIST_2_0/hg19_Twist_exome_2_1_annotated_targets_sorted.bed'
params.utrbed   = '/illumina/analysis/prod_pipeline/refs/interval_files/utr/UTR_combined_selected_noncoding.bed'
params.outdir   = './results'

// Iterate all panels
panels = Channel.fromPath(params.panels).filter {it && !it.toString().endsWith('_full_gene.BED')}
pan = Channel.fromPath(params.panels).filter {it && !it.toString().endsWith('_full_gene.BED')}


// Iterate all bams
bams = Channel.fromPath(params.bams).map{line -> 
    return [line,line[-1].toString().split('_recal')[0]]
}



// Run bedtools 
process bedtools {

    input:
    file(bed) from panels
    file(twist) from file(params.twistbed)
    file(utr) from file(params.utrbed)
    
    output:
    file("${bed.toString().replace('.BED','_intersected.BED')}") into bedtools_out

    script:
    """
    bedtools intersect -a $twist -b $bed -wb | cut -f 1,2,3,9 > ${bed.toString().replace('.BED','_intersected.BED')}
    """

}
// Join with all samples
samples = bedtools_out.combine(bams)
    
// Run Mosdepth
process mosdepth {
    
    //maxForks 16
        
    input:
    set file(bed), file(bam), val(sample) from samples
    file bai from Channel.fromPath(params.bais).collect()
    
    output:
    set file("${bed[0].toString().replace('_intersected.BED','')}_${sample}.regions.bed.gz"), file("${bed[0].toString().replace('_intersected.BED','')}_${sample}.thresholds.bed.gz") into out

    script:
    """
    mosdepth -t 6 \\
    --thresholds 1,5,10,20 \\
    --by $bed  \\
    ${bed[0].toString().replace('_intersected.BED','')}_$sample \\
    $bam
    """

}

process combine_beds {
    
    echo true
    publishDir path: "${params.outdir}", mode: 'copy'

    input:
    file(bed) from pan
    file(beds) from out.collect()

    output:
    set file("${bed.toString().replace(".BED", "")}.thresholds.bed"), file("${bed.toString().replace(".BED", "")}.regions.bed") into out2

    script:
    def cmd = ''
    def cmd2 = ''
    def count = 0
    beds.collate(2).each { regions, thresholds ->
        if (regions.toString().contains(bed.toString().split('.BED')[0]))  {
            if(count == 0) {
                cmd  += "paste <(zcat ${thresholds} | cut -f 1,2,3,4,5) "
                cmd2 += "paste <(zcat ${regions}) "
            } else {
                cmd  += "<(zcat ${thresholds} | cut -f 5) "
                cmd2 += "<(zcat ${regions} | cut -f 5) "
            }
            count += 1
        }
        
        
        
        }
    cmd  += "> ${bed.toString().replace(".BED", "")}.thresholds.bed;"
    cmd2 += "> ${bed.toString().replace(".BED", "")}.regions.bed"
    cmd += cmd2
    cmd
    
}
