# multitask-ft-fsmt
Multi-Task Neural Models for Translating Between Styles Within and Across Languages -- Formality Transfer (FT) and Formality-Sensitive Machine Translation (FSMT).

This repository contains implementations for
- Xing Niu, Sudha Rao, and Marine Carpuat. "[Multi-Task Neural Models for Translating Between Styles Within and Across Languages](http://xingniu.org/pub/multitaskftfsmt_coling18.pdf)". COLING 2018.
```
@InProceedings{niu-rao-carpuat:2018:COLING2018,
  author    = {Niu, Xing  and  Rao, Sudha  and  Carpuat, Marine},
  title     = {Multi-Task Neural Models for Translating Between Styles Within and Across Languages},
  booktitle = {{COLING}},
  year      = {2018}
}
```

## Usage Instructions
1. Set-up -- Follow the instructions in [setup.sh](setup.sh) to obtain necessary software and data.
2. Training
```bash
Bi-FT-ensemble (Bi-directional FT + domain combination + ensemble decoding)
> bash scripts/main.sh -e
MultiTask-tag-style
> bash scripts/main.sh -m tag-style -k 12 -e -f
MultiTask-style
> bash scripts/main.sh -m style -k 12 -e -f
MultiTask-random
> bash scripts/main.sh -m random -k 12 -e -f
```
3. Evaluation -- Adjust parameters in [scripts/evaluate.sh](scripts/evaluate.sh)
```bash
> bash scripts/evaluate.sh
```

## System Output
We provide the system output for GYAFC/OpenSubtitles2016 test sets (see [setup.sh](setup.sh)).
- Formality Transfer (GYAFC)
  - Bi-FT-ensemble (Bi-directional FT + domain combination + ensemble decoding)
  - MultiTask-tag-style

- Formality-Sensitive Machine Translation (OpenSubtitles2016)
  - NMT-constraint
  - MultiTask-tag-style
  - MultiTask-style
  - MultiTask-random
  - PBMT-random
 