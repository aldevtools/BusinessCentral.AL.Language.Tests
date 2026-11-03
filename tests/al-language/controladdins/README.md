# controladdins

Control add-ins.

## Topics


A new topic gets a line here in the same pull request (standing rule 8 in CONTRIBUTING.md).

## Shared fixtures used here

- none yet; see `../_fixtures/README.md` before you add a local object.

## Other apps

- Same area in other apps (only what cannot compile in the Cloud app): none.
- Must-not-compile cases (4, in `tests/must-not-compile/cases/`, listed by `tests/must-not-compile/areas.tsv`): `0787-controladdin-maximumheight-too-large`, `0788-controladdin-maximumwidth-too-large`, `0991-controladdin-unknown-procedure`, `2260-controladdin-procedure-return-value`.

## Adding a test

1. Search this area for a test that already pins the behavior. If one does, cite it and write nothing.
2. Add `[Test]` procedures at the end of the existing codeunit of the topic. Make a new codeunit only for a new topic.
3. Use the shared fixtures. A local object needs a `// local object: <reason>` line.
4. Name the folder after the topic, never after a writer, an issue or a batch.
5. Never renumber a codeunit or rename a test. Read the standing rules in `CONTRIBUTING.md` first.
