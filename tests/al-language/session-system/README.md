# session-system

Session, Company, User, NavApp, IsolatedStorage, TaskScheduler, StartSession and the system functions.

## Topics

- (area folder itself): 83 AL files that are about the area as a whole or were not given a topic yet.
- `callstack/`: SessionInformation.Callstack read in triggers, procedures and events of every object type (5 AL files).
- `company/`: Company and CompanyName (6 AL files).
- `isolated-storage/`: IsolatedStorage and encryption (9 AL files).
- `session/`: Session, User and system functions (11 AL files).
- `system-application/`: System Application codeunits used from tests (2 AL files).

A new topic gets a line here in the same pull request (standing rule 8 in CONTRIBUTING.md).

## Shared fixtures used here

- codeunit 69160 "Probe Observer": 59 files
- table 60000 "ALT Universal": 7 files
- table 60003 "ALT Trigger Log": 2 files
- table 60291 "ALT CRM Entity": 2 files
- table 60002 "ALT Triggered": 1 file
- table 60004 "ALT Parent": 1 file
- table 60005 "ALT Child": 1 file
- table 60001 "ALT Composite": 1 file
- codeunit 67581 "ALT IS Store Subscriber": 1 file
- enum 60009 "ALT Status": 1 file
- table 60008 "ALT Blob": 1 file

## Other apps

- Same area in other apps (only what cannot compile in the Cloud app): `tests/al-language-onprem/session-system/`.
- Must-not-compile cases (12, in `tests/must-not-compile/cases/`, listed by `tests/must-not-compile/areas.tsv`): `0560-navapp-getcallstackmoduleinfos`, `0565-session-aitokensused-is-onprem`, `0567-database-changeuserpassword-is-onprem`, `0568-database-setuserpassword-is-onprem`, `0569-database-exportdata-is-onprem`, `0570-database-importdata-is-onprem`, `0575-session-logsecurityaudit-is-onprem`, `0963-isolatedstorage-get-isolationlevel`, `0965-navapp-resources-appid`, `2791-loadpackagedata-no-argument`, `2792-loadpackagedata-two-arguments`, `2793-loadpackagedata-used-as-value`.

## Line-sensitive files

These files assert line numbers or call stacks. Only append at the end of the codeunit; never add or remove lines above existing code (standing rule 5).

- `TestSessionCallstackSourcesContracts.al`
- `TestSessionInformationCallstackContracts.al`
- `callstack/P128Callstack.al`
- `callstack/P129CallstackQuery.al`
- `callstack/P135CallstackTable.al`
- `callstack/P136CsBase.al`
- `callstack/PnD09_CallstackSources.al`

## Adding a test

1. Search this area for a test that already pins the behavior. If one does, cite it and write nothing.
2. Add `[Test]` procedures at the end of the existing codeunit of the topic. Make a new codeunit only for a new topic.
3. Use the shared fixtures. A local object needs a `// local object: <reason>` line.
4. Name the folder after the topic, never after a writer, an issue or a batch.
5. Never renumber a codeunit or rename a test. Read the standing rules in `CONTRIBUTING.md` first.
