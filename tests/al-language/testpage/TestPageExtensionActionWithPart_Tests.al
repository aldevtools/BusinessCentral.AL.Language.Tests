// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpageactiontestpage-invoke-method
// Scope: in-scope
// Fixtures used: TPXP Row (60725), TPXP List (60726), TPXP FactBox (60727), TPXP List Ext (60728), Assert (60021)
//
// Pins TestPage.<Action>.Invoke() for an action a PAGEEXTENSION contributes when that SAME
// pageextension ALSO adds a part() to the page's layout. Companion to
// TestPageExtensionActionInvoke_Tests, which covers the no-part case; the discriminator here
// is exclusively the part() — everything else (action names, unspaced and spaced, trigger
// bodies) is identical in shape to that suite.

codeunit 60729 "TPXP Action Invoke Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "TPXP Row";
    begin
        Row.DeleteAll();
    end;

    local procedure SeedRows()
    var
        Row: Record "TPXP Row";
    begin
        Row.Init();
        Row."No." := 'A';
        Row.Descr := 'Alpha';
        Row.Insert();

        Row.Init();
        Row."No." := 'B';
        Row.Descr := 'Bravo';
        Row.Insert();
    end;

    // Positive: an unspaced action on a pageextension that ALSO adds a part() still
    // dispatches its own OnAction trigger.
    [Test]
    procedure ExtActionWithPartInvokeRunsTheOnActionTrigger()
    var
        Row: Record "TPXP Row";
        TpxpList: TestPage "TPXP List";
    begin
        Initialize();
        SeedRows();

        TpxpList.OpenEdit();
        TpxpList.First();
        TpxpList.StampExtWithPart.Invoke();
        TpxpList.Close();

        Assert.IsTrue(Row.Get('STAMPEXTPART'),
            'Invoke() must have run the pageextension''s OnAction trigger, even though the same pageextension also adds a part() to the layout');
    end;

    // Positive: a SPACED action name on the same part()-adding pageextension also dispatches
    // — the part() is not a name-mangling discriminator either.
    [Test]
    procedure ExtActionWithPartInvokeRunsTheSpacedActionTrigger()
    var
        Row: Record "TPXP Row";
        TpxpList: TestPage "TPXP List";
    begin
        Initialize();
        SeedRows();

        TpxpList.OpenEdit();
        TpxpList.First();
        TpxpList."Stamp Ext With Part Spaced".Invoke();
        TpxpList.Close();

        Assert.IsTrue(Row.Get('STAMPEXTPARTSPACED'),
            'Invoke() must have run the pageextension''s spaced-name OnAction trigger, even though the same pageextension also adds a part() to the layout');
    end;

    // Positive: the trigger runs in the PAGE's context — it reads Rec, and must see the row
    // the page is positioned on, exactly like the no-part companion suite proves.
    [Test]
    procedure ExtActionWithPartInvokeRunsAgainstThePagesCurrentRow()
    var
        Row: Record "TPXP Row";
        TpxpList: TestPage "TPXP List";
    begin
        Initialize();
        SeedRows();

        TpxpList.OpenEdit();
        TpxpList.First();
        TpxpList.Next();
        TpxpList.StampExtWithPart.Invoke();
        TpxpList.Close();

        Assert.IsTrue(Row.Get('STAMPEXTPART'), 'the extension action must have run');
        Assert.AreEqual('B', Row.Descr,
            'the extension action''s OnAction must have seen the row the page is positioned on');
    end;

    // Negative / isolation: invoking the part()-adding extension's action must not run the
    // base page's OWN action's trigger.
    [Test]
    procedure ExtActionWithPartInvokeRunsOnlyItsOwnTrigger()
    var
        Row: Record "TPXP Row";
        TpxpList: TestPage "TPXP List";
    begin
        Initialize();
        SeedRows();

        TpxpList.OpenEdit();
        TpxpList.First();
        TpxpList.StampExtWithPart.Invoke();
        TpxpList.Close();

        Assert.IsTrue(Row.Get('STAMPEXTPART'), 'the invoked extension action must have run');
        Assert.IsFalse(Row.Get('STAMP'),
            'invoking the extension action must not run the page''s own StampRow action');
    end;
}
