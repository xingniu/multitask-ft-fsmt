#!/bin/bash

mkdir -p $corpus_path

if [[ $corpus_name == Europarl ]]; then
	lang_src=fr
	lang_tgt=en
	url=http://www.statmt.org/europarl/v7/$lang_src-$lang_tgt.tgz
	content=europarl-v7.$lang_src-$lang_tgt
	corpus=$corpus_name-v7.$lang_src-$lang_tgt
	cleaning=True
	#
	compressed_file=`basename $url`
	wget $url -O $corpus_path/$compressed_file
	tar -xvf $corpus_path/$compressed_file \
		-C $corpus_path \
		$content.$lang_src $content.$lang_tgt
	mv $corpus_path/$content.$lang_src $corpus_path/$corpus.$lang_src
	mv $corpus_path/$content.$lang_tgt $corpus_path/$corpus.$lang_tgt
	rm $corpus_path/$compressed_file
elif [[ $corpus_name == NewsCommentary ]]; then
	lang_src=en
	lang_tgt=fr
	url=http://data.statmt.org/news-commentary/v14/training/news-commentary-v14.$lang_src-$lang_tgt.tsv.gz
	content=news-commentary-v14.$lang_src-$lang_tgt.tsv
	corpus=$corpus_name-v14.$lang_src-$lang_tgt
	cleaning=True
	#
	compressed_file=`basename $url`
	wget $url -O $corpus_path/$compressed_file
	gzip -dc $corpus_path/$compressed_file \
		> $corpus_path/$content
	cut -f1 $corpus_path/$content > $corpus_path/$corpus.$lang_src
	cut -f2 $corpus_path/$content > $corpus_path/$corpus.$lang_tgt
	rm $corpus_path/$content
	rm $corpus_path/$compressed_file
elif [[ $corpus_name == WMT14 ]]; then
	lang_src=fr
	lang_tgt=en
	url=http://www.statmt.org/wmt14/test-full.tgz
	src_name=test-full/newstest2014-$lang_src$lang_tgt-src.$lang_src.sgm
	tgt_name=test-full/newstest2014-$lang_src$lang_tgt-ref.$lang_tgt.sgm
	corpus=newstest2014.$lang_src-$lang_tgt
	cleaning=False
	#
	compressed_file=`basename $url`
	wget $url -O $corpus_path/$compressed_file
	tar -xvf $corpus_path/$compressed_file \
		-C $corpus_path \
		$src_name $tgt_name
	cat $corpus_path/$src_name | sed -e "s/<[^>]*>//g" | sed '/^$/d' > $corpus_path/$corpus.$lang_src
	cat $corpus_path/$tgt_name | sed -e "s/<[^>]*>//g" | sed '/^$/d' > $corpus_path/$corpus.$lang_tgt
	rm -r $corpus_path/test-full
	rm $corpus_path/$compressed_file
elif [[ $corpus_name == MSLT ]]; then
	lang_src=en
	lang_tgt=fr
	corpus=MSLT.$lang_src-$lang_tgt.test-clean
	cleaning=False
	#
	data_prefix=MSLT_Corpus
	if [ ! -f $corpus_path/$data_prefix.zip ] && [ ! -f $corpus_path/$data_prefix.tgz ]; then
		wget https://download.microsoft.com/download/1/4/8/1489BF45-93AA-4B38-B4DA-5CA5678B2121/MSLT_Corpus.zip \
			-O $corpus_path/$data_prefix.zip
		bash $nlp_util_path/MSLT-repack.sh $corpus_path/$data_prefix.zip
		rm $corpus_path/$data_prefix.zip
	fi;
	python $nlp_util_path/MSLT-extract.py \
		-c test     \
		-s $lang_src \
		-t $lang_tgt  \
		-f $corpus_path/$data_prefix.tgz \
		-o $corpus_path/$corpus.temp
	paste $corpus_path/$corpus.temp.$lang_src $corpus_path/$corpus.temp.$lang_tgt \
		| sort -u | shuf | sed '/_x/d' \
		| python $nlp_util_path/bitext-cleaning.py -i \
		> $corpus_path/$corpus.temp.both
	cut -f1 $corpus_path/$corpus.temp.both > $corpus_path/$corpus.$lang_src
	cut -f2 $corpus_path/$corpus.temp.both > $corpus_path/$corpus.$lang_tgt
	rm $corpus_path/$corpus.temp*
fi;

# Tokenization
for lang in $lang_src $lang_tgt; do
	if [ ! -f $corpus_path/$corpus.tok.$lang ]; then
		echo " * Tokenizing $corpus.$lang ..."
		cat $corpus_path/$corpus.$lang \
			| $moses_scripts_path/tokenizer/remove-non-printing-char.perl      \
			| $moses_scripts_path/tokenizer/normalize-punctuation.perl -l $lang \
			| $moses_scripts_path/tokenizer/tokenizer.perl -l $lang -a -no-escape -threads 8 -lines 100000 \
			> $corpus_path/$corpus.tok.$lang
	fi;
done;

# Cleaning
if [[ $cleaning == True ]]; then
	if [ ! -f $corpus_path/$corpus.clean.tok.$lang_tgt ]; then
		echo " * Cleaning $corpus.tok.* ..."
		paste $corpus_path/$corpus.tok.$lang_src $corpus_path/$corpus.tok.$lang_tgt \
			| sort -u | shuf \
			| python $nlp_util_path/bitext-identical-pairs.py -t 0.5 -i -p -l \
			| python $nlp_util_path/bitext-cleaning.py -r 2.0 -u \
			> $corpus_path/$corpus.clean.tok.both
		cut -f1 $corpus_path/$corpus.clean.tok.both > $corpus_path/$corpus.clean.tok.$lang_src
		cut -f2 $corpus_path/$corpus.clean.tok.both > $corpus_path/$corpus.clean.tok.$lang_tgt
		rm $corpus_path/$corpus.clean.tok.both
	fi;
fi;
