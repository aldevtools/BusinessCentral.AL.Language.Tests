#!/usr/bin/env python3
"""Classify each in-place edit of a shared fixture as "additive" or "other" (CONTRIBUTING.md, standing rule 3).

    check-fixture-edit.py --base REV [--head REV] [--repo DIR] [--json FILE]

A merged fixture (an object in a file under one of FIXTURE_ROOTS) may change in place only by additions that code which
does not name the new member cannot see. select-tests.py runs every test codeunit that names a changed object; such an
addition also re-runs the codeunits the name scan cannot follow (SCAN_BLIND there). Any other edit is a full run, and a
pull request with one fails the job "Object IDs must be unique and in range" unless it has the label shared-change.

The diff is BASE..HEAD (two dots: the caller passes the merge base or the pull request's first parent). The method is an
allowlist: per object, remove the additions listed below from the HEAD text; what is left must equal the BASE text
(comments and whitespace outside strings do not count). Anything else is "other", with the reason.

  table      a field: a block field(N; Name; Type) in the fields section, N used by no other field, properties only
             Caption, DataClassification, ToolTip (so class Normal, no trigger, no relation)
  table, codeunit, page
             procedures appended at the end of the object: no attribute, no trigger; the code before them unchanged
  cleanup codeunit (CLEANUP_CODEUNITS)
             per table the same diff adds (no table of that name at BASE): one variable "X: Record T;" in a var section
             and one statement "X.DeleteAll(...);" after a begin
  enum       a value: value(N; Name) after every existing value, N used by no other value, only Caption; the enum has no
             implements clause
  page       a field control: field(Name; Rec.F) as the last control of an existing group or repeater, F a Normal field
             of the page's SourceTable, properties only ApplicationArea, Caption, ToolTip; PageType one of PAGE_TYPES
  page       an action: action(Name) as the last child of an existing area or group under actions, with no nested block

An enumextension of a fixture enum, in any file of the diff, counts as an edit of that enum: each value it adds follows
the enum value rule (its ordinal is used by no value of the enum or of another extension of it). A removed or renamed
fixture object, or a changed namespace, using or #define line of a fixture file, is "other". An object new in this diff
is no edit. Exit 0 when every edit is additive, 1 when one is "other", 2 when the check itself failed.
"""
import argparse
import difflib
import importlib.util
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))

FIXTURE_ROOTS = (re.compile(r'^tests/[^/]+/_fixtures/'),)
CLEANUP_CODEUNITS = {'altfixturecleanup'}
PAGE_TYPES = {'card', 'list', 'listpart', 'cardpart', 'worksheet', 'document'}
FIELD_PROPS = {'caption', 'dataclassification', 'tooltip'}
CONTROL_PROPS = {'applicationarea', 'caption', 'tooltip'}
VALUE_PROPS = {'caption'}
PROCEDURE_KINDS = {'table', 'codeunit', 'page'}


def _select_tests():
    spec = importlib.util.spec_from_file_location('select_tests', os.path.join(HERE, 'select-tests.py'))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


st = _select_tests()
N = st.NAME
FIELD_HEAD = re.compile(r'field\s*\(\s*(\d+)\s*;\s*(%s)\s*;[^;]*\)' % N, re.I)
VALUE_HEAD = re.compile(r'value\s*\(\s*(\d+)\s*;\s*(%s)\s*\)' % N, re.I)
CONTROL_HEAD = re.compile(r'field\s*\(\s*%s\s*;\s*Rec\s*\.\s*(%s)\s*\)' % (N, N), re.I)
ACTION_HEAD = re.compile(r'action\s*\(\s*%s\s*\)' % N, re.I)
CONTROL_PARENT = re.compile(r'(?:group|repeater)\s*\(', re.I)
ACTION_PARENT = re.compile(r'(?:area|group)\s*\(', re.I)
PROPERTY = re.compile(r'(\w+)\s*=', re.I)
DECL = re.compile(r'(%s)\s*:\s*Record\s+(%s)\s*;' % (N, N), re.I)
DELETEALL = re.compile(r'(%s)\s*\.\s*DeleteAll\s*(?:\(\s*(?:true|false)?\s*\))?\s*;' % N, re.I)


class Other(Exception):
    pass


# ---------- the object text as a tree of blocks ----------

def tokens(text):
    """The tokens of AL source, comments dropped; whitespace runs outside strings become one ' '."""
    out = []
    for m in st.LEX.finditer(text):
        t = m.group(0)
        if t.startswith('//') or t.startswith('/*'):
            continue
        if t[:1] in '\'"' or t in '{}':
            out.append(t)
        else:
            out.extend(x for x in re.split(r'(\s+)', t) if x)
    return out


def norm(toks):
    return re.sub(r'\s+', ' ', ''.join(' ' if t.isspace() else t for t in toks)).strip()


def split_head(toks):
    """(text before the block header, header) of the tokens before a '{': the header starts after the last ';' outside
    parentheses."""
    depth, cut = 0, 0
    for i, t in enumerate(toks):
        if t == '(':
            depth += 1
        elif t == ')':
            depth -= 1
        elif t == ';' and depth == 0:
            cut = i + 1
    return norm(toks[:cut]), norm(toks[cut:])


def tree(toks):
    """[('t', text) | ('b', header, items)] of a token list that starts inside a block."""
    stack = [[]]
    heads = []
    run = []
    for t in toks:
        if t == '{':
            pre, head = split_head(run)
            if pre:
                stack[-1].append(('t', pre))
            heads.append(head)
            stack.append([])
            run = []
        elif t == '}':
            if run and norm(run):
                stack[-1].append(('t', norm(run)))
            run = []
            items = stack.pop()
            if not stack:
                raise Other('unbalanced braces')
            stack[-1].append(('b', heads.pop(), items))
        else:
            run.extend(re.findall(r'\s+|[^\s;()]+|[;()]', t) if t[:1] not in '\'"' else [t])
    if run and norm(run):
        stack[-1].append(('t', norm(run)))
    if len(stack) != 1:
        raise Other('unbalanced braces')
    return stack[0]


def objects(path, text):
    """[(Obj of select-tests.py, header text, body tree)] of the top-level objects of a file."""
    objs = st.parse_al(path, text)
    out, toks, depth, head, body = [], tokens(text), 0, [], []
    for t in toks:
        if depth == 0:
            if t == '{':
                depth, body = 1, []
            else:
                head.append(t)
            continue
        depth += 1 if t == '{' else -1 if t == '}' else 0
        if depth == 0:
            out.append((norm(head), tree(body)))
            head = []
            continue
        body.append(t)
    if len(out) != len(objs):
        raise Other('%s: %d objects found by select-tests.py, %d by this script' % (path, len(objs), len(out)))
    return [(o, h, b) for o, (h, b) in zip(objs, out)]


def text_of(items):
    return ' '.join(x[1] if x[0] == 't' else '%s { %s }' % (x[1], text_of(x[2])) for x in items).strip()


def properties(items, allowed, what):
    """Raise Other unless the block holds only 'Name = value;' statements of the allowed names."""
    for x in items:
        if x[0] == 'b':
            raise Other('%s has a nested block %s' % (what, x[1]))
        for part in statements(x[1]):
            m = PROPERTY.match(part)
            if not m or m.group(1).lower() not in allowed:
                raise Other('%s has "%s" (allowed: %s)' % (what, part[:60], ', '.join(sorted(allowed))))


STATEMENT = re.compile(r"'(?:[^']|'')*'|\"[^\"]*\"|;|[^;'\"]+")


def statements(text):
    """The ';'-separated statements of a text, strings kept whole."""
    out, cur = [], ''
    for m in STATEMENT.finditer(text):
        if m.group(0) == ';':
            out.append(cur.strip())
            cur = ''
        else:
            cur += m.group(0)
    out.append(cur.strip())
    return [s for s in out if s]


# ---------- one object ----------

class Ctx:
    def __init__(self, kind, name, head_top, new_tables, field_class):
        self.kind, self.name, self.top = kind, name, head_top
        self.new_tables, self.field_class = new_tables, field_class
        self.adds = []


def top_props(items):
    out = {}
    for x in items:
        if x[0] == 't':
            for m in re.finditer(r'\b(\w+)\s*=\s*("[^"]*"|[^;]+);', x[1]):
                out.setdefault(m.group(1).lower(), st.unquote(m.group(2)))
    return out


def insertion(x, path, parent_new, j, ctx):
    """Accept one block of HEAD that BASE does not have, or raise Other."""
    if x[0] != 'b':
        raise Other('text added: "%s"' % x[1][:80])
    head = x[1]
    where = [p.lower() for p in path]
    later = parent_new[j + 1:]
    if ctx.kind == 'table' and where == ['fields'] and FIELD_HEAD.fullmatch(head):
        num = FIELD_HEAD.fullmatch(head).group(1)
        used = [FIELD_HEAD.match(y[1]).group(1) for y in parent_new if y is not x and y[0] == 'b' and FIELD_HEAD.match(y[1])]
        if num in used:
            raise Other('field %s: number already used' % head)
        properties(x[2], FIELD_PROPS, head)
        ctx.adds.append('field %s' % head)
        return
    if ctx.kind == 'enum' and where == [] and VALUE_HEAD.fullmatch(head):
        value(x, parent_new, later, ctx)
        return
    if ctx.kind == 'page' and where[:1] == ['layout'] and path and CONTROL_PARENT.match(path[-1]) and CONTROL_HEAD.fullmatch(head):
        if later:
            raise Other('control %s is not the last control of %s' % (head, path[-1]))
        ptype = ctx.top.get('pagetype', '').lower()
        if ptype not in PAGE_TYPES:
            raise Other('control %s on a page of PageType %s' % (head, ptype or '(none)'))
        source = ctx.top.get('sourcetable')
        fname = st.unquote(CONTROL_HEAD.fullmatch(head).group(1))
        cls = ctx.field_class(source, fname) if source else None
        if cls != 'normal':
            raise Other('control %s: Rec.%s is %s' % (head, fname, cls or 'no field of the source table this check can read'))
        properties(x[2], CONTROL_PROPS, head)
        ctx.adds.append('control %s' % head)
        return
    if ctx.kind == 'page' and where[:1] == ['actions'] and len(path) > 1 and ACTION_PARENT.match(path[-1]) and ACTION_HEAD.fullmatch(head):
        if later:
            raise Other('action %s is not the last child of %s' % (head, path[-1]))
        if any(y[0] == 'b' for y in x[2]):
            raise Other('action %s has a nested block' % head)
        ctx.adds.append('action %s' % head)
        return
    raise Other('block added that the rule does not allow: %s%s' % (' > '.join(path + ['']), head))


def value(x, items, later, ctx, used_elsewhere=()):
    head = x[1]
    if ctx.implements:
        raise Other('value %s: the enum implements an interface' % head)
    if any(y[0] == 'b' and VALUE_HEAD.match(y[1]) for y in later):
        raise Other('value %s is not after every existing value' % head)
    num = VALUE_HEAD.fullmatch(head).group(1)
    used = [VALUE_HEAD.match(y[1]).group(1) for y in items if y is not x and y[0] == 'b' and VALUE_HEAD.match(y[1])]
    if num in used or num in used_elsewhere:
        raise Other('value %s: ordinal already used' % head)
    properties(x[2], VALUE_PROPS, head)
    ctx.adds.append('value %s' % head)


def align(old, new, path, ctx, top=False):
    """Walk HEAD's items against BASE's; every HEAD item BASE lacks must be an allowed insertion."""
    i = 0
    for j, x in enumerate(new):
        y = old[i] if i < len(old) else None
        if y == x:
            i += 1
        elif y is not None and x[0] == 'b' and y[0] == 'b' and x[1] == y[1]:
            align(y[2], x[2], path + [x[1]], ctx)
            i += 1
        elif y is not None and x[0] == 't' and y[0] == 't':
            text_edit(y[1], x[1], ctx, top and j == len(new) - 1 and i == len(old) - 1)
            i += 1
        elif top and x[0] == 't' and j == len(new) - 1 and i == len(old):
            procedures(x[1], ctx)
        else:
            insertion(x, path, new, j, ctx)
    if i < len(old):
        y = old[i]
        raise Other('removed or changed: %s' % ((path and ' > '.join(path) + ' > ' or '') + (y[1][:80])))


UNIT = re.compile(r"'(?:[^']|'')*'|\"[^\"]*\"|\b(?:begin|var)\b|;|[^;'\"]+?(?=\bbegin\b|\bvar\b|;|'|\"|$)", re.I)


def units(text):
    """Statements of code text: split after ';', and 'var' and 'begin' are units of their own."""
    out, cur = [], ''
    for m in UNIT.finditer(text):
        t = m.group(0)
        if t.lower() in ('begin', 'var'):
            if cur.strip():
                out.append(cur.strip())
            out.append(t.lower())
            cur = ''
        elif t == ';':
            out.append((cur + ';').strip())
            cur = ''
        else:
            cur += t
    if cur.strip():
        out.append(cur.strip())
    return out


def text_edit(old, new, ctx, at_end):
    if at_end and new.startswith(old + ' '):
        procedures(new[len(old) + 1:], ctx)
        return
    if ctx.kind == 'codeunit' and ctx.name in CLEANUP_CODEUNITS:
        cleanup(old, new, ctx)
        return
    raise Other('code changed: %s' % first_diff(old, new))


def first_diff(old, new):
    a, b = units(old), units(new)
    for tag, i1, i2, j1, j2 in difflib.SequenceMatcher(None, a, b, autojunk=False).get_opcodes():
        if tag != 'equal':
            return '%s "%s" -> "%s"' % (tag, ' '.join(a[i1:i2])[:60], ' '.join(b[j1:j2])[:60])
    return 'text differs'


def cleanup(old, new, ctx):
    a, b = units(old), units(new)
    decls, deletes = {}, {}
    for tag, i1, i2, j1, j2 in difflib.SequenceMatcher(None, a, b, autojunk=False).get_opcodes():
        if tag == 'equal':
            continue
        if tag != 'insert':
            raise Other('cleanup codeunit: code changed: "%s" -> "%s"' % (' '.join(a[i1:i2])[:60], ' '.join(b[j1:j2])[:60]))
        for j in range(j1, j2):
            last = next((u for u in reversed(b[:j]) if u in ('var', 'begin')), None)
            d, k = DECL.fullmatch(b[j]), DELETEALL.fullmatch(b[j])
            if d and last == 'var':
                decls[st.unquote(d.group(1))] = st.unquote(d.group(2))
            elif k and last == 'begin':
                deletes.setdefault(st.unquote(k.group(1)), []).append(b[j])
            else:
                raise Other('cleanup codeunit: added "%s" is no Record variable or DeleteAll line' % b[j][:80])
    for var, table in decls.items():
        if table not in ctx.new_tables:
            raise Other('cleanup codeunit: table "%s" is not added by this diff' % table)
        if len(deletes.get(var, [])) != 1:
            raise Other('cleanup codeunit: variable %s needs exactly one DeleteAll line' % var)
        ctx.adds.append('DeleteAll for new table "%s"' % table)
    extra = sorted(set(deletes) - set(decls))
    if extra:
        raise Other('cleanup codeunit: DeleteAll on %s, no new Record variable of a new table' % ', '.join(extra))


WORD = re.compile(r"'(?:[^']|'')*'|\"[^\"]*\"|\[|\w+|[^\w\s]", re.I)


def procedures(text, ctx):
    if ctx.kind not in PROCEDURE_KINDS:
        raise Other('code added to a %s' % ctx.kind)
    toks = [t for t in WORD.findall(text)]
    low = [t.lower() for t in toks]
    i, found = 0, []
    while i < len(toks):
        if low[i] in ('local', 'internal', 'protected'):
            i += 1
        if i >= len(toks) or low[i] != 'procedure':
            raise Other('added at the end: "%s" is no plain procedure (no attribute, no trigger)' % ' '.join(toks[i:i + 6]))
        name = toks[i + 1] if i + 1 < len(toks) else '?'
        k = i + 1
        while k < len(toks) and low[k] != 'begin':
            if low[k] in ('procedure', 'trigger') or toks[k] == '[':
                raise Other('procedure %s: no body before "%s"' % (name, toks[k]))
            k += 1
        depth = 0
        while k < len(toks):
            if low[k] in ('begin', 'case'):
                depth += 1
            elif low[k] == 'end':
                depth -= 1
                if depth == 0:
                    break
            k += 1
        if k + 1 >= len(toks) or toks[k + 1] != ';':
            raise Other('procedure %s: no "end;" found' % name)
        found.append(name)
        i = k + 2
    if not found:
        raise Other('text added at the end')
    ctx.adds.extend('procedure %s' % n for n in found)


def classify_object(o, ohead, otree, n, nhead, ntree, new_tables, field_class):
    """(class, reason) for one object present in BASE (o) and HEAD (n)."""
    ctx = Ctx(n.kind, n.name, top_props(ntree), new_tables, field_class)
    ctx.implements = bool(re.search(r'\bimplements\b', nhead, re.I))
    try:
        if ohead != nhead:
            raise Other('declaration changed: "%s" -> "%s"' % (ohead, nhead))
        align(otree, ntree, [], ctx, top=True)
    except Other as e:
        return 'other', str(e)
    return ('additive', '; '.join(ctx.adds)) if ctx.adds else (None, 'no change')


def classify_extension(o, n, enum, ext_values, enum_implements):
    """An enumextension of a fixture enum: its added values follow the enum value rule."""
    ctx = Ctx('enum', enum, {}, set(), None)
    ctx.implements = enum_implements
    try:
        if o is not None and o[1] != n[1]:
            raise Other('declaration changed: "%s" -> "%s"' % (o[1], n[1]))
        old = o[2] if o is not None else []
        items = n[2]
        i = 0
        for j, x in enumerate(items):
            if i < len(old) and old[i] == x:
                i += 1
                continue
            if x[0] != 'b' or not VALUE_HEAD.fullmatch(x[1]):
                raise Other('enumextension of fixture enum "%s": added "%s"' % (enum, (x[1])[:60]))
            value(x, items, items[j + 1:], ctx, ext_values)
        if i < len(old):
            raise Other('removed or changed: %s' % old[i][1][:80])
    except Other as e:
        return 'other', str(e)
    return 'additive', '; '.join(ctx.adds) or 'no change'


# ---------- the diff ----------

def is_fixture(path):
    return any(r.match(path) for r in FIXTURE_ROOTS)


def classify(git, base, head):
    """[{path, object, class, reason}] for every fixture object BASE..HEAD changes, removes or extends."""
    base, head = git.rev(base), git.rev(head)
    out = git.run('diff', '--name-status', '--no-renames', '-z', base, head).split('\0')
    status = {}
    for k in range(0, len(out) - 1, 2):
        status[out[k + 1]] = out[k]
    al = [f for f in status if f.endswith('.al')]
    old_texts = git.read(base, [f for f in al if status[f] != 'A'])
    new_texts = git.read(head, [f for f in al if status[f] != 'D'])
    fixture_files = [f for f in git.files(head) if f.endswith('.al') and is_fixture(f)]
    head_fixture = git.read(head, fixture_files)

    def parsed(texts):
        return {f: objects(f, t) for f, t in texts.items()}
    old_objs, new_objs = parsed(old_texts), parsed(new_texts)

    def key(f, o):
        return ('/'.join(f.split('/')[:2]), o.kind, o.name)  # (app dir, kind, name)
    new_by_key = {key(f, x[0]): (f, x) for f, xs in new_objs.items() for x in xs}
    old_by_key = {key(f, x[0]): (f, x) for f, xs in old_objs.items() for x in xs}
    old_tables = {o.name for f, xs in old_objs.items() for o, _, _ in xs if o.kind == 'table'}
    added_tables = {o.name for f, xs in new_objs.items() for o, _, _ in xs if o.kind == 'table'} - old_tables
    # a table can only be new when no unchanged file declares it either
    added_tables -= {o.name for f, t in head_fixture.items() if f not in new_texts for o in st.parse_al(f, t)
                     if o.kind == 'table'}
    fx_head = {f: objects(f, t) for f, t in head_fixture.items()}
    fixture_enums = {o.name: bool(re.search(r'\bimplements\b', h, re.I)) for xs in fx_head.values() for o, h, _ in xs
                     if o.kind == 'enum'}
    fixture_enums.update({o.name: bool(re.search(r'\bimplements\b', h, re.I)) for f, xs in old_objs.items()
                          if is_fixture(f) for o, h, _ in xs if o.kind == 'enum' and o.name not in fixture_enums})
    tables = {}

    def field_class(table, field):
        if not tables:
            app_files = [f for f in git.files(head) if f.endswith('.al') and f.startswith('tests/')]
            for f, t in git.read(head, app_files).items():
                if re.search(r'\btable\s+\d+', t, re.I):
                    for o, h, items in objects(f, t):
                        if o.kind == 'table':
                            tables.setdefault(o.name, items)
        for x in tables.get(st.unquote(table), []):
            if x[0] == 'b' and x[1].lower() == 'fields':
                for y in x[2]:
                    m = FIELD_HEAD.fullmatch(y[1]) if y[0] == 'b' else None
                    if m and st.unquote(m.group(2)) == field:
                        cls = re.search(r'\bFieldClass\s*=\s*(\w+)', text_of(y[2]), re.I)
                        return cls.group(1).lower() if cls else 'normal'
        return None

    results = []
    for f in sorted(old_objs):
        if not is_fixture(f):
            continue
        scope_changed = f in new_texts and st.file_scope(old_texts[f]) != st.file_scope(new_texts[f])
        for o, oh, ot in old_objs[f]:
            hit = new_by_key.get(key(f, o))
            label = o.label() if o.kind else 'an object this script cannot read'
            if o.kind is None or hit is None:
                results.append({'path': f, 'object': label, 'class': 'other',
                                'reason': 'removed or renamed' if o.kind else 'object declaration not readable'})
                continue
            nf, (n, nh, nt) = hit
            if scope_changed:
                results.append({'path': f, 'object': label, 'class': 'other',
                                'reason': 'namespace, using or #define line of the file changed'})
                continue
            if st.sig(o) == st.sig(n):
                continue
            cls, why = classify_object(o, oh, ot, n, nh, nt, added_tables, field_class)
            if cls is None:  # only comments or whitespace changed
                continue
            results.append({'path': f, 'object': label, 'class': cls, 'reason': why})
    # enumextensions of fixture enums, anywhere in the diff
    exts = {}
    for side, objs in (('old', old_objs), ('new', new_objs)):
        for f, xs in objs.items():
            for x in xs:
                if x[0].kind == 'enumextension' and x[0].target in fixture_enums:
                    exts.setdefault((x[0].name, x[0].target), {})[side] = (f, x)
    for (name, enum), sides in sorted(exts.items()):
        o, n = sides.get('old'), sides.get('new')
        label = (n or o)[1][0].label()
        if n is None:
            if not any(k[2] == name for k in new_by_key):
                results.append({'path': o[0], 'object': label, 'class': 'other',
                                'reason': 'enumextension of fixture enum "%s" removed' % enum})
            continue
        if o is not None and st.sig(o[1][0]) == st.sig(n[1][0]):
            continue
        others = set()
        for xs in list(fx_head.values()) + list(new_objs.values()):
            for x in xs:
                if x[0].name != name and ((x[0].kind == 'enum' and x[0].name == enum)
                                          or (x[0].kind == 'enumextension' and x[0].target == enum)):
                    others |= {VALUE_HEAD.match(y[1]).group(1) for y in x[2] if y[0] == 'b' and VALUE_HEAD.match(y[1])}
        cls, why = classify_extension(o and o[1], n[1], enum, others, fixture_enums[enum])
        results.append({'path': n[0], 'object': label, 'class': cls,
                        'reason': 'edit of fixture enum "%s": %s' % (enum, why)})
    return results


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--base', required=True)
    ap.add_argument('--head', default='HEAD')
    ap.add_argument('--repo', default='.')
    ap.add_argument('--json')
    a = ap.parse_args(argv)
    try:
        results = classify(st.Git(a.repo), a.base, a.head)
    except Exception as e:  # noqa: BLE001 - the check could not be made: fail, never pass
        print('::error title=Fixture edit check::the check failed (%s: %s)' % (type(e).__name__, e))
        return 2
    for r in results:
        print('%-8s %s, %s: %s' % (r['class'], r['path'], r['object'], r['reason']))
    if not results:
        print('no merged fixture object changed in place')
    if a.json:
        with open(a.json, 'w') as f:
            json.dump(results, f, indent=1)
    return 1 if any(r['class'] == 'other' for r in results) else 0


if __name__ == '__main__':
    sys.exit(main())
