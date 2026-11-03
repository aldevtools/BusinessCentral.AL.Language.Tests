# text

Text and Code methods, TextBuilder, BigText, TextConst and Label.

## Topics

- (area folder itself): 34 AL files that are about the area as a whole or were not given a topic yet.
- `text-methods/`: Text and Code methods (28 AL files).
- `textbuilder-bigtext/`: TextBuilder and BigText (7 AL files).
- `textconst-label/`: TextConst and Label (11 AL files).

A new topic gets a line here in the same pull request (standing rule 8 in CONTRIBUTING.md).

## Shared fixtures used here

- codeunit 69160 "Probe Observer": 62 files

## Other apps

- Same area in other apps (only what cannot compile in the Cloud app): none.
- Must-not-compile cases (10, in `tests/must-not-compile/cases/`, listed by `tests/must-not-compile/areas.tsv`): `0236-textbuilder-no-add`, `0238-strlen-no-args`, `0239-strlen-two-args`, `0241-copystr-four-args`, `0254-replace-one-arg`, `0255-copystr-text-position`, `0490-secretstrsubstno-text-literal`, `0491-secretstrsubstno-integer-argument`, `1832-base64-frombase64-bigtext`, `1833-bigtext-to-text-assignment`.

## Adding a test

1. Search this area for a test that already pins the behavior. If one does, cite it and write nothing.
2. Add `[Test]` procedures at the end of the existing codeunit of the topic. Make a new codeunit only for a new topic.
3. Use the shared fixtures. A local object needs a `// local object: <reason>` line.
4. Name the folder after the topic, never after a writer, an issue or a batch.
5. Never renumber a codeunit or rename a test. Read the standing rules in `CONTRIBUTING.md` first.
