#!/usr/bin/env python -*- coding: utf-8 -*-

import argparse
import sys

IN_PHRASE = -1

def categorize_tokens(tokens, alignment, exact_match):
    mat_tokens = [token for token, match in zip(tokens, alignment) if match is not None]
    sub_tokens = [token for token, match in zip(tokens, exact_match) if not match]
    return mat_tokens, sub_tokens

def get_alignment(alignments, tokens1, tokens2, punctuations):
    alignment1, alignment2 = [None] * len(tokens1), [None] * len(tokens2)
    exact_match1, exact_match2 = [False] * len(tokens1), [False] * len(tokens2)
    alignments.readline()
    alignments.readline()
    alignments.readline()
    alignments.readline()
    line = alignments.readline()
    while line != "\n":
        segs = line.split()
        span1 = segs[1].split(':')
        idx1, len1 = int(span1[0]), int(span1[1])
        span2 = segs[0].split(':')
        idx2, len2 = int(span2[0]), int(span2[1])
        ident = tokens1[idx1:idx1+len1] == tokens2[idx2:idx2+len2]
        if tokens1[idx1] not in punctuations:
            alignment1[idx1] = idx2
        exact_match1[idx1] = ident
        for d in range(1, len1):
            alignment1[idx1 + d] = IN_PHRASE
            exact_match1[idx1 + d] = ident
        if tokens2[idx2] not in punctuations:
            alignment2[idx2] = idx1
        exact_match2[idx2] = ident
        for d in range(1, len2):
            alignment2[idx2 + d] = IN_PHRASE
            exact_match2[idx2 + d] = ident
        line = alignments.readline()
    return alignment1, alignment2, exact_match1, exact_match2

def _get_new_idx(alignment):
    new_idx = [None] * len(alignment)
    counter = 0
    for idx, align in enumerate(alignment):
        if align is not None and align != IN_PHRASE:
            new_idx[idx] = counter
            counter += 1
    return new_idx, counter

def _get_distortion(alignment, length, new_idx):
    distortion = [None] * length
    counter = 0
    for align in alignment:
        if align is not None and align != IN_PHRASE:
            distortion[counter] = new_idx[align] - counter
            counter += 1
    return distortion

def get_distortion(alignment1, alignment2):
    new_idx1, length1 = _get_new_idx(alignment1)
    new_idx2, length2 = _get_new_idx(alignment2)
    assert length1 == length2
    distortion1 = _get_distortion(alignment1, length1, new_idx2)
    distortion2 = _get_distortion(alignment2, length2, new_idx1)
    return distortion1, distortion2

if __name__ == "__main__":
    parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('-a', '--alignment', required=True, help='the alignment file produced by Meteor-Aligner')
    parser.add_argument('-f', '--file', required=True, nargs=2, help='two input files of sequences to be compared')
    parser.add_argument('-d', '--digits', required=False, type=int, default=3,
                        help='number of digits to the right of the decimal point')
    parser.add_argument('-p', '--punctuations', required=False, default="",
                        help='exclude given punctuations in the alignment')
    parser.add_argument('-l', '--lowercase', required=False, action="store_true", help='compare lowercased sequences')
    parser.add_argument('-v', '--verbose', required=False, action="store_true", help='print scores for each pair')
    parser.add_argument('-r', '--prefix', required=False, help='prefix of output files')
    parser.add_argument('-s', '--simple', required=False, action="store_true", help='only print LePod scores')
    args = parser.parse_args()

    alignments = open(args.alignment)
    files = [open(f) for f in args.file]
    if args.prefix:
        led_file = open("%s.led" % args.prefix, 'w')
        pod_file = open("%s.pod" % args.prefix, 'w')
    decimal_format = "%."+str(args.digits)+"f"

    non_zero_substitution = non_zero_distortion = non_zero_counter = 0
    substitution_score_all = distortion_score_all = 0
    substitution_score_min = distortion_score_min = sys.maxsize
    substitution_score_max = distortion_score_max = -sys.maxsize
    for counter, lines in enumerate(zip(*files), start=1):
        if args.verbose:
            print("    RAW-1\t%s" % lines[0].strip())
            print("    RAW-2\t%s" % lines[1].strip())

        raw_tokens1 = lines[0].strip().lower().split() if args.lowercase else lines[0].strip().split()
        raw_tokens2 = lines[1].strip().lower().split() if args.lowercase else lines[1].strip().split()

        alignment1, alignment2, exact_match1, exact_match2 = get_alignment(alignments, raw_tokens1, raw_tokens2,
                                                                           set(args.punctuations))
        distortion1, distortion2 = get_distortion(alignment1, alignment2)
        mat_tokens1, sub_tokens1 = categorize_tokens(raw_tokens1, alignment1, exact_match1)
        mat_tokens2, sub_tokens2 = categorize_tokens(raw_tokens2, alignment2, exact_match2)

        substitution_score = (len(sub_tokens1)*1.0/len(raw_tokens1) + len(sub_tokens2)*1.0/len(raw_tokens2)) / 2
        substitution_score_all += substitution_score
        if substitution_score > 0:
            non_zero_substitution += 1

        distortion_score = 0
        if len(distortion1) > 0:
            max_ddt = cumulative_distortion = 0
            for dtt in distortion1:
                cumulative_distortion += dtt
                max_ddt = max(max_ddt, abs(dtt))
                if cumulative_distortion == 0:
                    distortion_score += max_ddt
                    max_ddt = 0
            distortion_score = distortion_score*1.0/len(distortion1)
            distortion_score_all += distortion_score
            if distortion_score > 0:
                non_zero_distortion += 1

        if distortion_score > 0 or substitution_score > 0:
            non_zero_counter += 1
        distortion_score_min = min(distortion_score_min, distortion_score)
        distortion_score_max = max(distortion_score_max, distortion_score)
        substitution_score_min = min(substitution_score_min, substitution_score)
        substitution_score_max = max(substitution_score_max, substitution_score)

        if args.verbose:
            print("MAT | SUB\t%s | %s" % (" ".join(mat_tokens1), " ".join(sub_tokens1)))
            print("MAT | SUB\t%s | %s" % (" ".join(mat_tokens2), " ".join(sub_tokens2)))
            print(("%d\tdistortion-score="+decimal_format+"   substitution-score="+decimal_format)
                  % (counter, distortion_score, substitution_score))
            print("="*100)
        if args.prefix:
            led_file.write((decimal_format+"\t%d\t%s\t%s\n") % (substitution_score, counter,
                                                                lines[0].strip(), lines[1].strip()))
            pod_file.write((decimal_format+"\t%d\t%s\t%s\n") % (distortion_score, counter,
                                                                lines[0].strip(), lines[1].strip()))

    if args.prefix:
        led_file.close()
        pod_file.close()

    if args.simple:
        print(("LeD="+decimal_format+" PoD="+decimal_format)
              % (substitution_score_all/counter, distortion_score_all/counter))
    else:
        print("LeD="+decimal_format % (substitution_score_all/counter))
        print("   min="+decimal_format % substitution_score_min)
        print("   max="+decimal_format % substitution_score_max)
        print("PoD="+decimal_format % (distortion_score_all/counter))
        print("   min="+decimal_format % distortion_score_min)
        print("   max="+decimal_format % distortion_score_max)
        print("%d pairs were read in total" % counter)
        percentile = non_zero_substitution*100.0/counter
        print("   %d pairs (%.2f%%) got non-zero LeD scores" % (non_zero_substitution, percentile))
        percentile = non_zero_distortion*100.0/counter
        print("   %d pairs (%.2f%%) got non-zero PoD scores" % (non_zero_distortion, percentile))
        percentile = 100-non_zero_counter*100.0/counter
        print("   %d pairs (%.2f%%) got all zero scores" % (counter - non_zero_counter, percentile))
