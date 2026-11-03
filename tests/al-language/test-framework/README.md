# test-framework

Test runner behavior, test isolation, test permissions of the runner and code coverage.

## Topics

- (area folder itself): 1 AL files that are about the area as a whole or were not given a topic yet.
- `code-coverage/`: code coverage (3 AL files).

A new topic gets a line here in the same pull request (standing rule 8 in CONTRIBUTING.md).

## Shared fixtures used here

- codeunit 69160 "Probe Observer": 4 files

## Other apps

- Same area in other apps (only what cannot compile in the Cloud app): `tests/al-language-onprem/test-framework/`, `tests/al-language-testlibraries/test-framework/`, `tests/al-language-testlibraries/`.

## Adding a test

1. Search this area for a test that already pins the behavior. If one does, cite it and write nothing.
2. Add `[Test]` procedures at the end of the existing codeunit of the topic. Make a new codeunit only for a new topic.
3. Use the shared fixtures. A local object needs a `// local object: <reason>` line.
4. Name the folder after the topic, never after a writer, an issue or a batch.
5. Never renumber a codeunit or rename a test. Read the standing rules in `CONTRIBUTING.md` first.
