# _fixtures

Shared objects only: tables, pages, reports, xmlports, queries, codeunits, events, enums, interfaces, permission sets and report layouts that many test codeunits use. A shared fixture never changes once merged.

## Topics

- (area folder itself): 29 AL files that are about the area as a whole or were not given a topic yet.
- `enums/`: shared enum fixtures (3 AL files).
- `events/`: record and table events seen from the record (25 AL files).
- `interfaces/`: interfaces (1 AL file).
- `pages/`: shared page fixtures (16 AL files).
- `queries/`: shared query fixtures (3 AL files).
- `reports/`: shared report fixtures (3 AL files).
- `tables/`: shared table fixtures (36 AL files; `ALTShapeTables.al` holds the 30 shape tables).
- `xmlports/`: shared xmlport fixtures (10 AL files).

A new topic gets a line here in the same pull request (standing rule 8 in CONTRIBUTING.md).

## Objects

- codeunit 50302 "LT UR Install Low"
- codeunit 60014 "ALT Event Publisher"
- codeunit 60015 "ALT Event Subscriber"
- codeunit 60016 "ALT Table Event Subscriber"
- codeunit 60017 "ALT Internal Fanout Sub"
- codeunit 60020 "ALT Internals Subscriber"
- codeunit 60025 "ALT Global Trigger Sub"
- codeunit 60030 "ALT Event Mutation Control"
- codeunit 60031 "ALT Event Mutation Sub"
- codeunit 60032 "ALT Standard Table Mut"
- codeunit 60033 "ALT Manual Event Sub"
- codeunit 60034 "ALT Manual Table Event Sub"
- codeunit 60036 "ALTImplicitReturnProbe"
- codeunit 60049 "ALTImplicitReturnCallee"
- codeunit 60138 "ALT Inherent Perm Probe"
- codeunit 60287 "ALT Inherent Ent Probe"
- codeunit 60288 "ALT Namespaced Probe"
- codeunit 60366 "ALTTryFunctionNoExitProbe"
- codeunit 60591 "ALT Subscribed Table Sub"
- codeunit 60633 "ALT Page Evt Sub"
- codeunit 60634 "ALT Page Evt Manual Sub"
- codeunit 60635 "ALT Page Evt Veto Sub"
- codeunit 60828 "ALT Quoted Install Probe"
- codeunit 60829 "ALT Quoted Upgrade Probe"
- codeunit 60838 "ALT Install Probe"
- codeunit 60949 "ALT ManualTableEvt Ctrl Sub"
- codeunit 60963 "ALT Codeunit Meta Probe"
- codeunit 60967 "ALT IncludeSender Cu Pub"
- codeunit 60968 "ALT IncludeSender Event Sub"
- codeunit 60970 "ALT Sender Position Pub"
- codeunit 60971 "ALT Sender Position Sub"
- codeunit 60985 "ALT ManualObjEvt Ctrl Sub"
- codeunit 67371 "ALT Manual Sub Passer"
- codeunit 67372 "ALT SI Manual Event Sub"
- codeunit 67581 "ALT IS Store Subscriber"
- codeunit 67690 "ALT SI Bind Publisher"
- codeunit 67691 "ALT SI Bind Survivor"
- codeunit 67692 "ALT Plain Bind Contrast"
- codeunit 67695 "ALT SI Held Binder"
- codeunit 67696 "ALT SI Held Subscriber"
- codeunit 67697 "ALT SI Session Witness"
- codeunit 67702 "W3 Runner"
- codeunit 67703 "W3 Dataset"
- codeunit 69160 "Probe Observer"
- codeunit 69163 "Probe Observer State"
- enum 60009 "ALT Status"
- enum 60010 "ALT Color"
- enum 60910 "ALT Caption Kind"
- page 60016 "ALT List Page"
- page 60017 "ALT Card Page"
- page 60018 "ALT Universal Ext Card Page"
- page 60020 "ALT Triggered Card Page"
- page 60414 "ALT Run Tx None Card"
- page 60425 "ALT Control Defaults Page"
- page 60427 "ALT Control Tree Page"
- page 60521 "PCX List"
- page 60632 "ALT Page Evt Rows"
- page 60821 "ALT Source Table View List"
- page 60879 "ALT Prompt Dialog Page"
- page 60901 "ALT Page Properties Page"
- page 60902 "ALT Page Properties Api Page"
- page 60977 "ALT Manual PageEvent Pub"
- page 60994 "ALT Source Object Props Page"
- page 60995 "ALT Source Object Flags Page"
- permissionset 60023 "ALT NonAssignable"
- permissionset 60024 "ALT Undecl Assign"
- permissionset 67945 "ALT ExpPerm Leaf"
- permissionset 67946 "ALT ExpPerm Comp"
- query 60022 "ALT Universal Query"
- query 60023 "ALT Separator Caption Query"
- query 60981 "ALT Manual QueryEvent Pub"
- report 60018 "ALT Simple Report"
- report 60412 "ALT Run Tx None Rep Inserter"
- report 60978 "ALT Manual ReportEvent Pub"
- table 50000 "ALT Shape 00"
- table 50001 "ALT Shape 01"
- table 50002 "ALT Shape 02"
- table 50003 "ALT Shape 03"
- table 50004 "ALT Shape 04"
- table 50005 "ALT Shape 05"
- table 50006 "ALT Shape 06"
- table 50007 "ALT Shape 07"
- table 50008 "ALT Shape 08"
- table 50009 "ALT Shape 09"
- table 50010 "ALT Shape 10"
- table 50011 "ALT Shape 11"
- table 50012 "ALT Shape 12"
- table 50013 "ALT Shape 13"
- table 50014 "ALT Shape 14"
- table 50015 "ALT Shape 15"
- table 50016 "ALT Shape 16"
- table 50017 "ALT Shape 17"
- table 50018 "ALT Shape 18"
- table 50019 "ALT Shape 19"
- table 50020 "ALT Shape 20"
- table 50021 "ALT Shape 21"
- table 50022 "ALT Shape 22"
- table 50023 "ALT Shape 23"
- table 50024 "ALT Shape 24"
- table 50025 "ALT Shape 25"
- table 50026 "ALT Shape 26"
- table 50027 "ALT Shape 27"
- table 50028 "ALT Shape 28"
- table 50029 "ALT Shape 29"
- table 60000 "ALT Universal"
- table 60001 "ALT Composite"
- table 60002 "ALT Triggered"
- table 60003 "ALT Trigger Log"
- table 60004 "ALT Parent"
- table 60005 "ALT Child"
- table 60006 "ALT Keyed"
- table 60007 "ALT Base"
- table 60008 "ALT Blob"
- table 60009 "ALT Rename Key Parent"
- table 60010 "ALT Rename Key Child"
- table 60011 "ALT Rename Key Trig Child"
- table 60012 "ALT Rename Tenant Parent"
- table 60013 "ALT Rename Company Child"
- table 60023 "ALT Error Trigger"
- table 60024 "ALT Init Value"
- table 60025 "ALT Temp Only"
- table 60026 "ALT Separator Captioned"
- table 60028 "ALT Relation Parent"
- table 60029 "ALT Relation Child"
- table 60030 "ALT Relation Parent B"
- table 60291 "ALT CRM Entity"
- table 60404 "ALT Reten Pol Owned"
- table 60480 "ALT Rel Where Parent"
- table 60481 "ALT Rel Where Child"
- table 60483 "ALT Rel Field Class"
- table 60505 "ALT Case Enum"
- table 60506 "ALT Modified"
- table 60520 "PCX Row"
- table 60590 "ALT No Subscriber Table"
- table 60593 "ALT Subscribed Table"
- table 60631 "ALT Page Evt Row"
- table 60830 "ALT Captioned"
- table 60837 "ALT Unclassified"
- table 60966 "ALT IncludeSender Table Pub"
- table 60976 "ALT Manual TableEvent Pub"
- table 60980 "ALT Media"
- table 60990 "Shipping Agent"
- table 60991 "Config. Package Table"
- table 67020 "ALT TableFilter Holder"
- table 67021 "ALT TF Plain Target"
- table 67698 "W3 Row"
- table 67699 "W3 Child"
- table 67700 "W3 Marker"
- table 67701 "W3 Param"
- table 69162 "Probe Observer Entry"
- table 69200 "ALT Rel Same NS"
- table 69201 "ALT Rel Usings"
- table 69202 "ALT Rel Same NS Mod"
- table 69203 "ALT Rel Usings Mod"
- table 69214 "ALT Rel Third"
- table 69215 "ALT Rel Third Mod"
- table 69222 "ALT Rel OwnDep"
- table 69223 "ALT Rel OwnDep Mod"
- table 69226 "ALT Rel OwnBundle"
- table 69227 "ALT Rel OwnBundle Mod"
- table 69229 "ALT Rel OwnDep IO"
- table 69230 "ALT Rel OwnDep IO Mod"
- xmlport 60023 "ALT Universal XmlPort"
- xmlport 60024 "ALT Parent Child XmlPort"
- xmlport 60025 "ALT Variable XmlPort"
- xmlport 60026 "ALT Universal Update XmlPort"
- xmlport 60027 "ALT Universal Replace XmlPort"
- xmlport 60028 "ALT Universal Manual XmlPort"
- xmlport 60029 "ALT Temp Universal XmlPort"
- xmlport 60413 "ALT Run Tx None XmlPort"
- xmlport 60982 "ALT Manual XmlPortEvent Pub"
- xmlport 67451 "ALT XPM Probe"

Shared fixtures are frozen once merged: never change their fields, keys or triggers. Add a new one instead (ids 50000..50999), with a line here.

## Shape tables

`tables/ALTShapeTables.al` holds 30 plain tables, `ALT Shape 00` to `ALT Shape 29` (50000-50029). Each has one exact field
shape: field types, lengths and names in field-number order, the primary key `PK` on field 1, no triggers, no other keys and
no properties besides DataClassification. A test whose own table has exactly this shape and nothing else uses the shape table
(standing rule 2). Codeunit isolation gives each test codeunit an empty table; `ALTFixtureCleanup.Initialize` clears them too.
Keep a local table when the test can see its name, id or caption (error texts, RecordId, TableCaption), when it is extended,
has an event subscriber, sits in a namespace, or when one test codeunit would need two tables of the same shape.

| table | id | fields |
|---|---:|---|
| ALT Shape 00 | 50000 | Integer Id |
| ALT Shape 01 | 50001 | Integer Id; Text[30] Name |
| ALT Shape 02 | 50002 | Code[20] No.; Text[50] Descr |
| ALT Shape 03 | 50003 | Integer Id; Blob Data |
| ALT Shape 04 | 50004 | Code[20] No.; Text[50] Name |
| ALT Shape 05 | 50005 | Code[20] No. |
| ALT Shape 06 | 50006 | Integer Id; Text[20] Name |
| ALT Shape 07 | 50007 | Code[10] Code |
| ALT Shape 08 | 50008 | Code[20] Code; Text[50] Descr |
| ALT Shape 09 | 50009 | Code[20] Code |
| ALT Shape 10 | 50010 | Integer Id; Text[20] Info |
| ALT Shape 11 | 50011 | Integer Id; Text[30] Txt |
| ALT Shape 12 | 50012 | Integer Id; Boolean Flag |
| ALT Shape 13 | 50013 | Integer Id; Text[100] Txt |
| ALT Shape 14 | 50014 | Code[10] Code; Text[20] Name |
| ALT Shape 15 | 50015 | Integer Id; Code[10] Grp |
| ALT Shape 16 | 50016 | Integer Id; Integer Amount |
| ALT Shape 17 | 50017 | Integer Id; Text[250] Txt |
| ALT Shape 18 | 50018 | Integer Id; Text[50] Name |
| ALT Shape 19 | 50019 | Integer Entry No.; Code[20] Header No.; Decimal Amount; Date Posting Date |
| ALT Shape 20 | 50020 | Code[10] Code; Text[30] Name |
| ALT Shape 21 | 50021 | Integer Entry No.; Text[50] Name |
| ALT Shape 22 | 50022 | Code[20] No.; Decimal Amount |
| ALT Shape 23 | 50023 | Integer Id; Integer ParentId |
| ALT Shape 24 | 50024 | Integer Id; Text[30] Note |
| ALT Shape 25 | 50025 | Integer Id; Text[50] Note |
| ALT Shape 26 | 50026 | Code[20] No.; Integer Qty |
| ALT Shape 27 | 50027 | Code[20] No.; Text[30] Name |
| ALT Shape 28 | 50028 | Integer Entry No. |
| ALT Shape 29 | 50029 | Integer Entry No.; Text[50] Trigger Name |

## Other apps

- Same area in other apps (only what cannot compile in the Cloud app): none.

## Adding a test

1. Search this area for a test that already pins the behavior. If one does, cite it and write nothing.
2. Add `[Test]` procedures at the end of the existing codeunit of the topic. Make a new codeunit only for a new topic.
3. Use the shared fixtures. A local object needs a `// local object: <reason>` line.
4. Name the folder after the topic, never after a writer, an issue or a batch.
5. Never renumber a codeunit or rename a test. Read the standing rules in `CONTRIBUTING.md` first.

- `TblLexicalOwner.al`: extension-side lexical binding fixture over the dedicated `TBL Lexical Owner Base` dependency table; reset by `ALTFixtureCleanup.Initialize()`.
- `PagTriggerCloseParts.al`: temporary parent/part lifecycle observation fixtures; the dedicated log is used by the existing parts-after-close topic codeunit. Bootstrap observations are unqualified until complete native capture and stable assertions.
