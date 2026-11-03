# language

Statements, operators, preprocessor directives, identifiers, scope, `with`, procedures as values: the language itself, apart from a data type or an object type.

## Topics

- (area folder itself): 8 AL files that are about the area as a whole or were not given a topic yet.
- `namespaces/`: namespaces and using directives (3 AL files).
- `obsolete-pending/`: objects and members with ObsoleteState Pending (3 AL files).

A new topic gets a line here in the same pull request (standing rule 8 in CONTRIBUTING.md).

## Shared fixtures used here

- codeunit 69160 "Probe Observer": 14 files

## Other apps

- Same area in other apps (only what cannot compile in the Cloud app): none.
- Must-not-compile cases (112, in `tests/must-not-compile/cases/`, listed by `tests/must-not-compile/areas.tsv`): `0008-dotnet-objects-equal`, `0016-duplicate-object-name`, `0043-duplicate-procedure`, `0044-duplicate-variable`, `0048-exit-value-without-return-type`, `0053-missing-semicolon`, `0054-object-id-out-of-range`, `0055-object-name-too-long`, `0065-test-procedure-with-return-value`, `0066-too-few-arguments`, `0067-too-many-arguments`, `0111-this-passed-to-var-parameter`, `0113-file-data-type-is-onprem`, `0200-unknown-variable-cu`, `0201-unknown-procedure-cu`, `0221-unknown-attribute`, `0240-contains-no-args`, `0242-own-proc-too-few`, `0243-own-proc-too-many`, `0244-own-proc-wrong-type`, `0245-own-proc-wrong-order`, `0250-message-no-args`, `0251-error-no-args`, `0274-exit-wrong-type`, `0275-return-procedure-without-value-used`, `0298-duplicate-parameter-name`, `0299-duplicate-global-variable`, `0300-duplicate-onrun-trigger`, `0303-duplicate-local-and-param`, `0314-property-wrong-type`, `0329-missing-then`, `0330-missing-end`, `0331-extra-end`, `0332-variable-named-begin`, `0333-variable-named-end`, `0335-semicolon-before-else`, `0336-missing-type`, `0337-procedure-no-parentheses`, `0345-var-param-expression`, `0346-var-param-function-result`, `0347-var-param-wrong-type`, `0348-exit-value-in-trigger`, `0361-file-exists-cloud`, `0362-file-erase-cloud`, `0571-system-canloadtype-is-onprem`, `0572-system-exportencryptionkey-is-onprem`, `0573-system-importencryptionkey-is-onprem`, `0583-comparison-with-and-without-parentheses`, `0593-semicolon-before-else`, `0762-field-masktype-invalid-value`, `0763-field-width-out-of-range`, `0764-field-width-negative`, `0773-field-masktype-with-extendeddatatype-masked`, `0967-native-procedure-with-body`, `0968-scope-unknown-value`, `0971-requiredpending-before-29`, `0973-runonclient-cloud`, `0974-suppressdispose-cloud`, `0976-securityfiltering-on-procedure`, `0981-scope-onprem-procedure-called-in-cloud-app`, `0982-scope-internal-procedure-called-in-cloud-app`, `0987-testdatasource-before-29`, `0988-testdatasource-without-itestdatasource`, `1170-commitbehavior-unknown-member`, `1171-commitbehavior-no-argument`, `1172-user-group-member-removed`, `1310-file-ispathtemporary-cloud`, `1311-file-download-cloud`, `1374-continue-outside-loop`, `1378-question-mark-and-star-in-variable-name`, `1379-braces-and-nested-block-comments`, `1383-region-overlaps-if`, `1386-verbatim-string-without-quote`, `1391-variable-names-differ-only-in-case`, `1416-field-owner-property`, `1428-attribute-on-parameter`, `1429-cloud-app-onprem-file-excel-methods`, `1573-define-after-first-token`, `1574-preprocessor-bang-not`, `1575-preprocessor-double-ampersand`, `1576-preprocessor-equals-true`, `1875-continue-statement-with-continue-parameter-procedure`, `2016-parameter-named-begin`, `2017-parameter-named-procedure`, `2018-parameter-named-trigger`, `2019-parameter-named-end`, `2020-parameter-named-of`, `2021-parameter-named-true`, `2022-parameter-named-false`, `2025-parameter-named-area`, `2029-parameter-named-extends`, `2030-parameter-named-fieldattribute`, `2031-parameter-named-fieldelement`, `2039-parameter-named-var`, `2040-keyword-variable-used-unquoted`, `2170-too-few-arguments-this`, `2171-overload-too-few-arguments`, `2172-overload-no-arguments`, `2173-overload-own-too-many-and-none`, `2185-too-few-arguments-many-parameters`, `2186-too-few-arguments-return-value`, `2187-too-few-arguments-named-return-value`, `2188-too-few-arguments-no-arguments`, `2355-dotnet-undeclared-full-type-name`, `2357-dotnet-quoted-full-type-name`, `2358-dotnet-full-type-name-of-own-alias`, `2359-dotnet-alias-ambiguous-with-system-application`, `2412-y31-lt-recordid`, `2628-clear-of-constant-or-expression`, `2629-clear-wrong-argument-count`, `2713-global-variable-through-this-variable`, `2718-clear-this-keyword`.

## Adding a test

1. Search this area for a test that already pins the behavior. If one does, cite it and write nothing.
2. Add `[Test]` procedures at the end of the existing codeunit of the topic. Make a new codeunit only for a new topic.
3. Use the shared fixtures. A local object needs a `// local object: <reason>` line.
4. Name the folder after the topic, never after a writer, an issue or a batch.
5. Never renumber a codeunit or rename a test. Read the standing rules in `CONTRIBUTING.md` first.
