#!/bin/bash

formality_1=formal
formality_2=informal

# True-casing
tc_model=$global_data_dir/tc.$pp_vocab.$lang_base
for lang in $formality_1 $formality_2; do
	for type in train_transfer dev_transfer; do
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
for type in train_transfer dev_transfer; do
	for lang in $formality_1 $formality_2; do
		if [ -f $sub_data_dir/$type.tok.tc.$lang ] && [ ! -f $sub_data_dir/$type.tok.tc.bpe.$lang ]; then
			echo " * Applying BPE to $sub_data_dir/$type.tok.tc.$lang ..."
			python $bpe_scripts_path/apply_bpe.py \
				--codes $bpe_model                 \
				< $sub_data_dir/$type.tok.tc.$lang  \
				> $sub_data_dir/$type.tok.tc.bpe.$lang
		fi;
	done;
done;

# Language-tagging and concatenating data
for type in train_transfer dev_transfer; do
	if [ ! -f $sub_data_dir/$type.tgt ]; then
		echo " * Creating the source ($type) ..."
		cat $sub_data_dir/$type.tok.tc.bpe.$formality_1 | sed "s/^/<2$formality_2> /" >> $sub_data_dir/$type.src
		cat $sub_data_dir/$type.tok.tc.bpe.$formality_2 | sed "s/^/<2$formality_1> /" >> $sub_data_dir/$type.src
		
		echo " * Creating the target ($type) ..."
		cat $sub_data_dir/$type.tok.tc.bpe.$formality_2 | sed "s/^/<2$formality_1> /" >> $sub_data_dir/$type.tgt
		cat $sub_data_dir/$type.tok.tc.bpe.$formality_1 | sed "s/^/<2$formality_2> /" >> $sub_data_dir/$type.tgt
	fi;
done;
for lang in src tgt; do
	type=train
	if [ ! -f $sub_data_dir/$type.$lang ]; then
		echo " * Creating $type.$lang ..."
		for i in $(seq 1 $upsampling); do
			cat $sub_data_dir/${type}_transfer.$lang >> $sub_data_dir/$type.$lang
		done;
		cat $base_exp_dir/data/$type.$lang | sed "s/^/<2unk> /" >> $sub_data_dir/$type.$lang
	fi;
	type=dev
	if [ ! -f $sub_data_dir/$type-2unk.$lang ]; then
		echo " * Creating $type-2unk.$lang ..."
		cat $base_exp_dir/data/$type.$lang | sed "s/^/<2unk> /" > $sub_data_dir/$type-2unk.$lang
	fi;
	ln -srf $sub_data_dir/$type-2unk.$lang $sub_data_dir/$type.$lang
done;
