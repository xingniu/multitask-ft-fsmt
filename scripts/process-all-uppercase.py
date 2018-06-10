#!/usr/bin/env python -*- coding: utf-8 -*-

import fileinput

if __name__ == "__main__":
    for line in fileinput.input([]):
        line = line.strip()
        if line.isupper():
            print(line.lower().capitalize())
        else:
            print(line)
