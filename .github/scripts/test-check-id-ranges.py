#!/usr/bin/env python3
"""Self-test of check-id-ranges.py: which range filters over the object ids of a metadata table it flags."""
import contextlib
import importlib.util
import io
import tempfile
from pathlib import Path

spec = importlib.util.spec_from_file_location('chk', Path(__file__).with_name('check-id-ranges.py'))
chk = importlib.util.module_from_spec(spec)
spec.loader.exec_module(chk)

failures = []


def check(name, ok, got=None):
    print('%s %s' % ('ok  ' if ok else 'FAIL', name))
    if not ok:
        failures.append(name)
        print('     got: %r' % (got,))


def codeunit(body, var='R: Record AllObj;'):
    return ('codeunit 50100 "Reader"\n{\n    Subtype = Test;\n\n    [Test]\n    procedure P()\n    var\n        %s\n'
            '    begin\n        %s\n    end;\n}\n' % (var, body))


with tempfile.TemporaryDirectory() as d:
    root = Path(d)
    app = root / 'tests' / 'main'
    app.mkdir(parents=True)
    (app / 'app.json').write_text('{"name": "Main", "idRanges": [{"from": 50000, "to": 50999}]}')
    (app / 'Tables.al').write_text('table 50001 "T One"\n{\n}\ntable 50002 "T Two"\n{\n}\npage 50001 "P One"\n{\n}\n'
                                   'page 50002 "P Two"\n{\n}\ncodeunit 50001 "C One"\n{\n}\ncodeunit 50009 "C Nine"\n{\n}\ntable 50005 "T Five"\n{\n}\ntable 50009 "T Nine"\n{\n}\n')
    objects = chk.repository(root)

    def flagged(text, path='tests/main/X.al'):
        return [m for _, m in chk.find(path, text, objects)]

    TT = 'R.SetRange("Object Type", R."Object Type"::Table); '
    TC = 'R.SetRange("Object Type", R."Object Type"::Codeunit); '
    NAMES = "R.SetFilter(\"Object Name\", '%%1|%%2|%%3|%%4', %s); "
    RNG = 'R.SetRange("Object ID", 50002, 50005);'
    NT = "R.SetFilter(\"Object Name\", '%1|%2', 'T One', 'T Nine'); "
    NTC = "R.SetFilter(\"Object Name\", '%1|%2|%3|%4', 'T One', 'T Nine', 'C One', 'C Nine'); "
    CNT = "Assert.AreEqual(1, R.Count(), ''); "

    cases = [
        ('AllObj, two literal bounds inside an idRange', codeunit('R.SetRange("Object ID", 50001, 50002);'), 1),
        ('AllObj, a range of tables that are all declared: AllObj holds every kind', codeunit(
            'R.SetRange("Object Type", R."Object Type"::Table); R.SetRange("Object ID", 50001, 50002);'), 1),
        ('Table Metadata, SetFilter with ..', codeunit("R.SetFilter(ID, '50003..50010');", 'R: Record "Table Metadata";'), 1),
        ('Table Metadata, SetFilter with >', codeunit("R.SetFilter(ID, '>%1', 50001);", 'R: Record "Table Metadata";'), 1),
        ('Table Metadata, SetFilter with a text that is no literal', codeunit('R.SetFilter(ID, F);', 'R: Record "Table Metadata";'), 1),
        ('Field, a TableNo range', codeunit('R.SetRange(TableNo, 50001, 50005);', 'R: Record Field;'), 1),
        ('two literal bounds outside every idRange', codeunit('R.SetRange("Object ID", 99999998, 99999999);'), 0),
        ('one bound outside, one inside', codeunit('R.SetRange("Object ID", 50999, 99999999);'), 1),
        ('the same bound twice', codeunit('R.SetRange(TableNo, Database::Customer, Database::Customer);', 'R: Record Field;'), 0),
        ('Table Metadata, every id of the range is a declared table',
         codeunit('R.SetRange(ID, 50001, 50002);', 'R: Record "Table Metadata";'), 0),
        ('Table Metadata, a free id inside the range', codeunit('R.SetRange(ID, 50001, 50003);', 'R: Record "Table Metadata";'), 1),
        ('Page Metadata, bounds by Page:: name, all pages declared',
         codeunit('R.SetRange(ID, Page::"P One", Page::"P Two");', 'R: Record "Page Metadata";'), 0),
        ('Page Metadata, a bound naming no declared object', codeunit('R.SetRange(ID, Page::"P One", Page::"P Nine");',
                                                                      'R: Record "Page Metadata";'), 1),
        ('Codeunit Metadata over a range of declared tables', codeunit('R.SetRange(ID, 50001, 50002);',
                                                                       'R: Record "CodeUnit Metadata";'), 1),
        ('a closed name list with a declared object below and one above the range', codeunit(
            TT + "R.SetFilter(\"Object Name\", '%1|%2|%3', 'T One', 'T Five', 'T Nine'); R.SetRange(\"Object ID\", 50002, 50005);"), 0),
        ('a closed name list whose names all lie inside the range', codeunit(
            "R.SetFilter(\"Object Name\", '%1|%2', 'T Two', 'T Five'); R.SetRange(\"Object ID\", 50002, 50005);"), 1),
        ('a closed name list with a name below the range only', codeunit(
            "R.SetFilter(\"Object Name\", '%1|%2', 'T One', 'T Five'); R.SetRange(\"Object ID\", 50002, 50005);"), 1),
        ('a closed name list of names no object has', codeunit(
            "R.SetFilter(\"Object Name\", '%1|%2', 'A', 'B'); R.SetRange(\"Object ID\", 50002, 50005);"), 1),
        ('a closed name list written in the filter text', codeunit(
            TT + "R.SetFilter(\"Object Name\", 'T One|T Nine'); R.SetRange(\"Object ID\", 50002, 50005);"), 0),
        ('a name filter with a wildcard', codeunit(
            "R.SetFilter(\"Object Name\", 'A*'); R.SetRange(\"Object ID\", 50001, 50005);"), 1),
        ('a single name by SetRange cannot lie on both sides', codeunit(
            "R.SetRange(\"Object Name\", 'T One'); R.SetRange(\"Object ID\", 50002, 50005);"), 1),
        ('a name filter on another variable', codeunit(
            "S.SetRange(\"Object Name\", 'A'); R.SetRange(\"Object ID\", 50001, 50005);", 'R: Record AllObj; S: Record AllObj;'), 1),
        ('the id field of a table that is no metadata table', codeunit('R.SetRange(Id, 1, 3);', 'R: Record "W3 Row";'), 0),
        ('a filter in a comment', codeunit('// R.SetRange("Object ID", 50001, 50005);'), 0),
        ('a single id', codeunit('R.SetRange("Object ID", 50001);'), 0),
        ('a list of ids', codeunit("R.SetFilter(\"Object ID\", '%1|%2', 50001, 50005);"), 0),
        ('Rec of a page on Page Metadata', 'page 50003 "L"\n{\n    SourceTable = "Page Metadata";\n\n'
                                           '    trigger OnOpenPage()\n    begin\n        Rec.SetRange(ID, 50001, 50009);\n'
                                           '    end;\n}\n', 1),
        ('AllObj, type Table, a table below and a codeunit above only', codeunit(
            TT + "R.SetFilter(\"Object Name\", '%1|%2', 'T One', 'C Nine'); " + RNG), 1),
        ('AllObj, type Table, a table below and a table above', codeunit(
            TT + "R.SetFilter(\"Object Name\", '%1|%2', 'T One', 'T Nine'); " + RNG), 0),
        ('AllObj, types Table and Codeunit, both listed on both sides', codeunit(
            TT + TC + NAMES % "'T One', 'T Nine', 'C One', 'C Nine'" + RNG), 0),
        ('AllObj, types Table and Codeunit, no codeunit above', codeunit(
            TT + TC + "R.SetFilter(\"Object Name\", '%1|%2|%3', 'T One', 'T Nine', 'C One'); " + RNG), 1),
        ('AllObj, no filter on the object type', codeunit(
            "R.SetFilter(\"Object Name\", '%1|%2', 'T One', 'T Nine'); " + RNG), 1),
        ('AllObj, an object type no literal names', codeunit(
            "R.SetRange(\"Object Type\", T); R.SetFilter(\"Object Name\", '%1|%2', 'T One', 'T Nine'); " + RNG), 1),
        ('a name filter cleared by SetRange before the range', codeunit(
            TT + "R.SetFilter(\"Object Name\", '%1|%2', 'T One', 'T Nine'); R.SetRange(\"Object Name\"); " + RNG), 1),
        ('a name filter cleared by SetFilter before the range', codeunit(
            TT + "R.SetFilter(\"Object Name\", '%1|%2', 'T One', 'T Nine'); R.SetFilter(\"Object Name\"); " + RNG), 1),
        ('a name filter cleared by Reset before the range', codeunit(
            "R.SetFilter(\"Object Name\", '%1|%2', 'T One', 'T Nine'); R.Reset(); " + TT + RNG), 1),
        ('a name filter set again after the clear', codeunit(
            TT + "R.SetFilter(\"Object Name\", 'A'); R.SetRange(\"Object Name\"); "
            "R.SetFilter(\"Object Name\", '%1|%2', 'T One', 'T Nine'); " + RNG), 0),
        ('a name filter cleared after the range', codeunit(
            TT + "R.SetFilter(\"Object Name\", '%1|%2', 'T One', 'T Nine'); " + RNG + ' R.SetRange("Object Name");'), 0),
        ('a name filter set after the range', codeunit(
            TT + RNG + " R.SetFilter(\"Object Name\", '%1|%2', 'T One', 'T Nine');"), 0),
        ('a Reset of another variable keeps the name filter', codeunit(
            TT + "R.SetFilter(\"Object Name\", '%1|%2', 'T One', 'T Nine'); S.Reset(); " + RNG,
            'R: Record AllObj; S: Record AllObj;'), 0),
        # a name filter that is not in force when the range is read (review of PR 1446, probes C1-C15)
        ('Reset without parentheses before the range', codeunit(NT + 'R.Reset; ' + TT + RNG + CNT), 1),
        ('Clear(R) before the range', codeunit(NT + 'Clear(R); ' + TT + RNG + CNT), 1),
        ("SetFilter(name, '') before the range", codeunit(TT + NT + "R.SetFilter(\"Object Name\", ''); " + RNG + CNT), 1),
        ('the list replaced by a wildcard filter', codeunit(TT + NT + "R.SetFilter(\"Object Name\", 'A*'); " + RNG + CNT), 1),
        ('the list replaced by a filter text that is no literal', codeunit(
            TT + NT + 'R.SetFilter("Object Name", F); ' + RNG + CNT), 1),
        ('the list replaced by a closed list inside the range', codeunit(
            TT + NT + "R.SetFilter(\"Object Name\", '%1|%2', 'T Two', 'T Five'); " + RNG + CNT), 1),
        ('the list replaced by SetRange(name, variable)', codeunit(TT + NT + 'R.SetRange("Object Name", N); ' + RNG + CNT), 1),
        ('CopyFilters before the range', codeunit(TT + NT + 'R.CopyFilters(S); ' + RNG + CNT, 'R: Record AllObj; S: Record AllObj;'), 1),
        ('Copy before the range', codeunit(TT + NT + 'R.Copy(S); ' + RNG + CNT, 'R: Record AllObj; S: Record AllObj;'), 1),
        ("SetView('') before the range", codeunit(TT + NT + "R.SetView(''); " + TT + RNG + CNT), 1),
        ('Reset() without a semicolon', codeunit(NT + 'if X then begin R.Reset() end; ' + TT + RNG + CNT), 1),
        ('the name filter cleared after the range, then a read', codeunit(TT + NT + RNG + 'R.SetRange("Object Name"); ' + CNT), 1),
        ('the name filter set after the read', codeunit(TT + RNG + CNT + NT), 1),
        ('the name filter set after the range, cleared, then a read', codeunit(
            TT + RNG + NT + 'R.SetRange("Object Name"); ' + CNT), 1),
        ('a second range after a Reset', codeunit(TT + NT + RNG + CNT + 'R.Reset(); ' + TT + RNG + CNT), 1),
        ('the name filter cleared after the range, then another id filter, then a read', codeunit(
            TT + NT + RNG + 'R.SetRange("Object Name"); R.SetRange("Object ID", 99999998, 99999999); ' + CNT), 0),
        ('the name filter cleared after the range, then Reset(), then a read', codeunit(
            TT + NT + RNG + 'R.SetRange("Object Name"); R.Reset(); ' + CNT), 0),
        ('a read between the name filter and the range', codeunit(TT + NT + CNT + RNG), 1),
        ('the type filter cleared by SetRange between the name filter and the range', codeunit(
            TT + NT + 'R.SetRange("Object Type"); ' + RNG + CNT), 1),
        # the object types the test asserts on (probes T1-T9, K1-K11)
        ("type filter '<>%1' Table", codeunit(
            "R.SetFilter(\"Object Type\", '<>%1', R.\"Object Type\"::Table); " + NT + RNG + CNT), 1),
        ('type range Table..Codeunit', codeunit(
            'R.SetRange("Object Type", R."Object Type"::Table, R."Object Type"::Codeunit); ' + NTC + RNG + CNT), 1),
        ("type filter '%1..%2'", codeunit("R.SetFilter(\"Object Type\", '%1..%2', R.\"Object Type\"::Table, "
                                          "R.\"Object Type\"::Codeunit); " + NTC + RNG + CNT), 1),
        ("type filter '%1|%2' with a variable", codeunit(
            "R.SetFilter(\"Object Type\", '%1|%2', R.\"Object Type\"::Table, T); " + NT + RNG + CNT), 1),
        ('type cleared after the range, read of every type', codeunit(
            TT + NT + RNG + CNT + 'R.SetRange("Object Type"); ' + CNT), 1),
        ('type as a number', codeunit('R.SetRange("Object Type", 1); ' + NT + RNG + CNT), 1),
        ('type on another variable only', codeunit(
            'S.SetRange("Object Type", S."Object Type"::Table); ' + NT + RNG + CNT, 'R: Record AllObj; S: Record AllObj;'), 1),
        ('type cleared before the names', codeunit(TT + 'R.SetRange("Object Type"); ' + NT + RNG + CNT), 1),
        ('type set only after the read', codeunit(NT + RNG + CNT + TT), 1),
        ('type TableData is no declared kind', codeunit(
            'R.SetRange("Object Type", R."Object Type"::TableData); ' + NT + RNG + CNT), 1),
        ('type Codeunit replaced by Table, tables listed', codeunit(TC + TT + NT + RNG + CNT), 0),
        ('type Codeunit, Reset, type Table, tables listed', codeunit(TC + 'R.Reset(); ' + TT + NT + RNG + CNT), 0),
        ('type Table, then Reset, then names: no type filter in force', codeunit(
            TT + 'R.Reset(); ' + NT + RNG + CNT), 1),
        ('AllObjWithCaption, type Table, tables on both sides', codeunit(TT + NT + RNG + CNT, 'R: Record AllObjWithCaption;'), 0),
        ('Table Metadata, name list, no type filter', codeunit(
            "R.SetFilter(Name, '%1|%2', 'T One', 'T Nine'); R.SetRange(ID, 50002, 50005);", 'R: Record "Table Metadata";'), 0),
        ("type filter '%1|%2' Table|Codeunit, both listed", codeunit(
            "R.SetFilter(\"Object Type\", '%1|%2', R.\"Object Type\"::Table, R.\"Object Type\"::Codeunit); "
            + NTC + RNG + CNT), 0),
        ('type by quoted enum value', codeunit('R.SetRange("Object Type", R."Object Type"::"Table"); ' + NT + RNG + CNT), 0),
        ('names, type Table, range, read, type Codeunit, read', codeunit(NTC + TT + RNG + CNT + TC + CNT), 0),
        ('Rec of a page on AllObj', 'page 50003 "L"\n{\n    SourceTable = AllObj;\n\n    trigger OnOpenPage()\n    begin\n'
                                   '        Rec.SetRange("Object Type", Rec."Object Type"::Table); Rec.SetFilter("Object Name", '
                                   "'%1|%2', 'T One', 'T Nine'); Rec.SetRange(\"Object ID\", 50002, 50005);\n    end;\n}\n", 0),
    ]
    for name, text, want in cases:
        got = flagged(text)
        check('%s: %s' % (name, 'flagged' if want else 'not flagged'), len(got) == want, got)

    two = ('codeunit 50100 "Reader"\n{\n    procedure A()\n    var\n        R: Record "W3 Row";\n    begin\n'
           '        R.SetRange(Id, 1, 3);\n    end;\n\n    procedure B()\n    var\n        R: Record AllObj;\n    begin\n'
           '        R.SetRange("Object ID", 50001, 50005);\n    end;\n}\n')
    got = chk.find('tests/main/X.al', two, objects)
    check('a local variable is read in its own procedure only', [line for line, _ in got] == [14], got)
    check('the message names the procedure', got and ' in B ' in got[0][1], got)

    key = 'tests/main/X.al P'
    chk.ALLOWED.add(key)
    try:
        check('a key in ALLOWED is not flagged', flagged(codeunit('R.SetRange("Object ID", 50001, 50005);')) == [])
        check('ALLOWED names the file', len(flagged(codeunit('R.SetRange("Object ID", 50001, 50005);'), 'tests/main/Y.al')) == 1)
    finally:
        chk.ALLOWED.discard(key)

    def run():
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            code = chk.main([str(root)])
        return code, buf.getvalue()
    check('main: exit 0 when nothing is flagged', run()[0] == 0, run())
    (app / 'Reader.al').write_text(codeunit('R.SetRange("Object ID", 50001, 50005);'))
    code, out = run()
    check('main: exit 1 and an error annotation with file and line', code == 1
          and '::error file=tests/main/Reader.al,line=10::' in out, out)

if failures:
    raise SystemExit('%d failed' % len(failures))
print('all passed')
