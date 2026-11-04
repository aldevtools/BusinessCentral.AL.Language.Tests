# profiles

Profiles and page customizations.

## Topics

- (area folder itself): 9 AL files that are about the area as a whole or were not given a topic yet.

A new topic gets a line here in the same pull request (standing rule 8 in CONTRIBUTING.md).

## Shared fixtures used here

- codeunit 69160 "Probe Observer": 1 file

## Other apps

- Same area in other apps (only what cannot compile in the Cloud app): `tests/al-language-onprem/profiles/`.
- Must-not-compile cases (5, in `tests/must-not-compile/cases/`, listed by `tests/must-not-compile/areas.tsv`): `0019-executionmode-profile-does-not-exist`, `0765-table-allowincustomizations-invalid`, `0795-profile-profiledescriptionml-bad-language`, `2034-parameter-named-profileextension`, `2130-profile-name-31-characters`.

## Adding a test

1. Search this area for a test that already pins the behavior. If one does, cite it and write nothing.
2. Add `[Test]` procedures at the end of the existing codeunit of the topic. Make a new codeunit only for a new topic.
3. Use the shared fixtures. A local object needs a `// local object: <reason>` line.
4. Name the folder after the topic, never after a writer, an issue or a batch.
5. Never renumber a codeunit or rename a test. Read the standing rules in `CONTRIBUTING.md` first.
