#!/usr/bin/env python -*- coding: utf-8 -*-

import argparse
import mxnet as mx

if __name__ == "__main__":
    parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--old', '-o', required=True, help='path to old parameters')
    parser.add_argument('--new', '-n', required=True, help='path to new parameters')
    parser.add_argument('--save', '-s', required=True, help='path for saving updated parameters')
    args = parser.parse_args()

    params = mx.nd.load(args.old)
    params_new = mx.nd.load(args.new)
    for key in params_new.keys():
        params[key] = params_new[key]
    mx.nd.save(args.save, params)
