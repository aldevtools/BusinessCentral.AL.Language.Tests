#!/usr/bin/env python3
"""Self-test of facts.py on a small corpus in a temporary git repository: extract, then diff a base and a head that moved,
removed and merged tests. A move keeps every fact; a removal is a lost case until a rename-map line covers it; a rename to a
test without the fact is a lost fact."""
import importlib.util, os, subprocess, tempfile
from pathlib import Path

spec = importlib.util.spec_from_file_location('facts', Path(__file__).with_name('facts.py'))
facts = importlib.util.module_from_spec(spec)
spec.loader.exec_module(facts)

failures = []


def expect(cond, what):
    if not cond:
        failures.append(what)


CU = '''codeunit 50100 "T Format"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure Format_Zero()
    begin
        Assert.AreEqual('0', Format(0), 'zero'); // a comment: Assert.AreEqual('x', y, '')
    end;

    [Test]
    procedure Format_Zero_Integer()
    var
        i: Integer;
    begin
        Assert.AreEqual('0', Format(i), 'zero integer');
    end;

#if BC29PLUS
    [Test]
    procedure Through_Helper()
    begin
        CheckIt();
    end;
#endif

    [Test]
    procedure Runs_Only()
    begin
        Format(1);
    end;

    local procedure CheckIt()
    begin
        asserterror Error('boom');
        Assert.ExpectedError('boom');
    end;
}
'''
MNC = '// @expect AL0118 | The name \'X\' does not exist\n// @from 28\n\ncodeunit 50000 "MNC X" { }\n'


def repo(d, files):
    for rel, text in files.items():
        p = Path(d) / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text)
    subprocess.run(['git', 'init', '-q', d], check=True)
    subprocess.run(['git', '-C', d, 'add', '-A'], check=True)


def run_diff(base, head, ren=None, chg=None):
    # in GitHub Actions the report lines start with ::error::; compare the report itself
    lines = []
    rc = facts.diff(base, head, ren, chg, out=lines.append)
    return rc, [l[len('::error::'):] if l.startswith('::error::') else l for l in lines]


with tempfile.TemporaryDirectory() as t:
    t = Path(t)
    base_dir, head_dir = str(t / 'base'), str(t / 'head')
    repo(base_dir, {'tests/al-language/types/TFormat.al': CU, 'tests/must-not-compile/cases/0001-x.al': MNC})
    base = str(t / 'base.tsv')
    facts.extract(base_dir, base)
    rows = [l.split('\t') for l in Path(base).read_text().splitlines()[1:]]
    keys = {r[0] for r in rows}
    expect(keys == {'al-language/50100/Format_Zero', 'al-language/50100/Format_Zero_Integer', 'al-language/50100/Through_Helper',
                    'al-language/50100/Runs_Only', 'mnc/0001-x'}, 'keys: %r' % keys)
    by = {(r[0], r[2]): r for r in rows}
    expect(by[('al-language/50100/Format_Zero', 'eq')][3:5] == ["'0'", 'format'], 'eq fact: %r' % by.get(('al-language/50100/Format_Zero', 'eq')))
    expect(sum(1 for r in rows if r[0] == 'al-language/50100/Format_Zero') == 1, 'a commented-out assert is not a fact')
    expect(by.get(('al-language/50100/Through_Helper', 'error'), [''] * 6)[3:6] == ["'boom'", '', 'BC29PLUS'], 'helper facts are followed; the #if context is that of the test procedure')
    expect(('al-language/50100/Runs_Only', 'runs') in by, 'a test without an assertion pins "runs"')
    expect(by.get(('mnc/0001-x', 'mnc'), [''] * 6)[3:5] == ["AL0118 | The name 'X' does not exist", '@from 28'], 'mnc fact: %r' % by.get(('mnc/0001-x', 'mnc')))

    rc, out = run_diff(base, base)
    expect(rc == 0, 'base against itself: %r' % out)

    # a move to another folder and a local variable rename keep every fact
    repo(head_dir, {'tests/al-language/format-evaluate/zero/TFormat.al': CU.replace('i: Integer', 'n: Integer').replace('Format(i)', 'Format(n)'),
                    'tests/must-not-compile/cases/0001-x.al': MNC})
    head = str(t / 'head.tsv')
    facts.extract(head_dir, head)
    rc, out = run_diff(base, head)
    expect(rc == 0, 'move: %r' % out)

    # removing Format_Zero is a lost case
    removed = CU.replace('''    [Test]
    procedure Format_Zero()
    begin
        Assert.AreEqual('0', Format(0), 'zero'); // a comment: Assert.AreEqual('x', y, '')
    end;
''', '')
    Path(head_dir, 'tests/al-language/format-evaluate/zero/TFormat.al').write_text(removed)
    facts.extract(head_dir, head)
    rc, out = run_diff(base, head)
    expect(rc == 1 and any(l.startswith('LOST CASE  al-language/50100/Format_Zero ') for l in out), 'removal is a lost case: %r' % out)

    # a rename-map line to a test that holds the same fact clears it
    ren = t / 'rename-map.tsv'
    ren.write_text('# old_key<TAB>new_key\nold_key\tnew_key\nal-language/50100/Format_Zero\tal-language/50100/Format_Zero_Integer\n')
    rc, out = run_diff(base, head, str(ren))
    expect(rc == 0, 'rename map covers the removal: %r' % out)

    # a rename to a test without the fact is a lost fact
    ren.write_text('old_key\tnew_key\nal-language/50100/Format_Zero\tal-language/50100/Runs_Only\n')
    rc, out = run_diff(base, head, str(ren))
    expect(rc == 1 and any(l.startswith('LOST FACT  al-language/50100/Format_Zero ') for l in out), 'rename without the fact: %r' % out)

    # a rename to a key that does not exist is reported
    ren.write_text('al-language/50100/Format_Zero\tal-language/50100/Nope\n')
    rc, out = run_diff(base, head, str(ren))
    expect(rc == 1 and any(l.startswith('BAD RENAME') for l in out), 'rename to a missing key: %r' % out)

    # an edited expected value is a lost fact; a removed must-not-compile case is a lost case
    Path(head_dir, 'tests/al-language/format-evaluate/zero/TFormat.al').write_text(CU.replace("AreEqual('0', Format(i)", "AreEqual('1', Format(i)"))
    os.remove(Path(head_dir, 'tests/must-not-compile/cases/0001-x.al'))
    subprocess.run(['git', '-C', head_dir, 'add', '-A'], check=True)
    facts.extract(head_dir, head)
    rc, out = run_diff(base, head)
    expect(rc == 1 and any(l.startswith('LOST FACT  al-language/50100/Format_Zero_Integer ') for l in out)
           and any(l.startswith('LOST CASE  mnc/0001-x ') for l in out), 'edited value and removed mnc case: %r' % out)

    # an intended expected-value change passes with a facts-changes line (old fact -> new fact) for that test
    Path(head_dir, 'tests/must-not-compile/cases/0001-x.al').write_text(MNC)
    subprocess.run(['git', '-C', head_dir, 'add', '-A'], check=True)
    facts.extract(head_dir, head)
    chg = t / 'facts-changes.tsv'
    row = lambda new_value, reason='real BC returns 1': '\t'.join(['al-language/50100/Format_Zero_Integer', 'eq', "'0'", 'format', '',
                                                                  'eq', new_value, 'format', '', reason]) + '\n'
    chg.write_text('# comment\n' + facts.CHANGES_HEADER + '\n' + row("'1'"))
    rc, out = run_diff(base, head, None, str(chg))
    expect(rc == 0, 'facts-changes line covers the edited value: %r' % out)
    # the new fact must be held at head
    chg.write_text(row("'2'"))
    rc, out = run_diff(base, head, None, str(chg))
    expect(rc == 1 and any(l.startswith('LOST FACT  al-language/50100/Format_Zero_Integer ') for l in out), 'new fact not at head: %r' % out)
    # a line without a reason is refused
    chg.write_text(row("'1'", ''))
    try:
        run_diff(base, head, None, str(chg))
        expect(False, 'a facts-changes line without a reason is refused')
    except SystemExit:
        pass
    # the lost-fact report prints the start of the line to add
    rc, out = run_diff(base, head)
    expect(any(l.startswith("facts-changes line: al-language/50100/Format_Zero_Integer\teq\t'0'\tformat\t\t") for l in out), 'template line: %r' % out)

    # the repository's own rename map and facts-changes file parse
    expect(isinstance(facts.load_changes(str(Path(__file__).resolve().parents[2] / 'tests' / 'facts-changes.tsv')), dict), 'tests/facts-changes.tsv parses')
    # the repository's own rename map parses
    expect(isinstance(facts.load_map(str(Path(__file__).resolve().parents[2] / 'tests' / 'rename-map.tsv')), dict), 'tests/rename-map.tsv parses')

if failures:
    for f in failures:
        print('FAIL', f)
    raise SystemExit(1)
print('self-test OK')
