# Multi-Task Neural Models for FSMT and FT
Multi-Task Neural Models for Translating Between Styles Within and Across Languages:
- Formality Transfer (FT)
- Formality-Sensitive Machine Translation (FSMT)
- FSMT with Synthetic Supervision

This repository contains implementations for
- Xing Niu, Sudha Rao, and Marine Carpuat. "[Multi-Task Neural Models for Translating Between Styles Within and Across Languages](http://xingniu.org/pub/multitaskftfsmt_coling18.pdf)". COLING 2018.
- Xing Niu, and Marine Carpuat. "[Controlling Neural Machine Translation Formality with Synthetic Supervision](http://xingniu.org/pub/syntheticfsmt_aaai20.pdf)". AAAI 2020. ([Appendix](http://xingniu.org/pub/syntheticfsmt_aaai20_appendix.pdf))

## Usage Instructions

#### Set-Up
Read and follow the instructions in [setup.sh](setup.sh) to obtain the necessary software and data.

#### Machine Translation Models

| <br>Model<br>&nbsp; | WMT<br>Informal<br>BLEU | WMT<br>Formal<br>BLEU | WMT<br><br>LeD | WMT<br><br>PoD | MSLT<br>Informal<br>BLEU | MSLT<br>Formal<br>BLEU | MSLT<br><br>LeD | MSLT<br><br>PoD |
|---------------------|------------------------:|----------------------:|---------------:|---------------:|-------------------------:|-----------------------:|----------------:|---------------------:|
| NMT                     | 28.63 | 28.63 |     0 |     0 | 47.83 | 47.83 |     0 |    0 |
| NMT DS-Tag              | 28.24 | 28.95 |  9.27 |  6.44 | 47.60 | 47.24 |  8.18 | 1.10 |
| Multi-Task              | 27.75 | 28.39 | 10.89 |  7.76 | 47.55 | 45.08 | 11.97 | 1.41 |
| Multi-Task DS-Tag       | 27.65 | 29.12 | 11.51 |  8.35 | 47.46 | 46.66 | 10.29 | 1.54 |
| Online Target Inference | 27.70 | 28.53 | 10.97 |  7.25 | 46.64 | 43.23 | 12.40 | 1.63 |
| Online Style Inference  | 26.67 | 28.65 | 14.53 | 12.58 | 45.46 | 44.16 | 14.52 | 2.19 |

```bash
NMT
> bash scripts/main.sh -m 1 -t translation -y none
NMT DS-Tag
> bash scripts/main.sh -m 1 -t translation-unk-ds
Multi-Task
> bash scripts/main.sh -m 1 -t translation-unk-transfer
Multi-Task DS-Tag
> bash scripts/main.sh -m 1 -t translation-unk-transfer-ds
Online Target Inference
> bash scripts/main.sh -m 1 -t translation-unk-transfer -i oti
Online Style Inference
> bash scripts/main.sh -m 1 -t translation-unk-transfer -i osi
```

#### Formality Transfer Benchmark Models

| Model | TYPE (cmd) | Informal->Formal | Formal->Informal | Informal->Informal | Formal->Formal |
|-------|------------|-----------------:|-----------------:|-------------------:|---------------:|
| None          | none           | 70.63 ± 0.23 | 37.00 ± 0.18 | 54.54 ± 0.44 | 58.98 ± 0.93 |
| Tag-Src       | tag-src        | 72.16 ± 0.34 | 37.67 ± 0.11 | 66.87 ± 0.58 | 78.78 ± 0.37 |
| Tag-Src-Block | block-tag-src  | 72.00 ± 0.05 | 37.38 ± 0.12 | 65.46 ± 0.29 | 76.72 ± 0.39 |
| Tag-Src-Tgt   | tag            | 72.29 ± 0.23 | 37.62 ± 0.37 | 67.81 ± 0.41 | 79.34 ± 0.55 |
| Factor-Concat | factor-concat  | 72.47 ± 0.11 | 37.62 ± 0.26 | 67.03 ± 0.36 | 79.80 ± 0.38 |
| Factor-Sum    | factor-sum     | 72.43 ± 0.29 | 37.78 ± 0.26 | 67.24 ± 0.56 | 80.34 ± 0.46 |
| Pred-Concat   | decoder-concat | 72.35 ± 0.16 | 37.62 ± 0.13 | 66.69 ± 0.21 | 77.85 ± 0.31 |
| Pred-Sum      | decoder-sum    | 72.02 ± 0.30 | 37.41 ± 0.17 | 66.15 ± 0.41 | 77.62 ± 0.28 |
| BOS           | decoder-bos    | 72.08 ± 0.22 | 37.56 ± 0.13 | 66.40 ± 0.23 | 77.43 ± 0.34 |
| Bias          | decoder-bias   | 71.58 ± 0.31 | 37.52 ± 0.15 | 63.66 ± 0.51 | 73.24 ± 0.55 |

```bash
> bash scripts/main.sh -m -5 -t transfer -y TYPE
```

## Lexical and Positional Differences (LePoD)
See [the LePoD directory](LePoD).
