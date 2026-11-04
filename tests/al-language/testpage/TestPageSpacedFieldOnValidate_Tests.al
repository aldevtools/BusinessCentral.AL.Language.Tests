// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-field-setvalue-method
// Scope: in-scope
// Fixtures used: Spaced Field Row (60247), Spaced Field Card (60248), Assert (60021)
//
// Pins that TestPage.<Field>.SetValue runs the field control's page OnValidate
// trigger when the control NAME contains a space — the field-control sibling of
// TestPageSpacedActionName. The failure shape this guards against is nastier than
// the action one: the VALUE is still applied and the table-field validation still
// runs, only the page trigger is skipped, so nothing throws and the miss surfaces
// one step later as an assertion about the trigger's missing effect. Each spaced
// test therefore asserts the value-applied half separately from the trigger-ran
// half, so a failure names the exact half that broke.

codeunit 60249 "Spaced Field OnValidate Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "Spaced Field Row";
    begin
        Row.DeleteAll();
    end;

    local procedure SeedRow(No: Code[20]; var Row: Record "Spaced Field Row")
    begin
        Row.Init();
        Row."No." := No;
        Row.Insert();
    end;

    // Control: the unspaced sibling control on the same page dispatches its
    // OnValidate. If this fails the page itself is broken; if only the spaced
    // arm fails, the space in the control name is the trigger.
    [Test]
    procedure UnspacedControlOnValidateRunsOnSetValue()
    var
        Row: Record "Spaced Field Row";
        Card: TestPage "Spaced Field Card";
    begin
        Initialize();
        SeedRow('A1', Row);

        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.MarkerUnspaced.SetValue('x');
        Assert.AreEqual('UNSPACED-RAN', Card.Marker.Value,
            'the OnValidate of an unspaced field control must run on SetValue');
        Card.Close();
    end;

    // Positive: a spaced-name control's OnValidate dispatches on SetValue. The
    // value-applied assert comes first so a dispatcher that applies the value but
    // skips the trigger fails on the trigger assert specifically, not vaguely.
    [Test]
    procedure SpacedControlOnValidateRunsOnSetValue()
    var
        Row: Record "Spaced Field Row";
        Card: TestPage "Spaced Field Card";
    begin
        Initialize();
        SeedRow('B1', Row);

        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card."Marker Spaced".SetValue('x');
        Assert.AreEqual('x', Card."Marker Spaced".Value, 'the value itself must be applied');
        Assert.AreEqual('SPACED-RAN', Card.Marker.Value,
            'the OnValidate of a spaced-name field control must run on SetValue');
        Card.Close();
    end;

    // Negative: MarkerUnspaced and "Marker Spaced" bind the same table field but
    // are distinct controls. Setting the spaced one must run ITS trigger, not the
    // unspaced sibling's — a name-normalizing dispatcher could cross-match them.
    [Test]
    procedure SpacedControlOnValidateDoesNotRunTheSiblingsTrigger()
    var
        Row: Record "Spaced Field Row";
        Card: TestPage "Spaced Field Card";
    begin
        Initialize();
        SeedRow('C1', Row);

        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card."Marker Spaced".SetValue('x');
        Assert.AreNotEqual('UNSPACED-RAN', Card.Marker.Value,
            'setting the spaced control must not have run the unspaced sibling''s OnValidate');
        Assert.AreEqual('SPACED-RAN', Card.Marker.Value,
            'the spaced control''s own OnValidate must have run');
        Card.Close();
    end;

    // Negative: an Error raised inside a spaced-name control's OnValidate must
    // reach the test — a dispatcher that silently skips the trigger swallows it,
    // and SetValue on the always-failing control would just apply the value.
    [Test]
    procedure SpacedControlOnValidatePropagatesAnErrorRaisedInside()
    var
        Row: Record "Spaced Field Row";
        Card: TestPage "Spaced Field Card";
    begin
        Initialize();
        SeedRow('D1', Row);

        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror Card."Always Fails Spaced".SetValue('x');
        Assert.ExpectedError('Spaced Field Card control refused deliberately');
    end;
}
