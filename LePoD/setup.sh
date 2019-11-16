#!/bin/bash

root_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
software_dir=$root_dir/software
mkdir -p $software_dir

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

# === Installing Meteor-1.5
if [ ! -d $software_dir/meteor-1.5 ]; then
	cd $software_dir
	wget http://www.cs.cmu.edu/~alavie/METEOR/download/meteor-1.5.tar.gz
	tar -xzf meteor-1.5.tar.gz
	rm meteor-1.5.tar.gz
fi;
