#!/bin/bash

root_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"

file_1=$root_dir/experiments/osi-tag-translation-unk-transfer/decode-1/perplexity/test_1.trans.detok 
file_2=$root_dir/experiments/osi-tag-translation-unk-transfer/decode-1/perplexity/test_2.trans.detok 
work_dir=$root_dir/LePoD/score

## set-up
lang_base=en
moses_scripts_path=$root_dir/software/moses-scripts
meteor_jar=$root_dir/software/meteor-1.5/meteor-1.5.jar
lepod=$root_dir/LePoD/lepod-score.py

mkdir -p $work_dir
input_1=$work_dir/input_1.tok
input_2=$work_dir/input_2.tok
output=$work_dir/score

$moses_scripts_path/tokenizer/tokenizer.perl -l $lang_base -a -no-escape -q < $file_1 > $input_1
$moses_scripts_path/tokenizer/tokenizer.perl -l $lang_base -a -no-escape -q < $file_2 > $input_2
cat $input_1 | perl -ne 'print lc' > $input_1.lc
cat $input_2 | perl -ne 'print lc' > $input_2.lc

java -Xmx2G -cp $meteor_jar Matcher $input_1.lc $input_2.lc -l $lang_base > $work_dir/alignment

python $lepod -l -d 4 -p "," -a $work_dir/alignment -f $input_1 $input_2 -r $output
