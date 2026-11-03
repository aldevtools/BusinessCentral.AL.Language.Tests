# queries

The query object: joins and links, filters and FlowFields, reading.

## Topics

- (area folder itself): 110 AL files that are about the area as a whole or were not given a topic yet.
- `flowfields-filters/`: query filters and FlowFields (5 AL files).
- `joins-links/`: query joins and links (22 AL files).
- `read-lifecycle/`: Open, Read, Close and SaveAs (6 AL files).

A new topic gets a line here in the same pull request (standing rule 8 in CONTRIBUTING.md).

## Shared fixtures used here

- codeunit 69160 "Probe Observer": 55 files
- table 60000 "ALT Universal": 3 files
- query 60022 "ALT Universal Query": 1 file
- table 60008 "ALT Blob": 1 file
- table 60004 "ALT Parent": 1 file
- table 60005 "ALT Child": 1 file

## Other apps

- Same area in other apps (only what cannot compile in the Cloud app): `tests/al-language-onprem/queries/`.
- Must-not-compile cases (33, in `tests/must-not-compile/cases/`, listed by `tests/must-not-compile/areas.tsv`): `0009-query-crossjoin-dataitemlink`, `0058-query-column-field-does-not-exist`, `0101-query-sibling-dataitems`, `0102-query-count-column-with-source`, `0103-query-orderby-on-dataitem`, `0108-query-sum-over-text-column`, `0109-query-average-over-date-column`, `0209-unknown-variable-query-trigger`, `0217-query-dataitem-unknown-table`, `0301-duplicate-query-column`, `0453-tableconnectiontype-query`, `0647-query-saveascsv-file-cloud`, `0648-query-saveasxml-file-cloud`, `0649-query-saveascsv-number-file-cloud`, `0650-query-saveasxml-number-file-cloud`, `0791-query-helplink-with-contextsensitivehelppage`, `0792-query-contextsensitivehelppage-without-manifest-url`, `0793-query-helplink-not-a-url`, `0794-query-entitycaption-without-api`, `0796-query-entitycaption-with-entitycaptionml`, `1375-empty-variable-and-query-names`, `1380-query-column-on-flowfilter`, `1640-query-orderby-same-column-twice`, `1641-query-column-on-flowfilter`, `1648-query-min-over-code-column`, `1649-query-max-over-date-column`, `2125-query-name-31-characters`, `2138-two-queries-same-id`, `2161-exit-value-in-query-trigger`, `2162-exit-value-in-query-procedure`, `2248-query-readstate-nolocks`, `2621-obsolete-on-query-dataitem`, `2716-bindsubscription-this-in-query`.

## Line-sensitive files

These files assert line numbers or call stacks. Only append at the end of the codeunit; never add or remove lines above existing code (standing rule 5).

- `P129CallstackQuery.al`

## Adding a test

1. Search this area for a test that already pins the behavior. If one does, cite it and write nothing.
2. Add `[Test]` procedures at the end of the existing codeunit of the topic. Make a new codeunit only for a new topic.
3. Use the shared fixtures. A local object needs a `// local object: <reason>` line.
4. Name the folder after the topic, never after a writer, an issue or a batch.
5. Never renumber a codeunit or rename a test. Read the standing rules in `CONTRIBUTING.md` first.
