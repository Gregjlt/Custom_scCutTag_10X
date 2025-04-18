#!/bin/bash

## Mapping Research Pipeline
## Copyleft 2017 Institut Curie
## Author(s): Pacome Prompsy
## Contact: pacome.prompsy@curie.fr
## This software is distributed without any guarantee under the terms of the CECILL License
## See the LICENCE file for details


## Input : R1 fastq + R2 fastq
## Outpout : R1 fastq with a barcode flag

SOFT="schip_processing"
VERSION="scCutTag 10X v0.0.1"
ARGUMENTS=$@
COMMAND=${1}


BIN_PATH=`dirname "$0"`
BIN_NAME=`basename "$0"`
ABS_BIN_PATH=`cd "$BIN_PATH"; pwd`
SCRIPTS_PATH="$ABS_BIN_PATH/scripts/"

. /$SCRIPTS_PATH/utils.inc.sh
. /$SCRIPTS_PATH/func.inc.sh
. /$SCRIPTS_PATH/make_metadata.sh


function usage {
    echo -e ""
  echo -e "usage $SOFT
  \n[Sub-Commands]  
	All\t\t Execute the entire pipeline based on CONFIG file
	
	GetConf\t\t [PreRun] Complete a configuration template based on the genome assembly and the design type
	
	--version : print version\n"
    
}

function help_func {
    usage;
   
    local command=${1}
    if [ -z "$command" ]; then echo -e "Use option -h|--help [All|GetConf] for more information"; exit; fi
	  if [[ ! $command =~ "All" && ! $command =~ "GetConf" ]]; then echo -e "Wrong command  ${SOFT}.sh $1 ! \nUse option -h|--help [All|GetConf] for more information";exit; fi
  	echo -e "\n [Options]" 
    	
    if [[ $command =~ "All" ]]
    then
      echo
      echo "$SOFT $VERSION"
      echo "---------------"
      echo "OPTIONS"
      echo 
      echo "${SOFT}.sh All"
      echo
      echo "   -i|--fastqDir FASTQDIR: The input directory containing the splitted fastq files from 10X. R1 and R3 files are genomic DNA. R2 file is the index containing the cell barcode information. If already concatenated, the directory containing the concatenated fastq files."
      echo "   -c|--conf CONFIG: configuration file for ChIP processing"
      echo "   -o|--output OUTPUT: output folder"
      echo "   -n|--name NAME: name given to samples"
      echo "   -s|--downstreamOutput R analysis downstream output: if present, will run downstream analysis in given dir"
      echo "   -u|--override : Override defined arguments (semicolon-separated (;)) from config file (i.e: 'MIN_MAPQ=0;MIN_BAPQ=10') [optional]"
      echo "   [-d|--dryrun]: dry run mode"
      echo "   [-h|--help]: help"
      echo "   [-v|--version]: version"
      echo
    fi
    
    if [[ $command =~ "GetConf" ]]; then 
    echo "OPTIONS"
      echo 
      echo "${SOFT}.sh GetConf"
      echo
  		echo -e "\t-T/--template : Pipeline config template"
  		echo -e "\t-C/--configFile : Config description file"
   		echo -e "\t-D/--designType : Design type"
    	echo -e "\t-G/--genomeAssembly : Genome assembly"
      echo -e "\t-O/--outputConfig : Output config file"
      echo -e "\t-O/--mark : Histone mark : either 'h3k27me3', 'h3k4me3' or 'unbound'. "
      echo -e "\t-B/--targetBed : Target BED file"
      echo
  	fi 
    exit;
}

function version {
    echo -e "$SOFT version $VERSION"
    exit
}

function set_dry_run {
    DRY_RUN=1
}

function opts_error {
    echo -e "Error : invalid parameters !" >&2
    echo -e "Use $SOFT -h for help"
    exit
}

if [ $# -lt 1 ]
then
    help_func
    exit
fi

#Valid commands ?
if [[ $COMMAND =~ "All" ]]
then
COMMAND="Fastq+Barcoding+Trimming+Mapping+Filtering+Coverage+Counting+MQC+R_analysis"
fi

MULT_OP=($(echo ${COMMAND} | sed "s|+| |g"))
declare -A ALL_OP=()
OPS="All Fastq Trimming Barcoding Mapping Filtering Coverage Counting MQC R_analysis GetConf --version --help"
for OP in $OPS ; do ALL_OP+=( [$OP]=1 ) ; done

#Unauthorized subcommand
valid=0
for i in ${MULT_OP[@]} ; do if [[ -n "${ALL_OP[$i]}" ]]; then valid=$(($valid + 1)) ; fi ; done 

if [[ "${valid}" != ${#MULT_OP[@]} ]]; then echo -e "\nYou specified an unauthorized subcommand" ; help_func; exit 1; fi 
	
declare -A TO_RUN=()
for OP in ${MULT_OP[@]} ; do TO_RUN+=( [$OP]=1 ) ; done

if [[ -n "${TO_RUN[--version]}" ]]; then  echo "schip_processing.sh : single cell ChIP-seq pipeline version ${VERSION}" ;  exit 1; fi
	
for arg in "$@"; do
  shift
  case "$arg" in
      "--fastqDir") set -- "$@" "-i" ;;
      "--datasetName") set -- "$@" "-d" ;;
      "--output") set -- "$@" "-o" ;;
      "--conf")   set -- "$@" "-c" ;;
      "--name")   set -- "$@" "-n" ;;
      "--downstreamOutput")   set -- "$@" "-s" ;;
      "--onlyDownstream")   set -- "$@" "-e" ;;
      "--dryrun")   set -- "$@" "-d" ;;
      "--template")   set -- "$@" "-T" ;;
      "--configFile")   set -- "$@" "-C" ;;
      "--designType")   set -- "$@" "-D" ;;
      "--genomeAssembly")   set -- "$@" "-G" ;;
      "--outputConfig")   set -- "$@" "-O" ;;
      "--mark")   set -- "$@" "-M" ;;
      "--targetBed")   set -- "$@" "-B" ;;
      "--override")   set -- "$@" "-u" ;;
      "--help")   set -- "$@" "-h" ;;
      "--version")   set -- "$@" "-v" ;;
      *)        set -- "$@" "$arg"
  esac
done

echo "COMMAND $COMMAND "
if [[ ! $COMMAND =~ "Fastq" && ! $COMMAND =~ "Barcoding" && ! $COMMAND =~ "Trimming"  &&  ! $COMMAND =~ "Mapping"  && ! $COMMAND =~ "Filtering"  && ! $COMMAND =~ "Coverage" && ! $COMMAND =~ "Counting" && ! $COMMAND =~ "MQC" && ! $COMMAND =~ "R_analysis" && ! $COMMAND =~ "GetConf" ]] ; then usage; exit; fi

if [[ $COMMAND =~ "Fastq" || $COMMAND =~ "Barcoding" || $COMMAND =~ "Trimming"  ||   $COMMAND =~ "Mapping"  ||  $COMMAND =~ "Filtering"  ||  $COMMAND =~ "Coverage" ||  $COMMAND =~ "Counting"  ||  $COMMAND =~ "MQC" ||  $COMMAND =~ "R_analysis" ]]
then
  shift
  while getopts "i:d:o:c:s:n:u:dvh" OPT
  do
      case $OPT in
          i) FASTQ_DIR=$OPTARG;;
          d) DATASET_NAME=$OPTARG;;
          o) ODIR=$OPTARG;;
          c) CONF=$OPTARG;;
          s) DOWNSTREAM_ODIR=$OPTARG;;
          n) NAME=$OPTARG;;
          u) OVERRIDE_ARGS=${OPTARG};;
          d) set_dry_run ;;
          v) version ;;
          h) help ;;
          \?)
              echo "Invalid option: -$OPTARG" >&2
              usage
              exit 1
              ;;
          :)
              echo "Option -$OPTARG requires an argument." >&2
              usage
              exit 1
              ;;
      esac
  done
else
  shift
  while getopts "T:C:D:O:G:M:B:" OPT
  do
      case $OPT in
          T) TEMPLATE=$OPTARG;;
          C) CONFIGS=$OPTARG;;
          D) DESIGN_TYPE=$OPTARG;;
          G) GENOME_ASSEMBLY=$OPTARG;;
          O) OUTPUT_CONFIG=$OPTARG;;
          M) MARK=$OPTARG;;
          B) TARGET_BED=$OPTARG;;
          v) version;;
          h) help ;;
          \?)
              echo "Invalid option: -$OPTARG" >&2
              usage
              exit 1
              ;;
          :)
              echo "Option -$OPTARG requires an argument." >&2
              usage
              exit 1
              ;;
      esac
  done
  
  #Run GetConf
  getConf_func ${TEMPLATE} ${CONFIGS} ${DESIGN_TYPE} ${GENOME_ASSEMBLY} ${MARK} ${OUTPUT_CONFIG} ${TARGET_BED}
  
  echo "Config file done ! at ${OUTPUT_CONFIG}"
  #Exit
  exit 
fi

## RUN DATA ENGINEERING 

#####################
## Check Config file
#####################


#If -e is present, skip dataenginnering and process only downstream analysis
echo "$FASTQ_DIR | $CONF | $ODIR | $NAME"
if [[ -z $FASTQ_DIR || -z $CONF || -z $ODIR || -z $NAME ]]; then
      echo "One of the arguments is empty, please fill all obligatory arguments."
      help_func All
      exit
fi

echo
echo -e "Starting on $(date) scCutTag 10X pipeline ! Results are available in ${ODIR}"
echo

PREFIX=$NAME
CMD_LINE="$@"
LOGDIR=${ODIR}/logs
mkdir -p ${LOGDIR}
mkdir -p ${ODIR}


if [ ! -z "$CONF" ]; then
     CONF=`abspath $CONF`
    if [ -e "$CONF" ]; then
        cp $CONF ${ODIR}/
        read_config $CONF
    else
         echo "Error - config file '$CONF' not found"
         exit
    fi
else
    echo "Error - please precise a CONFIG file to use "
    help_func All
    exit
fi


#Override arguments if $OVERRIDE
if [[ "${OVERRIDE_ARGS}" ]] ; then 
  	eval ${OVERRIDE_ARGS}
		echo -e "Override of argument defined in config file: ${OVERRIDE_ARGS}"

	echo -e "\n"
fi

echo "Running pipeline for sample $NAME"

    ## 0 - Create a directory per sample in the kdi and copy the corresponding fastq in it 
    if [[  -n "${TO_RUN[Fastq]}" ]]; then

    mkdir -p ${ODIR}
    cd ${FASTQ_DIR}
    cp -L -R $(ls | grep ${DATASET_NAME}) ${ODIR}
    FASTQ_DIR=${ODIR}/
    cd ${ABS_BIN_PATH}
    
    
    fi

    ## 0bis- Concatenating Input Fastqs from 10X... and reverse complement the Index read
    if [[  -n "${TO_RUN[Fastq]}" ]]; then

      echo -e "Concatenating Input Fastqs from 10X... \n"
      concatenate_fastqs_from_10X ${FASTQ_DIR} ${ODIR}/fastqs ${DATASET_NAME} ${PREFIX} ${LOGDIR}
      # INDEX="${ODIR}/fastqs/${PREFIX}_toreverse.R2.fastq.gz"
      #  echo -e "Reversing the index fastq... \n"
      #   reverse_fastq_func ${ODIR} ${INDEX} ${PREFIX} ${LOGDIR}
    fi

   INDEX="${ODIR}/fastqs/${PREFIX}.R2.fastq.gz"

    ## 1- Align Indexes reads on barcode indexes (whitelist 10X)
    if [[  -n "${TO_RUN[Barcoding]}" ]]; then 
      echo -e "Barcoding... \n"	
      barcode_index_mapping_func ${INDEX} ${ODIR}/mapping/barcode ${PREFIX} ${LOGDIR}/barcode
    fi
    
    BARCODE_READS=${ODIR}/mapping/barcode/${PREFIX}_read_barcodes.txt
    FORWARD="${ODIR}/fastqs/${PREFIX}.R1.fastq.gz"
    REVERSE="${ODIR}/fastqs/${PREFIX}.R3.fastq.gz"

    ## 3- Align R2 reads on genome indexes - paired end with R1 - (STAR)
    MAPPING_INDEX_STAR=${GENOME_IDX_PATH_STAR}
    MAPPING_OPTS_STAR=${GENOME_MAPPING_OPTS_STAR}
    PAIRED_END=(${FORWARD} ${REVERSE})
    if [[  -n "${TO_RUN[Mapping]}" ]]; then

      echo -e "Mapping using $MAPPER... \n"
      star_func "$(echo ${PAIRED_END[@]})" ${ODIR}/mapping/genome ${LOGDIR}/genome ${PREFIX}

      if [[  $STRINGENT_MULTIMAP == "TRUE" ]]; then
        #Bowtie mapping to remove multimappers & filtering 
        MAPPING_IDX_BOWTIE1=${GENOME_IDX_PATH_BOWTIE1}
        bowtie_func ${FORWARD} ${ODIR}/mapping/genome ${LOGDIR}/genome ${PREFIX} ${ODIR}/mapping/genome/Aligned.out.sam
      fi
    fi
    GENOME_BAM=${ODIR}/mapping/genome/${PREFIX}.bam
    
    ## 4- Add cellular Barcode  - (STAR)
    if [[  -n "${TO_RUN[Filtering]}" ]]; then
      echo -e "Filtering... \n"
      add_cellBarcode_func ${GENOME_BAM} ${BARCODE_READS} ${ODIR}/mapping ${LOGDIR}
      GENOME_BAM_FLAGGED=${ODIR}/mapping/${PREFIX}_flagged.bam
      
      ## 5- Remove PCR and Reverse Transcription duplicate  - (STAR)
      remove_PCR_RT_duplicates_func_V2 ${GENOME_BAM_FLAGGED} ${ODIR}/mapping ${LOGDIR}
      GENOME_BAM_FLAGGED_rmPCR_RT=${ODIR}/mapping/${PREFIX}_flagged_rmPCR_RT.bam
      
      ## 6-Remove duplicates by window (if R2 is unmapped) - prime (STAR)
      #remove_duplicates ${GENOME_BAM_FLAGGED_rmPCR_RT} ${ODIR}/mapping/ ${LOGDIR}
      cp ${ODIR}/mapping/${PREFIX}_flagged_rmPCR_RT.count ${ODIR}/mapping/${PREFIX}_flagged_rmPCR_RT_rmDup.count
      GENOME_BAM_FLAGGED_RMDUP=${ODIR}/mapping/${PREFIX}_flagged_rmPCR_RT.bam
      
      ## 6-bis Removing encode black regions
      if [[ ! -z ${BIN_PATH}/${ENCODE_BLACKLIST} && -e ${BIN_PATH}/${ENCODE_BLACKLIST} ]]; then
        filter_black_regions $GENOME_BAM_FLAGGED_RMDUP ${ODIR} ${LOGDIR}
      fi
    fi
    GENOME_BAM_FLAGGED_RMDUP=${ODIR}/mapping/${PREFIX}_flagged_rmPCR_RT.bam
    GENOME_COUNT_FLAGGED_RMDUP=${ODIR}/mapping/${PREFIX}_flagged_rmPCR_RT.count
    
    ## 7-Generate BedGraph file
    if [[  -n "${TO_RUN[Coverage]}" ]]; then
      echo -e "Coverage - BedGraph... \n"
      #bam_to_bedGraph ${GENOME_BAM_FLAGGED_RMDUP} ${GENOME_COUNT_FLAGGED_RMDUP} ${ODIR}/tracks/ ${LOGDIR}
      
      #echo -e "Coverage - scBED... \n"
      #bam_to_sc_bed ${GENOME_BAM_FLAGGED_RMDUP} ${MIN_COUNT_PER_BARCODE_AFTER_RMDUP} ${ODIR}/tracks/ ${LOGDIR}
      
      echo -e "Coverage - BigWigs... \n"
      bw_func ${GENOME_BAM_FLAGGED_RMDUP} ${ODIR}/tracks/ ${LOGDIR}
    fi
    
    if [[  -n "${TO_RUN[Counting]}" ]]; then
      if [[ ! $MARK == "unbound" ]]; then
        echo -e "Counting... \n"
        ## 9- Use the R1 bam with the barcode flag to generate the count table (sc2counts.py)
        time make_counts ${GENOME_BAM_FLAGGED_RMDUP} ${ODIR}/counts/ ${ODIR}/mapping/ ${LOGDIR}
	time bam_to_fragment_file ${GENOME_BAM_FLAGGED_RMDUP} ${ODIR}/counts/
      else
        echo "Is an unbound, skipping generating bigwig & counting, going directly to reporting"
      fi
    fi
   

## 10- Write Metadata
if [[  -n "${TO_RUN[MQC]}" ]]; then
  echo -e "MQC... \n"
  cp multiqc_config.yaml ${ODIR}/multiqc_config.yaml
  add_info_to_log ${ODIR}/mapping/genome ${ODIR}/logs ${ODIR} ${PREFIX} ${BIN_PATH} ${ARGUMENTS} ${BIN_NAME}
  
  #Run MultiQC report for QC 
  /bioinfo/local/build/Centos/python/python-3.6.1/bin/multiqc -f --no-data-dir -i ${PREFIX} -o ${ODIR} -n ${PREFIX}_report.html  -c ${ODIR}/multiqc_config.yaml -f ${ODIR}/scChIPseq_table.csv ${ODIR}/scChIPseq_barcode.csv ${ODIR}/scChIPseq_alignments.csv 
fi  
## 10- Run Downstream analysis with default parameters
export PATH=/bioinfo/local/build/Centos/bedtools/bedtools-2.25.0/bin/:$PATH:/bioinfo/local/build/MACS2_2.0.10/bin/

echo
echo -e "Completed on $(date) ! Results are available in ${ODIR}"
echo

