# testpage

The TestPage and TestPart API: opening, navigating, fields and actions, filters, lifecycle and teardown.

## Topics

- (area folder itself): 475 AL files that are about the area as a whole or were not given a topic yet.
- `filters/`: SetRange, SetFilter, filter syntax and GetFilter(s) (8 AL files).
- `lifecycle/`: opening, closing and page variables (6 AL files).
- `notifications-and-control-values/`: notification handlers, control values read as decimal or text, role center TestPage (3 AL files).
- `parts/`: page parts and subpages (46 AL files).

A new topic gets a line here in the same pull request (standing rule 8 in CONTRIBUTING.md).

## Shared fixtures used here

- codeunit 69160 "Probe Observer": 137 files
- table 60000 "ALT Universal": 7 files
- page 60016 "ALT List Page": 3 files
- enum 60009 "ALT Status": 2 files
- page 60821 "ALT Source Table View List": 2 files
- table 60006 "ALT Keyed": 2 files
- table 60003 "ALT Trigger Log": 2 files
- report 60018 "ALT Simple Report": 1 file
- page 60017 "ALT Card Page": 1 file
- codeunit 60634 "ALT Page Evt Manual Sub": 1 file
- codeunit 60635 "ALT Page Evt Veto Sub": 1 file
- page 60632 "ALT Page Evt Rows": 1 file

## Other apps

- Same area in other apps (only what cannot compile in the Cloud app): none.
- Must-not-compile cases (11, in `tests/must-not-compile/cases/`, listed by `tests/must-not-compile/areas.tsv`): `0561-testpage-prev`, `0562-testpart-prev`, `1120-testrequestpage-dataitem-setrange`, `1211-modalpagehandler-testpage-with-response`, `1212-testpage-delete-action`, `1601-testpage-ok-cancel-unused`, `1602-testpage-delete`, `1632-testpage-pageext-procedure`, `1864-testpage-cannot-reach-pending-special-controls`, `2570-testpage-getrecord`, `2571-testpart-getrecord`.

## Line-sensitive files

These files assert line numbers or call stacks. Only append at the end of the codeunit; never add or remove lines above existing code (standing rule 5).

- `P129CallstackPageControls.al`
- `P135CallstackPage.al`
- `PnGPartRows.al`
- `PnGPartTriggers.al`
- `RmReadOnlyBlob.al`
- `TestPageAutoSplitKey_Tests.al`
- `TestPageSubpagePart.al`
- `parts/TestPartProvider.al`
- `parts/TestPartProviderMove.al`
- `parts/TestTestPart.al`

## Adding a test

1. Search this area for a test that already pins the behavior. If one does, cite it and write nothing.
2. Add `[Test]` procedures at the end of the existing codeunit of the topic. Make a new codeunit only for a new topic.
3. Use the shared fixtures. A local object needs a `// local object: <reason>` line.
4. Name the folder after the topic, never after a writer, an issue or a batch.
5. Never renumber a codeunit or rename a test. Read the standing rules in `CONTRIBUTING.md` first.
