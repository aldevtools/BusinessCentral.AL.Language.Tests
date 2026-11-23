#!/usr/bin/env python3
"""Self-test for ci-legs.py: the legs and the preprocessor symbols derived from the list of released minors (the table
of al-runtime-rs ADR-078, point 3), and the real list file."""
import importlib.util
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('ci_legs', HERE / 'ci-legs.py')
cl = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cl)

FAILED = []


def check(name, cond, detail=''):
    print('%s %s%s' % ('ok  ' if cond else 'FAIL', name, '' if cond else ': %s' % (detail,)))
    if not cond:
        FAILED.append(name)


def raises(fn):
    try:
        fn()
    except SystemExit as e:
        return str(e)
    return None


LIST = cl.released('# comment\n27.0\n27.1\n27.2\n27.3\n27.4\n27.5\n28.0\n28.1\n28.2\n28.3\n28.4\n28.5\n29.0\n29.1  # newest\n')
B27 = ['BC27PLUS', 'BC27_1PLUS', 'BC27_2PLUS', 'BC27_3PLUS', 'BC27_4PLUS', 'BC27_5PLUS']
B28 = ['BC28PLUS', 'BC28_1PLUS', 'BC28_2PLUS', 'BC28_3PLUS', 'BC28_4PLUS', 'BC28_5PLUS']

check('released: comments and blanks are skipped, version order', LIST[0] == (27, 0) and LIST[-1] == (29, 1) and len(LIST) == 14)
check('released: unordered input comes out ordered', cl.released('29.0\n27.5\n') == [(27, 5), (29, 0)])
check('released: a duplicate is an error', 'twice' in (raises(lambda: cl.released('27.5\n27.5\n')) or ''))
check('released: an empty list is an error', 'no released minor' in (raises(lambda: cl.released('# none\n')) or ''))
check('released: a bad line is an error', 'not a BC version' in (raises(lambda: cl.released('27.5.1\n')) or ''))
check('parse: a major before 27 is an error', 'before 27.0' in (raises(lambda: cl.parse('26.5')) or ''))

# the table of ADR-078, point 3
for v, want in (((27, 0), ['BC27PLUS']),
                ((27, 5), B27),
                ((29, 0), B27 + B28 + ['BC29PLUS']),
                ((29, 1), B27 + B28 + ['BC29PLUS', 'BC29_1PLUS']),
                ((29, 2), B27 + B28 + ['BC29PLUS', 'BC29_1PLUS', 'BC29_2PLUS']),
                ((30, 0), B27 + B28 + ['BC29PLUS', 'BC29_1PLUS', 'BC30PLUS'])):
    got = cl.symbols(v, LIST)
    check('symbols of %s' % cl.name(v), got == want, got)
check('symbols: no _0 form', not any('_0PLUS' in s for s in cl.symbols((29, 1), LIST)))
check('symbols: a later minor of an older major (28.6) reaches 29.0 and 30.0',
      'BC28_6PLUS' in cl.symbols((29, 0), LIST + [(28, 6)]) and 'BC28_6PLUS' in cl.symbols((30, 0), LIST + [(28, 6)])
      and 'BC28_6PLUS' not in cl.symbols((28, 5), LIST + [(28, 6)]))

m = cl.matrix(LIST)['include']
check('matrix: one leg per major, the newest minor', [e['bc_version'] for e in m] == ['27.5', '28.5', '29.1'], m)
check('matrix: leg is the major, runtime per major', [(e['leg'], e['runtime']) for e in m]
      == [('27', '16.1'), ('28', '17.1'), ('29', '18.0')], m)
check('matrix: symbols comma-separated', m[2]['preprocessor_symbols'] == ','.join(cl.symbols((29, 1), LIST)), m[2])
one = cl.matrix(LIST, '28.2')['include']
check('matrix --version: that version alone', [e['bc_version'] for e in one] == ['28.2']
      and one[0]['preprocessor_symbols'] == ','.join(B27 + ['BC28PLUS', 'BC28_1PLUS', 'BC28_2PLUS']), one)

full = cl.matrix(LIST, '28.5.54151.58194')['include']
check('matrix --version: a full build keeps the build, symbols of its minor', full[0]['bc_version'] == '28.5.54151.58194'
      and full[0]['preprocessor_symbols'] == ','.join(B27 + B28) and full[0]['leg'] == '28', full)
check('matrix --version: a bad version is an error', 'not a BC version' in (raises(lambda: cl.matrix(LIST, '29')) or ''))
real = cl.released()
check('real list: from 27.0, every minor of 27 and 28', real[0] == (27, 0) and all((j, n) in real for j in (27, 28) for n in range(6)))
check('real list: matrix is JSON', json.loads(json.dumps(cl.matrix(real))) == cl.matrix(real))

if FAILED:
    raise SystemExit('self-test FAILED: %d check(s): %s' % (len(FAILED), ', '.join(FAILED)))
print('self-test OK')
