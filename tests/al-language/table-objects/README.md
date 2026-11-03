# table-objects

The table object: table and field properties, table and field triggers, table extensions, table globals.

## Topics

- (area folder itself): 12 AL files that are about the area as a whole or were not given a topic yet.
- `extensions/`: extension objects of this object type (23 AL files).
- `globals/`: table globals (3 AL files).

A new topic gets a line here in the same pull request (standing rule 8 in CONTRIBUTING.md).

## Shared fixtures used here

- codeunit 69160 "Probe Observer": 15 files
- table 60028 "ALT Relation Parent": 1 file
- table 60506 "ALT Modified": 1 file
- page 60018 "ALT Universal Ext Card Page": 1 file
- table 60003 "ALT Trigger Log": 1 file
- table 60000 "ALT Universal": 1 file
- table 60006 "ALT Keyed": 1 file

## Other apps

- Same area in other apps (only what cannot compile in the Cloud app): none.
- Must-not-compile cases (104, in `tests/must-not-compile/cases/`, listed by `tests/must-not-compile/areas.tsv`): `0006-cloud-app-onprem-table`, `0020-cloud-app-onprem-platform-tables-01`, `0021-cloud-app-onprem-platform-tables-02`, `0022-cloud-app-onprem-platform-tables-03`, `0023-cloud-app-onprem-platform-tables-04`, `0024-cloud-app-onprem-platform-tables-05`, `0030-unknown-procedure-in-table`, `0035-two-tables-same-name`, `0063-table-duplicate-field-id`, `0064-table-duplicate-field-name`, `0202-unknown-table-var`, `0206-unknown-variable-table-trigger`, `0219-table-key-unknown-field`, `0220-tablerelation-unknown-table`, `0296-duplicate-table-id`, `0297-duplicate-key-name`, `0305-sourcetable-on-codeunit`, `0306-applicationarea-on-table`, `0318-onrun-in-table`, `0359-local-procedure-of-table-via-record`, `0452-table-relation-filter-code-field`, `0480-isolated-storage-integer-key`, `0481-table-field-format-property`, `0692-tablefield-movedfrom-base-table`, `0693-tableext-field-movedfrom-invalid-guid`, `0694-table-movedto-without-obsoletestate`, `0695-table-externalschema-normal-table`, `0696-field-optionordinalvalues-normal-table`, `0697-table-type-externalsql-cloud`, `0698-tablefield-maxlength`, `0699-tableext-field-movedto-own-app`, `0766-tableext-allowincustomizations-invalid`, `0767-table-columnstoreindex-unknown-field`, `0769-tableext-drilldownpageid-unknown`, `0770-tableext-lookuppageid-unknown`, `0771-tableext-modify-masktype-invalid`, `0772-tableext-modify-width-out-of-range`, `0970-obsolete-removed-table`, `1240-cloud-app-onprem-platform-tables-bc28-bc29`, `1246-record-unknown-field-tableext-and-dependency-table`, `1370-modifyall-on-flowfield`, `1373-calcformula-cycle`, `1376-table-metadata-after-procedure`, `1385-quoted-table-id`, `1387-trigger-call-enum-chain-table-as-record`, `1394-table-with-41-keys`, `1415-tableextension-field-autoincrement`, `1417-removed-field-in-active-key`, `1419-tableextension-of-record-link`, `1420-tableextension-field-named-timestamp`, `1421-tableextension-trigger-variable-without-var`, `1423-tablerelation-unknown-table`, `1424-richcontent-on-table-field`, `1425-removed-field-in-fieldgroup`, `1427-currfieldno-outside-table-code`, `1451-setcurrentkey-key-name`, `1452-modifyall-flowfield`, `1453-get-skips-middle-key-value`, `1470-calcsums-flowfield-argument`, `1471-optimizefortextsearch-flowfield`, `1473-tablefilter-tableidexpr`, `1490-tableext-caption-and-table-caption-same-app`, `1491-tableext-key-clustered-unique`, `1492-tableext-compressiontype`, `1493-table-primary-key-includedfields`, `1494-tableext-datapercompany`, `1495-tableext-of-system-and-virtual-table`, `1496-tableext-of-not-extensible-table`, `1497-tableext-procedure-same-signature-as-table`, `1498-tableext-field-sqltimestamp`, `1499-tableext-modify-calcformula`, `1500-table-fieldgroups-before-keys`, `1540-calcformula-biginteger-field-to-integer`, `1541-calcformula-biginteger-field-to-enum`, `1542-tablerelation-biginteger-field-to-integer`, `1581-ambiguous-procedure-of-table-and-other-app-tableext`, `1696-tableext-rec-currfieldno`, `1734-flowfield-lookup-biginteger-into-enum`, `1888-modifyall-flowfield-run-trigger`, `2024-parameter-named-key`, `2032-parameter-named-fieldgroups`, `2035-parameter-named-tableelement`, `2036-parameter-named-tableextension`, `2070-ternary-in-visible-and-editable-property`, `2071-bare-call-same-name-in-third-app-tableext`, `2122-table-name-31-characters`, `2127-tableextension-name-31-characters`, `2141-two-tableextensions-same-id`, `2149-table-id-of-dependency-app`, `2150-exit-value-in-table-trigger`, `2151-exit-value-in-field-trigger`, `2152-exit-value-in-table-procedure`, `2164-exit-value-in-tableextension-trigger`, `2169-too-few-arguments-in-own-table`, `2214-tablefilter-variable`, `2234-duration-const-integer-sourcetableview`, `2235-duration-const-text-sourcetableview`, `2263-enum-type-before-field-table-only-type-enum`, `2350-flowfield-lookup-option-into-enum`, `2356-tableextension-sibling-global-not-protected`, `2370-record-locktable-assign`, `2500-table-procedure-hides-builtin-insert-arity`, `2610-cloud-azure-key-vault-onprem-scope`, `2692-table-global-named-like-field-unqualified`.

## Line-sensitive files

These files assert line numbers or call stacks. Only append at the end of the codeunit; never add or remove lines above existing code (standing rule 5).

- `P129CallstackTableExt.al`

## Adding a test

1. Search this area for a test that already pins the behavior. If one does, cite it and write nothing.
2. Add `[Test]` procedures at the end of the existing codeunit of the topic. Make a new codeunit only for a new topic.
3. Use the shared fixtures. A local object needs a `// local object: <reason>` line.
4. Name the folder after the topic, never after a writer, an issue or a batch.
5. Never renumber a codeunit or rename a test. Read the standing rules in `CONTRIBUTING.md` first.
