#!/usr/bin/env python3
"""Compile every file of tests/must-not-compile/cases/ with a real AL compiler and check that it is REJECTED with exactly the diagnostics
the header of the file records. See tests/must-not-compile/README.md for the header grammar.

usage: check-must-not-compile.py --al "<AL command>" --symbols DIR [--bc-major 27] [--al-major N] [--cases DIR] [--only NAME] [--keep]
  --al        the compiler command, called as: <al> compile /project:DIR /packagecachepath:DIR/.alpackages /out:FILE [/define:...]
  --symbols   a folder with the .app symbol packages of the BC major (Application, Base Application, System Application, ...)
  --bc-major  the BC major under test (decides @from / @until); default 27
  --al-major  the compiler's major version (decides @min-al); default: unknown, cases with @min-al are then run
Exit status 0 when every case behaves as recorded, 1 otherwise."""
import argparse, json, os, re, shutil, subprocess, sys, tempfile

DIAG = re.compile(r'^(?:(?P<file>.*?)(?:\((?P<line>\d+),(?P<col>\d+)\))?: )?error (?P<code>AL\d+): (?P<msg>.*?)\s*(?:\[.*\])?\s*$')

DEFAULT_APP = {
    "id": "6c1f3a52-1b6e-4d1e-9a0a-1f7e4c2b9d10",
    "name": "Must Not Compile",
    "publisher": "AL Language",
    "version": "1.0.0.0",
    "dependencies": [],
    "idRanges": [{"from": 50000, "to": 59999}],
    "platform": "27.0.0.0",
    "application": "27.0.0.0",
    "runtime": "16.0",
    "target": "Cloud",
}
# The app runtime follows the BC major: the newest runtime each server accepts at publish
# (corpus run 39110861115: 27.5 up to 16.1, 28.5 up to 17.1, 29.0 up to 18.0).
RUNTIME_BY_BC_MAJOR = {27: "16.1", 28: "17.1", 29: "18.0"}
DEPENDENCIES = {
    "Base Application": ("437dbf0e-84ff-417a-965d-ed2bb9650972", "Microsoft"),
    "System Application": ("63ca2fa4-4f03-4f2b-a480-172fef340d3f", "Microsoft"),
}
# Corpus apps a cross-app case may depend on (CONTRIBUTING.md, "Multi-app fixtures"). Their compiled .app files, and those of their own
# dependencies, must be in the --symbols folder: compile them first, in the order ci.yml lists them.
CORPUS_DEPENDENCIES = {
    "AL Internals Test Fixture": ("f1e2d3c4-b5a6-7890-fedc-ba9876543210", "AL Language", "1.0.0.0"),
    "AL Language XApp A": ("cd6a4292-f27b-4af9-89bc-15a5956f5c71", "AL Language", "1.0.0.0"),
    "AL Language XApp B": ("c87ced6d-11a6-4ad2-87c7-ac10083d0a2f", "Zulu Probe Publisher", "1.0.0.0"),
    "AL Language XApp C": ("0df0fadc-d339-4b0f-a1d5-51dc51f10900", "Bravo Probe Publisher", "1.0.0.0"),
    "AL Language XApp D": ("e92be076-de11-44ed-895e-17031341df29", "Mike Probe Publisher", "1.0.0.0"),
    "AL Language XApp N": ("01a5e2c7-4f3b-4d1e-9b6a-2c8d7e1f0a53", "Yankee Probe Publisher", "1.0.0.0"),
    "AL Language XApp T": ("f7c3b9d2-6a41-4e85-8d0f-b3a97c5e1d26", "Aaa Probe Publisher", "1.0.0.0"),
    "AL Language XApp E": ("0b3f52e8-9d3a-4f61-b8e2-5a07c3d91f45", "Echo Probe Publisher", "1.0.0.0"),
    "AL Language XApp F": ("f2a8c113-3c17-4e9a-a5d4-e81b26f07c39", "Whiskey Probe Publisher", "1.0.0.0"),
}


def dependency(name):
    """The app.json dependency entry for a name of @depends."""
    if name in CORPUS_DEPENDENCIES:
        gid, pub, ver = CORPUS_DEPENDENCIES[name]
    else:
        (gid, pub), ver = DEPENDENCIES[name], "27.0.0.0"
    return {"id": gid, "name": name, "publisher": pub, "version": ver}


def parse_header(text):
    """Return the dict of the '// @key value' lines at the top of the file."""
    h = {"expect": [], "appjson": {}}
    for line in text.splitlines():
        m = re.match(r'^//\s*@(\w[\w-]*)\s*(.*)$', line)
        if not m:
            if line.strip() == '' or line.startswith('//'):
                continue
            break
        key, val = m.group(1), m.group(2).strip()
        if key == 'expect':
            code, _, msg = val.partition('|')
            h['expect'].append((code.strip(), msg.strip()))
        elif key == 'appjson':
            h['appjson'].update(json.loads(val))
        else:
            h[key] = val
    return h


def parse_diagnostics(output):
    found = []
    for line in output.splitlines():
        m = DIAG.match(line.strip())
        if m:
            found.append((m.group('code'), m.group('msg').strip(), m.group('line')))
    return found


def applies(h, bc_major, al_major):
    if 'from' in h and bc_major < int(h['from']):
        return False
    if 'until' in h and bc_major > int(h['until']):
        return False
    if 'min-al' in h and al_major is not None and al_major < int(h['min-al']):
        return False
    if 'max-al' in h and al_major is not None and al_major > int(h['max-al']):
        return False
    return True


def build_project(root, case_path, h, symbols, runtime=None):
    app = json.loads(json.dumps(DEFAULT_APP))
    if runtime:
        app['runtime'] = runtime
    app['target'] = h.get('target', 'Cloud')
    for name in h.get('depends', 'Base Application,System Application').split(','):
        name = name.strip()
        if name:
            app['dependencies'].append(dependency(name))
    app.update(h['appjson'])
    os.makedirs(os.path.join(root, 'src'))
    os.makedirs(os.path.join(root, '.alpackages'))
    json.dump(app, open(os.path.join(root, 'app.json'), 'w'), indent=2)
    shutil.copy(case_path, os.path.join(root, 'src', 'case.al'))
    for f in os.listdir(symbols):
        if f.endswith('.app'):
            os.symlink(os.path.abspath(os.path.join(symbols, f)), os.path.join(root, '.alpackages', f))


def run_case(al, symbols, case_path, h, define, runtime=None):
    with tempfile.TemporaryDirectory(prefix='mnc-') as root:
        build_project(root, case_path, h, symbols, runtime)
        cmd = al.split() + ['compile', '/project:' + root, '/packagecachepath:' + os.path.join(root, '.alpackages'),
                            '/out:' + os.path.join(root, 'out.app')]
        if define:
            cmd.append('/define:' + define)
        p = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL, text=True)
        built = os.path.exists(os.path.join(root, 'out.app'))
        return p.returncode, built, p.stdout


def check(expected, found):
    """Return a list of problems; the codes must match as a multiset and every recorded message must be the start of (or equal to) the found one:
    the compilers differ in the explanation they append after the first sentence."""
    problems = []
    exp = list(expected)
    got = list(found)
    for code, msg in exp:
        hit = next((g for g in got if g[0] == code and (msg == '' or g[1] == msg or g[1].startswith(msg))), None)
        if hit is None:
            same = [g for g in got if g[0] == code]
            if same:
                problems.append('code %s found with another text: %r (recorded %r)' % (code, same[0][1], msg))
            else:
                problems.append('expected diagnostic %s not reported' % code)
        else:
            got.remove(hit)
    for g in got:
        problems.append('unexpected diagnostic %s: %s' % (g[0], g[1]))
    return problems


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--al', required=True)
    ap.add_argument('--symbols', required=True)
    ap.add_argument('--bc-major', type=int, default=27)
    ap.add_argument('--al-major', type=int)
    ap.add_argument('--runtime', help='app.json runtime; default follows --bc-major (RUNTIME_BY_BC_MAJOR)')
    ap.add_argument('--cases', default=os.path.join(os.path.dirname(__file__), '..', '..', 'tests', 'must-not-compile', 'cases'))
    ap.add_argument('--only')
    a = ap.parse_args()
    cases = sorted(f for f in os.listdir(a.cases) if f.endswith('.al'))
    if a.only:
        cases = [c for c in cases if a.only in c]
    runtime = a.runtime or RUNTIME_BY_BC_MAJOR.get(a.bc_major)
    bad = 0
    ran = 0
    for c in cases:
        path = os.path.join(a.cases, c)
        h = parse_header(open(path).read())
        if not h['expect']:
            print('FAIL %s: no @expect line' % c)
            bad += 1
            continue
        if not applies(h, a.bc_major, a.al_major):
            print('skip %s (BC %d, AL %s)' % (c, a.bc_major, a.al_major))
            continue
        rc, built, out = run_case(a.al, a.symbols, path, h, 'BC%dPLUS' % a.bc_major, runtime)
        ran += 1
        found = [(code, msg) for code, msg, _ in parse_diagnostics(out)]
        problems = check(h['expect'], found)
        if built or rc == 0:
            problems.append('the compiler ACCEPTED the file')
        if problems:
            bad += 1
            print('FAIL %s' % c)
            for p in problems:
                print('     ' + p)
        else:
            print('ok   %s  (%s)' % (c, ', '.join(code for code, _ in h['expect'])))
    print('%d case(s) run, %d failed' % (ran, bad))
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()
