#!/usr/bin/env python3
"""The BC versions CI runs and the preprocessor symbols of each, derived from one list of released minors.

    ci-legs.py matrix [--version V]   the prepare job's matrix: {"include": [{bc_version, leg, runtime, preprocessor_symbols}]}
    ci-legs.py symbols VERSION        the preprocessor symbols of VERSION, comma-separated
    ci-legs.py released               the released minors, as a JSON list

WHY. The list of released minors (.github/released-minors.txt) is the only place that names minors. Before it, ci.yml
typed the default legs and looped over the majors twice, and nightly-windows.yml typed the same rule twice more.
al-runtime-rs derives the same symbols in its own code and refuses a bump when the results manifest (provenance.py
manifest, which records the list and each version's symbols) disagrees with it (its ADR-078, point 3).

matrix: without --version, one leg per major from 27 on: the newest released minor of that major. With --version (the
bc_version input of a dispatched run), that version alone; it may be an insider build that is not in the list, or a
full build (28.5.54151.58194: bc_version keeps the build, the symbols are those of its minor).

symbols: BC<n>PLUS for every major n from 27 to the version's major, BC<n>_<m>PLUS for every released minor n.m with m
of at least 1 at or below the version (in version order across majors: 30.0 gets BC29_1PLUS), and for a version not in
the list its own BC<n>_<m>PLUS when its minor is at least 1. There is no BC<n>_0PLUS: BC<n>PLUS means n.0 or later.

runtime: the app runtime of a leg (27 -> 16.1, 28 -> 17.1, later -> 18.0); some code compiles under one runtime only.
"""
import argparse
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
LIST = os.path.join(os.path.dirname(HERE), 'released-minors.txt')
FIRST_MAJOR = 27
RUNTIME = {27: '16.1', 28: '17.1'}
DEFAULT_RUNTIME = '18.0'
VERSION = re.compile(r'^([0-9]+)\.([0-9]+)$')
BUILD = re.compile(r'^([0-9]+\.[0-9]+)\.[0-9]+\.[0-9]+$')  # a full build: 28.5.54151.58194


def parse(v):
    """'29.1' -> (29, 1). SystemExit on any other shape, or a major before 27."""
    m = VERSION.match(v.strip())
    if not m:
        raise SystemExit('ci-legs: %r is not a BC version of the form <major>.<minor>' % v)
    major, minor = int(m.group(1)), int(m.group(2))
    if major < FIRST_MAJOR:
        raise SystemExit('ci-legs: BC %s is before %d.0, the first version the corpus runs' % (v, FIRST_MAJOR))
    return major, minor


def released(text=None):
    """The released minors of the list file (or of text), as (major, minor) in version order. SystemExit on a bad
    line, a duplicate or an empty list."""
    if text is None:
        with open(LIST) as f:
            text = f.read()
    out = []
    for line in text.split('\n'):
        line = line.split('#', 1)[0].strip()
        if line:
            out.append(parse(line))
    if not out:
        raise SystemExit('ci-legs: %s lists no released minor' % LIST)
    if len(set(out)) != len(out):
        raise SystemExit('ci-legs: %s lists a minor twice' % LIST)
    return sorted(out)


def name(v):
    return '%d.%d' % v


def symbols(version, minors):
    """The preprocessor symbols of version ((major, minor)), in version order."""
    major, minor = version
    out = []
    for n in range(FIRST_MAJOR, major + 1):
        out.append('BC%dPLUS' % n)
        known = sorted(m for (j, m) in minors if j == n and m >= 1 and (j, m) <= version)
        if n == major and minor >= 1 and minor not in known:
            known.append(minor)
        out.extend('BC%d_%dPLUS' % (n, m) for m in known)
    return out


def leg(version, minors, given=None):
    return {'bc_version': given or name(version), 'leg': str(version[0]), 'runtime': RUNTIME.get(version[0], DEFAULT_RUNTIME),
            'preprocessor_symbols': ','.join(symbols(version, minors))}


def matrix(minors, version=None):
    """version: None (the default legs) or the bc_version input, a minor or a full build."""
    if version is not None:
        b = BUILD.match(version.strip())
        return {'include': [leg(parse(b.group(1) if b else version), minors, version.strip())]}
    newest = {}
    for v in minors:
        newest[v[0]] = max(newest.get(v[0], v), v)
    return {'include': [leg(newest[j], minors) for j in sorted(newest)]}


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    sub = ap.add_subparsers(dest='cmd', required=True)
    m = sub.add_parser('matrix')
    m.add_argument('--version', default='', help='one version or full build instead of the default legs (empty: the default legs)')
    s = sub.add_parser('symbols')
    s.add_argument('version')
    sub.add_parser('released')
    a = ap.parse_args(argv)
    minors = released()
    if a.cmd == 'matrix':
        print(json.dumps(matrix(minors, a.version or None), separators=(',', ':')))
    elif a.cmd == 'symbols':
        print(','.join(symbols(parse(a.version), minors)))
    else:
        print(json.dumps([name(v) for v in minors]))
    return 0


if __name__ == '__main__':
    sys.exit(main())
