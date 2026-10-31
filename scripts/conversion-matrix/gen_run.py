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
FIXTURE_FILE = 'Y31ConvObjects.al'

# type -> AL declaration
DECL = {
    'Integer': 'Integer', 'BigInteger': 'BigInteger', 'Decimal': 'Decimal', 'Boolean': 'Boolean', 'Char': 'Char', 'Byte': 'Byte',
    'Option': 'Option A,B,C', 'Enum': 'Enum "LT Y31 E"', 'EnumImpl': 'Enum "LT Y31 EI"', 'Text': 'Text', 'Text10': 'Text[10]',
    'Text3': 'Text[3]', 'Code10': 'Code[10]', 'Code3': 'Code[3]', 'Code250': 'Code[250]', 'Date': 'Date', 'Time': 'Time',
    'DateTime': 'DateTime', 'Duration': 'Duration', 'Guid': 'Guid', 'Label': "Label 'abc', Locked = true",
    'LabelLong': "Label 'abcdefghijk', Locked = true",
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

CV_SOURCES = ['Integer', 'BigInteger', 'Decimal', 'Char', 'Byte', 'Option', 'Enum', 'EnumImpl', 'Text', 'Text10', 'Code10', 'Label',
              'LabelLong', 'Guid', 'Duration']
CV_TARGETS = ['Integer', 'BigInteger', 'Decimal', 'Char', 'Byte', 'Option', 'Enum', 'EnumImpl', 'Text', 'Text10', 'Text3', 'Code10',
              'Code3', 'Code250', 'Guid', 'Duration'] + list(FIELD_OF)
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
        self.procs = []   # extra procedures (lines)
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
        self.procs.append('    [TryFunction]\n    local procedure %s()\n    begin\n%s\n    end;\n' % (
            name, '\n'.join('        ' + b for b in body)))
        return name


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
                    pa = 'PA_%s_%d' % (t, u.n)
                    u.procs.append('    local procedure %s(p: %s)\n    begin\n        %s := p;\n    end;\n' % (pa, DECL[t], var(t)))
                    tries[c] = u.tryproc(['Clear(%s);' % var(t), '%s(%s);' % (pa, var(s))])
                else:
                    ex = 'EX_%s_%d' % (t, u.n)
                    u.procs.append('    local procedure %s(): %s\n    begin\n        exit(%s);\n    end;\n' % (ex, DECL[t], var(s)))
                    tries[c] = u.tryproc(['Clear(%s);' % var(t), '%s := %s();' % (var(t), ex)])
            for lbl, expr in CV_VALUES[s]:
                stmts += setv(s, expr)
                for c in ctxs:
                    stmts.append(observe_line('%s.%s' % (c, lbl), tries[c], fmt(t)))
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
                    pa = 'PA_%s_%d' % (t, u.n)
                    u.procs.append('    local procedure %s(p: %s)\n    begin\n        %s := p;\n    end;\n' % (pa, DECL[t], var(t)))
                    tr = u.tryproc(['Clear(%s);' % var(t), '%s(%s);' % (pa, lit)])
                else:
                    ex = 'EX_%s_%d' % (t, u.n)
                    u.procs.append('    local procedure %s(): %s\n    begin\n        exit(%s);\n    end;\n' % (ex, DECL[t], lit))
                    tr = u.tryproc(['Clear(%s);' % var(t), '%s := %s();' % (var(t), ex)])
                stmts.append(observe_line('%s.%s' % (c, lbl), tr, fmt(t)))
            u.tests.append(('%s_To_%s' % (lname.replace('lit.', 'Lit'), t.replace('.', '')), stmts))
    units.append(u)
    return units, cid


def pair_values(s, t, extra=False):
    a = FEW[s] + (AR_EXTRA.get(s, []) if extra else [])
    b = FEW[t] + (AR_EXTRA.get(t, []) if extra else [])
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
                else:
                    body = ['Clear(V);', 'V := Res ? %s : %s;' % (lv, rv)]
                tries[o] = u.tryproc(body)
            stmts = []
            a, b = pair_values(s, t, fam == 'Ar')
            for la, ea in a:
                for lb, eb in b:
                    for o in ops:
                        conds = [('t', 'true'), ('f', 'false')] if o == 'cond_branches' else [(None, None)]
                        for lc, ec in conds:
                            stmts += setv(s, ea)
                            if eb is not None:
                                stmts.append('%s := %s;' % (rv, eb))
                            if ec is not None:
                                stmts.append('Res := %s;' % ec)
                            key = '%s.%s.%s' % (o, la, lb) + ('.%s' % lc if lc else '')
                            if o in ('eq', 'lt', 'in_set', 'case_label'):
                                show = 'Format(Res, 0, 9)'
                            elif o == 'compound_add':
                                show = fmt(t) if s != t else fmt(t).replace(var(t), rv)
                            else:
                                show = 'Util.VShow(V)'
                            stmts.append(observe_line(key, tries[o], show))
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


def render(u, observed):
    out = [HEADER % u.title]
    out.append('codeunit %d "%s"' % (u.cid, u.name))
    out.append('{')
    out.append('    Subtype = Test;')
    out.append('    TestPermissions = Disabled;')
    out.append('')
    out.append('    var')
    out.append('        Observer: Codeunit "Probe Observer";')
    out.append('        Util: Codeunit "LT Y31 Conv Util";')
    for k in sorted(u.globals):
        out.append('        %s: %s;' % (k, u.globals[k]))
    out.append('')
    for name, stmts in u.tests:
        out.append('    [Test]')
        out.append('    procedure %s()' % name)
        out.append('    begin')
        for s in stmts:
            out.append('        ' + s)
        if observed is None:
            out.append('        Observer.Finish();')
        else:
            pairs = observed.get((u.name, name))
            if pairs is None:
                raise SystemExit('no observation for %s %s' % (u.name, name))
            for k, v in pairs:
                out.append("        Observer.Expect('%s', %s);" % (k, al_text(v)))
            out.append('        Observer.Verify();')
        out.append('    end;')
        out.append('')
        if observed is None:
            for i in range(1, 6):
                out.append('    [Test]')
                out.append('    procedure %s_More%d()' % (name, i))
                out.append('    begin')
                out.append('        Observer.More();')
                out.append('    end;')
                out.append('')
    out.extend(u.procs)
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
    for gen in (gen_cv, lambda m, c: gen_ops(m, c, 'Cmp'), lambda m, c: gen_ops(m, c, 'Ar'), lambda m, c: gen_ops(m, c, 'Cd')):
        us, cid = gen(m, cid)
        units += us
    if cid > 92549:
        raise SystemExit('out of ids: %d' % cid)
    observed = None
    if a.observed:
        msgs = load_observed(a.observed)
        observed = {}
        for u in units:
            for name, _ in u.tests:
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
