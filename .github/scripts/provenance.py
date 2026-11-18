#!/usr/bin/env python3
"""Which BC build a CI run used, and where each test result came from.

    provenance.py resolve --versions JSON [--github]
    provenance.py stamp --run ID --attempt N --commit SHA --bc-build BUILD --app full|partial FILE
    provenance.py manifest --versions JSON --ci-yml FILE --run ID --attempt N --commit SHA --event NAME --dir DIR --out FILE

WHY. al-runtime-rs takes the JUnit files of a green master run as its oracle (its ADR-007).
Until now no file recorded the BC build a run used: for 27.5 and 28.5 every shard resolved the newest build of the
minor on its own (bc-linux scripts/download-artifacts.sh), so two shards of one leg could even run two builds. Later
steps reuse results of earlier runs on the same build, which needs the build known before a container starts and
written next to every result (CONTRIBUTING.md, "BC build and result provenance").

resolve: the prepare job's matrix with two keys added to each entry: bc_artifact_url, the URL every leg of the version
passes to bc-linux, and bc_build, the full build. The newest build of the minor comes from Microsoft's index file, the
way bc-linux resolves it (released storage first, then the insider storage). A version with an entry in PINNED takes
that URL. Exit 1 when a version cannot be resolved: the run then starts no BC container.

stamp: gives each <testsuite> of FILE a <properties> child with source_run, source_attempt, source_commit, bc_build and
app. A suite that already has them (stamped by an earlier attempt of the same run) keeps them; a suite whose bc_build
differs from --bc-build is an error. The suite's timestamp is not changed.

manifest: writes the run's results manifest (artifact results-manifest) from the leg files of the run, DIR/<bc
version>/<artifact folder>/<junit file>; per JUnit file name the last artifact folder in name order wins. Exit 1 when a
test job of ci.yml has no file for a version, or a suite lacks this run's provenance or names another build.
"""
import argparse
import datetime
import importlib.util
import json
import os
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


# ---------- resolve ----------

def _vkey(v):
    return tuple(int(x) for x in v.split('.'))


def newest(index, prefix):
    """The newest Version in a Microsoft index file (a JSON list of {"Version": ...}) that starts with prefix + '.'."""
    versions = [d.get('Version', '') for d in index if isinstance(d, dict)]
    versions = [v for v in versions if v.startswith(prefix + '.')]
    return max(versions, key=_vkey) if versions else None


def _fetch(url):
    with urllib.request.urlopen(url, timeout=60) as r:
        return json.load(r)


def build_of(url):
    """The build of an artifact URL <base>/<type>/<build>/<country>."""
    return url.rstrip('/').split('/')[-2]


def resolve_one(bc_version, fetch=_fetch, attempts=3, pause=3):
    for prefix, url in PINNED.items():
        if bc_version.startswith(prefix):
            return url, build_of(url)
    if len(bc_version.split('.')) >= 3:  # a full build: bc-linux downloads it from the released storage as it is
        return '%s/%s/%s/%s' % (RELEASED, BC_TYPE, bc_version, BC_COUNTRY), bc_version
    errors = []
    for attempt in range(attempts):
        for base in (RELEASED, INSIDER):
            index_url = '%s/%s/indexes/%s.json' % (base, BC_TYPE, BC_COUNTRY)
            try:
                found = newest(fetch(index_url), bc_version)
            except Exception as e:  # network or JSON error: try the next storage, then the next attempt
                errors.append('%s: %s' % (index_url, e))
                continue
            if found:
                return '%s/%s/%s/%s' % (base, BC_TYPE, found, BC_COUNTRY), found
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


def stamp(path, run, attempt, commit, bc_build, app):
    if not (run and attempt and commit and bc_build) or app not in ('full', 'partial'):
        raise SystemExit('stamp: --run, --attempt, --commit and --bc-build must be set, --app full or partial')
    tree = ET.parse(path)
    new = 0
    for s in tree.getroot().findall('testsuite'):
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
                if p.get('source_run') != str(run) or p.get('bc_build') != build or p.get('app') != 'full':
                    errors.append('BC %s, %s, %s: provenance %s, expected source_run %s, bc_build %s, app full'
                                  % (v, name, s.get('name'), p or 'missing', run, build))
                    continue
                fresh += 1
            legs[name] = {'test_app_dir': expected.get(name), 'fresh': fresh, 'reused': 0, 'dropped': 0,
                          'oldest_source_run': int(run)}
        out['versions'][v] = {'bc_build': build, 'bc_artifact_url': entry.get('bc_artifact_url', ''), 'mode': 'full',
                              'chain': 0, 'app': 'full', 'legs': legs}
    return out, errors


# ---------- command line ----------

def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    sub = ap.add_subparsers(dest='cmd', required=True)
    r = sub.add_parser('resolve')
    r.add_argument('--versions', required=True, help='the prepare job matrix, {"include": [{"bc_version": ...}]}')
    r.add_argument('--github', action='store_true', help='also write a table to $GITHUB_STEP_SUMMARY')
    s = sub.add_parser('stamp')
    for a in ('--run', '--attempt', '--commit', '--bc-build', '--app'):
        s.add_argument(a, required=True)
    s.add_argument('file')
    m = sub.add_parser('manifest')
    m.add_argument('--versions', required=True, help='the resolved matrix (resolve output)')
    m.add_argument('--ci-yml', required=True)
    for a in ('--run', '--attempt', '--commit', '--event', '--dir', '--out'):
        m.add_argument(a, required=True)
    a = ap.parse_args(argv)

    if a.cmd == 'resolve':
        matrix = resolve(json.loads(a.versions))
        if a.github and os.environ.get('GITHUB_STEP_SUMMARY'):
            with open(os.environ['GITHUB_STEP_SUMMARY'], 'a') as f:
                f.write(resolve_summary(matrix))
        print(json.dumps(matrix, separators=(',', ':')))
    elif a.cmd == 'stamp':
        n = stamp(a.file, a.run, a.attempt, a.commit, a.bc_build, a.app)
        print('stamped %d codeunit(s) of %s with run %s, BC %s' % (n, a.file, a.run, a.bc_build))
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
