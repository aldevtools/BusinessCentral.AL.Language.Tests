#!/usr/bin/env python3
"""Every `// version change: <id>` comment in tests/ needs a page docs/content/changes/<id>.md.

A version guard (#if BC29PLUS and similar) that exists because Business Central behavior or shipped data changed carries
the comment `// version change: <id>` (CONTRIBUTING.md, "Version changes site"). The page documents the change on the
public site. This check fails when a comment names an id without a page, when an id does not have the form
<major>.<minor>-<slug>, or when a page's front matter `id:` differs from its file name.

Usage: check-version-change-docs.py [repo root]   (default: the current directory)
"""
import os
import re
import sys

COMMENT = re.compile(r'//\s*version change:\s*(\S+)', re.IGNORECASE)
ID_FORM = re.compile(r'^\d+\.\d+-[a-z0-9]+(?:-[a-z0-9]+)*$')
FRONT_ID = re.compile(r'^id:\s*["\']?([^"\'\s]+)["\']?\s*$', re.MULTILINE)


def comment_ids(tests_dir):
    """{id: [(path, line), ...]} for every version change comment in the .al files under tests_dir."""
    found = {}
    for root, dirs, files in os.walk(tests_dir):
        dirs.sort()
        for name in sorted(files):
            if not name.lower().endswith('.al'):
                continue
            path = os.path.join(root, name)
            with open(path, encoding='utf-8-sig', errors='replace') as f:
                for n, line in enumerate(f, 1):
                    for m in COMMENT.finditer(line):
                        found.setdefault(m.group(1), []).append((path, n))
    return found


def page_problems(changes_dir, root):
    """Problems of the pages themselves: an id that differs from the file name."""
    problems = []
    if not os.path.isdir(changes_dir):
        return problems
    for name in sorted(os.listdir(changes_dir)):
        if not name.endswith('.md') or name == '_index.md':
            continue
        path = os.path.join(changes_dir, name)
        with open(path, encoding='utf-8') as f:
            text = f.read()
        rel = os.path.relpath(path, root)
        m = FRONT_ID.search(text.split('---', 2)[1] if text.startswith('---') else '')
        if not m:
            problems.append('%s: no `id:` in the front matter' % rel)
        elif m.group(1) != name[:-3]:
            problems.append('%s: front matter id %r differs from the file name' % (rel, m.group(1)))
    return problems


def check(root):
    tests_dir = os.path.join(root, 'tests')
    changes_dir = os.path.join(root, 'docs', 'content', 'changes')
    problems = []
    ids = comment_ids(tests_dir)
    for cid, places in sorted(ids.items()):
        where = ', '.join('%s:%d' % (os.path.relpath(p, root), n) for p, n in places)
        if not ID_FORM.match(cid):
            problems.append('version change id %r (%s) is not of the form <major>.<minor>-<slug>' % (cid, where))
        elif not os.path.isfile(os.path.join(changes_dir, cid + '.md')):
            problems.append('version change %s (%s) has no page docs/content/changes/%s.md' % (cid, where, cid))
    problems += page_problems(changes_dir, root)
    return ids, problems


def main(argv):
    root = argv[1] if len(argv) > 1 else '.'
    ids, problems = check(root)
    for p in problems:
        print('::error title=Version change docs::%s' % p)
    if problems:
        print('%d problem(s). Add the page (CONTRIBUTING.md, "Version changes site").' % len(problems))
        return 1
    print('%d version change id(s) in tests/, each has its page.' % len(ids))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
