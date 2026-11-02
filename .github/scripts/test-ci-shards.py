#!/usr/bin/env python3
"""Self-test for ci-shards.py: the shard boundaries it measures, the shards it plans per leg (full run, subset run,
pull request skip, sentinel), and the JUnit merge of a leg's shards. Also checks that the real ci.yml and
ci-shards.json fit together."""
import importlib.util
import json
import os
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('ci_shards', HERE / 'ci-shards.py')
cs = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cs)

FAILED = []


def check(name, cond, detail=''):
    print('%s %s%s' % ('ok  ' if cond else 'FAIL', name, '' if cond else ': %s' % detail))
    if not cond:
        FAILED.append(name)


def junit(path, name, suites):
    """suites: [(codeunit id, timestamp, time, [(test, failed)])]"""
    root = ET.Element('testsuites', {'name': name, 'tests': '0', 'failures': '0', 'errors': '0', 'skipped': '0',
                                      'time': '10.000', 'timestamp': '2026-11-01T04:00:00Z'})
    for cu, ts, t, cases in suites:
        s = ET.SubElement(root, 'testsuite', {'name': 'Codeunit %d' % cu, 'tests': str(len(cases)),
                                              'failures': str(sum(1 for _, f in cases if f)), 'errors': '0',
                                              'skipped': '0', 'time': str(t), 'timestamp': ts})
        for n, f in cases:
            c = ET.SubElement(s, 'testcase', {'classname': 'Codeunit %d' % cu, 'name': n, 'time': '0.1'})
            if f:
                ET.SubElement(c, 'failure', {'message': 'boom'}).text = 'boom'
    ET.ElementTree(root).write(path, encoding='unicode', xml_declaration=True)


CI = """jobs:
  prepare:
    runs-on: ubuntu-latest
  test:
    name: BC ${{ matrix.bc_version }}
    uses: ./.github/workflows/bc-leg.yml
    with:
      test_app_dirs:        "tests/main"
      codeunit_range:       ${{ fromJson(needs.prepare.outputs.subset)['tests/main'] || '50000..50099|50200..50299' }}
  test-onprem:
    name: BC OnPrem ${{ matrix.bc_version }}
    uses: ./.github/workflows/bc-leg.yml
    with:
      test_app_dirs:        "tests/onprem"
      codeunit_range:       ${{ fromJson(needs.prepare.outputs.subset)['tests/onprem'] || '60000..60099' }}
"""
VERSIONS = {'include': [{'bc_version': '27.5'}, {'bc_version': '29.0'}]}
SHARDS = {'apps': {'tests/main': {'27': [50000, 50050, 50210], '29': [50000, 50020]}}}


def sel_subset(main, onprem, main_sentinel_only=False, onprem_sentinel_only=False):
    def entry(ids, sentinel_only, sentinel):  # as select-tests.py --json writes it
        if sentinel_only:
            return {'codeunits': [{'id': sentinel, 'sentinel': True}], 'sentinel': True}
        return {'codeunits': [{'id': i} for i in ids] + [{'id': sentinel, 'sentinel': True}], 'sentinel': False}
    return {'mode': 'subset', 'apps': {'tests/main': entry(main, main_sentinel_only, 50001),
                                       'tests/onprem': entry(onprem, onprem_sentinel_only, 60001)}}


def main():
    jobs = cs.parse_ci(CI)

    # ---- measure: contiguous id ranges, balanced by wall time per codeunit ----
    with tempfile.TemporaryDirectory() as d:
        p = os.path.join(d, 'j.xml')
        # wall time per codeunit = time to the next codeunit's start (run order, not id order); the last: its own time
        junit(p, 'hybrid', [(50010, '2026-11-01T04:00:00Z', 1, [('a', False)]),
                            (50030, '2026-11-01T04:00:10Z', 1, [('a', False)]),
                            (50020, '2026-11-01T04:00:40Z', 1, [('a', False)]),
                            (50040, '2026-11-01T04:00:50Z', 30, [('a', False)])])
        cost = cs.wall_costs(p)
        check('measure: cost is the time to the next start in run order', cost == {50010: 10, 50030: 30, 50020: 10, 50040: 30}, cost)
        starts = cs.cut(cost, 2, 50000)
        check('measure: two shards split the cost evenly, first starts at the range start', starts == [50000, 50040], starts)
        check('measure: one shard', cs.cut(cost, 1, 50000) == [50000])
        # a sharded run: the shards ran at the same time, so the next start is the next one in the same shard
        ps = os.path.join(d, 's.xml')
        junit(ps, 'hybrid', [(50010, '2026-11-01T04:00:00Z', 1, [('a', False)]),
                             (50030, '2026-11-01T04:00:05Z', 1, [('a', False)]),
                             (50020, '2026-11-01T04:00:20Z', 3, [('a', False)]),
                             (50040, '2026-11-01T04:00:25Z', 4, [('a', False)])])
        cost = cs.wall_costs(ps, cs.shard_spans([50000, 50030]))
        check('measure: a sharded run is timed per shard', cost == {50010: 20, 50020: 3, 50030: 20, 50040: 4}, cost)
        conf = os.path.join(d, 'c.json')
        cs.main(['measure', '--junit', '27=' + p, '--junit', '29=' + p, '--shards', '2', '--shards-for', '27=3',
                 '--app', 'tests/main', '--file', conf])
        got = json.load(open(conf))['apps']['tests/main']
        check('measure: --shards-for gives one major its own shard count', got == {'27': [50000, 50030, 50040], '29': [50000, 50040]}, got)

    # ---- spans ----
    check('spans: intersect', cs.fmt(cs.intersect(cs.spans('50000..50099|50200..50299'), [(50050, 50249)]))
          == '50050..50099|50200..50249')
    check('spans: shard spans from starts', cs.shard_spans([50000, 50050, 50210]) == [(0, 50049), (50050, 50209), (50210, cs.TOP)])

    # ---- plan: full run ----
    full = {'mode': 'full', 'apps': {}}
    out = cs.plan(full, jobs, VERSIONS, SHARDS, 'push')
    m27 = out['27.5']['tests/main']
    check('plan full: three shards on 27', [s['n'] for s in m27] == ['1 of 3', '2 of 3', '3 of 3'], m27)
    check('plan full: shard ranges cut the job range', [s['range'] for s in m27]
          == ['50000..50049', '50050..50099|50200..50209', '50210..50299'], m27)
    check('plan full: unsharded app runs its full range in one shard',
          out['27.5']['tests/onprem'] == [{'n': '1 of 1', 'range': '60000..60099'}], out['27.5'])
    check('plan full: 29 has its own boundaries', [s['range'] for s in out['29.0']['tests/main']]
          == ['50000..50019', '50020..50099|50200..50299'], out['29.0'])
    out = cs.plan(full, jobs, {'include': [{'bc_version': '30.1'}]}, SHARDS, 'push')
    check('plan full: an unknown major uses the newest boundaries', len(out['30.1']['tests/main']) == 2, out)
    out = cs.plan(full, jobs, VERSIONS, SHARDS, 'pull_request')
    check('plan full on a pull request: nothing skipped', len(out['29.0']['tests/onprem']) == 1, out)

    # ---- plan: subset ----
    sel = sel_subset([50010, 50060], [60011])
    out = cs.plan(sel, jobs, VERSIONS, SHARDS, 'pull_request')
    m27 = out['27.5']['tests/main']
    check('plan subset: only shards with a selected codeunit run, each with the sentinel',
          m27 == [{'n': '1 of 3', 'range': '50001,50010'}, {'n': '2 of 3', 'range': '50001,50060'}], m27)
    check('plan subset: unsharded app keeps its selection',
          out['27.5']['tests/onprem'] == [{'n': '1 of 1', 'range': '60001,60011'}], out['27.5'])
    sel = sel_subset([50010], [], onprem_sentinel_only=True)
    out = cs.plan(sel, jobs, VERSIONS, SHARDS, 'pull_request')
    check('plan subset, pull request: an app with nothing affected is skipped', out['27.5']['tests/onprem'] == [], out)
    out = cs.plan(sel, jobs, VERSIONS, SHARDS, 'workflow_dispatch')
    check('plan subset, dispatch (CI batcher): an app with nothing affected runs its sentinel',
          out['27.5']['tests/onprem'] == [{'n': '1 of 1', 'range': '60001'}], out)
    sel = sel_subset([], [60011], main_sentinel_only=True)
    out = cs.plan(sel, jobs, VERSIONS, SHARDS, 'workflow_dispatch')
    check('plan subset: sharded app with only its sentinel runs one shard', out['27.5']['tests/main']
          == [{'n': '1 of 3', 'range': '50001'}], out['27.5'])
    sel = {'mode': 'subset', 'apps': {'tests/main': {'codeunits': [{'id': 50060}], 'sentinel': False}}}
    out = cs.plan(sel, jobs, VERSIONS, SHARDS, 'pull_request')
    check('plan subset: an app missing from the selection runs its full range',
          out['27.5']['tests/onprem'] == [{'n': '1 of 1', 'range': '60000..60099'}], out)
    check('plan subset: no sentinel known, the shard runs only its ids',
          out['27.5']['tests/main'] == [{'n': '2 of 3', 'range': '50060'}], out)

    # ---- merge ----
    with tempfile.TemporaryDirectory() as d:
        a, b, rerun, o = (os.path.join(d, x) for x in ('a.xml', 'b.xml', 'r.xml', 'o.xml'))
        junit(a, 'hybrid', [(50020, '2026-11-01T04:00:00Z', 1, [('x', False)]), (50010, '2026-11-01T04:00:01Z', 1, [('y', False)])])
        junit(b, 'hybrid', [(50060, '2026-11-01T04:00:00Z', 1, [('z', True), ('w', False)])])
        junit(rerun, 'hybrid', [(50060, '2026-11-01T05:00:00Z', 1, [('z', False), ('w', False)])])
        cs.merge([a, b], o)
        r = ET.parse(o).getroot()
        check('merge: every suite, shard order kept', [s.get('name') for s in r.findall('testsuite')]
              == ['Codeunit 50020', 'Codeunit 50010', 'Codeunit 50060'], ET.tostring(r)[:300])
        check('merge: totals summed', (r.get('tests'), r.get('failures'), r.get('name')) == ('4', '1', 'hybrid'), r.attrib)
        cs.merge([o, rerun], o)
        r = ET.parse(o).getroot()
        check('merge: a later file (re-run shard) replaces a codeunit, in place',
              [s.get('name') for s in r.findall('testsuite')] == ['Codeunit 50020', 'Codeunit 50010', 'Codeunit 50060']
              and r.get('failures') == '0' and r.get('tests') == '4', ET.tostring(r)[:400])

    # ---- the real files ----
    real = cs.parse_ci((HERE.parent / 'workflows' / 'ci.yml').read_text())
    conf = json.loads((HERE.parent / 'ci-shards.json').read_text())
    keys = {j['key'] for j in real}
    check('real ci.yml: every test job reads the subset', all(j['key'] for j in real), real)
    check('real ci-shards.json: every sharded app is a test job of ci.yml', set(conf['apps']) <= keys, (conf['apps'].keys(), keys))
    out = cs.plan({'mode': 'full', 'apps': {}}, real, {'include': [{'bc_version': '27.5'}, {'bc_version': '28.5'},
                                                                    {'bc_version': '29.0'}]}, conf, 'push')
    check('real: a full run covers each job range exactly',
          all(cs.norm(cs.spans('|'.join(s['range'] for s in out[v][j['key']]))) == cs.norm(cs.spans(j['range']))
              for v in out for j in real), out)
    ci_text = (HERE.parent / 'workflows' / 'ci.yml').read_text()
    check('real ci.yml: every test job calls the local leg workflow and passes its shards',
          ci_text.count('uses: ./.github/workflows/bc-leg.yml') == len(real)
          and ci_text.count("shards:               ${{ toJson(fromJson(needs.prepare.outputs.shards)[matrix.bc_version]") == len(real),
          'uses/shards lines')

    if FAILED:
        raise SystemExit('%d check(s) failed: %s' % (len(FAILED), FAILED))
    print('self-test OK')


main()
