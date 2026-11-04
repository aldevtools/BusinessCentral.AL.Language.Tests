# ui-handlers

Test handlers: MessageHandler, ConfirmHandler, StrMenuHandler, ModalPageHandler, PageHandler, ReportHandler, RequestPageHandler and the notification handlers.

## Topics

- (area folder itself): 95 AL files that are about the area as a whole or were not given a topic yet.

A new topic gets a line here in the same pull request (standing rule 8 in CONTRIBUTING.md).

## Shared fixtures used here

- codeunit 69160 "Probe Observer": 31 files
- codeunit 67702 "W3 Runner": 1 file

## Other apps

- Same area in other apps (only what cannot compile in the Cloud app): none.
- Must-not-compile cases (16, in `tests/must-not-compile/cases/`, listed by `tests/must-not-compile/areas.tsv`): `0049-handler-function-does-not-exist`, `0784-codeunit-testhandlers-runtime-16`, `0962-testhandlercontext-type`, `0983-httpclienthandler-cloud`, `0984-httpclienthandler-wrong-signature`, `0985-reporthandler-wrong-signature`, `0986-reporthandler-outside-test-codeunit`, `0996-testhandlercontext-runtime-16`, `1210-modalpagehandler-page-without-response`, `1411-handler-attributes-placement-and-signature`, `1600-local-ui-handler`, `1608-handler-attribute-on-two-overloads`, `1609-handler-in-another-codeunit`, `2300-testhandlers-on-non-test-codeunit`, `2301-testhandlers-unknown-value`, `2305-testhandlers-same-value-twice`.

## Adding a test

1. Search this area for a test that already pins the behavior. If one does, cite it and write nothing.
2. Add `[Test]` procedures at the end of the existing codeunit of the topic. Make a new codeunit only for a new topic.
3. Use the shared fixtures. A local object needs a `// local object: <reason>` line.
4. Name the folder after the topic, never after a writer, an issue or a batch.
5. Never renumber a codeunit or rename a test. Read the standing rules in `CONTRIBUTING.md` first.
