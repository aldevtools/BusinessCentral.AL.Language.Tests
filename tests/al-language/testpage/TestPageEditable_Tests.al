// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-editable-method
// Scope: in-scope
// Fixtures used: Test Page Editable Row (60685), Test Page Editable Card (60686)
//
// TestPage must report a control's real Editable/Enabled state.
//
// A page protects data it does not own with control properties: Editable = false for a
// control that is never writable, Editable = SomeVar for one that depends on the row. Those
// properties ARE the read-only contract, and a TestPage is the only thing that can test them.
//
// A runner that answers Editable() with a constant true makes every such test unfailable.
// That is worse than a missing feature: the tests exist, they are green, and they assert
// nothing — so a regression that makes protected rows writable ships unnoticed.
//
// The default-editable and value-still-readable cases are load-bearing negatives: they are
// what a "just return false" fix fails.

codeunit 60687 "Test Page Editable Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Initialize()
    var
        Row: Record "Test Page Editable Row";
    begin
        Row.DeleteAll();
    end;

    local procedure SeedRows()
    var
        Row: Record "Test Page Editable Row";
    begin
        Row.Init();
        Row."No." := 'OPEN';
        Row.Name := 'open row';
        Row.Note := 'note-open';
        Row.Locked := false;
        Row.Insert();

        Row.Init();
        Row."No." := 'LOCKED';
        Row.Name := 'locked row';
        Row.Note := 'note-locked';
        Row.Locked := true;
        Row.Insert();
    end;

    local procedure OpenCardOn(No: Code[20]; var Card: TestPage "Test Page Editable Card")
    var
        Row: Record "Test Page Editable Row";
    begin
        Row.Get(No);
        Card.OpenEdit();
        Card.GoToRecord(Row);
    end;

    [Test]
    procedure ConstantEditableFalse_IsReportedAsNotEditable()
    var
        Card: TestPage "Test Page Editable Card";
    begin
        Initialize();
        SeedRows();
        OpenCardOn('OPEN', Card);

        // Editable = false is a compile-time constant on the control. Even on a row the page
        // considers fully editable, this control must not be.
        if Card."No.".Editable() then
            Error('"No.".Editable() was true, but the control declares Editable = false.');

        Card.Close();
    end;

    [Test]
    procedure NoEditableProperty_StaysEditable()
    var
        Card: TestPage "Test Page Editable Card";
    begin
        Initialize();
        SeedRows();
        OpenCardOn('OPEN', Card);

        // The default. A fix that reports false for everything passes every other test here
        // and fails this one.
        if not Card.Note.Editable() then
            Error('Note.Editable() was false, but the control declares no Editable property.');

        Card.Close();
    end;

    [Test]
    procedure EditableBoundToPageVariable_FollowsTheRow()
    var
        Card: TestPage "Test Page Editable Card";
    begin
        Initialize();
        SeedRows();

        // Editable = RowEditable, and OnAfterGetRecord sets RowEditable := not Rec.Locked.
        OpenCardOn('OPEN', Card);
        if not Card.Name.Editable() then
            Error('Name.Editable() was false on the unlocked row, expected true.');
        Card.Close();

        Clear(Card);
        OpenCardOn('LOCKED', Card);
        if Card.Name.Editable() then
            Error('Name.Editable() was true on the locked row, expected false.');
        Card.Close();
    end;

    [Test]
    procedure NotEditableControl_StillReadsItsValue()
    var
        Card: TestPage "Test Page Editable Card";
    begin
        Initialize();
        SeedRows();
        OpenCardOn('LOCKED', Card);

        // Not editable is not the same as not readable. A card shows read-only data; a fix
        // that suppressed the value along with the editability would break every list test.
        if Card.Name.Value() <> 'locked row' then
            Error('Name.Value() on the read-only row was <%1>, expected <locked row>.',
                Card.Name.Value());

        Card.Close();
    end;

    [Test]
    procedure ActionEnabledBoundToPageVariable_FollowsTheRow()
    var
        Card: TestPage "Test Page Editable Card";
    begin
        Initialize();
        SeedRows();

        OpenCardOn('OPEN', Card);
        if not Card.Rename.Enabled() then
            Error('Rename.Enabled() was false on the unlocked row, expected true.');
        Card.Close();

        Clear(Card);
        OpenCardOn('LOCKED', Card);
        if Card.Rename.Enabled() then
            Error('Rename.Enabled() was true on the locked row, expected false.');
        // An action with no Enabled property is the negative: it must stay enabled.
        if not Card.Refresh.Enabled() then
            Error('Refresh.Enabled() was false, but the action declares no Enabled property.');
        Card.Close();
    end;

    // Verified against real BC: TestPage.Editable() reflects the page's static open mode
    // (OpenEdit here), not a runtime CurrPage.Editable() toggle set from OnAfterGetRecord —
    // both the unlocked AND the locked row read back true, confirmed by opening fresh
    // directly on the locked row (ruling out stale state carried over from an earlier
    // GoToRecord). The per-control mechanism (EditableBoundToPageVariable_FollowsTheRow,
    // above) is the one that actually reacts to the row; this test pins the boundary
    // between the two so a platform change that makes them equivalent doesn't go unnoticed.
    [Test]
    procedure CurrPageEditable_TestPageGetterIgnoresTheRuntimeToggle()
    var
        Card: TestPage "Test Page Editable Card";
    begin
        Initialize();
        SeedRows();

        OpenCardOn('OPEN', Card);
        if not Card.Editable() then
            Error('TestPage.Editable() was false on the unlocked row, expected true.');
        Card.Close();

        Clear(Card);
        OpenCardOn('LOCKED', Card);
        if not Card.Editable() then
            Error('TestPage.Editable() was false on the locked row — if this starts failing, '
                + 'TestPage.Editable() has started reflecting CurrPage.Editable(), and this '
                + 'test (and its name) should be updated to assert the new, more useful behavior.');
        Card.Close();
    end;
}
