# codeunits

Codeunit.Run, OnRun, SingleInstance, TableNo, interfaces, procedures and overloads, call depth.

## Topics

- (area folder itself): 102 AL files that are about the area as a whole or were not given a topic yet.
- `call-depth/`: call depth (3 AL files).
- `code-coverage/`: code coverage (3 AL files).
- `interfaces/`: interfaces (12 AL files).
- `procedures/`: procedures, overloads, var parameters (5 AL files).
- `run-onrun/`: Codeunit.Run, OnRun and commit behavior (9 AL files).

A new topic gets a line here in the same pull request (standing rule 8 in CONTRIBUTING.md).

## Shared fixtures used here

- codeunit 69160 "Probe Observer": 33 files
- table 60000 "ALT Universal": 14 files
- codeunit 60014 "ALT Event Publisher": 6 files
- table 60003 "ALT Trigger Log": 5 files
- codeunit 60033 "ALT Manual Event Sub": 3 files
- codeunit 60015 "ALT Event Subscriber": 2 files
- page 60414 "ALT Run Tx None Card": 2 files
- codeunit 60967 "ALT IncludeSender Cu Pub": 1 file
- codeunit 60970 "ALT Sender Position Pub": 1 file
- table 60966 "ALT IncludeSender Table Pub": 1 file
- codeunit 60049 "ALTImplicitReturnCallee": 1 file
- codeunit 60036 "ALTImplicitReturnProbe": 1 file

## Other apps

- Same area in other apps (only what cannot compile in the Cloud app): none.
- Must-not-compile cases (52, in `tests/must-not-compile/cases/`, listed by `tests/must-not-compile/areas.tsv`): `0036-two-codeunits-same-id`, `0050-interface-not-implemented`, `0059-rec-in-codeunit-without-tableno`, `0213-unknown-codeunit-var`, `0215-implements-unknown-interface`, `0223-codeunit-run-unknown-id`, `0309-tableno-on-page`, `0310-datapercompany-on-codeunit`, `0312-unknown-property-codeunit`, `0322-interface-wrong-return-type`, `0323-interface-wrong-parameter`, `0324-interface-assign-unrelated`, `0325-interface-with-body`, `0353-xrec-in-codeunit`, `0356-call-local-procedure-other-codeunit`, `0357-protected-var-other-codeunit`, `0358-global-var-via-codeunit-variable`, `0360-protected-procedure-other-codeunit`, `0576-codeunit-run-by-name-runtime17`, `0705-interface-scope-onprem`, `0706-testisolation-on-test-codeunit`, `0780-codeunit-requiredtestisolation-without-test-subtype`, `0781-codeunit-testtype-without-test-subtype`, `0782-codeunit-testtype-invalid-value`, `0783-codeunit-requiredtestisolation-invalid-value`, `1242-codeunit-var-and-value-parameter-same-name`, `1377-interface-implementation-local-and-onprem`, `1388-as-cast-to-non-interface`, `1443-codeunit-protected-var-datascope`, `1445-internal-interface-keyword`, `1570-requiredpending-on-interface-method`, `1571-requiredpending-on-interface-method-before-29`, `1572-requiredpending-on-interface-method-bc27`, `1768-interface-impl-drops-temporary`, `1769-interface-from-unrelated-enum`, `1776-interface-declares-trigger`, `1777-defaultimplementation-same-interface-twice`, `1778-value-implementation-same-interface-twice`, `1779-scope-attribute-on-interface-member`, `1780-inherited-default-method-on-codeunit-variable`, `1781-onprem-override-of-default-method`, `2115-test-codeunit-name-31-characters`, `2120-codeunit-name-31-characters`, `2121-codeunit-name-36-characters`, `2147-three-codeunits-same-id`, `2148-codeunit-id-of-dependency-app`, `2166-exit-value-in-interface-implementation`, `2167-too-few-arguments-codeunit-variable`, `2262-enum-type-before-field-tableno-only-field-enum`, `2267-enum-type-before-field-tableno-onrun`, `2291-ternary-codeunit-true-interface-false`, `2712-compare-two-codeunit-variables-named-this`.

## Adding a test

1. Search this area for a test that already pins the behavior. If one does, cite it and write nothing.
2. Add `[Test]` procedures at the end of the existing codeunit of the topic. Make a new codeunit only for a new topic.
3. Use the shared fixtures. A local object needs a `// local object: <reason>` line.
4. Name the folder after the topic, never after a writer, an issue or a batch.
5. Never renumber a codeunit or rename a test. Read the standing rules in `CONTRIBUTING.md` first.
