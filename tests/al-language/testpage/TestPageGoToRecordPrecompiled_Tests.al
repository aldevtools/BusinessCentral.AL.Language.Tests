// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-gotorecord-method
// Scope: in-scope
// Fixtures used: Test Page Modal Handler Row (60702), TP Precompiled Capture Ext (60735),
//   Assert (60021)
//
// Pins TestPage.GoToRecord on a page that ships PRECOMPILED (Base Application's "Item
// Attribute" card): GoToRecord must return true and actually position the page's cursor, and
// a pageextension action invoked afterwards must see the positioned row through Rec —
// including SystemId, not just normal fields. The suite's own source-compiled pages already
// get this everywhere; nothing about GoToRecord should care where the page's code came from.
//
// The two-row movement carries the weight: a page whose GoToRecord silently no-ops but
// happens to sit on the first row would pass a single-row capture, and one that always
// answers the first row fails the second capture. The SystemId assertion catches a Rec that
// is a plausible-looking copy rather than the positioned row.

codeunit 60736 "TP GoToRecord Precompiled"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Capture: Record "Test Page Modal Handler Row";
        ItemAttribute: Record "Item Attribute";
    begin
        Capture.DeleteAll();
        ItemAttribute.SetFilter(Name, 'ALTGTR-*');
        ItemAttribute.DeleteAll();
    end;

    local procedure CapturedValue(No: Code[20]): Text
    var
        Capture: Record "Test Page Modal Handler Row";
    begin
        Assert.IsTrue(Capture.Get(No), StrSubstNo('the capture action must have stored %1', No));
        exit(Capture.Descr);
    end;

    // Positive: GoToRecord returns true and the pageextension action's Rec reads the
    // positioned row — Name and SystemId both.
    [Test]
    procedure GoToRecord_OnPrecompiledPage_PageextActionSeesThePositionedRow()
    var
        AttrA: Record "Item Attribute";
        AttrB: Record "Item Attribute";
        Card: TestPage "Item Attribute";
    begin
        Initialize();
        AttrA.Init();
        AttrA.Name := 'ALTGTR-A';
        AttrA.Insert();
        AttrB.Init();
        AttrB.Name := 'ALTGTR-B';
        AttrB.Insert();

        Card.OpenEdit();
        Assert.IsTrue(Card.GoToRecord(AttrB), 'GoToRecord must find the row on a precompiled page');
        Card.CaptureRow.Invoke();

        Assert.AreEqual('ALTGTR-B', CapturedValue('CAPTURED-NAME'),
            'the pageextension action''s Rec must read the row GoToRecord positioned on');
        Assert.AreEqual(Format(AttrB.SystemId), CapturedValue('CAPTURED-SYSTEMID'),
            'the pageextension action''s Rec must carry the positioned row''s SystemId');
        Card.Close();
    end;

    // Negative for "always answers the first row": moving the cursor a second time must
    // change what the action sees.
    [Test]
    procedure GoToRecord_OnPrecompiledPage_SecondGoToRecordMovesTheCursor()
    var
        AttrA: Record "Item Attribute";
        AttrB: Record "Item Attribute";
        Card: TestPage "Item Attribute";
    begin
        Initialize();
        AttrA.Init();
        AttrA.Name := 'ALTGTR-A';
        AttrA.Insert();
        AttrB.Init();
        AttrB.Name := 'ALTGTR-B';
        AttrB.Insert();

        Card.OpenEdit();
        Assert.IsTrue(Card.GoToRecord(AttrB), 'GoToRecord must find the second row');
        Card.CaptureRow.Invoke();
        Assert.AreEqual('ALTGTR-B', CapturedValue('CAPTURED-NAME'),
            'the first capture must see the row the first GoToRecord positioned on');

        Assert.IsTrue(Card.GoToRecord(AttrA), 'GoToRecord must find the first row from the second');
        Card.CaptureRow.Invoke();
        Assert.AreEqual('ALTGTR-A', CapturedValue('CAPTURED-NAME'),
            'the second capture must see the row the second GoToRecord moved to');
        Card.Close();
    end;
}
