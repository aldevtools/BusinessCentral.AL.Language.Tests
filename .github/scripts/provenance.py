#!/usr/bin/env python3
"""Which BC build a CI run used, and where each test result came from.

    provenance.py resolve --versions JSON [--github]
    provenance.py stamp --run ID --attempt N --commit SHA --bc-artifact-url URL --app full|partial FILE
    provenance.py manifest --versions JSON --ci-yml FILE --run ID --attempt N --commit SHA --event NAME --dir DIR --out FILE
    provenance.py check-manifest --manifest FILE --run-json FILE

WHY. al-runtime-rs takes the JUnit files of a green master run as its oracle (its ADR-007).
Until now no file recorded the BC build a run used: for 27.5 and 28.5 every shard resolved the newest build of the
minor on its own (bc-linux scripts/download-artifacts.sh), so two shards of one leg could even run two builds. Later
steps reuse results of earlier runs on the same build, which needs the build known before a container starts and
written next to every result (CONTRIBUTING.md, "BC build and result provenance").

resolve: the prepare job's matrix with two keys added to each entry: bc_artifact_url, the URL every leg of the version
passes to bc-linux, and bc_build, the full build. The newest build of the minor comes from Microsoft's index file, the
way bc-linux resolves it: the released storage, and the insider storage only when the released index was read and has
no build of the minor (a read error is retried, so one network error never moves a run to an insider build). A version
with an entry in PINNED takes that URL. Exit 1 when a version cannot be resolved: the run then starts no BC container.
After "Re-run all jobs" the prepare job resolves again, so the build is one per run attempt.

stamp: gives each <testsuite> of FILE a <properties> child with source_run, source_attempt, source_commit, bc_build (the
build of --bc-artifact-url, the URL the leg's shards ran) and app. A suite that already has them (stamped by an earlier
attempt of the same run) keeps them; a suite whose bc_build differs is an error, and so is a file without a suite. The
suite's timestamp is not changed.

manifest: writes the run's results manifest (artifact results-manifest) from the leg files of the run, DIR/<bc
version>/<artifact folder>/<junit file>; per JUnit file name the last artifact folder in name order wins. Exit 1 when a
test job of ci.yml has no file or no codeunit for a version, or a suite lacks this run's provenance (run, commit, app
full) or names another build. The manifest of a nightly run (event schedule) is written the same way; the job
"Nightly comparison" then adds versions.<v>.comparison (set_comparison, called by compare-results.py).

check-manifest: whether a downloaded results manifest counts for its run, given the run as the GitHub API returns it
(gh api repos/<repo>/actions/runs/<id>). It counts only when the run is completed with conclusion success and the
manifest's run_attempt is the run's latest attempt: a later attempt (a re-run) replaces the legs' JUnit artifacts, and
when it ends red the manifest job is skipped, so the manifest of the earlier attempt stays. Exit 1 when it does not
count. Every reader of a manifest goes through this check.
"""
import argparse
import datetime
import importlib.util
import json
import os
import re
import sys
import time
import urllib.request
import xml.etree.ElementTree as ET

HERE = os.path.dirname(os.path.abspath(__file__))
RELEASED = 'https://bcartifacts-exdbf9fwegejdqak.b02.azurefd.net'
INSIDER = 'https://bcinsider-fvh2ekdjecfjd6gk.b02.azurefd.net'
BC_TYPE = 'sandbox'
BC_COUNTRY = 'w1'

# bc_version prefix -> artifact URL. 29.x is pinned to the 29.0 build before 29.0.54011.55892 (published 2026-10-07).
# That build reports debugger protocol 9.0, and no published al tool supports it yet: 18.0.37.11445-beta and
# 18.0.43.1464 stop at 7.0, 30.0.42.60748-beta at 8.0, so every codeunit ended "al runtests exited 1 with no results"
# (corpus #561). Remove the entry once an al tool lists debugger 9.0. (Moved here from the five test jobs of ci.yml.)
PINNED = {'29.': RELEASED + '/sandbox/29.0.54011.55816/w1'}

PROPS = ('source_run', 'source_attempt', 'source_commit', 'bc_build', 'app')
SCHEMA = 1
# versions.<v>.comparison of a nightly run's manifest (compare-results.py): al-runtime-rs refuses a bump while the newest
# nightly at or before the bumped run's commit does not say "identical" for every BC version, unless the bumped run is
# that nightly and the comparison job is its only failed job (its ADR-077, decisions 5 and 6).
# "incomplete": the base run holds results reused from an earlier run that the comparison did not look at.
COMPARISONS = ('identical', 'differs', 'incomplete')


# ---------- resolve ----------

BUILD = re.compile(r'[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')  # a full BC build: four groups of ASCII digits


def _vkey(v):
    return tuple(int(x) for x in v.split('.'))


def newest(index, prefix):
    """The newest build in a Microsoft index file (a JSON list of {"Version": ...}) that starts with prefix + '.'."""
    versions = [d.get('Version') for d in index if isinstance(d, dict)]
    versions = [v for v in versions if isinstance(v, str) and BUILD.fullmatch(v) and v.startswith(prefix + '.')]
    return max(versions, key=_vkey) if versions else None


def _fetch(url):
    with urllib.request.urlopen(url, timeout=60) as r:
        return json.load(r)


def build_of(url):
    """The build of an artifact URL <base>/<type>/<build>/<country>; exit 1 when the URL has no full build there."""
    parts = (url or '').rstrip('/').split('/')
    if len(parts) < 3 or not BUILD.fullmatch(parts[-2]):
        raise SystemExit('no BC build in the artifact URL %r: expected <base>/<type>/<build>/<country>' % url)
    return parts[-2]


def resolve_one(bc_version, fetch=_fetch, attempts=3, pause=3):
    for prefix, url in PINNED.items():
        if bc_version.startswith(prefix):
            return url, build_of(url)
    if len(bc_version.split('.')) >= 3:  # a full build: bc-linux downloads it from the released storage as it is
        url = '%s/%s/%s/%s' % (RELEASED, BC_TYPE, bc_version, BC_COUNTRY)
        return url, build_of(url)
    errors = []
    for attempt in range(attempts):
        for base in (RELEASED, INSIDER):
            index_url = '%s/%s/indexes/%s.json' % (base, BC_TYPE, BC_COUNTRY)
            try:
                found = newest(fetch(index_url), bc_version)
            except Exception as e:  # network or JSON error: the next attempt, never the next storage
                errors.append('%s: %s' % (index_url, e))
                break
            if found:
                url = '%s/%s/%s/%s' % (base, BC_TYPE, found, BC_COUNTRY)
                return url, build_of(url)
        else:
            break  # both indexes read, neither has the minor: another attempt reads the same files
        if attempt + 1 < attempts:
            time.sleep(pause)
    raise SystemExit('::error title=BC build::no %s.x build in the index files of the released or insider storage%s'
                     % (bc_version, ('; ' + '; '.join(errors[-2:])) if errors else ''))


def resolve(versions, fetch=_fetch, pause=3):
    out = {'include': []}
    for entry in versions.get('include', []):
        url, build = resolve_one(entry['bc_version'], fetch=fetch, pause=pause)
        out['include'].append(dict(entry, bc_artifact_url=url, bc_build=build))
    return out


def resolve_summary(matrix):
    lines = ['## BC builds of this run\n', '| BC version | Build | Artifact URL |', '|---|---|---|']
    for e in matrix['include']:
        lines.append('| %s | %s | %s |' % (e['bc_version'], e['bc_build'], e['bc_artifact_url']))
    return '\n'.join(lines) + '\n'


# ---------- stamp ----------

def provenance(suite):
    """{name: value} of the provenance properties of a <testsuite> (empty when it has none)."""
    props = suite.find('properties')
    if props is None:
        return {}
    return {p.get('name'): p.get('value') for p in props.findall('property') if p.get('name') in PROPS}


def stamp(path, run, attempt, commit, bc_artifact_url, app):
    if not (run and attempt and commit) or app not in ('full', 'partial'):
        raise SystemExit('stamp: --run, --attempt and --commit must be set, --app full or partial')
    bc_build = build_of(bc_artifact_url)
    tree = ET.parse(path)
    suites = tree.getroot().findall('testsuite')
    if not suites:
        raise SystemExit('stamp: %s has no <testsuite> under its root <%s>' % (path, tree.getroot().tag))
    new = 0
    for s in suites:
        have = provenance(s)
        if have:
            if set(have) != set(PROPS):
                raise SystemExit('stamp: %s has only %s of the provenance properties' % (s.get('name'), sorted(have)))
            if have['bc_build'] != bc_build:
                raise SystemExit('stamp: %s was run on BC %s, this leg on %s' % (s.get('name'), have['bc_build'], bc_build))
            continue
        props = s.find('properties')
        if props is None:
            props = ET.Element('properties')
            s.insert(0, props)  # the JUnit schema puts <properties> before the test cases
        for name, value in zip(PROPS, (run, attempt, commit, bc_build, app)):
            ET.SubElement(props, 'property', {'name': name, 'value': str(value)})
        new += 1
    tree.write(path, encoding='unicode', xml_declaration=True)
    return new


# ---------- manifest ----------

def _ci_jobs(ci_text):
    spec = importlib.util.spec_from_file_location('select_tests', os.path.join(HERE, 'select-tests.py'))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod.parse_ci(ci_text)


def junit_name(test_app_dir):
    """The JUnit file name of a leg, as bc-leg.yml's job test names it."""
    return 'junit-%s.xml' % os.path.basename(test_app_dir.rstrip('/'))


def leg_files(version_dir):
    """{junit file name: path}; a later artifact folder (name order) replaces an earlier one."""
    out = {}
    if not os.path.isdir(version_dir):
        return out
    for folder in sorted(os.listdir(version_dir)):
        d = os.path.join(version_dir, folder)
        if not os.path.isdir(d):
            continue
        for f in sorted(os.listdir(d)):
            if f.startswith('junit-') and f.endswith('.xml'):
                out[f] = os.path.join(d, f)
    return out


def manifest(versions, jobs, run, attempt, commit, event, root):
    errors = []
    expected = {junit_name(j['test_app_dirs'][0]): j['test_app_dirs'][0] for j in jobs}
    out = {'schema': SCHEMA, 'run_id': int(run), 'run_attempt': int(attempt), 'commit': commit, 'event': event,
           'base_run': None, 'base_commit': None,
           'created': datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'), 'versions': {}}
    for entry in versions.get('include', []):
        v, build = entry['bc_version'], entry.get('bc_build', '')
        files = leg_files(os.path.join(root, v))
        for name in sorted(set(expected) - set(files)):
            errors.append('BC %s: no %s (test app %s)' % (v, name, expected[name]))
        legs = {}
        for name, path in sorted(files.items()):
            fresh = 0
            for s in ET.parse(path).getroot().findall('testsuite'):
                p = provenance(s)
                if (p.get('source_run') != str(run) or p.get('source_commit') != commit or p.get('bc_build') != build
                        or p.get('app') != 'full'):
                    errors.append('BC %s, %s, %s: provenance %s, expected source_run %s, source_commit %s, bc_build %s, '
                                  'app full' % (v, name, s.get('name'), p or 'missing', run, commit, build))
                    continue
                fresh += 1
            if not fresh:
                errors.append('BC %s, %s: no codeunit of this run' % (v, name))
            legs[name] = {'test_app_dir': expected.get(name), 'fresh': fresh, 'reused': 0, 'dropped': 0,
                          'oldest_source_run': int(run)}
        out['versions'][v] = {'bc_build': build, 'bc_artifact_url': entry.get('bc_artifact_url', ''), 'mode': 'full',
                              'chain': 0, 'app': 'full', 'legs': legs}
    return out, errors


def set_comparison(manifest, results):
    """Writes the nightly comparison into a manifest: versions.<v>.comparison (one of COMPARISONS) and
    versions.<v>.comparison_detail (the rest of the result of compare-results.py). Exit 1 when a version of the
    manifest has no result or another answer."""
    for v, entry in sorted(manifest['versions'].items()):
        r = dict(results.get(v) or {})
        answer = r.pop('comparison', None)
        if answer not in COMPARISONS:
            raise SystemExit('set_comparison: BC %s: comparison %r, expected one of %s' % (v, answer, ', '.join(COMPARISONS)))
        entry['comparison'] = answer
        entry['comparison_detail'] = r
    return manifest


def check_manifest(manifest, run):
    """[] when the manifest counts for run (the GitHub API run object), else the reasons it does not."""
    why = []
    if manifest.get('schema') != SCHEMA:
        why.append('manifest schema %r, expected %d' % (manifest.get('schema'), SCHEMA))
    if manifest.get('run_id') != run.get('id'):
        why.append('manifest of run %r, not of run %r' % (manifest.get('run_id'), run.get('id')))
    if manifest.get('commit') != run.get('head_sha'):
        why.append('manifest commit %r, run commit %r' % (manifest.get('commit'), run.get('head_sha')))
    if (run.get('status'), run.get('conclusion')) != ('completed', 'success'):
        why.append('run %s, conclusion %s' % (run.get('status'), run.get('conclusion')))
    if manifest.get('run_attempt') != run.get('run_attempt'):
        why.append('manifest of attempt %r, the run is at attempt %r' % (manifest.get('run_attempt'), run.get('run_attempt')))
    return why


# ---------- command line ----------

def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    sub = ap.add_subparsers(dest='cmd', required=True)
    r = sub.add_parser('resolve')
    r.add_argument('--versions', required=True, help='the prepare job matrix, {"include": [{"bc_version": ...}]}')
    r.add_argument('--github', action='store_true', help='also write a table to $GITHUB_STEP_SUMMARY')
    s = sub.add_parser('stamp')
    for a in ('--run', '--attempt', '--commit', '--bc-artifact-url', '--app'):
        s.add_argument(a, required=True)
    s.add_argument('file')
    m = sub.add_parser('manifest')
    m.add_argument('--versions', required=True, help='the resolved matrix (resolve output)')
    m.add_argument('--ci-yml', required=True)
    for a in ('--run', '--attempt', '--commit', '--event', '--dir', '--out'):
        m.add_argument(a, required=True)
    c = sub.add_parser('check-manifest')
    c.add_argument('--manifest', required=True, help='results-manifest.json of the run')
    c.add_argument('--run-json', required=True, help='the run: gh api repos/<repo>/actions/runs/<id> > FILE')
    a = ap.parse_args(argv)

    if a.cmd == 'resolve':
        matrix = resolve(json.loads(a.versions))
        if a.github and os.environ.get('GITHUB_STEP_SUMMARY'):
            with open(os.environ['GITHUB_STEP_SUMMARY'], 'a') as f:
                f.write(resolve_summary(matrix))
        print(json.dumps(matrix, separators=(',', ':')))
    elif a.cmd == 'stamp':
        n = stamp(a.file, a.run, a.attempt, a.commit, a.bc_artifact_url, a.app)
        print('stamped %d codeunit(s) of %s with run %s, BC %s' % (n, a.file, a.run, build_of(a.bc_artifact_url)))
    elif a.cmd == 'check-manifest':
        why = check_manifest(json.load(open(a.manifest)), json.load(open(a.run_json)))
        for w in why:
            print('the manifest does not count: %s' % w)
        return 1 if why else 0
    else:
        jobs = _ci_jobs(open(a.ci_yml).read())
        out, errors = manifest(json.loads(a.versions), jobs, a.run, a.attempt, a.commit, a.event, a.dir)
        with open(a.out, 'w') as f:
            json.dump(out, f, indent=2, sort_keys=True)
            f.write('\n')
        for v, e in out['versions'].items():
            print('BC %s (%s): %s' % (v, e['bc_build'], ', '.join('%s %d' % (n, l['fresh']) for n, l in e['legs'].items())))
        if errors:
            for e in errors:
                print('::error title=Results manifest::%s' % e)
            return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
