#!/bin/bash

root_dir=`dirname $0`
mkdir $root_dir/data

# === Installing Sockeye v1.16.6 (Sockeye requires python3)
# Adjust parameters according to the official instruction: https://github.com/awslabs/sockeye
cd $root_dir
git clone https://github.com/awslabs/sockeye.git
cd sockeye
git checkout 7485330 # This commit is v1.16.6
pip install . --no-deps -r requirements.gpu-cu90.txt

# === Installing Moses scripts
cd $root_dir
git clone https://github.com/moses-smt/mosesdecoder.git
mv mosesdecoder/scripts moses-scripts
rm -rf mosesdecoder

# === Installing BPE scripts (BPE requires python2)
cd $root_dir
git clone https://github.com/rsennrich/subword-nmt.git

# === Installing KenLM
cd $root_dir
git clone https://github.com/kpu/kenlm.git
cd kenlm
mkdir -p build
cd build
cmake ..
make -j 4

# === Obtaining the GYAFC corpus (train/dev/test/system_output)
# Follow the instruction on https://github.com/raosudha89/GYAFC-corpus to get the GYAFC corpus.
# Pre-process the GYAFC corpus
# - Combine data of two domains (E&M, F&R)
# - Tokenize data using:
#   moses-scripts/tokenizer/normalize-punctuation.perl -l en | moses-scripts/tokenizer/tokenizer.perl -l en -a -no-escape
# - Concatenate four tune-ref pairs to build the complete dev set
#   e.g. to build the dev set for formal->informal:
#        source=formal       +formal       +formal       +formal        (copy four times)
#        target=informal.ref0+informal.ref1+informal.ref2+informal.ref3 (concatenate four refs)
# Put files into data/
# - data/GYAFC.train.tok.formal
# - data/GYAFC.train.tok.informal
# - data/GYAFC.dev-to-formal.tok.formal     (target of the dev set, informal->formal)
# - data/GYAFC.dev-to-formal.tok.informal   (source of the dev set, informal->formal)
# - data/GYAFC.dev-to-informal.tok.formal   (source of the dev set, formal->informal)
# - data/GYAFC.dev-to-informal.tok.informal (target of the dev set, formal->informal)

# === Downloading cleaned OpenSubtitles2016 parallel data (train/dev/test)
cd $root_dir/data
wget https://obj.umiacs.umd.edu/mt-data/OpenSubtitles2016.en-fr.clean.tgz
tar -xf OpenSubtitles2016.en-fr.clean.tgz
rm OpenSubtitles2016.en-fr.clean.tgz
