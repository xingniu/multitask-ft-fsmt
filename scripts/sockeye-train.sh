#!/bin/bash

# Updating the base model in fine-tuning mode
if [[ $fine_tuning_on == True ]]; then
	# Preparing the base model
	base_model_dir=$prev_sub_exp_dir/model-$i
	if [ ! -f $base_model_dir/params.bleu-1 ]; then
		python3 -m sockeye.average \
			-n 1          \
			--metric bleu  \
			--strategy best \
			--output $base_model_dir/params.bleu-1 \
			$base_model_dir
	fi;
	ln -srf $base_model_dir/params.bleu-1 $base_model_dir/params.best
	init_params_dir=$sub_exp_dir/init-params
	mkdir -p $init_params_dir
	params_name=params-$i
	model_args="--params $init_params_dir/$params_name"
	model_args="${model_args} --source-vocab $init_params_dir/vocab.json"
	model_args="${model_args} --target-vocab $init_params_dir/vocab.json"
			
	# Building the vocabulary
	if [ ! -f $init_params_dir/vocab.json ]; then
		python3 -m sockeye.vocab    \
			-i $train_src $train_tgt \
			-o $init_params_dir/vocab
	fi;

	# Updating weights in the base model
	if [ ! -f $init_params_dir/$params_name ]; then
		## Initializing new weights with given vocabulary
		python3 -m sockeye.init_embedding \
			-w $base_model_dir/params.best $base_model_dir/params.best      \
			-i $base_model_dir/vocab.src.json $base_model_dir/vocab.src.json \
			-o $init_params_dir/vocab.json $init_params_dir/vocab.json        \
			-n source_target_embed_weight target_output_bias                   \
			-f $init_params_dir/$params_name-new
		## Updating base model parameters with new weights
		echo " * Updating base model parameters with new weights ..."
		python3 `dirname $0`/update-mxnet-params.py \
			-o $base_model_dir/params.best      \
			-n $init_params_dir/$params_name-new \
			-s $init_params_dir/$params_name
		rm $init_params_dir/$params_name-new
	fi;
fi;

# Training
gpu_ids=$(echo $gpus | sed "s/,/ /g")
if [ ! -d $model_dir ]; then
	python3 -m sockeye.train \
		-s $train_src \
		-t $train_tgt \
		-vs $dev_src \
		-vt $dev_tgt \
		-o $model_dir \
		$model_args \
		--weight-tying \
		--weight-tying-type src_trg_softmax \
		--layer-normalization \
		--rnn-dropout-inputs .2:.2 \
		--rnn-dropout-states .2:.2 \
		--embed-dropout .2:.2 \
		--num-words 50000:50000 \
		--encoder rnn \
		--decoder rnn \
		--num-layers 1:1 \
		--rnn-cell-type lstm \
		--rnn-num-hidden 512 \
		--num-embed 512:512 \
		--rnn-attention-type mlp \
		--max-seq-len $src_max_len:$tgt_max_len \
		--batch-size 64 \
		--checkpoint-frequency 1000 \
		--keep-last-params 30 \
		--max-num-checkpoint-not-improved 8 \
		--decode-and-evaluate 1000 \
		--seed $seed \
		--disable-device-locking \
		--device-ids $gpu_ids
fi;
