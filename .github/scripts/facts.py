#!/usr/bin/env python3
"""Coverage facts of the corpus: what every test asserts, so a restructure PR can prove it lost nothing.

  facts.py extract <corpus checkout> <out.tsv>
      one row per asserted fact of every [Test] procedure, and per @expect line of every must-not-compile case
  facts.py diff <base.tsv> <head.tsv> [rename-map.tsv [facts-changes.tsv]]
      exit 1 when a base case is missing at head, or a base fact is not held at head by the same case
      (or by the cases the rename map sends it to), unless a facts-changes line replaces that fact

A case key is "<app folder>/<codeunit id>/<test name>" (the JUnit key: app, codeunit id, test name), or "mnc/<file stem>" for a
must-not-compile case. A fact is (kind, expected value, API members of the checked expression, #if context of the test procedure):

  Assert.AreEqual(e, a) / AreNotEqual   -> eq / ne | e | members(a)
  Assert.IsTrue(x) / IsFalse(x)         -> true / false | | members(x), or x when it calls nothing
  Assert.ExpectedError(t)               -> error | t |
  Assert.ExpectedErrorCode(c)           -> errorcode | c |
  <x>.Expect(n, v)                      -> expect | n=v |
  <x>.Observe(n, e) / ObserveError      -> observe / observeerror | n | members(e)
  must-not-compile // @expect line      -> mnc | CODE | text | the @from/@until/@target/@depends lines
  a test with no assertion              -> runs (it pins "runs without error")

The facts of a test include the facts of the procedures of its own codeunit that it calls, transitively. Paths and variable names do
not count, so moving a file or renaming a local keeps every fact. Known weakness: when the checked value is a local variable, only
the kind and the expected value are compared; the full CI run covers the rest.

The rename map (tests/rename-map.tsv) has lines old_key<TAB>new_key. It is only read for a base key that is gone at head: its facts
must then be held by the union of its new keys. Lines starting with # and the header line are skipped.

The facts-changes file (tests/facts-changes.tsv) records an intended change of an asserted fact (real BC does something else than
the test said). One line per changed fact, ten tab-separated columns:
  key, old kind, old value, old members, old ifctx, new kind, new value, new members, new ifctx, reason
A line covers one missing occurrence of the old fact of that base key when the new fact is held at head by the key (or by its
rename targets). The reason is required. A lost-fact report prints the first five columns of the line to add.
"""
import collections
import os
import re
import subprocess
import sys

CU = re.compile(r'^\s*codeunit\s+(\d+)\s+("(?:[^"])*"|\w+)', re.I | re.M)
PROC = re.compile(r'^[ \t]*(?:\[[^\]]*\]\s*)*(?:local\s+|internal\s+)?procedure\s+("?[\w ]+"?)\s*\(', re.I | re.M)
CALL = re.compile(r'\b(Assert\.(AreEqual|AreNotEqual|IsTrue|IsFalse|ExpectedError|ExpectedErrorCode)|\w+\.(Expect|Observe|ObserveError))\s*\(', re.I)
MNC_APP = 'must-not-compile'
HEADER = 'key\tpath\tkind\tvalue\tmembers\tifctx\n'
MAP_HEADER = 'old_key\tnew_key'
CHANGES_HEADER = 'key\told_kind\told_value\told_members\told_ifctx\tnew_kind\tnew_value\tnew_members\tnew_ifctx\treason'


def strip(src):
    """Remove comments, keep strings and the line structure."""
    o, i, n = [], 0, len(src)
    while i < n:
        c = src[i]
        if c == "'":
            j = i + 1
            while j < n:
                if src[j] == "'":
                    if j + 1 < n and src[j + 1] == "'":
                        j += 2
                        continue
                    break
                if src[j] == '\n':
                    break
                j += 1
            o.append(src[i:j + 1])
            i = j + 1
        elif c == '"':
            j = src.find('"', i + 1)
            if j < 0 or '\n' in src[i:j]:
                j = i
            o.append(src[i:j + 1])
            i = j + 1
        elif src.startswith('//', i):
            j = src.find('\n', i)
            i = n if j < 0 else j
        elif src.startswith('/*', i):
            j = src.find('*/', i + 2)
            j = n if j < 0 else j + 2
            o.append('\n' * src[i:j].count('\n'))
            i = j
        else:
            o.append(c)
            i += 1
    return ''.join(o)


def body_end(s, start):
    """End of the { } block that starts at or after start."""
    d = 0
    i = s.find('{', start)
    if i < 0:
        return len(s)
    k, n = i, len(s)
    while k < n:
        c = s[k]
        if c == "'":
            j = k + 1
            while j < n and s[j] != '\n':
                if s[j] == "'":
                    if j + 1 < n and s[j + 1] == "'":
                        j += 2
                        continue
                    break
                j += 1
            k = j + 1
            continue
        if c == '"':
            j = s.find('"', k + 1)
            if j != -1 and '\n' not in s[k:j]:
                k = j + 1
                continue
        if c == '{':
            d += 1
        elif c == '}':
            d -= 1
            if d == 0:
                return k + 1
        k += 1
    return len(s)


def args_of(s, i):
    """The top-level arguments of the call whose '(' ends just before i."""
    d, cur, out = 1, [], []
    while i < len(s) and d:
        c = s[i]
        if c == "'":
            j = i + 1
            while j < len(s) and not (s[j] == "'" and (j + 1 >= len(s) or s[j + 1] != "'")):
                j += 2 if s[j] == "'" else 1
            cur.append(s[i:j + 1])
            i = j + 1
            continue
        if c in '([':
            d += 1
        elif c in ')]':
            d -= 1
            if d == 0:
                break
        if c == ',' and d == 1:
            out.append(''.join(cur).strip())
            cur = []
        else:
            cur.append(c)
        i += 1
    out.append(''.join(cur).strip())
    return out


def members(x):
    return ','.join(sorted(set(m.lower() for m in re.findall(r'(?:\.|\b)([A-Za-z_]\w*)\s*\(', x))))


def ifctx(src, pos):
    stack = []
    for m in re.finditer(r'^\s*#(if|elif|else|endif)\b([^\n]*)', src[:pos], re.M | re.I):
        k = m.group(1).lower()
        if k == 'if':
            stack.append(m.group(2).strip())
        elif k in ('elif', 'else') and stack:
            stack[-1] = ('not ' + stack[-1]) if k == 'else' else m.group(2).strip()
        elif k == 'endif' and stack:
            stack.pop()
    return '&'.join(stack)


def facts_of(body):
    out = []
    for am in CALL.finditer(body):
        a = args_of(body, am.end())
        m = (am.group(2) or am.group(3)).lower()
        if m in ('areequal', 'arenotequal'):
            fact = ('eq' if m == 'areequal' else 'ne', a[0], members(a[1] if len(a) > 1 else ''))
        elif m in ('istrue', 'isfalse'):
            fact = (m[2:], '', members(a[0]) or a[0])
        elif m == 'expectederror':
            fact = ('error', a[0], '')
        elif m == 'expectederrorcode':
            fact = ('errorcode', a[0], '')
        elif m == 'expect':
            fact = ('expect', '='.join(a[:2]), '')
        else:
            fact = (m, a[0], members(a[1] if len(a) > 1 else ''))
        out.append(fact)
    return out


def mnc_rows(f, raw):
    hdr = [l for l in raw.splitlines() if l.startswith('//')]
    scope = ' '.join(l[2:].strip() for l in hdr if re.match(r'//\s*@(from|until|target|depends)\b', l))
    key = 'mnc/' + os.path.basename(f)[:-3]
    return [(key, f, 'mnc', m.group(1).strip(), scope, '') for m in (re.match(r'//\s*@expect\s+(.*)', l) for l in hdr) if m]


def test_rows(app, f, raw):
    rows = []
    s = strip(raw)
    for cm in CU.finditer(s):
        end = body_end(s, cm.end())
        cu = s[cm.end():end]
        if not re.search(r'Subtype\s*=\s*Test\b', cu, re.I):
            continue
        procs = list(PROC.finditer(cu))
        bodies = {}
        for k, pm in enumerate(procs):
            e = procs[k + 1].start() if k + 1 < len(procs) else len(cu)
            bodies[pm.group(1).strip('"').lower()] = cu[pm.end():e]

        def reach(name, seen):
            # the facts of a procedure and of the procedures of the same codeunit it calls, transitively
            if name in seen or name not in bodies:
                return []
            seen.add(name)
            body = bodies[name]
            out = facts_of(body)
            for callee in sorted(set(c.lower().strip('"') for c in re.findall(r'(?<![.\w])("?[A-Za-z_][\w ]*"?)\s*\(', body))):
                if callee in bodies and callee != name:
                    out += reach(callee, seen)
            return out

        for pm in procs:
            head = cu[pm.start():pm.end()]
            prev = cu[max(0, pm.start() - 200):pm.start()].split('\n')
            if not re.search(r'\[\s*Test\s*\]', head + '\n'.join(l for l in prev[-4:] if l.strip().startswith('[')), re.I):
                continue
            name = pm.group(1).strip('"')
            key = f'{app}/{cm.group(1)}/{name}'
            ctx = ifctx(s, cm.end() + pm.end())
            fl = reach(name.lower(), set())
            rows += [(key, f, fact[0], fact[1], fact[2], ctx) for fact in fl]
            if not fl:
                rows.append((key, f, 'runs', '', '', ctx))
    return rows


def extract(root, out):
    ls = subprocess.run(['git', '-C', root, 'ls-files', 'tests/'], capture_output=True, text=True, check=True).stdout.split('\n')
    rows = []
    for f in sorted(x for x in ls if x.endswith('.al')):
        app = f.split('/')[1]
        raw = open(os.path.join(root, f), encoding='utf-8-sig', errors='replace').read()
        rows += mnc_rows(f, raw) if app == MNC_APP else test_rows(app, f, raw)
    with open(out, 'w', encoding='utf-8') as o:
        o.write(HEADER)
        for r in rows:
            o.write('\t'.join(x.replace('\t', ' ').replace('\n', ' ') for x in r) + '\n')
    print(len(rows), 'facts,', len({r[0] for r in rows}), 'tests and must-not-compile cases')
    return 0


def load(p):
    d = collections.defaultdict(collections.Counter)
    path = {}
    with open(p, encoding='utf-8') as fh:
        for line in fh.read().splitlines()[1:]:
            k, f, kind, v, mem, ctx = line.split('\t')
            d[k][(kind, v, mem, ctx)] += 1
            path[k] = f
    return d, path


def load_map(p):
    rmap = collections.defaultdict(list)
    if not p:
        return rmap
    with open(p, encoding='utf-8') as fh:
        for line in fh.read().splitlines():
            if not line.strip() or line.startswith('#') or line.startswith(MAP_HEADER):
                continue
            parts = line.split('\t')
            if len(parts) < 2 or not parts[0] or not parts[1]:
                raise SystemExit(f'{p}: not old_key<TAB>new_key: {line!r}')
            rmap[parts[0]].append(parts[1])
    return rmap


def load_changes(p):
    """{base key: [(old fact, new fact)]} from a facts-changes file."""
    changes = collections.defaultdict(list)
    if not p:
        return changes
    with open(p, encoding='utf-8') as fh:
        for line in fh.read().splitlines():
            if not line.strip() or line.startswith('#') or line.startswith(CHANGES_HEADER):
                continue
            parts = line.split('\t')
            if len(parts) != 10 or not parts[0] or not parts[1] or not parts[5] or not parts[9].strip():
                raise SystemExit(f'{p}: not key, old kind, old value, old members, old ifctx, new kind, new value, new members, new ifctx, reason (10 columns, reason required): {line!r}')
            changes[parts[0]].append((tuple(parts[1:5]), tuple(parts[5:9])))
    return changes


def diff(base, head, ren=None, chg=None, out=print):
    b, bp = load(base)
    h, _ = load(head)
    rmap = load_map(ren)
    changes = load_changes(chg)
    gh = os.environ.get('GITHUB_ACTIONS') == 'true'
    err = '::error::' if gh else ''
    lost_cases, lost_facts, bad_targets = [], [], []
    for k, facts in b.items():
        if k in h:
            targets = [k]
        else:
            targets = rmap.get(k, [])
            if not targets:
                lost_cases.append(k)
                continue
            bad_targets += [(k, t) for t in targets if t not in h]
        pool = collections.Counter()
        for t in targets:
            pool.update(h.get(t, {}))
        for fct, n in facts.items():
            missing = n - pool[fct]
            if missing > 0:
                # an intended change: a facts-changes line from this fact to a fact the head holds
                missing -= sum(1 for old, new in changes.get(k, []) if old == fct and pool[new] > 0)
            if missing > 0:
                lost_facts.append((k, bp[k], fct))
    for k in lost_cases:
        out(f'{err}LOST CASE  {k}  ({bp[k]}): not at head and not in the rename map')
    for k, t in bad_targets:
        out(f'{err}BAD RENAME  {k} -> {t}: the new key is not at head')
    for k, p, f in lost_facts:
        out(f'{err}LOST FACT  {k}  ({p}): kind={f[0]} value={f[1]} members={f[2]} ifctx={f[3]}')
        out('facts-changes line: ' + '\t'.join((k,) + f) + '\t<new kind>\t<new value>\t<new members>\t<new ifctx>\t<reason>')
    new = sum(1 for k in h if k not in b)
    out(f'{len(b)} base cases, {len(lost_cases)} lost cases, {len(lost_facts)} lost facts, {len(bad_targets)} bad renames, {new} new cases at head')
    return 1 if (lost_cases or lost_facts or bad_targets) else 0


def main(argv):
    if len(argv) >= 3 and argv[0] == 'extract':
        return extract(argv[1], argv[2])
    if len(argv) in (3, 4, 5) and argv[0] == 'diff':
        return diff(argv[1], argv[2], argv[3] if len(argv) > 3 else None, argv[4] if len(argv) > 4 else None)
    print(__doc__)
    return 2


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
