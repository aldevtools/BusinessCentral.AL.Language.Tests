#!/usr/bin/env python3
"""Render the Windows nightly's isolation-probe runs as per-test rows (AL Runner #4826).

The probe app (tests/al-language-isolation-probe) is run twice by nightly-windows.yml:
under a TestIsolation = Function runner (61300) and under the identical Codeunit runner
(61301) as a control. This script puts every test of both runs in the job summary, with
its failure message, because the message carries the observed value -- the rows are the
measurement, not the conclusion.

It is kept apart from bc-test-results.py on purpose: the probe's rows must never reach
that report's headline failure count or its #213 comparison.

Exit status:
  0  every run parsed, and every fixture test has a row in every run
  3  NO VERDICT for at least one run: file missing or unreadable, zero tests parsed, or a
     fixture test with no row. The summary says which. A run that died before executing
     a test is not a run that found nothing.
"""
import argparse
import importlib.util
import os
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent

# [Test] followed by `procedure <Name>(` -- the fixture's test methods, in declaration order.
TEST_PROC = re.compile(r"\[Test\]\s*procedure\s+(\w+)\s*\(", re.I)


def load_parser():
    spec = importlib.util.spec_from_file_location("bc_test_results", HERE / "bc-test-results.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod.parse_xunit


def fixture_tests(path):
    names = TEST_PROC.findall(pathlib.Path(path).read_text(encoding="utf-8-sig"))
    if not names:
        raise SystemExit(f"::error::no [Test] procedure found in {path}; refusing to render against an empty expectation")
    return names


def cell(text):
    return (text or "").replace("|", "\\|").replace("\n", " ")


def render_run(label, path, expected, parse_xunit):
    """-> (markdown lines, verdict_available, {test: result})"""
    lines = [f"#### {label}", "", f"source: `{path}`", ""]
    if not os.path.isfile(path):
        lines += [f"**NO VERDICT** -- `{path}` does not exist: the run never wrote results.", ""]
        return lines, False, {}
    try:
        tests = parse_xunit(path)
    except Exception as exc:  # malformed XML is a broken measurement, not an empty one
        lines += [f"**NO VERDICT** -- `{path}` could not be parsed: {cell(str(exc))}", ""]
        return lines, False, {}
    if not tests:
        lines += [f"**NO VERDICT** -- `{path}` parsed to 0 tests.", ""]
        return lines, False, {}

    by_name = {t["test"]: t for t in tests}
    lines += ["| test | result | message (observed value) |", "|---|---|---|"]
    results, missing = {}, []
    for name in expected:
        t = by_name.get(name)
        if t is None:
            missing.append(name)
            lines.append(f"| {name} | **NOT RUN** | no row in the XUnit file |")
            continue
        results[name] = t["result"]
        lines.append(f"| {name} | {t['result']} | {cell(t['message'])} |")
    for t in tests:
        if t["test"] not in expected:
            lines.append(f"| {t['test']} (not in the fixture) | {t['result']} | {cell(t['message'])} |")
    lines.append("")
    if missing:
        lines += [f"**NO VERDICT** -- {len(missing)} fixture test(s) have no row: {', '.join(missing)}.", ""]
    return lines, not missing, results


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--run", action="append", required=True, metavar="LABEL=XUNIT",
                    help="a run to render; repeat for each")
    ap.add_argument("--fixture", required=True, help="the fixture .al file whose [Test] procedures every run must report")
    ap.add_argument("--outdir", default="test-results")
    ap.add_argument("--title", default="Isolation probe (AL Runner #4826)", help="the summary heading")
    ap.add_argument("--note", default=None, help="the paragraph under the heading (default: the isolation fixture's)")
    args = ap.parse_args()

    parse_xunit = load_parser()
    expected = fixture_tests(args.fixture)

    note = args.note if args.note is not None else (
        "Not part of the headline above. Each fixture test asserts one reading -- the test "
        "codeunit instance is reused across its [Test] methods and Function isolation rolls "
        "the database back after each -- and a failure message carries what was observed. "
        "T5 is the instrument check: it must pass under the Function runner and fail under "
        "the Codeunit control; otherwise the run did not measure Function isolation.")
    out = [f"## {args.title}", "", note, ""]
    all_ok = True
    for spec in args.run:
        if "=" not in spec:
            raise SystemExit(f"::error::--run expects LABEL=XUNIT, got {spec!r}")
        # The PATH is after the LAST '=': a label may itself contain one ("TestIsolation = Function").
        label, path = spec.rsplit("=", 1)
        lines, ok, _ = render_run(label, path, expected, parse_xunit)
        out += lines
        all_ok = all_ok and ok

    text = "\n".join(out) + "\n"
    outdir = pathlib.Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)
    (outdir / "isolation-probe.md").write_text(text, encoding="utf-8")
    print(text)
    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        with open(summary, "a", encoding="utf-8") as fh:
            fh.write(text)
    if not all_ok:
        print("::warning::isolation probe: NO VERDICT for at least one run -- see the summary")
        return 3
    return 0


if __name__ == "__main__":
    sys.exit(main())
