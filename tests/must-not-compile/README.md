# Must-not-compile corpus

Each file in `cases/` is a small AL file that the real AL compiler REJECTS. The file records the diagnostic(s) the compiler gives, so a
runtime that claims to accept or refuse AL source can be held to the same verdict as real Business Central (`code AL0161` and the text, not a
guess). The corpus is not an app: every file is compiled alone, in a fresh one-file project.

## One case = one file

`cases/NNNN-short-name.al`, numbered in the order they were added. The file holds every object the case needs (the base page and the extension
that fails, the table, ...); object ids use 50000 to 59999, names start with `MNC`.

The header is the run of `//` comment lines at the top. A line `// @key value` is machine readable, any other comment line is for people.

| line | meaning |
|---|---|
| `// @expect AL0161 \| 'Hidden' is inaccessible due to its protection level` | one expected diagnostic: code, then the text. Repeat the line for several diagnostics. The recorded text must be the START of the compiler's text (the compilers differ in the explanation they append), and the diagnostics found must match the `@expect` lines exactly, none missing, none extra. |
| `// @target OnPrem` | the app's target; default `Cloud`. |
| `// @depends Base Application,System Application` | the dependencies; this is the default (names are `Base Application` and `System Application`). A cross-app case may also name the corpus apps `AL Internals Test Fixture`, `AL Language XApp A`, `AL Language XApp B` and `AL Language XApp C` (CONTRIBUTING.md, "Multi-app fixtures"); their compiled `.app` files, and those of their dependencies, must then be in the `--symbols` folder. |
| `// @appjson {"assemblyProbingPaths": ["./x"]}` | JSON merged into the generated app.json (for diagnostics about app.json). |
| `// @from 27` / `// @until 28` | the BC majors the verdict holds for (default all). |
| `// @max-al 17` | the case is skipped with a compiler newer than this AL major (the verdict is that of the AL 16 and 17 compilers; AL 18 and later accept the file). |
| `// @min-al 18` | the case is skipped with a compiler older than this AL major (AL 16 and 17 report AL0451 for a `dotnet` block before they reach the real error). |

The expected `AL` code and text are for the compiler of that BC major; where two majors differ, write two files (with `@from`/`@until`).

## How a case is checked

`.github/scripts/check-must-not-compile.py --al "<AL command>" --symbols <dir of .app symbol packages> --bc-major 27 [--al-major 16]` builds for
each file a project with a generated `app.json` (`runtime` 16.1 for BC 27, 17.1 for BC 28, 18.0 for BC 29, or `--runtime`; platform and application 27.0.0.0 unless `@appjson` says otherwise) and the file as
`src/case.al`, runs `AL compile /project:... /packagecachepath:... /out:... /define:BC<major>PLUS`, and requires: the compiler exits with errors, no
package is written, and the `error ALxxxx: text` lines equal the `@expect` lines. `.github/scripts/test-must-not-compile.py` tests the parsing and the
comparison without a compiler (it runs in the existing self-test job).

## For the runtime

The format is plain text on purpose. A runtime reads a case with: the header lines (`// @expect CODE | text`) and the rest of the file as source.
For every case the runtime should refuse the source (not run it) with a diagnostic whose code is the recorded one; the text is the compiler's and
is only a reference.

## Cases so far

| file | code | what |
|---|---|---|
| 0001 | AL0161 | page extension names a non-protected variable of its base page |
| 0002 | AL0161 | page extension calls a local procedure of its base page |
| 0003 | AL0440 | page extension procedure with the signature of a base page procedure |
| 0004 | AL0162 | OnInit trigger in a page extension |
| 0005 | AL0118 | `CreateSequentialGuid` does not exist |
| 0006 | AL0296 | Cloud app names a Scope = OnPrem table |
| 0007 | AL0124 | `assemblyProbingPaths` in app.json at runtime 16.0 |
| 0008 | AL0175 | `=` between two DotNet class objects (OnPrem, AL 18+) |
| 0009 | AL0365 | `DataItemLink` on a query data item with `SqlJoinType = CrossJoin` |
| 0010 to 0013 | AL0132 | `ExecutionMode::Install`, `Uninstall`, `Upgrade` and `Report` do not exist (only Standard and Debug) |
| 0014 | AL0296 | Cloud app names the Scope = OnPrem table `API Webhook Entity` |
| 0015 | AL0385 | `IncludeCaption` on a report column whose source is an expression |
| 0016 | AL0197 | two codeunits of the same name (one diagnostic per declaration) |
| 0017, 0018 | AL0162 | `OnFindRecord` and `OnNextRecord` in a page extension (every other page trigger, 12 of them, compiles in an extension: see tests/al-language/pageext/POPageExtTriggers.al) |
| 0019 | AL0132 | `ExecutionMode::Profile` does not exist |
| 0020 to 0024 | AL0296 (and AL0433 for removed tables) | all 123 platform tables of System.app with Scope = OnPrem named from a Cloud app, 30 per case; symbols of BC 27.0 only (`@from 27`, `@until 27`) |
| 0030 to 0033 | AL0118 | an unknown bare procedure name inside a table, a page, a report and a page extension |
| 0034, 0035 | AL0197 | two page extensions / two tables of the same name |
| 0036 | AL0264 | two codeunits with the same id |
| 0040 to 0042 | AL0161, AL0161, AL0440 | report extension forms of cases 0001 to 0003 |
| 0043 | AL0440 | two procedures with the same parameter types in one codeunit |
| 0044 | AL0121 | a variable declared twice |
| 0045, 0046 | AL0155, AL0231 | an enum with a duplicate value name / ordinal |
| 0047 | AL0280 | an event subscriber for an event the publisher does not have |
| 0048 | AL0139 | `exit(1)` in a procedure without a return value |
| 0049 | AL0499 | `HandlerFunctions` naming a procedure that does not exist |
| 0050 | AL0582 | a codeunit implements an interface and lacks a member |
| 0051 | AL0130 | a literal passed for a `var` parameter |
| 0053 | AL0111 | a statement without its semicolon |
| 0054, 0055 | AL0297, AL0305 | object id outside the `idRanges` of app.json / object name longer than 30 characters |
| 2115 | AL0305 | a test codeunit name of 31 characters, one over the limit (30 compiles: tests/al-language/codeunit/TestScopeIsolationContracts.al) |
| 0056 | AL0152 | an Option variable that repeats a member |
| 0057 | AL0247 | a page extension of a page that does not exist |
| 0058 | AL0345, AL0353 | a query column over a field the table lacks |
| 0059 | AL0118 | `Rec` in a codeunit without `TableNo` |
| 0060, 0061 | AL0132 | a field / a method that a Record does not have |
| 0062, 0063, 0064 | AL0155, AL0206, AL0155 | a report column / table field id / table field name declared twice |
| 0065, 0068 | AL0244 | a `[Test]` procedure or a `[TryFunction]` with a return value |
| 0066, 0067 | AL0135, AL0126 | too few / too many arguments |
| 0069, 0070 | AL0122 | Integer to Text and Text to Integer assignment |
| 0071 to 0073 | AL0124 | `assemblyProbingPaths` at runtime 15.0, 16.1 and 17.0 (16.1 and 17.0 need AL 17 or newer) |
| 0074, 0075 | AL0122 | an enum assigned to an enum of another type whose TARGET lacks `AssignmentCompatibility` (the source's flag does not help) |
| 0076 | AL0126 | `Media.ImportStream` with a file name as a fourth argument (BC 27 has three) |
| 0100 | AL0390 | A DateFormula field whose InitValue is not a date formula. |
| 0101 | AL0342 | A query with two dataitems nested under the same parent dataitem (siblings). |
| 0102 | AL0353 | A query column with Method = Count that names a source field. |
| 0103 | AL0124 | OrderBy written on a query dataitem (it belongs to the query object). |
| 0105 | AL0167 | TextEncoding on an xmlport whose Format is Xml (it needs VariableText or FixedText). |
| 0106 | AL0169 | Encoding = MSDOS on an xmlport (Encoding takes UTF8 or UTF16). |
| 0107 | AL0132 | Text has no Length method (StrLen is the function). |
| 0108 | AL0347 | A query column with Method = Sum over a Text field. |
| 0109 | AL0347 | A query column with Method = Average over a Date field. |
| 0110 | AL0296 | GetLastErrorObject has scope OnPrem; a Cloud app names it. |
| 0111 | AL0130 | this passed to a var parameter of another codeunit. |
| 0112 | AL0296 | SecretText.Unwrap named from a Cloud app (the method has scope OnPrem). |
| 0113 | AL0296 | A variable of the File data type in a Cloud app. |
| 0640 | AL0666 | `JsonArray.SelectTokens` needs runtime 17; the BC 27 app runs on 16.1 (BC 28 and 29 compile it) |
| 0641, 0642 | AL0126 | `MediaSet.ImportStream` and `Media.ImportStream` with a file name as fourth argument (0642: on 27, 28 and 29) |
| 0643 to 0646 | AL0296 | `Media.ExportFile`, `Media.ImportFile`, `MediaSet.ExportFile` and `MediaSet.ImportFile` named from a Cloud app (Scope = OnPrem) |
| 0647 to 0650 | AL0133 | `Query.SaveAsCsv` and `Query.SaveAsXml` with a file name (instance and by object number): in a Cloud app only the OutStream forms exist |
| 0651 to 0653 | AL0296 | `HttpClient.UseDefaultNetworkWindowsAuthentication` and `UseWindowsAuthentication` (Text and SecretText) named from a Cloud app |
| 0660 | AL0296 | Report.SaveAsExcel, SaveAsHtml, SaveAsPdf, SaveAsWord and SaveAsXml of the global Report object (object id and file name) are Scope = OnPrem: a Target = Cloud app cannot name them. (5 diagnostics) |
| 0661 | AL0296 | Report.SaveAsExcel, SaveAsHtml, SaveAsPdf, SaveAsWord and SaveAsXml on a Report variable (file name) are Scope = OnPrem: a Target = Cloud app cannot call them. (5 diagnostics) |
| 0664 | AL0666 | The fully qualified name overloads of Report.Run, Report.RunModal, Report.Execute, Page.Run and RecordRef.Open and RecordRef.FullyQualifiedName need runtime 17.0: the BC 27 app runtime is 16.1 and cannot call them (the BC 28 and 29 apps run on 17.1 and 18.0, where tests/al-language pins them). (6 diagnostics) |
| 0665 | AL0666 | The fully qualified name overloads of Report.Run, Report.RunModal, Report.Execute, Page.Run, Page.RunModal and RecordRef.Open and RecordRef.FullyQualifiedName need runtime 17.0: an app with runtime 16.0 (the default here) cannot call them on any BC major. (8 diagnostics) |
| 0680 | AL0246 | A page extension cannot change DecimalPlaces of a base field with modify. |
| 0681 | AL0246 | A page extension cannot change DrillDown of a base field with modify. |
| 0682 | AL0246 | A page extension cannot change Lookup of a base field with modify. |
| 0683 | AL0246 | A page extension cannot change ShowFilter of a base part with modify. |
| 0684 | AL0666 | A page extension cannot change Editable of a base part with modify (runtime 16.0). |
| 0685 | AL0169 | UpdatePropagation knows Both and SubPart only. |
| 0686 | AL0246 | A page extension cannot change UpdatePropagation of a base part with modify. |
| 0687 | AL0223 | DataAccessIntent is allowed on an API page only, and then only with Editable = false. (2 diagnostics) |
| 0688 | AL0167 | IsPreview is allowed on PromptDialog and ConfigurationDialog pages only. |
| 0689 | AL0674 | A custom action of type Flow needs a FlowId. |
| 0690 | AL0169 | CustomActionType takes a known value only. |
| 0691 | AL0169 | Scope of a file upload action takes Page or Repeater only. |
| 0692 | AL0825 | MovedFrom on a field of a base table (not of a table extension). |
| 0693 | AL0734 | MovedFrom takes the id of an app, a GUID. |
| 0694 | AL0167 | MovedTo needs ObsoleteState PendingMove or Moved. |
| 0695 | AL0167 | ExternalSchema needs TableType CRM, ExternalSQL or CDS. |
| 0696 | AL0167 | OptionOrdinalValues needs TableType CRM or CDS and an ExternalType of Picklist, State or Status. (2 diagnostics) |
| 0697 | AL0447 | TableType ExternalSQL cannot be used for Cloud development (ExternalSchema is meant for it). |
| 0698 | AL0124 | MaxLength is a modifier of Caption only; on a field it is not a property. |
| 0699 | AL0829 | MovedTo names the app of the extension itself. |
| 0700 | AL0456 | OptionOrdinalValues needs one value per option member. |
| 0701 | AL0124 | Width is not a property of a report column. |
| 0702 | AL0439 | A report label takes Comment, Locked and MaxLength only; CaptionClass is not one of them. |
| 0703 | AL0706 | RDLCLayout and WordLayout cannot be used while the report has a rendering section. (2 diagnostics) |
| 0704 | AL0124 | TableRelation is not a property of an XmlPort field element (the table field carries it). |
| 0705 | AL0850, AL0296 | Scope = OnPrem on an interface is refused for a Cloud app. (2 diagnostics) |
| 0706 | AL0223 | TestIsolation is a property of a test runner codeunit; a test codeunit cannot state it. |
| 0707 | AL0195 | InherentPermissions on a report takes X only. |
| 0708 | AL0674 | An entitlement of type ConcurrentUserServicePlan needs an Id. (2 diagnostics) |
| 0709 | AL0169, AL0327 | Removed is not a value of ObsoleteState for these object kinds (it is for table fields). (9 diagnostics) |
| 0710 | AL0169 | Removed is not a value of ObsoleteState for an enum value or an enum extension value. (2 diagnostics) |
| 0711 | AL0169 | Removed is not a value of ObsoleteState for a page group, cue group, label, field or separator. (4 diagnostics) |
| 0712 | AL0169 | Removed is not a value of ObsoleteState for a page extension, or for a group, field or action it adds. (4 diagnostics) |
| 0713 | AL0223 | ObsoleteReason and ObsoleteTag need ObsoleteState = Pending, on every object kind. (14 diagnostics) |
| 0714 | AL0169 | RoleType takes Local or Delegated only. |
| 0715 | AL0674 | An entitlement of type Role needs an Id. |
| 0716 | AL0223 | RoleType needs Type = Role, and GroupName needs Type = ConcurrentUserServicePlan. (2 diagnostics) |
| 0722 | AL0284 | A subscriber to Global Triggers.OnGlobalInsert declares its parameter as Integer instead of RecordRef. |
| 0723 | AL0284 | A subscriber to Environment Triggers.OnAfterCopyEnvironmentPerDatabase declares the environment types as Integer instead of an Option (two diagnostics). |
| 0724 | AL0282 | A subscriber to Reporting Triggers.GetPrinterName declares a parameter the event does not have. |
| 0725 | AL0280 | A subscriber names an event that Company Triggers does not declare (OnCompanyOpened). |
| 0740 | AL0161 | An app subscribes to GetRoleCenterBannerPartID of the platform codeunit "System Action Triggers"; the event is declared an InternalEvent. |
| 0760 | AL0844 | A Date field cannot carry DateFormula = true (the property exists only on Text-like fields). |
| 0761 | AL0843 | SQLDataType is allowed on Code fields only. |
| 0762 | AL0169 | MaskType takes None or Concealed. |
| 0763 | AL0103 | Width on a table field with a value that does not fit an Integer. |
| 0764 | AL0232 | Width with a negative value. |
| 0765 | AL0169 | AllowInCustomizations takes ToBeClassified, Never, AsReadOnly or AsReadWrite. |
| 0766 | AL0169 | Same as 0765, on a table extension. |
| 0767 | AL0186 | ColumnStoreIndex names a field the table does not have. |
| 0768 | AL0223 | LinkedInTransaction on a table that is not LinkedObject. |
| 0769 | AL0185 | DrillDownPageId of a table extension names a page that does not exist. |
| 0770 | AL0185 | LookupPageId of a table extension names a page that does not exist. |
| 0771 | AL0169 | modify() of a field with an invalid MaskType value. |
| 0772 | AL0103 | modify() of a field with a Width out of range. |
| 0773 | AL0876 | MaskType = Concealed together with ExtendedDatatype = Masked. |
| 0774 | AL0843 | SQLTimestamp on an Integer field. |
| 0775 | AL0843 | OptionCaptionML on a Text field. |
| 0777 | AL0666 | BC 28 only: a page content area and an action area take none of ObsoleteState, ObsoleteReason and ObsoleteTag (not available in runtime 17.1). (6 diagnostics) |
| 0778 | AL0666 | BC 29 and later: the same as 0777 at runtime 18.0. (6 diagnostics) |
| 0780 | AL0223 | RequiredTestIsolation is only allowed on a codeunit with Subtype = Test. |
| 0781 | AL0223 | TestType is only allowed on a codeunit with Subtype = Test. |
| 0782 | AL0169 | TestType takes UnitTest, IntegrationTest, Uncategorized or AITest. |
| 0783 | AL0169 | RequiredTestIsolation takes None, Disabled, Codeunit or Function. |
| 0784 | AL0666, AL0928 | BC 27 only: TestHandlers needs runtime 18.0, and the BC 27 symbols lack the system enum TestHandler. (2 diagnostics) |
| 0787 | AL0103 | MaximumHeight of a control add-in does not fit an Integer. |
| 0788 | AL0103 | MaximumWidth of a control add-in does not fit an Integer. |
| 0789 | AL0223 | AssignmentCompatibilityReason needs AssignmentCompatibility = true. |
| 0790 | AL0185 | ExcludedPermissionSets names a permission set that does not exist. |
| 0791 | AL0428, AL0543 | A query sets HelpLink and ContextSensitiveHelpPage together. (3 diagnostics) |
| 0792 | AL0543 | ContextSensitiveHelpPage on a query needs contextSensitiveHelpUrl in app.json. |
| 0793 | AL0471 | HelpLink on a query with a text that is not a URL. |
| 0794 | AL0223 | EntityCaption on a query that is not of QueryType API. |
| 0795 | AL0160 | ProfileDescriptionML with a language code that does not exist. |
| 0796 | AL0428 | EntityCaption together with EntityCaptionML, and EntitySetCaption together with EntitySetCaptionML, on a query. (4 diagnostics) |
| 0797 | AL0169 | Removed is not a value of ObsoleteState for page controls and actions. (11 diagnostics) |
| 0798 | AL0169 | Removed is not a value of ObsoleteState for a table field group, page customization, permission set, profile, query column and query filter. (8 diagnostics) |
| 0799 | AL0666 | BC 27 only: the same as 0777 at runtime 16.1. (6 diagnostics) |
| 0800 | AL0666 | Report parts need runtime 18.0 (BC 29). BC 27 compiles at runtime 16.1, BC 28 at 17.1: the text differs only in the version, so the recorded text stops before it. BC 29: positive test report/lt-y-report-props/YReportParts.al. (@until BC 28) |
| 0801 | AL0666 | Report parts need runtime 18.0 (BC 29). BC 27 compiles at runtime 16.1, BC 28 at 17.1: the text differs only in the version, so the recorded text stops before it. BC 29: positive test report/lt-y-report-props/YReportParts.al. (@until BC 28) |
| 0802 | AL0666 | Report parts need runtime 18.0 (BC 29). BC 27 compiles at runtime 16.1, BC 28 at 17.1: the text differs only in the version, so the recorded text stops before it. BC 29: positive test report/lt-y-report-props/YReportParts.al. (@until BC 28) |
| 0803 | AL0666 | Report parts need runtime 18.0 (BC 29). BC 27 compiles at runtime 16.1, BC 28 at 17.1: the text differs only in the version, so the recorded text stops before it. BC 29: positive test report/lt-y-report-props/YReportParts.al. (@until BC 28) |
| 0804 | AL0666 | Report parts need runtime 18.0 (BC 29). BC 27 compiles at runtime 16.1, BC 28 at 17.1: the text differs only in the version, so the recorded text stops before it. BC 29: positive test report/lt-y-report-props/YReportParts.al. (@until BC 28) |
| 0805 | AL0223 | Runtime 18.0 (BC 29): layout Subtype needs Type = Word. BC 27 and 28 give AL0666 for Subtype instead (case 0803). (@from BC 29) |
| 0806 | AL0296 | . |
| 0807 | AL0169 | . |
| 0808 | AL0169 | . |
| 0809 | AL0169 | . |
| 0810 | AL0169 | . |
| 0811 | AL0436 | . |
| 0812 | AL0543 | ContextSensitiveHelpPage needs the manifest property contextSensitiveHelpUrl, which the corpus apps do not set. |
| 0813 | AL0543, AL0428 | . |
| 0814 | AL0471 | . |
| 0815 | AL0185 | . |
| 0816 | AL0428 | . |
| 0817 | AL0324 | . |
| 0818 | AL0160 | . |
| 0819 | AL0359 | . |
| 0820 | AL0373 | . |
| 0821 | AL0103 | . |
| 0822 | AL0103 | . |
| 0823 | AL0103 | . |
| 0824 | AL0103 | . |
| 0825 | AL0169 | . |
| 0826 | AL0124 | . |
| 0840 | AL0543, AL0428 | HelpLink and ContextSensitiveHelpPage cannot both be set on a page. (3 diagnostics) |
| 0841 | AL0543 | ContextSensitiveHelpPage needs the manifest property contextSensitiveHelpUrl (app.json has none). |
| 0842 | AL0428 | EntityCaption and EntityCaptionML cannot both be set on an API page. (2 diagnostics) |
| 0843 | AL0428 | EntitySetCaption and EntitySetCaptionML cannot both be set on an API page. (2 diagnostics) |
| 0844 | AL0428 | PromotedActionCategories and PromotedActionCategoriesML cannot both be set on a page. (2 diagnostics) |
| 0845 | AL0428 | AdditionalSearchTerms and AdditionalSearchTermsML cannot both be set in a page extension. (2 diagnostics) |
| 0846 | AL0169 | PromptMode knows Prompt, Content and Generate only. |
| 0847 | AL0223 | A PromptDialog page must set Extensible = false. |
| 0848 | AL0471 | HelpLink must be a URL. |
| 0849 | AL0246 | A page extension cannot change DecimalPlaces with modify. |
| 0850 | AL0246 | A page extension cannot change DrillDown with modify. |
| 0851 | AL0246 | A page extension cannot change Lookup with modify. |
| 0852 | AL0246 | A page extension cannot change ShowFilter of a part with modify. |
| 0853 | AL0246 | A page extension cannot change UpdatePropagation of a part with modify. |
| 0854 | AL0185 | CardPageId must name an existing page. |
| 0855 | AL0185 | LookupPageId must name an existing page. |
| 0856 | AL0169 | MaskType knows None and Concealed only. |
| 0857 | AL0169 | Style knows the ten named styles only. |
| 0858 | AL0232 | Width must be within the allowed range (a negative value). |
| 0860 | AL0808 | A page customization cannot set Editable = true on a control whose source field has AllowInCustomizations ToBeClassified. |
| 0861 | AL0223 | ClearViews is for list pages only. |
| 0862 | AL0169 | Importance knows Standard, Promoted and Additional only. |
| 0863 | AL0169 | MaskType knows None and Concealed only. |
| 0864 | AL0232 | Width must be within the allowed range (a negative value). |
| 0865 | AL0161 | A page customization cannot name a variable of the page it customizes in an expression. |
| 0866 | AL0270 | modify() names a control that the customized page does not have. |
| 0868 | AL0208 | QuickEntry takes a boolean constant. |
| 0869 | AL0844 | BlankZero on a Text field of a page extension (a number property). |
| 0870 | AL0843 | OptionCaptionML on a Text field. |
| 0920 | AL0314 | FreezeColumn is a repeater property: a cue group refuses it (an unknown field name does not matter, the container is refused first). |
| 0921 | AL0591 | GridLayout is a grid property: a cue group refuses it. |
| 0922 | AL0314 | IndentationColumn is a repeater property: a cue group refuses it. |
| 0923 | AL0314 | IndentationControls is a repeater property: a cue group refuses it (a field that exists). |
| 0924 | AL0314 | IndentationControls is a repeater property: a cue group refuses it (a control that does not exist). |
| 0925 | AL0591 | TreeInitialState is a repeater property: a cue group refuses it. |
| 0926 | AL0169 | CuegroupLayout has one value, Wide (case does not matter: pages/lt-ab-group-properties/ABLayouts.al compiles Wide and wide). |
| 0927 | AL0169 | CuegroupLayout has one value, Wide. |
| 0928 | AL0169 | CuegroupLayout has one value, Wide: any other name is refused. |
| 0929 | AL0186 | FileUploadAction names an action of the page; an action that does not exist is refused. |
| 0930 | AL0591 | FileUploadRowAction is a repeater property: a cue group refuses it even when the action exists. |
| 0931 | AL0591 | CuegroupLayout is a cue group property: a fixed group refuses it. |
| 0932 | AL0314 | FreezeColumn is a repeater property: a fixed group refuses it. |
| 0933 | AL0591 | GridLayout is a grid property: a fixed group refuses it. |
| 0934 | AL0314 | IndentationColumn is a repeater property: a fixed group refuses it. |
| 0935 | AL0314 | IndentationControls is a repeater property: a fixed group refuses it. |
| 0936 | AL0591 | TreeInitialState is a repeater property: a fixed group refuses it. |
| 0937 | AL0186 | FileUploadAction names an action of the page; an action that does not exist is refused. |
| 0938 | AL0591 | FileUploadRowAction is a repeater property: a fixed group refuses it even when the action exists. |
| 0939 | AL0591 | CuegroupLayout is a cue group property: a grid refuses it. |
| 0940 | AL0314 | FreezeColumn is a repeater property: a grid refuses it. |
| 0941 | AL0314 | IndentationColumn is a repeater property: a grid refuses it. |
| 0942 | AL0314 | IndentationControls is a repeater property: a grid refuses it. |
| 0943 | AL0591 | TreeInitialState is a repeater property: a grid refuses it. |
| 0944 | AL0169 | GridLayout has the values Rows and Columns (pages/lt-ab-group-properties/ABLayouts.al): any other name is refused. |
| 0945 | AL0186 | FileUploadAction names an action of the page; an action that does not exist is refused. |
| 0946 | AL0591 | FileUploadRowAction is a repeater property: a grid refuses it even when the action exists. |
| 0947 | AL0162 | A control add-in trigger of a page field cannot be added to a field through a page extension modify block: OnControlAddIn is not a valid trigger there. |
| 0948 | AL0162 | A request page extension refuses the trigger OnFindRecord (every other page trigger compiles there: report/lt-ab-request-page-triggers/ABRequestPageExt.al); a page extension refuses the same two (0017, 0018). |
| 0949 | AL0162 | A request page extension refuses the trigger OnNextRecord (every other page trigger compiles there: report/lt-ab-request-page-triggers/ABRequestPageExt.al); a page extension refuses the same two (0017, 0018). |
| 0950 | AL0161 | The Rec variable of the base request page is not accessible from a trigger of a request page extension (the base page's own triggers use it: report/lt-ab-request-page-triggers/ABRequestPageFixtures.al). |
| 0951 | AL0477 | OnValidateUpgradePerCompany and OnValidateUpgradePerDatabase are valid only in a codeunit with Subtype = Upgrade (such a codeunit runs at publish, so the corpus holds none: .github/scripts/check-install-triggers.py). (two diagnostics). |
| 0960 | AL0132 | Record.IsDirty() exists from BC 29 (AL 18); BC 27 and 28 reject it. Runtime tests for BC 29: tests/al-language/lt-ac. |
| 0961 | AL0134 | The DataSourceContext type exists from BC 29. Runtime test for BC 29: tests/al-language/lt-ac/ACContexts.al. |
| 0962 | AL0134 | The TestHandlerContext type exists from BC 29. Runtime test for BC 29: tests/al-language/lt-ac/ACContexts.al. |
| 0963 | AL0126 | IsolatedStorage.Get with an IsolationLevel exists from BC 29. Runtime tests for BC 29: tests/al-language/lt-ac. |
| 0964 | AL0132 | ModuleInfo.ContextSensitiveHelpUrl, EULA, Help and PrivacyStatement exist from BC 29. Runtime tests for BC 29: tests/al-language/lt-ac. (4 diagnostics) |
| 0965 | AL0133 | NavApp.GetResource, GetResourceAsText and GetResourceAsJson with an AppId exist from BC 29. Runtime tests for BC 29: tests/al-language/lt-ac. (4 diagnostics) |
| 0966 | AL0126, AL0132 | NavApp.ListResources(AppId) and NavApp.ListAppsWithPublicResources exist from BC 29. Runtime tests for BC 29: tests/al-language/lt-ac. (2 diagnostics) |
| 0967 | AL0895 | The Native attribute on a procedure with a body outside the platform symbols app. (2 diagnostics) |
| 0968 | AL0112 | The Scope attribute takes OnPrem, Internal or Cloud; any other value is reported as an unknown attribute. |
| 0969 | AL0195 | InherentPermissions with a permission letter that is not R, I, M or D. |
| 0970 | AL0433 | A table with ObsoleteState = Removed is used as a record variable. A codeunit cannot be Removed (AL0169), a table can. |
| 0971 | AL0112 | The RequiredPending attribute exists from BC 29. |
| 0972 | AL0772 | RequiredPermissions is only valid on an external business event. |
| 0973 | AL0187, AL0296 | RunOnClient on a procedure: it is only valid on variables, and it has scope OnPrem. (2 diagnostics) |
| 0974 | AL0187, AL0296 | SuppressDispose on a procedure: it is only valid on variables, and it has scope OnPrem. (2 diagnostics) |
| 0975 | AL0187, AL0296 | WithEvents on a procedure: it is only valid on variables, and it has scope OnPrem. (2 diagnostics) |
| 0976 | AL0187 | SecurityFiltering on a procedure (it belongs on a Record variable: tests/al-language/lt-ac/ACAttributes.al). |
| 0977 | AL0187 | InDataSet on a procedure. The attribute is deprecated (AL0667 warning) and valid only on variables. |
| 0978 | AL0243 | The TestPermissions attribute on a procedure of a codeunit that is not a test codeunit. |
| 0979 | AL0132 | TestPermissions has Disabled, Restrictive, NonRestrictive and InheritFromTestRunner; there is no Normal. |
| 0980 | AL0619 | The Caption attribute on a procedure of a test codeunit (a plain codeunit accepts it). With ServiceEnabled it compiles: tests/al-language/lt-ac/ACAttributes.al. |
| 0981 | AL0296 | A procedure with [Scope('OnPrem')] called from the same Cloud app. |
| 0982 | AL0296 | A procedure with [Scope('Internal')] called from the same Cloud app. |
| 0983 | AL0296 | The HttpClientHandler attribute in a Cloud app (it has scope OnPrem). |
| 0984 | AL0241 | An HttpClientHandler procedure without parameters. |
| 0985 | AL0241 | A ReportHandler procedure without the Report parameter. Runtime test: tests/al-language/lt-ac/ACAttributes.al. |
| 0986 | AL0243 | The ReportHandler attribute in a codeunit that is not a test codeunit. |
| 0987 | AL0112 | The TestDataSource attribute exists from BC 29. |
| 0988 | AL0595 | On BC 29 the TestDataSource attribute names a codeunit that must implement ITestDataSource. |
| 0989 | AL0175 | PageStyle is option-like: it supports = and <> but not an ordering operator. The same holds for HttpRequestType, AuditCategory, SecurityOperationResult and PageBackgroundTaskErrorLevel. |
| 0990 | AL0132, AL0122 | HttpRequestType is option-like: no AsInteger, and an Integer cannot be assigned. The same holds for PageStyle, AuditCategory, SecurityOperationResult and PageBackgroundTaskErrorLevel. (2 diagnostics) |
| 0991 | AL0132 | A page calls a procedure that the control add-in does not declare. Runtime test for the valid call: tests/al-language/lt-ac/ACControlAddIn.al. |
| 0992 | AL0458 | WithEvents on a variable of a type that has no events (OnPrem app). Runtime test for a DotNet variable: tests/al-language-onprem-dotnet/lt-ac/AcDnAttributes.al. |
| 0993 | AL0458 | RunOnClient on a Boolean variable (OnPrem app): the attribute is valid only on DotNet variables. Runtime test: tests/al-language-onprem-dotnet/lt-ac/AcDnAttributes.al. |
| 0994 | AL0895 | The Native attribute needs runtime 17.0; at that runtime a procedure with a body outside the platform symbols app is rejected (once for the object, once for the attribute). (2 diagnostics) |
| 0995 | AL0666 | The DataSourceContext type needs runtime 18.0 (BC 29 and later). An app below that runtime gets AL0666 on every BC major (the AL 16 and 17 compilers' verdict for BC 27 and 28 is in cases 0961, 0962, 0971). |
| 0996 | AL0666 | The TestHandlerContext type needs runtime 18.0 (BC 29 and later). An app below that runtime gets AL0666 on every BC major (the AL 16 and 17 compilers' verdict for BC 27 and 28 is in cases 0961, 0962, 0971). |
| 0997 | AL0666 | The RequiredPending attribute needs runtime 18.0 (BC 29 and later). An app below that runtime gets AL0666 on every BC major (the AL 16 and 17 compilers' verdict for BC 27 and 28 is in cases 0961, 0962, 0971). |
| 0998 | AL0666 | The BC 29 methods Record.IsDirty, IsolatedStorage.Get with an IsolationLevel, ModuleInfo.ContextSensitiveHelpUrl, EULA, Help, PrivacyStatement and the NavApp resource methods need runtime 18.0. An app declared at runtime 16.0 gets AL0666 for each, on every BC major; the corpus app itself uses runtime 18.0 on BC 29 and guards them with BC29PLUS. (14 diagnostics) |
| 1040 | AL0175 | A Char minus a Text literal of two characters or of none, and the same literals minus a Char (four diagnostics). A one-character literal compiles. |
| 1041 | AL0122 | A Char minus a one-character literal is an Integer and cannot be assigned to a Text; a Char plus a two-character literal is a Text and cannot be assigned to an Integer (two diagnostics). |
| 1050 | AL0124 | XmlPort fieldelement: Occurrence belongs to attributes; elements use MinOccurs and MaxOccurs. |
| 1051 | AL0124 | XmlPort textelement: Occurrence belongs to attributes; elements use MinOccurs and MaxOccurs. |
| 1052 | AL0124 | XmlPort tableelement: Occurrence belongs to attributes; elements use MinOccurs and MaxOccurs. |
| 1053 | AL0169 | XmlPort fieldattribute: Occurrence takes Optional or Required. |
| 1150 | AL0122 | A Text character by index plus or minus a one-character literal is an Integer: it does not assign to a Text (three statements). |
| 1060 | AL0316 | A tree repeater whose IndentationColumn is a Decimal field. |
| 1360 | AL0271 | A page extension adds to area Creation of a ListPart page that declares no actions (a ListPart has no implicit Creation area). |
| 1361 | AL0193 | SetFilter on a Decimal field with a %1 placeholder whose value is a Text constant. |
| 1061 | AL0316 | A tree repeater whose IndentationColumn is a Text field. |
| 1062 | AL0316 | A tree repeater whose IndentationColumn is an Option field. |
| 1696 | AL0161 | Rec.CurrFieldNo in a table extension procedure is inaccessible; the unqualified CurrFieldNo := 10 compiles. |
| 1063 | AL0171 | An XmlPort table element sets LinkFields but no LinkTable. |
| 1090 | AL0132 | CurrPage.PromptMode is set to PromptMode::Lookup on a PromptDialog page: PromptMode has no member Lookup. |
| 1091 | AL0124 | ApplicationArea on a page group: the property is not available on a group. |
| 1270 | AL0270 | A page extension adds to an area name that is not a layout area (FactBoxes is accepted even when the base page does not declare it). |
| 1140 | AL0133 | RecordRef.GetTable with a RecordRef argument (a Variant that holds the RecordRef compiles). |
| 1141 | AL0196 | Record.TestField(Field, Value) with a Byte variable: ambiguous between the Integer and BigInteger overloads. |
| 1530 | AL0369 | A for loop over an Integer control variable with a BigInteger literal end bound above the Integer range. |
| 1531, 1532, 1533 | AL0172 | Unary minus on an Option variable, on an Option table field, and on an Enum. |
| 1534 | AL0530 | A Code[2049] variable (Code[1025] to Code[2048] compile). |
| 1535, 1536 | AL0154 | A Code[2049] and a Text[2049] table field. |
| 1537 | AL0581 | A Code[0] variable. |
| 1538 | AL0133 | A Code[20] variable passed to a var Text parameter. |
| 1539 | AL0133 | A Text[100] table field passed to a var Code[20] parameter. |
| 1540, 1541, 1542 | AL0204 | BC 27/28 only (AL 16 and 17): a CalcFormula or TableRelation where clause that filters an Integer or Enum field by a BigInteger field (AL 18 and later warn, AL0662/AL0663). |
| 1080 | AL0777 | Guid assigned to Text[10]. |
| 1120 | AL0132 | A TestRequestPage data item (TestFilter) has no SetRange, GetRangeMin or GetRangeMax. |
| 1121 | AL0721 | A report rendering section without DefaultRenderingLayout. |
| 1122 | AL0379 | A report column name with a space. |
| 1160, 1161 | AL0196 | A Decimal variable and a Decimal literal passed to a procedure whose only overloads take Integer and BigInteger. |
| 1162 | AL0193 | CopyArray with a two-dimensional destination and a one-dimensional source. |
| 1170 | AL0132 | CommitBehavior with a member other than Ignore and Error. |
| 1171 | AL0238 | The CommitBehavior attribute without its argument. |
| 1172 | AL0433 | The removed User Group Member table. |
| 1180 | AL0169 | A report layout with ObsoleteState = Removed (a layout takes only No and Pending). |
| 1190, 1191 | AL0122 | A Boolean assigned to a Text and to a Code variable. |
| 1192 | AL0111 | A number literal with an exponent (1e19) is a syntax error. |
| 1193 | AL0122 | A Date assigned to a DateTime variable. |
| 1240 | AL0296 | OnPrem-scoped platform tables of BC 28 and 29 used from a Cloud app (the BC 27 list is 0020 to 0024). |
| 1241 | AL0162 | Triggers of other object types (OnRun, OnInsert, OnValidate, OnAction, OnPreReport, OnBeforeOpen, ...) in a page extension. |
| 1242 | AL0440 | Foo(var A: Integer) next to Foo(A: Integer): var does not make a different signature. |
| 1243 | AL0440 | Two procedures with the same name and parameter types in a table, a page and a report. |
| 1244 | AL0124 | assemblyProbingPaths in app.json of a Target = OnPrem app at runtime 16.0. |
| 1245 | AL0124 | assemblyProbingPaths in app.json of a Cloud app at runtime 18.0. |
| 1246 | AL0132 | An unknown field of a table that has a table extension, and of a table of a dependency app. |
| 1247 | AL0118 | A bare call of an unknown name in a report extension, a table extension, a query trigger and an xmlport trigger. |
| 1248 | AL0197 | Two table extensions and two report extensions of one name. |
| 1249 | AL0133 | An enum value passed by value to a parameter of another enum type without AssignmentCompatibility. |
| 1250 | AL0122 | Integer from a Text variable, Code from an Integer, Text from an Integer expression. |
| 1251 | AL0122 | A two-character literal assigned to a BigInteger and to a Decimal. |
| 1252 to 1258 | AL0591, AL0314 | Cue group, file upload, freeze column, grid, indentation and tree properties on a plain group. |
| 1259, 1260 | AL0591 | CuegroupLayout and GridLayout on a repeater. |
| 1261 | AL0171 | SubPageLink on a system part. |
| 1262 | AL0171 | SubPageView on a system part. |
| 1263 | AL0543 | ContextSensitiveHelpPage on a page extension without the manifest property contextSensitiveHelpUrl. |
| 1264 | AL1150 | A contextSensitiveHelpUrl in app.json that is not a URL. |
| 1310 | AL0296 | File.IsPathTemporary from a Cloud app. |
| 1311 | AL0296 | File.Download from a Cloud app. |
| 1312 | AL0296 | Database.DataFileInformation from a Cloud app. |
| 1210 | AL0240 | A ModalPageHandler with a Page parameter and no var Response: Action. |
| 1211 | AL0241 | A ModalPageHandler with a TestPage parameter and a Response parameter. |
| 1212 | AL0132 | A TestPage has no Delete method for the standard Delete action. |
| 1370 | AL0779 | ModifyAll on a FlowField (Sum, Lookup); ModifyAll on a FlowFilter and assignments to either compile (corpus #664 item 4). |
| 1371 | AL0777 | A Guid assigned to Text[10] or Code[20] overflows; Code[50] and Text take it (corpus #664 item 5). |
| 1372 | AL0774 | exit(false) / exit(true) in a [TryFunction]; a bare exit compiles (corpus #664 item 6). |
| 1373 | AL0896 | FlowFields whose CalcFormula forms a cycle, directly or through a second FlowField (corpus #664 item 9). |
| 1374 | AL0873 | continue outside a loop (corpus #664 item 11). |
| 1375 | AL0855, AL0155, AL0379 | A variable named ""; a query data item and column named "" (corpus #664 item 13). |
| 1376 | AL0926, AL0104 | Table fields and keys after a procedure, on BC 27, 28 and 29 alike (corpus #664 item 15). |
| 1377 | AL0582, AL0922 | A local procedure, and a Scope OnPrem procedure, as an interface implementation (corpus #664 item 19). |
| 1378 | AL0104, AL0107 | '?' or '*' in a variable name (corpus #664 item 22). |
| 1379 | AL0224, AL0111, AL0104, AL0198 | Nested block comments; braces used as a comment in a procedure body (corpus #664 items 23, 24). |
| 1380 | AL0353, AL0815 | A query column whose source is a FlowFilter (corpus #664 item 5). |
| 1381 | AL0190 | Time literals with fewer than six digits: 2359T, 1130T, 12T, 123T (corpus #664 item 27). |
| 1382 | AL0111, AL0224, AL0104 | Lower-case literal suffixes 0d, 0t, 0dt, 20200101d, 120000t; DMY2Date(1, , 2020) (corpus #664 items 28, 34). |
| 1383 | AL0623, AL0622 | A #region that starts outside an #if and ends inside it (corpus #664 item 29). |
| 1384 | AL0831, AL0582 | A [TryFunction] as an interface implementation (corpus #664 item 6). |
| 1385 | AL0806 | Record "18": a quoted object id (corpus #664 item 31). |
| 1386 | AL0870, AL0224, AL0111 | @ not followed by a quote (corpus #664 item 11). |
| 1387 | AL0165, AL0750, AL0118 | Trigger called directly; chained enum value; "17".DeleteAll and Customer.Count without a variable (corpus #664 items 30, 32, 33). |
| 1388 | AL0185, AL0851 | 'as' with a target that is not an interface (corpus #664 item 19). |
| 1389 | AL0159 | Blob and TestPage as return types; the other complex types and the Http types compile (corpus #664 items 35, 36). |
| 1490 | AL0839 | a table and its table extension in the same app both set `Caption` (same XLIFF trans-unit id; Caption on a table extension alone compiles) |
| 1491 | AL0404 | `Clustered` and `Unique` on a key that a table extension adds (`MaintainSqlIndex = false` compiles) |
| 1492 | AL0246 | `CompressionType` on a table extension |
| 1493 | AL0690, AL0687 | `IncludedFields` on the primary key / a secondary key whose `IncludedFields` names a primary-key field |
| 1494 | AL0246 | `DataPerCompany` on a table extension |
| 1495 | AL0525 | a table extension of the system table `User` and of the virtual table `Integer` |
| 1496 | AL0564 | a table extension of a table with `Extensible = false` |
| 1497 | AL0440 | a table extension procedure with the name (case-insensitive) and parameter types of a procedure of its table (an overload compiles) |
| 1498 | AL0404 | `SqlTimestamp` on a field that a table extension adds |
| 1499 | AL0171 | `modify()` of a base table field in a table extension sets `CalcFormula` |
| 1500 | AL0926 | a table that declares `fieldgroups` before `keys` |
| 1501 | AL0246 | a page extension changes `ApplicationArea` of a base part with `modify` (on a field control it compiles) |
| 1502 | AL0378 | triggers in a page extension of a Role Center page (one diagnostic per trigger) |
| 1503 | AL0322 | a page extension `modify()` sets `Editable` to a procedure call (a constant or a Boolean variable compiles) |
| 1200 | AL0666 | BC 27 only: JsonToken.SelectTokens needs runtime 17. |
| 1340 | AL0122 | BC 28 and 29: the result of Page.Run(FullyQualifiedName, Record, FieldNo) assigned; the overload returns nothing. |
| 1341 | AL0133 | BC 28 and 29: Page.Run with a fully qualified name and a FieldRef (no such overload). |
| 1570 to 1572 | AL0187 (and AL0666 on BC 27 and 28) | [RequiredPending] on an interface method; one case per BC major (corpus #664 item 19). |
| 1573 | AL0625 | #define after the first token of a file (corpus #664 item 29). |
| 1574 to 1576 | AL0629, AL0631 | Preprocessor operators that do not exist: '!', '&&', '== true' (corpus #664 item 29). |
| 1390 | AL0304 | A local variable name of 121 characters (120 compile). |
| 1391 | AL0121 | Two local variables whose names differ only in letter case. |
| 1392 | AL0757 | From BC 28: a global variable `_operator` and a procedure `Operator` in one codeunit: both metadata names clash. |
| 1393 | AL0117 | `continue;` with a local variable named Continue in scope reads as the bare variable. |
| 1394 | AL0309 | A table with 41 keys (40 compile). |
| 1395 | AL0154 | A table field of type Text[2049] (Text[2048] compiles). |
| 1396 | AL0368 | An array with 11 dimensions (10 compile). |
| 1397 | AL0146 | An array of 1,000,001 elements (1,000,000 compile). |
| 1398 | AL0155 | An enum extension declares the same value name and ordinal twice: duplicate name only, no AL0231. |
| 1399 | AL0231 | An enum extension declares one ordinal twice under two names. |
| 1400 | AL0118 | Another procedure names a member of an option parameter through the parameter name. |
| 1401 | AL0405 | `case Enum::"X" of` with the enum type instead of a value. |
| 1402 | AL0311 | `E.FromInteger(1)` on an enum instance. |
| 1403 | AL0156 | A page field whose source expression is the name of an enum object. |
| 1404 | AL0103 | A for loop with an Integer control variable and a literal bound outside the Integer range. |
| 1405 | AL0122 | `Txt := Cond ? '1' : ''`: the Char true branch sets the type and the empty Text literal does not convert. |
| 1406 | AL0122 | `V := Cond ? CurrentDateTime() : Today()` into a Variant: the Date branch does not convert to DateTime. |
| 1407 | AL0666 | BC 27 and 28: a bare IsDirty() in a TableNo codeunit's OnRun binds to Record.IsDirty (runtime 18.0) before the local procedure. |
| 1408 | AL0757 | BC 27: a global variable `_operator` and a procedure `Operator`: error on the variable, only warning AL0758 on the procedure. |
| 1680 | AL0757 | Two event publishers, and two event subscribers, named `Foo Bar` and `Foo_Bar` in one codeunit. |
| 1681 | AL0155 | Two event publishers with one name and different parameter types; an event publisher named `Run` in a codeunit. |
| 1682 | AL0286, AL0283, AL0287 | An event publisher with a statement, a return value, a local variable, a local Label. |
| 1683 | AL0132 | An event subscriber with `ObjectType::TableExtension`. |
| 1684 | AL0118 | A table event subscriber naming the table with `Table::Customer` instead of `Database::Customer`. |
| 1685 | AL0288 | A subscriber declares `var` on a parameter the publisher passes by value. |
| 1686 | AL0284 | Subscriber parameter types: Enum as Integer, Option as Integer or Enum, a GlobalVarAccess global as Text, RunTrigger as Integer. |
| 1687 | AL0282 | Subscriber parameters matching no publisher parameter: RunTrigger on OnAfterValidateEvent, `Record` instead of `Rec`, an unknown global. |
| 1616 | AL0865 | A chartpart control in a page layout: the control type is not supported (an error on every leg, not the AL0864 warning). |
| 1728 | AL0172 | Unary minus on an Option variable (`-Alignment`). |
| 1729 | AL0172 | Unary minus on an Enum variable. |
| 1730 | AL0530 | A `Code[2049]` variable: the maximum for a Code variable is 2048 (Code[1025] compiles). |
| 1731 | AL0154 | A `Code[2049]` table field: the maximum for a Code field is 2048. |
| 1732 | AL0103 | A for loop over an Integer with the end bound literal 100000000000000. |
| 1733 | AL0369 | The same for loop with the BigInteger literal 100000000000000L as end bound. |
| 1734 | AL0427 | An Enum lookup FlowField over a BigInteger field. |
| 1735 | AL0103 | `InitValue = 3000000000` on an Integer field. |
| 1832 | AL0133 | A BigText passed to "Base64 Convert".FromBase64: no overload takes a BigText. |
| 1833 | AL0122 | A BigText assigned to a Text variable: no implicit conversion. |
| 1864 | AL0132 | A TestPage cannot reach a system part, file upload action, custom action, view or user control. |
| 1865 | AL0171 | SubPageLink and SubPageView on a system part. (two diagnostics) |
| 1866 | AL0543 | ContextSensitiveHelpPage on a page extension without the manifest property contextSensitiveHelpUrl. |
| 1888 | AL0779 | ModifyAll on a FlowField with RunTrigger = true. |
| 1430 | AL0528 | API page field control names with a space or a quoted special character (digit inside, leading digit, underscore compile). (two diagnostics) |
| 1431 | AL0666 | Importance = Optional on a page field: not available in the app runtime. |
| 1432 | AL0298 | StyleExpr set to a PageStyle variable. |
| 1433 | AL0155 | A page field and a page action with the same name. (two diagnostics) |
| 1434 | AL0155 | An action group and an action inside it with the same name. (two diagnostics) |
| 1435 | AL0844 | BlankZero on a Guid table field and on a page control bound to it. (two diagnostics) |
| 1436 | AL0843 | DecimalPlaces on page fields whose source is an Integer variable or the literal 0 (0.0 compiles). (two diagnostics) |
| 1437 | AL0114 | AutoFormatType set to a value of the enum "Auto Format" (integer literal expected). |
| 1438 | AL0204 | RunPageLink from a Text field to an Option field and to an Enum field. (two diagnostics) |
| 1439 | AL0255 | A request page action with RunObject = page and RunPageView. |
| 1440 | AL0107 | XMLport FieldValidate = true / false (each also AL0116; Yes, No, Undefined compile). (four diagnostics) |
| 1441 | AL0397 | A report column named like the hidden format column of a Decimal column (AmountFormat). |
| 1442 | AL0196 | System.GetUrl with a Variant record argument: ambiguous between the Table and RecordRef overloads. |
| 1443 | AL0676 | A codeunit with a protected var section. |
| 1444 | AL0371 | BigInteger assigned a product of Integer literals that overflows Integer. |
| 1445 | AL0198 | `internal interface` (access modifier before the keyword). |
| 1446 | AL0118 | A page field whose source is the bare name SystemId, with the feature NoImplicitWith. |
| 1450 | AL0166 | Record.SetRange with one argument that is an enum or option value, not a field. |
| 1451 | AL0118 | Record.SetCurrentKey with the name of a key instead of its fields. |
| 1452 | AL0779 | Record.ModifyAll on a FlowField (own FlowField and Customer."Balance (LCY)"). |
| 1453 | AL0224, AL0104 | Record.Get with an empty argument in the middle of the key values. |
| 1470 | AL0827 | Record.CalcSums with a Sum FlowField as the only argument and as the second argument. (two diagnostics) |
| 1471 | AL0223 | OptimizeForTextSearch = true on a Lookup FlowField of type Text. |
| 1472 | AL0223 | OptimizeForTextSearch = true on a FlowFilter field of type Text. |
| 1473 | AL0124 | TableIDExpr on a TableFilter field of a table. |
| 1510 | AL0175 | An Integer on the left of + with a Date on the right (Date + Integer compiles). (three diagnostics) |
| 1511 | AL0175 | An Integer minus a Date. |
| 1512 | AL0175 | An Integer on the left of + and - with a Time or a DateTime on the right. (four diagnostics) |
| 1600 | AL0245 | A local UI handler procedure (ModalPageHandler, MessageHandler). (two diagnostics) |
| 1601 | AL0192 | TestPage.OK() and Cancel() as plain statements: the TestAction return value must be used. (two diagnostics) |
| 1602 | AL0132 | A TestPage has no Delete or DeleteRow method. (two diagnostics) |
| 1608 | AL0518 | a [ModalPageHandler] and a [MessageHandler] with the same name (overloads) in one test codeunit (a handler plus a plain same-name procedure compiles) |
| 1609 | AL0499 | [HandlerFunctions] names a handler declared in another test codeunit |
| 1610 | AL0378 | an OnAction trigger on an action of a Role Center page (a RunObject action compiles) |
| 1632 | AL0132 | A TestPage of the base page names a procedure that a page extension adds. |
| 1633 | AL0666 | BC 27 only: Page.Run, Page.RunModal and Report.Run with a RecordRef in the place of the record. (three diagnostics) |
| 1634 | AL0133 | BC 28 and 29: Page.Run, Page.RunModal and Report.Run with a RecordRef in the place of the record. (three diagnostics) |
| 1640 | AL0350 | A query OrderBy names the same column twice. |
| 1641 | AL0815, AL0353 | A query column whose source is a FlowFilter field. |
| 1648 | AL0347 | A query column with Method = Min over a Code field. |
| 1649 | AL0347 | A query column with Method = Max over a Date field. |
| 1656 | AL0161 | A report trigger calls a procedure of a part of its request page (from the request page OnOpenPage it compiles). |
| 1672 | AL0162 | A report extension modify() of a base data item declares OnAfterGetRecord. |
| 1736 | AL0133 | Text[100] field passed to a var Code[20] parameter |
| 1744 | AL0107, AL0104 | Dictionary of [Guid, Option]: Option is not a type argument, the parser wants option members. |
| 1745 | AL0104 | Dictionary of [Guid, Option "a","b"] does not parse either. (two diagnostics) |
| 1746 | AL0107, AL0104 | List of [Option] does not parse. |
| 1747 | AL0408 | Dictionary of [Text, Variant] and List of [Variant]. (two diagnostics) |
| 1748 | AL0408 | Dictionary of [Integer, Record ...] and List of [Record ...] (List of [RecordRef] compiles). (two diagnostics) |
| 1749 | AL0408 | List of [Blob]. |
| 1750 | AL0133 | A Dictionary or a List passed to a var Variant parameter. (two diagnostics) |
| 1752 | AL0831 | A [TryFunction] procedure as the implementation of an interface method. |
| 1784 | AL0133 | A Record passed to a var Variant parameter. |
| 1785 | AL0777 | A Guid (variable or SystemId) assigned to a Code[20]. (two diagnostics) |
| 1786 | AL0133 | BC 28 and 29: Codeunit.Run(Id, RecordRef): no overload takes a RecordRef. |
| 1787 | AL0666 | BC 27 only: Codeunit.Run(Id, RecordRef) matches an overload that needs runtime 17.0. |
| 1788 | AL0157 | A variable of type Blob. |
| 1792 | AL0175 | `FieldRef.Value = Text`: '=' between Joker and Text. |
| 1793 | AL0175 | `FieldRef.Value = 2`: '=' between Joker and Integer. |
| 1794 | AL0175 | A Variant compared with a Text using '='. |
| 1800 | AL0884 | TestHttpResponseMessage status codes 300 and 304: redirect codes are not permitted. (two diagnostics) |
| 1801 | AL0883 | TestHttpResponseMessage status codes 399, 99, 600, 599 and 0: not valid HTTP status codes. (five diagnostics) |
| 1816 | AL0132 | JsonObject has no RemoveAll method. |
| 1817 | AL0132 | JsonArray has no RemoveAll method. |
| 1818 | AL0132 | JsonObject has no Clear method (Clear(variable) empties it). |
| 1819 | AL0132 | JsonArray has no Clear method (Clear(variable) empties it). |
| 1824 | AL0666 | BC 27 only: JsonToken.SelectTokens needs runtime 17. |
| 1776 | AL0612 | An interface that declares a trigger: an interface member must be a procedure. |
| 1777 | AL0675 | DefaultImplementation that lists the same interface twice. |
| 1778 | AL0675 | An enum value's Implementation that lists the same interface twice. |
| 1779 | AL0187, AL0919 | [Scope('Cloud')] on an interface member. |
| 1780 | AL0132 | BC 29: a default interface method called on a codeunit variable whose codeunit does not declare it. |
| 1781 | AL0922 | BC 29: a [Scope('OnPrem')] procedure overrides a default interface method. |
| 1782 | AL0231 | An enumextension of Base Application "Sales Line Type" reuses an ordinal of the base enum (ordinal 6 compiles). |
| 1872 | AL0122 | `V := Cond ? D : DT` (Date true, DateTime false): the DateTime branch does not convert to Date. |
| 1873 | AL0122 | `'K' in [TLo .. THi]` and `'K' in ['a' .. THi]`: a one-character literal is a Char and the Text range ends do not convert. |
| 1874 | AL0122 | `'K' in [CLo .. CHi]` with Code range ends: the Code ends do not convert to Char. |
| 1875 | AL0135 | `continue;` in a codeunit whose only procedure Continue takes a parameter (read as a call without its argument). |
| 1280 | AL0220 | A page extension sets InsertAllowed to a variable instead of a literal. |
| 1281 | AL0220 | A page sets InsertAllowed to an expression instead of a literal. |
| 1410 | AL0440 | Overloads that differ only in the length of a Text parameter, or only in the return type. |
| 1411 | AL0243, AL0245, AL0240 | Handler attributes outside a test codeunit, on a local procedure, and with wrong signatures. |
| 1412 | AL0161 | A local procedure called through a handle of its own object (codeunit variable, Rec./xRec., CurrPage.). |
| 1413 | AL0161, AL0118 | An internal procedure of Base Application ("Assembly Line".ShowAssemblyDocument) called from this app. |
| 1414 | AL0440 | Two extensions of one page (and of one table) in one app declare the same procedure. |
| 1415 | AL0404 | A table extension field with AutoIncrement = true. |
| 1416 | AL0124 | The Owner property on a Blob field and on an Integer field. (two diagnostics) |
| 1417 | AL0450 | A field with ObsoleteState = Removed in an active key (table extension and table). (two diagnostics) |
| 1418 | AL0166 | Record.FieldCaption with an enum value instead of a field. |
| 1419 | AL0525 | A table extension of the system table "Record Link". |
| 1420 | AL0757 | A table extension field named Timestamp: clashes with SystemRowVersion. |
| 1421 | AL0163 | A table extension modify() trigger declares a local variable without var. |
| 1422 | AL0365 | A codeunit with Subtype = Upgrade and TableNo. |
| 1423 | AL0185 | A TableRelation to a misspelled table name. |
| 1424 | AL0800, AL0844 | ExtendedDatatype = RichContent on a Text and on a Blob table field. (three diagnostics) |
| 1425 | AL0433 | A field with ObsoleteState = Removed kept in a fieldgroup (Pending compiles). |
| 1426 | AL0433 | A field of Base Application with ObsoleteState = Removed named by a dependent app. |
| 1427 | AL0118, AL0132 | CurrFieldNo outside table and table extension code. |
| 1428 | AL0104, AL0107 | An attribute on a parameter. |
| 1429 | AL0296 | A Cloud app calls the OnPrem File Management / Excel Buffer methods UploadFile, ServerCreateDirectory, OpenBook, CreateBook. |
| 1560 | AL0196 | An Integer argument to overloads that differ only by the enum type is ambiguous. |
| 1712 | AL0296 | A permission set in a Cloud app names tabledata of the Scope = OnPrem table `User Property`. |
| 1713 | AL0296 | A permission set in a Cloud app names the table object of the Scope = OnPrem table `User Property`. |
| 1714 | AL0161 | A permission set names a codeunit that is Access = Internal in a dependency (System Application `Agent Impl.`). |
| 1715 | AL0195 | AccessByPermission on a page field names a page with R (only X is allowed). |
| 1716 | AL0195 | AccessByPermission on a page field names a codeunit with RIMD (only X is allowed). |
| 1717 | AL0195 | AccessByPermission on page actions names a report with M, a query with R and an xmlport with R. |
| 1718 | AL0195 | AccessByPermission on a page action names a table object with D (tabledata takes RIMD). |
| 1720 | AL0124 | ExcludedPermissionSets in a permissionsetextension (only a permissionset may exclude sets). |
| 1760 | AL0774 | `exit(false)` / `exit(true)` in a `[TryFunction]` without a return value (a bare `exit;` compiles) |
| 1768 | AL0582 | An interface implementation omits `temporary` on a `var` record parameter. |
| 1769 | AL0122 | An interface variable assigned from a field of an enum that does not implement the interface. |
| 1770 | AL0698 | A `case` statement over a Record value. |
| 1290 | AL0220 | A page sets its own Editable property to a page variable (controls accept an expression). |
| 1688 | AL0284 | Subscriber parameter types: Record Vendor for Record Customer, a Codeunit for a Record, Decimal for Integer. |
| 1689 | AL0271 | An action subscriber names the action by its caption (with and without the ampersand) or by an unknown name. |
| 1690 | AL0155 | A page has an action group and an action with the same name. |
| 1691 | AL0132, AL0161 | A table event subscriber reads `Rec.CurrFieldNo` (a table of another app, a table of the same app). |
| 1856 | AL0107 | An XmlPort Namespaces entry with the empty prefix written as `''` (the quoted identifier `""` compiles). |
| 1857 | AL0107 | An XmlPort Namespaces property written as one string `'soap=http://...'`. |
| 1960, 1961 | AL0501 | An event subscriber in a test codeunit without `EventSubscriberInstance = Manual` (the default, and StaticAutomatic written out). |
| 1992 | AL0193 | `Validate` of an Enum field with a Variant (writer QO). |
| 1993 | AL0122 | A Variant assigned to an Enum field of a record (writer QO; 0263 is the Enum variable). |
| 2000 | AL0322 | A field control of a page binds `Visible`, `Enabled` or `Editable` to a procedure call (writer QQ, AL Runner issue 3762; on an action it compiles with warning AL0573). |
| 2008 | AL0398 | A Decimal constant as a case label of an Option (writer QS; =, <>, <, > of Option and Decimal compile: types/PROptionInteger.al). |
| 2009 | AL0398 | Decimal constants in the `in` list of an Option (writer QS). |
| 2010 | AL0385 | IncludeCaption on a report column whose source is a global variable (writer QS; 0015 is an expression). |
| 2016 to 2039 | AL0104 / AL0105, AL0107 | A keyword as an unquoted parameter name, by value and after `var` (one file per word, both forms): `begin`, `procedure`, `trigger` give AL0104 ')' expected; `end`, `of`, `true`, `false`, `event`, `key`, `area`, `actions`, `chartpart`, `cuegroup`, `extends`, `fieldattribute`, `fieldelement`, `fieldgroups`, `pageextension`, `profileextension`, `tableelement`, `tableextension`, `textattribute`, `textelement` give AL0105; `var` gives AL0107; after `var` every word gives AL0107 first. The other diagnostics are the compiler's recovery (writer QT, AL Runner PR 5656). |
| 2040 | AL0224 | A variable named by a keyword (`"If": Integer`) used unquoted in a statement (writer QT, AL Runner PR 5642; quoted use compiles: misc/lt-bn3-identifiers/Bn3Labels.al). |
| 2048 | AL0132 | JsonArray has no Remove(JsonToken) method; RemoveAt removes by index (writer QV, AL Runner issue 5680). |
| 2061 | AL0122 | Ternary with a Boolean and an Integer branch, both orders, also into a Variant (writer QW, corpus issue 685). |
| 2062 | AL0777 | Ternary `Cond ? 'abc' : Guid`: the literal true branch sets a short Text type (writer QW). |
| 2063 | AL0369 | Ternary with a Byte or Char true branch and an Integer constant out of its range (writer QW). |
| 2064 | AL0122 | Ternary with a SecretText and a Text branch, both orders (writer QW). |
| 2065 | AL0122 | Ternary with two record types, a codeunit and an interface, two List types (writer QW). |
| 2066 | AL0130 | Ternary passed for a var parameter (writer QW). |
| 2067 | AL0122 | Ternary with an Integer condition (writer QW). |
| 2068 | AL0117 | Ternary used as a statement (writer QW). |
| 2069 | AL0122 | Ternary with a Date and an Integer branch, both orders (writer QW). |
| 2070 | AL0322 | Ternary in a page control's Visible or Editable property (writer QW). |
| 2071 | AL0196 | Bare and Rec. calls of a method that a table (cross-app fixture A) and a table extension of another app (fixture B) both declare, from a table extension in a third app (writer QY). |
| 2081 | AL0185 | A Record of the platform table Integer in a codeunit inside a namespace, without `using System.Utilities;` (writer RI). |
| 2082 | AL0185 | A report dataitem over the platform table Integer inside a namespace, without `using System.Utilities;` (writer RI). |
| 2110 | AL0118 | `Rec` in the OnOpenPage trigger of a report request page that declares no SourceTable (with SourceTable it compiles: report/lt-y-request-page/RsRequestPageRec.al) (writer RS). |
| 2111 | AL0118 | `Rec` in the OnOpenPage trigger of an xmlport request page that declares no SourceTable (with SourceTable it compiles: xmlport 88570 in xmlport/lt-y-xmlport-props/YXmlPortProps.al) (writer RS). |
| 2112 | AL0118 | `Rec` in the OnPreXmlPort trigger of an xmlport without a request page (with a request page SourceTable it compiles: xmlport 88570) (writer RS). |
| 2113 | AL0118 | `Rec` in the OnPreReport trigger of a report whose request page declares no SourceTable (with SourceTable it compiles: report 88562) (writer RS). |
| 2114 | AL0118 | `CurrPage` in the OnOpenPage trigger of an xmlport request page with SourceTable (`Rec` compiles there) (writer RS). |
| 2120, 2121 | AL0305 | A plain codeunit (no `Subtype = Test`) whose name has 31 / 36 characters (30 compiles: codeunit/TestScopeIsolationContracts.al) (writer SH). |
| 2122 to 2129 | AL0305 | A table, page, report, query, xmlport, table extension, page extension and report extension whose name has 31 characters (30 compiles for each; enum and enum extension names are not limited to 30: misc/lt-cv-odd-leads/CvEnumLongNames.al) (writer SH). |
| 2130 | AL0305 | A profile whose name has 31 characters (writer SH). |
| 2131 | AL0305 | A permission set whose name has 21 characters: "cannot exceed 20 characters" (20 compiles) (writer SH). |
| 2132 | AL0304 | An enum name of 119 characters in quotes: identifiers stop at 120 characters and the two quotes count (118 in quotes compile) (writer SH). |
| 2133 to 2135 | AL0304 | A field, procedure and local variable name of 121 characters (120 compiles; field names have no 30 character limit) (writer SH). |
| 2136 to 2146 | AL0264 | Two pages, reports, queries, xmlports, enums, table extensions, page extensions, enum extensions, report extensions, permission sets and permission set extensions with one id: both declarations are reported (writer SH). |
| 2147 | AL0264 | Three codeunits with one id: three diagnostics (writer SH). |
| 2148, 2149 | AL0264 | Cross-app: a codeunit / table with the id of an object of the app it depends on (XApp A): one diagnostic that names the other app; without the dependency it compiles (writer SH). |
| 2150 to 2166 | AL0139 | `exit(value)` in a table trigger, field trigger and procedure; page trigger, procedure and action; report trigger, data item trigger and procedure; xmlport trigger and procedure; query trigger and procedure; an event subscriber; a table extension trigger; a page extension procedure; an interface implementation without a return type (writer SH). |
| 2167 to 2170 | AL0135 | Too few arguments through a codeunit variable, a record variable, `Rec.`/bare inside the table, and `this.` (writer SH). |
| 2171 to 2173 | AL0126 | An overloaded procedure called with too few, no, or too many arguments: "No overload for method ... takes N arguments" with every candidate, not AL0135 (writer SH). |
| 2174 to 2188 | AL0135 | The signature text of AL0135 for Record, var Record, var temporary Record, Code[20], Option, Enum, Decimal, Date, var Integer, other scalar and complex parameter types, many parameters, return values and no arguments (writer SH). |
| 2214 | AL0157 | A variable of type TableFilter (writer SI, al-runner issue 5998). |
| 2238 to 2240, 2244 | AL0196 | In one app, a page extension procedure (local, or internal) with the name of a protected, public or internal base page procedure compiles, but a bare call of it is ambiguous (writer TI, al-runner issue 6043). A cross-app extension is accepted: pageext/lt-ext-local-same-name. |
| 2241 to 2243 | AL0440 | In one app, a protected or public page extension procedure with the name and parameters of a protected or public base page procedure (writer TI). A local base procedure never clashes. |

Accepted by the compiler, so not cases: an overload in a page extension (the name of a base procedure with other parameter types: tests/al-language/pageext/POPageExtOverload.al), and a bare `exit;` in a procedure with a return value. Also accepted (writer SH, AL 30 on BC 27, 28 and 29): enum, enum extension, enum value, interface and control add-in names longer than 30 characters, a permission set name of 20 characters, field, procedure and variable names of 31 to 120 characters (misc/lt-cv-odd-leads/CvEnumLongNames.al, `LongNamesThatCompile`), objects of different types with one id, an id that an app it does not depend on also uses, and `exit(value)` in the page triggers that return a value (OnQueryClosePage, OnFindRecord, OnNextRecord, OnInsertRecord, OnModifyRecord, OnDeleteRecord, a field OnLookup).

## CI

The reusable workflow compiles apps that must build, so it cannot run these. A job of its own is needed per BC major: install the AL compiler of
that major (`bc-linux/scripts/install-al-compiler.sh <bc_version>`), stage the symbols of that major (the step that fills `symbols/` in
`bc-test-from-source.yml`), then run `check-must-not-compile.py --al AL --symbols symbols --bc-major <major> --al-major <AL major>`. The job needs no
BC container. Run locally with the tools in `~/.al-tool-cache` it passes today with AL 16.2, 17.0.34, 18.0.43 and 30.0.42 on the 27.0 symbols.
| 2260 | AL0416 | A control add-in procedure declares a return value (writer TZ). |
| 2261 | AL0783 | A page extension calls a procedure of the base page's usercontrol (writer TZ). |
