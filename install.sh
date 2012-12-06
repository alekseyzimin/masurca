#!/bin/sh

export ROOT=`pwd`
export JF_VERSION1="jellyfish-1.1.7beta"
export JF_VERSION2="jellyfish-1.9.0beta"
export SR_VERSION=`ls -d SuperReads*`
export QR_VERSION=`ls -d quorum*`
export NUM_THREADS=`cat /proc/cpuinfo |grep processor|wc -l`;
export PKG_CONFIG_PATH=${ROOT}/lib/pkgconfig:$PKG_CONFIG_PATH;

(cd CA/kmer;./configure.sh;make;make install)
(cd CA/src;make)
(cd $JF_VERSION1;./configure --prefix=$ROOT; make -j $NUM_THREADS  install;)
(cd $JF_VERSION2;./configure --prefix=$ROOT; make -j $NUM_THREADS  install;)
(cd $SR_VERSION;./configure --prefix=$ROOT; make -j $NUM_THREADS  install;)
(cd $QR_VERSION;./configure --prefix=$ROOT; make -j $NUM_THREADS  install;)

echo "creating sr_config_example.txt with correct PATHS"
cat > sr_config_example.txt <<EOF
#example configuration file for rhodobacter sphaeroides assembly from GAGE project (http://gage.cbcb.umd.edu)
#paths to installed components
PATHS
JELLYFISH_PATH=${ROOT}/bin
SR_PATH=${ROOT}/bin
CA_PATH=${ROOT}/CA/Linux-amd64/bin
END

#DATA is specified as type {PE,JUMP,OTHER}= two_letter_prefix mean stdev fastq(.gz)_fwd_reads fastq(.gz)_rev_reads
#NOTE that PE reads are always assumed to be  innies, i.e. --->  <---, and JUMP are assumed to be outties <---    --->; if there are any jump libraries that are innies, such as longjump, specify them as JUMP and specify NEGATIVE mean
#rev reads are optional for PE libraries and mandatory for JUMP libraries
#any OTHER sequence data (454, Sanger, Ion torrent, etc) must be first converted into Celera Assembler compatible .frg files (see http://wgs-assembler.sourceforge.com)
DATA
PE= pe 180 20  /FULL_PATH/frag_1.fastq  /FULL_PATH/frag_2.fastq
JUMP= sh 3600 200  /FULL_PATH/short_1.fastq  /FULL_PATH/short_2.fastq
OTHER=/FULL_PATH/file.frg
END

PARAMETERS
#this is k-mer size for deBruijn graph values between 25 and 101 are supported, auto will compute the optimal size based on the read data and GC content
GRAPH_KMER_SIZE=auto
#set this to 1 for Illumina-only assemblies and to 0 if you have 2x or more long (Sanger, 454) reads
USE_LINKING_MATES=1
#this parameter is useful if you have too many jumping library mates. Typically set it to 60 for bacteria and something large (300) for mammals
LIMIT_JUMP_COVERAGE = 60
#these are the additional parameters to Celera Assembler.  do not worry about performance, number or processors or batch sizes -- these are computed automatically. for mammals do not set cgwErrorRate above 0.15!!!
CA_PARAMETERS = ovlMerSize=30 cgwErrorRate=0.25 ovlMemory=4GB
#minimum count k-mers used in error correction 1 means all k-mers are used.  one can increase to 2 if coverage >100
KMER_COUNT_THRESHOLD = 1
#auto-detected number of cpus to use
NUM_THREADS= $NUM_THREADS
#this is mandatory jellyfish hash size
JF_SIZE=100000000
#this specifies if we do (1) or do not (0) want to trim long runs of homopolymers (e.g. GGGGGGGG) from 3' read ends, use it for high GC genomes
DO_HOMOPOLYMER_TRIM=0
END
EOF
