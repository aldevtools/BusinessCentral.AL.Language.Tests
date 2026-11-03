# install-upgrade

Install and upgrade codeunits, upgrade tags, DataTransfer.

## Topics

- (area folder itself): 26 AL files that are about the area as a whole or were not given a topic yet.
- `install-order/`: the order install and upgrade code runs in (7 AL files).
- `install-triggers/`: install and upgrade triggers (8 AL files).

A new topic gets a line here in the same pull request (standing rule 8 in CONTRIBUTING.md).

## Shared fixtures used here

- codeunit 69160 "Probe Observer": 19 files
- table 60001 "ALT Composite": 2 files
- table 60000 "ALT Universal": 2 files
- codeunit 50302 "LT UR Install Low": 1 file

## Other apps

- Same area in other apps (only what cannot compile in the Cloud app): none.
- Must-not-compile cases (6, in `tests/must-not-compile/cases/`, listed by `tests/must-not-compile/areas.tsv`): `0010-executionmode-install-does-not-exist`, `0011-executionmode-uninstall-does-not-exist`, `0012-executionmode-upgrade-does-not-exist`, `0365-datatransfer-adddestinationfilter-runtime17`, `0951-validate-upgrade-triggers-need-upgrade-subtype`, `1422-upgrade-codeunit-with-tableno`.

## Adding a test

1. Search this area for a test that already pins the behavior. If one does, cite it and write nothing.
2. Add `[Test]` procedures at the end of the existing codeunit of the topic. Make a new codeunit only for a new topic.
3. Use the shared fixtures. A local object needs a `// local object: <reason>` line.
4. Name the folder after the topic, never after a writer, an issue or a batch.
5. Never renumber a codeunit or rename a test. Read the standing rules in `CONTRIBUTING.md` first.
