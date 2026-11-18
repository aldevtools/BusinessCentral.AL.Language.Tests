#!/usr/bin/env python3
"""Self-test for run-artifacts.sh, the download of a run's artifacts that bc-leg.yml (merge step) and ci.yml (job
manifest) share. It runs the real script with a fake gh (the real jq applies the script's filter to a fake artifact
list) and a fake curl (answers per artifact id)."""
import io
import json
import os
import shutil
import subprocess
import tempfile
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCRIPT = HERE / 'run-artifacts.sh'
FAILED = []


def check(name, cond, detail=''):
    print('%s %s%s' % ('ok  ' if cond else 'FAIL', name, '' if cond else ': %s' % (detail,)))
    if not cond:
        FAILED.append(name)


FAKE_GH = r'''#!/usr/bin/env python3
import json, os, subprocess, sys
a = sys.argv[1:]
jq = a[a.index('--jq') + 1]
data = open(os.path.join(os.environ['FAKE_DIR'], 'artifacts.json')).read()
sys.stdout.write(subprocess.run(['jq', '-r', jq], input=data, capture_output=True, text=True, check=True).stdout)
'''

FAKE_CURL = r'''#!/usr/bin/env python3
import os, shutil, sys
a = sys.argv[1:]
out, url = a[a.index('-o') + 1], a[-1]
assert '-L' in a and 'Authorization: Bearer tok' in a, a
id_ = url.rstrip('/').split('/')[-2]
fake = os.environ['FAKE_DIR']
answer = dict(l.split() for l in open(os.path.join(fake, 'answers.txt')) if l.strip())
code = answer.get(id_, '200')
if code == 'neterr':
    sys.stderr.write('curl: (6) Could not resolve host\n'); sys.exit(6)
if code == '200':
    shutil.copy(os.path.join(fake, id_ + '.zip'), out)
else:
    open(out, 'w').write('{"message": "x"}')
sys.stdout.write(code)
'''


def zipped(files):
    b = io.BytesIO()
    with zipfile.ZipFile(b, 'w') as z:
        for n, t in files.items():
            z.writestr(n, t)
    return b.getvalue()


def run(artifacts, answers, args):
    """artifacts: [(id, name, created_at, expired, {file: text} or bytes)]; answers: {id: '404' | '500' | 'neterr'}"""
    w = Path(tempfile.mkdtemp())
    try:
        fake, bin_ = w / 'fake', w / 'bin'
        fake.mkdir(); bin_.mkdir()
        for n, t in (('gh', FAKE_GH), ('curl', FAKE_CURL)):
            (bin_ / n).write_text(t); (bin_ / n).chmod(0o755)
        lst = []
        for id_, name, at, expired, content in artifacts:
            lst.append({'id': id_, 'name': name, 'created_at': at, 'expired': expired})
            (fake / ('%d.zip' % id_)).write_bytes(content if isinstance(content, bytes) else zipped(content))
        (fake / 'artifacts.json').write_text(json.dumps({'total_count': len(lst), 'artifacts': lst}))
        (fake / 'answers.txt').write_text(''.join('%s %s\n' % kv for kv in answers.items()))
        env = {'PATH': '%s:%s' % (bin_, os.environ['PATH']), 'FAKE_DIR': str(fake), 'GH_TOKEN': 'tok',
               'GITHUB_REPOSITORY': 'o/r', 'GITHUB_RUN_ID': '7', 'GITHUB_API_URL': 'https://api.example'}
        p = subprocess.run(['bash', str(SCRIPT), args[0], str(w / 'out')] + args[1:],
                           env=env, capture_output=True, text=True)
        tree = {}
        if (w / 'out').is_dir():
            for d in sorted((w / 'out').iterdir()):
                tree[d.name] = sorted(f.name for f in d.iterdir())
        return p.returncode, p.stdout.split(), tree, p.stderr
    finally:
        shutil.rmtree(w)


N = 'junit-test-results-28.5'
OWN, OTHER = 'junit-al-language-onprem.xml', 'junit-al-language-onprem-dotnet.xml'
ARTS = [
    (101, N, '2026-11-18T04:40:00Z', False, {OWN: '<testsuites/>'}),
    (102, N, '2026-11-18T04:40:30Z', False, {OTHER: '<testsuites/>'}),
    (103, 'junit-test-results-29.0', '2026-11-18T04:39:00Z', False, {OWN: '<testsuites/>'}),
    (104, N, '2026-11-18T04:39:30Z', True, {OWN: '<testsuites/>'}),
    (105, N, '2026-11-18T04:41:00Z', False, {OWN: '<testsuites/>'}),
]


def main():
    code, out, tree, err = run(ARTS, {}, [N, OWN])
    check('member: only this name, not expired, only artifacts holding the file, oldest first',
          code == 0 and out == ['2026-11-18T04:40:00Z-101', '2026-11-18T04:41:00Z-105'], (code, out, err))
    check('member: only the member is unzipped, the zip is removed',
          tree == {'2026-11-18T04:40:00Z-101': [OWN], '2026-11-18T04:41:00Z-105': [OWN]}, tree)

    code, out, tree, err = run(ARTS, {}, [N])
    check('no member: every artifact of the name, whole',
          code == 0 and out == ['2026-11-18T04:40:00Z-101', '2026-11-18T04:40:30Z-102', '2026-11-18T04:41:00Z-105']
          and tree['2026-11-18T04:40:30Z-102'] == [OTHER], (code, out, tree, err))

    code, out, tree, err = run(ARTS, {'102': '404'}, [N, OWN])
    check('race: another leg deleted its artifact after the listing (404): skipped, success',
          code == 0 and out == ['2026-11-18T04:40:00Z-101', '2026-11-18T04:41:00Z-105'] and '102' not in ''.join(tree)
          and 'HTTP 404' in err, (code, out, err))

    for answer in ('500', '403', '410', 'neterr'):
        code, out, _, err = run(ARTS, {'102': answer}, [N, OWN])
        check('download %s: the script fails' % answer, code != 0, (code, out, err))

    bad = list(ARTS) + [(106, N, '2026-11-18T04:42:00Z', False, b'not a zip')]
    code, out, _, err = run(bad, {}, [N, OWN])
    check('a broken zip fails, also with a member', code != 0, (code, out, err))

    code, out, tree, err = run([a for a in ARTS if a[0] in (102, 103)], {}, [N, OWN])
    check('no artifact holds the member: success, nothing printed', code == 0 and out == [] and tree == {},
          (code, out, tree, err))

    if FAILED:
        raise SystemExit('%d check(s) failed: %s' % (len(FAILED), FAILED))
    print('self-test OK')


main()
