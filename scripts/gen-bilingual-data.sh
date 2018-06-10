#!/bin/bash

### Data selection
lang_ds=$lang_base
ds_dir=$bilingual_data_dir
select_data=$ds_dir/pool.select.$select_n.$lang_pos
if [[ $nods == True ]]; then
	select_data=$ds_dir/pool.top.$select_n
	head -n $select_n $pool.$bilingual_lang_src > $select_data.$bilingual_lang_src
	head -n $select_n $pool.$lang_ds > $select_data.$lang_ds
else
	. `dirname $0`/data-selection-ced.sh
fi;

### Cleaning selected parallel data
if [ ! -f $select_data.clean.$lang_ds ]; then
	echo " * Cleaning selected parallel data $select_data.* ..."
	$moses_scripts_path/training/clean-corpus-n.perl \
		-ratio 3        \
		$select_data     \
		$bilingual_lang_src $lang_ds \
		$select_data.clean \
		1 1000
fi;
if [[ $nods == True ]]; then
	ln -srf $select_data.clean.$bilingual_lang_src $ds_dir/bilingual.$bilingual_lang_src
	ln -srf $select_data.clean.$lang_ds $ds_dir/bilingual.$lang_ds
else
	ln -srf $select_data.clean.$bilingual_lang_src $ds_dir/$lang_pos.$bilingual_lang_src
	ln -srf $select_data.clean.$lang_ds $ds_dir/$lang_pos.$lang_ds
fi;
