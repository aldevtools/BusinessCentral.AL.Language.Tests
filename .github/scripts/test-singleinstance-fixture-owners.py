#!/usr/bin/env python3
"""Self-test for check-singleinstance-fixture-owners.py -- AND the thing that runs it
against the real corpus.

Why both jobs live in one file
------------------------------
ci.yml discovers `.github/scripts/test-*.py` BY GLOB, so a suite named this way
gates from the day it lands with no workflow edit. Adding a separate, explicitly
named step for the checker would need one, and the account these agents push under
has no `workflow` OAuth scope -- the push is rejected outright. Rather than land a
checker that nothing runs, this suite ends by running it over the repository root.

The ordering matters and is deliberate: the synthetic scenarios run FIRST, so a
green on the corpus is only ever reported by a checker that has just demonstrated
it still detects, still ignores what it must ignore, and still refuses to pass
vacuously. A checker that silently stopped parsing AL would otherwise report OK on
the corpus for the same reason it reports OK on an empty tree.

The check's interesting path fires only when someone reintroduces a shared
SingleInstance fixture, which is exactly what nobody does on purpose. Left
untested it would sit in CI reporting OK whether or not it still parsed AL --
the shape of a check that has quietly stopped checking, and the shape this
whole area already produced once: eight green BC 28.x legs that measured
nothing because 60615 happened to run last (issue #261).

So this builds throwaway AL trees with known answers and asserts both
directions, including the three ways the check must NOT fire. No network,
about a second.
"""
import importlib.util
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location(
    "sifo", HERE / "check-singleinstance-fixture-owners.py")
sifo = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sifo)

FAILURES = []


def check(root: Path) -> int:
    argv = sys.argv
    sys.argv = ["check", str(root)]
    try:
        return sifo.main()
    finally:
        sys.argv = argv


def scenario(name: str, files: dict, expected: int):
    with tempfile.TemporaryDirectory() as td:
        root = Path(td)
        (root / "app.json").write_text(
            '{"id":"a","name":"T","publisher":"p","version":"1.0.0.0",'
            '"idRanges":[{"from":60000,"to":62000}]}')
        for rel, text in files.items():
            p = root / rel
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(text)
        print(f"--- {name}")
        got = check(root)
    if got != expected:
        FAILURES.append(f"{name}: expected exit {expected}, got {got}")
    return got


def fixture(oid, name, single=True):
    return (f'codeunit {oid} "{name}"\n{{\n'
            f'    SingleInstance = {"true" if single else "false"};\n'
            f'    var\n        V: Integer;\n'
            f'    procedure Get(): Integer begin exit(V); end;\n}}\n')


def test_cu(oid, name, body):
    return (f'codeunit {oid} "{name}"\n{{\n    Subtype = Test;\n'
            f'    [Test]\n    procedure T()\n    var\n{body}    begin\n    end;\n}}\n')


# 1. The #261 shape itself: two test codeunits declaring one SingleInstance fixture.
scenario("shared fixture is REPORTED", {
    "f.al": fixture(60001, "Shared"),
    "a.al": test_cu(60002, "Test A", '        C: Codeunit "Shared";\n'),
    "b.al": test_cu(60003, "Test B", '        C: Codeunit "Shared";\n'),
}, expected=1)

# 2. The fix shape: one fixture each.
scenario("one fixture per test codeunit is ACCEPTED", {
    "f.al": fixture(60001, "Own A") + fixture(60004, "Own B"),
    "a.al": test_cu(60002, "Test A", '        C: Codeunit "Own A";\n'),
    "b.al": test_cu(60003, "Test B", '        C: Codeunit "Own B";\n'),
}, expected=0)

# 3. Must NOT fire on `Codeunit::"X"` used as an object-id literal. Several corpus
#    tests assert on CodeUnit Metadata / AllObj rows this way and never touch the
#    instance; reporting them would make the check unusable.
scenario("Codeunit::\"X\" id literal is NOT a reference", {
    "f.al": fixture(60001, "Shared"),
    "a.al": test_cu(60002, "Test A", '        C: Codeunit "Shared";\n'),
    "b.al": ('codeunit 60003 "Test B"\n{\n    Subtype = Test;\n'
             '    [Test]\n    procedure T()\n    var\n        I: Integer;\n'
             '    begin\n        I := Codeunit::"Shared";\n    end;\n}\n'),
}, expected=0)

# 4. Must NOT fire on a non-SingleInstance codeunit: every variable gets its own
#    instance, so sharing one across test codeunits is fine. The unrelated
#    SingleInstance fixture is here so the tree does not instead trip the
#    refuse-to-pass-vacuously guard, which would make this scenario prove nothing
#    -- it caught exactly that when first written.
scenario("non-SingleInstance codeunit shared is ACCEPTED", {
    "f.al": fixture(60001, "Plain", single=False) + fixture(60005, "Unrelated"),
    "a.al": test_cu(60002, "Test A", '        C: Codeunit "Plain";\n'),
    "b.al": test_cu(60003, "Test B", '        C: Codeunit "Plain";\n'),
}, expected=0)

# 5. Must NOT fire on a fixture named only in a `//` comment.
scenario("fixture named only in a comment is NOT a reference", {
    "f.al": fixture(60001, "Shared"),
    "a.al": test_cu(60002, "Test A", '        C: Codeunit "Shared";\n'),
    "b.al": ('// Fixtures used: Shared (60001) -- prose, not a reference\n'
             '// C: Codeunit "Shared";\n'
             + test_cu(60003, "Test B", '        I: Integer;\n')),
}, expected=0)

# 6. MUST fire transitively: the second test codeunit reaches the fixture through a
#    plain helper it runs, never naming the fixture itself. This is the shape the
#    #261 fix uses for its primers, so a non-transitive check would pass the very
#    tree it was written for while a regression hid one level down.
scenario("transitive reach through Codeunit.Run is REPORTED", {
    "f.al": fixture(60001, "Shared"),
    "h.al": ('codeunit 60004 "Helper"\n{\n    trigger OnRun()\n    var\n'
             '        C: Codeunit "Shared";\n    begin\n    end;\n}\n'),
    "a.al": test_cu(60002, "Test A", '        C: Codeunit "Shared";\n'),
    "b.al": ('codeunit 60003 "Test B"\n{\n    Subtype = Test;\n'
             '    [Test]\n    procedure T()\n    begin\n'
             '        if Codeunit.Run(Codeunit::"Helper") then;\n    end;\n}\n'),
}, expected=1)

# 7. Refuse to pass vacuously when parsing finds nothing -- the failure mode that
#    lets a broken regex read as a clean tree.
scenario("a tree with no SingleInstance codeunit REFUSES to pass", {
    "a.al": test_cu(60002, "Test A", '        I: Integer;\n'),
}, expected=1)

# 8. A file that marks its SingleInstance codeunit as shared on purpose is not
#    reported; the same tree without the marker is (scenario 1).
scenario("marked shared-on-purpose fixture is ACCEPTED", {
    "f.al": "// singleinstance-shared-on-purpose: the probe reads it in a later test codeunit\n"
            + fixture(60001, "Shared"),
    "a.al": test_cu(60002, "Test A", '        C: Codeunit "Shared";\n'),
    "b.al": test_cu(60003, "Test B", '        C: Codeunit "Shared";\n'),
}, expected=0)

print()
if FAILURES:
    for f in FAILURES:
        print(f"::error::{f}")
    print(f"FAILED — {len(FAILURES)} of 8 scenarios wrong")
    sys.exit(1)
print("OK — all 8 scenarios behaved as specified")

# The gate itself. Only reached once the scenarios above have proved the checker
# still works, so an OK here means something.
print()
print("--- the real corpus")
REPO_ROOT = HERE.parent.parent
rc = check(REPO_ROOT)
if rc != 0:
    print("::error::a SingleInstance fixture is shared between test codeunits — see above")
    sys.exit(rc)
