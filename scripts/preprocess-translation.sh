#!/bin/bash

bpe_num_operations=50000

# True-casing
for lang in $lang_1 $lang_2; do
	tc_model=$global_data_dir/tc.$pp_vocab.$lang
	if [ ! -f $tc_model ]; then
		echo " * Training truecaser using $train.$lang ..."
		$moses_scripts_path/recaser/train-truecaser.perl \
			-corpus $train.$lang \
			-model $tc_model
	fi;
	for type in train dev; do
		if [ -f ${!type}.$lang ] && [ ! -f $sub_data_dir/$type.tok.tc.$lang ]; then
			echo " * True-casing ${!type}.$lang ..."
			$moses_scripts_path/recaser/truecase.perl \
				-model $tc_model                       \
				< ${!type}.$lang                        \
				> $sub_data_dir/$type.tok.tc.$lang
		fi;
	done;
done;

# Byte Pair Encoding (BPE)
bpe_model=$global_data_dir/bpe.$pp_vocab
if [ ! -f $bpe_model ]; then
	echo " * Training BPE using $sub_data_dir/train.tok.tc.* ..."
	cat $sub_data_dir/train.tok.tc.$lang_1 $sub_data_dir/train.tok.tc.$lang_2 \
		| python $bpe_scripts_path/learn_bpe.py \
			-s $bpe_num_operations \
			> $bpe_model
fi;
for type in train dev; do
	for lang in $lang_1 $lang_2; do
		if [ -f $sub_data_dir/$type.tok.tc.$lang ] && [ ! -f $sub_data_dir/$type.tok.tc.bpe.$lang ]; then
			echo " * Applying BPE to $sub_data_dir/$type.tok.tc.$lang ..."
			python $bpe_scripts_path/apply_bpe.py \
				--codes $bpe_model                 \
				< $sub_data_dir/$type.tok.tc.$lang  \
				> $sub_data_dir/$type.tok.tc.bpe.$lang
		fi;
	done;
done;

# Data linking
for type in train dev; do
	if [ ! -f $sub_data_dir/$type.tgt ]; then
		echo " * Creating the source ($type) ..."
		ln -srf $sub_data_dir/$type.tok.tc.bpe.$lang_1 $sub_data_dir/$type.src
		
		echo " * Creating the target ($type) ..."
		ln -srf $sub_data_dir/$type.tok.tc.bpe.$lang_2 $sub_data_dir/$type.tgt
	fi;
done;
