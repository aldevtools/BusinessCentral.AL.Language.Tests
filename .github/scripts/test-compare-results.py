#!/usr/bin/env python3
"""Self-test for compare-results.py, the nightly comparison (CONTRIBUTING.md, "Nightly full run"): which codeunits a
master run at the nightly's commit would have reused from the base run, the key-by-key comparison of those codeunits,
the choice of the base run, and the comparison fields it writes into the nightly's results manifest. Also checks that
ci.yml runs the nightly in the same workflow as the push runs and has the job "Nightly comparison"."""
import importlib.util
import json
import os
import re
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path

HERE = Path(__file__).resolve().parent


def load(name, file):
    spec = importlib.util.spec_from_file_location(name, HERE / file)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


cr = load('compare_results', 'compare-results.py')
pv = load('provenance', 'provenance.py')

FAILED = []


def check(name, cond, detail=''):
    print('%s %s%s' % ('ok  ' if cond else 'FAIL', name, '' if cond else ': %s' % (detail,)))
    if not cond:
        FAILED.append(name)


def raises(fn):
    try:
        fn()
    except SystemExit as e:
        return str(e)
    return None


def junit(path, suites, run='300', commit='head', build='27.5.10.0', ts='2026-11-18T02:00:00Z'):
    """suites: {codeunit id: {test name: outcome}}; outcome passed, failure, error or skipped."""
    os.makedirs(os.path.dirname(path), exist_ok=True)
    root = ET.Element('testsuites', {'name': 'DEFAULT'})
    for cu, tests in suites.items():
        s = ET.SubElement(root, 'testsuite', {'name': 'Codeunit %d' % cu, 'tests': str(len(tests)), 'timestamp': ts})
        props = ET.SubElement(s, 'properties')
        for k, v in zip(pv.PROPS, (run, '1', commit, build, 'full')):
            ET.SubElement(props, 'property', {'name': k, 'value': v})
        for name, outcome in tests.items():
            c = ET.SubElement(s, 'testcase', {'classname': 'Codeunit %d' % cu, 'name': name, 'time': '0.1'})
            if outcome != 'passed':
                ET.SubElement(c, outcome, {'message': 'x'})
    ET.ElementTree(root).write(path, encoding='unicode', xml_declaration=True)


def version(build='27.5.10.0', legs=('junit-al-language.xml',)):
    apps = {'junit-al-language.xml': 'tests/al-language', 'junit-al-language-onprem.xml': 'tests/al-language-onprem'}
    return {'bc_build': build, 'mode': 'full', 'chain': 0, 'app': 'full',
            'legs': {n: {'test_app_dir': apps[n], 'fresh': 1, 'reused': 0, 'dropped': 0} for n in legs}}


def manifest(run, commit, versions, event='push'):
    return {'schema': 1, 'run_id': run, 'run_attempt': 1, 'commit': commit, 'event': event, 'base_run': None,
            'base_commit': None, 'versions': versions}


# Two test jobs as ci-shards.py parse_ci reads them from ci.yml.
JOBS = [{'job': 'test', 'app_dirs': [], 'test_app_dirs': ['tests/al-language'], 'range': '50000..59999',
         'key': 'tests/al-language'},
        {'job': 'test-onprem', 'app_dirs': [], 'test_app_dirs': ['tests/al-language-onprem'], 'range': '61000..61999',
         'key': 'tests/al-language-onprem'}]
VERSIONS = {'include': [{'bc_version': '27.5'}, {'bc_version': '28.5'}]}
SUBSET = {'mode': 'subset', 'base': 'base', 'head': 'head', 'reasons': [], 'changed_files': ['tests/al-language/a.al'],
          'apps': {'tests/al-language': {'codeunits': [{'id': 50002}, {'id': 50009, 'sentinel': True}]}}}


def main():
    # ---- outcome of a test case ----
    with tempfile.TemporaryDirectory() as d:
        p = os.path.join(d, 'j.xml')
        junit(p, {50001: {'A': 'passed', 'B': 'failure', 'C': 'error', 'D': 'skipped'}})
        leg = cr.read_leg(p)
        check('read_leg: the outcome of each case', leg[50001]['tests'] == {
            'A': ['passed'], 'B': ['failure'], 'C': ['error'], 'D': ['skipped']}, leg)
        check('read_leg: the provenance and timestamp of the suite',
              (leg[50001]['source_run'], leg[50001]['source_commit'], leg[50001]['timestamp'])
              == ('300', 'head', '2026-11-18T02:00:00Z'), leg[50001])

    # ---- what a master run at the nightly's commit would have reused ----
    ids = {50001, 50002, 50003, 50009}
    reuse, note = cr.reuse_rule(SUBSET, 'base', 'head', JOBS, {}, VERSIONS)
    check('reuse: a subset selection reuses every codeunit it does not run (the sentinel runs)',
          reuse('tests/al-language', ids) == {50001, 50003}, reuse('tests/al-language', ids))
    check('reuse: an app the subset selection leaves out runs its full range, nothing reused',
          reuse('tests/al-language-onprem', {61000}) == set())
    check('reuse: a codeunit outside the job range is not run, so it is reused',
          reuse('tests/al-language-onprem', {61000, 62000}) == {62000}, reuse('tests/al-language-onprem', {61000, 62000}))
    only_sentinel = dict(SUBSET, apps={'tests/al-language': {'codeunits': [{'id': 50009, 'sentinel': True}],
                                                             'sentinel': True}})
    reuse, note = cr.reuse_rule(only_sentinel, 'base', 'head', JOBS, {}, VERSIONS)
    check('reuse: an app with nothing affected starts no BC, every codeunit reused (ci-shards.py plan)',
          reuse('tests/al-language', ids) == ids, reuse('tests/al-language', ids))
    empty = dict(SUBSET, apps={'tests/al-language': {'codeunits': []}})
    reuse, note = cr.reuse_rule(empty, 'base', 'head', JOBS, {}, VERSIONS)
    check('reuse: an app with an empty selection runs its full range, nothing reused (ci-shards.py plan)',
          reuse('tests/al-language', ids) == set(), reuse('tests/al-language', ids))
    check('reuse: an app no job runs: nothing reused', reuse('tests/elsewhere', ids) == set())
    reuse, note = cr.reuse_rule(None, 'same', 'same')
    check('reuse: the base run is at the nightly commit: every codeunit', reuse('tests/al-language', ids) == ids)
    reuse, note = cr.reuse_rule(None, 'base', 'head')
    check('reuse: no selection (the script failed): nothing', reuse('tests/al-language', ids) == set() and note, note)
    ignored = {'mode': 'full', 'base': 'base', 'head': 'head', 'reasons': ['no changed file in the test apps'],
               'apps': {}, 'changed_files': ['docs/a.md', 'README.md'], 'ignored_files': ['docs/a.md', 'README.md']}
    reuse, note = cr.reuse_rule(ignored, 'base', 'head')
    check('reuse: only files CI does not read changed: every codeunit', reuse('tests/al-language', ids) == ids)
    full = dict(ignored, changed_files=['docs/a.md', '.github/workflows/ci.yml'], ignored_files=['docs/a.md'],
                reasons=['CI configuration changed: .github/workflows/ci.yml'])
    reuse, note = cr.reuse_rule(full, 'base', 'head')
    check('reuse: a full selection with a reason: nothing', reuse('tests/al-language', ids) == set() and 'CI' in note,
          note)
    early = {'mode': 'full', 'base': 'base', 'head': 'head', 'reasons': ['could not read the test jobs'], 'apps': {},
             'changed_files': []}
    reuse, note = cr.reuse_rule(early, 'base', 'head')
    check('reuse: a full selection that stopped before the diff (no ignored_files): nothing',
          reuse('tests/al-language', ids) == set())

    # ---- the comparison of one version ----
    def setup(d, nightly, base, base_build='27.5.10.0', base_legs=None):
        nf = os.path.join(d, 'n', 'junit-al-language.xml')
        bf = os.path.join(d, 'b', 'junit-al-language.xml')
        junit(nf, nightly)
        junit(bf, base, run='200', commit='base', ts='2026-11-17T09:00:00Z')
        return ({'junit-al-language.xml': nf}, {'junit-al-language.xml': bf} if base_legs is None else base_legs)

    every = lambda app, ids: set(ids)
    same = {50001: {'A': 'passed'}, 50002: {'B': 'passed'}}
    with tempfile.TemporaryDirectory() as d:
        nf, bf = setup(d, same, same)
        r = cr.compare_version(version(), nf, version(), bf, every)
        check('compare: equal results are identical', (r['comparison'], r['compared'], r['differences'])
              == ('identical', 2, []), r)
    with tempfile.TemporaryDirectory() as d:
        nf, bf = setup(d, {50001: {'A': 'failure'}, 50002: {'B': 'passed'}}, same)
        r = cr.compare_version(version(), nf, version(), bf, every)
        check('compare: another outcome differs, with the source of the reused result',
              r['comparison'] == 'differs' and r['differences'] == [
                  {'leg': 'junit-al-language.xml', 'codeunit': 50001, 'test': 'A', 'nightly': ['failure'],
                   'base': ['passed'], 'source_run': '200', 'source_commit': 'base',
                   'timestamp': '2026-11-17T09:00:00Z'}], r)
    with tempfile.TemporaryDirectory() as d:
        nf, bf = setup(d, {50001: {'A': 'passed'}, 50002: {}}, same)
        r = cr.compare_version(version(), nf, version(), bf, every)
        check('compare: a lost test differs', r['comparison'] == 'differs'
              and [(x['test'], x['nightly'], x['base']) for x in r['differences']] == [('B', [], ['passed'])], r)
    with tempfile.TemporaryDirectory() as d:
        nf, bf = setup(d, {50001: {'A': 'passed', 'A2': 'passed'}, 50002: {'B': 'passed'}}, same)
        r = cr.compare_version(version(), nf, version(), bf, every)
        check('compare: an added test differs', r['comparison'] == 'differs', r)
    with tempfile.TemporaryDirectory() as d:
        nf, bf = setup(d, {**same, 50003: {'C': 'passed'}}, same)
        r = cr.compare_version(version(), nf, version(), bf, every)
        check('compare: a reused codeunit without a base result differs', r['comparison'] == 'differs'
              and [(x['codeunit'], x['test'], x['base']) for x in r['differences']] == [(50003, None, None)], r)
    with tempfile.TemporaryDirectory() as d:
        nf, bf = setup(d, {50001: {'A': 'passed'}}, same)
        r = cr.compare_version(version(), nf, version(), bf, every)
        check('compare: a base codeunit the nightly no longer has is dropped, not a difference',
              (r['comparison'], r['compared'], r['dropped']) == ('identical', 1, 1), r)
    with tempfile.TemporaryDirectory() as d:
        nf, bf = setup(d, {50001: {'A': 'passed'}, 50002: {'B': 'failure'}}, same)
        r = cr.compare_version(version(), nf, version(), bf, lambda app, ids: set(ids) - {50002})
        check('compare: a codeunit the master run would run again is not compared',
              (r['comparison'], r['compared']) == ('identical', 1), r)
    with tempfile.TemporaryDirectory() as d:
        nf, bf = setup(d, {50001: {'A': 'failure'}}, same)
        r = cr.compare_version(version(), nf, version(build='27.5.9.0'), bf, every)
        check('compare: another BC build is not compared', (r['comparison'], r['compared']) == ('identical', 0)
              and '27.5.9.0' in r['note'], r)
        r = cr.compare_version(version(), nf, None, {}, every)
        check('compare: a version the base run lacks is not compared',
              (r['comparison'], r['compared']) == ('identical', 0) and r['note'], r)
        err = raises(lambda: cr.compare_version(version(), nf, version(), {}, every))
        check('compare: a leg the base manifest names without its file stops the comparison',
              err and 'junit-al-language.xml' in err, err)

    # ---- the base run ----
    def run(id_, sha, attempt=1, conclusion='success'):
        return {'id': id_, 'head_sha': sha, 'run_attempt': attempt, 'status': 'completed', 'conclusion': conclusion}

    runs = [run(205, 'later'), run(204, 'nomanifest'), run(203, 'rerun', attempt=2), run(202, 'good'), run(201, 'old')]
    mans = {204: None, 203: dict(manifest(203, 'rerun', {}), run_attempt=1), 202: manifest(202, 'good', {}),
            201: manifest(201, 'old', {})}
    anc = lambda a, b: a != 'later'
    got, man, notes = cr.find_base(runs, 'head', anc, lambda r: mans[r['id']])
    check('base: the newest green master run at or before the commit whose manifest counts',
          got and got['id'] == 202 and man['run_id'] == 202 and len(notes) == 3, (got, notes))
    got, man, notes = cr.find_base([run(205, 'later')], 'head', anc, lambda r: mans.get(r['id']))
    check('base: none', got is None and man is None and notes, notes)

    # ---- the whole comparison and the manifest it writes ----
    with tempfile.TemporaryDirectory() as d:
        legs, base = os.path.join(d, 'legs'), os.path.join(d, 'base')
        for v, build in (('27.5', '27.5.10.0'), ('29.0', '29.0.1.0')):
            junit(os.path.join(legs, v, '2026-11-18T03:00:00Z-1', 'junit-al-language.xml'), same, build=build)
        junit(os.path.join(base, '27.5', '2026-11-17T10:00:00Z-1', 'junit-al-language.xml'),
              {50001: {'A': 'passed'}, 50002: {'B': 'failure'}}, run='202', commit='good')
        junit(os.path.join(base, '29.0', '2026-11-17T10:00:00Z-1', 'junit-al-language.xml'), same, run='202',
              commit='good', build='29.0.1.0')
        nm = manifest(300, 'head', {'27.5': version(), '29.0': version(build='29.0.1.0')}, event='schedule')
        bm = manifest(202, 'good', {'27.5': version(), '29.0': version(build='29.0.1.0')})
        results = cr.compare(nm, legs, bm, base, every)
        check('compare: per version', (results['27.5']['comparison'], results['29.0']['comparison'])
              == ('differs', 'identical') and results['27.5']['base_run'] == 202, results)
        pv.set_comparison(nm, results)
        check('manifest: comparison per version', [nm['versions'][v]['comparison'] for v in ('27.5', '29.0')]
              == ['differs', 'identical'], nm)
        check('manifest: the detail names the base run and the differences',
              nm['versions']['27.5']['comparison_detail']['base_run'] == 202
              and nm['versions']['27.5']['comparison_detail']['differences'][0]['codeunit'] == 50002, nm)
        check('manifest: still a full run, base_run null (al-runtime-rs reads both)',
              nm['base_run'] is None and all(e['mode'] == 'full' and e['chain'] == 0 for e in nm['versions'].values()))
        check('manifest: is JSON', json.loads(json.dumps(nm)) == nm)
        err = raises(lambda: pv.set_comparison(manifest(1, 'x', {'27.5': version()}), {}))
        check('manifest: a version without a comparison is an error', err and '27.5' in err, err)
        err = raises(lambda: pv.set_comparison(manifest(1, 'x', {'27.5': version()}),
                                               {'27.5': dict(results['27.5'], comparison='unknown')}))
        check('manifest: only identical or differs', err and 'unknown' in err, err)

        results = cr.compare(nm, legs, None, None, every)
        check('compare: no base run: identical, nothing compared, with the reason',
              all(r['comparison'] == 'identical' and r['compared'] == 0 and r['base_run'] is None and r['note']
                  for r in results.values()), results)

    # ---- the command nightly, with fake I/O ----
    with tempfile.TemporaryDirectory() as d:
        def put_manifest(folder, m):
            os.makedirs(folder, exist_ok=True)
            json.dump(m, open(os.path.join(folder, 'results-manifest.json'), 'w'))

        put_manifest(os.path.join(d, 'manifest', '2026-11-18T03:00:00Z-9'),
                     manifest(300, 'head', {'27.5': version()}, event='schedule'))
        junit(os.path.join(d, 'legs', '27.5', '2026-11-18T02:00:00Z-1', 'junit-al-language.xml'),
              {50001: {'A': 'passed'}, 50002: {'B': 'failure'}})
        calls = []

        def download(run_id, name, into):
            calls.append((run_id, name, os.path.relpath(into, d)))
            if name == 'results-manifest' and run_id == 202:
                put_manifest(os.path.join(into, '2026-11-17T10:00:00Z-5'), manifest(202, 'good', {'27.5': version()}))
            elif name == 'junit-test-results-27.5':
                junit(os.path.join(into, '2026-11-17T09:00:00Z-4', 'junit-al-language.xml'),
                      {50001: {'A': 'passed'}, 50002: {'B': 'passed'}}, run='202', commit='good')

        selected = []

        def select(base, head, out):
            selected.append((base, head))
            return dict(SUBSET, apps={'tests/al-language': {'codeunits': [{'id': 50009, 'sentinel': True}]}})

        def gh_json(*args):
            check('nightly: lists the green master push runs of ci.yml',
                  'actions/workflows/ci.yml/runs?branch=master&event=push&status=success' in args[1], args)
            return {'workflow_runs': [run(205, 'later'), run(202, 'good')]}

        out = os.path.join(d, 'out.json')
        a = cr.argparse.Namespace(repo='o/r', head='head', manifest_dir=os.path.join(d, 'manifest'),
                                  legs=os.path.join(d, 'legs'), work=os.path.join(d, 'work'), out=out, github=False)
        cr.nightly(a, gh_json=gh_json, download=download, is_ancestor=lambda x, y: x != 'later', select=select)
        written = json.load(open(out))
        e = written['versions']['27.5']
        check('nightly: base run 202, its JUnit downloaded, the selection from its commit',
              e['comparison_detail']['base_run'] == 202 and (202, 'junit-test-results-27.5', 'work/base/27.5') in calls
              and selected == [('good', 'head')], (e, calls, selected))
        check('nightly: the changed outcome of a reused codeunit is written as differs',
              e['comparison'] == 'differs' and [x['codeunit'] for x in e['comparison_detail']['differences']] == [50002], e)
        check('nightly: the rest of the manifest is unchanged',
              (written['run_id'], written['event'], written['base_run'], e['mode']) == (300, 'schedule', None, 'full'))
        err = raises(lambda: cr.nightly(cr.argparse.Namespace(**dict(vars(a), manifest_dir=os.path.join(d, 'none'))),
                                        gh_json=gh_json, download=download, is_ancestor=lambda x, y: True, select=select))
        check('nightly: no manifest of this run stops the comparison', err and 'results-manifest.json' in err, err)

    # ---- the real ci.yml ----
    ci = (HERE.parent / 'workflows' / 'ci.yml').read_text()
    on = re.search(r'^on:\n((?:  .*\n|\n)*)', ci, re.M).group(1)
    check('real ci.yml: the nightly is a schedule of the same workflow as the push runs',
          re.search(r"^  schedule:\n    - cron: '[^']+'", on, re.M) is not None and re.search(r'^  push:', on, re.M))
    job = re.search(r'^  nightly-comparison:\n((?:    .*\n|\n)*)', ci, re.M)
    body = job.group(1) if job else ''
    check('real ci.yml: the job "Nightly comparison" runs on the schedule after the manifest job',
          re.search(r'^    name: Nightly comparison$', body, re.M) and re.search(r'^    needs: \[.*\bmanifest\b.*\]', body, re.M)
          and re.search(r"^    if: .*github\.event_name == 'schedule'", body, re.M), body[:300])
    check('real ci.yml: it runs compare-results.py and replaces the manifest artifact',
          'compare-results.py nightly' in body and 'name: results-manifest' in body and 'overwrite: true' in body)
    m = re.search(r'^  manifest:\n((?:    .*\n|\n)*)', ci, re.M)
    cond = m and re.search(r'^    if: (.*)$', m.group(1), re.M)
    check('real ci.yml: the manifest job runs for push and schedule runs',
          cond and "github.event_name == 'push'" in cond.group(1) and "github.event_name == 'schedule'" in cond.group(1),
          cond and cond.group(1))

    if FAILED:
        raise SystemExit('%d check(s) failed: %s' % (len(FAILED), FAILED))
    print('self-test OK')


main()
