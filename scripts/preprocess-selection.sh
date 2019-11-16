#!/bin/bash

lang_pos=formal
lang_neg=informal
pos=$train_transfer.$lang_pos
neg=$train_transfer.$lang_neg
pool_tgt=$base_exp_dir/data/train.tok.tc.$lang_2
pool_bpe_src=$base_exp_dir/data/train.tok.tc.bpe.$lang_1
pool_bpe_tgt=$base_exp_dir/data/train.tok.tc.bpe.$lang_2

# Training language models
tc_model=$global_data_dir/tc.$pp_vocab.$lang_base
for corpus in $pos $neg; do
	lm=$global_data_dir/lm.transfer-`basename $corpus`.tc
	if [ ! -f $lm.bin ]; then
		echo " * Training LM for $corpus ..."
		cat $corpus \
			| $moses_scripts_path/recaser/truecase.perl -model $tc_model \
			| $kenlm_path/lmplz --order 5 -S 30G \
			> $lm
	    $kenlm_path/build_binary $lm $lm.bin
		rm $lm
	fi;
done; # for corpus

# Computing average cross-entropy scores for the pool
lm_pos=$global_data_dir/lm.transfer-`basename $pos`.tc.bin
lm_neg=$global_data_dir/lm.transfer-`basename $neg`.tc.bin
xent_using_pos=$global_data_dir/xent.$pp_vocab.tok.tc.$lang_pos
xent_using_neg=$global_data_dir/xent.$pp_vocab.tok.tc.$lang_neg
for corpus in pos neg; do
	eval lm='$'lm_$corpus
	eval xent='$'xent_using_$corpus
	if [ ! -f $xent ]; then
		echo " * POS: $pos"
		echo " * NEG: $neg"
		echo " * Computing cross-entropy of pool with the $corpus LM ..."
		cat $pool_tgt \
			| $kenlm_path/query -v sentence $lm         \
			| perl -pe 's/^Total:\s+//; s/ OOV: /\t/;'   \
			| paste <(awk '{print NR"\t"NF}' $pool_tgt) - \
			| perl -pe 'chomp; my @line=split("\t",$_); my @outline=($line[0],-$line[2]/$line[1],$line[1],$line[3]); $_=join("\t",@outline)."\n";' \
			> $xent
		# -> logprob perplexity, oov
		# -> line #, #words, logprob ppl, oov
		# -> line #, avg per-word cross-entropy, #words, oov
		# The KenLM score is the log of the probability according to the LM: K(S) = log [ P_LM (S) ],
		# so we need to flip the sign of the KenLM score to get cross-entropy.
	fi;
done; # for corpus

# Computing cross-entropy difference and sorting pool sentences by XEdiff score
xediff=$global_data_dir/xediff.$pp_vocab.tok.tc.bpe.$lang_pos-$lang_neg
if [ ! -f $xediff ]; then
	echo " * Computing CED scores for $lang_pos-$lang_neg ..."
	# The cross-entropy scores are #1 (pos) and #5 (neg)
	# fields 0 and 4 are sentence ID and should match
	# fields 2 and 6 are number of words and should match
	# fields 3 and 7 are OOV and can be ignored
	# remember to round down scores in scientific notation.
	paste $xent_using_pos $xent_using_neg  \
		| perl -pe 'my @arr=split(/\t/); $_ = join("\t", ($arr[1]-$arr[5], $arr[0]))."\n" if (($arr[0] == $arr[4]) && ($arr[2] == $arr[6]));' \
		| perl -pe 's/^-?\d+\.\d+e-\d+/0/;'  \
		| paste - $pool_bpe_tgt $pool_bpe_src \
		| sort --numeric-sort \
		| cut -f1,3,4          \
		> $xediff
fi;

# Language-tagging
if [ ! -f $sub_data_dir/train.src ]; then
	echo " * Tagging the training data ..."
	python `dirname $0`/ced-to-tag.py \
		-d $xediff  \
		-p $lang_pos \
		-n $lang_neg  \
		-o $sub_data_dir/train.tgt $sub_data_dir/train.src
fi;

if [[ $train_data == *transfer* ]]; then
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
	if [ ! -f $sub_data_dir/dev.tgt ]; then
		echo " * Tagging dev_transfer ..."
		cat $sub_data_dir/dev_transfer.tok.tc.bpe.$formality_1 | sed "s/^/<2$formality_2> /" >> $sub_data_dir/dev.src
		cat $sub_data_dir/dev_transfer.tok.tc.bpe.$formality_2 | sed "s/^/<2$formality_1> /" >> $sub_data_dir/dev.src
		cat $sub_data_dir/dev_transfer.tok.tc.bpe.$formality_2 | sed "s/^/<2$formality_1> /" >> $sub_data_dir/dev.tgt
		cat $sub_data_dir/dev_transfer.tok.tc.bpe.$formality_1 | sed "s/^/<2$formality_2> /" >> $sub_data_dir/dev.tgt
	fi;
	if [ ! -f $sub_data_dir/train_transfer.tgt ]; then
		echo " * Concatenating train_transfer ..."
		cat $sub_data_dir/train_transfer.tok.tc.bpe.$formality_1 | sed "s/^/<2$formality_2> /" >> $sub_data_dir/train_transfer.src
		cat $sub_data_dir/train_transfer.tok.tc.bpe.$formality_2 | sed "s/^/<2$formality_1> /" >> $sub_data_dir/train_transfer.src
		cat $sub_data_dir/train_transfer.tok.tc.bpe.$formality_2 | sed "s/^/<2$formality_1> /" >> $sub_data_dir/train_transfer.tgt
		cat $sub_data_dir/train_transfer.tok.tc.bpe.$formality_1 | sed "s/^/<2$formality_2> /" >> $sub_data_dir/train_transfer.tgt
		for lang in src tgt; do
			for i in $(seq 1 $upsampling); do
				cat $sub_data_dir/train_transfer.$lang >> $sub_data_dir/train.$lang
			done;
		done;
	fi;
else
	for lang in src tgt; do
		if [ ! -f $sub_data_dir/dev.$lang ]; then
			cat $base_exp_dir/data/dev.$lang | sed "s/^/<2unk> /" > $sub_data_dir/dev-2unk.$lang
			ln -srf $sub_data_dir/dev-2unk.$lang $sub_data_dir/dev.$lang
		fi;
	done;
fi;
