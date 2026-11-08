# format-evaluate

Format and Evaluate of every type, format strings and AutoFormat.

## Topics

- (area folder itself): 85 AL files that are about the area as a whole or were not given a topic yet.
- `autoformat/`: AutoFormatType and AutoFormatExpression (7 AL files).
- `record-format/`: Format of a Record, RecordRef and FieldRef, also as a %n argument of StrSubstNo, Message and Error (1 AL file).

- `SoEvaluateSystemOptions.al` (in the area folder itself): Evaluate into the system option types ObjectType, Verbosity, TelemetryScope, DataClassification, TransactionType, ReportFormat, ErrorType, DefaultLayout, TestPermissions, DataScope, ExecutionContext, NotificationScope, WebServiceActionResultCode and FieldClass.

A new topic gets a line here in the same pull request (standing rule 8 in CONTRIBUTING.md).

## Shared fixtures used here

- codeunit 69160 "Probe Observer": 84 files
- table 60000 "ALT Universal": 1 file
- codeunit 67703 "W3 Dataset": 1 file

## Other apps

- Same area in other apps (only what cannot compile in the Cloud app): none.
- Must-not-compile cases (5, in `tests/must-not-compile/cases/`, listed by `tests/must-not-compile/areas.tsv`): `0252-evaluate-one-arg`, `0257-format-four-args`, `1312-database-datafileinformation-cloud`, `1393-continue-statement-with-variable-named-continue`, `1437-autoformattype-enum-value`.

## Adding a test

1. Search this area for a test that already pins the behavior. If one does, cite it and write nothing.
2. Add `[Test]` procedures at the end of the existing codeunit of the topic. Make a new codeunit only for a new topic.
3. Use the shared fixtures. A local object needs a `// local object: <reason>` line.
4. Name the folder after the topic, never after a writer, an issue or a batch.
5. Never renumber a codeunit or rename a test. Read the standing rules in `CONTRIBUTING.md` first.

- `tablefilter-neutral/`: neutral public-API and page contracts reproduced from AL Runner reports.

- `tablefilter-neutral/`: quoted blank enum-member filters and non-empty Code predicates select the intended row.

- `tablefilter-neutral/`: CaptionClass field-name/caption lookup and quoted blank Code[10] predicates, alone and in a compound filter.

- `tablefilter-neutral/`: quoted numeric grouping commas, quoted literal commas, and compound-condition boundaries (en-US), with plain/quoted controls.

- `tablefilter-neutral/`: quoted blank Text equality/inequality and rejection of an incomplete bare inequality.

- `tablefilter-neutral/`: declared and undeclared enum ordinal conditions, including preserving the numeric filter when no declared row matches.

- `tablefilter-neutral/`: setup-grammar batch controls for Code wildcards, Boolean Yes, nonzero Decimal and sum FlowField predicates, and nonempty Text wildcards.
