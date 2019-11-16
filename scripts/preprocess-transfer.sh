#!/bin/bash

bpe_num_operations=32000

# True-casing
tc_model=$global_data_dir/tc.$pp_vocab.$lang_base
if [ ! -f $tc_model ]; then
	echo " * Training truecaser using $train.* ..."
	cat $train.$lang_1 $train.$lang_2 > $sub_data_dir/tc.corpus.tmp
	$moses_scripts_path/recaser/train-truecaser.perl \
		-corpus $sub_data_dir/tc.corpus.tmp           \
		-model $tc_model
	rm $sub_data_dir/tc.corpus.tmp
fi;
for type in train dev; do
	for lang in $lang_1 $lang_2; do
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

# Language-tagging and concatenating data
for type in train dev; do
	if [ ! -f $sub_data_dir/$type.tgt ]; then
		echo " * Creating the source ($type) ..."
		if [[ $style_model == tag* ]]; then
			cat $sub_data_dir/$type.tok.tc.bpe.$lang_1 | sed "s/^/<2$lang_2> /" >> $sub_data_dir/$type.src
			cat $sub_data_dir/$type.tok.tc.bpe.$lang_2 | sed "s/^/<2$lang_1> /" >> $sub_data_dir/$type.src
		else
			cat $sub_data_dir/$type.tok.tc.bpe.$lang_1 >> $sub_data_dir/$type.src
			cat $sub_data_dir/$type.tok.tc.bpe.$lang_2 >> $sub_data_dir/$type.src
		fi;
		if [[ $style_model == *factor* ]] || [[ $style_model == *decoder* ]] || [[ $style_model == block* ]]; then
			cat $sub_data_dir/$type.tok.tc.bpe.$lang_1 | sed "s/[^ ]\+/<2$lang_2>/g" >> $sub_data_dir/$type.src.factor
			cat $sub_data_dir/$type.tok.tc.bpe.$lang_2 | sed "s/[^ ]\+/<2$lang_1>/g" >> $sub_data_dir/$type.src.factor
		fi;
		
		echo " * Creating the target ($type) ..."
		if [[ $style_model == tag ]]; then
			cat $sub_data_dir/$type.tok.tc.bpe.$lang_2 | sed "s/^/<2$lang_1> /" >> $sub_data_dir/$type.tgt
			cat $sub_data_dir/$type.tok.tc.bpe.$lang_1 | sed "s/^/<2$lang_2> /" >> $sub_data_dir/$type.tgt
		else
			cat $sub_data_dir/$type.tok.tc.bpe.$lang_2 >> $sub_data_dir/$type.tgt
			cat $sub_data_dir/$type.tok.tc.bpe.$lang_1 >> $sub_data_dir/$type.tgt
		fi;
	fi;
done;
