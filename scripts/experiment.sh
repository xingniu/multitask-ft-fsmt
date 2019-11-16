#!/bin/bash

date;

## experiment naming variables
exp_dir=$base_dir/$exp_name-$style_model-$train_data
mkdir -p $exp_dir

echo "Experiment: `basename $exp_dir`"

if [[ $style_model == tag ]]; then
	src_max_len=$((src_max_len_base+1))
	tgt_max_len=$((tgt_max_len_base+1))
elif [[ $style_model == tag-src ]]; then
	src_max_len=$((src_max_len_base+1))
	tgt_max_len=$tgt_max_len_base
else
	src_max_len=$src_max_len_base
	tgt_max_len=$tgt_max_len_base
fi;

## begin!

if [[ $exp_name == baseline ]]; then
	sub_data_dir=$exp_dir/data
	mkdir -p $sub_data_dir
	if [[ $train_data == transfer* ]]; then
		. `dirname $0`/preprocess-transfer.sh
	elif [[ $train_data == translation* ]]; then
		. `dirname $0`/preprocess-translation.sh
	fi;
else
	sub_data_dir=$exp_dir/data
	if [[ $exp_name == multitask ]]; then
		base_exp_dir=$base_dir/baseline-none-translation
		mkdir -p $sub_data_dir
		. `dirname $0`/preprocess-multitask.sh
	elif [[ $exp_name == selection ]]; then
		base_exp_dir=$base_dir/baseline-none-translation
		mkdir -p $sub_data_dir
		. `dirname $0`/preprocess-selection.sh
	else
		base_exp_dir=$base_dir/multitask-$style_model-$train_data
		ln -srf $base_exp_dir/data $sub_data_dir
		ln -srf $sub_data_dir/dev_transfer.src $sub_data_dir/dev.src
		ln -srf $sub_data_dir/dev_transfer.tgt $sub_data_dir/dev.tgt
	fi;
fi;

train_src=$sub_data_dir/train.src
train_tgt=$sub_data_dir/train.tgt
dev_src=$sub_data_dir/dev.src
dev_tgt=$sub_data_dir/dev.tgt
for i in $(seq $run_start $run_end); do
	model_dir=$exp_dir/model-$i
	if [[ $exp_name != baseline ]]; then
		fine_tuning_on=True
	fi;
	if [[ $exp_name == multitask ]] || [[ $exp_name == selection ]]; then
		new_vocab=True
	else
		new_vocab=False
	fi;
	
	## Training model-$i
	seed=$i
	. `dirname $0`/sockeye-train.sh
done;

model_exp_dir=$exp_dir
. `dirname $0`/evaluate.sh

date;
