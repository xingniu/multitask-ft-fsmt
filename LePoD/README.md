# Lexical and Positional Differences (LePoD)
**Le**xical and **Po**sitional **D**ifferences (LePoD) score is used to quantify the surface differences between paraphrases.

| <img src="lepod.png" alt="A LePoD example" width="500"> |
|-|
| Comparing S1 and S2 with LePoD: hollow circles represent non-exact matched tokens, yielding a LeD score of ![LeD](https://latex.codecogs.com/svg.latex?%5Cinline%20%5Csmall%20%28%5Cfrac%7B7%7D%7B15%7D&plus;%5Cfrac%7B4%7D%7B12%7D%29%5Ctimes%5Cfrac%7B1%7D%7B2%7D%3D0.4). Given the alignment illustrated above, the PoD score is ![PoD](https://latex.codecogs.com/svg.latex?%5Cinline%20%5Csmall%20%5Cfrac%7B0&plus;3&plus;2&plus;0%7D%7B10%7D%3D0.5). |

We first compute the pairwise Lexical Difference (**LeD**) based on the percentages of tokens that are not found in both outputs. Formally,

![LeD](https://latex.codecogs.com/svg.latex?%5Csmall%20%5Ctextsc%7BLeD%7D%20%3D%20%5Cfrac%7B1%7D%7B2%7D%5Cleft%28%5Cfrac%7B%7CS_1%20%5Cbackslash%20S_2%7C%7D%7B%7CS_1%7C%7D&plus;%5Cfrac%7B%7CS_2%20%5Cbackslash%20S_1%7C%7D%7B%7CS_2%7C%7D%5Cright%29%2C)

where S1 and S2 is a pair of sequences and S1\S2 indicates tokens appearing in S1 but not in S2.

We then compute the pairwise Positional Difference (**PoD**). (1) We segment the sentence pairs into the longest sequence of phrasal units that are consistent with the word alignments. Word alignments are obtained using the [latest METEOR software](http://www.cs.cmu.edu/~alavie/METEOR/), which supports stem, synonym and paraphrase matches in addition to exact matches. (2) We compute the maximum distortion within each segment. To do these, we first re-index N aligned words and calculate distortions as the position differences (i.e., index2-index1 in the figure). Then, we keep a running total of the distortion array (d1, d2, ...), and do segmentation p=(di, ..., dj)∈P whenever the accumulation is zero (i.e., Σ p=0). Now we can define

![PoD](https://latex.codecogs.com/svg.latex?%5Csmall%20%5Ctextsc%7BPoD%7D%20%3D%20%5Cfrac%7B1%7D%7BN%7D%5Csum_%7Bp%5Cin%20P%7D%5Cmax%28%5Coperatorname%7Babs%7D%28p%29%29.)

In extreme cases, when the first word in S1 is reordered to the last position in S2, PoD score approaches 1. When words are aligned without any reordering, each alignment constitutes a segment and PoD equals 0.

## Usage Instructions
If you have already set up the multitask-ft-fsmt project, you are all set. Otherwise, please use [setup.sh](setup.sh) to install the necessary software.

An example of using LePoD is given in [example.sh](example.sh).

## Citation
Please cite the following paper if you use LePoD in your own work:
- Xing Niu, and Marine Carpuat. "[Controlling Neural Machine Translation Formality with Synthetic Supervision](http://xingniu.org/pub/syntheticfsmt_aaai20.pdf)". AAAI 2020. ([Appendix](http://xingniu.org/pub/syntheticfsmt_aaai20_appendix.pdf))
