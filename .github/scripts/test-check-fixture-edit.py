#!/usr/bin/env python3
"""Self-test for check-fixture-edit.py: small git repos with one fixture edit each, then the 44 in-place edits of a
fixture .al file in this repository's history, each with its class written down by hand."""
import contextlib
import importlib.util
import io
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('check_fixture_edit', HERE / 'check-fixture-edit.py')
cf = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cf)

FX = 'tests/main/_fixtures/'
TAB = ('table 50001 "Fx Tab"\n{\n    DataClassification = SystemMetadata;\n\n    fields\n    {\n'
       '        field(1; "No."; Integer)\n        {\n            DataClassification = SystemMetadata;\n        }\n'
       '        field(2; Amount; Decimal)\n        {\n            FieldClass = FlowField;\n'
       '            CalcFormula = sum("Fx Tab"."No.");\n        }\n    }\n\n    keys\n    {\n'
       '        key(PK; "No.")\n        {\n            Clustered = true;\n        }\n    }\n\n'
       '    procedure A()\n    begin\n    end;\n}\n')
CLEANUP = ('codeunit 50002 ALTFixtureCleanup\n{\n    procedure Initialize()\n    var\n        FxTab: Record "Fx Tab";\n'
           '    begin\n        FxTab.DeleteAll(false);\n    end;\n}\n')
ENUM = ("enum 50003 \"Fx Status\"\n{\n    Extensible = true;\n\n    value(0; Open)\n    {\n        Caption = 'Open';\n    }\n"
        '    value(1; Closed)\n    {\n    }\n}\n')
IENUM = ('enum 50004 "Fx Impl" implements "Fx Iface"\n{\n    Extensible = true;\n    value(0; A)\n    {\n'
         '        Implementation = "Fx Iface" = "Fx Impl A";\n    }\n}\n')
PAGE = ('page 50005 "Fx List"\n{\n    PageType = List;\n    SourceTable = "Fx Tab";\n\n    layout\n    {\n'
        '        area(Content)\n        {\n            repeater(Lines)\n            {\n'
        '                field("No."; Rec."No.")\n                {\n                    ApplicationArea = All;\n'
        '                }\n            }\n        }\n    }\n\n    actions\n    {\n        area(Processing)\n        {\n'
        '            action(Go)\n            {\n                trigger OnAction()\n                begin\n'
        '                end;\n            }\n        }\n    }\n}\n')
CU = 'codeunit 50006 "Fx Helper"\n{\n    procedure One()\n    begin\n    end;\n\n    procedure Two()\n    begin\n    end;\n}\n'
REP = "report 50007 \"Fx Report\"\n{\n    UsageCategory = None;\n    ProcessingOnly = true;\n}\n"
SCOPED = 'namespace Fx.Scoped;\n\ncodeunit 50008 "Fx Scoped"\n{\n}\n'
BASE = {
    'tests/main/app.json': '{}',
    FX + 'Tab.al': TAB, FX + 'Cleanup.al': CLEANUP, FX + 'Enum.al': ENUM, FX + 'IEnum.al': IENUM, FX + 'Page.al': PAGE,
    FX + 'Cu.al': CU, FX + 'Rep.al': REP, FX + 'Scoped.al': SCOPED,
    'tests/main/T1.al': 'codeunit 50100 "T One"\n{\n    Subtype = Test;\n    [Test]\n    procedure A() begin end;\n}\n',
}

FIELD3 = '        field(3; Note; Text[50])\n        {\n            Caption = \'Note\';\n            DataClassification = SystemMetadata;\n        }\n'
LAST_FIELD = "            CalcFormula = sum(\"Fx Tab\".\"No.\");\n        }\n"
PROC = '    procedure Three()\n    var\n        X: Integer;\n    begin\n        case X of\n            1:\n                X := 2;\n        end;\n    end;\n'
CONTROL = '                field(Note; Rec."No.")\n                {\n                    ApplicationArea = All;\n                    Caption = \'Number\';\n                }\n'
AFTER_CONTROL = '                    ApplicationArea = All;\n                }\n'
ACTION = '            action(Stop)\n            {\n                ApplicationArea = All;\n            }\n'
AFTER_ACTION = '                end;\n            }\n'


def add_after(text, anchor, new, count=1):
    assert text.count(anchor) == count, (anchor, text.count(anchor))
    k = text.index(anchor) + len(anchor)
    return text[:k] + new + text[k:]


def table_file(cid, name):
    return 'table %d "%s"\n{\n    fields\n    {\n        field(1; "No."; Integer) { }\n    }\n}\n' % (cid, name)


CASES = [
    # (name, {path: text or None}, [(object substring, class)])
    ('table: a field with Caption and DataClassification', {FX + 'Tab.al': add_after(TAB, LAST_FIELD, FIELD3)},
     [('Fx Tab', 'additive')]),
    ('table: a field in the middle of the fields section', {FX + 'Tab.al': add_after(
        TAB, '            DataClassification = SystemMetadata;\n        }\n', FIELD3)}, [('Fx Tab', 'additive')]),
    ('table: a field with InitValue', {FX + 'Tab.al': add_after(TAB, LAST_FIELD, FIELD3.replace(
        "Caption = 'Note';", 'InitValue = 7;'))}, [('Fx Tab', 'other')]),
    ('table: a field with a trigger', {FX + 'Tab.al': add_after(TAB, LAST_FIELD, FIELD3.replace(
        "Caption = 'Note';", 'trigger OnValidate() begin end;'))}, [('Fx Tab', 'other')]),
    ('table: a FlowField', {FX + 'Tab.al': add_after(TAB, LAST_FIELD, FIELD3.replace(
        "Caption = 'Note';", 'FieldClass = FlowFilter;'))}, [('Fx Tab', 'other')]),
    ('table: a field number already used', {FX + 'Tab.al': add_after(TAB, LAST_FIELD, FIELD3.replace('field(3;', 'field(2;'))},
     [('Fx Tab', 'other')]),
    ('table: a key', {FX + 'Tab.al': add_after(TAB, '            Clustered = true;\n        }\n',
                                               '        key(K2; Amount) { }\n')}, [('Fx Tab', 'other')]),
    ('table: a changed property', {FX + 'Tab.al': TAB.replace('Clustered = true', 'Clustered = false')}, [('Fx Tab', 'other')]),
    ('table: a procedure at the end', {FX + 'Tab.al': add_after(TAB, '    end;\n', PROC)}, [('Fx Tab', 'additive')]),
    ('codeunit: two procedures at the end', {FX + 'Cu.al': add_after(CU, '    procedure Two()\n    begin\n    end;\n',
                                                                    PROC + PROC.replace('Three', 'Four'))},
     [('Fx Helper', 'additive')]),
    ('codeunit: a procedure in the middle', {FX + 'Cu.al': add_after(CU, '    procedure One()\n    begin\n    end;\n', PROC)},
     [('Fx Helper', 'other')]),
    ('codeunit: an event subscriber at the end', {FX + 'Cu.al': add_after(
        CU, '    procedure Two()\n    begin\n    end;\n',
        "    [EventSubscriber(ObjectType::Table, Database::\"Fx Tab\", 'OnAfterInsertEvent', '', false, false)]\n" + PROC)},
     [('Fx Helper', 'other')]),
    ('codeunit: a trigger at the end', {FX + 'Cu.al': add_after(CU, '    procedure Two()\n    begin\n    end;\n',
                                                               '    trigger OnRun()\n    begin\n    end;\n')},
     [('Fx Helper', 'other')]),
    ('codeunit: changed code in an existing procedure', {FX + 'Cu.al': CU.replace(
        '    procedure One()\n    begin\n', '    procedure One()\n    begin\n        Sleep(1);\n')}, [('Fx Helper', 'other')]),
    ('report: a procedure at the end', {FX + 'Rep.al': add_after(REP, 'ProcessingOnly = true;\n', PROC)},
     [('Fx Report', 'other')]),
    ('cleanup: a DeleteAll line for a table this diff adds', {
        FX + 'NewTab.al': table_file(50009, 'Fx New'),
        FX + 'Cleanup.al': CLEANUP.replace('        FxTab: Record "Fx Tab";\n',
                                           '        FxNew: Record "Fx New";\n        FxTab: Record "Fx Tab";\n')
        .replace('    begin\n', '    begin\n        FxNew.DeleteAll(false);\n')}, [('ALTFixtureCleanup', 'additive')]),
    ('cleanup: a DeleteAll line for a table new in an existing file', {
        FX + 'Rep.al': REP + table_file(50009, 'Fx New'),
        FX + 'Cleanup.al': CLEANUP.replace('    begin\n', '    begin\n        FxNew.DeleteAll();\n')
        .replace('        FxTab: Record "Fx Tab";\n', '        FxTab: Record "Fx Tab";\n        FxNew: Record "Fx New";\n')},
     [('ALTFixtureCleanup', 'additive')]),
    ('cleanup: a DeleteAll line for a table that already exists', {
        FX + 'Cleanup.al': CLEANUP.replace('        FxTab: Record "Fx Tab";\n',
                                           '        FxTab: Record "Fx Tab";\n        FxOld: Record "Fx Old";\n')
        .replace('    begin\n', '    begin\n        FxOld.DeleteAll(false);\n'),
    }, [('ALTFixtureCleanup', 'other')]),
    ('cleanup: another statement', {FX + 'NewTab.al': table_file(50009, 'Fx New'),
                                    FX + 'Cleanup.al': CLEANUP.replace('        FxTab: Record "Fx Tab";\n',
                                                                       '        FxNew: Record "Fx New";\n        FxTab: Record "Fx Tab";\n')
                                    .replace('    begin\n', '    begin\n        FxNew.ModifyAll("No.", 1);\n')},
     [('ALTFixtureCleanup', 'other')]),
    ('enum: a value after every value', {FX + 'Enum.al': add_after(ENUM, "    value(1; Closed)\n    {\n    }\n",
                                                                   "    value(2; Parked)\n    {\n        Caption = 'Parked';\n    }\n")},
     [('Fx Status', 'additive')]),
    ('enum: a value in the middle', {FX + 'Enum.al': add_after(ENUM, "        Caption = 'Open';\n    }\n",
                                                               '    value(5; Parked) { }\n')}, [('Fx Status', 'other')]),
    ('enum: an ordinal already used', {FX + 'Enum.al': add_after(ENUM, '    value(1; Closed)\n    {\n    }\n',
                                                                 '    value(1; Parked) { }\n')}, [('Fx Status', 'other')]),
    ('enum: a changed caption', {FX + 'Enum.al': ENUM.replace("Caption = 'Open'", "Caption = 'Opened'")},
     [('Fx Status', 'other')]),
    ('enum: a value of an enum that implements an interface', {FX + 'IEnum.al': add_after(
        IENUM, '        Implementation = "Fx Iface" = "Fx Impl A";\n    }\n', '    value(1; B) { }\n')}, [('Fx Impl', 'other')]),
    ('enumextension in a test file: a new value', {'tests/main/Ext.al': 'enumextension 50101 "Fx Ext" extends "Fx Status"\n'
                                                   "{\n    value(50101; Ext) { Caption = 'Ext'; }\n}\n"},
     [('Fx Ext', 'additive')]),
    ('enumextension in a test file: an ordinal the enum uses', {
        'tests/main/Ext.al': 'enumextension 50101 "Fx Ext" extends "Fx Status"\n{\n    value(1; Ext) { }\n}\n'},
     [('Fx Ext', 'other')]),
    ('enumextension of an enum that is no fixture: not checked', {
        'tests/main/Ext.al': 'enum 50102 Local { value(0; A) { } }\nenumextension 50101 "Fx Ext" extends Local\n'
                             '{\n    value(1; Ext) { InitValue = 1; }\n}\n'}, []),
    ('page: a field control at the end of the repeater', {FX + 'Page.al': add_after(PAGE, AFTER_CONTROL, CONTROL)},
     [('Fx List', 'additive')]),
    ('page: a field control with Visible', {FX + 'Page.al': add_after(PAGE, AFTER_CONTROL, CONTROL.replace(
        "Caption = 'Number';", 'Visible = false;'))}, [('Fx List', 'other')]),
    ('page: a field control on a FlowField', {FX + 'Page.al': add_after(PAGE, AFTER_CONTROL, CONTROL.replace(
        'Rec."No."', 'Rec.Amount'))}, [('Fx List', 'other')]),
    ('page: a field control before an existing one', {FX + 'Page.al': add_after(PAGE, '            repeater(Lines)\n            {\n',
                                                                                CONTROL)}, [('Fx List', 'other')]),
    ('page: a field control on a page of another PageType', {FX + 'Page.al': add_after(
        PAGE, AFTER_CONTROL, CONTROL).replace('PageType = List;', 'PageType = NavigatePage;')}, [('Fx List', 'other')]),
    ('page: a part', {FX + 'Page.al': add_after(PAGE, AFTER_CONTROL, '                part(P; "Fx List") { }\n')},
     [('Fx List', 'other')]),
    ('page: an action at the end of an area', {FX + 'Page.al': add_after(PAGE, AFTER_ACTION, ACTION)},
     [('Fx List', 'additive')]),
    ('page: an action before an existing one', {FX + 'Page.al': add_after(PAGE, '        area(Processing)\n        {\n', ACTION)},
     [('Fx List', 'other')]),
    ('fixture file deleted', {FX + 'Rep.al': None}, [('Fx Report', 'other')]),
    ('fixture object renamed', {FX + 'Rep.al': REP.replace('"Fx Report"', '"Fx Report 2"')}, [('Fx Report', 'other')]),
    ('fixture object moved to another file unchanged', {FX + 'Rep.al': None, FX + 'reports/Rep.al': REP}, []),
    ('namespace line changed', {FX + 'Scoped.al': SCOPED.replace('Fx.Scoped', 'Fx.Other')}, [('Fx Scoped', 'other')]),
    ('comments and blank lines only', {FX + 'Cu.al': '// a note\n' + CU.replace('    end;\n\n', '    end; // done\n\n\n')}, []),
    ('a new object in an existing fixture file', {FX + 'Cu.al': CU + 'codeunit 50010 "Fx More"\n{\n}\n'}, []),
    ('a test file outside the fixtures', {'tests/main/T1.al': BASE['tests/main/T1.al'].replace('begin end', 'begin Sleep(1); end')},
     []),
]

# The in-place edits of a fixture .al file in this repository's history (whole history up to 2026-11-18), one row per
# commit and file: the classes of the file's changed objects ("additive+other": one of each); "none": no existing
# object of the file changed.
HISTORY = [
    ('90ce2f033f97f5884392ca45ae7b0880627bbfea', 'ALTFixtureCleanup.al', 'additive'),
    ('2b9c57289cc129bf311e86d476eacbf7c1bb73bd', 'ALTFixtureCleanup.al', 'additive'),
    ('782c38892b58e991ae18b5cfd02c31767cdfc688', 'ALTFixtureCleanup.al', 'additive'),
    ('b8092fd0cf7d132d69fad00a8294554d5629946d', 'ALTFixtureCleanup.al', 'additive'),
    ('44b64f4799c94d6fa6ce1711610ce618e3b8bd60', 'ALTInstallProbe.al', 'none'),
    ('a1ffb8bda00bccca6d66162e007856679a5aa773', 'ProbeObserver.Codeunit.al', 'other'),
    ('53d0dad9a1a2319f68eb6f3fbf6ac71c982e729e', 'ProbeObserver.Codeunit.al', 'other'),
    ('ecda9b6b54abb59034c2a1afbb561e7cc7faedef', 'ProbeObserver.Codeunit.al', 'other'),
    ('05e3923c3c300a8d7fd20fd6a884e4b4e1b5005e', 'ProbeObserver.Codeunit.al', 'other'),
    ('ae3fe8857795946ddb12b4668627444d3f89681c', 'ProbeObserver.Codeunit.al', 'other'),
    ('8a6d965893e28a18bd9221453b45d628ba48bfa2', 'ProbeObserver.Codeunit.al', 'other'),
    ('31db82290e3e2830e56c95455001e796b09440e4', 'ProbeObserver.Codeunit.al', 'other'),
    ('345627d7d7fd6bdbb40b34c75d3f018fcb46b6cb', 'ProbeObserver.Codeunit.al', 'other'),
    ('66cc5d87695af545329ec254a4b70b1cb655fe8c', 'ProbeObserver.Codeunit.al', 'other'),
    ('9172f9358701cb820af5052e540a66cde9232d3c', 'ProbeObserver.Codeunit.al', 'other'),
    ('cd6668628f8936bf3bc9b864d6932051ef26af28', 'ALTFixtureCleanup.al', 'additive'),
    ('8694a724732a2d415186bcca08dd2460f82c8cc8', 'tables/ALTRelationWhereField.al', 'other'),
    ('fb543799caca8664623f68ee8116ad5e6040ba6d', 'ALTFixtureCleanup.al', 'additive'),
    ('fb543799caca8664623f68ee8116ad5e6040ba6d', 'ALTPermissionSet.permissionset.al', 'other'),
    ('b3c662a215784b256b34a8460788e747257d8ea7', 'pages/ALTListPage.al', 'other'),
    ('bebd7e98932ffb222bcf74a8970e15b006364ded', 'tables/ALTInitValue.al', 'other'),
    ('0a30b0070f335c6421aa394a200b0720922285cb', 'ALTFixtureCleanup.al', 'additive'),
    ('848831aa26a437241c31b84e99518efc1ae9c4ac', 'tables/ALTTriggeredOrder.TableExt.al', 'other'),
    ('ce4c13994f097ae0bb74f6f79a270ef368dcb8e9', 'ALTFixtureCleanup.al', 'additive'),
    ('0cdcafe29c82d1ab88d2132b347a7d84bf5d5aaa', 'ALTFixtureCleanup.al', 'additive'),
    ('643acf0c44a26a944ad395cb158141ae05df4718', 'pages/ALTListPage.al', 'other'),
    ('3ba5aa9a7b8fc112e77de928ee777093ed72d57e', 'ALTFixtureCleanup.al', 'additive'),
    ('3ba5aa9a7b8fc112e77de928ee777093ed72d57e', 'ALTPermissionSet.permissionset.al', 'other'),
    ('3ba5aa9a7b8fc112e77de928ee777093ed72d57e', 'tables/ALTRelationParentChild.al', 'additive+other'),
    ('efd822f5299d193cf770f45ceb5c2bc2eca8e16d', 'events/ALTEventPublisher.al', 'other'),
    ('d90ad032fedd0f6726760f45435e4d52eafd3d3a', 'ALTFixtureCleanup.al', 'additive'),
    ('d90ad032fedd0f6726760f45435e4d52eafd3d3a', 'ALTPermissionSet.permissionset.al', 'other'),
    ('484c96178faf0e1fcef397fb0b4e0b7ccf6bdaf2', 'xmlports/ALTParentChildXmlPort.al', 'other'),
    ('992c5911ecadace0c38bc6ee86fa4947d251f87e', 'events/ALTTableEventSubscriber.al', 'other'),
    ('bf8c260f47c417051c76702d851c76f0bbcbb65c', 'tables/ALTTriggered.al', 'additive+other'),
    ('bd45f84249be7a869d38ff16dbd09873ebf74964', 'ALTFixtureCleanup.al', 'other'),
    ('63dfb53c29f65d99b4f9b92d7a8890845cf34a68', 'ALTPermissionSet.permissionset.al', 'other'),
    ('d65d3ae8ef0cd48fc6a110d85e02961c9fdc0526', 'ALTFixtureCleanup.al', 'additive'),
    ('d65d3ae8ef0cd48fc6a110d85e02961c9fdc0526', 'ALTPermissionSet.permissionset.al', 'other'),
    ('e8eb0758277055ef458485b39773b66fb9fb2492', 'ALTFixtureCleanup.al', 'additive'),
    ('e8eb0758277055ef458485b39773b66fb9fb2492', 'ALTPermissionSet.permissionset.al', 'other'),
    ('7f8008e017b6e6f2bd33f76c582895938abe2731', 'reports/ALTSimpleReport.al', 'other'),
    ('7f8008e017b6e6f2bd33f76c582895938abe2731', 'tables/ALTBase.al', 'additive+other'),
    ('7f8008e017b6e6f2bd33f76c582895938abe2731', 'tables/ALTTriggered.al', 'other'),
]


FAILED = []
ROOT = tempfile.mkdtemp(prefix='check-fixture-edit-')


def check(name, cond, detail=''):
    print('%s %s%s' % ('ok  ' if cond else 'FAIL', name, '' if cond else ': %s' % detail))
    if not cond:
        FAILED.append(name)


def git(repo, *a):
    return subprocess.run(['git', '-C', str(repo), '-c', 'user.name=t', '-c', 'user.email=t@t', '-c', 'commit.gpgsign=false']
                          + list(a), check=True, capture_output=True, text=True).stdout.strip()


def make(changes):
    repo = tempfile.mkdtemp(prefix='repo-', dir=ROOT)
    git(repo, 'init', '-q', '-b', 'main')
    base_files = dict(BASE)
    base_files[FX + 'Old.al'] = table_file(50011, 'Fx Old')
    for p, t in base_files.items():
        f = Path(repo, p)
        f.parent.mkdir(parents=True, exist_ok=True)
        f.write_text(t)
    git(repo, 'add', '-A')
    git(repo, 'commit', '-q', '-m', 'base')
    base = git(repo, 'rev-parse', 'HEAD')
    for p, t in changes.items():
        f = Path(repo, p)
        if t is None:
            f.unlink()
        else:
            f.parent.mkdir(parents=True, exist_ok=True)
            f.write_text(t)
    git(repo, 'add', '-A')
    git(repo, 'commit', '-q', '--allow-empty', '-m', 'change')
    return repo, base


def synthetic():
    for name, changes, want in CASES:
        repo, base = make(changes)
        got = cf.classify(cf.st.Git(repo), base, 'HEAD')
        ok = len(got) == len(want) and all(w[0] in g['object'] and g['class'] == w[1] for g, w in zip(got, want))
        check(name, ok, got)
    repo, base = make(CASES[0][1])
    with contextlib.redirect_stdout(io.StringIO()):
        code = cf.main(['--repo', repo, '--base', base])
    check('exit 0 when every edit is additive', code == 0, code)
    repo, base = make(CASES[2][1])
    with contextlib.redirect_stdout(io.StringIO()):
        code = cf.main(['--repo', repo, '--base', base])
    check('exit 1 when an edit is "other"', code == 1, code)
    with contextlib.redirect_stdout(io.StringIO()):
        code = cf.main(['--repo', repo, '--base', 'no-such-rev'])
    check('exit 2 when the check fails', code == 2, code)


def history():
    repo = HERE.parent.parent
    shas = sorted({c for c, _, _ in HISTORY})
    missing = [c for c in shas if subprocess.run(['git', '-C', str(repo), 'cat-file', '-e', c + '^^{commit}'],
                                                 capture_output=True).returncode != 0]
    if missing:  # a shallow CI checkout: fetch each commit with its parent
        subprocess.run(['git', '-C', str(repo), 'fetch', '--no-tags', '--quiet', '--depth=2', 'origin'] + missing,
                       check=True, capture_output=True)
    for c, path, want in HISTORY:
        got = [r for r in cf.classify(cf.st.Git(str(repo)), c + '^', c) if r['path'] == 'tests/al-language/_fixtures/' + path]
        classes = '+'.join(sorted({r['class'] for r in got})) or 'none'
        check('history %s %s: %s' % (c[:8], path, want), classes == want, got)


def main():
    synthetic()
    history()
    if FAILED:
        print('%d failed: %s' % (len(FAILED), ', '.join(FAILED)))
        return 1
    print('all passed')
    return 0


if __name__ == '__main__':
    try:
        code = main()
    finally:
        shutil.rmtree(ROOT, ignore_errors=True)
    sys.exit(code)
