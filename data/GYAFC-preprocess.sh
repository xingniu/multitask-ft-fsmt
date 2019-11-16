#!/bin/bash

for domain in Entertainment_Music Family_Relationships; do
	bitext_path=$GYAFC_path/$domain

	# Tokenization
	for type in train/informal train/formal tune/informal tune/informal.ref0 tune/informal.ref1 tune/informal.ref2 tune/informal.ref3 tune/formal tune/formal.ref0 tune/formal.ref1 tune/formal.ref2 tune/formal.ref3 test/informal test/formal; do
		if [ ! -f $bitext_path/$type.tok ]; then
			echo " * Tokenizing $domain/$type ..."
			cat $bitext_path/$type \
				| $moses_scripts_path/tokenizer/normalize-punctuation.perl -l en \
				| $moses_scripts_path/tokenizer/tokenizer.perl -l en -a -no-escape -threads 8 -lines 100000 \
				> $bitext_path/$type.tok
		fi;
	done;

	cd $bitext_path
	for lang in informal formal; do
		if [ ! -f train.tok.$lang ]; then
			ln -sf train/$lang.tok train.tok.$lang
		fi;
	done;

	for lang in informal formal; do
		if [[ $lang == informal ]]; then
			tolang=formal
		elif [[ $lang == formal ]]; then
			tolang=informal
		fi;
		if [ ! -f dev-to-$tolang.tok.$lang ]; then
			cat tune/$lang.tok tune/$lang.tok tune/$lang.tok tune/$lang.tok > dev-to-$tolang.tok.$lang
		fi;
		if [ ! -f dev-to-$tolang.tok.$tolang ]; then
			cat tune/$tolang.ref0.tok tune/$tolang.ref1.tok tune/$tolang.ref2.tok tune/$tolang.ref3.tok > dev-to-$tolang.tok.$tolang
		fi;
		if [ ! -f test-to-$tolang.$lang ]; then
			ln -sf test/$lang test-to-$tolang.$lang
		fi;
		if [ ! -f test-to-$tolang.tok.$lang ]; then
			ln -sf test/$lang.tok test-to-$tolang.tok.$lang
		fi;
		for i in $(seq 0 3); do
			if [ ! -f test-to-$tolang.$tolang$i ]; then
				ln -sf test/$tolang.ref$i test-to-$tolang.$tolang$i
			fi;
		done;
	done;
done;

# Combining datasets of all domains
bitext_path=$GYAFC_path/Combo
mkdir -p $bitext_path
for type in train.tok dev-to-formal.tok dev-to-informal.tok test-to-formal.tok test-to-informal.tok test-to-formal test-to-informal; do
	for lang in informal formal; do
		if [ ! -f $bitext_path/$type.$lang ]; then
			for dm in Entertainment_Music Family_Relationships; do
				if [ -f $GYAFC_path/$dm/$type.$lang ]; then
					echo " * Copying $dm/$type.$lang ..."
					cat $GYAFC_path/$dm/$type.$lang >> $bitext_path/$type.$lang
				fi;
			done;
		fi;
		for i in $(seq 0 3); do
			if [ ! -f $bitext_path/$type.$lang$i ]; then
				for dm in Entertainment_Music Family_Relationships; do
					if [ -f $GYAFC_path/$dm/$type.$lang$i ]; then
						echo " * Copying $dm/$type.$lang$i ..."
						cat $GYAFC_path/$dm/$type.$lang$i >> $bitext_path/$type.$lang$i
					fi;
				done;
			fi;
		done;
		if [ -f $bitext_path/$type.${lang}0 ] && [ ! -f $bitext_path/$type.$lang-all ]; then
			echo " * Merging $bitext_path/$type.${lang}*4 ..."
			paste -d'\n' $bitext_path/$type.${lang}0 $bitext_path/$type.${lang}1 $bitext_path/$type.${lang}2 $bitext_path/$type.${lang}3 > $bitext_path/$type.$lang-all
		fi;
	done;
done;
