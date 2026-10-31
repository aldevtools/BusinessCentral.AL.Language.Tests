#!/usr/bin/env python3
"""Run matrix of AL implicit conversions: test codeunits for the cells the compile matrix accepts.

usage: gen_run.py --matrix compile-matrix.csv --out DIR [--observed RESULT.json ...]

Without --observed the codeunits are written in the observe form: every test ends with Observer.Finish(), so the test fails with the
values BC produced (and _MoreN tests carry the rest of a long observation). With --observed (the result JSON of a run of the observe
form: local-loop or ci-batch shape, legs.<major>.tests[].message) the same tests are written in the final form, with one Expect per
observed value and Verify().

Families (one codeunit per family and source type):
  Cv  conversions: assignment (:=), by-value argument, exit(x); each target the compile matrix accepts for that source
  Cmp comparisons: =, <, `in [..]`, case selector against a case label of the other type
  Ar  arithmetic: +, - (result type and value through a Variant) and the compound assignment +=
  Cd  conditional expression: Variant := Cond ? Source : Other, for both values of Cond (result type and value)
Each operation runs in a [TryFunction], so a cell gives a value or the error text and code (Observer.ObserveError).
"""
import argparse
import csv
import json
import os
import re
import sys

ID_FIRST = 92410
ID_SUSPECT = 92500
# tests whose codeunit lost its BC session on the corpus CI (BC 29.0, 2026-10-31: "session killed twice by this codeunit"): each runs in a
# codeunit of its own, after the others, until the crashing cell is known (then it is held as a Linux suspect)
SUSPECTS = [('LT Y31 Cv Enum', 'Enum_To_BigInteger'), ('LT Y31 Cv Enum', 'Enum_To_FBigInteger'),
            ('LT Y31 Cv EnumImpl', 'EnumImpl_To_BigInteger'), ('LT Y31 Cv EnumImpl', 'EnumImpl_To_FBigInteger'),
            ('LT Y31 Cv Literals', 'LitEnum_To_BigInteger'), ('LT Y31 Cv Literals', 'LitEnum_To_FBigInteger'),
            ('LT Y31 Cd BigInteger', 'BigInteger_Enum'), ('LT Y31 Cd BigInteger', 'BigInteger_EnumImpl'),
            ('LT Y31 Cd EnumImpl', '*'), ('LT Y31 Ar Byte', 'Byte_BigInteger'), ('LT Y31 Ar Byte', 'Byte_Enum'),
            ('LT Y31 Ar Byte', 'Byte_EnumImpl')]
FIXTURE_FILE = 'Y31ConvObjects.al'

# type -> AL declaration
DECL = {
    'Integer': 'Integer', 'BigInteger': 'BigInteger', 'Decimal': 'Decimal', 'Boolean': 'Boolean', 'Char': 'Char', 'Byte': 'Byte',
    'Option': 'Option A,B,C', 'Enum': 'Enum "LT Y31 E"', 'EnumImpl': 'Enum "LT Y31 EI"', 'Text': 'Text', 'Text10': 'Text[10]',
    'Text3': 'Text[3]', 'Code10': 'Code[10]', 'Code3': 'Code[3]', 'Code250': 'Code[250]', 'Date': 'Date', 'Time': 'Time',
    'DateTime': 'DateTime', 'Duration': 'Duration', 'Guid': 'Guid', 'Label': "Label 'abc', Locked = true",
    'LabelLong': "Label 'abcdefghijk', Locked = true", 'Variant': 'Variant',
}
FIELD_OF = {'F.Integer': 'Integer', 'F.BigInteger': 'BigInteger', 'F.Decimal': 'Decimal', 'F.Option': 'Option', 'F.Enum': 'Enum',
            'F.Text10': 'Text10', 'F.Code10': 'Code10', 'F.Guid': 'Guid', 'F.Duration': 'Duration'}
GUID = '{5C4E1F0A-9B3D-4E2F-8A1B-0C2D3E4F5A6B}'
GUID_LOWER_NOBRACE = '5c4e1f0a-9b3d-4e2f-8a1b-0c2d3e4f5a6b'

# boundary values of a source of the conversion family: (label, AL statement that sets v<Type>)
CV_VALUES = {
    'Integer': [('0', '0'), ('m1', '-1'), ('3', '3'), ('255', '255'), ('256', '256'), ('65536', '65536'), ('max', '2147483647')],
    'BigInteger': [('0', '0'), ('m1', '-1'), ('3', '3'), ('2p31', '2147483648L'), ('m2p31m1', '-2147483649L')],
    'Decimal': [('0', '0'), ('1p5', '1.5'), ('m1p5', '-1.5'), ('2p5', '2.5'), ('3', '3'), ('255', '255'), ('256', '256'),
                ('2p31', '2147483648.0'), ('0p0001', '0.0001')],
    'Char': [('0', '0'), ('65', '65'), ('97', '97'), ('255', '255'), ('256', '256'), ('65535', '65535')],
    'Byte': [('0', '0'), ('97', '97'), ('255', '255')],
    'Option': [('0', '0'), ('2', '2'), ('3', '3'), ('m1', '-1')],
    'Enum': [('A', '"LT Y31 E"::A'), ('C', '"LT Y31 E"::C'), ('ord5', '5')],
    'EnumImpl': [('A', '"LT Y31 EI"::A'), ('ord9', '9')],
    'Text': [('empty', "''"), ('a', "'a'"), ('abc', "'abc'"), ('lead', "' ab'"), ('trail', "'ab '"), ('ten', "'abcdefghij'"),
             ('eleven', "'abcdefghijk'"), ('umlaut', "'äöß'"), ('guid', "'%s'" % GUID), ('guidlow', "'%s'" % GUID_LOWER_NOBRACE),
             ('notguid', "'xyz'"), ('digits', "'12'")],
    'Text10': [('empty', "''"), ('a', "'a'"), ('abc', "'abc'"), ('ten', "'abcdefghij'")],
    'Code10': [('empty', "''"), ('ABC', "'abc'"), ('ten', "'ABCDEFGHIJ'"), ('digits', "'12'")],
    'Label': [('abc', None)],
    'LabelLong': [('eleven', None)],
    'Guid': [('null', None), ('g', "'%s'" % GUID)],
    'Duration': [('0', '0'), ('1', '1'), ('255', '255'), ('m1', '-1'), ('2p31', '2147483648L')],
    # a Variant holding a value of each type (the Util helpers return the typed value)
    'Variant': [('int3', '3'), ('int300', '300'), ('big', '3000000000L'), ('dec1p5', '1.5'), ('dec2', '2.0'), ('charA', 'Util.AsChar(65)'),
                ('byte65', 'Util.AsByte(65)'), ('optB', 'Util.AsOption(1)'), ('enumC', '"LT Y31 E"::C'), ('textabc', "Util.AsText('abc')"),
                ('text11', "Util.AsText('abcdefghijk')"), ('text12', "Util.AsText('12')"), ('codeABC', "Util.AsCode('abc')"),
                ('code12', "Util.AsCode('12')"), ('guid', "Util.AsGuid('%s')" % GUID), ('boolF', 'false'), ('boolT', 'true'),
                ('date', '20260131D'), ('time', '120000T'), ('dt', 'CreateDateTime(20260131D, 120000T)'), ('dur65', 'Util.AsDuration(65)')],
}
# a few values per type for comparisons, arithmetic and conditional expressions
FEW = {
    'Integer': [('65', '65'), ('1', '1')], 'BigInteger': [('65', '65')], 'Decimal': [('65', '65'), ('1p5', '1.5')],
    'Char': [('A', '65'), ('a', '97')], 'Byte': [('65', '65')], 'Option': [('1', '1'), ('3', '3')],
    'Enum': [('B', '"LT Y31 E"::B'), ('ord5', '5')], 'EnumImpl': [('A', '"LT Y31 EI"::A')], 'Boolean': [('t', 'true')],
    'Text': [('a', "'a'"), ('A', "'A'"), ('abc', "'abc'"), ('guidlow', "'%s'" % GUID_LOWER_NOBRACE)],
    'Text10': [('abc', "'abc'")], 'Code10': [('A', "'A'"), ('ABC', "'ABC'")], 'Guid': [('g', "'%s'" % GUID)],
    'Date': [('d', '20260131D')], 'Time': [('t', '120000T')], 'DateTime': [('dt', 'CreateDateTime(20260131D, 120000T)')],
    'Duration': [('65', '65')], 'Label': [('abc', None)],
}
AR_EXTRA = {'Integer': [('max', '2147483647')], 'Byte': [('255', '255')], 'Char': [('65535', '65535')]}
# a false branch longer than a Text[10] true branch (al-runner refuses `B ? Text[N] : Text`)
CD_EXTRA = {'Text': [('eleven', "'abcdefghijk'")], 'Label': []}
TEXTISH = ('Text', 'Text10', 'Code10', 'Label', 'Guid', 'Char')

CV_SOURCES = ['Integer', 'BigInteger', 'Decimal', 'Char', 'Byte', 'Option', 'Enum', 'EnumImpl', 'Text', 'Text10', 'Code10', 'Label',
              'LabelLong', 'Guid', 'Duration', 'Variant']
CV_TARGETS = ['Integer', 'BigInteger', 'Decimal', 'Char', 'Byte', 'Option', 'Enum', 'EnumImpl', 'Text', 'Text10', 'Text3', 'Code10',
              'Code3', 'Code250', 'Guid', 'Duration', 'Boolean', 'Date', 'Time', 'DateTime'] + list(FIELD_OF)
OP_TYPES = ['Integer', 'BigInteger', 'Decimal', 'Char', 'Byte', 'Option', 'Enum', 'EnumImpl', 'Boolean', 'Text', 'Text10', 'Code10',
            'Guid', 'Date', 'Time', 'DateTime', 'Duration', 'Label']
LITERALS = [('lit.Decimal', '1.5', 'dec1p5'), ('lit.Char1', "'a'", 'chara'), ('lit.Text', "'abc'", 'abc'), ('lit.TextEmpty', "''", 'empty'),
            ('lit.Integer', '7', 'i7'), ('lit.Enum', '"LT Y31 E"::C', 'enumC')]
# the compile matrix uses the probe objects "Y31 E", "Y31 EI"; the corpus objects are named "LT Y31 ..."
MATRIX_NAME = {'Label': 'Label', 'LabelLong': 'Label'}


def var(t):
    if t in FIELD_OF:
        return 'R.%s' % t.split('.', 1)[1]
    return 'v' + t


def fmt(t):
    """AL expression that shows the value of target t."""
    base = FIELD_OF.get(t, t)
    v = var(t)
    if base in ('Text', 'Text10', 'Text3', 'Code10', 'Code3', 'Code250'):
        return "%s + '|' + Format(StrLen(%s))" % (v, v)
    if base == 'Char':
        return "Format(%s) + '|' + Format(Util.CharOrd(%s))" % (v, v)
    if base == 'Option':
        return "Format(%s) + '|' + Format(Util.OptOrd(%s))" % (v, v)
    if base in ('Enum', 'EnumImpl'):
        return "Format(%s) + '|' + Format(%s.AsInteger())" % (v, v)
    if base == 'Guid':
        return 'Format(%s)' % v
    return 'Format(%s, 0, 9)' % v


def load_matrix(path):
    rows = list(csv.reader(open(path)))
    hdr = rows[0]
    m = {}
    for r in rows[1:]:
        for i in range(2, len(r)):
            if r[i]:
                m[(r[0], r[1], hdr[i])] = r[i].startswith('ok')
    return m


def accepted(m, ctx, s, t):
    s = MATRIX_NAME.get(s, s)
    t = MATRIX_NAME.get(t, t)
    return m.get((ctx, s, t), False)


class Unit:
    def __init__(self, cid, name, title):
        self.cid, self.name, self.title = cid, name, title
        self.tests = []   # (name, [statements])
        self.procs = []   # (name, try?, params, return type, body lines)
        self.globals = {}
        self.n = 0

    def g(self, t):
        if t in FIELD_OF:
            self.globals['R'] = 'Record "LT Y31 Conv Fields"'
        else:
            self.globals[var(t)] = DECL[t]

    def tryproc(self, body):
        self.n += 1
        name = 'Try%d' % self.n
        self.procs.append((name, True, '', '', body))
        return name

    def pa(self, t):
        self.n += 1
        name = 'PA_%s_%d' % (t.replace('.', ''), self.n)
        self.procs.append((name, False, 'p: %s' % DECL[t], '', ['%s := p;' % var(t)]))
        return name

    def ex(self, t, expr):
        self.n += 1
        name = 'EX_%s_%d' % (t.replace('.', ''), self.n)
        self.procs.append((name, False, '', DECL[t], ['exit(%s);' % expr]))
        return name


GROUP = '--group--'
MAX_OBS = 8
LABELS = ('vLabel', 'vLabelLong', 'vLabel_R')


def observe_line(key, tryname, show):
    return 'if %s() then Observer.Observe(\'%s\', %s) else Observer.ObserveError(\'%s\');' % (tryname, key, show, key)


def setv(t, expr):
    return [] if expr is None else ['%s := %s;' % (var(t), expr)]


def gen_cv(m, cid):
    units = []
    for s in CV_SOURCES:
        u = Unit(cid, 'LT Y31 Cv %s' % s, 'conversions from %s' % s)
        cid += 1
        u.g(s)
        for t in CV_TARGETS:
            if FIELD_OF.get(t, t) == s:
                continue
            ctxs = [c for c in ('assign', 'arg_byvalue', 'exit') if t not in FIELD_OF or c == 'assign']
            ctxs = [c for c in ctxs if accepted(m, c, s, t)]
            if not ctxs:
                continue
            u.g(t)
            stmts = []
            tries = {}
            for c in ctxs:
                if c == 'assign':
                    tries[c] = u.tryproc(['Clear(%s);' % var(t), '%s := %s;' % (var(t), var(s))])
                elif c == 'arg_byvalue':
                    pa = u.pa(t)
                    tries[c] = u.tryproc(['Clear(%s);' % var(t), '%s(%s);' % (pa, var(s))])
                else:
                    ex = u.ex(t, var(s))
                    tries[c] = u.tryproc(['Clear(%s);' % var(t), '%s := %s();' % (var(t), ex)])
            for lbl, expr in CV_VALUES[s]:
                stmts += setv(s, expr)
                for c in ctxs:
                    stmts.append(observe_line('%s.%s' % (c, lbl), tries[c], fmt(t)))
                stmts.append(GROUP)
            u.tests.append(('%s_To_%s' % (s, t.replace('.', '')), stmts))
        if u.tests:
            units.append(u)
    # literals
    u = Unit(cid, 'LT Y31 Cv Literals', 'conversions from literals')
    cid += 1
    for lname, lit, lbl in LITERALS:
        for t in CV_TARGETS:
            ctxs = [c for c in ('assign', 'arg_byvalue', 'exit') if t not in FIELD_OF or c == 'assign']
            ctxs = [c for c in ctxs if accepted(m, c, lname, t)]
            if not ctxs:
                continue
            u.g(t)
            stmts = []
            for c in ctxs:
                if c == 'assign':
                    tr = u.tryproc(['Clear(%s);' % var(t), '%s := %s;' % (var(t), lit)])
                elif c == 'arg_byvalue':
                    pa = u.pa(t)
                    tr = u.tryproc(['Clear(%s);' % var(t), '%s(%s);' % (pa, lit)])
                else:
                    ex = u.ex(t, lit)
                    tr = u.tryproc(['Clear(%s);' % var(t), '%s := %s();' % (var(t), ex)])
                stmts.append(observe_line('%s.%s' % (c, lbl), tr, fmt(t)))
                stmts.append(GROUP)
            u.tests.append(('%s_To_%s' % (lname.replace('lit.', 'Lit'), t.replace('.', '')), stmts))
    units.append(u)
    return units, cid


TP_VALUES = [('abc', "'abc'"), ('ten', "'abcdefghij'"), ('lead', "' ab'"), ('empty', "''")]
TP_TARGETS = ['Text', 'Text10', 'Text3', 'Code10', 'Code3', 'Guid', 'F.Code10']


def gen_tp(m, cid):
    """the value of a TestPage control (Text) converted by :=, by-value argument and exit; the control shows a Text[10] field."""
    u = Unit(cid, 'LT Y31 Tp Value', 'the value of a TestPage control')
    cid += 1
    u.globals['TP'] = 'TestPage "LT Y31 Conv Card"'
    u.globals['R'] = 'Record "LT Y31 Conv Fields"'
    u.globals['RowR'] = 'Record "LT Y31 Conv Fields"'
    u.globals['vShown'] = 'Text'
    for t in TP_TARGETS:
        ctxs = [c for c in ('assign', 'arg_byvalue') if (t not in FIELD_OF or c == 'assign') and accepted(m, c, 'TestPage.Value', t)]
        if not ctxs:
            continue
        u.g(t)
        tries = {}
        for c in ctxs:
            if c == 'assign':
                tries[c] = u.tryproc(['Clear(%s);' % var(t), '%s := TP.FText.Value;' % var(t)])
            else:
                pa = u.pa(t)
                tries[c] = u.tryproc(['Clear(%s);' % var(t), '%s(TP.FText.Value);' % pa])
        stmts = []
        for lbl, expr in TP_VALUES:
            stmts += ['RowR.DeleteAll();', 'RowR.Init();', 'RowR.Integer := 1;', 'RowR.Text10 := %s;' % expr, 'RowR.Insert();',
                      'TP.OpenView();', 'TP.GoToRecord(RowR);', 'vShown := TP.FText.Value;',
                      "Observer.Observe('shown.%s', vShown + '|' + Format(StrLen(vShown)));" % lbl]
            for c in ctxs:
                stmts.append(observe_line('%s.%s' % (c, lbl), tries[c], fmt(t)))
            stmts.append('TP.Close();')
            stmts.append(GROUP)
        u.tests.append(('TestPageValue_To_%s' % t.replace('.', ''), stmts))
    return [u], cid


def pair_values(s, t, fam):
    ex = {'Ar': AR_EXTRA, 'Cd': CD_EXTRA}.get(fam, {})
    a = FEW[s] + ex.get(s, [])
    b = FEW[t] + ex.get(t, [])
    return a, b


def second(t):
    """the right operand of a pair of the same type uses a second variable."""
    return t + '_R'


def gen_ops(m, cid, fam):
    units = []
    for s in OP_TYPES:
        u = Unit(cid, 'LT Y31 %s %s' % (fam, s), {'Cmp': 'comparisons', 'Ar': 'arithmetic', 'Cd': 'conditional expressions'}[fam] + ' with ' + s)
        cid += 1
        for t in OP_TYPES:
            if fam == 'Cmp':
                ops = [o for o in ('eq', 'lt', 'in_set', 'case_label') if accepted(m, o, s, t)]
                if s == t:
                    ops = []
            elif fam == 'Ar':
                ops = [o for o in ('add', 'sub', 'compound_add') if accepted(m, o, s, t)]
            else:
                ops = ['cond_branches'] if accepted(m, 'cond_branches', s, t) and s != t else []
                if ops and s in TEXTISH and t in TEXTISH and accepted(m, 'assign', s, 'Text'):
                    ops.append('cond_to_text')
            if not ops:
                continue
            lv = var(s)
            rt = t
            if s == t:
                rv = 'v%s_R' % t
                u.globals[rv] = DECL[t]
            else:
                rv = var(t)
                u.g(t)
            u.g(s)
            u.globals['V'] = 'Variant'
            u.globals['Res'] = 'Boolean'
            tries = {}
            for o in ops:
                if o == 'eq':
                    body = ['Res := %s = %s;' % (lv, rv)]
                elif o == 'lt':
                    body = ['Res := %s < %s;' % (lv, rv)]
                elif o == 'in_set':
                    body = ['Res := %s in [%s];' % (lv, rv)]
                elif o == 'case_label':
                    body = ['Res := false;', 'case %s of' % lv, '    %s:' % rv, '        Res := true;', 'end;']
                elif o == 'add':
                    body = ['Clear(V);', 'V := %s + %s;' % (lv, rv)]
                elif o == 'sub':
                    body = ['Clear(V);', 'V := %s - %s;' % (lv, rv)]
                elif o == 'compound_add':
                    body = ['%s += %s;' % (rv, lv)]
                elif o == 'cond_to_text':
                    u.globals['vOut'] = 'Text'
                    body = ['Clear(vOut);', 'vOut := Res ? %s : %s;' % (lv, rv)]
                else:
                    body = ['Clear(V);', 'V := Res ? %s : %s;' % (lv, rv)]
                tries[o] = u.tryproc(body)
            stmts = []
            a, b = pair_values(s, t, fam)
            for la, ea in a:
                for lb, eb in b:
                    for o in ops:
                        conds = [('t', 'true'), ('f', 'false')] if o.startswith('cond') else [(None, None)]
                        for lc, ec in conds:
                            stmts += setv(s, ea)
                            if eb is not None:
                                stmts.append('%s := %s;' % (rv, eb))
                            if ec is not None:
                                stmts.append('Res := %s;' % ec)
                            key = '%s.%s.%s' % (o, la, lb) + ('.%s' % lc if lc else '')
                            if o in ('eq', 'lt', 'in_set', 'case_label'):
                                show = 'Format(Res, 0, 9)'
                            elif o == 'cond_to_text':
                                show = "vOut + '|' + Format(StrLen(vOut))"
                            elif o == 'compound_add':
                                show = fmt(t) if s != t else fmt(t).replace(var(t), rv)
                            else:
                                show = 'Util.VShow(V)'
                            stmts.append(observe_line(key, tries[o], show))
                            stmts.append(GROUP)
            u.tests.append(('%s_%s' % (s, t if s != t else t + '_Same'), stmts))
        if u.tests:
            units.append(u)
    return units, cid


HEADER = '''// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-type-conversion
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), LT Y31 Conv Util / LT Y31 Conv Fields (Y31ConvObjects.al)
// Generated by scripts/conversion-matrix/gen_run.py from scripts/conversion-matrix/compile-matrix.csv (the cells the AL compiler
// accepts); the expected values are what the corpus CI containers produced. Regenerate, do not edit by hand.
// Facts: implicit conversion matrix, %s
'''


def strip_strings(line):
    return re.sub(r"'(?:[^']|'')*'", "''", line)


def refs(lines, names):
    found = set()
    for l in lines:
        for w in re.findall(r'[A-Za-z_][A-Za-z0-9_]*', strip_strings(l)):
            if w in names:
                found.add(w)
    return found


def chunks(name, stmts):
    """split a test at its group marks so that every part has at most MAX_OBS observations."""
    groups, cur = [], []
    for st in stmts:
        if st == GROUP:
            if cur:
                groups.append(cur)
            cur = []
        else:
            cur.append(st)
    if cur:
        groups.append(cur)
    parts, part, nobs = [], [], 0
    for g in groups:
        k = sum(1 for st in g if 'Observer.Observe' in st)
        if part and nobs + k > MAX_OBS:
            parts.append(part)
            part, nobs = [], 0
        part += g
        nobs += k
    if part:
        parts.append(part)
    return [(name if i == 0 else '%s_%d' % (name, i + 1), p) for i, p in enumerate(parts)]


MAX_OBS_FINAL = 48


def final_parts(tname, stmts, final):
    """the observe form: the chunks of chunks(); the final form joins consecutive chunks up to MAX_OBS_FINAL observations (a Verify
    has no message limit), and names the observe chunks whose observations it expects."""
    parts = chunks(tname, stmts)
    if not final:
        return [(n, p, [n]) for n, p in parts]
    out, cur, names, nobs = [], [], [], 0
    for n, p in parts:
        k = sum(1 for st in p if 'Observer.Observe' in st)
        if cur and nobs + k > MAX_OBS_FINAL:
            out.append(cur_names(tname, len(out)) + (cur, names))
            cur, names, nobs = [], [], 0
        cur, names, nobs = cur + p, names + [n], nobs + k
    if cur:
        out.append(cur_names(tname, len(out)) + (cur, names))
    return out


def cur_names(tname, i):
    return (tname if i == 0 else '%s_%d' % (tname, i + 1),)


def render(u, observed):
    """every variable is local: a test declares what it uses and passes it as a var parameter to the procedures that use it (so a
    test does not depend on the state an earlier test left). Labels are declared where they are used."""
    names = dict(u.globals)
    names['Util'] = 'Codeunit "LT Y31 Conv Util"'
    labels = {n: d for n, d in names.items() if n in LABELS}
    vars_ = {n: d for n, d in names.items() if n not in LABELS}
    procnames = [p[0] for p in u.procs]
    # names a procedure needs, through the procedures it calls
    need = {}
    calls = {}
    for name, _, _, _, body in u.procs:
        need[name] = refs(body, vars_)
        calls[name] = refs(body, set(procnames))
    changed = True
    while changed:
        changed = False
        for n in need:
            for c in calls[n]:
                if not need[c] <= need[n]:
                    need[n] |= need[c]
                    changed = True
    order = {n: sorted(need[n]) for n in need}

    def call_fix(line):
        def sub(mm):
            pn, args = mm.group(1), mm.group(2)
            extra = ', '.join(order[pn])
            if not extra:
                return mm.group(0)
            return '%s(%s)' % (pn, (args + ', ' + extra) if args.strip() else extra)
        return re.sub(r'\b(%s)\(([^()]*)\)' % '|'.join(map(re.escape, procnames)), sub, line) if procnames else line

    out = [HEADER % u.title]
    out.append('codeunit %d "%s"' % (u.cid, u.name))
    out.append('{')
    out.append('    Subtype = Test;')
    out.append('    TestPermissions = Disabled;')
    out.append('')
    for tname, stmts in u.tests:
        for name, part, obs_names in final_parts(tname, stmts, observed is not None):
            used = refs(part, vars_)
            for st in part:
                for pn in refs([st], set(procnames)):
                    used |= need[pn]
            out.append('    [Test]')
            out.append('    procedure %s()' % name)
            out.append('    var')
            out.append('        Observer: Codeunit "Probe Observer";')
            for n in sorted(used):
                out.append('        %s: %s;' % (n, vars_[n]))
            out.append('    begin')
            for st in part:
                out.append('        ' + call_fix(st))
            if observed is None:
                out.append('        Observer.Finish();')
            else:
                pairs = []
                for on in obs_names:
                    got = observed.get((u.name, on))
                    if got is None:
                        raise SystemExit('no observation for %s %s' % (u.name, on))
                    pairs += got
                for k, v in pairs:
                    out.append("        Observer.Expect('%s', %s);" % (k, al_text(v)))
                out.append('        Observer.Verify();')
            out.append('    end;')
            out.append('')
    called = set()
    for tname, stmts in u.tests:
        called |= refs([x for x in stmts if x != GROUP], set(procnames))
    frontier = set(called)
    while frontier:
        nxt = set()
        for n in frontier:
            nxt |= calls[n] - called
        called |= nxt
        frontier = nxt
    for name, is_try, params, ret, body in u.procs:
        if name not in called:
            continue
        ps = [params] if params else []
        ps += ['var %s: %s' % (n, vars_[n]) for n in order[name]]
        lab = sorted(refs(body, labels))
        if is_try:
            out.append('    [TryFunction]')
        out.append('    local procedure %s(%s)%s' % (name, '; '.join(ps), (': ' + ret) if ret else ''))
        if lab:
            out.append('    var')
            for n in lab:
                out.append('        %s: %s;' % (n, labels[n]))
        out.append('    begin')
        for b in body:
            out.append('        ' + call_fix(b))
        out.append('    end;')
        out.append('')
    out.append('}')
    return '\n'.join(out) + '\n'


def al_text(v):
    return "'" + v.replace("'", "''") + "'"


RS, US = '␞', '␟'


def load_observed(paths):
    msgs = {}
    for p in paths:
        j = json.load(open(p))
        legs = j.get('legs', {})
        for leg in legs.values():
            for t in leg.get('tests', []):
                msgs[(t['codeunit'], t['test'])] = t.get('message') or ''
    return msgs


def observed_pairs(msgs, cname_by_id, unit, test):
    def find(name):
        for k, v in msgs.items():
            if (k[0] == unit.name or str(k[0]) == str(unit.cid) or k[0] == cname_by_id.get(unit.cid)) and k[1] == name:
                return v
        return None
    text = ''
    m = find(test)
    if m is None:
        return None
    i = 1
    while True:
        m = m.strip()
        mm = re.match(r'^(OBSERVE|OBSERVEMORE):(.*?)(<MORE>)?$', m, re.S)
        if not mm:
            raise SystemExit('unexpected message for %s %s: %s' % (unit.name, test, m[:200]))
        text += mm.group(2)
        if not mm.group(3):
            break
        m = find('%s_More%d' % (test, i))
        i += 1
        if m is None:
            raise SystemExit('missing more piece %d for %s %s' % (i - 1, unit.name, test))
    pairs = []
    for p in text.split(RS):
        if p:
            k, v = p.split(US, 1)
            pairs.append((k, v))
    return pairs


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--matrix', required=True)
    ap.add_argument('--out', required=True)
    ap.add_argument('--observed', action='append')
    a = ap.parse_args()
    m = load_matrix(a.matrix)
    units = []
    cid = ID_FIRST
    for gen in (gen_cv, gen_tp, lambda m, c: gen_ops(m, c, 'Cmp'), lambda m, c: gen_ops(m, c, 'Ar'), lambda m, c: gen_ops(m, c, 'Cd')):
        us, cid = gen(m, cid)
        units += us
    if cid > ID_SUSPECT:
        raise SystemExit('out of ids: %d' % cid)
    sid = ID_SUSPECT
    for u in list(units):
        for tname, stmts in list(u.tests):
            if (u.name, tname) in SUSPECTS or (u.name, '*') in SUSPECTS:
                v = Unit(sid, 'LT Y31 Sus %d' % (sid - ID_SUSPECT + 1), u.title + ' (' + tname + ', in a codeunit of its own)')
                sid += 1
                v.globals = dict(u.globals)
                v.procs = u.procs
                v.tests = [(tname, stmts)]
                v.family = u.name
                u.tests.remove((tname, stmts))
                units.append(v)
        if not u.tests:
            units.remove(u)
    if sid > 92549:
        raise SystemExit('out of suspect ids: %d' % sid)
    observed = None
    if a.observed:
        msgs = load_observed(a.observed)
        observed = {}
        for u in units:
            for tname, stmts in u.tests:
              for name, _ in chunks(tname, stmts):
                p = observed_pairs(msgs, {}, u, name)
                if p is not None:
                    observed[(u.name, name)] = p
    os.makedirs(a.out, exist_ok=True)
    files = {}
    for u in units:
        fam = u.name.split(' ')[2]
        files.setdefault('Y31Conv%s.al' % fam, []).append(render(u, observed))
    for fn, parts in files.items():
        with open(os.path.join(a.out, fn), 'w') as f:
            f.write('\n'.join(parts))
    print('%d codeunits (%d-%d), %d tests' % (len(units), ID_FIRST, cid - 1, sum(len(u.tests) for u in units)), file=sys.stderr)


if __name__ == '__main__':
    main()
