# AL Language Coverage Test Suite — Agent Instructions

## What This Repo Is

An executable specification that proves AL language features work correctly
in **BC Cloud** (SaaS). Every test is a behavioral contract: a documented
AL feature + the actual BC runtime + a passing assertion.

### Primary goal — Cloud compatibility

Prove that the AL features the community relies on actually work in BC Cloud.
Every feature the language exposes gets a real test that exercises it against
the actual BC runtime and asserts on the real outcome — whether that outcome
is success or a specific thrown error. A test proving a call throws is just
as much a positive contribution as one proving it succeeds; what's not
acceptable is a stub that never calls the API at all (see the Verification
Checklist).

This repo has no "out of scope" list of its own. What a downstream consumer
(al-runtime-rs, which pins this repo as a submodule and uses the JUnit files of
its CI as its oracle) can or cannot execute is that project's concern, tracked
in its own repository — it does not shrink what gets tested here.

### Secondary goal — Language surface coverage

Over time, cover the full in-scope AL language surface documented in
`al-surface-inscope.json`. Every in-scope method should have at least one
positive and one negative test.

### Branches

`master` is the default branch. A ruleset protects it: changes come only
through a pull request whose required checks are green (the `BC <ver> / test`,
`BC OnPrem <ver> / test` and `BC OnPrem DotNet <ver> / test` legs for 27.5,
28.5 and 29.0, and `Object IDs must be unique and in range`). Pull requests are
merged with a merge commit.

Probe tests written for al-runtime-rs go through `al-runtime-rs-staging`:
writers branch from it, a publisher merges green writer branches into a bump
branch made from it and opens a bump pull request to `master`. After the merge,
staging is fast-forwarded to `master`.

A test that passes here but fails in a downstream consumer is a bug of that
consumer, not a reason to change the test. A test changes only when real BC
does something else.

---

## Scope

### Always in scope (write positive + negative tests)

- Record CRUD, filters, FlowFields, keys, triggers, SystemId, RecordId
- RecordRef / FieldRef full API
- Codeunit instantiation, interfaces, events (subscribe/publish/bind)
- Error handling: Error(), asserterror, ErrorInfo, collected errors
- Text, TextBuilder, BigText, Format, Evaluate
- JSON (JsonObject, JsonArray, JsonToken, JsonValue)
- XML (XmlDocument, XmlElement, XmlAttribute, XmlNamespaceManager)
- Query objects
- Streams (InStream, OutStream, Blob) -- in-memory only, no File
- Date/Time arithmetic and formatting
- Integer, Decimal, Boolean arithmetic and edge cases
- Guid, Variant, RecordId coercions
- List<T>, Dictionary<T,U>, Array
- Session functions: UserId, CompanyName, Today, CurrentDateTime
- Database: Commit, IsEmpty, Count, LockTable (in-scope overloads)
- NavApp: GetCurrentModuleInfo, resource access
- Notification, Page handler, Report handler, including rendering (Report.SaveAs
  to a stream, all formats -- Cloud renders these for real)
- `HttpClient` -- outbound HTTP is allowed in Cloud
- `DataTransfer`, `TaskScheduler` and other install/session-scoped APIs --
  write the negative test that proves what actually happens when called
  from a running test

### The two test apps, and which one a test belongs in

`tests/al-language` (Target = **Cloud**) is the primary app and where almost
every test goes. It is what "prove AL works in BC Cloud" means, and adding to
it needs no justification.

`tests/al-language-onprem` (Target = **OnPrem**) exists for one reason: some
AL surfaces cannot be *named* from a Cloud-target app, so no test in the Cloud
app can adjudicate them either way. Microsoft declares a number of system
tables `Scope = OnPrem`; naming one fails `AL0296` at compile, and the
`RecordRef` way round is refused at runtime by
`NavRecordRef.CheckIsOpenAllowed`. Both refusals are decided by the calling
app's **compilation target** and by nothing else -- `IsOpenAllowed` returns
`true` immediately for an OnPrem target -- so a second app with a different
target is all it takes to reach them.

**A test belongs in the OnPrem app only when it cannot compile in the Cloud
app.** That is the whole rule. It is not a general-purpose second home, and a
test that would compile in `tests/al-language` and was put here instead is
misfiled: it loses the Cloud guarantee that is this repo's primary goal. Keep
the OnPrem app small.

Its objects live in `61200..61299` and `98000..98999` (new objects: use 98000..98999; the OnPrem DotNet app has `61400..61499` and `99000..99499`), and it depends on the Cloud app so it can
reuse the shared `Assert` fixture rather than growing a second one.

### Untestable by construction -- document, don't stub

A small number of things have no AL statement that can invoke them from
headless test code at all:

- `File.Upload` / `File.Download` -- require a live browser round-trip
- Printing -- requires a live browser print dialog
- `File.*` -- scope `OnPrem`; the compiler rejects it for Target = Cloud
  (`AL0296`), confirmed against a live compile. It would now compile in the
  OnPrem app, and that is deliberately NOT a reason to test it there: what a
  Cloud consumer needs to know about `File` is that it is unavailable, which
  is a compile-time fact no runtime test adds to.
- `DotNet` interop -- same shape, same answer: the compiler rejects `DotNet`
  variables for Target = Cloud, and the OnPrem app is not an invitation to
  re-open surfaces Cloud deliberately removed

The OnPrem app is for surfaces where a Cloud consumer's question has a
*runtime* answer that only an OnPrem-target app can ask for -- the
`Scope = OnPrem` system tables -- not for everything that happens to compile
once the target changes.

For these, don't write a test at all -- a stub that never calls the API
(e.g. `Assert.IsTrue(true, ...)`) is worse than no test, since it reads as
coverage that doesn't exist. A one-line comment at the point where the
feature would otherwise be covered, explaining why, is enough.

---

## Writing a Test

### The test contract

Every [Test] procedure must satisfy two rules:

1. **It fails if the behavior is broken.** Ask: would this test pass if the
   method always returned a default value (0, '', false)? If yes, strengthen it.
2. **It proves, not just executes.** Assert a specific, non-default value.

### Structure

    [Test]
    procedure Record_Insert_DuplicateKey_Throws()
    // CLAIM: inserting a record with a key that already exists throws a runtime error.
    // DOCS: https://learn.microsoft.com/.../record-insert-boolean-method
    begin
        Initialize();

        Rec.Init();
        Rec."No." := 1;
        Rec.Insert(false);

        asserterror Rec.Insert(false);
        Assert.ExpectedError('already exists');
    end;

### Initialize()

Every test must call `Initialize()` as its first line. This calls
`ALTFixtureCleanup.DeleteAll()` -- the only acceptable way to reset state.
Never delete individual records by hand inside a test.

### Fixture objects

Use the shared fixture objects from `_fixtures/`. A test file defines its
own object only for a reason of standing rule 2 below, and says so in one
line: `// local object: <reason>`.

| Object | When to use |
|---|---|
| ALT Universal (60000) | Any test involving primitive field types |
| ALT Composite (60001) | Multi-field PK, composite filter, Rename |
| ALT Triggered (60002) | Trigger verification (OnInsert/Modify/Delete/Rename) |
| ALT Trigger Log (60003) | Assert which triggers fired |
| ALT Parent / ALT Child (60004/60005) | FlowFields, Sum/Count/Lookup |
| ALT Keyed (60006) | SetCurrentKey, secondary key ordering |
| ALT Blob (60008) | InStream/OutStream, Blob.HasValue |
| IALTCompute / ALTDouble (60011) / ALTSquare (60012) | Interface injection, codeunit-as-variable |
| ALT Event Publisher (60014) | Published events, bind/unbind |

### Standing rules for new tests (accepted 2026-11-03)

The full text is in CONTRIBUTING.md, "Standing rules for new tests". In short:

1. **Placement.** `tests/<app>/<area>/<topic>/File.al`, with the 30 areas
   listed in CONTRIBUTING.md. A new topic gets a line in the area README.
   No writer id, issue number or batch name in a folder name: no new
   `lt-<writer>-...`, `probes-needed-N`, `ms-refusals-N`, `triage` folders.
2. **Fixture first.** A local object only when its own definition is under
   test, the test asserts its name, id, caption or field names, the test must
   commit, run in another session or install, or it enumerates fields or
   keys. The file says so: `// local object: <reason>`.
3. **Object budget.** At most 3 non-test objects per new test codeunit without
   that line (enforced by an object budget check in CI, added in a later
   restructure pull request). Shared fixtures never change once merged; add a
   new one in 50000..50999.
4. **Look for a duplicate first** with `find-similar.py <draft>` (added in a
   later restructure pull request; until then search the corpus by hand). On a
   hit, cite the existing test and write nothing.
5. **Extend at the end.** Add `[Test]` procedures to the topic's existing
   codeunit (claims as today), at the end of the codeunit. Never insert lines
   above existing code in a line-sensitive file (listed in the area README).
6. **Keys never change.** Never renumber a codeunit or rename a `[Test]`
   procedure or a must-not-compile case. Moving files is fine. Removing or
   merging a test needs a `tests/rename-map.tsv` line and a green
   `Coverage facts must not shrink` check.
7. **Names.** New objects: `<area code> <topic> <role>` (for example
   `REC SetFilter Row`), unique. Existing names stay. Id blocks stay per writer.
8. **README.** A new topic, shared fixture or must-not-compile case updates
   the area README; a new must-not-compile case also adds its line to
   `tests/must-not-compile/areas.tsv`.
9. **No build outputs** in commits. One claim per test procedure; many test
   procedures per codeunit of a topic.

---

## Naming Conventions

### Files

`Test<TypeName><Aspect>.al` -- e.g. `TestRecordInsert.al`, `TestJsonObject.al`

Place in `<area>/<topic>/` of the app (standing rule 1): `record/crud/`,
`json/json/`, `text/text-methods/`, etc. -- including tests that prove a call
throws in Cloud; there is no separate out-of-scope folder.

### Procedures

`<Type>_<Method>_<Scenario>_<ExpectedOutcome>`

Examples:
- `Record_Insert_DuplicateKey_Throws`
- `Record_SetRange_DateField_FiltersCorrectly`
- `JsonObject_Get_MissingKey_ReturnsFalse`
- `HttpClient_Get_ValidUrl_ReturnsSuccessResponse`

The full claim must be readable from the procedure name alone.

### Doc-link comment block (top of each file)

    // BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/
    //   dev-itpro/developer/methods-auto/<type>/<method>-method
    // Scope: in-scope (Cloud-compatible)
    // Fixtures used: ALT Universal, ALT Triggered
    // BC versions: 27.5+

---

## Version Compatibility

All tests must pass on all versions in the CI matrix (currently 27.5, 28.5 and 29.0).

For features that only exist from a specific BC version onwards, wrap the
test in a preprocessor guard:

    #if BC28PLUS
    [Test]
    procedure SomeNewBC28Feature_Works()
    begin
        ...
    end;
    #endif

Preprocessor symbols are defined in the workflow per version:

| Symbol    | Meaning                        |
|-----------|--------------------------------|
| BC27PLUS  | Available from BC 27.0 onwards |
| BC28PLUS  | Available from BC 28.0 onwards |
| BC29PLUS  | Available from BC 29.0 onwards |

Add a comment explaining why the guard exists:

    #if BC28PLUS // System.GetLastErrorText overload with CallStack added in BC 28

---

## Verification Checklist

Before submitting a test:

1. `al-compile` produces zero errors (warnings are allowed).
2. The test passes against a real BC instance (local Docker or CI).
3. The test name uniquely identifies the claim without opening the body.
4. `Initialize()` is the first line of every [Test] procedure.
5. Shared `_fixtures/` objects used; every local object has a
   `// local object: <reason>` line (standing rule 2).
6. A test that asserts a call throws still calls the real API -- no
   `Assert.IsTrue(true, ...)` stubs.
7. The doc-link comment block is present at the top of the file.

---

## Local Development Setup

See `tests/al-language/PLAN.md` for the full compile-publish-run cycle.

Quick reference:

    # 1. Start BC (from bc-linux repo)
    cd ~/Documents/Repos/community/bc-linux && docker compose up -d --wait

    # 2. Compile + publish + run (from tests/al-language/)
    al-compile && bc-publish && python3 run-bc-tests.py

    # 3. Run a single codeunit
    python3 run-bc-tests.py --ids 60100

Default credentials: BCRUNNER / Admin123! (local dev container only).
