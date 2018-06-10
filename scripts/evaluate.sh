#!/bin/bash

root_dir=`dirname $0`/..
test_dir=$root_dir/test
mkdir $test_dir

### Parameters
test_src=$test_dir/GYAFC.test-to-formal.tok.informal # GYAFC test data should be tokenized.
test_ref=$test_dir/GYAFC.test-to-formal.formal
test_ref_num=4
tgt_tag=formal
mt_models_dir=$root_dir/experiments/iter-1
tc_model=$mt_models_dir/data/tc.en
bpe_model=$mt_models_dir/data/bpe.en
# test_src=$root_dir/data/OpenSubtitles2016/OpenSubtitles2016.en-fr.test-2500.tok.fr
# test_ref=$root_dir/data/OpenSubtitles2016/OpenSubtitles2016.en-fr.test-2500.en
# test_ref_num=1
# tgt_tag=formal
# mt_models_dir=$root_dir/experiments/iter-2-fix-12/exp-random-fine-tuning
# tc_model=$mt_models_dir/data/tc
# bpe_model=$mt_models_dir/data/bpe

ensemble=True
gpu_id=0

if [[ $ensemble == True ]]; then
	run_n=4
else
	run_n=1
fi;
if [[ $tgt_tag == formal ]] || [[ $test_ref_num == 1 ]]; then
	detruecase=True
else
	detruecase=False
fi;

## software bits
moses_scripts_path=$root_dir/moses-scripts
bpe_scripts_path=$root_dir/subword-nmt/subword_nmt
sacrebleu_path=$root_dir/sockeye/contrib/sacrebleu

# Pre-processing test data
if [ ! -f $test_dir/test.tc ]; then
	echo " * True-casing $test_src ..."
	$moses_scripts_path/recaser/truecase.perl \
		-model $tc_model                       \
		< $test_src                             \
		> $test_dir/test.tc
fi;
if [ ! -f $test_dir/test.tc.bpe ]; then
	echo " * Applying BPE to $test_dir/test.tc ..."
	python2 $bpe_scripts_path/apply_bpe.py \
		--codes $bpe_model                  \
		< $test_dir/test.tc                  \
		> $test_dir/test.tc.bpe
fi;
if [ ! -f $test_dir/test.src ]; then
	echo " * Adding language tags to $test_dir/test.tc.bpe ..."
	cat $test_dir/test.tc.bpe    \
		| sed "s/^/<2$tgt_tag> /" \
		> $test_dir/test.src
fi;

# Ensemble decoding
model_list=""
for i in $(seq 1 $run_n); do
	model_list="$model_list $mt_models_dir/model-$i"
	if [ ! -f $mt_models_dir/model-$i/params.bleu-1 ]; then
		python3 -m sockeye.average \
			-n 1          \
			--metric bleu  \
			--strategy best \
			--output $mt_models_dir/model-$i/params.bleu-1 \
			$mt_models_dir/model-$i
	fi;
	ln -srf $mt_models_dir/model-$i/params.bleu-1 $mt_models_dir/model-$i/params.best
done;

if [ ! -f $test_dir/test.trans ]; then
	python3 -m sockeye.translate    \
		--input $test_dir/test.src   \
		--output $test_dir/test.trans \
		--models $model_list  \
		--ensemble-mode linear \
		--beam-size 5   \
		--batch-size 16  \
		--chunk-size 1024 \
		--device-ids $gpu_id
fi;

# Post-processing translations
if [ ! -f $test_dir/test.trans.detok ]; then
	echo " * Post-processing $test_dir/test.trans ..."
	if [[ $detruecase == False ]]; then
		cat $test_dir/test.trans \
			| perl -pe 's/@@ //g' 2>/dev/null \
			| $moses_scripts_path/tokenizer/detokenizer.perl -q -l en 2>/dev/null \
			> $test_dir/test.trans.detok
	else
		cat $test_dir/test.trans \
			| perl -pe 's/@@ //g' 2>/dev/null \
			| $moses_scripts_path/recaser/detruecase.perl 2>/dev/null \
			| $moses_scripts_path/tokenizer/detokenizer.perl -q -l en 2>/dev/null \
			> $test_dir/test.trans.detok
	fi;
fi;

# Evaluation
if [ ! -f $test_dir/bleu.log ]; then
	if (( $test_ref_num == 4 )); then
		python3 $sacrebleu_path/sacrebleu.py \
			${test_ref}0 ${test_ref}1 ${test_ref}2 ${test_ref}3 \
			< $test_dir/test.trans.detok \
			> $test_dir/bleu.log
	else
		python3 $sacrebleu_path/sacrebleu.py \
			$test_ref \
			< $test_dir/test.trans.detok \
			> $test_dir/bleu.log
	fi;
	cat $test_dir/bleu.log
fi;
