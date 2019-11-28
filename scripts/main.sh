#!/bin/bash

. `dirname $0`/import.sh

gpus=0
proc_per_gpu=1
sampling_loss_weight=0.05
fine_tuning_lr=0.0001
upsampling=10
style_model=tag
while getopts ":g:d:m:t:u:y:i:w:nh" opt; do
	case $opt in
	g)
		gpus=$OPTARG ;;
	d)
		decode_gpu=$OPTARG ;;
	m)
		model_id=$OPTARG ;;
	t)
		train_data=$OPTARG ;;
	u)
		upsampling=$OPTARG ;;
	y)
		style_embed=5
		style_model=$OPTARG
		if [[ $style_model == *factor* ]] || [[ $style_model == *decoder* ]] || [[ $style_model == block* ]]; then
			factor_mode=True
		else
			factor_mode=False
		fi ;;
	i)
		inference_type=$OPTARG ;;
	w)
		sampling_loss_weight=$OPTARG ;;
	n)
		no_eval=True ;;
	h)
		echo "Usage: main.sh"
		echo "-g GPU ids (e.g. 1,2,4)"
		echo "-d GPU id for decoding during training (e.g. 1)"
		echo "-m model id (positive int means id, negative int means ensemble size)"
		echo "-t training data (transfer/translation/translation-unk-transfer/translation-unk-ds/translation-unk-transfer-ds)"
		echo "-u upsampling ratio for the transfer data"
		echo "-y style model (none/tag/tag-src/block-tag-src/factor-concat/factor-sum/decoder-bias/decoder-concat/decoder-sum/decoder-bos)"
		echo "-i inference type (oti/osi)"
		echo "-w sampling loss weight"
		echo "-n no evaluation"
		exit 0 ;;
    \?)
		echo "Invalid option: -$OPTARG" >&2
		exit 1 ;;
    :)
		echo "Option -$OPTARG requires an argument." >&2
		exit 1 ;;
	esac
done

## pipeline parameters
if (( $model_id < 0 )); then
	run_start=1
	run_end=$((-model_id))
	ensemble=True
else
	run_start=$model_id
	run_end=$model_id
	ensemble=False
fi;

## experiment naming variables
base_dir=$root_dir/experiments
mkdir -p $base_dir

## experiment files
global_data_dir=$base_dir/global-data
mkdir -p $global_data_dir

if [[ $train_data == transfer* ]]; then
	lang_1=formal
	lang_2=informal
	pp_vocab=style-transfer
	test_transfer=True
	
	train=$GYAFC_data_dir/train.tok
	dev=$global_data_dir/dev.f2i-i2f.tok
	if [ ! -f $dev.$lang_2 ]; then
		echo " * Combining dev data ..."
		cat $GYAFC_data_dir/dev-to-$lang_2.tok.$lang_1 >> $dev.$lang_1
		cat $GYAFC_data_dir/dev-to-$lang_2.tok.$lang_2 >> $dev.$lang_2
		cat $GYAFC_data_dir/dev-to-$lang_1.tok.$lang_1 >> $dev.$lang_1
		cat $GYAFC_data_dir/dev-to-$lang_1.tok.$lang_2 >> $dev.$lang_2
	fi;
	
	test_src_1=$GYAFC_data_dir/test-to-formal.tok.informal
	test_src_lang_1=$lang_base
	test_ref_1=$GYAFC_data_dir/test-to-formal.formal
	test_ref_num_1=4
	test_ref_tag_1=formal
	test_src_2=$GYAFC_data_dir/test-to-informal.tok.formal
	test_src_lang_2=$lang_base
	test_ref_2=$GYAFC_data_dir/test-to-informal.informal
	test_ref_num_2=4
	test_ref_tag_2=informal
	test_src_3=$GYAFC_data_dir/test-to-formal.tok.informal
	test_src_lang_3=$lang_base
	test_ref_3=$GYAFC_data_dir/test-to-formal.informal
	test_ref_num_3=1
	test_ref_tag_3=informal
	test_src_4=$GYAFC_data_dir/test-to-informal.tok.formal
	test_src_lang_4=$lang_base
	test_ref_4=$GYAFC_data_dir/test-to-informal.formal
	test_ref_num_4=1
	test_ref_tag_4=formal
	test_number=4
fi;
if [[ $train_data == translation* ]]; then
	lang_1=fr
	lang_2=en
	pp_vocab=translation-$lang_1-$lang_2
	if [[ $train_data == *unk* ]]; then
		unk_tag=True
	fi;
	
	train=$global_data_dir/OpenSubtitles2016-Europarl-NewsCommentary.tok
	for lang in $lang_1 $lang_2; do
		if [ ! -f $train.$lang ]; then
			echo " * Combining train.$lang data ..."
			cat $OpenSubtitles2016_data_dir/OpenSubtitles2016.en-fr.train-16M.tok.$lang >> $train.$lang
			cat $Europarl_data_dir/Europarl-v7.fr-en.clean.tok.$lang >> $train.$lang
			cat $NewsCommentary_data_dir/NewsCommentary-v14.en-fr.clean.tok.$lang >> $train.$lang
		fi;
	done;
	dev=$OpenSubtitles2016_data_dir/OpenSubtitles2016.en-fr.dev-3000.tok
	train_transfer=$GYAFC_data_dir/train.tok
	dev_transfer=$global_data_dir/dev.f2i-i2f.tok
	if [ ! -f $dev_transfer.informal ]; then
		echo " * Combining dev data ..."
		cat $GYAFC_data_dir/dev-to-informal.tok.formal >> $dev_transfer.formal
		cat $GYAFC_data_dir/dev-to-informal.tok.informal >> $dev_transfer.informal
		cat $GYAFC_data_dir/dev-to-formal.tok.formal >> $dev_transfer.formal
		cat $GYAFC_data_dir/dev-to-formal.tok.informal >> $dev_transfer.informal
	fi;
	
	test_src_1=$WMT_data_dir/newstest2014.fr-en.tok.$lang_1
	test_src_lang_1=$lang_1
	test_ref_1=$WMT_data_dir/newstest2014.fr-en.$lang_2
	test_ref_num_1=1
	test_ref_tag_1=informal
	test_src_2=$WMT_data_dir/newstest2014.fr-en.tok.$lang_1
	test_src_lang_2=$lang_1
	test_ref_2=$WMT_data_dir/newstest2014.fr-en.$lang_2
	test_ref_num_2=1
	test_ref_tag_2=formal
	
	
	test_src_3=$MSLT_data_dir/MSLT.en-fr.test-clean.tok.$lang_1
	test_src_lang_3=$lang_1
	test_ref_3=$MSLT_data_dir/MSLT.en-fr.test-clean.$lang_2
	test_ref_num_3=1
	test_ref_tag_3=informal
	test_src_4=$MSLT_data_dir/MSLT.en-fr.test-clean.tok.$lang_1
	test_src_lang_4=$lang_1
	test_ref_4=$MSLT_data_dir/MSLT.en-fr.test-clean.$lang_2
	test_ref_num_4=1
	test_ref_tag_4=formal
	
	test_src_5=$OpenSubtitles2016_data_dir/OpenSubtitles2016.en-fr.test-3000.tok.$lang_1
	test_src_lang_5=$lang_1
	test_ref_5=$OpenSubtitles2016_data_dir/OpenSubtitles2016.en-fr.test-3000.$lang_2
	test_ref_num_5=1
	test_ref_tag_5=informal
	test_src_6=$OpenSubtitles2016_data_dir/OpenSubtitles2016.en-fr.test-3000.tok.$lang_1
	test_src_lang_6=$lang_1
	test_ref_6=$OpenSubtitles2016_data_dir/OpenSubtitles2016.en-fr.test-3000.$lang_2
	test_ref_num_6=1
	test_ref_tag_6=formal
	
	test_number=6
fi;

exp_name=baseline
if [[ $train_data == translation* ]]; then
	style_model_save=$style_model
	train_data_save=$train_data
	style_model=none
	train_data=translation
	. `dirname $0`/experiment.sh
	style_model=$style_model_save
	train_data=$train_data_save
elif [[ $train_data == transfer* ]]; then
	. `dirname $0`/experiment.sh
fi;

if [[ $train_data == translation*-transfer ]]; then
	exp_name=multitask
	. `dirname $0`/experiment.sh
elif [[ $train_data == translation*-ds ]]; then
	exp_name=selection
	. `dirname $0`/experiment.sh
fi;

if [[ $inference_type != "" ]]; then
	exp_name=$inference_type
	. `dirname $0`/experiment.sh
fi;
