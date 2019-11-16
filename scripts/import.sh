#!/bin/bash

root_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"

## software bits
moses_scripts_path=$root_dir/software/moses-scripts
bpe_scripts_path=$root_dir/software/subword-nmt/subword_nmt
kenlm_path=$root_dir/software/kenlm/build/bin
sacrebleu_path=$root_dir/software/sockeye/sockeye_contrib/sacrebleu
meteor_jar=$root_dir/software/meteor-1.5/meteor-1.5.jar
statistics_tool=$root_dir/software/nlp-util/vertical-statistics.py

## datasets
data_dir=$root_dir/data
GYAFC_data_dir=$data_dir/GYAFC_Corpus/Combo
OpenSubtitles2016_data_dir=$data_dir/OpenSubtitles2016
Europarl_data_dir=$data_dir/Europarl-v7
NewsCommentary_data_dir=$data_dir/NewsCommentary-v14
MSLT_data_dir=$data_dir/MSLT
WMT_data_dir=$data_dir/WMT14

## pipeline parameters
src_max_len_base=50
tgt_max_len_base=50
lang_base=en # formality transfer language
avg_metric_list="perplexity bleu"
fine_tuning_metric=perplexity