# xmlports

The xmlport object: import, export, element and attribute properties.

## Topics

- (area folder itself): 21 AL files that are about the area as a whole or were not given a topic yet.
- `import/`: xmlport import (20 AL files).
- `shapes-properties/`: xmlport shapes, elements and properties (48 AL files).

A new topic gets a line here in the same pull request (standing rule 8 in CONTRIBUTING.md).

## Shared fixtures used here

- codeunit 69160 "Probe Observer": 55 files
- table 60000 "ALT Universal": 6 files
- table 60008 "ALT Blob": 4 files
- table 60004 "ALT Parent": 2 files
- table 60005 "ALT Child": 2 files
- xmlport 60025 "ALT Variable XmlPort": 2 files
- xmlport 60023 "ALT Universal XmlPort": 2 files
- xmlport 60024 "ALT Parent Child XmlPort": 1 file
- table 60002 "ALT Triggered": 1 file
- table 60003 "ALT Trigger Log": 1 file
- xmlport 67451 "ALT XPM Probe": 1 file

## Other apps

- Same area in other apps (only what cannot compile in the Cloud app): none.
- Must-not-compile cases (44, in `tests/must-not-compile/cases/`, listed by `tests/must-not-compile/areas.tsv`): `0105-xmlport-textencoding-on-xml-format`, `0106-xmlport-encoding-msdos`, `0210-unknown-variable-xmlport-trigger`, `0218-xmlport-unknown-table`, `0321-onprexmlport-in-report`, `0704-xmlport-fieldelement-tablerelation`, `0816-xmlport-requestfilterheading-and-ml`, `0819-xmlport-fieldelement-xmlname-invalid`, `0820-xmlport-fieldelement-xmlname-empty`, `0821-xmlport-fieldattribute-width-out-of-range`, `0822-xmlport-tableelement-width-out-of-range`, `0823-xmlport-textattribute-width-out-of-range`, `0824-xmlport-textelement-width-out-of-range`, `0825-xmlport-xmlversionno-invalid`, `0826-xmlport-tableelement-autocalcfield`, `1050-xmlport-fieldelement-occurrence`, `1051-xmlport-textelement-occurrence`, `1052-xmlport-tableelement-occurrence`, `1053-xmlport-fieldattribute-occurrence-invalid-value`, `1063-xmlport-linkfields-without-linktable`, `1247-unknown-bare-call-reportext-tableext-query-xmlport`, `1440-xmlport-fieldvalidate-true-false`, `1717-accessbypermission-report-query-xmlport`, `1856-xmlport-namespaces-empty-prefix`, `1857-xmlport-namespaces-string-form`, `2111-xmlport-requestpage-rec-without-sourcetable`, `2112-xmlport-trigger-rec-without-requestpage`, `2114-xmlport-requestpage-currpage`, `2126-xmlport-name-31-characters`, `2139-two-xmlports-same-id`, `2159-exit-value-in-xmlport-trigger`, `2160-exit-value-in-xmlport-procedure`, `2253-xmlport-attribute-after-child-element`, `2513-testrequestpage-typed-on-xmlport`, `2546-bare-run-page-in-xmlport`, `2620-obsolete-on-xmlport-schema-elements`, `2642-xmlport-variable-break-quit-skip`, `2643-xmlport-variable-userequestpage`, `2650-xmlport-separator-assigned-integer`, `2651-xmlport-textencoding-assigned-integer`, `2652-xmlport-separator-read-into-char`, `2715-bindsubscription-this-in-xmlport`, `2780-xmlport-defaultnamespace-variabletext`, `2781-xmlport-usedefaultnamespace-variabletext`.

## Adding a test

1. Search this area for a test that already pins the behavior. If one does, cite it and write nothing.
2. Add `[Test]` procedures at the end of the existing codeunit of the topic. Make a new codeunit only for a new topic.
3. Use the shared fixtures. A local object needs a `// local object: <reason>` line.
4. Name the folder after the topic, never after a writer, an issue or a batch.
5. Never renumber a codeunit or rename a test. Read the standing rules in `CONTRIBUTING.md` first.
