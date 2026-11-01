#!/usr/bin/env python3
"""Split a CI leg's test codeunits into shards, each run in a BC container of its own, and merge the shards' JUnit.

    ci-shards.py measure --junit MAJOR=FILE ... --shards N --app DIR [--range-start ID] [--source TEXT] --file FILE
    ci-shards.py plan --ci-yml FILE --versions JSON --file FILE --event NAME [--selection FILE] [--github]
    ci-shards.py merge --out FILE IN ...

WHY. The "Run AL tests" step of the al-language legs ran about 53 minutes in one container (master run 41270764562:
3051 s on 27.5, 2494 s on 28.5, 3175 s on 29.0), and the run waited for the slowest leg. The codeunits are independent
of each other's order (bc-linux runs them in an order that is not fixed), so a leg can run them in N containers at once
and merge the results. Each container still compiles and publishes every app, so a shard costs about 9 to 12 minutes of
setup: more shards are not free (CONTRIBUTING.md, "Shards in CI").

measure: reads the al-language JUnit file of a full run per BC major and writes, per major, the first codeunit id of
each shard to FILE (.github/ci-shards.json). A shard is a contiguous id range, so a new codeunit falls into the shard of
its neighbours and the shards need no edit when tests are added. The ranges are balanced by wall time per codeunit:
the time from its start to the next codeunit's start in run order (the JUnit timestamps), which includes the runner's
cost per codeunit that the testsuite time leaves out. Rerun it when the shards drift apart (the run summary of each
shard shows its time).

plan: the shards each leg of a run runs, as the job output `shards`: {bc_version: {test app dir: [{"n": "1 of 3",
"range": codeunit_range}]}}. An app without entry in FILE runs as one shard. A full run gives each shard its id range,
cut down to the job's codeunit_range. A subset run (select-tests.py --json, its `selection`) gives each shard the
selected codeunits of its range plus the app's sentinel; a shard with no selected codeunit does not run. On a pull
request an app whose selection is its sentinel only (nothing in it is affected) gets no shard at all, and its leg
reports success without starting BC; a dispatched subset run (the CI batcher) still runs the sentinel.

merge: merges JUnit files into one, in the order given. A codeunit that appears again in a later file (the shard of a
re-run) replaces the earlier result in place. The totals are summed again.
"""
import argparse
import datetime
import importlib.util
import json
import os
import sys
import xml.etree.ElementTree as ET

TOP = 2 ** 31 - 1
HERE = os.path.dirname(os.path.abspath(__file__))


def _select_tests():
    spec = importlib.util.spec_from_file_location('select_tests', os.path.join(HERE, 'select-tests.py'))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def parse_ci(text):
    """The test jobs of ci.yml as select-tests.py reads them: [{job, test_app_dirs, range, key}]."""
    return _select_tests().parse_ci(text)


# ---------- id spans ----------

def spans(expr):
    out = []
    for part in (expr or '').replace('|', ',').split(','):
        part = part.strip()
        if part:
            lo, _, hi = part.partition('..')
            out.append((int(lo), int(hi or lo)))
    return out


def norm(sp):
    out = []
    for lo, hi in sorted(sp):
        if out and lo <= out[-1][1] + 1:
            out[-1] = (out[-1][0], max(out[-1][1], hi))
        else:
            out.append((lo, hi))
    return out


def intersect(a, b):
    return [(max(x, y), min(p, q)) for x, p in a for y, q in b if max(x, y) <= min(p, q)]


def fmt(sp):
    return '|'.join(str(lo) if lo == hi else '%d..%d' % (lo, hi) for lo, hi in sp)


def shard_spans(starts):
    """Shard i covers starts[i] up to the next start; the first reaches down to 0 and the last up to TOP."""
    return [(0 if i == 0 else s, (starts[i + 1] - 1) if i + 1 < len(starts) else TOP) for i, s in enumerate(starts)]


# ---------- measure ----------

def _ts(text):
    return datetime.datetime.fromisoformat(text.replace('Z', '+00:00')).timestamp()


def wall_costs(path):
    """{codeunit id: seconds}: time from its start to the next codeunit's start, in run order."""
    rows = []
    for i, s in enumerate(ET.parse(path).getroot().iter('testsuite')):
        name = (s.get('name') or '').split()
        if len(name) == 2 and name[0] == 'Codeunit' and name[1].isdigit() and s.get('timestamp'):
            rows.append((_ts(s.get('timestamp')), i, int(name[1]), float(s.get('time') or 0)))
    rows.sort()
    cost = {}
    for k, (t, _, cu, own) in enumerate(rows):
        c = rows[k + 1][0] - t if k + 1 < len(rows) else own
        cost[cu] = cost.get(cu, 0) + c
    return cost


def cut(cost, n, start):
    """The first codeunit id of each of n contiguous shards, balanced by cost; the first shard starts at `start`."""
    ids = sorted(cost)
    total = sum(cost.values())
    before, acc = [], 0
    for i in ids:
        before.append(acc)
        acc += cost[i]
    starts = [start]
    for k in range(1, n):
        target = total * k / n
        cands = [j for j, i in enumerate(ids) if i > starts[-1]]
        if not cands:
            break
        j = min(cands, key=lambda j: abs(before[j] - target))
        starts.append(ids[j])
    return starts


# ---------- plan ----------

def plan(sel, jobs, versions, conf, event):
    out = {}
    subset = (sel or {}).get('mode') == 'subset'
    for v in versions.get('include', []):
        bc = v['bc_version']
        major = bc.split('.')[0]
        legs = out.setdefault(bc, {})
        for j in jobs:
            key = j['key'] or j['test_app_dirs'][0]
            job_range = spans(j['range'])
            by_major = conf.get('apps', {}).get(key, {})
            starts = by_major.get(major) or (by_major[max(by_major, key=int)] if by_major else None)
            sp = shard_spans(starts) if starts else [(0, TOP)]
            n = len(sp)
            entry = sel['apps'].get(key) if subset else None
            shards = []
            if entry is None:
                for i, s in enumerate(sp):
                    r = intersect(job_range, [s])
                    if r:
                        shards.append({'n': '%d of %d' % (i + 1, n), 'range': fmt(r)})
            elif event == 'pull_request' and entry.get('sentinel'):
                shards = []  # nothing in this app is affected: the leg reports success without starting BC
            else:
                cus = entry.get('codeunits', [])
                sentinels = sorted({c['id'] for c in cus if c.get('sentinel')})
                own = sorted({c['id'] for c in cus if not c.get('sentinel')})
                for i, (lo, hi) in enumerate(sp):
                    mine = [c for c in own if lo <= c <= hi]
                    if mine:
                        ids = sorted(set(mine) | set(sentinels))
                        shards.append({'n': '%d of %d' % (i + 1, n), 'range': ','.join(map(str, ids))})
                if not shards and sentinels:
                    i = next(i for i, (lo, hi) in enumerate(sp) if lo <= sentinels[0] <= hi)
                    shards.append({'n': '%d of %d' % (i + 1, n), 'range': ','.join(map(str, sentinels))})
                if not shards:  # an empty selection: run the full range rather than nothing
                    shards = [{'n': '1 of 1', 'range': fmt(job_range)}]
            legs[key] = shards
    return out


def summary(out):
    lines = ['## Shards\n', '| BC | Test app | Shards | Ranges |', '|---|---|---|---|']
    for bc, legs in out.items():
        for app, shards in legs.items():
            what = ', '.join('%s: `%s`' % (s['n'], (s['range'] if len(s['range']) < 60 else s['range'][:57] + '...').replace('|', '\\|'))
                             for s in shards) or 'none: nothing in this app is affected, the leg reports success'
            lines.append('| %s | `%s` | %d | %s |' % (bc, app, len(shards), what))
    return '\n'.join(lines) + '\n'


# ---------- merge ----------

def merge(paths, out_path):
    suites, order, roots = {}, [], []
    for p in paths:
        root = ET.parse(p).getroot()
        roots.append(root)
        for s in root.findall('testsuite'):
            k = s.get('name')
            if k not in suites:
                order.append(k)
            suites[k] = s
    kept = [suites[k] for k in order]
    first = roots[0] if roots else ET.Element('testsuites')

    def isum(attr):
        return str(sum(int(s.get(attr, '0')) for s in kept))

    stamps = [r.get('timestamp') for r in roots if r.get('timestamp')]
    merged = ET.Element('testsuites', {
        'name': first.get('name', 'merged'), 'tests': isum('tests'), 'failures': isum('failures'),
        'errors': isum('errors'), 'skipped': isum('skipped'),
        'time': '%.3f' % sum(float(r.get('time') or 0) for r in roots if any(s in kept for s in r.findall('testsuite'))),
        'timestamp': max(stamps) if stamps else ''})
    for s in kept:
        merged.append(s)
    ET.ElementTree(merged).write(out_path, encoding='unicode', xml_declaration=True)


# ---------- command line ----------

def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    sub = ap.add_subparsers(dest='cmd', required=True)
    m = sub.add_parser('measure')
    m.add_argument('--junit', action='append', required=True, help='MAJOR=FILE, the al-language JUnit of a full run')
    m.add_argument('--shards', type=int, required=True)
    m.add_argument('--app', required=True)
    m.add_argument('--range-start', type=int, default=50000)
    m.add_argument('--source', default='')
    m.add_argument('--file', required=True)
    p = sub.add_parser('plan')
    p.add_argument('--ci-yml', required=True)
    p.add_argument('--versions', required=True, help='the prepare job matrix, {"include": [{"bc_version": ...}]}')
    p.add_argument('--file', required=True)
    p.add_argument('--event', required=True)
    p.add_argument('--selection', help='select-tests.py --json output; missing or unreadable: a full run')
    p.add_argument('--github', action='store_true')
    g = sub.add_parser('merge')
    g.add_argument('--out', required=True)
    g.add_argument('inputs', nargs='+')
    a = ap.parse_args(argv)

    if a.cmd == 'measure':
        conf = json.load(open(a.file)) if os.path.exists(a.file) else {}
        app = {}
        for spec in a.junit:
            major, _, path = spec.partition('=')
            app[major] = cut(wall_costs(path), a.shards, a.range_start)
        conf.setdefault('apps', {})[a.app] = app
        if a.source:
            conf.setdefault('source', {})[a.app] = a.source
        with open(a.file, 'w') as f:
            json.dump(conf, f, indent=1, sort_keys=True)
            f.write('\n')
        print(json.dumps(app))
    elif a.cmd == 'plan':
        sel = None
        if a.selection:
            try:
                sel = json.load(open(a.selection))
            except (OSError, ValueError) as e:
                print('selection %s not readable (%s): a full run' % (a.selection, e))
        out = plan(sel, parse_ci(open(a.ci_yml).read()), json.loads(a.versions), json.load(open(a.file)), a.event)
        text = summary(out)
        print(text)
        if a.github:
            if os.environ.get('GITHUB_STEP_SUMMARY'):
                with open(os.environ['GITHUB_STEP_SUMMARY'], 'a') as f:
                    f.write(text)
            with open(os.environ['GITHUB_OUTPUT'], 'a') as f:
                f.write('shards=%s\n' % json.dumps(out, separators=(',', ':')))
    else:
        merge(a.inputs, a.out)
    return 0


if __name__ == '__main__':
    sys.exit(main())
