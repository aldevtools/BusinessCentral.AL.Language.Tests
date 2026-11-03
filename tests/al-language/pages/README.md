# pages

The page object: page triggers, parts, controls, actions, CurrPage, Run and RunModal, page properties, page extensions, application areas, page background tasks, FilterPageBuilder, lookups.

## Topics

- (area folder itself): 61 AL files that are about the area as a whole or were not given a topic yet.
- `actions/`: actions and promoted actions (8 AL files).
- `activate-new-host/`: named after its old folder; scope to be written (REVIEW) (1 AL file).
- `application-area/`: ApplicationArea (13 AL files).
- `assistedit-refresh/`: named after its old folder; scope to be written (REVIEW) (1 AL file).
- `background-tasks/`: page background tasks (2 AL files).
- `bare-page-methods/`: named after its old folder; scope to be written (REVIEW) (2 AL files).
- `changed-by-other/`: named after its old folder; scope to be written (REVIEW) (3 AL files).
- `client-features/`: named after its old folder; scope to be written (REVIEW) (1 AL file).
- `controls/`: page controls and their properties (24 AL files).
- `cue-visible/`: named after its old folder; scope to be written (REVIEW) (1 AL file).
- `currpage/`: CurrPage, Update, SetRecord, SetTableView, SetSelectionFilter (32 AL files).
- `empty-error/`: named after its old folder; scope to be written (REVIEW) (2 AL files).
- `enum-setvalue-blank/`: named after its old folder; scope to be written (REVIEW) (2 AL files).
- `expr-refresh/`: named after its old folder; scope to be written (REVIEW) (1 AL file).
- `extensions/`: extension objects of this object type (73 AL files).
- `filterpagebuilder/`: FilterPageBuilder (2 AL files).
- `fqn-missing/`: named after its old folder; scope to be written (REVIEW) (1 AL file).
- `gone-rows/`: named after its old folder; scope to be written (REVIEW) (1 AL file).
- `gone-single-move/`: named after its old folder; scope to be written (REVIEW) (1 AL file).
- `journal-batch/`: named after its old folder; scope to be written (REVIEW) (1 AL file).
- `lifecycle/`: opening, closing and page variables (1 AL file).
- `link-filter/`: named after its old folder; scope to be written (REVIEW) (2 AL files).
- `link-quoted-member/`: named after its old folder; scope to be written (REVIEW) (1 AL file).
- `list-key-moves/`: named after its old folder; scope to be written (REVIEW) (2 AL files).
- `list-order/`: named after its old folder; scope to be written (REVIEW) (5 AL files).
- `long-list-open/`: named after its old folder; scope to be written (REVIEW) (2 AL files).
- `lookups/`: Lookup and DrillDown (1 AL file).
- `modify-denied/`: named after its old folder; scope to be written (REVIEW) (1 AL file).
- `new-host-key/`: named after its old folder; scope to be written (REVIEW) (1 AL file).
- `obsolete-pending/`: named after its old folder; scope to be written (REVIEW) (1 AL file).
- `odd-667/`: named after its old folder; scope to be written (REVIEW) (3 AL files).
- `onopenpage-moves-rec/`: named after its old folder; scope to be written (REVIEW) (7 AL files).
- `opennew-findrecord/`: named after its old folder; scope to be written (REVIEW) (1 AL file).
- `or-group-page-rec/`: named after its old folder; scope to be written (REVIEW) (1 AL file).
- `page-array-path/`: named after its old folder; scope to be written (REVIEW) (1 AL file).
- `page-customization/`: named after its old folder; scope to be written (REVIEW) (1 AL file).
- `page-handler-record/`: named after its old folder; scope to be written (REVIEW) (1 AL file).
- `page-props/`: named after its old folder; scope to be written (REVIEW) (2 AL files).
- `page-summary/`: named after its old folder; scope to be written (REVIEW) (1 AL file).
- `pages-xmlport-upload-members/`: named after its old folder; scope to be written (REVIEW) (7 AL files).
- `parts/`: page parts and subpages (39 AL files).
- `properties/`: page properties (78 AL files).
- `readonly-repeater/`: named after its old folder; scope to be written (REVIEW) (1 AL file).
- `record-save/`: how a page saves its record (3 AL files).
- `refill-key/`: named after its old folder; scope to be written (REVIEW) (1 AL file).
- `row-page-var/`: named after its old folder; scope to be written (REVIEW) (1 AL file).
- `run-modal/`: Page.Run and RunModal and their results (30 AL files).
- `save-row-gone/`: named after its old folder; scope to be written (REVIEW) (1 AL file).
- `subpagelink-empty-term/`: named after its old folder; scope to be written (REVIEW) (1 AL file).
- `subpageview/`: named after its old folder; scope to be written (REVIEW) (2 AL files).
- `table-globals-page/`: named after its old folder; scope to be written (REVIEW) (1 AL file).
- `temp-list-gone-row/`: named after its old folder; scope to be written (REVIEW) (1 AL file).
- `temp-list-key-desc/`: named after its old folder; scope to be written (REVIEW) (1 AL file).
- `tree-expand-leaf/`: named after its old folder; scope to be written (REVIEW) (1 AL file).
- `triggers/`: page triggers (33 AL files).
- `values-allowed/`: named after its old folder; scope to be written (REVIEW) (1 AL file).
- `values-allowed-table-field/`: named after its old folder; scope to be written (REVIEW) (1 AL file).
- `view-filters/`: named after its old folder; scope to be written (REVIEW) (2 AL files).
- `xrec-table-procedure/`: named after its old folder; scope to be written (REVIEW) (1 AL file).

A new topic gets a line here in the same pull request (standing rule 8 in CONTRIBUTING.md).

## Shared fixtures used here

- codeunit 69160 "Probe Observer": 316 files
- table 60000 "ALT Universal": 4 files
- page 60016 "ALT List Page": 2 files
- table 60001 "ALT Composite": 1 file
- table 67698 "W3 Row": 1 file
- table 67699 "W3 Child": 1 file
- enum 60009 "ALT Status": 1 file

## Other apps

- Same area in other apps (only what cannot compile in the Cloud app): none.
- Must-not-compile cases (219, in `tests/must-not-compile/cases/`, listed by `tests/must-not-compile/areas.tsv`): `0001-pageext-nonprotected-base-var`, `0002-pageext-local-base-procedure`, `0003-pageext-procedure-same-name-as-base`, `0004-pageext-oninit-trigger`, `0017-pageext-onfindrecord-trigger`, `0018-pageext-onnextrecord-trigger`, `0031-unknown-procedure-in-page`, `0033-unknown-procedure-in-pageextension`, `0034-two-pageextensions-same-name`, `0057-pageextension-of-missing-page`, `0207-unknown-variable-page-trigger`, `0211-page-unknown-source-table`, `0212-page-field-unknown-column`, `0302-duplicate-page-action`, `0308-pagetype-on-table`, `0313-pagetype-bad-value`, `0315-initvalue-on-page-field`, `0316-onopenpage-in-codeunit`, `0317-oninsert-in-page`, `0320-onopenpage-in-table`, `0334-variable-named-area`, `0339-page-layout-without-area`, `0351-currpage-in-codeunit`, `0354-currpage-in-table`, `0540-subpageview-field-expression`, `0541-usercontrol-passed-as-controladdin`, `0680-pageext-modify-decimalplaces`, `0681-pageext-modify-drilldown`, `0682-pageext-modify-lookup`, `0683-pageext-modify-part-showfilter`, `0684-pageext-modify-part-editable`, `0685-part-updatepropagation-invalid-value`, `0686-pageext-modify-part-updatepropagation`, `0687-page-dataaccessintent-card`, `0688-page-ispreview-card`, `0689-customaction-flow-without-flowid`, `0690-customaction-type-invalid-value`, `0691-fileuploadaction-scope-invalid-value`, `0711-obsoletestate-removed-page-controls`, `0712-obsoletestate-removed-page-extension`, `0768-table-linkedintransaction-without-linkedobject`, `0777-obsoletestate-on-page-areas-bc28`, `0778-obsoletestate-on-page-areas-bc29`, `0797-obsoletestate-removed-page-elements`, `0799-obsoletestate-on-page-areas`, `0840-page-helplink-with-contextsensitivehelppage`, `0841-page-contextsensitivehelppage-without-manifest-url`, `0842-page-entitycaption-with-ml`, `0843-page-entitysetcaption-with-ml`, `0844-page-promotedactioncategories-with-ml`, `0845-pageext-additionalsearchterms-with-ml`, `0846-page-promptmode-invalid-value`, `0847-page-promptdialog-extensible`, `0848-page-helplink-invalid-url`, `0849-pageext-modify-decimalplaces`, `0850-pageext-modify-drilldown`, `0851-pageext-modify-lookup`, `0852-pageext-modify-part-showfilter`, `0853-pageext-modify-part-updatepropagation`, `0854-pageext-cardpageid-unknown-page`, `0855-pageext-modify-lookuppageid-unknown-page`, `0856-pageext-modify-masktype-invalid`, `0857-pageext-modify-style-invalid`, `0858-pageext-modify-width-negative`, `0860-pagecustomization-editable-true-without-allow`, `0861-pagecustomization-clearviews-on-card`, `0862-pagecustomization-importance-invalid`, `0863-pagecustomization-masktype-invalid`, `0864-pagecustomization-width-negative`, `0865-pagecustomization-editable-expression`, `0866-pagecustomization-modify-unknown-control`, `0868-pageext-modify-quickentry-expression`, `0869-pageext-modify-blankzero-on-text-field`, `0870-pageext-modify-optioncaptionml-on-text-field`, `0883-field-navigationpageid-card-page`, `0884-field-navigationpageid-unknown-page`, `0888-part-multiplicity-invalid-value`, `0889-part-multiplicity-card-page`, `0890-part-entityname-invalid-name`, `0891-part-entitysetname-invalid-name`, `0892-part-provider-unknown-part`, `0893-part-updatepropagation-invalid-value`, `0894-part-fileuploadaction-unknown-action`, `0895-view-sharedlayout-invalid-value`, `0896-action-gesture-invalid-value`, `0897-group-showas-invalid-value`, `0899-customaction-scope-invalid-value`, `0900-customaction-flowcaption-on-flow-type`, `0901-customaction-flowtemplateid-not-guid`, `0902-customaction-flowenvironmentid-without-type`, `0903-fileuploadaction-gesture-invalid-value`, `0904-fileuploadaction-infooterbar-invalid-value`, `0905-cuegroup-layout-invalid-value`, `0906-group-cuegrouplayout-on-group`, `0907-repeater-cuegrouplayout-on-repeater`, `0908-grid-layout-invalid-value`, `0909-group-gridlayout-on-group`, `0910-repeater-gridlayout-on-repeater`, `0911-repeater-freezecolumn-unknown-field`, `0912-group-freezecolumn-on-group`, `0913-repeater-indentationcontrols-unknown-control`, `0914-group-indentationcontrols-on-group`, `0915-repeater-fileuploadrowaction-on-group`, `0916-group-treeinitialstate-on-group`, `0917-repeater-treeinitialstate-invalid-value`, `0918-repeater-fileuploadaction-unknown-action`, `0919-repeater-fileuploadrowaction-unknown-action`, `0920-cuegroup-freezecolumn`, `0921-cuegroup-gridlayout`, `0922-cuegroup-indentationcolumn`, `0923-cuegroup-indentationcontrols`, `0924-cuegroup-indentationcontrols-unknown`, `0925-cuegroup-treeinitialstate`, `0926-cuegroup-layout-medium`, `0927-cuegroup-layout-small`, `0928-cuegroup-layout-invalid`, `0929-cuegroup-fileuploadaction-unknown`, `0930-cuegroup-fileuploadrowaction`, `0931-fixed-cuegrouplayout`, `0932-fixed-freezecolumn`, `0933-fixed-gridlayout`, `0934-fixed-indentationcolumn`, `0935-fixed-indentationcontrols`, `0936-fixed-treeinitialstate`, `0937-fixed-fileuploadaction-unknown`, `0938-fixed-fileuploadrowaction`, `0939-grid-cuegrouplayout`, `0940-grid-freezecolumn`, `0941-grid-indentationcolumn`, `0942-grid-indentationcontrols`, `0943-grid-treeinitialstate`, `0944-grid-gridlayout-invalid`, `0945-grid-fileuploadaction-unknown`, `0946-grid-fileuploadrowaction`, `0947-pageext-modify-field-oncontroladdin`, `0989-pagestyle-greater-than`, `1060-repeater-indentationcolumn-decimal`, `1061-repeater-indentationcolumn-text`, `1062-repeater-indentationcolumn-option`, `1090-currpage-promptmode-lookup`, `1091-group-applicationarea`, `1241-pageext-non-page-triggers`, `1252-group-cuegrouplayout`, `1253-group-fileuploadrowaction`, `1259-repeater-cuegrouplayout`, `1260-repeater-gridlayout`, `1261-systempart-subpagelink`, `1262-systempart-subpageview`, `1263-pageext-contextsensitivehelppage-without-manifest-url`, `1270-pageextension-addfirst-unknown-area`, `1280-pageextension-insertallowed-variable`, `1281-page-insertallowed-expression`, `1290-page-editable-expression`, `1340-page-run-fqn-fieldno-return-value`, `1360-pageext-listpart-implicit-creation-area`, `1403-page-field-source-enum-object-name`, `1412-local-procedure-through-own-object-handle`, `1413-internal-procedure-of-another-app`, `1414-same-procedure-in-two-extensions-of-one-target`, `1430-api-page-field-control-names`, `1431-page-field-importance-optional`, `1432-styleexpr-pagestyle-variable`, `1433-page-field-and-action-same-name`, `1434-page-action-group-and-action-same-name`, `1436-decimalplaces-on-integer-page-field`, `1438-runpagelink-text-to-option-and-enum`, `1446-page-field-bare-systemid-noimplicitwith`, `1501-pageext-modify-part-applicationarea`, `1502-pageext-of-rolecenter-triggers`, `1503-pageext-modify-editable-procedure-call`, `1580-pageext-protected-var-type-from-unreferenced-app`, `1610-rolecenter-action-onaction`, `1616-chartpart-not-supported`, `1690-page-action-and-group-same-name`, `1865-systempart-subpagelink-subpageview`, `1866-pageextension-contextsensitivehelppage`, `2000-control-visible-enabled-procedure-call`, `2026-parameter-named-actions`, `2027-parameter-named-chartpart`, `2028-parameter-named-cuegroup`, `2033-parameter-named-pageextension`, `2123-page-name-31-characters`, `2128-pageextension-name-31-characters`, `2136-two-pages-same-id`, `2142-two-pageextensions-same-id`, `2153-exit-value-in-page-trigger`, `2154-exit-value-in-page-procedure`, `2155-exit-value-in-page-action`, `2165-exit-value-in-pageextension-procedure`, `2238-pageext-local-same-name-as-protected-base-bare-call`, `2239-pageext-local-same-name-as-public-base-bare-call`, `2240-pageext-local-same-name-as-internal-base-bare-call`, `2241-pageext-protected-same-name-as-protected-base`, `2242-pageext-public-same-name-as-public-base`, `2243-pageext-protected-same-name-as-public-base`, `2244-pageext-internal-same-name-as-protected-base-bare-call`, `2261-pageext-calls-base-page-usercontrol`, `2264-enum-type-before-field-page-only-type-enum`, `2276-subpagelink-const-enum-unknown-value`, `2277-subpagelink-const-enum-unknown-bare-value`, `2290-pageext-addafter-unknown-group`, `2351-pageextension-factboxes-on-listpart`, `2352-pageextension-factboxes-on-cardpart`, `2353-pageextension-factboxes-on-rolecenter`, `2354-pageextension-factboxes-on-headlinepart`, `2510-subpagelink-field-filter-unknown-field`, `2511-subpagelink-field-filter-const`, `2512-subpagelink-filter-field-reversed`, `2543-bare-run-page-in-codeunit`, `2544-bare-run-page-in-table`, `2547-bare-run-page-result-used`, `2625-pageext-category-group-out-of-range`, `2626-pageext-promoted-ref-of-unpromoted-action`, `2627-pageext-modify-implicit-promoted-caption`, `2630-cuegroup-visible-integer`, `2632-field-visible-method-call`, `2755-page-field-onbeforevalidate-trigger`, `2756-page-varfield-onbeforevalidate-trigger`, `2765-subpageview-field-condition`.

## Adding a test

1. Search this area for a test that already pins the behavior. If one does, cite it and write nothing.
2. Add `[Test]` procedures at the end of the existing codeunit of the topic. Make a new codeunit only for a new topic.
3. Use the shared fixtures. A local object needs a `// local object: <reason>` line.
4. Name the folder after the topic, never after a writer, an issue or a batch.
5. Never renumber a codeunit or rename a test. Read the standing rules in `CONTRIBUTING.md` first.
