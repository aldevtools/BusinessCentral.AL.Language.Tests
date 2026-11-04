// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-data-type
// Scope: in-scope
// Fixtures used: TRT Row (60839), TRT Echo (60840), TRT Card (60841), TRT Card No Insert (60842), TRT Singleton Card (60843)
//
// Migrated from AL Runner tests/runner-extras/testpage-record-triggers (TrtTests.Codeunit.al).
//
/// <summary>
/// The standard AL new-record flow is <c>OpenNew()</c>, set a few fields, <c>OK().Invoke()</c>,
/// and everything that makes the resulting row CORRECT lives in the page's record triggers:
/// OnNewRecord seeds the defaults a blank record does not have, OnInsertRecord gets the last
/// word before the persist.
///
/// A runner that skips them still inserts a row — just not the row the page would ever have
/// produced. The test then fails complaining about a field value, several layers from the
/// trigger that never ran, which reads like an application bug rather than a missing trigger.
/// </summary>
codeunit 60844 "TRT Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Initialize()
    var
        Row: Record "TRT Row";
        Echo: Record "TRT Echo";
    begin
        Row.DeleteAll();
        Echo.DeleteAll();
    end;

    [Test]
    procedure OpenNew_RunsOnNewRecordBeforeTheFieldsAreSet()
    var
        Row: Record "TRT Row";
        Card: TestPage "TRT Card";
    begin
        Initialize();

        Card.OpenNew();
        Card."No.".SetValue('NEW-1');
        Card.OK().Invoke();

        Row.Get('NEW-1');
        // Kind::Tenant is 1 and only OnNewRecord sets it; a blank record carries Extension (0).
        if Row.Kind <> Row.Kind::Tenant then
            Error('Kind was %1, expected Tenant — OnNewRecord did not run.', Format(Row.Kind));
    end;

    [Test]
    procedure OnInsertRecord_RunsBeforeTheRowIsPersisted()
    var
        Row: Record "TRT Row";
        Card: TestPage "TRT Card";
    begin
        Initialize();

        Card.OpenNew();
        Card."No.".SetValue('NEW-2');
        Card.Note.SetValue('typed-by-user');
        Card.OK().Invoke();

        Row.Get('NEW-2');
        // "Insert Stamp" is written only by OnInsertRecord, never by the client — a stale
        // value proves the trigger never ran. (Note itself is NOT a valid probe for this:
        // verified against real BC that a field the client also edited persists the
        // client's value regardless of what OnInsertRecord assigns to that same field.)
        if Row."Insert Stamp" <> 'stamped-by-oninsert' then
            Error('Insert Stamp was <%1>, expected <stamped-by-oninsert> — OnInsertRecord did not run.',
                Row."Insert Stamp");
        if Row.Note <> 'typed-by-user' then
            Error('Note was <%1>, expected <typed-by-user> — the client-edited field must persist as typed.',
                Row.Note);
    end;

    [Test]
    procedure OnInsertRecord_ReturningFalse_SuppressesTheInsert()
    var
        Row: Record "TRT Row";
        Card: TestPage "TRT Card No Insert";
    begin
        Initialize();

        Card.OpenNew();
        Card."No.".SetValue('VETOED');
        Card.OK().Invoke();

        // The negative that gives the trigger meaning: its RETURN VALUE decides whether the
        // row is written at all. A runner that runs the trigger and ignores the result passes
        // every other test here and fails this one.
        if Row.Get('VETOED') then
            Error('The row was inserted even though OnInsertRecord returned false.');
    end;

    [Test]
    procedure OK_PersistsTheNewRowImmediately()
    var
        Row: Record "TRT Row";
        Card: TestPage "TRT Card";
    begin
        Initialize();

        Card.OpenNew();
        Card."No.".SetValue('NEW-3');
        Card.OK().Invoke();

        // Right after OK, before Close or Dispose. Persisting only at teardown means every
        // assertion a test makes between the two reads a table that does not have the row yet.
        if not Row.Get('NEW-3') then
            Error('The row was not persisted by OK().Invoke().');
    end;

    // Verified against real BC, two platform facts, neither the original test's premise:
    //   1. TestPage.Cancel() needs a genuine client Cancel affordance — a plain Card page
    //      opened via OpenNew() (not run modally) has none, so TestPage.Cancel() raises
    //      "The built-in action = Cancel is not found on the page." regardless of what
    //      actions the page declares.
    //   2. Close() is NOT a discard. The row does not exist before Close() (confirmed by
    //      probing Row.Get() immediately before it) but does exist after — Close() on a
    //      dirty new-record Card page persists it, the same as OK() does. A plain
    //      SourceTable-bound Card page opened via OpenNew() has no client-level way to
    //      abandon a new row at all; that needs an explicit AL mechanism (e.g. an
    //      OnQueryClosePage guard, or InsertAllowed = false — see TestPageInsertAllowed_Tests),
    //      not a bare Close().
    [Test]
    procedure Close_WithoutOK_StillPersistsTheNewRow()
    var
        Row: Record "TRT Row";
        Card: TestPage "TRT Card";
    begin
        Initialize();

        Card.OpenNew();
        Card."No.".SetValue('CLOSED-NO-OK');
        if Row.Get('CLOSED-NO-OK') then
            Error('the row must not exist before Close() persists it — this assertion catches a '
                + 'test environment where the record was already inserted eagerly on SetValue.');
        Card.Close();

        if not Row.Get('CLOSED-NO-OK') then
            Error('Close() on a dirty new-record Card page must persist it, the same as OK() — '
                + 'if this starts failing, real BC has started letting Close() discard, and '
                + 'Cancel_DiscardsTheNewRow (see TestPageInsertAllowed_Tests for the pattern of '
                + 'proving a refused write) should be reinstated instead of this test.');
    end;

    [Test]
    procedure OnOpenPage_RunsBeforeThePageIsRead()
    var
        Row: Record "TRT Row";
        Card: TestPage "TRT Singleton Card";
    begin
        Initialize();

        Card.OpenEdit();

        // The page had no row to open on; OnOpenPage is what creates and selects one.
        if Card."No.".Value() <> 'SINGLETON' then
            Error('The page opened on <%1>, expected SINGLETON — OnOpenPage did not run.',
                Card."No.".Value());
        if not Row.Get('SINGLETON') then
            Error('OnOpenPage did not create the singleton row.');

        Card.Close();
    end;

    [Test]
    procedure OnOpenPage_LeavesTheRecordUsableByThePagesOwnActions()
    var
        Row: Record "TRT Row";
        Card: TestPage "TRT Singleton Card";
    begin
        Initialize();

        Card.OpenEdit();
        // The real consequence: an action that Modifies the row OnOpenPage fetched. On an
        // unpositioned record this fails with "the row does not exist" naming a blank key,
        // which is how the missing trigger actually surfaced.
        Card.Stamp.Invoke();
        Card.Close();

        Row.Get('SINGLETON');
        if Row.Note <> 'stamped' then
            Error('The action''s Modify did not reach the row: Note is <%1>.', Row.Note);
    end;

    [Test]
    procedure OnClosePage_RunsWhenThePageIsClosed()
    var
        Echo: Record "TRT Echo";
        Card: TestPage "TRT Singleton Card";
    begin
        Initialize();

        Card.OpenEdit();
        if Echo.Get('CLOSED') then
            Error('OnClosePage ran before the page was closed.');

        Card.Close();

        if not Echo.Get('CLOSED') then
            Error('OnClosePage did not run on Close().');
    end;

    [Test]
    procedure OnAfterGetCurrRecord_RunsWhenTheCursorMoves()
    var
        Row: Record "TRT Row";
        Echo: Record "TRT Echo";
        Card: TestPage "TRT Card";
        Before: Integer;
    begin
        Initialize();

        Row.Init();
        Row."No." := 'A';
        Row.Insert();
        Row.Init();
        Row."No." := 'B';
        Row.Insert();

        Card.OpenEdit();
        Card.First();
        if Echo.Get('CURR') then
            Before := Echo.Hits;

        Card.Next();

        // OnAfterGetCurrRecord is the trigger that fires on EVERY navigation, including one to
        // an already-fetched record — which is why a page that must refresh derived state on
        // every move uses it rather than OnAfterGetRecord.
        if not Echo.Get('CURR') then
            Error('OnAfterGetCurrRecord never ran.');
        if Echo.Hits <= Before then
            Error('OnAfterGetCurrRecord did not run on Next(): hits stayed at %1.', Echo.Hits);
    end;
}
