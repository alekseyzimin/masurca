# MaSuRCA Genome Assembler Quick Start Guide

The MaSuRCA (Maryland Super Read Cabog Assembler) assembler combines the benefits of deBruijn graph and Overlap-Layout-Consensus assembly approaches. Since version 3.2.1 it supports hybrid assembly with short Illumina reads and long high error PacBio/MinION data.

Citation for MaSuRCA: Zimin AV, Marçais G, Puiu D, Roberts M, Salzberg SL, Yorke JA. The MaSuRCA genome assembler. Bioinformatics. 2013 Nov 1;29(21):2669-77.

Citation for MaSuRCA hybrid assembler: Zimin AV, Puiu D, Luo MC, Zhu T, Koren S, Yorke JA, Dvorak J, Salzberg S. Hybrid assembly of the large and highly repetitive genome of Aegilops tauschii, a progenitor of bread wheat, with the mega-reads algorithm. Genome Research. 2017 Jan 1:066100.

# 1. System requirements/run rimes

## Compile/Install requirements. 
To compile the assembler we require gcc version 4.7 or newer to be installed on the system.
Only Linux is supported (May or may not compile under gcc for MacOS or Cygwin, Windows, etc). The assembler has been tested on the following distributions:

•	Fedora 12 and up

•	RedHat 5 and 6 (requires installation of gcc 4.7)

•	CentOS 5 and 6 (requires installation of gcc 4.7)

•	Ubuntu 12 LTS and up

•	SUSE Linux 16 and up

## Hardware requirements. 
The hardware requirements vary with the size of the genome project.  Both Intel and AMD x64 architectures are supported. The general guidelines for hardware configuration are as follows:

•	Bacteria (up to 10Mb): 16Gb RAM, 8+ cores, 10Gb disk space

•	Insect (up to 500Mb): 128Gb RAM, 16+ cores, 1Tb disk space

•	Avian/small plant genomes (up to 1Gb): 256Gb RAM, 32+ cores, 2Tb disk space

•	Mammalian genomes (up to 3Gb): 512Gb RAM, 32+ cores, 5Tb disk space

•	Plant genomes (up to 30Gb): 1Tb RAM, 64+cores, 10Tb+ disk space

## Expected run times. 
The expected run times depend on the cpu speed/number of cores used for the assembly and on the data used. The following lists the expected run times for the minimum configurations outlined above for Illumina-only data sets. Adding long reads (454, Sanger, etc. makes the assembly run about 50-100% longer:

•	Bacteria (up to 10Mb): <1 hour

•	Insect (up to 500Mb): 1-2 days

•	Avian/small plant genomes (up to 1Gb): 4-5 days

•	Mammalian genomes (up to 3Gb): 15-20 days

•	Plant genomes (up to 30Gb): 60-90 days

# 2. Installation instructions

To install, first download the latest distribution from ftp://ftp.genome.umd.edu/pub/MaSuRCA/ or from the github release page. Then untar/unzip the package MaSuRCA-X.X.X.tgz, cd to the resulting folder and run `./install.sh`.  The installation script will configure and make all necessary packages.

In the rest of this document, `/install_path` refers to a path to the directory in which `./install.sh` was run.

You can instead clone the development tree:

```
git clone https://github.com/alekseyzimin/masurca
git submodule init
git submodule update
make
```

When compiling the development tree (as opposed to compiling the distribution), there are dependencies on swig and yaggo (http://www.swig.org/ and https://github.com/gmarcais/yaggo).  Both must be available on the path.

# 3. Running the assembler

## Overview. 
The general steps to run the MaSuRCA assemblers are as follows, and will be covered in details in later sections. It is advised to create a new directory for each assembly project.

IMPORTANT! Do not use third party tools to pre-process the Illumina data before providing it to MaSuRCA, unless you are absolutely sure you know exactly what the preprocessing tool does.  Do not do any trimming, cleaning or error correction. This will likely deteriorate the assembly.

First, create a configuration file which contains the location of the compiled assembler, the location of the data and some parameters. Copy in your assembly directory the template configuration file `/install_path/sr_config_example.txt` which was created by the installer with the correct paths to the freshly compiled software and with reasonable parameters. Many assembly projects should only need to set the path to the input data.

Second, run the `masurca` script which will generate from the configuration file a shell script `assemble.sh`. This last script is the main driver of the assembly.

Finally, run the script `assemble.sh` to assemble the data.

## Configuration. 
To run the assembler, one must first create a configuration file that specifies the location of the executables, data and assembly parameters for the assembler. The installation script will create a sample config file `sr_config_example.txt`. Lines starting with a pound sign ('#') are comments and ignored. All options are explained in the sample configuration file that looks like this:

example configuration file 
```
\# DATA is specified as type {PE,JUMP,OTHER,PACBIO} and 5 fields:

\# 1)two_letter_prefix 2)mean 3)stdev 4)fastq(.gz)_fwd_reads

\# 5)fastq(.gz)_rev_reads. The PE reads are always assumed to be

\# innies, i.e. --->.<---, and JUMP are assumed to be outties

\# <---.--->. If there are any jump libraries that are innies, such as

\# longjump, specify them as JUMP and specify NEGATIVE mean. Reverse reads

\# are optional for PE libraries and mandatory for JUMP libraries. Any

\# OTHER sequence data (454, Sanger, Ion torrent, etc) must be first

\# converted into Celera Assembler compatible .frg files (see

\# http://wgs-assembler.sourceforge.com)

DATA

PE= pe 180 20  /FULL_PATH/frag_1.fastq  /FULL_PATH/frag_2.fastq

JUMP= sh 3600 200  /FULL_PATH/short_1.fastq  /FULL_PATH/short_2.fastq

\#pacbio reads must be in a single fasta file! make sure you provide absolute path

PACBIO=/FULL_PATH/pacbio.fa

OTHER=/FULL_PATH/file.frg

END

PARAMETERS

\#set this to 1 if your Illumina jumping library reads are shorter than 100bp

EXTEND_JUMP_READS=0

\#this is k-mer size for deBruijn graph values between 25 and 127 are supported, auto will compute the optimal size based on the read data and GC content

GRAPH_KMER_SIZE = auto

\#set this to 1 for all Illumina-only assemblies

\#set this to 1 if you have less than 20x long reads (454, Sanger, Pacbio) and less than 50x CLONE coverage by Illumina, Sanger or 454 mate pairs

\#otherwise keep at 0

USE_LINKING_MATES = 0

\#specifies whether to run mega-reads correction on the grid

USE_GRID=0

\#specifies queue to use when running on the grid MANDATORY

GRID_QUEUE=all.q

\#batch size in the amount of long read sequence for each batch on the grid

GRID_BATCH_SIZE=300000000

\#coverage by the longest Long reads to use

LHE_COVERAGE=30

\#this parameter is useful if you have too many Illumina jumping library mates. Typically set it to 60 for bacteria and 300 for the other organisms 

LIMIT_JUMP_COVERAGE = 300

\#these are the additional parameters to Celera Assembler.  do not worry about performance, number or processors or batch sizes -- these are computed automatically. 

\#set cgwErrorRate=0.25 for bacteria and 0.1<=cgwErrorRate<=0.15 for other organisms.

CA_PARAMETERS =  cgwErrorRate=0.15 

\#minimum count k-mers used in error correction 1 means all k-mers are used.  one can increase to 2 if Illumina coverage >100

KMER_COUNT_THRESHOLD = 1

\#whether to attempt to close gaps in scaffolds with Illumina data

CLOSE_GAPS=1

\#auto-detected number of cpus to use

NUM_THREADS = 16

\#this is mandatory jellyfish hash size -- a safe value is estimated_genome_size*estimated_coverage

JF_SIZE = 200000000

\#set this to 1 to use SOAPdenovo contigging/scaffolding module.  Assembly will be worse but will run faster. Useful for very large (>5Gbp) genomes from Illumina-only data

SOAP_ASSEMBLY=0

END
```

The config file consists of two sections: DATA and PARAMETERS. Each section concludes with END statement. User should copy the sample config file to the directory of choice for running the assembly and then modify it according to the specifications of the assembly project. Here are brief descriptions of the sections.

DATA – in this section the user must specify the types of data available for the assembly. Each line represent a library and must start with PE=, JUMP= or OTHER= for the 3 different type of input read library (Paired Ends, Jumping or other). There can be multiple lines starting with `PE=` (or JUMP=), one line per library. PE and JUMP data must be in fastq format while the other data is in provided as a Celera Assembler frag format (`.frg`). Every PE or JUMP library is named by a unique two letter prefix. No two library can have the same prefix and a prefix should be made of two printable characters or number (no space or control characters), e.g. `aa`, `ZZ`, `l5`, or `J2`.

 The following types of data are supported:
 
•	Illumina paired end (or single end) reads -- MANDATORY:

`PE = two_letter_prefix mean stdev /PATH/fwd_reads.fastq /PATH/rev_reads.fastq`

example:

`PE = aa 180 20 /data/fwd_reads.fastq /data/rev_reads.fastq`

The `mean` and `stdev` parameters are the library insert average length and standard deviation. If the standard deviation is not known, set it to approximately 15% of the mean.If the second (reverse) read set is not available, do not specify it and just specify the forward reads.

•	Illumina jumping/DiTag/other circularization protocol-based library mate pair reads:

`JUMP = two_letter_prefix mean stdev /PATH/fwd_reads.fastq /PATH/rev_reads.fastq`

example:

`JUMP = cc 3500 500 /data/jump_fwd_reads.fastq /data/jump_rev_reads.fastq`

By default, the assembler assumes that the jumping library pairs are “outties” (<--   -->). Some protocols (DiTag) use double-circularization which results in “innie” pairs (-->   <--).  In this case please specify negative mean.

•	Other types of data (454, Sanger, etc) must be converted to CABOG format FRG files (see CABOG documentation at http://sourceforge.net/apps/mediawiki/wgs-assembler/index.php?title=Main_Page ):

`OTHER = data.frg`

•	PacBio/MinION data are supported.  Note that you have to have 50x + coverage in Illumina Paired End reads to use PacBio of Oxford Nanopore MinION data.  Supply PacBio or MinION reads (cannot use both at the same time) in a single fasta file as:

`PACBIO=file.fa` or `NANOPORE=file.fa`

More than one entry for each data type/set of files is allowed EXCEPT for PacBio/Nanopore data.  That is if you have several pairs of PE fastq files, specify each pair on a separate line with a different two-letter prefix.

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

`CA_PARAMETERS = cgwErrorRate=0.25`

these are the additional parameters to Celera Assembler, and they should only be supplied/modified by advanced users.  “ovlMerSize=30 cgwErrorRate=0.25 ovlMemory=4GB” should be used for bacterial assemblies; “ovlMerSize=30 cgwErrorRate=0.15 ovlMemory=4GB” should be used for all other genomes

`SOAP_ASSEMBLY = 0`

Set this to 1 if you would like to perform contigging and scaffolding done by SOAPdenovo2 instead of CABOG.  This will decrease assembly runtime, but will likely result in inferior assembly.  This option is useful when assembling very large genomes (5Gbp+), as CABOG may take months to rung on these.

# Running mega-reads on the grid. 
Starting with version 3.2.4 MaSuRCA supports execution of the mega-reads correction of the long high error reads such as PacBio or Nanopore reads on SGE grid.  SLURM support is coming in the next release.  To run on the grid, you must set USE_GRID=1 and specify the SGE queue to use (MANDATORY) using GRID_QUEUE=<name>.  Please create a special queue on the SGE grid for this operation.  The queue MUST have ONLY 1 SLOT PER PHYSICAL COMPUTER. Each batch will use NUM_THREADS threads on each computer, thus the number of slots in the SGE queue should be set to 1 for each physical computer.

Long reads are corrected in batches. GRID_BATCH_SIZE is the batch size in bases of long reads.  You can figure out the number of batches by dividing the total amount of long read data by the GRID_BATCH_SIZE. Memory usage for each batch does not depend on this parameter, it scales with genome size instead. Since there is some overhead to starting each batch, I recommend setting this to have not more than 100 batches. The setting that is equal to 2-3 times the number of physical computers you have in the grid works best.  The total number of batches is limited to 1000.
The Celera Assembler (or CABOG) will use the grid as well to run overlapper only.  Overlapper jobs are not memory-intensive and thus multiple jobs can be submitted to each node.  Each job will use up to 4 threads – the code is not efficient enough to use more than that number of threads effectively.  

The masurca and the assemble.sh script. Once you’ve created a configuration file, use the `masurca` script from the MaSuRCA bin directory to generate the `assemble.sh` shell script that executes the assembly:

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
The final assembly scaffolds file is under CA/ or CA.mr...../ and named final.genome.scf.fasta. 
