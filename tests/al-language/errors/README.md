# errors

Error, asserterror, ErrorInfo, collected errors, GetLastError*, TryFunction and the texts of runtime errors.

## Topics

- (area folder itself): 46 AL files that are about the area as a whole or were not given a topic yet.
- `error-texts/`: the texts of runtime errors (14 AL files).
- `errorinfo/`: ErrorInfo and error notifications (12 AL files).
- `last-error/`: GetLastError* and call stacks (19 AL files).

A new topic gets a line here in the same pull request (standing rule 8 in CONTRIBUTING.md).

## Shared fixtures used here

- codeunit 69160 "Probe Observer": 67 files
- table 60000 "ALT Universal": 10 files
- table 60590 "ALT No Subscriber Table": 1 file
- table 60291 "ALT CRM Entity": 1 file
- table 60025 "ALT Temp Only": 1 file
- query 60022 "ALT Universal Query": 1 file
- xmlport 60023 "ALT Universal XmlPort": 1 file
- codeunit 60014 "ALT Event Publisher": 1 file
- table 60002 "ALT Triggered": 1 file
- table 60003 "ALT Trigger Log": 1 file

## Other apps

- Same area in other apps (only what cannot compile in the Cloud app): none.
- Must-not-compile cases (6, in `tests/must-not-compile/cases/`, listed by `tests/must-not-compile/areas.tsv`): `0068-trigger-function-with-return-value`, `0110-getlasterrorobject-is-onprem`, `1372-tryfunction-explicit-return-value`, `1384-tryfunction-implements-interface`, `1752-tryfunction-implements-interface-method`, `1760-tryfunction-explicit-exit-value`.

## Adding a test

1. Search this area for a test that already pins the behavior. If one does, cite it and write nothing.
2. Add `[Test]` procedures at the end of the existing codeunit of the topic. Make a new codeunit only for a new topic.
3. Use the shared fixtures. A local object needs a `// local object: <reason>` line.
4. Name the folder after the topic, never after a writer, an issue or a batch.
5. Never renumber a codeunit or rename a test. Read the standing rules in `CONTRIBUTING.md` first.
