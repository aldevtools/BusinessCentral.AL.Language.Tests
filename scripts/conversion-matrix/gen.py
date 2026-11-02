#!/usr/bin/env python3
"""Compile matrix of AL implicit conversions.

For every context (assignment, by-value argument, var argument, exit, comparison, arithmetic, in-set, case, conditional
expression, compound assignment) and every (source, target) type pair, this script writes one line of AL that uses the
source value where the target type is expected, compiles every context as its own one-app project with the real AL
compiler, and records per cell: `ok` (no diagnostic on that line) or the diagnostic codes on that line, with the first
message. Warnings are recorded too (for example AL0603, the Integer-to-Enum warning).

usage: gen.py --al <AL command> --symbols <dir with System.app> [--runtime 18.0] [--out compile-matrix.csv] [--keep DIR]

The matrix is the input for the run matrix (tests/al-language/types/lt-y31-conversion-matrix/): only accepted cells run.
"""
import argparse
import csv
import os
import re
import shutil
import subprocess
import sys
import tempfile

# name -> (declaration of a global variable or None, expression). Fields live on table 92400, the TestPage control on page 92400.
VARS = [
    ('Integer', 'Integer'), ('BigInteger', 'BigInteger'), ('Decimal', 'Decimal'), ('Boolean', 'Boolean'),
    ('Char', 'Char'), ('Byte', 'Byte'), ('Option', 'Option A,B,C'), ('Option2', 'Option X,Y,Z'),
    ('Enum', 'Enum "Y31 E"'), ('Enum2', 'Enum "Y31 E2"'), ('EnumImpl', 'Enum "Y31 EI"'),
    ('Text', 'Text'), ('Text10', 'Text[10]'), ('Text3', 'Text[3]'), ('Code250', 'Code[250]'), ('Code10', 'Code[10]'), ('Code3', 'Code[3]'),
    ('Label', "Label 'abc'"), ('TextConst', "TextConst ENU = 'abc'"),
    ('Date', 'Date'), ('Time', 'Time'), ('DateTime', 'DateTime'), ('Duration', 'Duration'), ('DateFormula', 'DateFormula'),
    ('Guid', 'Guid'), ('RecordId', 'RecordId'), ('Variant', 'Variant'), ('TextBuilder', 'TextBuilder'),
    ('Interface', 'Interface "Y31 I"'),
]
FIELDS = [
    ('F.Integer', 'Integer'), ('F.BigInteger', 'BigInteger'), ('F.Decimal', 'Decimal'), ('F.Boolean', 'Boolean'),
    ('F.Option', 'Option'), ('F.Enum', 'Enum "Y31 E"'), ('F.Text10', 'Text[10]'), ('F.Code10', 'Code[10]'),
    ('F.Date', 'Date'), ('F.Time', 'Time'), ('F.DateTime', 'DateTime'), ('F.Duration', 'Duration'),
    ('F.DateFormula', 'DateFormula'), ('F.Guid', 'Guid'), ('F.RecordId', 'RecordId'), ('F.Media', 'Media'), ('F.MediaSet', 'MediaSet'),
]
LITERALS = [
    ('lit.Integer', '7'), ('lit.BigInteger', '10000000000L'), ('lit.Decimal', '1.5'), ('lit.Char1', "'a'"), ('lit.Text', "'abc'"),
    ('lit.TextEmpty', "''"), ('lit.Boolean', 'true'), ('lit.Date', '20260131D'), ('lit.Time', '120000T'), ('lit.DateTime', '0DT'),
    ('lit.Enum', '"Y31 E"::A'), ('lit.OptionMember', 'vOption::B'),
]
# sources that only make sense as sources
EXTRA_SOURCES = [('TestPage.Value', 'TP.FInt.Value'), ('MediaId', 'R.Media.MediaId()')]


def var_name(n):
    return 'v' + n


def fld_expr(n):
    return 'R."%s"' % n.split('.', 1)[1]


def sources():
    out = [(n, var_name(n)) for n, _ in VARS]
    out += [(n, fld_expr(n)) for n, _ in FIELDS]
    out += LITERALS
    out += EXTRA_SOURCES
    return out


def lvalue_targets():
    out = [(n, var_name(n), d) for n, d in VARS]
    out += [(n, fld_expr(n), d) for n, d in FIELDS]
    out.append(('TestPage.Value', 'TP.FInt.Value', None))
    return out


def type_targets():
    """targets that are a declarable parameter / return type (no Label, TextConst; fields map to their type)."""
    return [(n, var_name(n), d) for n, d in VARS if n not in ('Label', 'TextConst')]


def safe(n):
    return re.sub(r'[^A-Za-z0-9]', '_', n)


# context -> (kind, template). kind: 'lv' uses lvalue targets, 'ty' uses declarable types, 'ex' uses lvalue targets as an
# expression (comparison etc.). Template placeholders: {s} source expression, {t} target expression, {p} procedure suffix.
CONTEXTS = {
    'assign': ('lv', '{t} := {s};'),
    'compound_add': ('lv', '{t} += {s};'),
    'arg_byvalue': ('ty', 'PA_{p}({s});'),
    'arg_var': ('ty', 'PV_{p}({s});'),
    'exit': ('ty', None),
    'eq': ('ex', 'if {s} = {t} then;'),
    'ne': ('ex', 'if {s} <> {t} then;'),
    'lt': ('ex', 'if {s} < {t} then;'),
    'add': ('ex', "Message('%1', {s} + {t});"),
    'sub': ('ex', "Message('%1', {s} - {t});"),
    'in_set': ('ex', 'if {s} in [{t}] then;'),
    'case_label': ('ex', 'case {s} of {t}: ; end;'),
    'cond_branches': ('ex', "Message('%1', vBoolCond ? {s} : {t});"),
}

HEADER_OBJECTS = '''
interface "Y31 I"
{
    procedure Name(): Text;
}
enum 92400 "Y31 E"
{
    Extensible = true;
    value(0; A) { }
    value(1; B) { }
    value(2; C) { }
}
enum 92401 "Y31 E2"
{
    value(0; X) { }
    value(1; Y) { }
}
enum 92402 "Y31 EI" implements "Y31 I"
{
    value(0; A) { Implementation = "Y31 I" = "Y31 Impl"; }
}
codeunit 92402 "Y31 Impl" implements "Y31 I"
{
    procedure Name(): Text
    begin
        exit('impl');
    end;
}
table 92400 "Y31 Fields"
{
    fields
    {
        field(1; Integer; Integer) { }
        field(2; BigInteger; BigInteger) { }
        field(3; Decimal; Decimal) { }
        field(4; Boolean; Boolean) { }
        field(5; Option; Option) { OptionMembers = A,B,C; }
        field(6; Enum; Enum "Y31 E") { }
        field(7; Text10; Text[10]) { }
        field(8; Code10; Code[10]) { }
        field(9; Date; Date) { }
        field(10; Time; Time) { }
        field(11; DateTime; DateTime) { }
        field(12; Duration; Duration) { }
        field(13; DateFormula; DateFormula) { }
        field(14; Guid; Guid) { }
        field(15; RecordId; RecordId) { }
        field(16; Media; Media) { }
        field(17; MediaSet; MediaSet) { }
    }
    keys { key(PK; Integer) { } }
}
page 92400 "Y31 Card"
{
    PageType = Card;
    SourceTable = "Y31 Fields";
    layout
    {
        area(Content)
        {
            field(FInt; Rec.Integer) { ApplicationArea = All; }
        }
    }
}
'''


def build_context(ctx):
    kind, tmpl = CONTEXTS[ctx]
    lines = []
    cells = {}  # line number (1-based) -> (source, target)
    lines.append('codeunit 92401 "Y31 Matrix"')
    lines.append('{')
    lines.append('    Subtype = Test;')
    lines.append('    var')
    for n, d in VARS:
        lines.append('        %s: %s;' % (var_name(n), d))
    lines.append('        vBoolCond: Boolean;')
    lines.append('        R: Record "Y31 Fields";')
    lines.append('        TP: TestPage "Y31 Card";')
    targets = lvalue_targets() if kind in ('lv', 'ex') else type_targets()
    srcs = sources()
    if ctx == 'exit':
        k = 0
        for tn, _, td in targets:
            for sn, se in srcs:
                k += 1
                lines.append('    local procedure E%d(): %s begin exit(%s); end;' % (k, td, se))
                cells[len(lines)] = (sn, tn)
    else:
        lines.append('    procedure Cells()')
        lines.append('    begin')
        for tn, te, _ in targets:
            for sn, se in srcs:
                lines.append('        ' + tmpl.format(s=se, t=te, p=safe(tn)))
                cells[len(lines)] = (sn, tn)
        lines.append('    end;')
        if kind == 'ty':
            for tn, _, td in targets:
                lines.append('    local procedure PA_%s(p: %s) begin end;' % (safe(tn), td))
                lines.append('    local procedure PV_%s(var p: %s) begin end;' % (safe(tn), td))
    lines.append('}')
    return '\n'.join(lines) + '\n', cells


DIAG = re.compile(r'^(?P<file>[^()]*?)\((?P<line>\d+),(?P<col>\d+)\): (?P<sev>error|warning|info) (?P<code>AL\w+): (?P<msg>.*)$')


def compile_project(al, symbols, runtime, ctx, keep):
    src, cells = build_context(ctx)
    root = tempfile.mkdtemp(prefix='y31-' + ctx + '-', dir=keep) if keep else tempfile.mkdtemp(prefix='y31-')
    os.makedirs(os.path.join(root, 'src'))
    os.makedirs(os.path.join(root, '.alpackages'))
    shutil.copy(os.path.join(symbols, 'System.app'), os.path.join(root, '.alpackages', 'System.app'))
    with open(os.path.join(root, 'app.json'), 'w') as f:
        f.write('{"id":"11111111-2222-3333-4444-555555555555","name":"Y31 matrix","publisher":"Y31","version":"1.0.0.0",'
                '"platform":"27.0.0.0","runtime":"%s","target":"Cloud","idRanges":[{"from":92400,"to":92549}],"dependencies":[]}' % runtime)
    with open(os.path.join(root, 'src', 'objects.al'), 'w') as f:
        f.write(HEADER_OBJECTS)
    with open(os.path.join(root, 'src', 'matrix.al'), 'w') as f:
        f.write(src)
    cmd = al.split() + ['compile', '/project:' + root, '/packagecachepath:' + os.path.join(root, '.alpackages'),
                        '/out:' + os.path.join(root, 'out.app')]
    out = subprocess.run(cmd, capture_output=True, text=True).stdout
    per_line = {}
    stray = []
    for raw in out.splitlines():
        m = DIAG.match(raw.strip())
        if not m:
            continue
        if not m.group('file').replace('\\', '/').endswith('matrix.al'):
            stray.append(raw.strip())
            continue
        ln = int(m.group('line'))
        if ln in cells:
            per_line.setdefault(ln, []).append((m.group('sev'), m.group('code'), m.group('msg').strip()))
        else:
            stray.append(raw.strip())
    if not keep:
        shutil.rmtree(root, ignore_errors=True)
    return cells, per_line, stray


def cell_text(verdict, codes, wcodes):
    """ok, ok/AL0603 (accepted with a warning), AL0122, AL0122+AL0698 (several errors on the line)."""
    if verdict == 'ok':
        return 'ok/' + wcodes.replace(' ', '+') if wcodes else 'ok'
    return codes.replace(' ', '+')


def write_wide(path, rows):
    """one row per (context, source), one column per target; an empty cell is a target the context does not have."""
    targets = []
    for r in rows:
        if r[2] not in targets:
            targets.append(r[2])
    table = {}
    for ctx, sn, tn, verdict, codes, wcodes, _ in rows:
        table.setdefault((ctx, sn), {})[tn] = cell_text(verdict, codes, wcodes)
    with open(path, 'w', newline='') as f:
        w = csv.writer(f, lineterminator='\n')
        w.writerow(['context', 'source'] + targets)
        for (ctx, sn), cells in table.items():
            w.writerow([ctx, sn] + [cells.get(t, '') for t in targets])


def write_messages(path, rows):
    """the first three cells of every (context, diagnostic code), with the compiler's message."""
    seen = {}
    for ctx, sn, tn, verdict, codes, wcodes, msg in rows:
        for code in (codes or wcodes).split():
            seen.setdefault((ctx, code), [])
            if len(seen[(ctx, code)]) < 3:
                seen[(ctx, code)].append([ctx, code, sn, tn, msg])
    with open(path, 'w', newline='') as f:
        w = csv.writer(f, lineterminator='\n')
        w.writerow(['context', 'code', 'source', 'target', 'first_message_on_the_line'])
        for k in sorted(seen):
            w.writerows(seen[k])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--al', required=True)
    ap.add_argument('--symbols', required=True)
    ap.add_argument('--runtime', default='18.0')
    ap.add_argument('--out', default='compile-matrix.csv')
    ap.add_argument('--only', action='append')
    ap.add_argument('--keep')
    a = ap.parse_args()
    rows = []
    ok = True
    for ctx in CONTEXTS:
        if a.only and ctx not in a.only:
            continue
        cells, per_line, stray = compile_project(a.al, a.symbols, a.runtime, ctx, a.keep)
        if stray:
            ok = False
            print('%s: %d diagnostics outside the cells, first: %s' % (ctx, len(stray), stray[0]), file=sys.stderr)
        for ln in sorted(cells):
            sn, tn = cells[ln]
            diags = per_line.get(ln, [])
            errs = [d for d in diags if d[0] == 'error']
            warns = [d for d in diags if d[0] == 'warning']
            verdict = 'rejected' if errs else 'ok'
            codes = ' '.join(sorted({d[1] for d in errs}))
            wcodes = ' '.join(sorted({d[1] for d in warns}))
            msg = errs[0][2] if errs else (warns[0][2] if warns else '')
            rows.append([ctx, sn, tn, verdict, codes, wcodes, msg])
        print('%s: %d cells, %d rejected' % (ctx, len(cells), sum(1 for ln in cells if any(d[0] == 'error' for d in per_line.get(ln, [])))),
              file=sys.stderr)
    write_wide(a.out, rows)
    write_messages(os.path.join(os.path.dirname(os.path.abspath(a.out)), 'compile-messages.csv'), rows)
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())
