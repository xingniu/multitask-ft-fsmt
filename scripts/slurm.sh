#!/bin/bash
# Xing

host_list="clipgpu00 clipgpu01 clipgpu02 clipgpu03 materialgpu00 materialgpu01 cherokee"

if [[ $1 == check ]]; then
	for host in $host_list; do
		echo "ssh to $host"
		ssh -T $host << ENDHERE
		   gpustat
		   exit
ENDHERE
	done;
	exit;
fi;

gpu=$1 # gtxtitanx, gtxtitanxp, gtx1080ti, gtx1080ti-m00, gtx1080ti-m01, gpu
gpu_gres=$gpu:
cpu_n=8
if [[ $gpu == gtxtitanx ]] || [[ $gpu == gtxtitanxp ]]; then
	mem=64000
elif [[ $gpu == gtx1080ti ]]; then
	mem=42000
	srun_args="--exclude=materialgpu00,materialgpu01"
elif [[ $gpu == gtx1080ti-m01 ]]; then
	mem=32000
	gpu_gres=gtx1080ti:
	srun_args="--nodelist=materialgpu01"
elif [[ $gpu == gtx1080ti-m00 ]]; then
	mem=32000
	gpu_gres=gtx1080ti:
	cpu_n=2
	srun_args="--nodelist=materialgpu00"
elif [[ $gpu == "" ]] || [[ $gpu == gpu ]]; then
	mem=32000
	gpu_gres=""
	cpu_n=4
	srun_args="--exclude=materialgpu02"
fi;

if [[ $2 != "" ]]; then
	days=$2
	if (( $days > 4 )); then
		qos=gpu-epic
	elif (( $days > 1 )); then
		qos=gpu-long
	else
		qos=gpu-medium
	fi;
else
	days=4
	qos=gpu-long
fi;

if [[ $3 != "" ]]; then
	gpu_n=$3
	cpu_n=$((cpu_n*gpu_n))
	mem=$((mem*gpu_n))
else
	gpu_n=1
fi;

srun \
	--pty --qos=$qos --partition=gpu --gres=gpu:$gpu_gres$gpu_n \
	--job-name=FSMT \
	--cpus-per-task=$cpu_n \
	--mem=$mem \
	--time=$days-00:00:00 \
	$srun_args \
	bash

exit;

# install
SW_PATH=/fs/clip-scratch/xingniu/sockeye
VE_NAME=multitask-ft-fsmt
cd $SW_PATH
module load Python3/3.6.4
module load cuda/9.0.176
module load cudnn/v7.2.1
python3 ~/virtualenv/virtualenv.py --system-site-packages $VE_NAME
source $VE_NAME/bin/activate
cd /fs/clip-scratch/xingniu/multitask-ft-fsmt/software/sockeye
pip install -e . --no-deps
pip install -r requirements/requirements.gpu-cu90.txt

# launch
module load cuda/9.0.176
module load cudnn/v7.2.1
source /fs/clip-scratch/xingniu/sockeye/multitask-ft-fsmt/bin/activate

rsync -avz --chmod=ugo=rwX Dropbox/Workspace/github/multitask-ft-fsmt xingniu@context.umiacs.umd.edu:/fs/clip-scratch/xingniu/
rsync -avz --chmod=ugo=rwX Dropbox/Workspace/github/sockeye-lm/ xingniu@context.umiacs.umd.edu:/fs/clip-scratch/xingniu/multitask-ft-fsmt/software/sockeye/

sinfo -o "%30N %10A %1X*%2Y*%1Z=%5c %15C %10m %20f %35G %10P %E - %H"
squeue -o "%.10i %.10P %.15j %.10u %.8T %.10M %.11l %.6D %.16R %.16b %.4C %.6m"
squeue -o "%.10i %.10P %.15j %.10u %.8T %.10M %.11l %.6D %.16R %.16b %.4C %.6m" | grep --color=never "gpu"

bash /fs/clip-scratch/xingniu/multitask-ft-fsmt/scripts/main.sh -m -5 -t transfer -y none #
bash /fs/clip-scratch/xingniu/multitask-ft-fsmt/scripts/main.sh -m -5 -t transfer -y tag #
bash /fs/clip-scratch/xingniu/multitask-ft-fsmt/scripts/main.sh -m -5 -t transfer -y tag-src #
bash /fs/clip-scratch/xingniu/multitask-ft-fsmt/scripts/main.sh -m -5 -t transfer -y block-tag-src #
bash /fs/clip-scratch/xingniu/multitask-ft-fsmt/scripts/main.sh -m -5 -t transfer -y factor-concat #
bash /fs/clip-scratch/xingniu/multitask-ft-fsmt/scripts/main.sh -m -5 -t transfer -y factor-sum #
bash /fs/clip-scratch/xingniu/multitask-ft-fsmt/scripts/main.sh -m -5 -t transfer -y decoder-bias #
bash /fs/clip-scratch/xingniu/multitask-ft-fsmt/scripts/main.sh -m -5 -t transfer -y decoder-concat #
bash /fs/clip-scratch/xingniu/multitask-ft-fsmt/scripts/main.sh -m -5 -t transfer -y decoder-sum #
bash /fs/clip-scratch/xingniu/multitask-ft-fsmt/scripts/main.sh -m -5 -t transfer -y decoder-bos #

bash /fs/clip-scratch/xingniu/multitask-ft-fsmt/scripts/main.sh -m 1 -t translation -y none # NMT
bash /fs/clip-scratch/xingniu/multitask-ft-fsmt/scripts/main.sh -m 1 -t translation-unk-ds # DS-Tag
bash /fs/clip-scratch/xingniu/multitask-ft-fsmt/scripts/main.sh -m 1 -t translation-unk-transfer # Multi-Task
bash /fs/clip-scratch/xingniu/multitask-ft-fsmt/scripts/main.sh -m 1 -t translation-unk-transfer-ds # Multi-Task DS-Tag

bash /fs/clip-scratch/xingniu/multitask-ft-fsmt/scripts/main.sh -m 1 -t translation-unk-transfer -i oti # OTI
bash /fs/clip-scratch/xingniu/multitask-ft-fsmt/scripts/main.sh -m 1 -t translation-unk-transfer -i osi # OSI
