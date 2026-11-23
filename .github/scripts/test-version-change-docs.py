#!/usr/bin/env python3
"""Self-test of check-version-change-docs.py: a documented id passes, a missing page, a bad id and a page whose
front matter id differs from its file name fail."""
import importlib.util
import os
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location('cvcd', os.path.join(HERE, 'check-version-change-docs.py'))
cvcd = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cvcd)


def write(root, rel, text):
    path = os.path.join(root, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(text)


def run(files):
    with tempfile.TemporaryDirectory() as root:
        for rel, text in files.items():
            write(root, rel, text)
        return cvcd.check(root)


PAGE = '---\nid: 29.1-page-part-refresh\ntitle: x\n---\nbody\n'

ids, problems = run({
    'tests/a/X.al': '#if BC29PLUS // version change: 29.1-page-part-refresh\n#endif\n',
    'docs/content/changes/29.1-page-part-refresh.md': PAGE,
    'docs/content/changes/_index.md': '---\ntitle: Changes\n---\n',
})
assert list(ids) == ['29.1-page-part-refresh'] and problems == [], problems

ids, problems = run({'tests/a/X.al': 'x\n  // Version change: 29.1-missing-page\n'})
assert len(problems) == 1 and 'X.al:2' in problems[0] and 'has no page' in problems[0], problems

ids, problems = run({'tests/a/X.al': '// version change: page-part-refresh\n'})
assert len(problems) == 1 and 'not of the form' in problems[0], problems

ids, problems = run({'docs/content/changes/29.1-a.md': '---\nid: 29.1-b\n---\n'})
assert len(problems) == 1 and 'differs from the file name' in problems[0], problems

ids, problems = run({'tests/a/X.txt': '// version change: 29.1-not-al\n'})
assert ids == {} and problems == [], problems

print('check-version-change-docs.py: all self-tests passed')
