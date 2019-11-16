#!/bin/bash

# MT Evaluation
if [ ! -f $bleu_log ]; then
	lang_tok=en
	if [[ $test_ref_tag == informal ]] && [[ $test_transfer == True ]]; then # no detruecasing for informal output
		cat $decode_data_out \
			| sed -r 's/<2[a-z]+> //g' 2>/dev/null   \
			| sed -r 's/(@@ )|(@@ ?$)//g' 2>/dev/null \
			> $decode_data_out.tok
	else 
		cat $decode_data_out \
			| sed -r 's/<2[a-z]+> //g' 2>/dev/null   \
			| sed -r 's/(@@ )|(@@ ?$)//g' 2>/dev/null \
			| $moses_scripts_path/recaser/detruecase.perl 2>/dev/null \
			> $decode_data_out.tok
	fi;
	cat $decode_data_out.tok \
		| $moses_scripts_path/tokenizer/detokenizer.perl -q -l $lang_tok 2>/dev/null \
		> $decode_data_out.detok
	
	if [[ $test_transfer == True ]]; then
		sacrebleu_args=" --width 2"
	else
		sacrebleu_args=" --width 2 -lc"
	fi;
	
	if (( $test_ref_num == 4 )); then
		python $sacrebleu_path/sacrebleu.py $sacrebleu_args \
			${test_ref}0 ${test_ref}1 ${test_ref}2 ${test_ref}3 \
			< $decode_data_out.detok \
			> $bleu_log
	else
		python $sacrebleu_path/sacrebleu.py $sacrebleu_args \
			$test_ref \
			< $decode_data_out.detok \
			> $bleu_log
	fi;
	
	cat $bleu_log >> $summary_log
	if [[ $statistics_on == True ]]; then
		echo "- average" >> $summary_log
		cut -f2- -d' ' $bleu_list | python $statistics_tool -l -m mean >> $summary_log
		cut -f2- -d' ' $bleu_list | python $statistics_tool -l -m std >> $summary_log
		cut -f2- -d' ' $bleu_list | python $statistics_tool -l -m min >> $summary_log
		cut -f2- -d' ' $bleu_list | python $statistics_tool -l -m max >> $summary_log
	fi;
fi;
