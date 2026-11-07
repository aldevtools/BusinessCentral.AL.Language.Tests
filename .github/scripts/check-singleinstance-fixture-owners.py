#!/usr/bin/env python3
"""Fail the build when one SingleInstance codeunit is instantiated from more than
one TEST codeunit.

Why this exists
---------------
A `SingleInstance = true` codeunit gets exactly one instance per session, and that
instance is registered on the session's company -- `NCLMetaCodeunit.InternalCreateInstance`
adds it to `NavCompany.SingleInstanceCodeunits`, and only `NavCompany.Dispose` ever
clears that dictionary. Nothing in the test-execution path touches it:
`NavTestExecution.LeaveTestCodeunit` clears `executingTestCodeUnit` and nothing else.
(Verified identical on BC 27.5 and 28.4.)

So a SingleInstance fixture shared by two test codeunits is shared state with no
reset between them, and whichever test codeunit runs FIRST decides what the others
observe. That is BC behaving exactly as documented; the bug is the shared fixture.

This is not hypothetical. Issue #261: three test codeunits (60613/60614/60615) all
used `SIS Cache` (60608), each seeding a different currency into the one cached
record. The three BC 27.x legs ran 60615 first and the other two read its `CHF`;
the eight 28.x legs ran 60615 LAST and passed -- not by clearing anything, but by
ordering luck. Eight green legs measured nothing, which is the reason this check
looks at structure rather than at a run's outcome.

What counts as "instantiated"
-----------------------------
A variable declaration -- `Foo: Codeunit "Bar"` -- because that is what resolves an
instance, and `Codeunit.Run(Codeunit::"Bar")`, because that executes Bar's OnRun.
`Codeunit::"Bar"` on its own is a compile-time object-id literal and reaches no
instance at all; several corpus tests use it to assert on metadata rows (object id
ordering, the `CodeUnit Metadata` SingleInstance column) and must not be reported.

Reachability is transitive: a test codeunit that runs a plain helper codeunit which
declares the fixture owns the fixture just as much as one naming it directly.

Shared on purpose
-----------------
A probe whose subject IS the state carried from one test codeunit to the next (the
runner-trigger probe of the isolation-probe app records what a test runner's triggers
saw and reads it back in a later test codeunit) needs one log across several test
codeunits. Its file says so in a comment line starting with SHARED_MARKER and the
reason; every SingleInstance codeunit declared in that file is then not reported.
The marker is explicit and greppable on purpose: sharing stays the exception.

Preprocessor branches are not interpreted, matching check-object-ids.py. A fixture
reachable only under mutually exclusive `#if` branches would be reported falsely;
no corpus file does that today, and a loud false positive beats a silent miss.
"""
import re
import sys
from collections import defaultdict
from pathlib import Path

CODEUNIT_DECL = re.compile(r'^[ \t]*codeunit[ \t]+(\d+)[ \t]+"([^"]+)"', re.M)
SINGLE_INSTANCE = re.compile(r'\bSingleInstance\s*=\s*true\s*;', re.I)
SUBTYPE_TEST = re.compile(r'\bSubtype\s*=\s*Test\s*;', re.I)

# `Name: Codeunit "Foo"` -- a variable/parameter/return declaration. This is the
# form that resolves an instance.
VAR_DECL = re.compile(r':\s*Codeunit\s+"([^"]+)"')
# `Codeunit.Run(Codeunit::"Foo")` -- executes Foo's OnRun, so it reaches Foo's
# instance even though the argument itself is only an id literal.
SHARED_MARKER = "// singleinstance-shared-on-purpose:"
SHARED_OK = set()
CODEUNIT_RUN = re.compile(r'Codeunit\s*\.\s*Run\s*\(\s*Codeunit\s*::\s*"([^"]+)"')


def strip_comments(text: str) -> str:
    """Drop `//` line comments so header prose naming a fixture is not a reference.

    Block comments are not stripped: AL has no `/* */`, and the corpus does not
    use one.
    """
    return "\n".join(line.split("//", 1)[0] for line in text.splitlines())


def parse(root: Path):
    """-> (objects, refs). objects[name] = (id, relpath, line, is_single, is_test)."""
    objects, refs = {}, defaultdict(set)
    SHARED_OK.clear()
    for al in sorted(root.rglob("*.al")):
        if ".git" in al.parts:
            continue
        try:
            raw = al.read_text(encoding="utf-8-sig", errors="replace")
        except OSError as exc:
            print(f"::error file={al}::could not be read: {exc}")
            raise SystemExit(1)
        body = strip_comments(raw)
        shared_ok = any(line.strip().startswith(SHARED_MARKER) for line in raw.splitlines())
        decls = list(CODEUNIT_DECL.finditer(body))
        for i, m in enumerate(decls):
            end = decls[i + 1].start() if i + 1 < len(decls) else len(body)
            seg = body[m.end():end]
            name = m.group(2)
            objects[name] = (
                int(m.group(1)),
                al.relative_to(root),
                body[:m.start()].count("\n") + 1,
                SINGLE_INSTANCE.search(seg) is not None,
                SUBTYPE_TEST.search(seg) is not None,
            )
            if shared_ok:
                SHARED_OK.add(name)
            for pat in (VAR_DECL, CODEUNIT_RUN):
                for r in pat.finditer(seg):
                    refs[name].add(r.group(1))
    return objects, refs


def reachable(start: str, refs) -> set:
    seen, stack = set(), [start]
    while stack:
        for nxt in refs.get(stack.pop(), ()):
            if nxt not in seen:
                seen.add(nxt)
                stack.append(nxt)
    return seen


def main() -> int:
    root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
    objects, refs = parse(root)

    if not objects:
        print(f"::error::no AL codeunits found under {root} — refusing to pass vacuously")
        return 1

    singles = {n for n, v in objects.items() if v[3]}
    tests = {n for n, v in objects.items() if v[4]}

    if not singles:
        print(f"::error::no SingleInstance codeunit found under {root} — the corpus has "
              f"several, so this almost certainly means parsing broke rather than that "
              f"they were all deleted; refusing to pass vacuously")
        return 1

    owners = defaultdict(set)
    for t in tests:
        for s in reachable(t, refs) & singles:
            owners[s].add(t)

    shared = {s: sorted(v) for s, v in owners.items() if len(v) > 1 and s not in SHARED_OK}

    if not shared:
        print(f"OK — {len(singles)} SingleInstance codeunit(s), {len(tests)} test codeunit(s); "
              f"no SingleInstance fixture is instantiated from more than one test codeunit.")
        return 0

    print("=" * 78)
    print("SingleInstance FIXTURE SHARED BY SEVERAL TEST CODEUNITS")
    print("=" * 78)
    print("A SingleInstance instance lives on the session's company and is NOT reset")
    print("between test codeunits, so the first test codeunit to touch one of these")
    print("decides what every later one observes. The tests then pass or fail on")
    print("execution order rather than on the behavior they assert (issue #261).")
    print()
    print("Fix: give each test codeunit its own fixture. A reset procedure is not")
    print("equivalent -- for tests whose subject IS the SingleInstance lifetime, the")
    print("reset removes the very state under test.")
    print()
    for fixture, tcs in sorted(shared.items()):
        obj_id, rel, line, _, _ = objects[fixture]
        print(f'  codeunit {obj_id} "{fixture}"  ({rel}:{line})')
        print(f"      instantiated from {len(tcs)} test codeunits:")
        for tc in tcs:
            t_id, t_rel, t_line, _, _ = objects[tc]
            print(f'          codeunit {t_id} "{tc}"   {t_rel}:{t_line}')
        print()
    for fixture, tcs in sorted(shared.items()):
        obj_id, rel, line, _, _ = objects[fixture]
        print(f"::error file={rel},line={line}::SingleInstance codeunit {obj_id} "
              f'"{fixture}" is instantiated from {len(tcs)} test codeunits '
              f"({', '.join(tcs)}) — its state is not reset between them, so the "
              f"result depends on execution order")
    return 1


if __name__ == "__main__":
    sys.exit(main())
