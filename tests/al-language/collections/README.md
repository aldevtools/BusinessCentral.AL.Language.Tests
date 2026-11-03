# collections

List, Dictionary and the array functions (CopyArray, ArrayLen, CompressArray).

## Topics

- (area folder itself): 36 AL files that are about the area as a whole or were not given a topic yet.
- `copyarray-procedure-result/`: CopyArray with a procedure result as source or target (1 AL file).
- `multi-dimension-array-rows/`: rows of multi-dimensional arrays: clear, pass by value and var, CopyArray (1 AL file).

A new topic gets a line here in the same pull request (standing rule 8 in CONTRIBUTING.md).

## Shared fixtures used here

- codeunit 69160 "Probe Observer": 24 files
- table 60000 "ALT Universal": 2 files

## Other apps

- Same area in other apps (only what cannot compile in the Cloud app): none.
- Must-not-compile cases (29, in `tests/must-not-compile/cases/`, listed by `tests/must-not-compile/areas.tsv`): `0225-list-no-length`, `0226-dictionary-no-size`, `0246-list-add-no-args`, `0247-list-add-wrong-type`, `0248-dictionary-add-one-arg`, `0249-dictionary-add-wrong-value`, `0291-assign-scalar-to-array`, `0294-array-too-many-indices`, `0295-array-size-zero`, `0966-navapp-list-resources-appid`, `1162-copyarray-one-dimension-into-two-dimensions`, `1254-group-freezecolumn`, `1255-group-gridlayout`, `1256-group-indentationcolumn`, `1257-group-indentationcontrols`, `1258-group-treeinitialstate`, `1396-array-with-11-dimensions`, `1397-array-with-1000001-elements`, `1744-dictionary-option-value-type`, `1745-dictionary-option-members-value-type`, `1746-list-of-option`, `1748-dictionary-of-record`, `2009-option-in-decimal-list`, `2302-testdatasource-with-test-attribute`, `2631-field-visible-array-element`, `2640-clear-of-array-procedure-result`, `2641-assign-array-from-procedure-result`, `2770-list-of-variant`, `2771-dictionary-of-variant-value`.

## Adding a test

1. Search this area for a test that already pins the behavior. If one does, cite it and write nothing.
2. Add `[Test]` procedures at the end of the existing codeunit of the topic. Make a new codeunit only for a new topic.
3. Use the shared fixtures. A local object needs a `// local object: <reason>` line.
4. Name the folder after the topic, never after a writer, an issue or a batch.
5. Never renumber a codeunit or rename a test. Read the standing rules in `CONTRIBUTING.md` first.
