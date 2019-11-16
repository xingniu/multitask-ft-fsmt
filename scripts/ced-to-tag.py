#!/usr/bin/env python -*- coding: utf-8 -*-

import argparse
import numpy as np

if __name__ == "__main__":
    parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--data', '-d', required=True, help='parallel data with CED scores in the first column')
    parser.add_argument('--pos', '-p', required=True, help='style of positive examples')
    parser.add_argument('--neg', '-n', required=True, help='style of negative examples')
    parser.add_argument('--output', '-o', required=True, nargs=2, help='output files')
    args = parser.parse_args()

    scores = [float(line.split("\t")[0]) for line in open(args.data)]
    ced_abs_mean = np.mean(np.abs(scores))
    src_neg_n = sum(1 for score in scores if score < -ced_abs_mean)
    src_pos_n = sum(1 for score in scores if score > ced_abs_mean)
    select_n = min(src_neg_n, src_pos_n)
    scores = sorted(scores)
    src_neg_threshold = scores[select_n-1]
    src_pos_threshold = scores[-select_n]
    output0, output1 = open(args.output[0], 'w'), open(args.output[1], 'w')
    for line in open(args.data):
        segs = line.strip().split("\t")
        score = float(segs[0])
        tag_src = tag_tgt = "<2unk> "
        if score <= src_neg_threshold:
            tag_src = "<2"+args.neg+"> "
            tag_tgt = "<2"+args.pos+"> "
        elif score >= src_pos_threshold:
            tag_src = "<2"+args.pos+"> "
            tag_tgt = "<2"+args.neg+"> "
        output0.write(tag_src+segs[1]+"\n")
        output1.write(tag_tgt+segs[2]+"\n")
    output0.close()
    output1.close()
