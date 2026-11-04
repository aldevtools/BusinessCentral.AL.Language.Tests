#!/usr/bin/env python3
import importlib.util, sys, tempfile
from pathlib import Path

spec = importlib.util.spec_from_file_location('chk', Path(__file__).with_name('check-install-triggers.py'))
chk = importlib.util.module_from_spec(spec)
spec.loader.exec_module(chk)

with tempfile.TemporaryDirectory() as d:
    root = Path(d).resolve()
    app = root / 'tests' / 'app1'
    (app / 'area').mkdir(parents=True)
    (app / 'app.json').write_text('{}')
    (app / 'a.al').write_text('codeunit 1 "A"\n{\n    Subtype = Install;\n}\n')
    (app / 'b.al').write_text('codeunit 2 "B"\n{\n    Subtype = Test;\n}\n')
    (app / 'area' / 'c.al').write_text('table 9 "T" { }\ncodeunit 3 "C"\n{\n    subtype = upgrade;\n}\n')
    keys = lambda bad: [k for _, k in bad]
    assert keys(chk.find(root, set())) == ['tests/app1 codeunit 1', 'tests/app1 codeunit 3'], chk.find(root, set())
    assert keys(chk.find(root, {'tests/app1 codeunit 1'})) == ['tests/app1 codeunit 3']
    # the key names the object: moving the file inside its app keeps it allowed
    (app / 'a.al').rename(app / 'area' / 'moved.al')
    assert keys(chk.find(root, {'tests/app1 codeunit 1', 'tests/app1 codeunit 3'})) == []
    # a second install codeunit in an allowed file needs its own key
    (app / 'area' / 'moved.al').write_text('codeunit 1 "A"\n{\n    Subtype = Install;\n}\ncodeunit 4 "D"\n{\n    Subtype = Install;\n}\n')
    assert keys(chk.find(root, {'tests/app1 codeunit 1', 'tests/app1 codeunit 3'})) == ['tests/app1 codeunit 4']
    # the same id in another app is another object
    other = root / 'tests' / 'app2'
    other.mkdir()
    (other / 'app.json').write_text('{}')
    (other / 'e.al').write_text('codeunit 1 "E"\n{\n    Subtype = Install;\n}\n')
    assert 'tests/app2 codeunit 1' in keys(chk.find(root, {'tests/app1 codeunit 1'}))
    # a Subtype line without a codeunit header above it is reported, never skipped
    (other / 'e.al').write_text('    Subtype = Install;\n')
    assert (('tests/app2/e.al', None)) in chk.find(root, set())
print('self-test OK')
