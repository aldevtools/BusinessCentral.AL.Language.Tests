// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-actionref-type
// Scope: in-scope
// Fixtures used: TPR Row (60764), TPR List (60765), TPR List Ext (60766), Assert (60021)
//
// Pins that TestPage.<Actionref>.Invoke() runs the OnAction trigger of the action the
// actionref POINTS AT.
//
// An `actionref` carries no trigger of its own — delegating to the action it names is the
// whole reason it exists, and `action(X) { trigger OnAction() ... }` in area(Processing) plus
// `actionref(X_Promoted; X)` in area(Promoted) is the standard promotion pattern every real
// page uses. A TestPage implementation that looked for a trigger on the ACTIONREF instead of
// following it to its target would find none, because there is none to find.
//
// The negatives carry the weight here, as in TestPageActionInvoke. "Invoke() did not throw"
// is worth nothing when the failure mode is running nothing at all, so every positive asserts
// a specific logged tag. One test invokes one ref and asserts the OTHER targets did not run,
// which a resolution that fell back to "the first OnAction on the page" would fail. And one
// asserts an Error raised inside the target propagates out through the ref, since swallowing
// it would turn a failing promoted action into a passing test.

codeunit 60767 "Test Page Promoted Actionref"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "TPR Row";
    begin
        Row.DeleteAll();
    end;

    local procedure SeedRows()
    var
        Row: Record "TPR Row";
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

    // Control arm: the target action invoked DIRECTLY. If this ever fails, every arm below is
    // measuring broken plumbing rather than actionref delegation.
    [Test]
    procedure DirectInvokeOfTheTargetRunsItsTrigger()
    var
        Row: Record "TPR Row";
        TprList: TestPage "TPR List";
    begin
        Initialize();
        SeedRows();

        TprList.OpenEdit();
        TprList.First();
        TprList.StampFlat.Invoke();
        TprList.Close();

        Assert.IsTrue(Row.Get('FLAT'), 'invoking the action directly must run its OnAction trigger');
    end;

    // The claim: an actionref sitting directly in the page's own area(Promoted) runs its
    // target's trigger.
    [Test]
    procedure PromotedActionrefInvokeRunsItsTargetsTrigger()
    var
        Row: Record "TPR Row";
        TprList: TestPage "TPR List";
    begin
        Initialize();
        SeedRows();

        TprList.OpenEdit();
        TprList.First();
        TprList.StampFlat_Promoted.Invoke();
        TprList.Close();

        Assert.IsTrue(Row.Get('FLAT'),
            'invoking a promoted actionref must run the OnAction trigger of the action it points at');
    end;

    // …and it runs in the PAGE's context, exactly as the direct invoke does: the target reads
    // Rec and must see the row the page is positioned on. Delegation that dispatched the
    // trigger against a detached record would stamp a blank No. here.
    [Test]
    procedure PromotedActionrefRunsItsTargetAgainstThePagesCurrentRow()
    var
        Row: Record "TPR Row";
        TprList: TestPage "TPR List";
    begin
        Initialize();
        SeedRows();

        TprList.OpenEdit();
        TprList.First();
        TprList.Next();
        TprList.StampFlat_Promoted.Invoke();
        TprList.Close();

        Assert.IsTrue(Row.Get('FLAT'), 'the promoted actionref must have run its target');
        Assert.AreEqual('B', Row.Descr,
            'the target''s OnAction must have seen the row the page is positioned on');
    end;

    // The same reference one level down, inside a promoted category group — the layout real
    // promoted pages actually use.
    [Test]
    procedure PromotedActionrefInsideAGroupRunsItsTargetsTrigger()
    var
        Row: Record "TPR Row";
        TprList: TestPage "TPR List";
    begin
        Initialize();
        SeedRows();

        TprList.OpenEdit();
        TprList.First();
        TprList.StampGrouped_Promoted.Invoke();
        TprList.Close();

        Assert.IsTrue(Row.Get('GROUPED'),
            'an actionref inside a promoted group must run its target''s OnAction trigger');
    end;

    // Negative: invoking one ref must not run any other target's trigger. A resolution that
    // matched loosely — by name prefix, or by taking the page's first OnAction method — would
    // pass every positive above while always running the same trigger.
    [Test]
    procedure PromotedActionrefRunsOnlyItsOwnTargetsTrigger()
    var
        Row: Record "TPR Row";
        TprList: TestPage "TPR List";
    begin
        Initialize();
        SeedRows();

        TprList.OpenEdit();
        TprList.First();
        TprList.StampGrouped_Promoted.Invoke();
        TprList.Close();

        Assert.IsTrue(Row.Get('GROUPED'), 'the invoked ref''s target must have run');
        Assert.IsFalse(Row.Get('FLAT'),
            'invoking StampGrouped_Promoted must not have run StampFlat''s trigger');
        Assert.IsFalse(Row.Get('EXT'),
            'invoking StampGrouped_Promoted must not have run the extension action''s trigger');
    end;

    // Negative: an Error raised inside the TARGET's OnAction must reach the test through the
    // ref. Swallowing it would make every failing promoted action look like a passing one.
    [Test]
    procedure PromotedActionrefPropagatesAnErrorRaisedInsideItsTarget()
    var
        TprList: TestPage "TPR List";
    begin
        Initialize();
        SeedRows();

        TprList.OpenEdit();
        TprList.First();
        asserterror TprList.AlwaysFails_Promoted.Invoke();
        Assert.ExpectedError('TPR promoted target refused deliberately');
    end;

    // A pageextension's promoted actionref pointing at an action the SAME extension declares.
    [Test]
    procedure PageExtensionPromotedActionrefRunsItsOwnExtensionActionsTrigger()
    var
        Row: Record "TPR Row";
        TprList: TestPage "TPR List";
    begin
        Initialize();
        SeedRows();

        TprList.OpenEdit();
        TprList.First();
        TprList.StampExt_Promoted.Invoke();
        TprList.Close();

        Assert.IsTrue(Row.Get('EXT'),
            'a pageextension''s promoted actionref must run its own extension action''s trigger');
    end;

    // The other direction across the same boundary: a pageextension's promoted actionref
    // pointing at an action the BASE PAGE declares.
    [Test]
    procedure PageExtensionPromotedActionrefRunsABasePageActionsTrigger()
    var
        Row: Record "TPR Row";
        TprList: TestPage "TPR List";
    begin
        Initialize();
        SeedRows();

        TprList.OpenEdit();
        TprList.First();
        TprList.StampBase_Promoted.Invoke();
        TprList.Close();

        Assert.IsTrue(Row.Get('BASE-VIA-EXT'),
            'a pageextension''s promoted actionref pointing at a BASE PAGE action must run that action''s trigger');
    end;
}
