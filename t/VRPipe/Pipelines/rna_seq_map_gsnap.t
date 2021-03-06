#!/usr/bin/env perl
use strict;
use warnings;
use File::Copy;
use Path::Class;

BEGIN {
    use Test::Most tests => 3;
    use VRPipeTest (
        required_env => [qw(VRPIPE_TEST_PIPELINES TRIMMOMATIC_JAR_PATH)],
        required_exe => [qw(fastqc java gsnap)]
    );
    use TestPipelines;
}
my $output_dir = get_output_dir('rna_seq_map_gsnap-test');
ok my $pipeline = VRPipe::Pipeline->create(name => 'rna_seq_map_gsnap'), 'able to get the rna_seq_map_gsnap pipeline';
my @s_names;
foreach my $stepmember ($pipeline->steps) {
    push(@s_names, $stepmember->step->name);
}

is_deeply \@s_names, [qw(fastqc_quality_report trimmomatic gsnap sam_sort sam_mark_duplicates)], 'the pipeline has the correct steps';

my $pipelinesetup = VRPipe::PipelineSetup->create(
    name       => 'rna_seq_gsnap_map_test',
    datasource => VRPipe::DataSource->create(
        type    => 'delimited',
        method  => 'all_columns',
        options => { delimiter => "\t" },
        source  => file(qw(t data gsnap_datasource.fofn)),
    ),
    output_root => $output_dir,
    pipeline    => $pipeline,
    options     => {
        trimmomatic_jar_path       => $ENV{TRIMMOMATIC_JAR_PATH},
        gsnap_db                   => 'mm9',
        paired_end                 => 1,
        sam_mark_duplicates_memory => 100,
        sam_mark_duplicates_time   => 1,
    }
);

my @output_subdirs = output_subdirs(1);

my $outputfile_1 = file(@output_subdirs, '5_sam_mark_duplicates', 'ERR032995_160_lines_1.paired.trim.concordant_uniq.sort.markdup.sam');
my $outputfile_2 = file(@output_subdirs, '4_sam_sort',            'ERR032995_160_lines_1.paired.trim.concordant_uniq.sort.sam');
my $outputfile_3 = file(@output_subdirs, '3_gsnap',               'ERR032995_160_lines_1.paired.trim.concordant_uniq');
my $outputfile_4 = file(@output_subdirs, '2_trimmomatic',         'ERR032995_160_lines_1.paired.trim.fastq');
my $outputfile_5 = file(@output_subdirs, '2_trimmomatic',         'ERR032995_160_lines_2.paired.trim.fastq');
my @outputfiles;
push(@outputfiles, $outputfile_1, $outputfile_2, $outputfile_3, $outputfile_4, $outputfile_5);
ok handle_pipeline(@outputfiles), 'rna-seq-pipeline ran ok, generating the expected output files';

finish;
