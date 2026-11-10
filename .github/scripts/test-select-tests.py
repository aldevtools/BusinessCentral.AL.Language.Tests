#!/usr/bin/env python3
"""Self-test for select-tests.py: builds small git repos and checks which test codeunits it selects and when it falls
back to a full run. Also checks that the real ci.yml wires every test job to the selection."""
import contextlib
import importlib.util
import io
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('select_tests', HERE / 'select-tests.py')
st = importlib.util.module_from_spec(spec)
spec.loader.exec_module(st)

CI = """name: t
on: [pull_request]
jobs:
  prepare:
    runs-on: ubuntu-latest
  test:
    name: BC ${{ matrix.bc_version }}
    uses: x/y/.github/workflows/bc-test-from-source.yml@master
    with:
      app_dirs:             "tests/fixture"
      test_app_dirs:        "tests/main"
      codeunit_range:       ${{ fromJson(needs.prepare.outputs.subset)['tests/main'] || '50000..50099|50200..50299' }}
  test-onprem:
    name: BC OnPrem ${{ matrix.bc_version }}
    uses: x/y/.github/workflows/bc-test-from-source.yml@master
    with:
      app_dirs: |
        tests/fixture
        tests/main
      test_app_dirs:        "tests/onprem"
      codeunit_range:       ${{ fromJson(needs.prepare.outputs.subset)['tests/onprem'] || '60000..60099' }}
"""

def fake_app(names):
    """A symbol package: the 40-byte NAVX header, then a zip with SymbolReference.json."""
    import io
    import zipfile
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, 'w') as z:
        z.writestr('SymbolReference.json', json.dumps({'Namespaces': [{'Tables': [{'Id': 18, 'Name': n} for n in names]}]}))
    return b'NAVX' + b' ' * 36 + buf.getvalue()


BASE_FILES = {
    '.github/workflows/ci.yml': CI,
    'README.md': '# corpus\n',
    'tests/fixture/app.json': '{}',
    'tests/fixture/Fix.al': 'codeunit 70000 "Fix Helper"\n{\n}\n',
    'tests/main/app.json': json.dumps({'resourceFolders': ['res']}),
    'tests/main/.alpackages/Base Application.app': fake_app(['Some Microsoft Table']),
    'tests/main/res/a.txt': 'hello',
    'tests/main/Assert.al': 'codeunit 50000 Assert\n{\n    procedure IsTrue(b: Boolean) begin end;\n}\n',
    'tests/main/Probe.Table.al': 'table 50001 "Probe Rec"\n{\n    fields { field(1; "No."; Integer) { } }\n}\n',
    'tests/main/Helper.al': ('codeunit 50002 "Probe Helper"\n{\n    procedure Make()\n    var R: Record "Probe Rec";\n'
                             '    begin R.Insert(); end;\n}\n'),
    'tests/main/T1.al': ('codeunit 50010 "Uses Table"\n{\n    Subtype = Test;\n    [Test]\n    procedure A()\n'
                         '    var R: Record "Probe Rec";\n    begin end;\n}\n'),
    'tests/main/T2.al': ('codeunit 50011 "Uses Helper"\n{\n    Subtype = Test;\n    [Test]\n    procedure A()\n'
                         '    var H: Codeunit "Probe Helper";\n    begin H.Make(); end;\n}\n'),
    'tests/main/T3.al': ('// mentions [EventSubscriber( only in a comment; "Probe Rec" too\n'
                         'codeunit 50012 Unrelated\n{\n    Subtype = Test;\n    [Test]\n    procedure A()\n    begin\n'
                         "        Message('{ not a brace }');\n    end;\n    [Test]\n    procedure B() begin end;\n}\n"),
    'tests/main/NoTests.al': 'codeunit 50013 "Fixture Only"\n{\n    Subtype = Test;\n    var R: Record "Probe Rec";\n}\n',
    'tests/main/OutOfRange.al': ('codeunit 50150 "Out Of Range"\n{\n    Subtype = Test;\n    [Test]\n    procedure A()\n'
                                 '    var R: Record "Probe Rec";\n    begin end;\n}\n'),
    'tests/main/Cust.al': ('codeunit 50014 "Uses Customer"\n{\n    Subtype = Test;\n    [Test]\n    procedure A()\n'
                           '    var C: Record Customer;\n    begin end;\n}\n'),
    'tests/main/CustExt.al': ('namespace Corpus.Ext;\nusing Microsoft.Sales.Customer;\n'
                              'tableextension 50003 "Cust Ext" extends Microsoft.Sales.Customer.Customer\n{\n}\n'),
    'tests/main/Rep.al': ("report 50004 \"Probe Report\"\n{\n    RDLCLayout = 'Layout.rdlc';\n}\n"
                          'codeunit 50015 "Runs Report"\n{\n    Subtype = Test;\n    [Test]\n    procedure A()\n'
                          '    begin Report.Run(Report::"Probe Report"); end;\n}\n'),
    'tests/main/Layout.rdlc': '<Report/>',
    'tests/main/Orphan.al': 'codeunit 50005 "Nobody Calls Me"\n{\n}\n',
    'tests/onprem/app.json': '{}',
    'tests/onprem/O1.al': ('codeunit 60010 "OnPrem Uses Table"\n{\n    Subtype = Test;\n    [Test]\n    procedure A()\n'
                           '    var R: Record "Probe Rec";\n    begin end;\n}\n'),
    'tests/onprem/O2.al': 'codeunit 60011 "OnPrem Other"\n{\n    Subtype = Test;\n    [Test]\n    procedure A() begin end;\n}\n',
}


def git(repo, *a):
    return subprocess.run(['git', '-C', repo, '-c', 'user.name=t', '-c', 'user.email=t@t', '-c', 'commit.gpgsign=false']
                          + list(a), check=True, capture_output=True, text=True).stdout.strip()


def make(changes, base_files=None):
    """A repo with BASE_FILES committed, then `changes` ({path: text or None to delete}) committed on top."""
    repo = tempfile.mkdtemp(prefix='repo-', dir=ROOT)
    git(repo, 'init', '-q', '-b', 'main')
    for p, t in (base_files or BASE_FILES).items():
        f = Path(repo, p)
        f.parent.mkdir(parents=True, exist_ok=True)
        f.write_bytes(t) if isinstance(t, bytes) else f.write_text(t)
    git(repo, 'add', '-A')
    git(repo, 'commit', '-q', '-m', 'base')
    base = git(repo, 'rev-parse', 'HEAD')
    for p, t in changes.items():
        f = Path(repo, p)
        if t is None:
            f.unlink()
        else:
            f.parent.mkdir(parents=True, exist_ok=True)
            f.write_bytes(t) if isinstance(t, bytes) else f.write_text(t)
    git(repo, 'add', '-A')
    git(repo, 'commit', '-q', '--allow-empty', '-m', 'change')
    return st.select(st.Git(repo), base, 'HEAD')


def ids(result, app):
    return [c['id'] for c in result['apps'][app]['codeunits'] if not c.get('sentinel')]


def sentinels(result, app):
    return [c['id'] for c in result['apps'][app]['codeunits'] if c.get('sentinel')]


def subscriber(cid, publisher, event='OnAfterInsertEvent', props='', body='', name=None):
    return ('codeunit %d "%s"\n{\n%s    [EventSubscriber(ObjectType::%s, \'%s\', \'\', false, false)]\n'
            '    local procedure X() begin %s end;\n}\n') % (cid, name or 'Subs %d' % cid, props, publisher, event, body)


def binder(cid, sub_name):
    return ('codeunit %d "Binds %d"\n{\n    Subtype = Test;\n    [Test]\n    procedure A()\n    var S: Codeunit "%s";\n'
            '    begin BindSubscription(S); end;\n}\n') % (cid, cid, sub_name)


def subscribers():
    """[EventSubscriber]: a subscriber runs in the tests that can raise its publisher's event, unless that is any test."""
    own = 'Table, Database::"Probe Rec"'
    r = make({'tests/main/Subs.al': subscriber(50020, own)})
    check('subscriber to a table of the test apps: the tests that use the table', r['mode'] == 'subset'
          and ids(r, 'tests/main') == [50010, 50011] and ids(r, 'tests/onprem') == [60010], r.get('reasons') or r['apps'])
    r = make({'tests/main/Subs.al': subscriber(50020, 'Codeunit, Codeunit::"Probe Helper"', 'OnMake')})
    check('subscriber to a codeunit of the test apps: the tests that use the codeunit', r['mode'] == 'subset'
          and ids(r, 'tests/main') == [50011], r.get('reasons') or r['apps'])
    r = make({'tests/main/Subs.al': subscriber(50020, 'Table, 50001')})
    check('publisher named by id', r['mode'] == 'subset' and ids(r, 'tests/main') == [50010, 50011], r.get('reasons') or r['apps'])

    manual = dict(BASE_FILES)
    manual['tests/main/Man.al'] = subscriber(50024, 'Codeunit, Codeunit::"Caption Class"', 'OnResolveCaptionClass',
                                             '    EventSubscriberInstance = Manual;\n', name='Man Sub')
    manual['tests/main/Binder.al'] = binder(50025, 'Man Sub')
    r = make({'tests/main/Man.al': manual['tests/main/Man.al'].replace('begin  end', 'begin Message(\'x\'); end')}, manual)
    check('manual subscriber, even to a platform publisher: the tests that bind it', r['mode'] == 'subset'
          and ids(r, 'tests/main') == [50025], r.get('reasons') or r['apps'])
    single = manual['tests/main/Man.al'].replace('Manual;\n', 'Manual;\n    SingleInstance = true;\n')
    r = make({'tests/main/Man.al': single}, manual)
    check('manual SingleInstance subscriber stays bound into later codeunits: like an automatic one (full run here)',
          r['mode'] == 'full' and any('not an object of the test apps' in x for x in r['reasons']), r['reasons'])

    fulls = {
        'subscriber to a Base Application table': (subscriber(50020, 'Table, Database::Customer'), 'not an object of the test apps'),
        'subscriber to Global Triggers': (subscriber(50020, 'Codeunit, Codeunit::"Global Triggers"', 'GetGlobalTableTriggerMask'),
                                          'install, upgrade or every session'),
        'subscriber to an install event': (subscriber(50020, 'Codeunit, Codeunit::"Probe Helper"', 'OnInstallAppPerCompany'),
                                           'install, upgrade or every session'),
        'subscriber whose publisher cannot be read': (subscriber(50020, 'Table, Some.Expression()'), 'cannot read'),
        'subscriber to an object that does not exist': (subscriber(50020, 'Table, Database::"No Such Table"'),
                                                        'not an object of the test apps'),
    }
    for name, (text, needle) in fulls.items():
        r = make({'tests/main/Subs.al': text})
        check('full run: %s' % name, r['mode'] == 'full' and any(needle in x for x in r['reasons']), r['reasons'])

    saved = st.MAX_PUBLISHER_USERS
    st.MAX_PUBLISHER_USERS = 1
    try:
        r = make({'tests/main/Subs.al': subscriber(50020, own)})
    finally:
        st.MAX_PUBLISHER_USERS = saved
    check('full run: subscriber to a publisher used by more than MAX_PUBLISHER_USERS test codeunits', r['mode'] == 'full'
          and any('test codeunits use (more than 1)' in x for x in r['reasons']), r['reasons'])

    named = dict(BASE_FILES)
    named['tests/main/.alpackages/Base Application.app'] = fake_app(['Probe Rec'])
    r = make({'tests/main/Subs.al': subscriber(50020, own)}, named)
    check('full run: a Microsoft object has the publisher\'s name too', r['mode'] == 'full'
          and any('a Microsoft object has that name too' in x for x in r['reasons']), r['reasons'])
    nopkg = {p: t for p, t in BASE_FILES.items() if '/.alpackages/' not in p}
    r = make({'tests/main/Subs.al': subscriber(50020, own)}, nopkg)
    check('full run: no symbol packages in the tree', r['mode'] == 'full'
          and any('no Microsoft symbol packages in the tree' in x for x in r['reasons']), r['reasons'])
    named['tests/main/.alpackages/Base Application.app'] = 'not a package'
    r = make({'tests/main/Subs.al': subscriber(50020, own)}, named)
    check('full run: symbol packages that cannot be read', r['mode'] == 'full'
          and any('could not be read' in x for x in r['reasons']), r['reasons'])

    # an existing subscriber that may run any time: whatever it uses counts as used by every test
    global_sub = dict(BASE_FILES)
    global_sub['tests/main/GSub.al'] = subscriber(50026, 'Table, Database::Customer', body='Helper.Make();',
                                                  name='Cust Sub').replace('local procedure X()', 'local procedure X()\n    var Helper: Codeunit "Probe Helper";')
    r = make({'tests/main/Helper.al': BASE_FILES['tests/main/Helper.al'].replace('R.Insert();', 'R.Insert(true);')}, global_sub)
    check('full run: a changed object that an existing subscriber to a Base Application table uses', r['mode'] == 'full'
          and any('it can run codeunit 50026' in x for x in r['reasons']), r['reasons'])
    r = make(touch('tests/main/Helper.al'), global_sub)
    check('... but not when only a comment changed', r['mode'] == 'subset' and ids(r, 'tests/main') == [50011],
          r.get('reasons') or r['apps'])

    # an event chain: test -> table -> subscriber -> changed codeunit
    chain = dict(BASE_FILES)
    chain['tests/main/Chain.al'] = subscriber(50027, own, body='Helper2.Go();', name='Chain Sub').replace(
        'local procedure X()', 'local procedure X()\n    var Helper2: Codeunit "Chain Helper";')
    chain['tests/main/ChainHelper.al'] = 'codeunit 50028 "Chain Helper"\n{\n    procedure Go() begin end;\n}\n'
    r = make({'tests/main/ChainHelper.al': chain['tests/main/ChainHelper.al'].replace('begin end', 'begin Message(\'x\'); end')},
             chain)
    check('changed codeunit that only a subscriber calls: the tests that raise the subscriber\'s event', r['mode'] == 'subset'
          and ids(r, 'tests/main') == [50010, 50011] and ids(r, 'tests/onprem') == [60010], r.get('reasons') or r['apps'])

    # only the objects that changed count, not every object of a changed file
    mixed = dict(BASE_FILES)
    mixed['tests/main/Mixed.al'] = (subscriber(50029, 'Table, Database::Customer', name='Mixed Sub')
                                    + 'table 50030 "Mixed Row"\n{\n    fields { field(1; "No."; Integer) { } }\n}\n'
                                    + 'codeunit 50031 "Uses Mixed"\n{\n    Subtype = Test;\n    [Test]\n    procedure A()\n'
                                      '    var R: Record "Mixed Row";\n    begin end;\n}\n')
    grown = mixed['tests/main/Mixed.al'].replace('field(1; "No."; Integer) { }', 'field(1; "No."; Integer) { } field(2; Two; Integer) { }')
    r = make({'tests/main/Mixed.al': grown}, mixed)
    check('unchanged subscriber in a changed file: no full run', r['mode'] == 'subset' and ids(r, 'tests/main') == [50031],
          r.get('reasons') or r['apps'])
    r = make({'tests/main/Mixed.al': mixed['tests/main/Mixed.al'] + '// a comment\n'}, mixed)
    check('comment added to a file with a subscriber: no full run', r['mode'] == 'subset' and ids(r, 'tests/main') == [50031],
             r.get('reasons') or r['apps'])
    r = make({'tests/main/Mixed.al': 'using Some.Namespace;\n' + grown}, mixed)
    check('full run: using added to a file with a subscriber (every object of the file counts as changed)',
          r['mode'] == 'full' and any('codeunit 50029' in x for x in r['reasons']), r['reasons'])
    r = make({'tests/main/Mixed.al': grown.replace('Database::Customer', 'Database::"Mixed Row"')}, mixed)
    check('full run: subscriber moved off a Base Application table (it ran in any test before)', r['mode'] == 'full'
          and any('before this change' in x for x in r['reasons']), r['reasons'])
    r = make({'tests/main/Mixed.al': None, 'tests/main/T1.al': BASE_FILES['tests/main/T1.al'] + '\n'}, mixed)
    check('full run: subscriber to a Base Application table removed', r['mode'] == 'full'
          and any('before this change' in x for x in r['reasons']), r['reasons'])
    gone = dict(BASE_FILES)
    gone['tests/main/Subs.al'] = subscriber(50020, own)
    r = make({'tests/main/Subs.al': None}, gone)
    check('subscriber to a table of the test apps removed: the tests that use the table', r['mode'] == 'subset'
          and ids(r, 'tests/main') == [50010, 50011], r.get('reasons') or r['apps'])

    # an object's own id is not a reference: table 50036 and codeunit 50036 are different objects
    same_id = dict(BASE_FILES)
    same_id['tests/main/CollRow.al'] = 'table 50036 "Coll Row"\n{\n    fields { field(1; "No."; Integer) { } }\n}\n'
    same_id['tests/main/CollHelper.al'] = 'codeunit 50036 "Coll Helper"\n{\n    procedure A() begin end;\n}\n'
    same_id['tests/main/UsesRow.al'] = ('codeunit 50037 "Uses Coll Row"\n{\n    Subtype = Test;\n    [Test]\n    procedure A()\n'
                                        '    var R: Record "Coll Row";\n    begin end;\n}\n')
    same_id['tests/main/UsesHelper.al'] = ('codeunit 50038 "Uses Coll Helper"\n{\n    Subtype = Test;\n    [Test]\n'
                                           '    procedure A()\n    var H: Codeunit "Coll Helper";\n    begin H.A(); end;\n}\n')
    r = make({'tests/main/CollHelper.al': same_id['tests/main/CollHelper.al'].replace('begin end', "begin Message('x'); end")},
             same_id)
    check("an object's own id in its header is not a reference to another kind's object with that id",
          r['mode'] == 'subset' and ids(r, 'tests/main') == [50038], r.get('reasons') or r['apps'])


def given_cases():
    """--codeunits / select_codeunits: a selection given as input (the corpus CI batcher's union of the selections of
    the branches it merged) is used as it is; no diff is read."""
    repo = tempfile.mkdtemp(prefix='repo-', dir=ROOT)
    git(repo, 'init', '-q', '-b', 'main')
    for p, t in BASE_FILES.items():
        f = Path(repo, p)
        f.parent.mkdir(parents=True, exist_ok=True)
        f.write_bytes(t) if isinstance(t, bytes) else f.write_text(t)
    git(repo, 'add', '-A')
    git(repo, 'commit', '-q', '-m', 'base')
    g = st.Git(repo)

    r = st.given(g, 'HEAD', '{"tests/main":"50010,50011..50012"}')
    check('given: ids and ranges are used as they are; no diff is read', r['mode'] == 'subset' and r.get('given')
          and ids(r, 'tests/main') == [50010, 50011, 50012] and r['changed_files'] == [], r)
    check('given: an app the input leaves out runs only its sentinel', r['apps']['tests/onprem'].get('sentinel')
          and ids(r, 'tests/onprem') == [] and sentinels(r, 'tests/onprem') == [60011], r['apps'].get('tests/onprem'))
    check('given: the sentinel is added when the input lacks it', sentinels(r, 'tests/main') == [50014], r['apps']['tests/main'])
    check('given: subset output lists every id (a range is expanded)',
          st.subset_output(r) == {'tests/main': '50010,50011,50012,50014', 'tests/onprem': '60011'}, st.subset_output(r))

    r = st.given(g, 'HEAD', '{"tests/main":"50010..50015|50150|50999", "tests/onprem":"60010"}')
    check('given: a range keeps only runnable test codeunits of the job range (no [Test] fixture, nothing out of range)',
          r['mode'] == 'subset' and ids(r, 'tests/main') == [50010, 50011, 50012, 50014, 50015]
          and ids(r, 'tests/onprem') == [60010] and sentinels(r, 'tests/onprem') == [60011], r)
    check('given: listed ids that are no runnable test codeunit are reported', r['apps']['tests/main'].get('dropped') == [50150, 50999],
          r['apps']['tests/main'])
    check('given: the summary says the selection was given', 'select_codeunits' in st.summary(r), st.summary(r))

    for name, text, needle in (
            ('not JSON', '50010,50011', 'not valid'),
            ('not an object', '["tests/main"]', 'not valid'),
            ('empty object', '{}', 'not valid'),
            ('bad id', '{"tests/main":"50010,abc"}', 'not valid'),
            ('reversed range', '{"tests/main":"50012..50010"}', 'not valid'),
            ('unknown app', '{"tests/main":"50010","tests/nope":"1"}', 'tests/nope')):
        r = st.given(g, 'HEAD', text)
        check('given: full run when the input is %s' % name, r['mode'] == 'full' and any(needle in x for x in r['reasons']),
              r['reasons'])

    out, summ = Path(ROOT, 'given-out.txt'), Path(ROOT, 'given-summary.md')
    old = dict(os.environ)
    os.environ.update(GITHUB_OUTPUT=str(out), GITHUB_STEP_SUMMARY=str(summ))
    try:
        with contextlib.redirect_stdout(io.StringIO()):
            st.main(['--repo', repo, '--codeunits', '{"tests/main":"50011"}', '--github'])
    finally:
        os.environ.clear()
        os.environ.update(old)
    check('given: --codeunits --github writes the job output subset',
          out.read_text().strip() == 'subset=' + json.dumps({'tests/main': '50011,50014', 'tests/onprem': '60011'},
                                                            separators=(',', ':')), out.read_text())

    # the real ci.yml hands the dispatch input to the script unchanged, through the environment (not inlined in the shell)
    real = (HERE.parent / 'workflows' / 'ci.yml').read_text()
    check('real ci.yml: workflow_dispatch input select_codeunits', '      select_codeunits:\n' in real, 'input missing')
    check('real ci.yml: the prepare job passes select_codeunits to --codeunits',
          'SELECT_CODEUNITS: ${{ github.event.inputs.select_codeunits }}' in real and '--codeunits "$SELECT_CODEUNITS"' in real,
          'prepare job does not use the input')


FAILED = []
ROOT = tempfile.mkdtemp(prefix='select-tests-')


def check(name, cond, detail=''):
    print('%s %s%s' % ('ok  ' if cond else 'FAIL', name, '' if cond else ': %s' % detail))
    if not cond:
        FAILED.append(name)


def touch(path):
    return {path: BASE_FILES[path] + '\n// changed\n'}


def main():
    r = make(touch('tests/main/T1.al'))
    check('changed test codeunit runs alone', r['mode'] == 'subset' and ids(r, 'tests/main') == [50010], r)
    check('app with nothing selected runs only its sentinel', r['apps']['tests/onprem'].get('sentinel')
          and ids(r, 'tests/onprem') == [] and sentinels(r, 'tests/onprem') == [60011], r['apps'].get('tests/onprem'))
    check('every app also runs one sentinel: the smallest codeunit with one test and no #if',
          sentinels(r, 'tests/main') == [50014], r['apps']['tests/main'])
    check('subset output is {app: "ids"}', st.subset_output(r) == {'tests/main': '50010,50014', 'tests/onprem': '60011'},
          st.subset_output(r))

    with_if = dict(BASE_FILES)
    with_if['tests/main/Tiny.al'] = '#if BC29PLUS\ncodeunit 50016 Tiny\n{\n    Subtype = Test;\n    [Test]\n    procedure A() begin end;\n}\n#endif\n'
    r = make(touch('tests/main/T1.al'), with_if)
    check('a codeunit in #if is never the sentinel', sentinels(r, 'tests/main') == [50014], r['apps']['tests/main'])

    comment_only = dict(BASE_FILES)
    comment_only['tests/main/Notes.al'] = '// placeholder, no object yet\n'
    r = make({'tests/main/Notes.al': '// placeholder, still no object\n', 'tests/main/T1.al': BASE_FILES['tests/main/T1.al'] + '\n'},
             comment_only)
    check('a file with only comments selects nothing and is no reason for a full run', r['mode'] == 'subset'
          and ids(r, 'tests/main') == [50010], r['reasons'])

    r = make(touch('tests/main/Probe.Table.al'))
    check('changed table: users, users through a helper, other apps; not out of range, not without [Test], '
          'not a mention in a comment', r['mode'] == 'subset' and ids(r, 'tests/main') == [50010, 50011]
          and ids(r, 'tests/onprem') == [60010], r)

    r = make(touch('tests/main/CustExt.al'))
    check('table extension: tests that use the extended table', r['mode'] == 'subset'
          and ids(r, 'tests/main') == [50014], r)

    r = make(touch('tests/main/Layout.rdlc'))
    check('layout file: tests that use the report that names it', r['mode'] == 'subset'
          and ids(r, 'tests/main') == [50015], r)

    r = make({'tests/main/Orphan.al': None, 'tests/main/T1.al': BASE_FILES['tests/main/T1.al'] + '\n'})
    check('removed object does not force a full run', r['mode'] == 'subset' and ids(r, 'tests/main') == [50010], r)

    r = make({'tests/main/T3.al': BASE_FILES['tests/main/T3.al'] + '\n'})
    check('[EventSubscriber( in a comment is not a subscriber', r['mode'] == 'subset', r['reasons'])

    subscribers()
    given_cases()

    fulls = {
        'install codeunit': ({'tests/main/I.al': 'codeunit 50021 Inst\n{\n    Subtype = Install;\n}\n'}, 'Subtype = Install'),
        'permission set': ({'tests/main/P.al': 'permissionset 50022 "PS"\n{\n}\n'}, 'permissionset'),
        'app.json': ({'tests/main/app.json': '{"x": 1}'}, 'manifest'),
        'resource': ({'tests/main/res/a.txt': 'changed'}, 'resource'),
        'CI file': ({'.github/scripts/x.py': 'print(1)'}, 'CI configuration'),
        'dependency app': (touch('tests/fixture/Fix.al'), 'dependency app'),
        'unknown file outside the apps': ({'tools/x.sh': 'echo'}, 'outside the test apps'),
        'docs only': ({'README.md': '# changed\n', 'docs/a.md': 'x'}, 'no changed file in the test apps'),
        'empty diff': ({}, 'no changed files'),
        'orphan object': (touch('tests/main/Orphan.al'), 'effect is unknown'),
        'more than MAX_FILES': ({'tests/main/gen/T%d.al' % i: 'codeunit %d "G%d"\n{\n}\n' % (50100 + i, i)
                                 for i in range(st.MAX_FILES + 1)}, 'more than'),
    }
    r = make(dict(touch('tests/main/T1.al'), **{'.github/nightly-windows/run.ps1': 'x',
                                                '.github/workflows/nightly-windows.yml': 'on: push'}))
    check('nightly-windows files are ignored', r['mode'] == 'subset' and ids(r, 'tests/main') == [50010]
          and sorted(r['ignored_files']) == ['.github/nightly-windows/run.ps1', '.github/workflows/nightly-windows.yml'], r)
    for name, (changes, needle) in fulls.items():
        r = make(changes)
        check('full run: %s' % name, r['mode'] == 'full' and any(needle in x for x in r['reasons']), r['reasons'])
    with_upgrade = dict(BASE_FILES)
    with_upgrade['tests/main/U.al'] = 'codeunit 50023 Upg\n{\n    Subtype = Upgrade;\n}\n'
    r = make({'tests/main/U.al': None}, with_upgrade)
    check('full run: upgrade codeunit removed', r['mode'] == 'full'
          and any('Subtype = Upgrade' in x for x in r['reasons']), r['reasons'])

    # a job whose codeunit_range is a plain string keeps its full range and is listed as such
    plain = dict(BASE_FILES)
    plain['.github/workflows/ci.yml'] = CI.replace(
        "${{ fromJson(needs.prepare.outputs.subset)['tests/onprem'] || '60000..60099' }}", '"60000..60099"')
    r = make(touch('tests/main/T1.al'), plain)
    check('unwired job runs its full range', r['mode'] == 'subset' and 'tests/onprem' not in r['apps']
          and r['unwired_jobs'] == ['test-onprem'], r)

    # a ci.yml change that only edits codeunit_range values (a "CI range edit") is selected as usual, not a full run
    wider = CI.replace("'50000..50099|50200..50299'", "'50000..50099|50200..50299|50300..50399'")
    r = make(dict(touch('tests/main/T1.al'), **{'.github/workflows/ci.yml': wider}))
    check('CI range edit: selected as usual', r['mode'] == 'subset' and ids(r, 'tests/main') == [50010]
          and r.get('ci_range_edit') == ['.github/workflows/ci.yml'], r)
    into_range = CI.replace("'50000..50099|50200..50299'", "'50000..50199|50200..50299'")
    r = make(dict(touch('tests/main/T1.al'), **{'.github/workflows/ci.yml': into_range}))
    check('CI range edit: a test codeunit the edit brings into the range runs too', r['mode'] == 'subset'
          and ids(r, 'tests/main') == [50010, 50150], r)
    r = make({'.github/workflows/ci.yml': wider})
    check('CI range edit alone: full run (nothing in the test apps changed)', r['mode'] == 'full'
          and any('no changed file in the test apps' in x for x in r['reasons']), r['reasons'])
    more = wider.replace('  test-onprem:\n', '  # a comment\n  test-onprem:\n')
    r = make(dict(touch('tests/main/T1.al'), **{'.github/workflows/ci.yml': more}))
    check('ci.yml edit beyond codeunit_range lines: full run', r['mode'] == 'full'
          and any('CI configuration' in x for x in r['reasons']), r['reasons'])
    rewired = CI.replace("['tests/onprem'] || '60000..60099'", "['tests/main'] || '60000..60099'")
    r = make(dict(touch('tests/main/T1.al'), **{'.github/workflows/ci.yml': rewired}))
    check('codeunit_range edit that changes the subset key: full run', r['mode'] == 'full'
          and any('CI configuration' in x for x in r['reasons']), r['reasons'])
    other_key = CI.replace('      test_app_dirs:        "tests/onprem"', '      test_app_dirs:        "tests/other"')
    r = make(dict(touch('tests/main/T1.al'), **{'.github/workflows/ci.yml': other_key}))
    check('ci.yml edit of another with: key: full run', r['mode'] == 'full'
          and any('CI configuration' in x for x in r['reasons']), r['reasons'])

    # the parser: several objects per file, braces in strings, quoted and namespaced names
    objs = st.parse_al('x.al', BASE_FILES['tests/main/Rep.al'] + BASE_FILES['tests/main/CustExt.al'])
    check('parse_al reads every object', [(o.kind, o.id, o.name, o.target) for o in objs] == [
        ('report', '50004', 'probe report', None), ('codeunit', '50015', 'runs report', None),
        ('tableextension', '50003', 'cust ext', 'customer')], [(o.kind, o.id, o.name, o.target) for o in objs])
    stray = st.parse_al('s.al', '#if NEVER\nreport 98103, test codeunit 98104\n\nreport 98103 "Save Report"\n{\n}\n'
                                'codeunit 98105 "Impl" implements "Some Iface", Other\n{\n}\n#endif\n')
    check('parse_al takes the declaration right before the brace', [(o.kind, o.id, o.name) for o in stray] == [
        ('report', '98103', 'save report'), ('codeunit', '98105', 'impl')], [(o.kind, o.id, o.name) for o in stray])
    t3 = st.parse_al('t3.al', BASE_FILES['tests/main/T3.al'])
    check('comments are not tokens, strings are', len(t3) == 1 and 'probe rec' not in t3[0].tokens
          and '{ not a brace }' in t3[0].tokens and t3[0].tests == 2, [(o.name, sorted(o.tokens)) for o in t3])

    subs = st.parse_al('s.al', subscriber(1, 'Codeunit, Codeunit::Microsoft.Foo."Gen. Jnl.-Post"', 'OnX')
                       + subscriber(2, 'Table, 18', 'x').replace("'x'", 'OnAfterInsertEvent')
                       + subscriber(3, 'Table, Rec.TableNo()'))
    check('parse_al reads subscriptions: dotted quoted names, ids, unreadable ones',
          [o.subscriptions for o in subs] == [[('codeunit', 'gen. jnl.-post', 'onx')], [('table', '18', 'onafterinsertevent')],
                                               [None]], [o.subscriptions for o in subs])

    # a branch cut from an older base: only what the branch changed counts (merge base, three dots), not what the base
    # branch changed after the branch left it; also from a shallow clone that lacks the merge base
    repo = tempfile.mkdtemp(prefix='repo-', dir=ROOT)
    git(repo, 'init', '-q', '-b', 'main')
    for p_, t in BASE_FILES.items():
        f = Path(repo, p_)
        f.parent.mkdir(parents=True, exist_ok=True)
        f.write_bytes(t) if isinstance(t, bytes) else f.write_text(t)
    git(repo, 'add', '-A')
    git(repo, 'commit', '-q', '-m', 'base')
    git(repo, 'checkout', '-q', '-b', 'topic')
    Path(repo, 'tests/onprem/O2.al').write_text(BASE_FILES['tests/onprem/O2.al'].replace('begin end', 'begin Sleep(1); end'))
    git(repo, 'commit', '-q', '-am', 'topic change')
    git(repo, 'checkout', '-q', 'main')
    Path(repo, 'tests/main/Probe.Table.al').write_text(BASE_FILES['tests/main/Probe.Table.al'].replace('Integer', 'Code[20]'))
    git(repo, 'commit', '-q', '-am', 'base moved on')
    r = st.select(st.Git(repo), 'main', 'topic')
    check('branch behind its base: only the branch change is selected', r['mode'] == 'subset'
          and ids(r, 'tests/onprem') == [60011] and ids(r, 'tests/main') == [], r)
    clone = tempfile.mkdtemp(prefix='clone-', dir=ROOT)
    git(clone, 'init', '-q')
    git(clone, 'remote', 'add', 'origin', 'file://' + repo)
    git(clone, 'fetch', '-q', '--depth=1', 'origin', 'topic:refs/remotes/origin/topic', 'main:refs/remotes/origin/main')
    r = st.select(st.Git(clone), 'origin/main', 'origin/topic')
    check('shallow clone: the merge base is fetched, only the branch change is selected', r['mode'] == 'subset'
          and ids(r, 'tests/onprem') == [60011] and ids(r, 'tests/main') == [], r)

    # the real ci.yml: every job that runs BC tests reads the selection under its own test app dir
    real = st.parse_ci((HERE.parent / 'workflows' / 'ci.yml').read_text())
    check('real ci.yml has test jobs', len(real) >= 3, real)
    for j in real:
        check('real ci.yml job %s reads the selection for its test app' % j['job'],
              j['key'] is not None and j['test_app_dirs'] == [j['key']] and st.spans(j['range']), j)
    # test-testlibraries (the job that installs Tests-TestLibraries and Data Archive) keeps its own id block as full range
    tl = [j for j in real if j['job'] == 'test-testlibraries']
    check('real ci.yml job test-testlibraries runs 81550..81649 in full', len(tl) == 1
          and tl[0]['key'] == 'tests/al-language-testlibraries' and st.spans(tl[0]['range']) == [(81550, 81649)], tl)

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
