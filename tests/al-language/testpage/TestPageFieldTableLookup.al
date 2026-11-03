// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers/devenv-triggers
// Scope: in-scope
// Fixtures used: TFL Row (60314), TFL Card (60315); shared Assert (60021)
//
/// <summary>
/// Pins which OnLookup trigger a TestPage field's Lookup() runs, when a page control and the
/// source table field both spell one.
///
/// AL has two unrelated triggers under that name. On a page control it is
/// OnLookup(var Text: Text) returning Boolean -- the text it writes back replaces the field's
/// value, and the Boolean says whether the user picked anything. On a table field it is
/// parameterless and writes into Rec itself. They are not overloads of each other and nothing
/// in the AL syntax connects them.
///
/// The claims, each in its own test:
///   - Lookup() on a field whose control declares NO trigger runs the source table field's
///     OnLookup, and the field afterwards reads what that trigger wrote.
///   - When both are declared, the CONTROL's trigger runs and the table field's does not.
///
/// The negative is in the data rather than in an asserterror: each trigger writes a different
/// literal, so a test that ran the wrong one fails naming the value it found, and a test that
/// ran NEITHER fails on the field still being blank. An implementation that simply ran both
/// would fail the second test, since the table trigger writes after the control's value would
/// have landed.
/// </summary>
codeunit 60316 "TFL Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure OpenOn(var Card: TestPage "TFL Card")
    var
        Row: Record "TFL Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row."No." := 'R1';
        Row.Insert();

        Card.OpenEdit();
        Card.GoToRecord(Row);
    end;

    // CLAIM: with no trigger on the control, Lookup() reaches the SOURCE TABLE FIELD's
    // OnLookup. The test never writes the field, so 'FROM-TABLE' can only have come from the
    // table trigger.
    [Test]
    procedure Lookup_ControlWithoutTrigger_RunsTheTableFieldsOnLookup()
    var
        Card: TestPage "TFL Card";
    begin
        OpenOn(Card);

        Card."Table Only".Lookup();

        Assert.AreEqual('FROM-TABLE', Card."Table Only".Value,
            'Lookup() on a control with no OnLookup must run the source table field''s OnLookup');
        Card.Close();
    end;

    // CLAIM: when the control declares one too, the control's trigger is the one that runs.
    // Both write to the same field, so the value says unambiguously which fired -- and says it
    // even if both fired, since the table trigger would then overwrite the control's text.
    [Test]
    procedure Lookup_ControlWithTrigger_WinsOverTheTableFieldsOnLookup()
    var
        Card: TestPage "TFL Card";
    begin
        OpenOn(Card);

        Card.Both.Lookup();

        Assert.AreEqual('FROM-CONTROL', Card.Both.Value,
            'a control''s own OnLookup must win over the source table field''s OnLookup');
        Card.Close();
    end;
}
