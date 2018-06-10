#!/bin/bash

pos=$task.$lang_pos
neg=$task.$lang_neg
pool_src=$pool.$bilingual_lang_src
pool_tgt=$pool.$lang_ds

# Training a truecaser
if [ ! -f $global_data_dir/tc.$lang_ds ]; then
	echo " * Training truecaser using pos/neg/pool-tgt ..."
	cat $pos $neg $pool_tgt > $global_data_dir/tc.corpus.tmp
	$moses_scripts_path/recaser/train-truecaser.perl \
		-corpus $global_data_dir/tc.corpus.tmp        \
		-model $global_data_dir/tc.$lang_ds
	rm $global_data_dir/tc.corpus.tmp
fi;

# Training language models
for corpus in $pos $neg; do
	lm=$global_data_dir/`basename $corpus`.tc.lm
	if [ ! -f $lm.bin ]; then
		echo " * Training LM for $corpus ..."
		cat $corpus \
			| $moses_scripts_path/recaser/truecase.perl -model $global_data_dir/tc.$lang_ds \
			| $kenlm_path/lmplz --order 5 -S 30G \
			> $lm
	    $kenlm_path/build_binary $lm $lm.bin
		rm $lm
	fi;
done; # for corpus

# Pre-processing fully upper-cased sentences
pool_pp_tgt=$global_data_dir/pool.pp.$lang_ds
if [ ! -f $pool_pp_tgt ]; then
	echo " * Pre-processing fully upper-cased sentences in $pool_tgt"
	cat $pool_tgt \
		| python `dirname $0`/process-all-uppercase.py \
		> $pool_pp_tgt
fi;

# Computing average cross-entropy scores for the pool
lm_pos=$global_data_dir/`basename $pos`.tc.lm.bin
lm_neg=$global_data_dir/`basename $neg`.tc.lm.bin
xent_using_pos=$global_data_dir/xent.$lang_pos
xent_using_neg=$global_data_dir/xent.$lang_neg
for corpus in pos neg; do
	eval lm='$'lm_$corpus
	eval xent='$'xent_using_$corpus
	if [ ! -f $xent ]; then
		echo " * POS: $pos"
		echo " * NEG: $neg"
		echo " * Computing cross-entropy of pool with the $corpus LM ..."
		cat $pool_pp_tgt \
			| $moses_scripts_path/recaser/truecase.perl -model $global_data_dir/tc.$lang_ds \
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
xediff=$global_data_dir/xediff.$lang_pos-$lang_neg
xediff_reversed=$global_data_dir/xediff.$lang_neg-$lang_pos
if [ ! -f $xediff ] && [ ! -f $xediff_reversed ]; then
	echo " * Computing CED scores for $lang_pos-$lang_neg ..."
	# The cross-entropy scores are #1 (pos) and #5 (neg)
	# fields 0 and 4 are sentence ID and should match
	# fields 2 and 6 are number of words and should match
	# fields 3 and 7 are OOV and can be ignored
	# remember to round down scores in scientific notation.
	paste $xent_using_pos $xent_using_neg \
		| perl -pe 'my @arr=split(/\t/); $_ = join("\t", ($arr[1]-$arr[5], $arr[0]))."\n" if (($arr[0] == $arr[4]) && ($arr[2] == $arr[6]));' \
		| perl -pe 's/^-?\d+\.\d+e-\d+/0/;' \
		| paste - $pool_tgt $pool_src        \
		| sort --numeric-sort \
		| cut -f1,3,4          \
		> $xediff
fi;

# Selecting specified size of data from the pool
if [ ! -f $select_data.$lang_ds ]; then
	echo " * Selecting data from $pool ..."
	if [ -f $xediff ]; then
		cut -f2 $xediff | head -n $select_n > $select_data.$lang_ds
		cut -f3 $xediff | head -n $select_n > $select_data.$bilingual_lang_src
	elif [ -f $xediff_reversed ]; then
		tac $xediff_reversed | cut -f2 | head -n $select_n > $select_data.$lang_ds
		tac $xediff_reversed | cut -f3 | head -n $select_n > $select_data.$bilingual_lang_src
	fi;
fi;
