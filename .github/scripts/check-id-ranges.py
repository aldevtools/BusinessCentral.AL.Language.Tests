#!/usr/bin/env python3
"""Fail the build when a test filters the object ids of a metadata table by a range that another file can add to.

Why: CI selects the test codeunits that name a changed object, and the al-runtime-rs corpus bump reuses the results of
the codeunits it did not select (CONTRIBUTING.md, standing rule 10 and "Test selection in CI"). A test that reads AllObj,
Table Metadata or a similar table over an id range names no object of that range. A new object in the range changes
the rows it reads, the selection does not run it again, and its old result would be reused.

Flagged, in every .al file under tests/: X.SetRange(<id field>, A, B) with two bounds, and X.SetFilter(<id field>,
'<text>', ...) whose text holds '..', '<' or '>', where X is declared as a Record of a table in METADATA in the same
object, or X is Rec of an object whose SourceTable is one of them.

Not flagged:
- two literal bounds that lie outside the idRanges of every app.json (check-object-ids.py rejects an object there);
- the same bound twice (a range of one id);
- a range on a table whose rows are objects of one kind (Table Metadata: tables, ...) where an app of this repository
  already declares an object of that kind at every id from the low to the high bound. Object ids are unique per kind
  (check-object-ids.py), so no file can add a row. A bound is a number or <Kind>::"<name>" of a declared object;
- a filter in a procedure or trigger that also filters the name field of the same variable to a closed list (no '*',
  '?', '@', '..', '<' or '>' in the filter text): an object another file adds is not on the list;
- a key in ALLOWED: a reviewed exception, "<path> <procedure or trigger name>", each with its reason.

Exit code 0: nothing flagged. 1: flagged lines (each printed as a GitHub error annotation).
"""
import importlib.util
import re
import sys
from pathlib import Path

# check-object-ids.py owns the object declaration pattern and the reading of app.json.
_spec = importlib.util.spec_from_file_location('check_object_ids', Path(__file__).with_name('check-object-ids.py'))
coi = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(coi)

# Metadata tables whose rows are objects: table name -> (id fields, name field or None, object kind of the rows or None for
# every kind). Names are matched without case.
METADATA = {
    'allobj': (('object id',), 'object name', None),
    'allobjwithcaption': (('object id',), 'object name', None),
    'table metadata': (('id',), 'name', 'table'),
    'codeunit metadata': (('id',), 'name', 'codeunit'),
    'page metadata': (('id',), 'name', 'page'),
    'report metadata': (('id',), 'name', 'report'),
    'xmlport metadata': (('id',), 'name', 'xmlport'),
    'query metadata': (('id',), 'name', 'query'),
    'table information': (('table no.',), 'table name', 'table'),
    'field': (('tableno',), 'tablename', 'table'),
    'key': (('tableno',), None, 'table'),
}
BOUND_KIND = {'database': 'table', 'table': 'table', 'page': 'page', 'codeunit': 'codeunit', 'report': 'report',
              'xmlport': 'xmlport', 'query': 'query'}

# Reviewed exceptions: "<path> <procedure or trigger name>". Each line says why an added object cannot change the result.
ALLOWED = {
    # The walk over SubType = Test and 60000..60999 asserts only that the ids come strictly ascending and that there are at
    # least 50 of them. An added test codeunit is one more row of the same walk; it cannot make either assertion false.
    'tests/al-language/record/TestCodeunitInventoryOrder.al Record_CodeunitMetadata_TestCodeunitsInThisAppsRange_AreStrictlyAscending',
}

NAME = r'(?:"[^"\n]+"|[A-Za-z_]\w*)'
RECORD_VAR = re.compile(r'\b([A-Za-z_]\w*)\s*:\s*Record\s+(' + NAME + r')', re.I)
SOURCE_TABLE = re.compile(r'\bSourceTable\s*=\s*(' + NAME + r')\s*;', re.I)
OBJECT = re.compile(r'^\s*(?:table|tableextension|page|pageextension|report|reportextension|codeunit|query|xmlport|'
                    r'enum|enumextension|permissionset|permissionsetextension|interface|controladdin|profile|entitlement)\b',
                    re.I | re.M)
MEMBER = re.compile(r'\b(?:procedure|trigger)\s+(' + NAME + r')\s*\(', re.I)
CALL = re.compile(r'\b([A-Za-z_]\w*)\s*\.\s*(SetRange|SetFilter)\s*\(\s*(' + NAME + r')\s*(,[^;]*)?\)\s*;', re.I)
STRING = re.compile(r"'(?:[^']|'')*'")
OPEN_TEXT = re.compile(r'\.\.|<|>|\*|\?|@')
RANGE_TEXT = re.compile(r'\.\.|<|>')


def bare(name):
    return name.strip('"').lower()


def strip_comments(text):
    """The text with // and /* */ comments blanked (strings kept), so offsets and line numbers stay."""
    out, i, n = [], 0, len(text)
    while i < n:
        c = text[i]
        if c == "'":
            j = i + 1
            while j < n and not (text[j] == "'" and (j + 1 >= n or text[j + 1] != "'")):
                j += 2 if text[j] == "'" else 1
            out.append(text[i:j + 1])
            i = j + 1
        elif text.startswith('//', i):
            j = text.find('\n', i)
            j = n if j < 0 else j
            out.append(' ' * (j - i))
            i = j
        elif text.startswith('/*', i):
            j = text.find('*/', i + 2)
            j = n if j < 0 else j + 2
            out.append(re.sub(r'[^\n]', ' ', text[i:j]))
            i = j
        else:
            out.append(c)
            i += 1
    return ''.join(out)


def split_args(text):
    """The top-level comma-separated arguments of an argument list text (without the outer parentheses)."""
    args, depth, cur, i = [], 0, [], 0
    while i < len(text):
        c = text[i]
        if c == "'":
            m = STRING.match(text, i)
            j = m.end() if m else len(text)
            cur.append(text[i:j])
            i = j
            continue
        if c in '([':
            depth += 1
        elif c in ')]':
            depth -= 1
        if c == ',' and depth == 0:
            args.append(''.join(cur).strip())
            cur = []
        else:
            cur.append(c)
        i += 1
    if cur or args:
        args.append(''.join(cur).strip())
    return args


BOUND = re.compile(r'(\w+)\s*::\s*(' + NAME + r')')


def resolve(arg, objects):
    """The id a bound stands for: a number, or <Kind>::<name> of an object declared in this repository; else None."""
    if re.fullmatch(r'\d+', arg):
        return int(arg)
    m = BOUND.fullmatch(arg)
    kind = m and BOUND_KIND.get(m.group(1).lower())
    return objects['names'].get((kind, bare(m.group(2)))) if kind else None


def occupied(kind, lo, hi, objects):
    """Every id from lo to hi is declared by an object of kind."""
    ids = objects['ids'].get(kind, set())
    return kind is not None and lo is not None and hi is not None and lo <= hi and hi - lo < 100000 \
        and all(i in ids for i in range(lo, hi + 1))


def outside(lo, hi, ranges):
    return lo is not None and hi is not None and all(hi < a or lo > b for a, b in ranges)


def repository(root):
    """The idRanges of every app.json, and the objects its apps declare: {'ranges': [(from, to)], 'ids': {kind: {id}},
    'names': {(kind, name): id}}."""
    ranges, roots = [], []
    for app, _, rs in coi.app_dirs(Path(root)):
        ranges.extend(rs)
        roots.append(app)
    objects = {'ranges': ranges, 'ids': {}, 'names': {}}
    for app in roots:
        for f in app.rglob('*.al'):
            for line in f.read_text(encoding='utf-8-sig', errors='replace').splitlines():
                m = coi.DECL.match(line)
                if m:
                    kind, oid = m.group('kind').lower(), int(m.group('id'))
                    objects['ids'].setdefault(kind, set()).add(oid)
                    objects['names'][(kind, bare(m.group('name')))] = oid
    return objects


def range_bounds(method, args, objects):
    """(is a range, low id or None, high id or None) of the filter arguments after the field. The same bound twice is
    no range."""
    if method.lower() == 'setrange':
        if len(args) == 2 and re.sub(r'\s+', '', args[0]).lower() != re.sub(r'\s+', '', args[1]).lower():
            return True, resolve(args[0], objects), resolve(args[1], objects)
        return False, None, None
    if not args:
        return False, None, None
    m = STRING.fullmatch(args[0])
    if not m:
        return True, None, None  # a filter text that is no literal: it can hold a range
    if not RANGE_TEXT.search(args[0][1:-1]):
        return False, None, None
    found = re.fullmatch(r"'(\d+)\.\.(\d+)'", args[0])
    return True, (int(found.group(1)) if found else None), (int(found.group(2)) if found else None)


def closed_name_filter(method, args):
    if method.lower() == 'setrange':
        return len(args) == 1
    if not args:
        return False
    m = STRING.fullmatch(args[0])
    return bool(m) and not OPEN_TEXT.search(args[0][1:-1])


def find(path, text, objects):
    """[(line, message)] for one file."""
    text = strip_comments(text)
    starts = [m.start() for m in OBJECT.finditer(text)] + [len(text)]
    found = []
    for a, b in zip(starts, starts[1:]):
        obj = text[a:b]
        # a variable declared in several members: any metadata table it is declared as counts (over-match)
        anywhere = {v.lower(): bare(t) for v, t in RECORD_VAR.findall(obj)}
        src = SOURCE_TABLE.search(obj)
        if src:
            anywhere['rec'] = bare(src.group(1))
        if not any(t in METADATA for t in anywhere.values()):
            continue
        members = [(m.start(), m.group(1).strip('"')) for m in MEMBER.finditer(obj)]
        for i, (ms, member) in enumerate(members):
            me = members[i + 1][0] if i + 1 < len(members) else len(obj)
            body = obj[ms:me]
            head = re.split(r'\bbegin\b', body, maxsplit=1, flags=re.I)[0]
            tables = dict(anywhere)
            tables.update({v.lower(): bare(t) for v, t in RECORD_VAR.findall(head)})
            calls = [(c, c.group(1).lower(), c.group(2), bare(c.group(3)), split_args((c.group(4) or ',')[1:]))
                     for c in CALL.finditer(body)]
            for c, var, method, field, args in calls:
                table = tables.get(var)
                if table not in METADATA or field not in METADATA[table][0]:
                    continue
                is_range, lo, hi = range_bounds(method, args, objects)
                if not is_range or outside(lo, hi, objects['ranges']) or occupied(METADATA[table][2], lo, hi, objects):
                    continue
                name_field = METADATA[table][1]
                if name_field and any(v2 == var and f2 == name_field and closed_name_filter(m2, a2)
                                      for _, v2, m2, f2, a2 in calls):
                    continue
                if '%s %s' % (path, member) in ALLOWED:
                    continue
                line = text.count('\n', 0, a + ms + c.start()) + 1
                found.append((line, '%s.%s(%s, ...) in %s filters the object ids of %s by a range that another file can '
                                    'add an object to' % (c.group(1), method, c.group(3), member, table)))
    return found


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    root = Path(argv[0] if argv else '.')
    objects = repository(root)
    bad = []
    for f in sorted((root / 'tests').rglob('*.al')):
        rel = f.relative_to(root).as_posix()
        for line, msg in find(rel, f.read_text(encoding='utf-8-sig', errors='replace'), objects):
            bad.append((rel, line, msg))
    for rel, line, msg in bad:
        print('::error file=%s,line=%d::%s. Name the objects you assert on: add a filter on the name field with a closed '
              'list, or filter single ids (CONTRIBUTING.md, standing rule 10).' % (rel, line, msg))
    if not bad:
        print('No test filters the object ids of a metadata table by an open range.')
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
