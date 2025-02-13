process SENTIEON_DATAMETRICS {
    tag "$meta.id"
    label 'process_high'
    label 'sentieon'

    secret 'SENTIEON_LICENSE_BASE64'

    input:
    tuple val(meta), path(bam), path(bai)
    path fasta
    path fai

    output:
    tuple val(meta), path('*mq_metrics.txt') , emit: mq_metrics
    tuple val(meta), path('*qd_metrics.txt') , emit: qd_metrics
    tuple val(meta), path('*gc_summary.txt') , emit: gc_summary
    tuple val(meta), path('*gc_metrics.txt') , emit: gc_metrics
    tuple val(meta), path('*aln_metrics.txt'), emit: aln_metrics
    tuple val(meta), path('*is_metrics.txt') , emit: is_metrics
    path  "versions.yml"                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    def input  = bam.sort().collect{"-i $it"}.join(' ')
    def prefix       = task.ext.prefix ?: "${meta.id}"
    """
    if [ \${SENTIEON_LICENSE_BASE64:-"unset"} != "unset" ]; then
        echo "Initializing SENTIEON_LICENSE env variable"
        source sentieon_init.sh SENTIEON_LICENSE_BASE64
    fi

    sentieon \\
        driver \\
        -t $task.cpus \\
        -r $fasta \\
        $input \\
        $args \\
        --algo GCBias --summary ${prefix}_gc_summary.txt ${prefix}_gc_metrics.txt \\
        --algo MeanQualityByCycle ${prefix}_mq_metrics.txt \\
        --algo QualDistribution ${prefix}_qd_metrics.txt \\
        --algo InsertSizeMetricAlgo ${prefix}_is_metrics.txt  \\
        --algo AlignmentStat ${prefix}_aln_metrics.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sentieon: \$(echo \$(sentieon driver --version 2>&1) | sed -e "s/sentieon-genomics-//g")
    END_VERSIONS
    """

    stub:
    def prefix       = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_mq_metrics.txt
    touch ${prefix}_qd_metrics.txt
    touch ${prefix}_gc_summary.txt
    touch ${prefix}_gc_metrics.txt
    touch ${prefix}_aln_metrics.txt
    touch ${prefix}_is_metrics.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sentieon: \$(echo \$(sentieon driver --version 2>&1) | sed -e "s/sentieon-genomics-//g")
    END_VERSIONS
    """
}
