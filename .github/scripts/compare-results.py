#!/usr/bin/env python3
"""The nightly comparison: the nightly full run's fresh results against the results of the latest green master run
(CONTRIBUTING.md, "Nightly full run").

    compare-results.py nightly --repo REPO --head SHA --manifest-dir DIR --legs DIR --work DIR --out FILE [--github]

WHY. al-runtime-rs takes the JUnit files of a green corpus master run as its oracle (its ADR-077). Once master runs
reuse results, a reused result is right only when the test selection did not miss an effect of a later change. The
nightly runs every test and compares, so a missed effect is found within a day. al-runtime-rs refuses a bump while the
newest nightly at or before the bump's commit does not say "identical" for every BC version (its ADR-077, decisions 5
and 6).

What is compared, per BC version: the codeunits that a master run at the nightly's commit would have reused from the
base run (reuse_rule), each test of them key by key (leg, codeunit, test name -> outcome). The base run is the newest
green master push run of this workflow whose commit is the nightly's commit or an ancestor of it and whose results
manifest counts (provenance.py check-manifest). Another BC build than the base's, a version the base run lacks, or no
base run at all: nothing of that version would have been reused, so nothing is compared and the version is "identical"
with "compared": 0 and the reason in "note". A codeunit the base has and the nightly does not was deleted or compiled
out since the base: it is dropped (counted, never a difference). A reused codeunit without a base result is a
difference.

nightly: finds the base run, downloads its manifest and its legs' JUnit files into WORK (run-artifacts.sh), runs
select-tests.py from the base commit to SHA, compares, and writes the nightly's manifest (the job manifest's
results-manifest.json, downloaded into --manifest-dir by run-artifacts.sh) with versions.<v>.comparison and
versions.<v>.comparison_detail to OUT (provenance.py set_comparison). Prints "differs=1" or "differs=0" to $GITHUB_OUTPUT with --github. Exit 1 when the comparison could
not run; OUT is then not written, so the manifest keeps no comparison.
"""
import argparse
import importlib.util
import json
import os
import subprocess
import sys
import xml.etree.ElementTree as ET

HERE = os.path.dirname(os.path.abspath(__file__))
# The JUnit child element that marks a case as not passed; a case without one passed.
NOT_PASSED = ('failure', 'error', 'skipped')
# How many green master push runs the base search reads, newest first.
BASE_CANDIDATES = 30


def _load(name, file):
    spec = importlib.util.spec_from_file_location(name, os.path.join(HERE, file))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


pv = _load('provenance', 'provenance.py')
cs = _load('ci_shards', 'ci-shards.py')


# ---------- results ----------

def outcome(case):
    for tag in NOT_PASSED:
        if case.find(tag) is not None:
            return tag
    return 'passed'


def read_leg(path):
    """{codeunit id: {'tests': {test name: [outcome, ...]}, 'source_run', 'source_commit', 'timestamp'}} of a JUnit file."""
    out = {}
    for s in ET.parse(path).getroot().iter('testsuite'):
        name = (s.get('name') or '').split()
        if len(name) != 2 or name[0] != 'Codeunit' or not name[1].isdigit():
            raise SystemExit('%s: suite %r is not a codeunit' % (path, s.get('name')))
        tests = {}
        for c in s.iter('testcase'):
            tests.setdefault(c.get('name'), []).append(outcome(c))
        p = pv.provenance(s)
        out[int(name[1])] = {'tests': tests, 'source_run': p.get('source_run'), 'source_commit': p.get('source_commit'),
                             'timestamp': s.get('timestamp')}
    return out


# ---------- what a master run would have reused ----------

def would_run(selection, jobs, conf, versions):
    """{test app dir: [(lo, hi), ...]}: the codeunits each leg of a run with this selection runs, over all BC versions:
    the ranges of the shards ci-shards.py plan gives it (the owner of what a leg runs). jobs: ci-shards.py parse_ci of
    ci.yml; conf: .github/ci-shards.json; versions: {"include": [{"bc_version": ...}]}."""
    out = {}
    for legs in cs.plan(selection, jobs, versions, conf, 'schedule').values():
        for j in jobs:
            shards = legs.get(j['key'] or j['test_app_dirs'][0], [])
            out.setdefault(j['test_app_dirs'][0], []).extend(sp for s in shards for sp in cs.spans(s['range']))
    return out


def reuse_rule(selection, base_commit, head_commit, jobs=(), conf=None, versions=None):
    """(reuse(app, ids) -> the ids a master run at head_commit would take from the base run, note).

    selection is the select-tests.py --json result for base_commit..head_commit (None when the script failed). A subset
    selection reuses every codeunit its shard plan does not run (would_run); an app no job runs reuses nothing. A full
    selection reuses nothing, unless every changed file is one CI does not read (select-tests.py: changed_files all in
    ignored_files). The same commit reuses everything."""
    if base_commit == head_commit:
        return (lambda app, ids: set(ids)), 'the base run is at the nightly commit'
    if selection is None:
        return (lambda app, ids: set()), 'select-tests.py gave no selection: a master run would run every test'
    if selection.get('mode') == 'subset':
        runs = would_run(selection, jobs, conf or {}, versions or {'include': []})

        def subset(app, ids):
            if app not in runs:
                return set()
            return {i for i in ids if not any(lo <= i <= hi for lo, hi in runs[app])}
        return subset, None
    changed, ignored = selection.get('changed_files') or [], selection.get('ignored_files')
    if changed and ignored is not None and set(changed) <= set(ignored):
        return (lambda app, ids: set(ids)), 'only files CI does not read changed since the base run'
    return (lambda app, ids: set()), 'full selection: %s' % '; '.join(selection.get('reasons') or ['no reason given'])


# ---------- the comparison ----------

def result(base_manifest, compared=0, differences=(), dropped=0, note=None):
    return {'comparison': 'differs' if differences else 'identical',
            'base_run': base_manifest.get('run_id') if base_manifest else None,
            'base_commit': base_manifest.get('commit') if base_manifest else None,
            'compared': compared, 'dropped': dropped, 'differences': list(differences), 'note': note}


def compare_version(nightly_ver, nightly_files, base_ver, base_files, reuse, base_manifest=None):
    """The comparison of one BC version. *_ver: the version entry of a manifest (base_ver None: the base run lacks it);
    *_files: {JUnit file name: path}; reuse: the first value of reuse_rule."""
    if base_ver is None:
        return result(base_manifest, note='the base run has no results for this BC version')
    if base_ver.get('bc_build') != nightly_ver.get('bc_build'):
        return result(base_manifest, note='the base run ran BC %s, this run BC %s'
                      % (base_ver.get('bc_build'), nightly_ver.get('bc_build')))
    compared, dropped, diffs = 0, 0, []
    for name, leg in sorted((nightly_ver.get('legs') or {}).items()):
        if name not in nightly_files:
            raise SystemExit('this run has no %s, its manifest names it' % name)
        now = read_leg(nightly_files[name])
        if name in (base_ver.get('legs') or {}):
            if name not in base_files:
                raise SystemExit('the base run has no %s, its manifest names it' % name)
            then = read_leg(base_files[name])
        else:
            then = {}
        reused = reuse(leg.get('test_app_dir'), now)
        dropped += len([cu for cu in then if cu not in now and cu in reuse(leg.get('test_app_dir'), then)])
        for cu in sorted(reused):
            compared += 1
            b = then.get(cu)
            src = {'source_run': b and b['source_run'], 'source_commit': b and b['source_commit'],
                   'timestamp': b and b['timestamp']}
            if b is None:
                diffs.append(dict({'leg': name, 'codeunit': cu, 'test': None, 'nightly': None, 'base': None}, **src))
                continue
            for test in sorted(set(now[cu]['tests']) | set(b['tests'])):
                n, o = now[cu]['tests'].get(test, []), b['tests'].get(test, [])
                if n != o:
                    diffs.append(dict({'leg': name, 'codeunit': cu, 'test': test, 'nightly': n, 'base': o}, **src))
    return result(base_manifest, compared, diffs, dropped)


def compare(nightly_manifest, legs_dir, base_manifest, base_dir, reuse, note=None):
    """{bc version: result} for every version of the nightly's manifest. legs_dir and base_dir hold
    <bc version>/<artifact folder>/<JUnit file> (run-artifacts.sh); base_manifest None: no base run."""
    out = {}
    for v, ver in sorted(nightly_manifest['versions'].items()):
        if base_manifest is None:
            out[v] = result(None, note=note or 'no base run')
            continue
        r = compare_version(ver, pv.leg_files(os.path.join(legs_dir, v)), base_manifest['versions'].get(v),
                            pv.leg_files(os.path.join(base_dir, v)), reuse, base_manifest)
        if note and r['note'] is None:
            r['note'] = note
        out[v] = r
    return out


# ---------- the base run ----------

def find_base(runs, head, is_ancestor, fetch_manifest):
    """(run, manifest, notes): the first run of runs (green master push runs, newest first, as the GitHub API returns
    them) whose commit is head or an ancestor of it and whose results manifest counts; (None, None, notes) when none."""
    notes = []
    for r in runs:
        if not is_ancestor(r['head_sha'], head):
            notes.append('run %s: commit %s is not an ancestor of %s' % (r['id'], r['head_sha'][:12], head[:12]))
            continue
        m = fetch_manifest(r)
        if m is None:
            notes.append('run %s: no results manifest' % r['id'])
            continue
        why = pv.check_manifest(m, r)
        if why:
            notes.append('run %s: the manifest does not count: %s' % (r['id'], '; '.join(why)))
            continue
        return r, m, notes
    return None, None, notes


def _gh_json(*args):
    return json.loads(subprocess.run(['gh', *args], check=True, capture_output=True, text=True).stdout)


def _is_ancestor(a, b):
    """git merge-base --is-ancestor; a commit git cannot read counts as no (the search then takes an older run)."""
    return subprocess.run(['git', 'merge-base', '--is-ancestor', a, b], capture_output=True).returncode == 0


def _download(run_id, name, into):
    """The run's artifacts named name into into/<created_at>-<id>/ (run-artifacts.sh, with this run id)."""
    env = dict(os.environ, GITHUB_RUN_ID=str(run_id))
    subprocess.run(['bash', os.path.join(HERE, 'run-artifacts.sh'), name, into], check=True, env=env,
                   stdout=subprocess.DEVNULL)


def _manifest_in(folder):
    names = sorted(os.listdir(folder)) if os.path.isdir(folder) else []
    if not names:
        return None
    path = os.path.join(folder, names[-1], 'results-manifest.json')
    return json.load(open(path)) if os.path.isfile(path) else None


def _select(base, head, out):
    p = subprocess.run([sys.executable, os.path.join(HERE, 'select-tests.py'), '--base', base, '--head', head,
                        '--json', out], stdout=subprocess.DEVNULL)
    return json.load(open(out)) if p.returncode == 0 and os.path.isfile(out) else None


def summary(results):
    lines = ['## Nightly comparison\n', '| BC version | Comparison | Base run | Compared codeunits | Differences | Note |',
             '|---|---|---|---|---|---|']
    for v, r in sorted(results.items()):
        lines.append('| %s | %s | %s | %d | %d | %s |' % (v, r['comparison'], r['base_run'] or '-', r['compared'],
                                                        len(r['differences']), r['note'] or ''))
    diffs = [(v, d) for v, r in sorted(results.items()) for d in r['differences']]
    if diffs:
        lines += ['', '| BC | Leg | Codeunit | Test | This run | Base | Source run | Source commit | Ran at |',
                  '|---|---|---|---|---|---|---|---|---|']
        for v, d in diffs[:200]:
            lines.append('| %s | %s | %s | %s | %s | %s | %s | %s | %s |' % (
                v, d['leg'], d['codeunit'], d['test'] or '(codeunit)', d['nightly'], d['base'], d['source_run'],
                (d['source_commit'] or '')[:12], d['timestamp']))
        if len(diffs) > 200:
            lines.append('\n%d more in the manifest (versions.<v>.comparison_detail.differences).' % (len(diffs) - 200))
    return '\n'.join(lines) + '\n'


def nightly(a, gh_json=_gh_json, download=_download, is_ancestor=_is_ancestor, select=_select):
    """The command nightly; the I/O functions are parameters for the self-test."""
    nightly_manifest = _manifest_in(a.manifest_dir)
    if nightly_manifest is None:
        raise SystemExit('no results-manifest.json of this run in %s' % a.manifest_dir)
    runs = gh_json('api', 'repos/%s/actions/workflows/ci.yml/runs?branch=master&event=push&status=success&per_page=%d'
                    % (a.repo, BASE_CANDIDATES))['workflow_runs']

    def fetch(r):
        d = os.path.join(a.work, 'manifest-%s' % r['id'])
        download(r['id'], 'results-manifest', d)
        return _manifest_in(d)
    run, base_manifest, notes = find_base(runs, a.head, is_ancestor, fetch)
    for n in notes:
        print(n)
    note, reuse = None, None
    if run is None:
        note = 'no green master push run at or before this commit with a results manifest that counts'
    else:
        print('base run %s at %s' % (run['id'], run['head_sha']))
        for v in sorted(nightly_manifest['versions']):
            download(run['id'], 'junit-test-results-%s' % v, os.path.join(a.work, 'base', v))
        selection = None if run['head_sha'] == a.head else select(run['head_sha'], a.head, os.path.join(a.work, 'selection.json'))
        ci = os.path.join(HERE, '..', 'workflows', 'ci.yml')
        reuse, note = reuse_rule(selection, run['head_sha'], a.head, cs.parse_ci(open(ci).read()),
                                 json.load(open(os.path.join(HERE, '..', 'ci-shards.json'))),
                                 {'include': [{'bc_version': v} for v in sorted(nightly_manifest['versions'])]})
    results = compare(nightly_manifest, a.legs, base_manifest, os.path.join(a.work, 'base'), reuse, note)
    pv.set_comparison(nightly_manifest, results)
    with open(a.out, 'w') as f:
        json.dump(nightly_manifest, f, indent=2, sort_keys=True)
        f.write('\n')
    text = summary(results)
    print(text)
    differs = any(r['comparison'] == 'differs' for r in results.values())
    if a.github:
        if os.environ.get('GITHUB_STEP_SUMMARY'):
            with open(os.environ['GITHUB_STEP_SUMMARY'], 'a') as f:
                f.write(text)
        if os.environ.get('GITHUB_OUTPUT'):
            with open(os.environ['GITHUB_OUTPUT'], 'a') as f:
                f.write('differs=%d\n' % differs)
    return 0


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    sub = ap.add_subparsers(dest='cmd', required=True)
    n = sub.add_parser('nightly')
    for x in ('--repo', '--head', '--manifest-dir', '--legs', '--work', '--out'):
        n.add_argument(x, required=True)
    n.add_argument('--github', action='store_true')
    return nightly(ap.parse_args(argv))


if __name__ == '__main__':
    sys.exit(main())
