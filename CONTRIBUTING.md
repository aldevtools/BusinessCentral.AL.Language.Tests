# Contributing to BusinessCentral.AL.Language.Tests

Thank you for contributing! This repo is an executable specification proving AL language features work in BC Cloud — every PR should add or strengthen a behavioral contract.

## Table of Contents

- [What to contribute](#what-to-contribute)
- [Writing a test](#writing-a-test)
- [Naming conventions](#naming-conventions)
- [Fixture library](#fixture-library)
- [Multi-app fixtures](#multi-app-fixtures)
- [Coverage gaps](#coverage-gaps)
- [Version-gated tests (preprocessor directives)](#version-gated-tests-preprocessor-directives)
- [Out-of-scope features](#out-of-scope-features)
- [Local development](#local-development)
- [Running CI locally](#running-ci-locally)
- [Test selection in CI](#test-selection-in-ci)
- [Pull request checklist](#pull-request-checklist)

---

## What to contribute

**Positive tests** — prove an AL language feature works correctly in BC Cloud. This is the primary contribution type. See the in-scope list in [CLAUDE.md](CLAUDE.md#in-scope-and-out-of-scope) for what belongs here.

**Negative tests (out-of-scope)** — prove that Cloud-restricted features throw the expected error. One test per surface area, placed in `tests/al-language/out-of-scope/`. Do not add more than one per feature.

If you are unsure whether something is in scope, open an issue first and describe what you want to test.

---

## Writing a test

### The two-rule contract

Every `[Test]` procedure must satisfy:

1. **It fails if the behavior is broken.** Would the test pass if the method always returned a default value (`0`, `''`, `false`)? If yes, strengthen the assertion.
2. **It proves, not just executes.** Assert a specific, non-default value that can only appear if the feature worked correctly.

### File structure

One codeunit per file, one behavioral claim per codeunit:

```al
// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/
//   dev-itpro/developer/methods-auto/record/record-insert-boolean-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT Universal (50900)
// BC versions: 27.5+

codeunit 60XXX "Record Insert Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Rec: Record "ALT Universal";
        Assert: Codeunit "Library Assert";

    [Test]
    procedure Record_Insert_AssignsSystemId()
    // CLAIM: Insert() assigns a non-empty SystemId to the record.
    begin
        Initialize();

        Rec.Init();
        Rec."No." := 1;
        Rec.Insert(false);

        Assert.AreNotEqual('', Format(Rec.SystemId), 'SystemId must be assigned after Insert');
    end;

    local procedure Initialize()
    begin
        Rec.DeleteAll();
    end;
}
```

### Rules

- **`Initialize()` first** — every `[Test]` procedure must call `Initialize()` as its first line. `Initialize()` must call `DeleteAll()` on every table used by the codeunit.
- **No per-test fixture definitions** — only use shared objects from `_fixtures/`. Never define tables, enums, pages, or codeunits in a test file.
- **One claim per codeunit** — a file named `TestRecordInsert.al` should only test `Record.Insert`.
- **Doc-link comment** — the top-of-file comment block must link to the relevant BC documentation page.

---

## Naming conventions

### Files

`Test<TypeName><Aspect>.al` — placed in the matching area subfolder:

```
tests/al-language/
  record/          TestRecordInsert.al, TestRecordFindFirst.al
  json/            TestJsonObjectGet.al, TestJsonArrayAdd.al
  query/           TestQueryOpen.al, TestQueryFilters.al
  xml/             TestXmlDocumentLoad.al
  text/            TestTextBuilderAppend.al
  out-of-scope/    TestFileSystemThrows.al, TestHttpClientThrows.al
```

### Procedures

`<Type>_<Method>_<Scenario>_<Outcome>` — the full claim must be readable from the name alone:

| Good | Bad |
|------|-----|
| `Record_Insert_DuplicateKey_Throws` | `TestInsert` |
| `Record_FindFirst_EmptyTable_ReturnsFalse` | `FindFirstOnEmptyTable` |
| `JsonObject_Get_MissingKey_ReturnsFalse` | `TestGetMissing` |
| `Record_Insert_AssignsSystemId` | `InsertSetsId` |

When there is no special condition, omit it: `Record_Insert_AssignsSystemId`.

### Codeunit IDs

The Cloud app (`tests/al-language`) declares two ID ranges: `60000–60999` and `67000–69999`. The first range is nearly full, so **allocate new objects from `67000–69999`**. Check existing files and open pull requests to avoid conflicts — `check-object-ids.py` and `check-cross-pr-object-ids.py` catch duplicates and out-of-range ids.

Do not edit `.github/workflows/ci.yml` for a new id block or a new range in `app.json`. The `codeunit_range` of every test job already covers `50000..99999`, every id a test app can use. The runner only runs the `Subtype = Test` codeunits of the job's own test app, so the ids of the other apps in that span cost nothing. The one gap is `75020..75024`, which is left out of the main app's range: those are `Subtype = Test` codeunits without a `[Test]` procedure, read only as metadata. A codeunit like that reports no result and fails the leg, so do not add another one in the range.

---

## Fixture library

All tests share a single fixture library in `_fixtures/`. Never define your own schema objects in a test file.

| Object | ID | When to use |
|--------|-----|-------------|
| ALT Universal | 50900 | Primitive field types: Integer, Text, Boolean, Decimal, Date, etc. |
| ALT Composite | 50901 | Multi-field primary keys, composite filters, Rename |
| ALT Triggered | 50902 | Verifying OnInsert / OnModify / OnDelete / OnRename triggers |
| ALT Trigger Log | 50903 | Asserting which triggers fired |
| ALT Parent / ALT Child | 50904/50905 | FlowFields: Sum, Count, Lookup |
| ALT Keyed | 50906 | SetCurrentKey, secondary key ordering |
| ALT Blob | 50908 | InStream / OutStream, Blob.HasValue |
| IALTCompute / ALTDouble / ALTSquare | — | Interface injection, codeunit-as-variable |
| ALT Event Publisher | 50910 | Published events, bind / unbind |

---

## Multi-app fixtures

Some behavior only shows when code is spread over several apps: an extension of a table that another app extends too, a subscriber in another app, the order of subscribers of different apps. Besides the main test app (`tests/al-language`) and the AL Internals Test Fixture (`tests/al-language-internals-fixture`), CI publishes five small apps for these cases. They hold no tests; the tests stay in the main test app, which depends on A, B and C. D depends on A only, and only C depends on D (so D is visited before C; writer UI).

| Folder | App id | Name | Publisher | Object ids | Depends on | What it is for |
|---|---|---|---|---|---|---|
| `tests/al-language-xapp-a` | `cd6a4292-f27b-4af9-89bc-15a5956f5c71` | AL Language XApp A | AL Language | 61100-61109, 61130-61139 | nothing | the base app: an event other apps subscribe to, tables other apps extend, a local event, a Company Triggers counter |
| `tests/al-language-xapp-b` | `c87ced6d-11a6-4ad2-87c7-ac10083d0a2f` | AL Language XApp B | Zulu Probe Publisher | 61110-61119, 61140-61149 | fixture, A | table extensions of A's tables, a page with a protected variable whose type is a fixture table |
| `tests/al-language-xapp-c` | `0df0fadc-d339-4b0f-a1d5-51dc51f10900` | AL Language XApp C | Bravo Probe Publisher | 61120-61129, 61150-61159 | B, A (in this order on purpose), D (not the fixture) | a page extension of B's page |
| `tests/al-language-xapp-d` | `e92be076-de11-44ed-895e-17031341df29` | AL Language XApp D | Mike Probe Publisher | 61160-61169 | A | a subscriber of an event of A, in an app that only C depends on and that depends on none of B, C and the main test app (subscriber order of apps that do not depend on each other) |
| `tests/al-language-xapp-e` | `04f582dd-d65c-4c89-bd08-b67e749aa43d` | AL Language XApp E | Echo Probe Publisher | 61170-61179 | nothing | the install codeunit and subscribers of the upgrade tag and company initialization probe (a separate app, so its install rows stay out of the main app's install-order test) |

CI publishes the fixture, A, D, B, C and then the main test app (D right after A, before B, on purpose) (`app_dirs` of every job in `ci.yml` that compiles `al-language`, and `$apps` in `nightly-windows.yml`). A change to one of these apps is a change to a dependency app, so the pull request gets a full run.

**The ids, names and publishers are fixed on purpose.** The cross-app subscriber order probe (`tests/al-language/events/lt-bw-subscriber-order/`) needs every candidate rule to predict another order of the four apps A, B, C and the main app (M):

| Rule | Order of the apps |
|---|---|
| dependency and publish order | A B C M |
| app id as text | C M B A |
| app id as the bytes of `Guid.ToByteArray` | B A M C |
| app id as a SQL Server `uniqueidentifier` | A C B M |
| app name | M A B C |
| publisher, then name | M A C B |

Each reversed order differs from all of these too. Each app has two object id blocks that interleave with the other apps' blocks, so an order by object id alone (ignoring the app) is also told apart. Do not change an app id, name or publisher, and do not move an object to another block, without redoing that table.

**Adding a cross-app case.**

1. Put the objects the other apps need into the app that fits the dependencies (A for a base object, B for an extension of A, C for an extension of B without the fixture). Use the free ids of that app's blocks; a new block needs a range outside every other app's `idRanges` (free today: 61170-61199 and 61350-61399).
2. Put the test into the main test app, as for any other test. It can name objects of A, B and C.
3. A cross-app case that must not compile goes into `tests/must-not-compile/cases/` with `// @depends AL Language XApp A,AL Language XApp B` (the names of the corpus apps the case app depends on; see `tests/must-not-compile/README.md`). To check it locally, compile the fixture, A, B and C first and put their `.app` files into the `--symbols` folder.
4. A new app is a bigger change: give it an id range outside every other app, add it to `app_dirs` of every job in `ci.yml` that compiles `al-language` (before `tests/al-language`), to `$apps` in `nightly-windows.yml`, to `CORPUS_DEPENDENCIES` in `.github/scripts/check-must-not-compile.py`, and to the tables above. Tell al-runtime-rs: its corpus runner loads the corpus apps by folder.

---

## Version-gated tests (preprocessor directives)

Tests that rely on APIs only available from a specific BC version must be wrapped in a preprocessor guard:

```al
#if BC28PLUS // XYZ overload added in BC 28
[Test]
procedure Record_NewBC28Feature_Works()
begin
    Initialize();
    // ...
end;
#endif
```

The CI matrix defines these symbols per version:

| Symbol | Meaning |
|--------|---------|
| `BC27PLUS` | Available from BC 27.0 onwards (always defined) |
| `BC28PLUS` | Available from BC 28.0 onwards |
| `BC29PLUS` | Available from BC 29.0 onwards |

The guard comment must explain **why** the guard exists — which API or behavior changed.

If you are writing a test for a feature available in all supported BC versions (27.5+), **no guard is needed**.

---

## Out-of-scope features

Features that are not available in BC Cloud each get **exactly one** negative test:

```al
[Test]
procedure File_Open_CloudSandbox_Throws()
// CLAIM: File.Open throws in a BC Cloud tenant.
begin
    Initialize();

    asserterror SomeFile.Open('test.txt');
    Assert.ExpectedError('');
end;
```

- Place in `tests/al-language/out-of-scope/`
- Name: `<Type>_<Method>_CloudSandbox_Throws`
- Do not add more than one test per out-of-scope surface area

Out-of-scope features: `File.*`, `HttpClient`, `File.Upload` / `File.Download`, SMTP, OData/SOAP calls from AL, background job scheduling, report rendering to PDF/Word/Excel, printing, `DotNet` interop.

---

## Coverage gaps

The working backlog for expanding language coverage lives in [docs/al-language-coverage-gaps.md](docs/al-language-coverage-gaps.md).

Use that document to pick the next AL surface to add before writing tests.

---

## Local development

You need a running BC on Linux container. See [StefanMaron/MsDyn365Bc.On.Linux](https://github.com/StefanMaron/MsDyn365Bc.On.Linux) for setup.

```bash
# Start BC (from bc-linux repo)
cd ~/Documents/Repos/bc-linux
docker compose up -d --wait

# Compile, publish, and run all tests
cd tests/al-language
al-compile && bc-publish && python3 run-bc-tests.py

# Run a single codeunit by ID
python3 run-bc-tests.py --ids 60100

# Run only tests in a specific ID range
python3 run-bc-tests.py --ids "60100..60199"
```

Default local credentials: `BCRUNNER` / `Admin123!`

To compile with `alc` directly and trust the result, run it through `scripts/check-alc-output.sh`
(for example `scripts/check-alc-output.sh alc /project:. /packagecachepath:pkgs /out:out.app`).
`alc | grep ': error'` can call a broken build clean: errors can print at column 0, and an empty
package cache can fail with no diagnostics. The script requires the start and end lines, exit
code 0, and no `error ALnnnn` line in either shape.

---

## Running CI locally

Open a pull request and GitHub Actions runs every BC leg, no self-hosted runner required. A pull request runs only the test codeunits its change can affect, and every merge to master runs all of them (see [Test selection in CI](#test-selection-in-ci)). Check the [Actions tab](https://github.com/StefanMaron/BusinessCentral.AL.Language.Tests/actions) for results.

You can also trigger a single-version run manually via **Actions → AL Language Test Suite → Run workflow** and entering a specific BC version.

---

## Test selection in CI

A full BC leg takes about 26 minutes, and about 21 of them are the "Run AL tests" step. So a pull request runs only the test codeunits that its change can affect. Every app is still compiled and published on every leg, and the job and check names stay the same.

### What runs on a pull request

`.github/scripts/select-tests.py` compares the pull request with its base branch. For each test job in `ci.yml` it selects:

- every test codeunit declared in a changed file;
- every test codeunit that uses an object the change touches, directly or through other objects. A codeunit uses an object when its source code names the object by name or by id (an object's own id and name in its header do not count). A changed extension object (`tableextension`, `pageextension`, `enumextension`, `reportextension`) also counts as a change to the object it extends;
- for a changed file that is not AL code (a report layout, an add-in script), the objects that name the file, and the test codeunits that use those objects.

An object the change touches is one whose code changed. An object in a changed file whose code is the same before and after (comments and line breaks do not count) is not one, unless the file's `namespace`, `using` or `#define` lines changed. If only comments changed in a file, the test codeunits that use its objects run.

#### Event subscribers

A subscriber runs when its publisher raises the event. So a test codeunit that uses the publisher also uses the subscriber, and the selection follows that path too:

- An automatic subscriber (the default `EventSubscriberInstance`) to an object of the test apps selects the test codeunits that use that publisher object, directly or through other objects. For example, a subscriber to the `OnAfterModifyEvent` of a table the same change adds selects the tests that use that table.
- A manual subscriber (`EventSubscriberInstance = Manual`) runs only after `BindSubscription` on an instance of its codeunit. It selects the test codeunits that use the subscriber codeunit, whatever its publisher. A manual subscriber that is also `SingleInstance = true` stays bound into later test codeunits, so it is treated like an automatic one.
- A subscriber that the change does not touch still counts when the change touches an object it uses: the test codeunits that use its publisher run.

Each leg also runs one small test codeunit that is not inside an `#if` (the summary calls it the sentinel). The test workflow fails a leg that ran no test at all, and a selected codeunit can be compiled out on an older BC version. A codeunit outside the job's `codeunit_range` is never selected, and neither is a `Subtype = Test` codeunit without a `[Test]` procedure.

The summary of the `prepare` job lists every selected codeunit and the reason it was selected, or the reason for a full run.

### When everything runs

Every test codeunit runs when one of these is true:

- The run is a push to master (so every merge gets a full run), or a manual run without `select_base` and without `select_codeunits`.
- The pull request comes from `al-runtime-rs-staging` (a corpus bump).
- The pull request has the label `full-run`.
- The change touches one of these:
  - a file under `.github/` (workflows and the scripts CI runs). One exception: a change to `ci.yml` that edits only the values of `codeunit_range` lines (a "CI range edit") is selected as usual, plus every test codeunit the edit brings into its job's range. Any other line changed in `ci.yml`, a comment included, means a full run;
  - an `app.json`, the symbols in an app's `.alpackages/` folder, or an app's resource folder (`NavApp.ListResources` sees every resource);
  - a dependency app: an app in `app_dirs` of a job and in no job's `test_app_dirs` (the fixture app `tests/al-language-internals-fixture` and the cross-app fixtures `tests/al-language-xapp-a`, `-b`, `-c` and `-d`; the other apps depend on the fixture and on A, B and C);
  - an event subscriber that can run during any test, when the change touches it, removes it, or touches an object it uses. That is an automatic subscriber whose publisher is:
    - not an object of the test apps (a platform, System Application or Base Application object, for example `Global Triggers`, `Company Triggers`, `Caption Class`, or a table event of `Customer`);
    - an install or upgrade event (the event name contains `Install` or `Upgrade`);
    - an object of the test apps that more than 40 test codeunits use. Shared fixture publishers such as `ALT Triggered` or `ALT Event Publisher` are used by more than 250; a subscriber there changes the behavior of many unrelated tests;
    - named the same as a Microsoft object in the symbol packages, so the scan cannot tell which one is meant;
    - written in a way the scan cannot read;
  - an `Install` or `Upgrade` codeunit that uses an object the change touches;
  - a codeunit with `Subtype = Install`, `Upgrade` or `TestRunner`;
  - a permission set, permission set extension or entitlement;
  - more than 50 files in the test apps;
  - a file outside the test apps that CI may read. These paths are known to be unused by CI and do not count: `docs/`, `scripts/`, `.claude/`, `tests/must-not-compile/`, Markdown files, `tests/al-surface*.json`, `v2-classification.json`, `.gitignore`, and apps under `tests/` that no CI job builds (the isolation probe).
- The selection is uncertain: a changed object that no test codeunit uses (a test can still reach it through metadata, for example `AllObj` filtered on an id range), an AL file with no object the script can read, or a changed non-AL file that no object names.
- Nothing is selected, for example when a pull request changes only documentation.
- The selection script fails. It never fails the build.

To force a full run on a pull request, add the label `full-run` and then push a commit or use **Re-run all jobs**. **Re-run failed jobs** reuses the earlier selection.

### What a subset run can miss

- A test that depends on data an earlier codeunit left in the database. A full run executes all codeunits one after the other on one database; a subset run skips most of them.
- A reference the scan cannot see, for example an object id computed at run time.

The full run on master after the merge covers both.

### Running a selection by hand

A manual run (**Actions → AL Language Test Suite → Run workflow**) takes `select_base`, a commit or a branch. The run then selects the tests affected by what the branch changed since it left `select_base`: the diff from the merge base of the two to the branch (three dots, `select_base...branch`). Later commits on `select_base` do not count, so a branch cut from master stays a subset run after master and staging move on. To see a selection without running CI:

```bash
python3 .github/scripts/select-tests.py --base origin/master --head HEAD
python3 .github/scripts/select-tests.py --base origin/al-runtime-rs-staging --head my-branch
```

A manual run can also take `select_codeunits`: the test codeunits to run, as a JSON object with one entry per test app, for example `{"tests/al-language":"50010,50012..50015","tests/al-language-onprem":"60011"}`. The run then uses this list as it is and reads no diff; `select_base` is ignored. Ids are separated by `,` or `|`, and `lo..hi` is a range. The `prepare` job keeps only the runnable test codeunits of the job's `codeunit_range` (a range never adds a `Subtype = Test` codeunit without a `[Test]` procedure), lists the ids it dropped, and adds each app's sentinel. An app the input leaves out runs only its sentinel. An input that cannot be read, or that names an app no test job reads, means a full run. GitHub limits all inputs of one dispatch to 65,535 characters together; every test codeunit of the corpus written out one by one is about 20,000.

The corpus CI batcher of al-runtime-rs uses `select_codeunits`. It merges many branches into one run, and the merged diff usually has more than 50 files, so `select_base` would mean a full run. The batcher passes the union of the selections of each branch alone instead. To check an input by hand:

```bash
python3 .github/scripts/select-tests.py --head HEAD --codeunits '{"tests/al-language":"50010,50012..50015"}'
```

---

## Pull request checklist

Before opening a PR, verify:

- [ ] `Initialize()` is the first line of every `[Test]` procedure
- [ ] `Initialize()` calls `DeleteAll()` on every table used in the codeunit
- [ ] No per-test fixture definitions — only `_fixtures/` objects
- [ ] Test name uniquely identifies the claim without opening the body
- [ ] Doc-link comment block is present at the top of the file
- [ ] Out-of-scope tests are in `out-of-scope/` and confirm the error only
- [ ] Version-gated code uses `#if BC28PLUS` (or equivalent) with an explanatory comment
- [ ] The test fails for the right reason (remove the assertion and confirm it passes; restore it and confirm it fails)
- [ ] CI passes on your pull request (all required checks)
