#!/bin/bash

### Parameters
# ensemble_mode=False/True
# factor_mode=False/True

### Parallel decoding
if [ ! -f $decode_data_out ]; then
	decode_data_in_tmp_dir=$decode_data_out.chunks.input
	decode_data_out_tmp_dir=$decode_data_out.chunks.output
	mkdir -p $decode_data_out_tmp_dir
	
	if [[ $decode_gpu != "" ]]; then
		all_gpus=$gpus,$decode_gpu
	else
		all_gpus=$gpus
	fi;
	IFS=',' read -r -a gpu_array <<< "$all_gpus"
	gpu_n=${#gpu_array[@]}
	chunk_num=$((gpu_n*proc_per_gpu))
	if [ ! -d $decode_data_in_tmp_dir ]; then
		mkdir -p $decode_data_in_tmp_dir
		echo " * Splitting $decode_data_in into $chunk_num chunks ..."
		if [[ $factor_mode == True ]]; then
			decode_data_in_tmp=$decode_data_in_tmp_dir/input-factor
			paste $decode_data_in $decode_data_in.factor > $decode_data_in_tmp
			split -a 2 -dn l/$chunk_num $decode_data_in_tmp $decode_data_in_tmp_dir/input-factor.
			for i in $(seq -f "%02g" 0 $((chunk_num-1))); do
				cut -f1 $decode_data_in_tmp_dir/input-factor.$i > $decode_data_in_tmp_dir/input.$i
				cut -f2 $decode_data_in_tmp_dir/input-factor.$i > $decode_data_in_tmp_dir/factor.$i
			done;
		else
			split -a 2 -dn l/$chunk_num $decode_data_in $decode_data_in_tmp_dir/input.
		fi;
	fi;
	
	if [[ $ensemble_mode == True ]]; then
		translate_args="--models $model_list --ensemble-mode linear"
	else
		translate_args="--models $model_dir"
	fi
	
	for i in ${!gpu_array[@]}; do
		gpu_i=${gpu_array[i]}
		for j in $(seq 0 $((proc_per_gpu-1))); do
			chunk_i=`printf "%02d" $((i*proc_per_gpu+j))`
			if [[ $factor_mode == True ]]; then
				factor_args="--input-factors $decode_data_in_tmp_dir/factor.$chunk_i"
			else
				factor_args=""
			fi;
			if [ ! -f $decode_data_out_tmp_dir/output.$chunk_i ]; then
				( echo " * Starting decoding chunk-$chunk_i on GPU-$gpu_i ..."
				  python3 -m sockeye.translate \
					--input $decode_data_in_tmp_dir/input.$chunk_i   \
					--output $decode_data_out_tmp_dir/output.$chunk_i \
					$factor_args        \
					$translate_args      \
					--beam-size 5         \
					--batch-size 16        \
					--chunk-size 1024       \
					--disable-device-locking \
					--device-ids $gpu_i ) &
				  # cp $decode_data_in_tmp_dir/input.$chunk_i $decode_data_out_tmp_dir/output.$chunk_i ) &
			fi;
		done;
	done;
	wait

	echo " * Concatenating translations ..."
	for i in $(seq -f "%02g" 0 $((chunk_num-1))); do
		cat $decode_data_out_tmp_dir/output.$i >> $decode_data_out
	done;
	n_in=$(wc -l < $decode_data_in)
	n_out=$(wc -l < $decode_data_out)
	if [[ $n_in == $n_out ]]; then
		rm -r $decode_data_in_tmp_dir
		rm -r $decode_data_out_tmp_dir
		echo " * Decoding finished."
	else
		echo " * Decoding finished incorrectly."
		exit;
	fi;

	# exit; # if parallel decoding uses different #GPUs
fi;
