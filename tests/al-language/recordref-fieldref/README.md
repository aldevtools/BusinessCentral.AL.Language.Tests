# recordref-fieldref

RecordRef, FieldRef and KeyRef.

## Topics

- (area folder itself): 32 AL files that are about the area as a whole or were not given a topic yet.
- `fieldref/`: FieldRef (38 AL files).
- `recordref/`: RecordRef and KeyRef (59 AL files).

A new topic gets a line here in the same pull request (standing rule 8 in CONTRIBUTING.md).

## Shared fixtures used here

- codeunit 69160 "Probe Observer": 94 files
- table 60000 "ALT Universal": 18 files
- table 60990 "Shipping Agent": 3 files
- table 60991 "Config. Package Table": 3 files
- enum 60009 "ALT Status": 2 files
- table 60030 "ALT Relation Parent B": 2 files
- table 60480 "ALT Rel Where Parent": 2 files
- table 60481 "ALT Rel Where Child": 1 file
- table 60483 "ALT Rel Field Class": 1 file
- table 60002 "ALT Triggered": 1 file
- table 60003 "ALT Trigger Log": 1 file
- table 60291 "ALT CRM Entity": 1 file

## Other apps

- Same area in other apps (only what cannot compile in the Cloud app): none.
- Must-not-compile cases (18, in `tests/must-not-compile/cases/`, listed by `tests/must-not-compile/areas.tsv`): `0230-recordref-no-fieldd`, `0566-database-alterkey-is-onprem`, `1140-recordref-gettable-of-recordref`, `1341-page-run-fqn-fieldref`, `1633-page-run-recordref-bc27`, `1634-page-run-recordref`, `1786-codeunit-run-recordref`, `1787-codeunit-run-recordref-bc27`, `1792-fieldref-value-equals-text`, `1793-fieldref-value-equals-integer`, `2184-too-few-arguments-complex-parameters`, `2501-recordref-locktable-assign`, `2502-recordref-readconsistency-assign`, `2503-fieldref-setrange-assign`, `2504-fieldref-setfilter-assign`, `2548-record-validate-fieldref-value`, `2549-record-field-assign-fieldref`, `2556-fieldref-value-ordered-compare`.

## Adding a test

1. Search this area for a test that already pins the behavior. If one does, cite it and write nothing.
2. Add `[Test]` procedures at the end of the existing codeunit of the topic. Make a new codeunit only for a new topic.
3. Use the shared fixtures. A local object needs a `// local object: <reason>` line.
4. Name the folder after the topic, never after a writer, an issue or a batch.
5. Never renumber a codeunit or rename a test. Read the standing rules in `CONTRIBUTING.md` first.
