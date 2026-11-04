# metadata

Virtual and system tables (AllObj, Field, page metadata) and other platform tables.

## Topics

- (area folder itself): 13 AL files that are about the area as a whole or were not given a topic yet.
- `code-coverage/`: code coverage (2 AL files).
- `platform-tables/`: platform and system tables (77 AL files).
- `session-system/`: platform objects about the session (REVIEW) (20 AL files).

A new topic gets a line here in the same pull request (standing rule 8 in CONTRIBUTING.md).

## Shared fixtures used here

- codeunit 69160 "Probe Observer": 103 files
- page 60879 "ALT Prompt Dialog Page": 1 file
- table 60000 "ALT Universal": 1 file

## Other apps

- Same area in other apps (only what cannot compile in the Cloud app): `tests/al-language-onprem/metadata/`.

## Adding a test

1. Search this area for a test that already pins the behavior. If one does, cite it and write nothing.
2. Add `[Test]` procedures at the end of the existing codeunit of the topic. Make a new codeunit only for a new topic.
3. Use the shared fixtures. A local object needs a `// local object: <reason>` line.
4. Name the folder after the topic, never after a writer, an issue or a batch.
5. Never renumber a codeunit or rename a test. Read the standing rules in `CONTRIBUTING.md` first.
