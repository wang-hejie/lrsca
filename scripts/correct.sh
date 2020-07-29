#!/bin/bash

#########################################
#  $1: species - ecoli, scere
#  $2: folds - 10, 30, 50, 75, 100
#  $3: tools - raw, mecat2, falcon, lorma, canu, pbcr, flas, consent
#  $4: company - pacbio, ont
#  (all varaibles are converted to the lower cases)
#########################################
species="$(echo $1 | tr '[:upper:]' '[:lower:]')"
folds="$(echo $2 | tr '[:upper:]' '[:lower:]')"
tools="$(echo $3 | tr '[:upper:]' '[:lower:]')"
company="$(echo $4 | tr '[:upper:]' '[:lower:]')"
echo "------------------"$tools"-------------------"


#########################################
# set paths
#########################################
home="/home/wanghejie"
standard_raw_fa_name="raw_longreads_"$folds"x.fasta"
standard_raw_fq_name="raw_longreads_"$folds"x.fastq"
raw_file_fa="/HDD1/wanghejie/datasets/Reads/$species/$standard_raw_fa_name"  # 原始long reads的fasta
raw_file_fq="/HDD1/wanghejie/datasets/Reads/$species/$standard_raw_fq_name"  # 原始long reads的fastq
if [ $tools == "raw" ]
    then
        experience_dir="$home/experience/"$species"_"$folds"/$tools/raw_data"
else
    experience_dir="$home/experience/"$species"_"$folds"/$tools/correct"  # 执行纠错及保存纠错后reads文件的目录
fi
standard_corrected_file_name="corrected_longreads.fasta"  # 纠错后reads文件的存储名

#scripts path
scripts_path="$(cd `dirname $0`; pwd)"


#########################################
# create experience directory
#########################################
if [ -d $experience_dir ]
    then
        echo -e "\e[1;35m #### Warning: $experience_dir Exist! #### \e[0m"  # Warning
        rm -rf $experience_dir
        echo -e "\e[1;35m #### Warning end: Already remove it. #### \e[0m"
fi
mkdir -p $experience_dir
cd $experience_dir


#########################################
# Set tool installed path
#########################################
# 1. mecat2
# 直接调用mecat.pl即可

# 2. falcon
if [ $tools == "falcon" ]
    then
        source activate
        source deactivate
        conda activate falcon
fi

# 3. lorma
if [ $tools == "lorma" ]
    then
        source activate
        source deactivate
        conda activate lorma
fi

# 4. canu
if [ $tools == "canu" ]
    then
        source activate
        source deactivate
        conda activate canu
fi

# 5. pbcr
# 直接调用PBcR即可

# 6. flas
flas_path="/home/wanghejie/biotools/FLAS"

# 7. consent
# 直接调用CONSENT-correct即可


#########################################
# set genome size
#########################################
if [ $species == "ecoli" ]
    then
        genome_size=4800000
    else
        genome_size=12000000
fi


#########################################
# Running the tools 
#########################################
####1. raw####
if [ $tools == "raw" ]
    then
        echo -e "\e[1;32m #### Skip the error correction and go straight to assembly. #### \e[0m"
        echo "#### Start: ln -s "$raw_file_fa" "$experience_dir/$standard_raw_fa_name" ####"
        ln -s "$raw_file_fa" "$experience_dir/$standard_raw_fa_name"
        echo -e "#### End: ln -s "$raw_file_fa" "$experience_dir/$standard_raw_fa_name" ####\n"
        echo -e "\n"



####2. mecat2####
elif [ $tools == "mecat2" ]
    then
        config_file=""$experience_dir"/"$species"_config_file.txt"

        # 设置配置文件
        echo -e "\e[1;32m #### "$tools" correct step 1/4: config #### \e[0m"
        echo "#### Start: mecat.pl config $config_file ####"
        echo "PROJECT="$species"_"$folds"" > $config_file
        echo "RAWREADS=$raw_file_fa" >> $config_file
        echo "GENOME_SIZE=$genome_size" >> $config_file
        echo "THREADS=16" >> $config_file
        echo "MIN_READ_LENGTH=2000" >> $config_file
        echo "CNS_OVLP_OPTIONS=\"-kmer_size 13\"" >> $config_file
        echo "CNS_PCAN_OPTIONS=\"-p 100000 -k 100\"" >> $config_file
        echo "CNS_OPTIONS=\"\"" >> $config_file
        echo "CNS_OUTPUT_COVERAGE=30" >> $config_file
        echo "TRIM_OVLP_OPTIONS=\"-skip_overhang\"" >> $config_file
        echo "TRIM_PM4_OPTIONS=\"-p 100000 -k 100\"" >> $config_file
        echo "TRIM_LCR_OPTIONS=\"\"" >> $config_file
        echo "TRIM_SR_OPTIONS=\"\"" >> $config_file
        echo "ASM_OVLP_OPTIONS=\"\"" >> $config_file
        echo "FSA_OL_FILTER_OPTIONS=\"--max_overhang=-1 --min_identity=-1\"" >> $config_file
        echo "FSA_ASSEMBLE_OPTIONS=\"\"" >> $config_file
        echo "CLEANUP=0" >> $config_file
        echo -e "#### End: mecat.pl config $config_file ####\n"
        echo -e "\n"

        # 执行correct步骤
        echo -e "\e[1;32m #### "$tools" correct step 2/4: correct #### \e[0m"
        echo "#### Start: mecat.pl correct $config_file ####"
        perl $scripts_path/memory3.pl memoryrecord_1 "mecat.pl correct $config_file"
        echo -e "#### End: mecat.pl correct $config_file ####\n"

        # 执行trim步骤
        echo -e "\e[1;32m #### "$tools" correct step 3/4: trim #### \e[0m"
        echo "#### Start: mecat.pl trim $config_file ####"
        perl $scripts_path/memory3.pl memoryrecord_2 "mecat.pl trim $config_file"
        echo -e "#### End: mecat.pl trim $config_file ####\n"

        # 标准化校正数据文件名
        # 所有工具的校正后长读，均在其实验目录的/correct目录下，名称为corrected_longreads.fasta
        echo -e "\e[1;32m #### "$tools" correct step 4/4: standard corrected reads file name #### \e[0m"
        unstandard_file_path=""$experience_dir"/"$species"_"$folds"/2-trim_bases"
        unstandard_corrected_file_name="trimReads.fasta"
        standard_file_path="$experience_dir"
        echo "#### Start: cp "$unstandard_file_path"/"$unstandard_corrected_file_name" "$standard_file_path" ####"
        cp "$unstandard_file_path"/"$unstandard_corrected_file_name" "$standard_file_path"
        echo -e "#### End: cp "$unstandard_file_path"/"$unstandard_corrected_file_name" "$standard_file_path" ####\n"
        echo "#### Start: mv "$standard_file_path"/"$unstandard_corrected_file_name" "$standard_file_path"/"$standard_corrected_file_name" ####"
        mv "$standard_file_path"/"$unstandard_corrected_file_name" "$standard_file_path"/"$standard_corrected_file_name"
        echo -e "#### End: mv "$standard_file_path"/"$unstandard_corrected_file_name" "$standard_file_path"/"$standard_corrected_file_name" ####\n"



####3. falcon####
elif [ $tools == "falcon" ]
    then
        cfg_file=""$experience_dir"/fc_run_"$species""$folds".cfg"
        fofn_file=""$experience_dir"/input.fofn"

        # 设置配置文件
        echo -e "\e[1;32m #### "$tools" correct step 1/3: config #### \e[0m"
        echo "#### Start: init "$cfg_file" ####"
        echo "#### Input" > $cfg_file
        echo "[General]" >> $cfg_file
        echo "input_fofn=input.fofn" >> $cfg_file
        echo "input_type=raw" >> $cfg_file
        echo "pa_DBdust_option=" >> $cfg_file
        echo "pa_fasta_filter_option=pass" >> $cfg_file
        echo "target=pre-assembly" >> $cfg_file
        echo "skip_checks=False" >> $cfg_file
        echo "LA4Falcon_preload=false" >> $cfg_file
        echo "" >> $cfg_file
        echo "#### Data Partitioning" >> $cfg_file
        echo "pa_DBsplit_option=-x500 -s200" >> $cfg_file
        echo "ovlp_DBsplit_option=-x500 -s200" >> $cfg_file
        echo "" >> $cfg_file
        echo "#### Repeat Masking" >> $cfg_file
        echo "pa_HPCTANmask_option=" >> $cfg_file
        echo "pa_REPmask_code=0,300;0,300;0,300" >> $cfg_file
        echo "" >> $cfg_file
        echo "####Pre-assembly" >> $cfg_file
        echo "genome_size=$genome_size" >> $cfg_file
        echo "seed_coverage=-1" >> $cfg_file  # 注意此变量，不设置
        echo "length_cutoff=500" >> $cfg_file  # 注意此变量，不设置seed_coverage只设置length_cutoff可以防止bug
        echo "pa_HPCdaligner_option=-v -B128 -M24" >> $cfg_file
        echo "pa_daligner_option=-e.8 -l2000 -k18 -h480  -w8 -s100" >> $cfg_file
        echo "falcon_sense_option=--output-multi --min-idt 0.70 --min-cov 2 --max-n-read 1800" >> $cfg_file
        echo "falcon_sense_greedy=False" >> $cfg_file
        echo "" >> $cfg_file
        echo "####Pread overlapping" >> $cfg_file
        echo "ovlp_daligner_option=-e.9 -l2500 -k24 -h1024 -w6 -s100" >> $cfg_file
        echo "ovlp_HPCdaligner_option=-v -B128 -M24" >> $cfg_file
        echo "" >> $cfg_file
        echo "####Final Assembly" >> $cfg_file
        echo "overlap_filtering_setting=--max-diff 100 --max-cov 100 --min-cov 2" >> $cfg_file
        echo "fc_ovlp_to_graph_option=" >> $cfg_file
        echo "length_cutoff_pr=1000" >> $cfg_file
        echo "" >> $cfg_file
        echo "[job.defaults]" >> $cfg_file
        echo "job_type=local" >> $cfg_file
        echo "pwatcher_type=blocking" >> $cfg_file
        echo "MB=262144" >> $cfg_file
        echo "NPROC=16" >> $cfg_file
        echo "njobs=240" >> $cfg_file
        echo "submit=/bin/bash -c \"\${CMD}\" > \"\${STDOUT_FILE}\" 2> \"\${STDERR_FILE}\"" >> $cfg_file
        echo -e "#### End: init "$cfg_file" ####\n"

        echo "#### Start: init "$fofn_file" ####"
        echo $raw_file_fa > $fofn_file
        echo -e "#### End: init "$fofn_file" ####\n"

        # 运行falcon纠错
        echo -e "\e[1;32m #### "$tools" correct step 2/3: correct #### \e[0m"
        echo "#### Start: fc_run "$cfg_file" ####"
        perl $scripts_path/memory3.pl memoryrecord "fc_run $cfg_file"
        echo -e "#### End: fc_run "$cfg_file" ####\n"

        # 将所有consensus片段文件合成1个
        echo -e "\e[1;32m #### "$tools" correct step 3/3: standard corrected reads file name #### \e[0m"
        cns_root="$experience_dir"/0-rawreads/cns-runs
        cd $cns_root
        cns_pieces_path=""
        for i in $(ls)
            do
                cd "$cns_root"/"$i"/uow-00
                cns_pieces_path=""$cns_root"/"$i"/uow-00/$(ls *.fasta) "$cns_pieces_path
            done
        echo "#### Start: cat $cns_pieces_path> $experience_dir/$standard_corrected_file_name ####"
        cat $cns_pieces_path> $experience_dir/$standard_corrected_file_name
        echo -e "#### End: cat $cns_pieces_path> $experience_dir/$standard_corrected_file_name ####\n"



####4. lorma####
elif [ $tools == "lorma" ]
    then
        # 运行lorma纠错
        echo -e "\e[1;32m #### "$tools" correct step 1/2: correct #### \e[0m"
        echo "#### Start: lorma.sh -threads 16 $raw_file_fa ####"
        perl $scripts_path/memory3.pl memoryrecord "lorma.sh -threads 16 $raw_file_fa"
        echo -e "#### End: lorma.sh -threads 16 $raw_file_fa ####\n"

        # 标准化校正数据文件名
        # 所有工具的校正后长读，均在其实验目录的/correct目录下，名称为corrected_longreads.fasta
        echo -e "\e[1;32m #### "$tools" correct step 2/2: standard corrected reads file name #### \e[0m"
        echo "#### Start: mv final.fasta $standard_corrected_file_name ####"
        mv final.fasta $standard_corrected_file_name
        echo -e "#### End: mv final.fasta $standard_corrected_file_name ####\n"



####5. canu####
elif [ $tools == "canu" ]
    then
        # 运行canu纠错
        echo -e "\e[1;32m #### "$tools" correct step 1/2: correct #### \e[0m"
        echo "#### Start: canu -correct -p $species -d correct genomeSize=$genome_size useGrid=false -$company-raw $raw_file_fa ####"
        perl $scripts_path/memory3.pl memoryrecord "canu -correct -p $species -d correct genomeSize=$genome_size useGrid=false minInputCoverage=5 stopOnLowCoverage=5 -$company-raw $raw_file_fa"
        echo -e "#### End: canu -correct -p $species -d correct genomeSize=$genome_size useGrid=false -$company-raw $raw_file_fa ####\n"

        # 标准化校正数据文件名
        # 所有工具的校正后长读，均在其实验目录的/correct目录下，名称为corrected_longreads.fasta
        echo -e "\e[1;32m #### "$tools" correct step 2/2: standard corrected reads file name #### \e[0m"
        echo "#### Start: gunzip $experience_dir/correct/$species.correctedReads.fasta.gz ####"
        gunzip $experience_dir/correct/$species.correctedReads.fasta.gz
        echo -e "#### End: gunzip $experience_dir/correct/$species.correctedReads.fasta.gz ####\n"
        echo "#### Start: mv $experience_dir/correct/$species.correctedReads.fasta $experience_dir/$standard_corrected_file_name ####"
        mv $experience_dir/correct/$species.correctedReads.fasta $experience_dir/$standard_corrected_file_name
        echo -e "#### End: mv $experience_dir/correct/$species.correctedReads.fasta $experience_dir/$standard_corrected_file_name ####\n"



####6. pbcr####
elif [ $tools == "pbcr" ]
    then
        config_file=""$experience_dir"/"$company".spec"
        
        # 设置配置文件
        echo -e "\e[1;32m #### "$tools" correct step 1/3: config #### \e[0m"
        echo "#### Start: init "$config_file" ####"
        echo "# limit to 32GB. By default the pipeline will auto-detect memory and try to use maximum. This allow limiting it" > $config_file
        echo "merSize = 14" >> $config_file
        echo "assemble = 0" >> $config_file
        echo "ovlMemory = 250" >> $config_file
        echo "ovlStoreMemory = 32000" >> $config_file
        echo "blasr = -bestn 10 -nCandidates 10" >> $config_file
        echo "ovlThreads = 16" >> $config_file
        echo -e "#### End: init "$config_file" ####\n"

        # 执行PBcR纠错
        echo -e "\e[1;32m #### "$tools" correct step 2/3: correct #### \e[0m"
        echo "#### Start: PBcR -length 500 -partitions 200 -genomeSize $genome_size -libraryname $species$folds -s $config_file -fastq $raw_file_fq > run.log 2>&1 ####"
        perl $scripts_path/memory3.pl memoryrecord "PBcR -length 500 -partitions 200 -genomeSize $genome_size -libraryname $species$folds -s $config_file -fastq $raw_file_fq > run.log 2>&1"
        echo -e "#### End: PBcR -length 500 -partitions 200 -genomeSize $genome_size -libraryname $species$folds -s $config_file -fastq $raw_file_fq > run.log 2>&1 ####\n"

        # 标准化校正数据文件名
        # 所有工具的校正后长读，均在其实验目录的/correct目录下，名称为corrected_longreads.fasta
        echo -e "\e[1;32m #### "$tools" correct step 3/3: standard corrected reads file name #### \e[0m"
        echo "#### Start: mv $species$folds.fasta $standard_corrected_file_name ####"
        mv $species$folds.fasta $standard_corrected_file_name
        echo -e "#### End: $species$folds.fasta $standard_corrected_file_name ####\n"



####7. flas####
elif [ $tools == "flas" ]
    then
        # 执行flas纠错
        echo -e "\e[1;32m #### "$tools" correct step 1/2: correct #### \e[0m"
        echo "#### Start: python $flas_path/runFLAS.py $raw_file_fq -c $folds ####"
        perl $scripts_path/memory3.pl memoryrecord "python $flas_path/runFLAS.py $raw_file_fa -c $folds"
        echo -e "#### End: python $flas_path/runFLAS.py $raw_file_fq -c $folds ####\n"

        # 标准化校正数据文件名
        # 所有工具的校正后长读，均在其实验目录的/correct目录下，名称为corrected_longreads.fasta
        echo -e "\e[1;32m #### "$tools" correct step 2/2: standard corrected reads file name #### \e[0m"
        echo "#### Start: mv $experience_dir/output/split_reads.fasta $experience_dir/$standard_corrected_file_name ####"
        mv $experience_dir/output/split_reads.fasta $experience_dir/$standard_corrected_file_name
        echo -e "#### End: mv $experience_dir/output/split_reads.fasta $experience_dir/$standard_corrected_file_name ####\n"



####8. consent####
elif [ $tools == "consent" ]
    then
        if [ $company == "pacbio" ]
            then
                type="PB"
            else
                type="ONT"
        fi

        # 执行consent纠错
        # CONSENT可以设置输出文件名，因此可省略标准化文件名步骤
        echo -e "\e[1;32m #### "$tools" correct step 1/1: correct #### \e[0m"
        echo "#### Start: CONSENT-correct --in $raw_file_fa --out $standard_corrected_file_name --type $type ####"
        perl $scripts_path/memory3.pl memoryrecord "CONSENT-correct --in $raw_file_fa --out $standard_corrected_file_name --type $type"
        echo -e "#### End: CONSENT-correct --in $raw_file_fa --out $standard_corrected_file_name --type $type ####\n"



else
    echo -e "\e[1;31m #### Error: $tools NOT EXIST! #### \e[0m"  # Error
fi