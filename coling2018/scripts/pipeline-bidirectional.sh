#!/bin/bash

date;

## experiment naming variables
exp_dir=$base_dir
if [[ $multitask == tag-style ]] || [[ $multitask == style ]]; then
	global_data_dir=$exp_dir/data-bilingual
elif [[ $multitask == random ]]; then
	nods=True
fi;

## pipeline parameters
if [[ $ensemble == True ]]; then
	run_n=4
else
	run_n=1
fi;

## begin!
for t in $(seq 1 $iterations); do
	echo "=== Iteration $t ==="
	
	if [[ $t == 1 ]]; then
		sub_exp_dir=$exp_dir/iter-$t
		sub_data_dir=$sub_exp_dir/data
		mkdir -p $sub_data_dir
	elif (( $t >= 2 )); then
		mkdir -p $global_data_dir
		pt=$((t-1))
		base_n=$(wc -l < $train.$lang_1)
		iter_dir=$exp_dir/iter-$t
		select_n=$((data_selection*base_n))
		iter_dir=$iter_dir-fix-$data_selection
		
		prev_sub_exp_dir=$sub_exp_dir
		sub_exp_dir=$iter_dir/exp-$multitask
		if [[ $fine_tuning == True ]]; then
			sub_exp_dir=$sub_exp_dir-fine-tuning
		fi;
		sub_data_dir=$sub_exp_dir/data
		mkdir -p $sub_data_dir

		## Generating the training data
		## *_1 -> target language is L1
		train_st_1=$sub_data_dir/train_st_1.tok
		train_st_2=$sub_data_dir/train_st_2.tok
		if [ ! -f $train_st_2.$lang_1 ]; then
			echo " * Generating style transfer training data ..."
			for i in $(seq 1 $data_selection); do
				cat $train.$lang_1 >> $train_st_1.$lang_1
				cat $train.$lang_2 >> $train_st_1.$lang_2
				cat $train.$lang_2 >> $train_st_2.$lang_2
				cat $train.$lang_1 >> $train_st_2.$lang_1
			done;
		fi;
		
		## Selecting the bilingual parallel data
		task=$train
		pool=$bilingual_data
		if [[ $nods == True ]]; then
			select_n=$((2*data_selection*base_n))
			lang_pos=$lang_1
			lang_neg=$lang_2
			bilingual_data_dir=$iter_dir/bilingual
			mkdir -p $bilingual_data_dir
			. `dirname $0`/gen-bilingual-data.sh
			
			train_ad_1=$sub_data_dir/train_ad_1.tok
			train_ad_2=$sub_data_dir/train_ad_2.tok
			if [ ! -f $train_ad_2.$lang_1 ]; then
				echo " * Generating machine translation training data ..."
				cat $iter_dir/bilingual/bilingual.$lang_base          > $train_ad_1.$lang_1
				cat $iter_dir/bilingual/bilingual.$bilingual_lang_src > $train_ad_1.$lang_2
				touch $train_ad_2.$lang_2
				touch $train_ad_2.$lang_1
			fi;
		else
			lang_pos=$lang_2
			lang_neg=$lang_1
			bilingual_data_dir=$iter_dir/bilingual-$lang_pos
			mkdir -p $bilingual_data_dir
			. `dirname $0`/gen-bilingual-data.sh
			
			lang_pos=$lang_1
			lang_neg=$lang_2
			bilingual_data_dir=$iter_dir/bilingual-$lang_pos
			mkdir -p $bilingual_data_dir
			. `dirname $0`/gen-bilingual-data.sh
			
			train_ad_1=$sub_data_dir/train_ad_1.tok
			train_ad_2=$sub_data_dir/train_ad_2.tok
			if [ ! -f $train_ad_2.$lang_1 ]; then
				echo " * Generating machine translation training data ..."
				cat $iter_dir/bilingual-$lang_1/$lang_1.$lang_base          > $train_ad_1.$lang_1
				cat $iter_dir/bilingual-$lang_1/$lang_1.$bilingual_lang_src > $train_ad_1.$lang_2
				cat $iter_dir/bilingual-$lang_2/$lang_2.$lang_base          > $train_ad_2.$lang_2
				cat $iter_dir/bilingual-$lang_2/$lang_2.$bilingual_lang_src > $train_ad_2.$lang_1
			fi;
		fi;
	fi;
	
	## Preprocessing data for iteration-$t
	test_number=$test_n_base
	if [[ $multitask == style ]] || [[ $multitask == random ]]; then
		ad_tag=False
	fi;
	if [[ $multitask != "" ]] && (( $t >= 2 )); then
		. `dirname $0`/preprocess-multitask.sh
	else
		. `dirname $0`/preprocess.sh
	fi;
	
	train_src=$sub_data_dir/train.src
	train_tgt=$sub_data_dir/train.tgt
	dev_src=$sub_data_dir/dev.src
	dev_tgt=$sub_data_dir/dev.tgt
	for i in $(seq 1 $run_n); do
		model_dir=$sub_exp_dir/model-$i
		if [[ $fine_tuning == True ]] && (( $t >= 2 )); then
			fine_tuning_on=True
		fi;
		
		## Training model-$i
		seed=$i
		. `dirname $0`/sockeye-train.sh
	done;
done;

date;
