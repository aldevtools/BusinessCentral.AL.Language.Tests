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
base run (reuse_rule), each test of them key by key (leg, codeunit, test name -> list of outcomes). The base run is the
newest green master push run of this workflow whose commit is the nightly's commit or an ancestor of it and whose
results manifest counts (provenance.py check-manifest). A reused codeunit without a base result is a difference. A
compared codeunit that the base run has and the nightly lacks is dropped (counted, not a difference) only when the base commit is not
the nightly's commit and the diff between them deleted or renamed every file that declared it (make_gone); otherwise it
is a difference.

The answer of a version (result): "differs" with a difference; else "incomplete" when the base run holds results it
reused from an earlier run and not all of them were compared or dropped; else "identical". Another BC build than the
base's, a version the base run lacks, or no base run at all: nothing is compared ("compared": 0, the reason in
"note"), so the answer is "identical" only when the base run reused nothing there.

nightly: finds the base run, downloads its manifest and its legs' JUnit files into WORK (run-artifacts.sh), runs
select-tests.py from the base commit to SHA, compares, and writes the nightly's manifest (the job manifest's
results-manifest.json, downloaded into --manifest-dir by run-artifacts.sh) with versions.<v>.comparison and
versions.<v>.comparison_detail to OUT (provenance.py set_comparison). With --github it writes "answer=" and the answer
of the run ("differs" if a version differs, else "incomplete" if one is, else "identical") to $GITHUB_OUTPUT. Exit 1
when the comparison could not run (a git error included); OUT is then not written, so the manifest keeps no comparison.
"""
import argparse
import importlib.util
import json
import os
import re
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
        if int(name[1]) in out:
            raise SystemExit('%s: codeunit %s has two suites' % (path, name[1]))
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

def result(base_manifest, compared=0, differences=(), dropped=0, base_reused=0, base_reused_compared=0,
           source_runs=None, note=None):
    """The answer of one version: "differs" with a difference; else "incomplete" when the base run holds results reused
    from an earlier run that were not compared (or dropped); else "identical"."""
    answer = 'differs' if differences else 'incomplete' if base_reused != base_reused_compared else 'identical'
    return {'comparison': answer,
            'compared_run': base_manifest.get('run_id') if base_manifest else None,
            'compared_commit': base_manifest.get('commit') if base_manifest else None,
            # The attempt of the base run that was downloaded (check_manifest: the manifest is of the run's latest
            # attempt). al-runtime-rs compares it with the attempt of the run it bumps to.
            'compared_attempt': base_manifest.get('run_attempt') if base_manifest else None,
            'compared': compared, 'dropped': dropped, 'base_reused': base_reused,
            'base_reused_compared': base_reused_compared, 'source_runs': dict(sorted((source_runs or {}).items())),
            'differences': list(differences), 'note': note}


def compare_version(nightly_ver, nightly_files, base_ver, base_files, reuse, base_manifest, gone=None):
    """The comparison of one BC version. *_ver: the version entry of a manifest (base_ver None: the base run lacks it);
    *_files: {JUnit file name: path}; reuse: the first value of reuse_rule; gone(test app dir, codeunit): True when the
    diff from the base commit deleted or renamed every file that declared it (make_gone; None: the same commit).

    base_reused counts the base run's suites that it reused from an earlier run (source_run is not the base run);
    base_reused_compared those of them that were compared or dropped. source_runs: {source run: compared codeunits},
    the runs whose results the comparison looked at. A base suite without source_run stops the comparison."""
    if base_ver is None:
        return result(base_manifest, note='the base run has no results for this BC version')
    base_run = str(base_manifest.get('run_id'))
    then_legs = {}
    for name in sorted(base_ver.get('legs') or {}):
        if name not in base_files:
            raise SystemExit('the base run has no %s, its manifest names it' % name)
        then_legs[name] = read_leg(base_files[name])
        unstamped = sorted(cu for cu, b in then_legs[name].items() if not b['source_run'])
        if unstamped:
            raise SystemExit('the base run\'s %s has no source_run for codeunits %s' % (name, unstamped[:5]))
    base_reused = sum(1 for then in then_legs.values() for b in then.values() if b['source_run'] != base_run)
    if base_ver.get('bc_build') != nightly_ver.get('bc_build'):
        return result(base_manifest, base_reused=base_reused, note='the base run ran BC %s, this run BC %s'
                      % (base_ver.get('bc_build'), nightly_ver.get('bc_build')))
    compared, dropped, looked, diffs, runs = 0, 0, 0, [], {}

    def source(b):
        return {'source_run': b and b['source_run'], 'source_commit': b and b['source_commit'],
                'timestamp': b and b['timestamp']}
    for name, leg in sorted((nightly_ver.get('legs') or {}).items()):
        if name not in nightly_files:
            raise SystemExit('this run has no %s, its manifest names it' % name)
        now, then, app = read_leg(nightly_files[name]), then_legs.get(name, {}), leg.get('test_app_dir')
        for cu in sorted(reuse(app, now)):
            compared += 1
            b = then.get(cu)
            if b is None:
                diffs.append(dict({'leg': name, 'codeunit': cu, 'test': None, 'nightly': None, 'base': None}, **source(b)))
                continue
            looked += b['source_run'] != base_run
            runs[b['source_run']] = runs.get(b['source_run'], 0) + 1
            for test in sorted(set(now[cu]['tests']) | set(b['tests'])):
                n, o = now[cu]['tests'].get(test, []), b['tests'].get(test, [])
                if n != o:
                    diffs.append(dict({'leg': name, 'codeunit': cu, 'test': test, 'nightly': n, 'base': o}, **source(b)))
        for cu in sorted(reuse(app, [cu for cu in then if cu not in now])):
            b = then[cu]
            looked += b['source_run'] != base_run
            if gone is not None and gone(app, cu):
                dropped += 1
            else:
                diffs.append(dict({'leg': name, 'codeunit': cu, 'test': None, 'nightly': None, 'base': b['tests']},
                                  **source(b)))
    return result(base_manifest, compared, diffs, dropped, base_reused, looked, runs)


def compare(nightly_manifest, legs_dir, base_manifest, base_dir, reuse, note=None, gone=None):
    """{bc version: result} for every version of the nightly's manifest. legs_dir and base_dir hold
    <bc version>/<artifact folder>/<JUnit file> (run-artifacts.sh); base_manifest None: no base run."""
    out = {}
    for v, ver in sorted(nightly_manifest['versions'].items()):
        if base_manifest is None:
            out[v] = result(None, note=note or 'no base run')
            continue
        r = compare_version(ver, pv.leg_files(os.path.join(legs_dir, v)), base_manifest['versions'].get(v),
                            pv.leg_files(os.path.join(base_dir, v)), reuse, base_manifest, gone)
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


def _git(args, cwd=None):
    return subprocess.run(['git', *args], cwd=cwd, capture_output=True, text=True)


def _is_ancestor(a, b, cwd=None):
    """git merge-base --is-ancestor: exit 0 is yes, exit 1 is no; any other exit (a commit git cannot read) stops the
    comparison."""
    p = _git(['merge-base', '--is-ancestor', a, b], cwd)
    if p.returncode not in (0, 1):
        raise SystemExit('git merge-base --is-ancestor %s %s failed (exit %d): %s'
                         % (a[:12], b[:12], p.returncode, p.stderr.strip()))
    return p.returncode == 0


# A line that declares a codeunit: the same rule and the same git grep as al-runtime-rs (DECLARATION and tree in
# tools/corpus_bump_provenance.py).
DECLARATION = re.compile(r'\s*codeunit\s+(\d+)(\s|$)', re.I)


def make_gone(base, head, cwd=None):
    """gone(test app dir, codeunit): True when the diff base..head deleted or renamed every file under the test app
    dir that declared the codeunit at base (the rule of al-runtime-rs, check_missing in
    tools/corpus_bump_provenance.py). A codeunit no file declared is not gone."""
    p = _git(['diff', '--name-status', '-M', base, head], cwd)
    if p.returncode != 0:
        raise SystemExit('git diff %s %s failed: %s' % (base[:12], head[:12], p.stderr.strip()))
    deleted = {f[1] for f in (line.split('\t') for line in p.stdout.splitlines()) if f[0] == 'D' or f[0].startswith('R')}
    declared = {}

    def files_of(app):
        if app not in declared:
            p = _git(['grep', '-I', '-i', '-E', '--null', '-e', r'^[[:space:]]*codeunit[[:space:]]+[0-9]+([[:space:]]|$)',
                      base, '--', app], cwd)
            if p.returncode not in (0, 1):
                raise SystemExit('git grep at %s failed: %s' % (base[:12], p.stderr.strip()))
            out = {}
            for line in p.stdout.splitlines():
                name, _, text = line.partition('\0')
                m = DECLARATION.match(text)
                if m:
                    out.setdefault(int(m.group(1)), set()).add(name.split(':', 1)[1])
            declared[app] = out
        return declared[app]

    def gone(app, cu):
        files = files_of(app).get(cu, [])
        return bool(files) and all(f in deleted for f in files)
    return gone


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
    lines = ['## Nightly comparison\n',
             '| BC version | Comparison | Base run | Compared codeunits | Dropped | Reused in the base run (compared / all) '
             '| Differences | Note |', '|---|---|---|---|---|---|---|---|']
    for v, r in sorted(results.items()):
        lines.append('| %s | %s | %s | %d | %d | %d / %d | %d | %s |' % (
            v, r['comparison'], r['compared_run'] or '-', r['compared'], r['dropped'], r['base_reused_compared'],
            r['base_reused'], len(r['differences']), r['note'] or ''))
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


def nightly(a, gh_json=_gh_json, download=_download, is_ancestor=_is_ancestor, select=_select, gone_rule=make_gone):
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
    note, reuse, gone = None, None, None
    if run is None:
        note = 'no green master push run at or before this commit with a results manifest that counts'
    else:
        print('base run %s at %s' % (run['id'], run['head_sha']))
        for v in sorted(nightly_manifest['versions']):
            download(run['id'], 'junit-test-results-%s' % v, os.path.join(a.work, 'base', v))
        same = run['head_sha'] == a.head
        selection = None if same else select(run['head_sha'], a.head, os.path.join(a.work, 'selection.json'))
        gone = None if same else gone_rule(run['head_sha'], a.head)
        ci = os.path.join(HERE, '..', 'workflows', 'ci.yml')
        reuse, note = reuse_rule(selection, run['head_sha'], a.head, cs.parse_ci(open(ci).read()),
                                 json.load(open(os.path.join(HERE, '..', 'ci-shards.json'))),
                                 {'include': [{'bc_version': v} for v in sorted(nightly_manifest['versions'])]})
    results = compare(nightly_manifest, a.legs, base_manifest, os.path.join(a.work, 'base'), reuse, note, gone)
    pv.set_comparison(nightly_manifest, results)
    with open(a.out, 'w') as f:
        json.dump(nightly_manifest, f, indent=2, sort_keys=True)
        f.write('\n')
    text = summary(results)
    print(text)
    answers = {r['comparison'] for r in results.values()}
    answer = 'differs' if 'differs' in answers else 'incomplete' if 'incomplete' in answers else 'identical'
    if a.github:
        if os.environ.get('GITHUB_STEP_SUMMARY'):
            with open(os.environ['GITHUB_STEP_SUMMARY'], 'a') as f:
                f.write(text)
        if os.environ.get('GITHUB_OUTPUT'):
            with open(os.environ['GITHUB_OUTPUT'], 'a') as f:
                f.write('answer=%s\n' % answer)
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
