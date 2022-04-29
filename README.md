# MaSuRCA Genome Assembly and Analysis Toolkit Quick Start Guide

The MaSuRCA (Maryland Super Read Cabog Assembler) genome assembly and analysis toolkit contains of MaSuRCA genome assembler, QuORUM error corrector for Illumina data, POLCA genome polishing software, Chromosome scaffolder, jellyfish mer counter, and MUMmer aligner.  The usage instructions for the additional tools that are exclusive to MaSuRCA, such as POLCA and Chromosome scaffolder are provided at the end of this Guide. 

The MaSuRCA assembler combines the benefits of deBruijn graph and Overlap-Layout-Consensus assembly approaches. Since version 3.2.1 it supports hybrid assembly with short Illumina reads and long high error PacBio/MinION data.

Citation for MaSuRCA: Zimin AV, Marçais G, Puiu D, Roberts M, Salzberg SL, Yorke JA. The MaSuRCA genome assembler. Bioinformatics. 2013 Nov 1;29(21):2669-77.

Citation for MaSuRCA hybrid assembler: Zimin AV, Puiu D, Luo MC, Zhu T, Koren S, Yorke JA, Dvorak J, Salzberg S. Hybrid assembly of the large and highly repetitive genome of Aegilops tauschii, a progenitor of bread wheat, with the mega-reads algorithm. Genome Research. 2017 Jan 1:066100.

This project is governed by the code of conduct at https://github.com/alekseyzimin/masurca/blob/master/code_of_conduct.md

# 1. System requirements/run rimes for assembly

## Compile/Install requirements. 
To compile the assembler we require gcc version 4.7 or newer to be installed on the system.
Only Linux is supported (May or may not compile under gcc for MacOS or Cygwin, Windows, etc). The assembler has been tested on the following distributions:

•	Fedora 12 and up

•	RedHat 5 and 6 (requires installation of gcc 4.7)

•	CentOS 5 and 6 (requires installation of gcc 4.7)

•	Ubuntu 12 LTS and up

•	SUSE Linux 16 and up

WARNING:  installing MaSuRCA via Bioconda is not supported, and may result in broken installation due to conflicts with other packages, especially Mummer package.  If you get errors during assembly related to mummer.pm, remove the Bioconda from your path by editing your .bashrc. 

## Hardware requirements for assembly.
The hardware requirements vary with the size of the genome project.  Both Intel and AMD x64 architectures are supported. The general guidelines for hardware configuration are as follows:

•	Bacteria (up to 10Mb): 16Gb RAM, 8+ cores, 10Gb disk space

•	Insect (up to 500Mb): 128Gb RAM, 16+ cores, 1Tb disk space

•	Avian/small plant genomes (up to 1Gb): 256Gb RAM, 32+ cores, 2Tb disk space

•	Mammalian genomes (up to 3Gb): 512Gb RAM, 32+ cores, 5Tb disk space

•	Plant genomes (up to 30Gb): 2Tb RAM, 64+cores, 10Tb+ disk space

## Expected assembly run times. 
The expected run times depend on the cpu speed/number of cores used for the assembly and on the data used. The following lists the expected run times for the minimum configurations outlined above for Illumina-only data sets. Adding long reads (454, Sanger, etc. makes the assembly run about 50-100% longer:

•	Bacteria (up to 10Mb): <1 hour

•	Insect (up to 500Mb): 1-2 days

•	Avian/small plant genomes (up to 1Gb): 4-5 days

•	Mammalian genomes (up to 3Gb): 15-20 days

•	Plant genomes (up to 30Gb): 60-90 days

# 2. Installation instructions

To install, first download the latest distribution from the github release page https://github.com/alekseyzimin/masurca/releases.Then untar/unzip the package MaSuRCA-X.X.X.tgz, cd to the resulting folder and run `./install.sh`.  The installation script will configure and make all necessary packages.

Only for developers:  you can clone the development tree, but then there are dependencies such as swig and yaggo (http://www.swig.org/ and https://github.com/gmarcais/yaggo) that must be available on the PATH:

```
git clone https://github.com/alekseyzimin/masurca
git submodule init
git submodule update
make
```
Note that on some systems you may encounter a build error due to lack of xlocale.h file, because it was removed in glibc 2.26.  xlocale.h is used in Perl extension modules used by MaSuRCA.  To fix/work around this error, you can upgrade the Perl extensions, or create a symlink for xlocale.h to /etc/local.h or /usr/include/locale.h, e.g.:
```
ln -s /usr/include/locale.h /usr/include/xlocale.h
```

# 3. Running the MaSuRCA assembler

## Overview. 
The general steps to run the MaSuRCA assemblers are as follows, and will be covered in details in later sections. It is advised to create a new directory for each assembly project.

In the rest of this document, `/install_path` refers to a path to the directory in which `./install.sh` was run.

IMPORTANT! Avoid using third party tools to pre-process the Illumina data before providing it to MaSuRCA, unless you are absolutely sure you know exactly what the preprocessing tool does.  Do not do any trimming, cleaning or error correction. This will likely deteriorate the assembly.

There are two ways to run MaSuRCA.  For small projects that only use data from two Illumina sequencing fastq files representing forward and reverse reads from a paired end run, and (optionally) data from a long-read run such as Pacbio SMRT or Nanopore sequencing run in a single fasta/fastq file, one can use a simplified approach.  This runs the full version of the MaSuRCA assembly pipeline with default settings on a command line. The options are described in the usage message that is displayed by using -h or --help switch.  There are three command line switches, -i, -t and -r.  -t specifies the number of threads to use, -i specifies the names and paths to Illumina paired end reads files and -r specifies the name and the path to the long reads file.  For example:

`/path_to_MaSuRCA/bin/masurca -t 32 -i /path_to/pe_R1.fa,/path_to/pe_R2.fa`

will run assembly with only Illumina paired end reads from files /path_to/pe_R1.fa (forward) and /path_to/pe_R2.fa (reverse). An example of the hybrid assembly:

`/path_to_MaSuRCA/bin/masurca -t 32 -i /path_to/pe_R1.fa,/path_to/pe_R2.fa -r /path_to/nanopore.fastq.gz`

This command will run a hybrid assembly, correcting Nanopore reads with Illumina data first.  Ilumina paired end reads files must be fastq, can be gzipped, and Nanopore/PacBio data files for the -r option can be fasta or fastq and can be gzipped. 

For bigger projects that use Ullimina data from multiple instrument runs, Illumina mate pairs, legacy Sanger data and/or need parameter adjustments, there is a more advanced mode. To use it, create a configuration file which contains the location of the compiled assembler, the location of the data and some parameters. Copy in your assembly directory the template configuration file `/install_path/sr_config_example.txt` which was created by the installer with the correct paths to the freshly compiled software and with reasonable parameters. Most assembly projects should only need to set the paths to the input data in the example configuration.  More detailed description of the configuration is in the next section.

Second, run the `masurca` script which will generate from the configuration file a shell script `assemble.sh`. This last script is the main driver of the assembly.

Finally, run the script `assemble.sh` to assemble the data.

## Configuration. 
To run the assembler, one must first create a configuration file that specifies the location of the executables, data and assembly parameters for the assembler. The installation script will create a sample configuration file `sr_config_example.txt`. Lines starting with a pound sign ('#') are comments and ignored. The configuration file consists of two sections: DATA and PARAMETERS. Each section concludes with END statement. The easiest way is to copy the sample configuration file to the directory of choice for running the assembly and then modify it according to the specifications of the assembly project. 

Please read all comments in the example configuration file before using MaSuRCA. All options are explained in the comments.  Here is the example configuration file:
```
# example configuration file 

# DATA is specified as type {PE,JUMP,OTHER,PACBIO} and 5 fields:
# 1)two_letter_prefix 2)mean 3)stdev 4)fastq(.gz)_fwd_reads
# 5)fastq(.gz)_rev_reads. The PE reads are always assumed to be
# innies, i.e. --->.<---, and JUMP are assumed to be outties
# <---.--->. If there are any jump libraries that are innies, such as
# longjump, specify them as JUMP and specify NEGATIVE mean. Reverse reads
# are optional for PE libraries and mandatory for JUMP libraries. Any
# OTHER sequence data (454, Sanger, Ion torrent, etc) must be first
# converted into Celera Assembler compatible .frg files (see
# http://wgs-assembler.sourceforge.com)
DATA
#Illumina paired end reads supplied as <two-character prefix> <fragment mean> <fragment stdev> <forward_reads> <reverse_reads>
#if single-end, do not specify <reverse_reads>
#MUST HAVE Illumina paired end reads to use MaSuRCA
PE= pe 500 50  /FULL_PATH/frag_1.fastq  /FULL_PATH/frag_2.fastq
#Illumina mate pair reads supplied as <two-character prefix> <fragment mean> <fragment stdev> <forward_reads> <reverse_reads>
JUMP= sh 3600 200  /FULL_PATH/short_1.fastq  /FULL_PATH/short_2.fastq
#pacbio OR nanopore reads must be in a single fasta or fastq file with absolute path, can be gzipped
#if you have both types of reads supply them both as NANOPORE type
#PACBIO=/FULL_PATH/pacbio.fa
#NANOPORE=/FULL_PATH/nanopore.fa
#Other reads (Sanger, 454, etc) one frg file, concatenate your frg files into one if you have many
#OTHER=/FULL_PATH/file.frg
#synteny-assisted assembly, concatenate all reference genomes into one reference.fa; works for Illumina-only data
#REFERENCE=/FULL_PATH/nanopore.fa
END

PARAMETERS
#PLEASE READ all comments to essential parameters below, and set the parameters according to your project
#set this to 1 if your Illumina jumping library reads are shorter than 100bp
EXTEND_JUMP_READS=0
#this is k-mer size for deBruijn graph values between 25 and 127 are supported, auto will compute the optimal size based on the read data and GC content
GRAPH_KMER_SIZE = auto
#set this to 1 for all Illumina-only assemblies
#set this to 0 if you have more than 15x coverage by long reads (Pacbio or Nanopore) or any other long reads/mate pairs (Illumina MP, Sanger, 454, etc)
USE_LINKING_MATES = 0
#specifies whether to run the assembly on the grid
USE_GRID=0
#specifies grid engine to use SGE or SLURM
GRID_ENGINE=SGE
#specifies queue (for SGE) or partition (for SLURM) to use when running on the grid MANDATORY
GRID_QUEUE=all.q
#batch size in the amount of long read sequence for each batch on the grid
GRID_BATCH_SIZE=500000000
#use at most this much coverage by the longest Pacbio or Nanopore reads, discard the rest of the reads
#can increase this to 30 or 35 if your reads are short (N50<7000bp)
LHE_COVERAGE=25
#set to 0 (default) to do two passes of mega-reads for slower, but higher quality assembly, otherwise set to 1
MEGA_READS_ONE_PASS=0
#this parameter is useful if you have too many Illumina jumping library mates. Typically set it to 60 for bacteria and 300 for the other organisms 
LIMIT_JUMP_COVERAGE = 300
#these are the additional parameters to Celera Assembler.  do not worry about performance, number or processors or batch sizes -- these are computed automatically. 
#CABOG ASSEMBLY ONLY: set cgwErrorRate=0.25 for bacteria and 0.1<=cgwErrorRate<=0.15 for other organisms.
CA_PARAMETERS =  cgwErrorRate=0.15
#CABOG ASSEMBLY ONLY: whether to attempt to close gaps in scaffolds with Illumina  or long read data
CLOSE_GAPS=1
#number of cpus to use, set this to the number of CPUs/threads per node you will be using
NUM_THREADS = 16
#this is mandatory jellyfish hash size -- a safe value is estimated_genome_size*20
JF_SIZE = 200000000
#ILLUMINA ONLY. Set this to 1 to use SOAPdenovo contigging/scaffolding module.  
#Assembly will be worse but will run faster. Useful for very large (>=8Gbp) genomes from Illumina-only data
SOAP_ASSEMBLY=0
#If you are doing Hybrid Illumina paired end + Nanopore/PacBio assembly ONLY (no Illumina mate pairs or OTHER frg files).  
#Set this to 1 to use Flye assembler for final assembly of corrected mega-reads.  
#A lot faster than CABOG, AND QUALITY IS THE SAME OR BETTER. 
#Works well even when MEGA_READS_ONE_PASS is set to 1.  
#DO NOT use if you have less than 15x coverage by long reads.
FLYE_ASSEMBLY=0
END 
```
DATA – in this section the user must specify the types of data available for the assembly. Each line represent a library and must start with PE=, JUMP= or OTHER= for the 3 different type of input read library (Paired Ends, Jumping or other). There can be multiple lines starting with `PE=` (or JUMP=), one line per library. PE and JUMP data must be in fastq format while the other data is in provided as a Celera Assembler frag format (`.frg`). Every PE or JUMP library is named by a unique two letter prefix. No two library can have the same prefix and a prefix should be made of two printable characters or number (no space or control characters), e.g. `aa`, `ZZ`, `l5`, or `J2`.

 The following types of data are supported:
 
•	Illumina paired end (or single end) reads -- MANDATORY:

`PE = two_letter_prefix mean stdev /PATH/fwd_reads.fastq /PATH/rev_reads.fastq`

example:

`PE = aa 180 20 /data/fwd_reads.fastq /data/rev_reads.fastq`

The `mean` and `stdev` parameters are the library insert average length and standard deviation. If the standard deviation is not known, set it to approximately 15% of the mean.If the second (reverse) read set is not available, do not specify it and just specify the forward reads.  Files must be in fastq format and can be gzipped.

•	Illumina jumping/DiTag/other circularization protocol-based library mate pair reads:

`JUMP = two_letter_prefix mean stdev /PATH/fwd_reads.fastq /PATH/rev_reads.fastq`

example:

`JUMP = cc 3500 500 /data/jump_fwd_reads.fastq /data/jump_rev_reads.fastq`

By default, the assembler assumes that the jumping library pairs are “outties” (<--   -->). Some protocols (DiTag) use double-circularization which results in “innie” pairs (-->   <--).  In this case please specify negative mean.

•	Other types of data (454, Sanger, etc) must be converted to CABOG format FRG files (see CABOG documentation at http://sourceforge.net/apps/mediawiki/wgs-assembler/index.php?title=Main_Page ):

`OTHER = data.frg`

•	PacBio/MinION data are supported.  Note that you have to have 50x + coverage in Illumina Paired End reads to use PacBio of Oxford Nanopore MinION data.  Supply PacBio or MinION reads in a single fasta or fastq file (can be gzipped) as:

`PACBIO=file.fa` or `NANOPORE=file.fa`

If you have both PacBio and Nanopore reads, cat them all into a single fasta file and supply them as "NANOPORE" type. More than one entry for each data type/set of files is allowed EXCEPT for PacBio/Nanopore data.  If you have several pairs of PE or JUMP fastq files, specify each pair on a separate line with a different two-letter prefix.  PACBIO or NANOPORE data must be in ONE file.

PARAMETERS. The following parameters are mandatory:

`NUM_THREADS=16`

set it to the number of cores in the computer to be used for assembly

`JF_SIZE=2000000000`

jellyfish hash size, set this to about 10x the genome size.

`GRID_QUEUE=all.q`

mandatory if USE_GRID set to 1. Name of the SGE queue to use.  NOTE that number of slots must be set to 1 for each physical computer

Optional parameters:

`USE_LINKING_MATES=1`

Most of the paired end reads end up in the same super read and thus are not passed to the assembler.  Those that do not end up in the same super read are called ”linking mates” . The best assembly results are achieved by setting this parameter to 1 for Illumina-only assemblies.  If you have more than 2x coverage by long (454, Sanger, etc) reads, set this to 0. 

`GRAPH_KMER_SIZE=auto`

this is the kmer size to be used for super reads.  “auto” is the safest choice. Only advanced users should modify this parameter.

`LIMIT_JUMP_COVERAGE = 60`

in some cases (especially for bacterial assemblies) the jumping library has too much coverage which confuses the assembler.  By setting this parameter you can have assembler down-sample the jumping library to 60x (from above) coverage.  For bigger eukaryotic genomes you can set this parameter to 300.

`CA_PARAMETERS = cgwErrorRate=0.1

these are the additional parameters to Celera Assembler, and they should only be supplied/modified by advanced users.  “ovlMerSize=30 cgwErrorRate=0.25 ovlMemory=4GB” should be used for bacterial assemblies; “ovlMerSize=30 cgwErrorRate=0.15 ovlMemory=4GB” should be used for all other genomes

`SOAP_ASSEMBLY = 0`

Set this to 1 if you would like to perform contigging and scaffolding done by SOAPdenovo2 instead of CABOG.  This will decrease assembly runtime, but will likely result in inferior assembly.  This option is useful when assembling very large genomes (5Gbp+), as CABOG may take months to rung on these.

# Running MaSuRCA hybrid assembly on the grid. 
Starting with version 3.2.4 MaSuRCA supports execution of the mega-reads correction of the long high error reads such as PacBio or Nanopore reads on SGE grid.  SLURM support is implemented in 3.3.1 and later releases.  To run MaSuRCA on the grid, you must set USE_GRID=1 and specify the SGE queue to use (MANDATORY) using GRID_QUEUE=<name>.  Please create a special queue on the SGE grid for this operation.  The queue MUST have ONLY 1 SLOT PER PHYSICAL COMPUTER. Each batch will use NUM_THREADS threads on each computer, thus the number of slots in the SGE queue should be set to 1 for each physical computer.

Long reads are corrected in batches. GRID_BATCH_SIZE is the batch size in bases of long reads.  You can figure out the number of batches by dividing the total amount of long read data by the GRID_BATCH_SIZE. Memory usage for each batch does not depend on this parameter, it scales with genome size instead. Since there is some overhead to starting each batch, I recommend setting this to have not more than 100 batches. The setting that is equal to 2-3 times the number of physical computers you have in the grid works best.  The total number of batches is limited to 1000.
The Celera Assembler (or CABOG) will use the grid as well to run overlapper only.  Overlapper jobs are not memory-intensive and thus multiple jobs can be submitted to each node.  Each job will use up to 4 threads – the code is not efficient enough to use more than that number of threads effectively.  

# If you only need to output corrected PacBio or Nanopore reads or super-reads. 
You can abort the assemble.sh script after it reports "Running assembly" if you only need corrected reads or super-reads output.  
The super reads file is work1/superReadSequences.fasta.  The PacBio corrected reads are in mr.41.15.17.0.029.1.fa.  The Nanopore corrected reads are in mr.41.15.15.0.02.1.fa.  The PacBio/Nanopore corrected read names correspond to the original read names.

# The masurca and the assemble.sh scripts. 
Once you’ve created a configuration file, use the `masurca` script from the MaSuRCA bin directory to generate the `assemble.sh` shell script that executes the assembly:

`$ /install_path/ MaSuRCA-X.X.X/bin/masurca config.txt`

To run the assembly, execute `assemble.sh`. 
Typically upon completion of the successful assembly, the current directory, where `assemble.sh` was generated, will contain the following files, in reverse chronological order:

`$ ls –lth`

FILE	CONTAINS

`gapClose.err`	STDOUT/STDERR for gap filling

CA	CABOG folder – the final assembly ends up in CA/9-terminator  or CA/10-gapclose (if gapClose succeeded, most of the time)

`runCA2.out`	CABOG stdout for scaffolder

`tigStore.err`	Stderr for tigStore

`unitig_cov.txt`	CABOG coverage statistics

`global_arrival_rate.txt`	CABOG coverage statistics, global arrival rate

`unitig_layout.txt`	Unitig layout/sequences used to recomputed the coverage statistics

`genome.uid`	File relating UID to read name for CABOG

`runCA1.out`	CABOG stdout for unitig consensus

`runCA0.out`	CABOG stdout for initial stages: store building, overlapping, unitigging

`superReadSequences_shr.frg`	FRG file for super reads, super reads >2047br are shredded with an overlap of 1500bp

`pe.linking.frg`	FRG file of PE pairs where the two reads ended up in different super reads

`pe.linking.fa`	Fasta file of PE pairs where the two reads ended up in different super reads

`work1/`	Working directory of the super reads code that generates the super reads from PE reads

`super1.err`	STDERR output of the super reads code that generates the super reads from PE reads

`sj.cor.clean.frg`	CABOG FRG file with corrected jumping library pairs, redundant and non-junction removed, coverage limited

`sj.cor.ext.reduced.fa`	Fasta file with corrected jumping library pairs, redundant and non-junction removed, coverage limited

`mates_to_break.txt`	File that lists the jumping library mates that are to be removed, if the jumping library clone coverage exceeds the LIMIT_JUMP_COVERAGE parameter 

`compute_jump_coverage.txt`	Supplementary file used to compute clone coverage of the jumping library, post-filtering

`sj.cor.clean.fa`	Fasta file with corrected jumping library pairs, redundant and non-junction removed

`redundant_sj.txt`	Text file with names of the redundant jumping library mate pairs

`chimeric_sj.txt`	text file with names of the non-junction jumping library mate pairs

`work2/`	working directory for the super reads code used to filter the JUMP libraries for non-junction/redundant pairs

`work2.1/`	working directory for secondary jumping filter based on the variable k-mer size

`super2.err`	STDERR output of the super reads code used to filter the JUMP libraries for non-junction/redundant pairs

`guillaumeKUnitigsAtLeast32bases_all.fasta`	fasta file for k-unitigs (see the paper referred above)

k_u_0	jellyfish hash created from all error corrected reads, and used to estimate the genome size

`??.cor.fa`	error corrected JUMP reads, one such file for each library with '??' being the prefix.  The ordering of the reads is arbitrary, but the pairs are guaranteed to appear together. No quality scores.

`error_correct.log`	log file for error correction

`pe.cor.fa`	error corrected PE reads.  The ordering of the reads is arbitrary, but the pairs are guaranteed to appear together. No quality scores

combined_0	special combined Jellyfish hash for error correction

`pe_data.tmp`	supplementary information to figure out the GC content and lengths of PE reads

`sj.renamed.fastq`	the ??.renamed.fastq file is created for each “JUMP= …” entry in the configuration file. These file(s) contain renamed reads in the fastq format

`meanAndStdevByPrefix.sj.txt` auto-generated file of “fake” mean and stdev for non-junction jumping library pairs.  The Illumina protocol states that these are about 200-700bp long

`pe.renamed.fastq`	the `??.renamed.fastq file` is created for each “PE= …” entry in the configuration file. These file(s) contain renamed reads in the fastq format.

`meanAndStdevByPrefix.pe.txt`	auto-generated file of means and stdevs for PE reads

`assemble.sh`	the original assemble.sh script

# Restarting a failed assembly. 
If something fails or goes wrong, or you noticed a mistake made in configuration, you can stop and re-start the assembly as follows.

•	Terminate the assembly by Control-C or by killing the `assemble.sh` process

•	Examine the assembly folder and delete all files that contain incorrect/failed contents (see table above for file designations).

•	Run $/install_path/MaSuRCA-X.X.X/bin/masurca config.txt in the assembly directory.  This will create a new `assemble.sh` script 
accounting for the files that are already present and checking for all dependencies to only run the steps that need to be run

•	Run ./assemble.sh

For example

•	if you noticed that CABOG failed due to lack of disk space, then, after freeing some space, simply run 

$/install_path/MaSuRCA-X.X.X/bin/masurca config.txt and execute  `assemble.sh`

•	if you noticed that you omitted or misspecified one of the jumping library files, add the files to the DATA section of config.txt and run $/install_path/ MaSuRCA-X.X.X/bin/masurca config.txt and execute `assemble.sh`

•	if error correction failed then remove the files named `??.cor.fa` and then run $/install_path/ MaSuRCA-X.X.X/bin/masurca config.txt and execute `assemble.sh`

# Assembly result. 
The final assembly scaffolds file is under CA/{primary,alternative}.scf.fasta or CA.mr...../{primary,alternative}.scf.fasta if CABOG assembler was used for contigging/scaffolding, which is default, or flye.mr....../assembly.scaffolds.fasta if Flye was used for final contigging/scaffolding. 

# 4. Additional tools
## POLCA
POLCA is a polishing tool aimed at improving the consensus accuracy in genome assemblies produced from long high error sequencing data generated by PacBio SMRT or Oxford Nanopore sequencing technologies. POLCA utilizes Illumina or PacBio HIFI reads for the same genome for improving the consensus quality of the assembly.  Its inputs are the genome sequence and a fasta or fastq file (or files) of Illumina or PacBioHIFI reads and its outputs are the polished genome and a VCF file with the variants called from the read data. 

Please cite POLCA as follows: Zimin AV, Salzberg SL. The genome polishing tool POLCA makes fast and accurate corrections in genome assemblies. PLoS computational biology. 2020 Jun 26;16(6):e1007981.

It is very important to use fastq files of polishing reads for proper operation of freebayes.  If you have fasta files, you can convert it to fastq file faux quality scores (use "G" for quality). For example, 
```
>read
ACGT
```
becomes
```
@read
ACGT
+
GGGG
```

POLCA has one external dependency: bwa mem aligner (http://bio-bwa.sourceforge.net/).  It requires that bwa mem aligner is available on the $PATH.

Usage: 
```
polca.sh [options]
-a <assembly fasta file> 
-r <'polishing _reads1.fastq polishing_reads2.fastq'> 
-t <number of cpus> 
-n <optional: do not fix errors, just call variants> 
-m <optional: memory per thread to use in samtools sort>
```
Example:

polca.sh -a genome.fasta -r 'reads1.fastq reads2.fastq.gz' -t 16 -m 1G

POLCA also includes a tool to introduce random errors into an assembly.  This tool is primarily useful for testing the polishing techniques. It is also useful for aligning to genomes that have long exact repeats (such as GRCh38) with Nucmer without use of --maxmatch option. To use the tool, one must perform two steps.  First step is to generate a pseudo-VCF file with random errors by running:

$ introduce_errors_fasta_file.pl sequence.fasta error_probability <optional:maximum_indel_size, default 20> > errors.evcf

where sequence.fasta is the multi-fasta file of the original contigs/scaffolds, error_probability is a floating point number less than 1, equal to the probability of error per base. The last argument is optional, it specifies the maximum insertion/deletion size.  By defaul, the last argument is 20. 90% of the errors introduced are substitutions and 10% are insertions and deletions.  The rate of introduced errors is rougly equal to error_probability*(1+maximum_indel_size/20).  To introduce the errors to the sequence.fasta file, run:

$ fix_consensus_from_vcf.pl sequence.fasta < errors.evcf > sequence_with_errors.fasta

## Chromosome scaffolder
The chromosome scaffolder tools allows to scaffold the assembled contigs using (large) reference scaffolds or chromosome sequences from the same or closely related species. For example, you've assembled a novel human genome and you wish to create a new reference genome with contigs placed on the chromosomes. The chromosome scaffolder will let you do exactly that. It will examine your contigs to see if there are any misassemblies in places where the contigs disagree with the reference using read alignments.  The scaffolder will then break the contigs at all putative misassembled locations,  creating clean contigs (you can disable that optionally). Then it will order and orient the clean contigs onto the chromosomes using the reference alignments. The scaffolder can be invoked as:
```
chromosome_scaffolder.sh [options]
-r <reference genome> MANDATORY
-q <assembly to be scaffolded with the reference> MANDATORY
-t <number of threads>
-i <minimum sequence similarity percentage: default 97>
-m <merge equence alignments slack: default 100000>
-nb do not align reads to query contigs and do not attempt to break at misassemblies: default off
-v <verbose>
-s <reads to align to the assembly to check for misassemblies> MANDATORY unless -nb set
-cl <coverage threshold for splitting at misassemblies: default 3>
-ch <repeat coverage threshold for splitting at misassemblies: default 30>
-M attempt to fill unaligned gaps with reference contigs: defalut off
-h|-u|--help this message
```
This tool is primarily designed for assemblies wigh good contiguity produced from long PacBio or Nanopore reads. The long reads (minimum 20x coverage) can be supplied with -s option. If you do not supply the lobg reads, you must set the -nb option which will skip splitting contigs and scaffold them as is. The -cl and -ch options set the coverage thresholds for splitting at suspect misassemblies, I recommend keeping -cl option at 3 and setting -ch option to about 1.5x the coverage of the long reads supplied with the -s option.

## SAMBA scaffolder
SAMBA is a tool that is designed to scaffold and gap-fill existing genome assemblies with additional long-read data, resulting in substantially greater contiguity.  SAMBA is the only tool of its kind that also computes and fills in the sequence for all spanned gaps in the scaffolds, yielding much longer contigs. 

Please cite SAMBA as follows: Zimin AV, Salzberg SL. The SAMBA tool uses long reads to improve the contiguity of genome assemblies. PLoS computational biology. 2022 Feb 4;18(2):e1009860.

The invocation of SAMBA is as follows:
```
samba.sh [options]
-r <contigs or scaffolds in fasta format> 
-q <long reads or another assembly used to scaffold in fasta or fastq format, can be gzipped> 
-t <number of threads> 
-d <scaffolding data type: ont, pbclr or asm, default:ont> 
-m <minimum matching length, default:5000> 
-o <maximum overhang, default:1000> 
-a <optional: allowed merges file in the format per line: contig1 contig2, only pairs of contigs listed will be considered for merging, useful for intrascaffold gap filling>
-v verbose flag
-h|--help|-u|--usage this message
```
SAMBA installs with MaSuRCA and requires no external dependencies. The only parameter that is worth modifying is -m or the minimum matching length.  2000-2500 is a good value for small eukaryotis genomes 100-400Mb in size, 5000 is the default best value for large eukaryotic genomes (2-3Gbp), and 9000-10000 is the best value for large highly repetitive plant genomes (5Gbp+).  

MaSuRCA also provides a wrapper script for SAMBA that allows to use SAMBA to close intra-scaffold gaps in an assembly. The usage is as follows:
```
close_scaffold_gaps.sh [options]
-r <scaffolds to gapclose> MANDATORY
-q <sequences used for closing gaps,  can be long reads or another assembly, in fasta or fastq format, can ge gzipped> MANDATORY
-t <number of threads, default:1>
-i <identity% default:98>
-m <minimum match length on the two sides of the gap, default:2500>
-o <max overhang, default:1000>
-v verbose flag
-h|--help|-u|--usage this message
```
The above script will split the scaffolds into contigs and then run SAMBA only allowing intrascaffold gaps to be filled.  Contig "flips" inside the scaffold are allowed, making this a great tool to gapfill and fix assemblies scaffolded with HiC data, because HiC scaffolding sometimes incorrectly flips contigs in scaffolds.
