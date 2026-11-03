# permissions

Permission sets, entitlements, access control, inherent permissions and TestPermissions.

## Topics

- (area folder itself): 34 AL files that are about the area as a whole or were not given a topic yet.
- `access-control/`: access control (5 AL files).
- `permission-sets/`: permission sets and entitlements (27 AL files).
- `testpermissions/`: TestPermissions and the runner permission sets (12 AL files).

A new topic gets a line here in the same pull request (standing rule 8 in CONTRIBUTING.md).

## Shared fixtures used here

- codeunit 69160 "Probe Observer": 52 files
- table 60000 "ALT Universal": 6 files
- table 60006 "ALT Keyed": 3 files
- table 60003 "ALT Trigger Log": 1 file
- table 60001 "ALT Composite": 1 file
- table 60404 "ALT Reten Pol Owned": 1 file
- table 60590 "ALT No Subscriber Table": 1 file

## Other apps

- Same area in other apps (only what cannot compile in the Cloud app): `tests/al-language-onprem/permissions/`.
- Must-not-compile cases (30, in `tests/must-not-compile/cases/`, listed by `tests/must-not-compile/areas.tsv`): `0708-entitlement-missing-id`, `0714-entitlement-roletype-invalid`, `0715-entitlement-role-without-id`, `0716-entitlement-roletype-groupname-on-implicit`, `0790-permissionset-excludedpermissionsets-unknown`, `0969-inherentpermissions-invalid-kind`, `0972-requiredpermissions-without-externalbusinessevent`, `0978-testpermissions-attribute-non-test`, `0979-testpermissions-normal`, `1712-permissionset-tabledata-onprem-table`, `1713-permissionset-table-object-onprem-table`, `1714-permissionset-internal-codeunit-other-app`, `1715-accessbypermission-page-read`, `1716-accessbypermission-codeunit-rimd`, `1718-accessbypermission-table-object-delete`, `1720-permissionsetextension-excludedpermissionsets`, `2131-permissionset-name-21-characters`, `2145-two-permissionsets-same-id`, `2146-two-permissionsetextensions-same-id`, `2333-permissionset-not-assignable-name-31-characters`, `2334-permissionset-no-assignable-name-31-characters`, `2360-permissions-property-codeunit-execute`, `2361-permissions-property-object-execute`, `2670-permission-set-moved-table-by-id`, `2671-permission-set-system-grant-kind-and-id`, `2672-permission-set-system-grant-unknown-name`, `2673-permission-set-system-grant-twice`, `2674-inherentpermissions-foreign-table`, `2785-accessbypermission-group`, `2786-accessbypermission-page-no-usagecategory`.

## Adding a test

1. Search this area for a test that already pins the behavior. If one does, cite it and write nothing.
2. Add `[Test]` procedures at the end of the existing codeunit of the topic. Make a new codeunit only for a new topic.
3. Use the shared fixtures. A local object needs a `// local object: <reason>` line.
4. Name the folder after the topic, never after a writer, an issue or a batch.
5. Never renumber a codeunit or rename a test. Read the standing rules in `CONTRIBUTING.md` first.
