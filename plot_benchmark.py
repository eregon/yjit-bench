#!/usr/bin/env python3

# Based on https://github.com/Shopify/yjit-metrics/blob/plotting_scripts_vmil2021/plot_benchmarks.py

import argparse
import numpy as np
from scipy import stats
import matplotlib.pyplot as plt
from matplotlib.ticker import StrMethodFormatter, MaxNLocator
from pathlib import Path
import re

parser = argparse.ArgumentParser()
parser.add_argument('--out_file', default='benchmarks.png')
parser.add_argument('input_files', nargs='*')
args = parser.parse_args()

def pretty_engine(engine):
    engine = engine.replace('-', ' ')
    engine = re.sub('^ruby ', '', engine)
    engine = re.sub('^(jruby \d+\.\d+).*', '\\1', engine)
    engine = re.sub('^jruby.*', 'jruby', engine)
    engine = re.sub(' ee$', '', engine)
    engine = engine.replace('truffleruby ', 'truffleruby\n')
    engine = engine.replace('truffleruby\njvm', 'truffleruby')
    engine = re.sub('^(\d+\.\d+)\.\d+', '\\1', engine)
    engine = re.sub('^3.1 (mjit|yjit)$', '\\1', engine)
    return engine

def engine_order(file):
    return (file
        .replace('jruby', 'sruby') # sort JRuby after CRuby
        .replace('-mjit', '.mjit') # sort MJIT after interpreter
        .replace('-yjit', '.yjit') # sort YJIT after interpreter
        .replace('jvm-ee', 'zvm-ee')) # sort JVM EE after Native EE

baseline = pretty_engine("ruby-3.1.0")

files = args.input_files
files = [file for file in files if 'results-' in file]
# files = [file for file in files if '2.0.0' not in file]
files = [file for file in files if 'truffleruby-native' not in file]
files.sort(key=engine_order)

bench_name = Path(files[0]).parent.stem

engine_results = {}

for filename in files:
    with open(filename) as f:
        lines = f.readlines()

    times = [float(line) for line in lines[1:]]
    # Take the second half of results, the first half is warmup
    times = times[len(times)//2:]

    engine = Path(filename).stem.replace('results-', '')
    engine = pretty_engine(engine)

    bench_values = times
    engine_results[engine] = times

yvalue_per_engine = {}
stddev_per_engine = {}
mad_per_engine = {}
baseline_median = np.median(engine_results[baseline])

for engine, results in engine_results.items():
    speedups = baseline_median / results

    # Use robust estimators, so mean->median and no stddev->median absolute deviation
    yvalue_per_engine[engine] = np.median(speedups)
    stddev_per_engine[engine] = np.std(speedups)
    mad_per_engine[engine] = stats.median_abs_deviation(speedups)

engines = list(yvalue_per_engine.keys())

# Generate the plot
fig = plt.figure()
fig, ax = plt.subplots()

x = np.arange(len(engines)) # the label locations
plt.xticks(rotation=0)
ax.set_xticks(x)
ax.set_xticklabels(engines)

ax.ticklabel_format(axis='y', useOffset=False, style='plain')

colors = {
    'jruby': 'tab:blue',
    'mjit': 'tab:orange',
    '3.0': 'tab:green',
    'truffleruby': 'tab:red',
    'yjit': 'tab:purple',
    'unused': 'tab:brown',
    'unused': 'tab:pink',
    '2.0': 'tab:gray',
    '2.7': 'tab:olive',
    '3.1': 'tab:cyan'
}

bar_width = 1.0 # 0.8

for engine_idx, engine in enumerate(yvalue_per_engine.keys()):
    y = yvalue_per_engine[engine]
    # yerr = stddev_per_engine[engine]
    yerr = mad_per_engine[engine]

    color = colors.get(engine, None)
    ax.bar(engine_idx, y, yerr=yerr, capsize=5, width=bar_width, label=engine, color=color)
    ax.annotate("%.2f" % y, xy=(engine_idx, y+yerr), ha='center', va='bottom')

# ax.axhline(1, color='black', alpha=0.25)

ax.set_axisbelow(True)
ax.yaxis.set_major_locator(MaxNLocator(11))
ax.yaxis.grid(True, color='grey', alpha=0.25)

ax.set_ylabel('Speedup compared to ' + baseline)
title = bench_name
if title == 'geomean':
    title = 'Geometric mean over all macro benchmarks'
plt.title(title)

fig.tight_layout()

# w, h = 800, 500
# wi, hi = fig.get_size_inches()
# fig.set_size_inches(hi*(w/h), hi)
# plt.savefig(args.out_file, dpi=h/hi)

plt.savefig(args.out_file, dpi=120)
