#!/bin/bash

model_args=""

if [[ $fine_tuning_on == True ]]; then
	init_params_dir=$exp_dir/init-params
	mkdir -p $init_params_dir
	params_name=params-$i
	
	if [[ $new_vocab == True ]]; then
		# Building the vocabulary
		if [ ! -f $init_params_dir/vocab.json ]; then
			python3 -m sockeye.vocab    \
				-i $train_src $train_tgt \
				-o $init_params_dir/vocab.json
		fi;
		# Updating weights in the base model
		if [ ! -f $init_params_dir/$params_name ]; then
			## Initializing new weights with given vocabulary
			python3 -m sockeye.init_embedding \
				-w $base_exp_dir/decode-$i/$fine_tuning_metric/params $base_exp_dir/decode-$i/$fine_tuning_metric/params \
				-i $base_exp_dir/model-$i/vocab.src.0.json $base_exp_dir/model-$i/vocab.src.0.json \
				-o $init_params_dir/vocab.json $init_params_dir/vocab.json \
				-n source_target_embed_weight target_output_bias \
				-f $init_params_dir/$params_name-new
			## Updating base model parameters with new weights
			echo " * Updating base model parameters with new weights ..."
			python3 `dirname $0`/update-mxnet-params.py \
				-o $base_exp_dir/decode-$i/$fine_tuning_metric/params \
				-n $init_params_dir/$params_name-new \
				-s $init_params_dir/$params_name
			rm $init_params_dir/$params_name-new
		fi;
	else
		if [ ! -f $init_params_dir/$params_name ]; then
			cp $base_exp_dir/decode-$i/$fine_tuning_metric/params $init_params_dir/$params_name
		fi;
		if [ ! -f $init_params_dir/vocab.json ]; then
			cp $base_exp_dir/model-$i/vocab.src.0.json $init_params_dir/vocab.json
		fi;
	fi;
	
	model_args="${model_args} --params $init_params_dir/$params_name"
	model_args="${model_args} --source-vocab $init_params_dir/vocab.json"
	model_args="${model_args} --target-vocab $init_params_dir/vocab.json"
	model_args="${model_args} --initial-learning-rate $fine_tuning_lr"
fi;

if [[ $inference_type == oti ]]; then
	model_args="${model_args} --sampling-objectives consistency --sampling-loss-weights $sampling_loss_weight"
	model_args="${model_args} --instantiate-hidden argmax"
	model_args="${model_args} --gradient-clipping-type abs --gradient-clipping-threshold 1"
elif [[ $inference_type == osi ]]; then
	model_args="${model_args} --adaptive-tagging"
fi;

if [[ $factor_mode == True ]]; then
	model_args="${model_args} -sf $train_src.factor -vsf $dev_src.factor"
	if [[ $style_model == factor-concat ]]; then
		model_args="${model_args} --source-factors-combine concat --source-factors-num-embed $style_embed"
	elif [[ $style_model == factor-sum ]]; then
		model_args="${model_args} --source-factors-combine sum"
	elif [[ $style_model == block* ]]; then
		model_args="${model_args} --source-factors-combine sum --conditional-decoder cd-tag-attention"
	elif [[ $style_model == decoder-bias ]]; then
		model_args="${model_args} --source-factors-combine sum --conditional-decoder cd-output-bias"
	elif [[ $style_model == decoder-concat ]]; then
		model_args="${model_args} --source-factors-combine sum --conditional-decoder cd-prev-embed-concat --style-num-embed $style_embed"
	elif [[ $style_model == decoder-sum ]]; then
		model_args="${model_args} --source-factors-combine sum --conditional-decoder cd-prev-embed-sum"
	elif [[ $style_model == decoder-bos ]]; then
		model_args="${model_args} --source-factors-combine sum --conditional-decoder cd-bos-embed"
	fi;
fi;

if [[ $decode_gpu != "" ]]; then
	model_args="${model_args} --decode-and-evaluate-device-id $decode_gpu"
fi;

# Training
gpu_ids=$(echo $gpus | sed "s/,/ /g")
if [ ! -d $model_dir ]; then
	echo " * Training model-$i ..."
	python -m sockeye.train \
		-s $train_src \
		-t $train_tgt \
		-vs $dev_src \
		-vt $dev_tgt \
		-o $model_dir \
		--weight-tying \
		--weight-tying-type src_trg_softmax \
		--layer-normalization \
		--rnn-dropout-inputs .2:.2 \
		--rnn-dropout-states .2:.2 \
		--embed-dropout .2:.2 \
		--num-words 100000:100000 \
		--encoder rnn \
		--decoder rnn \
		--num-layers 1:1 \
		--rnn-residual-connections \
		--rnn-cell-type lstm \
		--rnn-num-hidden 512 \
		--num-embed 512:512 \
		--rnn-attention-type mlp \
		--max-seq-len $src_max_len:$tgt_max_len \
		--batch-type sentence \
		--batch-size 64 \
		--initial-learning-rate 0.001 \
		--checkpoint-frequency 1000 \
		--keep-last-params 30 \
		--max-num-checkpoint-not-improved 10 \
		--learning-rate-reduce-num-not-improved 4 \
		--decode-and-evaluate 2000 \
		--seed $seed \
		--disable-device-locking \
		--device-ids $gpu_ids \
		$model_args
fi;
