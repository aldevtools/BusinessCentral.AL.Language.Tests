#!/usr/bin/env python3
"""Self-test for provenance.py: the BC build a run resolves once per version, the provenance properties a leg writes
into each <testsuite> (also after a shard re-run), and the results manifest of a master run. Also checks that ci.yml
and bc-leg.yml pass the resolved build to every leg and stamp and record it."""
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


pv = load('provenance', 'provenance.py')
cs = load('ci_shards', 'ci-shards.py')

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


def junit(path, suites, stamp_ts='2026-11-01T04:00:00Z'):
    """suites: [codeunit id]"""
    root = ET.Element('testsuites', {'name': 'DEFAULT', 'tests': str(len(suites)), 'failures': '0', 'errors': '0',
                                      'skipped': '0', 'time': '1.000', 'timestamp': stamp_ts})
    for cu in suites:
        s = ET.SubElement(root, 'testsuite', {'name': 'Codeunit %d' % cu, 'tests': '1', 'failures': '0', 'errors': '0',
                                              'skipped': '0', 'time': '0.5', 'timestamp': stamp_ts})
        ET.SubElement(s, 'testcase', {'classname': 'Codeunit %d' % cu, 'name': 'T%d' % cu, 'time': '0.1'})
    ET.ElementTree(root).write(path, encoding='unicode', xml_declaration=True)


def suites_of(path):
    return {s.get('name'): s for s in ET.parse(path).getroot().findall('testsuite')}


REL = pv.RELEASED + '/sandbox/indexes/w1.json'


def U(build):
    return pv.RELEASED + '/sandbox/%s/w1' % build
INS = pv.INSIDER + '/sandbox/indexes/w1.json'


def fake(indexes):
    calls = []

    def fetch(url):
        calls.append(url)
        v = indexes.get(url)
        if isinstance(v, Exception):
            raise v
        if v is None:
            raise OSError('404')
        return v
    fetch.calls = calls
    return fetch


def main():
    # ---- resolve ----
    idx = [{'Version': '27.5.9.1'}, {'Version': '27.5.10.0'}, {'Version': '27.50.1.0'}, {'Version': '28.5.1.0'}, 'x', {}]
    check('newest: numeric order, not text order', pv.newest(idx, '27.5') == '27.5.10.0', pv.newest(idx, '27.5'))
    check('newest: 27.5 does not match 27.50', pv.newest([{'Version': '27.50.1.0'}], '27.5') is None)
    check('newest: none', pv.newest(idx, '26.0') is None)
    check('newest: only four groups of ASCII digits', pv.newest(
        [{'Version': '27.5.9.9\n'}, {'Version': '27.5.1_0.0'}, {'Version': '27.5.٣.0'}, {'Version': '27.5.1'},
         {'Version': 27.5}, {'Version': '27.5.2.0'}], '27.5') == '27.5.2.0')

    f = fake({REL: idx})
    url, build = pv.resolve_one('27.5', fetch=f, pause=0)
    check('resolve: released index', (url, build) == (pv.RELEASED + '/sandbox/27.5.10.0/w1', '27.5.10.0'), (url, build))
    check('resolve: one index read', f.calls == [REL], f.calls)

    f = fake({REL: [{'Version': '28.5.1.0'}], INS: [{'Version': '30.0.1.0'}, {'Version': '30.0.2.0'}]})
    check('resolve: insider storage when the released index lacks the minor',
          pv.resolve_one('30.0', fetch=f, pause=0) == (pv.INSIDER + '/sandbox/30.0.2.0/w1', '30.0.2.0'))

    f = fake({REL: OSError('timeout'), INS: [{'Version': '27.5.3.0'}]})
    err = raises(lambda: pv.resolve_one('27.5', fetch=f, pause=0))
    check('resolve: a released index error is retried, never answered from the insider storage',
          err and '27.5.x' in err and f.calls == [REL, REL, REL], (err, f.calls))

    answers = [OSError('timeout'), [{'Version': '27.5.4.0'}]]

    def flaky(url):
        flaky.calls.append(url)
        a = answers.pop(0)
        if isinstance(a, Exception):
            raise a
        return a
    flaky.calls = []
    check('resolve: a released index error, then the released index on the next attempt',
          pv.resolve_one('27.5', fetch=flaky, pause=0) == (pv.RELEASED + '/sandbox/27.5.4.0/w1', '27.5.4.0')
          and flaky.calls == [REL, REL], flaky.calls)

    f = fake({REL: [{'Version': '28.5.1.0'}], INS: OSError('timeout')})
    err = raises(lambda: pv.resolve_one('27.5', fetch=f, pause=0))
    check('resolve: an insider index error is retried', err and f.calls == [REL, INS] * 3, f.calls)

    f = fake({REL: [{'Version': '28.5.1.0'}], INS: []})
    err = raises(lambda: pv.resolve_one('27.5', fetch=f, pause=0))
    check('resolve: no build anywhere is an error', err and '::error' in err and '27.5.x' in err, err)
    check('resolve: both indexes read without the minor: no second attempt', f.calls == [REL, INS], f.calls)
    check('resolve: an artifact URL without a full build is an error',
          raises(lambda: pv.build_of(pv.RELEASED + '/sandbox/29.0/w1')) and raises(lambda: pv.build_of('')))

    for v in ('29.0',):
        f = fake({})
        check('resolve: %s takes the pinned URL without reading an index' % v,
              pv.resolve_one(v, fetch=f, pause=0) == (pv.PINNED['29.0'], '29.0.54011.55816') and not f.calls)

    check('resolve: a full build is taken as it is',
          pv.resolve_one('28.5.54151.58194', fetch=fake({}), pause=0)
          == (pv.RELEASED + '/sandbox/28.5.54151.58194/w1', '28.5.54151.58194'))

    m = pv.resolve({'include': [{'bc_version': '27.5', 'runtime': '16.1', 'preprocessor_symbols': 'BC27PLUS'},
                                {'bc_version': '29.0', 'runtime': '18.0'}]}, fetch=fake({REL: idx}), pause=0)
    check('resolve: the matrix keeps its keys and gains bc_artifact_url and bc_build',
          m['include'][0] == {'bc_version': '27.5', 'runtime': '16.1', 'preprocessor_symbols': 'BC27PLUS',
                              'bc_artifact_url': pv.RELEASED + '/sandbox/27.5.10.0/w1', 'bc_build': '27.5.10.0'}
          and m['include'][1]['bc_build'] == '29.0.54011.55816', m)
    check('resolve: summary names each build', '| 27.5 | 27.5.10.0 |' in pv.resolve_summary(m))

    # ---- stamp ----
    with tempfile.TemporaryDirectory() as d:
        p = os.path.join(d, 'junit-al-language.xml')
        junit(p, [50001, 50002])
        n = pv.stamp(p, '100', '1', 'abc', U('27.5.10.0'), 'full')
        s = suites_of(p)
        first = list(s['Codeunit 50001'])[0]
        check('stamp: every suite stamped', n == 2, n)
        check('stamp: <properties> is the first child', first.tag == 'properties', first.tag)
        check('stamp: the five properties', pv.provenance(s['Codeunit 50001']) == {
            'source_run': '100', 'source_attempt': '1', 'source_commit': 'abc', 'bc_build': '27.5.10.0', 'app': 'full'},
            pv.provenance(s['Codeunit 50001']))
        check('stamp: the suite timestamp is unchanged', s['Codeunit 50001'].get('timestamp') == '2026-11-01T04:00:00Z')
        check('stamp: the test case is kept', s['Codeunit 50001'].find('testcase').get('name') == 'T50001')

        n = pv.stamp(p, '100', '2', 'abc', U('27.5.10.0'), 'full')
        check('stamp: an earlier stamp of the run is kept', n == 0
              and pv.provenance(suites_of(p)['Codeunit 50001'])['source_attempt'] == '1')
        err = raises(lambda: pv.stamp(p, '100', '2', 'abc', U('27.5.11.0'), 'full'))
        check('stamp: another build is an error', err and 'was run on BC 27.5.10.0' in err, err)

        q = os.path.join(d, 'other.xml')
        junit(q, [50003])
        t = ET.parse(q)
        props = ET.Element('properties')
        ET.SubElement(props, 'property', {'name': 'codeunit', 'value': '50003'})
        t.getroot().find('testsuite').insert(0, props)
        t.write(q, encoding='unicode', xml_declaration=True)
        pv.stamp(q, '100', '1', 'abc', U('27.5.10.0'), 'full')
        got = suites_of(q)['Codeunit 50003'].find('properties')
        check('stamp: an existing <properties> keeps its properties and gets the five',
              [x.get('name') for x in got] == ['codeunit'] + list(pv.PROPS), [x.get('name') for x in got])

        t = ET.parse(q)
        pr = t.getroot().find('testsuite').find('properties')
        pr.remove([x for x in pr if x.get('name') == 'app'][0])
        t.write(q, encoding='unicode', xml_declaration=True)
        err = raises(lambda: pv.stamp(q, '100', '1', 'abc', U('27.5.10.0'), 'full'))
        check('stamp: a partial stamp is an error', err and 'only' in err, err)
        check('stamp: an artifact URL without a build is an error',
              raises(lambda: pv.stamp(p, '100', '1', 'abc', U(''), 'full')))
        empty = os.path.join(d, 'empty.xml')
        junit(empty, [])
        check('stamp: a file without a codeunit is an error',
              'no <testsuite>' in (raises(lambda: pv.stamp(empty, '100', '1', 'abc', U('27.5.10.0'), 'full')) or ''))
        ET.ElementTree(ET.Element('testsuite', {'name': 'x'})).write(empty, encoding='unicode', xml_declaration=True)
        check('stamp: a root that is not <testsuites> is an error',
              raises(lambda: pv.stamp(empty, '100', '1', 'abc', U('27.5.10.0'), 'full')))
        check('stamp: app other than full or partial is an error',
              raises(lambda: pv.stamp(p, '100', '1', 'abc', U('27.5.10.0'), 'mixed')))

        # Re-run failed jobs: the earlier merged (stamped) file plus the re-run shard's file; the merge replaces the
        # re-run codeunit, the stamp gives only that one the new attempt.
        merged1 = os.path.join(d, 'merged1.xml')
        junit(merged1, [60001, 60002])
        pv.stamp(merged1, '200', '1', 'def', U('28.5.1.0'), 'full')
        rerun = os.path.join(d, 'rerun.xml')
        junit(rerun, [60002], stamp_ts='2026-11-01T05:00:00Z')
        out = os.path.join(d, 'merged2.xml')
        cs.merge([merged1, rerun], out)
        pv.stamp(out, '200', '2', 'def', U('28.5.1.0'), 'full')
        s = suites_of(out)
        check('re-run: the kept codeunit keeps attempt 1',
              pv.provenance(s['Codeunit 60001'])['source_attempt'] == '1')
        check('re-run: the re-run codeunit gets attempt 2 and its own timestamp',
              pv.provenance(s['Codeunit 60002'])['source_attempt'] == '2'
              and s['Codeunit 60002'].get('timestamp') == '2026-11-01T05:00:00Z')

    # ---- manifest ----
    jobs = [{'test_app_dirs': ['tests/al-language']}, {'test_app_dirs': ['tests/al-language-onprem']}]
    versions = {'include': [{'bc_version': '27.5', 'bc_build': '27.5.10.0', 'bc_artifact_url': 'u27',
                             'preprocessor_symbols': 'BC27PLUS,BC27_5PLUS'},
                            {'bc_version': '29.0', 'bc_build': '29.0.1.0', 'bc_artifact_url': 'u29',
                             'preprocessor_symbols': 'BC27PLUS,BC28PLUS,BC29PLUS'}]}

    def tree(d, broken=None):
        for v, build in (('27.5', '27.5.10.0'), ('29.0', '29.0.1.0')):
            for folder, name, cus in (('2026-11-18T01:00:00Z-1', 'junit-al-language.xml', [50001, 50002]),
                                      ('2026-11-18T01:00:01Z-2', 'junit-al-language-onprem.xml', [61200])):
                os.makedirs(os.path.join(d, v, folder), exist_ok=True)
                p = os.path.join(d, v, folder, name)
                junit(p, cus)
                pv.stamp(p, '300', '1', 'sha', U(build), 'full')

    with tempfile.TemporaryDirectory() as d:
        tree(d)
        out, errors = pv.manifest(versions, jobs, '300', '1', 'sha', 'push', d)
        check('manifest: no error on a complete run', errors == [], errors)
        v27 = out['versions']['27.5']
        check('manifest: run fields', (out['schema'], out['run_id'], out['commit'], out['event'], out['base_run'],
                                       out['base_commit']) == (1, 300, 'sha', 'push', None, None), out)
        check('manifest: per version build, mode, chain, app',
              (v27['bc_build'], v27['mode'], v27['chain'], v27['app'], v27['bc_artifact_url'])
              == ('27.5.10.0', 'full', 0, 'full', 'u27'), v27)
        check('manifest: per leg counts', v27['legs']['junit-al-language.xml'] == {
            'test_app_dir': 'tests/al-language', 'fresh': 2, 'reused': 0, 'dropped': 0, 'oldest_source_run': 300},
            v27['legs'])
        check('manifest: is JSON', json.loads(json.dumps(out)) == out)
        check('manifest: each version records the symbols of its matrix entry, as a list',
              (v27['preprocessor_symbols'], out['versions']['29.0']['preprocessor_symbols'])
              == (['BC27PLUS', 'BC27_5PLUS'], ['BC27PLUS', 'BC28PLUS', 'BC29PLUS']), v27)
        check('manifest: records the list of released minors of released-minors.txt',
              out['released_minors'] == pv.released_minors() and '27.0' in out['released_minors'], out['released_minors'])
        out, _ = pv.manifest(versions, jobs, '300', '1', 'sha', 'push', d, released=['27.5', '29.0'])
        check('manifest: a given list of released minors is recorded as given', out['released_minors'] == ['27.5', '29.0'])
        bare = {'include': [dict(e, preprocessor_symbols='') for e in versions['include']]}
        _, errors = pv.manifest(bare, jobs, '300', '1', 'sha', 'push', d)
        check('manifest: a matrix entry without symbols is an error',
              any('BC 27.5: the matrix entry has no preprocessor_symbols' in e for e in errors), errors)

        # a later artifact folder (a leftover shard artifact would sort earlier) replaces an earlier one
        later = os.path.join(d, '27.5', '2026-11-18T02:00:00Z-9')
        os.makedirs(later)
        junit(os.path.join(later, 'junit-al-language.xml'), [50001, 50002, 50003])
        pv.stamp(os.path.join(later, 'junit-al-language.xml'), '300', '1', 'sha', U('27.5.10.0'), 'full')
        out, errors = pv.manifest(versions, jobs, '300', '1', 'sha', 'push', d)
        check('manifest: the later artifact wins', out['versions']['27.5']['legs']['junit-al-language.xml']['fresh'] == 3)

    with tempfile.TemporaryDirectory() as d:
        tree(d)
        os.remove(os.path.join(d, '29.0', '2026-11-18T01:00:01Z-2', 'junit-al-language-onprem.xml'))
        _, errors = pv.manifest(versions, jobs, '300', '1', 'sha', 'push', d)
        check('manifest: a missing leg is an error', any('BC 29.0: no junit-al-language-onprem.xml' in e for e in errors),
              errors)

    with tempfile.TemporaryDirectory() as d:
        tree(d)
        p = os.path.join(d, '27.5', '2026-11-18T01:00:00Z-1', 'junit-al-language.xml')
        junit(p, [50001])
        pv.stamp(p, '300', '1', 'sha', U('27.5.9.0'), 'full')
        _, errors = pv.manifest(versions, jobs, '300', '1', 'sha', 'push', d)
        check('manifest: a suite of another build is an error', any('Codeunit 50001' in e for e in errors), errors)
        junit(p, [50001])
        _, errors = pv.manifest(versions, jobs, '300', '1', 'sha', 'push', d)
        check('manifest: an unstamped suite is an error', any('missing' in e for e in errors), errors)
        junit(p, [50001])
        pv.stamp(p, '299', '1', 'sha', U('27.5.10.0'), 'full')
        _, errors = pv.manifest(versions, jobs, '300', '1', 'sha', 'push', d)
        check('manifest: a suite of another run is an error (no reuse yet)', any('299' in e for e in errors), errors)
        junit(p, [50001])
        pv.stamp(p, '300', '1', 'other', U('27.5.10.0'), 'full')
        _, errors = pv.manifest(versions, jobs, '300', '1', 'sha', 'push', d)
        check('manifest: a suite of another commit is an error', any("'other'" in e for e in errors), errors)
        junit(p, [])
        _, errors = pv.manifest(versions, jobs, '300', '1', 'sha', 'push', d)
        check('manifest: a leg without a codeunit is an error', any('no codeunit of this run' in e for e in errors),
              errors)

    # ---- check-manifest ----
    man = {'schema': 1, 'run_id': 300, 'run_attempt': 1, 'commit': 'sha'}
    run = {'id': 300, 'run_attempt': 1, 'head_sha': 'sha', 'status': 'completed', 'conclusion': 'success'}
    check('check-manifest: the latest attempt of a green run counts', pv.check_manifest(man, run) == [])
    for label, change in (('a later attempt exists', {'run_attempt': 2}), ('the run is red', {'conclusion': 'failure'}),
                          ('the run is cancelled', {'conclusion': 'cancelled'}),
                          ('the run still runs', {'status': 'in_progress', 'conclusion': None}),
                          ('another run', {'id': 301}), ('another commit', {'head_sha': 'x'})):
        check('check-manifest: does not count when %s' % label, pv.check_manifest(man, dict(run, **change)) != [])
    check('check-manifest: another schema does not count', pv.check_manifest(dict(man, schema=2), run) != [])

    # ---- the real workflows ----
    ci = (HERE.parent / 'workflows' / 'ci.yml').read_text()
    leg = (HERE.parent / 'workflows' / 'bc-leg.yml').read_text()
    calls = ci.count('uses: ./.github/workflows/bc-leg.yml')
    check('real ci.yml: no artifact URL is written in the test jobs', 'bcartifacts' not in ci and 'bcinsider' not in ci)
    check('real ci.yml: every leg takes the resolved URL',
          len(re.findall(r'^\s+bc_artifact_url:\s+\$\{\{ matrix\.bc_artifact_url \}\}$', ci, re.M)) == calls, calls)
    check('real ci.yml: no leg passes the build apart from its URL', 'bc_build:' not in ci)
    check('real ci.yml: the prepare job resolves the builds', 'provenance.py resolve' in ci)
    check('real ci.yml: the matrix comes from the list of released minors, no leg or symbol is typed',
          'ci-legs.py matrix --version "$OVERRIDE"' in ci and '"preprocessor_symbols":"' not in ci
          and not re.search(r'^\s+[^#\s].*BC2[0-9]PLUS', ci, re.M))
    check('real ci.yml: a manifest job on push runs provenance.py manifest and uploads results-manifest',
          re.search(r'^  manifest:\n(?:    .*\n|\n)*?    if: .*github\.event_name == .push.', ci, re.M) is not None
          and 'provenance.py manifest' in ci and 'name: results-manifest' in ci)
    real_jobs = cs.parse_ci(ci)
    m = re.search(r'^  manifest:\n((?:    .*\n|\n)*)', ci, re.M)
    needs = m and re.search(r'^    needs: \[(.*)\]', m.group(1), re.M)
    check('real ci.yml: the manifest job needs every test job and prepare',
          needs and set(x.strip() for x in needs.group(1).split(',')) == {'prepare'} | {j['job'] for j in real_jobs},
          needs and needs.group(1))
    check('real bc-leg.yml: the artifact URL is required and the stamp takes the build from it',
          re.search(r'^      bc_artifact_url:\s+\{type: string, required: true\}', leg, re.M) is not None
          and 'bc_build' not in leg and '--bc-artifact-url "$BC_ARTIFACT_URL"' in leg)
    check('real workflows: every artifact download goes through run-artifacts.sh',
          'run-artifacts.sh' in leg and 'run-artifacts.sh' in ci and '/zip' not in leg and '/zip' not in ci)

    if FAILED:
        raise SystemExit('%d check(s) failed: %s' % (len(FAILED), FAILED))
    print('self-test OK')


main()
