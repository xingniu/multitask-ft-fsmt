#!/bin/bash

root_dir=`dirname $0`/..
gpus=0
lang_1=formal
lang_2=informal
iterations=1
while getopts ":g:k:m:ef" opt; do
	case $opt in
	g)
		gpus=$OPTARG ;;
	k)
		data_selection=$OPTARG ;;
	m)
		multitask=$OPTARG
		iterations=2 ;;
	e)
		ensemble=True ;;
	f)
		fine_tuning=True ;;
	h)
		echo "Usage: main.sh"
		echo "-g GPU ids (e.g. 1,2,4)"
		echo "-k data selection factor (k*n)"
		echo "-m multitask (tag-style/style/random)"
		echo "-e ensemble decoding"
		echo "-f fine-tuning"
		exit 0 ;;
    \?)
		echo "Invalid option: -$OPTARG" >&2
		exit 1 ;;
    :)
		echo "Option -$OPTARG requires an argument." >&2
		exit 1 ;;
	esac
done

## software bits
moses_scripts_path=$root_dir/moses-scripts
bpe_scripts_path=$root_dir/subword-nmt/subword_nmt
kenlm_path=$root_dir/kenlm/build/bin

## pipeline parameters
src_max_len=51
tgt_max_len=50
bpe_num_operations=32000
lang_base=en

## experiment naming variables
base_dir=$root_dir/experiments
mkdir -p $base_dir

## experiment files
data_dir=$root_dir/data
train=$data_dir/GYAFC.train.tok
dev_1=$data_dir/GYAFC.dev-to-$lang_1.tok
dev_2=$data_dir/GYAFC.dev-to-$lang_2.tok

bilingual_data=$data_dir/OpenSubtitles2016/OpenSubtitles2016.en-fr.train-20M.tok
bilingual_lang_src=fr

. $root_dir/scripts/pipeline-bidirectional.sh
