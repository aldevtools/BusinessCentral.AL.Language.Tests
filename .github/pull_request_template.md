## What this PR adds or changes

<!-- One sentence describing what behavioral claim(s) this PR adds, fixes, or improves. -->

## Linked issue

Closes #<!-- issue number, or "n/a" -->

## Test area(s)

<!-- Which <area>/<topic>/ folder(s) does this touch? (CONTRIBUTING.md, "Standing rules for new tests") -->

## Checklist

- [ ] `Initialize()` is the first line of every `[Test]` procedure
- [ ] `Initialize()` calls `DeleteAll()` on every table used in the codeunit
- [ ] Shared `_fixtures/` objects used; each local object has a `// local object: <reason>` line
- [ ] New files are in `<area>/<topic>/` (no writer id, issue number or batch name in a folder name)
- [ ] New tests are at the end of the topic's existing codeunit; no codeunit renumbered, no test or must-not-compile case renamed
- [ ] A removed or merged test has a line in `tests/rename-map.tsv`
- [ ] Test name uniquely identifies the claim without reading the body (`Type_Method_Scenario_Outcome`)
- [ ] Doc-link comment block is present at the top of each new file
- [ ] Out-of-scope tests are in the area of the feature and confirm the error only
- [ ] Version-gated code uses `#if BC28PLUS` (or equivalent) with an explanatory comment
- [ ] CI passes on this pull request (all required checks: BC 27.5, 28.5 and 29.0)
