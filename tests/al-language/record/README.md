# record

The Record type: insert, modify, delete, get and find; filters; keys and sorting; FlowFields and CalcFields; loading fields; table views; temporary records; system fields; TestField; table relations; captions.

## Topics

- (area folder itself): 314 AL files that are about the area as a whole or were not given a topic yet.
- `builtin-name-procedures/`: named after its old folder; scope to be written (REVIEW) (2 AL files).
- `captions/`: captions and CaptionClass of fields and records (2 AL files).
- `chained-array-index/`: named after its old folder; scope to be written (REVIEW) (1 AL file).
- `crud/`: Insert, Modify, Delete, Rename, Get, Find*, TransferFields, Copy and Init (37 AL files).
- `curr-field-no/`: named after its old folder; scope to be written (REVIEW) (1 AL file).
- `events/`: record and table events seen from the record (2 AL files).
- `filters/`: SetRange, SetFilter, filter syntax and GetFilter(s) (27 AL files).
- `flowfields/`: FlowFields, CalcFields, CalcSums, CalcFormula and AutoCalcFields (19 AL files).
- `keys-sorting/`: keys, SetCurrentKey, SetAscending and sort order (11 AL files).
- `load-fields/`: SetLoadFields, AddLoadFields and AreFieldsLoaded (12 AL files).
- `stale-buffers/`: named after its old folder; scope to be written (REVIEW) (1 AL file).
- `system-fields/`: SystemId, SystemCreatedAt and the other system fields, timestamps (10 AL files).
- `table-globals-record/`: named after its old folder; scope to be written (REVIEW) (1 AL file).
- `table-properties/`: table and field properties seen through a record (12 AL files).
- `table-relation/`: TableRelation and its conditions (8 AL files).
- `temporary/`: temporary records and tables (6 AL files).
- `testfield/`: TestField and FieldError (27 AL files).
- `transfer-xapp/`: named after its old folder; scope to be written (REVIEW) (2 AL files).
- `views/`: SetView and GetView (5 AL files).

A new topic gets a line here in the same pull request (standing rule 8 in CONTRIBUTING.md).

## Shared fixtures used here

- codeunit 69160 "Probe Observer": 262 files
- table 60000 "ALT Universal": 51 files
- table 60003 "ALT Trigger Log": 19 files
- table 60002 "ALT Triggered": 15 files
- table 60007 "ALT Base": 10 files
- table 60006 "ALT Keyed": 9 files
- table 60004 "ALT Parent": 8 files
- table 60028 "ALT Relation Parent": 7 files
- page 60016 "ALT List Page": 7 files
- table 60005 "ALT Child": 7 files
- table 60001 "ALT Composite": 5 files
- table 60030 "ALT Relation Parent B": 4 files

## Other apps

- Same area in other apps (only what cannot compile in the Cloud app): `tests/al-language-onprem/record/`.
- Must-not-compile cases (28, in `tests/must-not-compile/cases/`, listed by `tests/must-not-compile/areas.tsv`): `0014-cloud-app-api-webhook-entity`, `0060-record-field-does-not-exist`, `0061-record-method-does-not-exist`, `0227-record-no-insertt`, `0253-setrange-no-args`, `0256-record-insert-text-arg`, `0266-record-to-integer`, `0277-record-plus-record`, `0284-record-equals-integer`, `0363-file-copy-cloud`, `0620-record-fullyqualifiedname-runtime-16`, `0621-record-fullyqualifiedname-runtime-16-al17`, `0722-subscribe-globaltriggers-insert-wrong-type`, `0960-record-isdirty`, `1141-record-testfield-byte-value`, `1361-setfilter-text-placeholder-decimal-field`, `1426-removed-field-of-dependency`, `1442-geturl-variant-record-ambiguous`, `1450-setrange-value-without-field`, `1770-case-over-record`, `1784-record-to-var-variant`, `2081-namespace-record-integer-without-using`, `2168-too-few-arguments-record-method`, `2174-too-few-arguments-record-parameter`, `2175-too-few-arguments-var-record-parameter`, `2176-too-few-arguments-temporary-record-parameter`, `2719-record-method-on-this-keyword-with-record-variable-named-this`, `2794-loadpackagedata-record-argument`.

## Line-sensitive files

These files assert line numbers or call stacks. Only append at the end of the codeunit; never add or remove lines above existing code (standing rule 5).

- `P128Callstack.al`
- `TestCalcFormulaSystemFieldsHeader.Table.al`
- `TestCalcFormulaSystemFieldsTests.Codeunit.al`
- `TestRenameKeyRelation.al`

## Adding a test

1. Search this area for a test that already pins the behavior. If one does, cite it and write nothing.
2. Add `[Test]` procedures at the end of the existing codeunit of the topic. Make a new codeunit only for a new topic.
3. Use the shared fixtures. A local object needs a `// local object: <reason>` line.
4. Name the folder after the topic, never after a writer, an issue or a batch.
5. Never renumber a codeunit or rename a test. Read the standing rules in `CONTRIBUTING.md` first.
