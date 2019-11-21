#!/bin/bash

# Pre-processing the test data
for i in $(seq 1 $test_number); do
	eval test_src='$'test_src_$i
	eval test_src_lang='$'test_src_lang_$i
	if [ ! -f $sub_data_dir/test_$i.tok.tc.bpe ]; then
		echo " * True-casing and applying BPE to $test_src ..."
		cat $test_src \
			| $moses_scripts_path/recaser/truecase.perl -model $global_data_dir/tc.$pp_vocab.$test_src_lang \
			| python $bpe_scripts_path/apply_bpe.py --codes $global_data_dir/bpe.$pp_vocab \
			> $sub_data_dir/test_$i.tok.tc.bpe
	fi;
	
	eval test_ref_tag='$'test_ref_tag_$i
	if [ ! -f $sub_data_dir/test_$i.src ]; then
		if [[ $style_model == tag* ]]; then
			if [[ $test_ref_tag == unk ]] && [[ $unk_tag != True ]]; then
				ln -srf $sub_data_dir/test_$i.tok.tc.bpe $sub_data_dir/test_$i.src
			else
				echo " * Adding language tags to $sub_data_dir/test_$i.tok.tc.bpe ..."
				cat $sub_data_dir/test_$i.tok.tc.bpe | sed "s/^/<2$test_ref_tag> /" > $sub_data_dir/test_$i.src
			fi;
		else
			ln -srf $sub_data_dir/test_$i.tok.tc.bpe $sub_data_dir/test_$i.src
		fi;
		if [[ $style_model == *factor* ]] || [[ $style_model == *decoder* ]] || [[ $style_model == block* ]]; then
			echo " * Creating language factors to $sub_data_dir/test_$i.tok.tc.bpe ..."
			cat $sub_data_dir/test_$i.tok.tc.bpe | sed "s/[^ ]\+/<2$test_ref_tag>/g" > $sub_data_dir/test_$i.src.factor
		fi;
	fi;
done;

if [[ $no_eval != True ]]; then
	for avg_metric in $avg_metric_list; do
		for ti in $(seq 1 $test_number); do
			decode_data_in=$sub_data_dir/test_$ti.src
			eval test_ref='$'test_ref_$ti
			eval test_ref_num='$'test_ref_num_$ti
			eval test_ref_tag='$'test_ref_tag_$ti
			
			bleu_list=""
			for mi in $(seq $run_start $run_end); do
				model_dir=$model_exp_dir/model-$mi
				decode_dir=$exp_dir/decode-$mi/$avg_metric
				mkdir -p $decode_dir
				decode_data_out=$decode_dir/test_$ti.trans
				
				## Generating parameters for model-$mi
				if [ ! -f $decode_dir/params ]; then
					python -m sockeye.average -n 1 \
						--metric $avg_metric \
						--strategy best       \
						--output $decode_dir/params \
						$model_dir
				fi;
				ln -srf $decode_dir/params $model_dir/params.best

				## Decoding for model-$mi
				ensemble_mode=False
				. `dirname $0`/sockeye-decode-parallel.sh
				
				## Evaluating model-$mi
				bleu_log=$decode_dir/bleu.test_$ti.log
				bleu_list="$bleu_list $bleu_log"
				summary_log=$exp_dir/decode-$mi/bleu.test_$ti.log
				if [ ! -f $bleu_log ]; then
					echo "best $avg_metric" >> $summary_log
				fi;
				statistics_on=False
				. `dirname $0`/evaluate-bleu.sh
			done;
			if [[ $ensemble == True ]]; then
				decode_dir=$exp_dir/decode-ensemble/$avg_metric
				mkdir -p $decode_dir
				decode_data_out=$decode_dir/test_$ti.trans
				
				## Ensemble decoding
				model_list=""
				for mi in $(seq $run_start $run_end); do
					model_list="$model_list $model_exp_dir/model-$mi"
				done;
				ensemble_mode=True
				. `dirname $0`/sockeye-decode-parallel.sh
				
				## Evaluating the result of ensemble decoding
				bleu_log=$decode_dir/bleu.test_$ti.log
				summary_log=$exp_dir/bleu-ensemble.test_$ti.log
				if [ ! -f $bleu_log ]; then
					echo "--- best $avg_metric ($run_end models)" >> $summary_log
					echo "- ensemble" >> $summary_log
				fi;
				statistics_on=True
				. `dirname $0`/evaluate-bleu.sh
			fi;
		done;
	done;
	
	for ti in $(seq 1 $test_number); do
		echo ""
		eval test_ref_tag='$'test_ref_tag_$ti
		eval test_ref='$'test_ref_$ti
		echo "TEST-$ti TAG=$test_ref_tag REF=$test_ref"
		if [[ $ensemble != True ]]; then
			for mi in $(seq $run_start $run_end); do
				echo "=== Model-$mi ==="
				cat $exp_dir/decode-$mi/bleu.test_$ti.log
			done;
		elif [[ $ensemble == True ]]; then
			cat $exp_dir/bleu-ensemble.test_$ti.log
		fi;
	done;
fi;
