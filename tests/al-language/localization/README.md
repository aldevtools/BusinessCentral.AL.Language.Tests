# localization

Captions in other languages, translation files, language and region settings.

## Topics

- `app-xliff/`: app translation files (1 AL file).

A new topic gets a line here in the same pull request (standing rule 8 in CONTRIBUTING.md).

## Shared fixtures used here

- codeunit 69160 "Probe Observer": 1 file

## Other apps

- Same area in other apps (only what cannot compile in the Cloud app): none.
- Must-not-compile cases (14, in `tests/must-not-compile/cases/`, listed by `tests/must-not-compile/areas.tsv`): `0015-includecaption-on-expression-column`, `0205-unknown-label`, `0350-assign-to-label`, `0775-field-optioncaptionml-text`, `0885-field-optioncaptionml-text-field`, `0980-caption-attribute-without-serviceenabled`, `1418-fieldcaption-with-enum-value`, `2008-case-option-decimal-label`, `2010-includecaption-on-global-variable-column`, `2330-label-trailing-comma-after-property`, `2331-label-trailing-comma-after-comment`, `2332-label-two-trailing-commas`, `2422-y31-case-char-text-label`, `2423-y31-case-decimal-enum-label`.

## Adding a test

1. Search this area for a test that already pins the behavior. If one does, cite it and write nothing.
2. Add `[Test]` procedures at the end of the existing codeunit of the topic. Make a new codeunit only for a new topic.
3. Use the shared fixtures. A local object needs a `// local object: <reason>` line.
4. Name the folder after the topic, never after a writer, an issue or a batch.
5. Never renumber a codeunit or rename a test. Read the standing rules in `CONTRIBUTING.md` first.
