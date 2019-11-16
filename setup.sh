#!/bin/bash

root_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
data_dir=$root_dir/data
software_dir=$root_dir/software
mkdir -p $software_dir

# === Installing Sockeye (forked from v1.18.82)
# Note: Sockeye requires python3
sockeye_path=$software_dir/sockeye
if [ ! -d $sockeye_path ]; then
	cd $software_dir
	git clone https://github.com/xingniu/sockeye.git
	cd $sockeye_path
	git checkout style-mt
	# See the detailed instruction on https://github.com/xingniu/sockeye/blob/style-mt/docs/setup.md
	pip install . --no-deps -r requirements/requirements.gpu-cu90.txt
fi;

# === Installing Moses scripts (commit: 06f519d)
moses_scripts_path=$software_dir/moses-scripts
if [ ! -d $moses_scripts_path ]; then
	cd $software_dir
	git clone https://github.com/moses-smt/mosesdecoder.git
	cd mosesdecoder
	git checkout 06f519d
	cd $software_dir
	mv mosesdecoder/scripts moses-scripts
	rm -rf mosesdecoder
fi;

# === Installing BPE scripts (commit: d21ced8)
if [ ! -d $software_dir/subword-nmt ]; then
	cd $software_dir
	git clone https://github.com/rsennrich/subword-nmt.git
	cd subword-nmt
	git checkout d21ced8
fi;

# === Installing KenLM
if [ ! -d $software_dir/kenlm ]; then
	cd $software_dir
	git clone https://github.com/kpu/kenlm.git
	cd kenlm
	mkdir -p build
	cd build
	cmake ..
	make -j 4
fi;

# === Installing Meteor-1.5
if [ ! -d $software_dir/meteor-1.5 ]; then
	cd $software_dir
	wget http://www.cs.cmu.edu/~alavie/METEOR/download/meteor-1.5.tar.gz
	tar -xzf meteor-1.5.tar.gz
	rm meteor-1.5.tar.gz
fi;

# === Installing nlp-util
nlp_util_path=$software_dir/nlp-util
if [ ! -d $nlp_util_path ]; then
	cd $software_dir
	git clone https://github.com/xingniu/nlp-util.git
fi;

# === Pre-processing the GYAFC corpus (train/dev/test/system_output)
# Follow the instruction on https://github.com/raosudha89/GYAFC-corpus to get the GYAFC corpus.
# Copy GYAFC_Corpus.zip into /data
if [ ! -f $data_dir/GYAFC_Corpus.zip ]; then
	echo "Please copy GYAFC_Corpus.zip into /data"
	exit;
fi;
GYAFC_path=$data_dir/GYAFC_Corpus
if [ ! -d $GYAFC_path ]; then
	cd $data_dir
	unzip GYAFC_Corpus.zip
	rm -rf __MACOSX
	. GYAFC-preprocess.sh
fi;

# === Downloading cleaned OpenSubtitles2016 parallel data (train/dev/test)
OpenSubtitles2016_path=$data_dir/OpenSubtitles2016
if [ ! -d $OpenSubtitles2016_path ]; then
	cd $data_dir
	wget https://obj.umiacs.umd.edu/mt-data/OpenSubtitles2016.en-fr.16M.tgz
	tar -xf OpenSubtitles2016.en-fr.16M.tgz
	rm OpenSubtitles2016.en-fr.16M.tgz
fi;

# === Downloading and pre-processing the Europarl-v7 corpus
corpus_path=$data_dir/Europarl-v7
if [ ! -d $corpus_path ]; then
	cd $data_dir
	corpus_name=Europarl
	. corpus-preprocess.sh
fi;

# === Downloading and pre-processing the NewsCommentary-v14 corpus
corpus_path=$data_dir/NewsCommentary-v14
if [ ! -d $corpus_path ]; then
	cd $data_dir
	corpus_name=NewsCommentary
	. corpus-preprocess.sh
fi;

# === Downloading and pre-processing the WMT14 test set
corpus_path=$data_dir/WMT14
if [ ! -d $corpus_path ]; then
	cd $data_dir
	corpus_name=WMT14
	. corpus-preprocess.sh
fi;

# === Downloading and pre-processing the MSLT test set
corpus_path=$data_dir/MSLT
if [ ! -d $corpus_path ]; then
	cd $data_dir
	corpus_name=MSLT
	. corpus-preprocess.sh
fi;
