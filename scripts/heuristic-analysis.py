#!/usr/bin/env python -*- coding: utf-8 -*-

import argparse
import re

MODE_CHAR = "char"
MODE_TOKEN = "token"

# https://gist.github.com/nealrs/96342d8231b75cf4bb82
# https://en.wikipedia.org/wiki/Wikipedia:List_of_English_contractions
CONTRACTION_WORD = {
    "'cause": "because",
    "'d": " would",
    "'ll": " will",
    "'m": " am",
    "'re": " are",
    "'ve": " have"
}
CONTRACTION_PHRASE = {
    "ain't": "am not",
    "amn't": "am not",
    "aren't": "are not",
    "can't": "cannot",
    "couldn't": "could not",
    "daren't": "dare not",
    "daresn't": "dare not",
    "dasn't": "dare not",
    "didn't": "did not",
    "doesn't": "does not",
    "don't": "do not",
    "everyone's": "everyone is",
    "gimme": "give me",
    "giv'n": "given",
    "gonna": "going to",
    "hadn't": "had not",
    "gotta": "got to",
    "hadn't": "had not",
    "hasn't": "has not",
    "haven't": "have not",
    "he's": "he is",
    "how's": "how is",
    "isn't": "is not",
    "it's": "it is",
    "let's": "let us",
    "ma'am": "madam",
    "mayn't": "may not",
    "mightn't": "might not",
    "mustn't": "must not",
    "needn't": "need not",
    "ne'er": "never",
    "o'clock": "of the clock",
    "o'er": "over",
    " ol'": " old",
    "oughtn't": "ought not",
    "shan't": "shall not",
    "she's": "she is",
    "shouldn't": "should not",
    "somebody's": "somebody is",
    "someone's": "someone is",
    "something's": "something is",
    "that's": "that is",
    "there's": "there is",
    "this's": "this is",
    "wasn't": "was not",
    "weren't": "were not",
    "what'd": "what did",
    "what's": "what is",
    "when's": "when is",
    "where'd": "where did",
    "where's": "where is",
    "which's": "which is",
    "who's": "who is",
    "whom'st": "whom hast",
    "why'd": "why did",
    "why's": "why is",
    "won't": "will not",
    "wouldn't": "would not",
    "y'all": "you all"
}
# https://en.wikipedia.org/wiki/Interrogative_word
INTERROGATIVE_WORD = {"which", "what", "whose", "who", "whom", "what", "where", "whither", "whence", "when", "how",
                      "why", "whether", "whatsoever"}

# https://www.dailywritingtips.com/punctuating-so-at-the-beginning-of-a-sentence/
CONJUNCTION_WORD = {"so", "and", "but"}
INTERJECTION_WORD = {"well"}

# https://www.lawlessenglish.com/learn-english/grammar/questions-yes-no/
YESNO_WORD = {"am", "is", "are", "was", "were", "do", "does", "did", "have", "has"}

BOS_LIST = ["^"+w+" " for w in CONJUNCTION_WORD] + ["^"+w+", " for w in CONJUNCTION_WORD] + \
           ["^"+w+" " for w in INTERJECTION_WORD] + ["^"+w+", " for w in INTERJECTION_WORD]

def expand_contractions(text, contraction_dict, contraction_pattern):
    def replace(match):
        return contraction_dict[match.group(0)]
    return contraction_pattern.sub(replace, text)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('-f', '--file', required=True, nargs='+', help='input files of sequences to be compared')
    args = parser.parse_args()

    contraction_word_pattern = re.compile('(%s)' % '|'.join(CONTRACTION_WORD.keys()))
    contraction_phrase_pattern = re.compile('(%s)' % '|'.join(CONTRACTION_PHRASE.keys()))
    contraction_pattern = re.compile('(%s)' % '|'.join(list(CONTRACTION_WORD.keys())+list(CONTRACTION_PHRASE.keys())))
    wh_pattern = re.compile('(%s)' % '|'.join(INTERROGATIVE_WORD))
    bos_pattern = re.compile('(%s)' % '|'.join(BOS_LIST))
    quotation_pattern = re.compile('(")')
    yesno_pattern = re.compile('(%s)' % '|'.join(["^"+w+" " for w in YESNO_WORD]))

    pre_identical_counter = 0
    less_contraction_counter = 0
    contraction_ident_counter = 0
    remove_bos_counter = 0
    bos_ident_counter = 0
    more_quotation_counter = 0
    quotation_ident_counter = 0
    yesno_counter = 0
    possessive_counter = 0
    post_identical_counter = 0
    delta_length = 0.0
    files = [open(f) for f in args.file]
    for counter, raw_lines in enumerate(zip(*files), start=1):
        lines = [line.strip().lower() for line in raw_lines]
        delta_length += len(lines[1]) - len(lines[0])
        if lines[0] == lines[1]:
            pre_identical_counter += 1
        else:
            if lines[0] != lines[1]:
                contraction_n = [len(contraction_pattern.findall(line)) for line in lines]
                if contraction_n[0] > contraction_n[1]:
                    less_contraction_counter += 1
                lines[0] = expand_contractions(lines[0], CONTRACTION_PHRASE, contraction_phrase_pattern)
                lines[0] = expand_contractions(lines[0], CONTRACTION_WORD, contraction_word_pattern)
                lines[1] = expand_contractions(lines[1], CONTRACTION_PHRASE, contraction_phrase_pattern)
                lines[1] = expand_contractions(lines[1], CONTRACTION_WORD, contraction_word_pattern)
                if lines[0] == lines[1]:
                    contraction_ident_counter += 1
            if lines[0] != lines[1]:
                bos_n = [len(bos_pattern.findall(line)) for line in lines]
                if bos_n[0] == 1 and bos_n[1] == 0:
                    remove_bos_counter += 1
                lines[0] = bos_pattern.sub("", lines[0])
                lines[1] = bos_pattern.sub("", lines[1])
                if lines[0] == lines[1]:
                    bos_ident_counter += 1
            if lines[0] != lines[1]:
                quotation_n = [len(quotation_pattern.findall(line)) for line in lines]
                if quotation_n[0] < quotation_n[1]:
                    more_quotation_counter += 1
                lines[0] = quotation_pattern.sub("", lines[0])
                lines[1] = quotation_pattern.sub("", lines[1])
                if lines[0] == lines[1]:
                    quotation_ident_counter += 1
            if lines[0] == lines[1]:
                post_identical_counter += 1
            if lines[0] != lines[1] and lines[0][-1] == "?" and lines[1][-1] == "?":
                if yesno_pattern.search(lines[0]) is None and yesno_pattern.search(lines[1]) is not None:
                    yesno_counter += 1
            if lines[0] != lines[1]:
                for possessive in re.findall("[^ ]+'s|[^ ]+s'", lines[0]):
                    owner = possessive.split("'")[0]
                    if "of "+owner in lines[1] and possessive not in lines[1]:
                        possessive_counter += 1
                        print(raw_lines[0].strip())
                        print(raw_lines[1].strip())
                        print("-"*100)
                for possessive in re.findall("[^ ]+ of the [^ ?!.,\"]+", lines[1]):
                    tokens = possessive.split()
                    if tokens[3]+" "+tokens[0] in lines[0]:
                        possessive_counter += 1
                        print(raw_lines[0].strip())
                        print(raw_lines[1].strip())
                        print("-"*100)
                
    delta_length = delta_length/counter
    print("total=%d" % counter)
    print("pre_identical=%d" % pre_identical_counter)
    print("less_contraction=%d" % less_contraction_counter)
#    print("contraction_ident=%d" % contraction_ident_counter)
    print("remove_bos=%d" % remove_bos_counter)
#    print("bos_ident=%d" % bos_ident_counter)
    print("more_quotation=%d" % more_quotation_counter)
#    print("quotation_ident=%d" % quotation_ident_counter)
    print("post_identical=%d" % post_identical_counter)
    print("yesno=%d" % yesno_counter)
    print("possessive=%d" % possessive_counter)
    print("delta_length=%.2f" % delta_length)
