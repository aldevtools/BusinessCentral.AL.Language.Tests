# reports

The report object: running, dataset and data items, request pages, layouts and SaveAs, report extensions.

## Topics

- (area folder itself): 98 AL files that are about the area as a whole or were not given a topic yet.
- `bare-report-member/`: report members used without a variable (1 AL file).
- `dataset/`: datasets, data items and columns (14 AL files).
- `extension-settableview/`: SetTableView of report extensions (2 AL files).
- `extensions/`: extension objects of this object type (10 AL files).
- `layouts-saveas/`: layouts, rendering and Report.SaveAs* (34 AL files).
- `reporthandler/`: ReportHandler and processing-only request pages (6 AL files).
- `request-page/`: request pages (69 AL files).
- `runtime/`: running a report and its members (35 AL files).

A new topic gets a line here in the same pull request (standing rule 8 in CONTRIBUTING.md).

## Shared fixtures used here

- codeunit 69160 "Probe Observer": 171 files
- table 67698 "W3 Row": 15 files
- codeunit 67703 "W3 Dataset": 8 files
- codeunit 67702 "W3 Runner": 8 files
- table 67700 "W3 Marker": 6 files
- table 67699 "W3 Child": 5 files
- table 60000 "ALT Universal": 4 files
- table 60004 "ALT Parent": 3 files
- table 60005 "ALT Child": 2 files
- report 60018 "ALT Simple Report": 1 file
- table 67701 "W3 Param": 1 file

## Other apps

- Same area in other apps (only what cannot compile in the Cloud app): `tests/al-language-onprem/reports/`.
- Must-not-compile cases (85, in `tests/must-not-compile/cases/`, listed by `tests/must-not-compile/areas.tsv`): `0013-executionmode-report-does-not-exist`, `0032-unknown-procedure-in-report`, `0040-reportext-nonprotected-base-var`, `0041-reportext-local-base-procedure`, `0042-reportext-procedure-same-signature-as-base`, `0062-report-column-duplicate-name`, `0121-this-extension-variable-in-reportextension`, `0122-this-nonprotected-base-variable-in-reportextension`, `0123-bindsubscription-this-in-report`, `0208-unknown-variable-report-trigger`, `0216-report-dataitem-unknown-table`, `0307-editable-on-report`, `0319-onprereport-in-codeunit`, `0352-currreport-in-codeunit`, `0355-rec-in-report`, `0660-report-static-saveas-file`, `0661-report-instance-saveas-file`, `0664-fqn-overloads-bc27`, `0701-report-column-width`, `0702-report-label-captionclass`, `0703-report-rdlclayout-with-rendering`, `0707-report-inherentpermissions-invalid-kind`, `0709-obsoletestate-removed-object-kinds`, `0713-obsoletereason-without-pending`, `0724-subscribe-reporting-printer-name-extra-parameter`, `0798-obsoletestate-removed-other-elements`, `0800-report-defaultheaderfooterpart-bc27-28`, `0801-report-defaultthemepart-bc27-28`, `0802-layout-headerfooterpart-bc27-28`, `0803-layout-subtype-bc27-28`, `0804-layout-themepart-bc27-28`, `0805-layout-subtype-rdlc`, `0806-report-enableexternalassemblies-cloud`, `0807-report-papersourcefirstpage-invalid`, `0808-report-papersourcedefaultpage-invalid`, `0809-report-papersourcelastpage-invalid`, `0810-report-pdffontembedding-invalid`, `0811-report-formatregion-empty`, `0812-requestpage-contextsensitivehelppage-no-manifest`, `0813-requestpage-helplink-and-contextsensitivehelppage`, `0814-requestpage-helplink-invalid-url`, `0815-requestpage-cardpageid-unknown-page`, `0817-report-additionalsearchtermsml-duplicate-language`, `0818-report-additionalsearchtermsml-invalid-language`, `0948-reportext-requestpage-onfindrecord`, `0949-reportext-requestpage-onnextrecord`, `0950-reportext-requestpage-rec-access`, `0977-indataset-on-procedure`, `1121-report-rendering-without-defaultrenderinglayout`, `1122-report-column-name-with-space`, `1180-report-layout-obsoletestate-removed`, `1243-table-page-report-duplicate-procedure`, `1248-two-tableextensions-and-two-reportextensions-same-name`, `1439-requestpage-action-runpageview`, `1441-report-column-clashes-with-format-column`, `1656-report-trigger-requestpage-part`, `1672-reportext-modify-dataitem-onaftergetrecord`, `2082-namespace-report-dataitem-integer-without-using`, `2110-report-requestpage-rec-without-sourcetable`, `2113-report-trigger-rec-without-sourcetable`, `2124-report-name-31-characters`, `2129-reportextension-name-31-characters`, `2137-two-reports-same-id`, `2144-two-reportextensions-same-id`, `2156-exit-value-in-report-trigger`, `2157-exit-value-in-report-dataitem-trigger`, `2158-exit-value-in-report-procedure`, `2340-reportextension-addafter-top-level-dataitem`, `2505-report-bare-preview`, `2506-report-bare-skip`, `2507-report-bare-quit`, `2508-report-bare-pageno-totalscausedby`, `2509-report-bare-showoutput-newpage-createtotals`, `2514-currreport-requestoptionspage`, `2525-reportext-addlast-content-empty-requestpage-same-app`, `2545-bare-run-page-in-report`, `2580-currreport-requestoptionspage-oninitreport`, `2581-currreport-requestoptionspage-onprereport`, `2582-currreport-requestoptionspage-onpostreport`, `2583-currreport-requestoptionspage-onpredataitem`, `2584-currreport-requestoptionspage-dataitem-aftergetrecord`, `2622-reportext-requestpage-calls-base-local-procedure`, `2623-reportext-requestpage-local-not-visible-outside`, `2624-reportext-local-same-name-as-public-base`, `2691-report-global-named-like-dataitem`.

## Line-sensitive files

These files assert line numbers or call stacks. Only append at the end of the codeunit; never add or remove lines above existing code (standing rule 5).

- `dataset/ReportDatasetHeaderRaw.al`
- `request-page/RptFilters.al`
- `request-page/Y86LayoutStreams.al`

## Adding a test

1. Search this area for a test that already pins the behavior. If one does, cite it and write nothing.
2. Add `[Test]` procedures at the end of the existing codeunit of the topic. Make a new codeunit only for a new topic.
3. Use the shared fixtures. A local object needs a `// local object: <reason>` line.
4. Name the folder after the topic, never after a writer, an issue or a batch.
5. Never renumber a codeunit or rename a test. Read the standing rules in `CONTRIBUTING.md` first.
