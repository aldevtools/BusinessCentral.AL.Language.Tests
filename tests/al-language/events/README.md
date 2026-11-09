# events

Event publishers and subscribers, BindSubscription, platform trigger events, subscriber order, events of extensions.

## Topics

- (area folder itself): 18 AL files that are about the area as a whole or were not given a topic yet.
- `binding-senders/`: binding, senders and parameters of subscribers (10 AL files).
- `extension-events/`: events of extension objects (3 AL files).
- `page-events/`: page events (4 AL files).
- `platform-triggers/`: platform trigger events (26 AL files).
- `subscriber-order/`: the order subscribers run in (8 AL files).
- `table-events/`: table events (2 AL files).

A new topic gets a line here in the same pull request (standing rule 8 in CONTRIBUTING.md).

## Shared fixtures used here

- codeunit 69160 "Probe Observer": 46 files
- table 69162 "Probe Observer Entry": 1 file

## Other apps

- Same area in other apps (only what cannot compile in the Cloud app): none.
- Must-not-compile cases (24, in `tests/must-not-compile/cases/`, listed by `tests/must-not-compile/areas.tsv`): `0047-event-subscriber-missing-event`, `0222-subscriber-unknown-codeunit`, `0725-subscribe-company-triggers-unknown-event`, `0740-subscribe-internal-event-get-role-center-banner`, `0975-withevents-cloud`, `0992-withevents-integer-variable`, `1680-event-names-differ-by-space-or-underscore`, `1681-event-publisher-overload-and-builtin-name`, `1682-event-publisher-body-return-locals`, `1683-subscriber-objecttype-tableextension`, `1684-subscriber-table-instead-of-database`, `1685-subscriber-var-on-by-value-parameter`, `1686-subscriber-enum-option-integer-mismatch`, `1687-subscriber-parameter-name-not-found`, `1688-subscriber-record-codeunit-decimal-type-mismatch`, `1689-action-subscriber-caption-instead-of-name`, `1691-subscriber-reads-rec-currfieldno`, `1960-test-codeunit-static-subscriber`, `1961-test-codeunit-explicit-static-subscriber`, `2023-parameter-named-event`, `2163-exit-value-in-event-subscriber`, `2335-runonclient-withevents-codeunit`, `2714-bindsubscription-this-in-table`, `2717-bindsubscription-integer-variable-named-this`.

## Adding a test

1. Search this area for a test that already pins the behavior. If one does, cite it and write nothing.
2. Add `[Test]` procedures at the end of the existing codeunit of the topic. Make a new codeunit only for a new topic.
3. Use the shared fixtures. A local object needs a `// local object: <reason>` line.
4. Name the folder after the topic, never after a writer, an issue or a batch.
5. Never renumber a codeunit or rename a test. Read the standing rules in `CONTRIBUTING.md` first.
