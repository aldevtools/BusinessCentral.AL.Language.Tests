// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testactionenabled-method
// Scope: in-scope
// Fixtures used: TPAE Row (60434), TPAE Log (60437), TPAE Card (60435), Assert (60021)

codeunit 60436 "TPAE Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    // The row on which every expression under test is TRUE.
    local procedure InitializeTrueRow(var Row: Record "TPAE Row")
    var
        Log: Record "TPAE Log";
    begin
        Row.DeleteAll();
        Log.DeleteAll();
        Row.Init();
        Row.PK := 'ROW1';
        Row.Flag := true;
        Row.Value := 'Filled';
        Row.LineType := Row.LineType::One;
        Row.Insert();
    end;

    // The row on which every expression under test is FALSE. Distinct PK so a test that
    // accidentally landed on the wrong row fails on the ValueCtl guard rather than silently.
    local procedure InitializeFalseRow(var Row: Record "TPAE Row")
    var
        Log: Record "TPAE Log";
    begin
        Row.DeleteAll();
        Log.DeleteAll();
        Row.Init();
        Row.PK := 'ROW2';
        Row.Flag := false;
        Row.Value := '';
        Row.LineType := Row.LineType::Zero;
        Row.Insert();
    end;

    // ---- an ACTION's Enabled bound to a source-table Boolean field ----------------------------

    [Test]
    procedure TPAE_ActionEnabledBoolField_TrueRow_IsEnabledAndItsTriggerRuns()
    var
        Row: Record "TPAE Row";
        Log: Record "TPAE Log";
        Card: TestPage "TPAE Card";
    begin
        InitializeTrueRow(Row);

        Card.OpenEdit();
        Card.GoToRecord(Row);
        Assert.AreEqual('Filled', Card.ValueCtl.Value(),
            'the page must be on the row just inserted before Enabled means anything');

        Assert.IsTrue(Card.ABoolField.Enabled(),
            'Enabled = Rec.Flag reads true on a row whose Flag is true');
        Card.ABoolField.Invoke();
        Card.Close();

        Assert.IsTrue(Log.Stamped('BOOL-FIELD'),
            'invoking an action whose Enabled = Rec.Flag is true on this row must run its OnAction');
    end;

    [Test]
    procedure TPAE_ActionEnabledBoolField_FalseRow_IsDisabledAndItsTriggerIsSkipped()
    var
        Row: Record "TPAE Row";
        Log: Record "TPAE Log";
        Card: TestPage "TPAE Card";
    begin
        InitializeFalseRow(Row);

        Card.OpenEdit();
        Card.GoToRecord(Row);

        Assert.IsFalse(Card.ABoolField.Enabled(),
            'Enabled = Rec.Flag reads false on a row whose Flag is false');
        Card.ABoolField.Invoke();
        Card.Close();

        Assert.IsFalse(Log.Stamped('BOOL-FIELD'),
            'invoking a disabled action must not run its OnAction, and must not raise');
    end;

    // ---- an ACTION's Enabled bound to a comparison against a source-table text field ----------

    [Test]
    procedure TPAE_ActionEnabledTextCompare_TrueRow_IsEnabledAndItsTriggerRuns()
    var
        Row: Record "TPAE Row";
        Log: Record "TPAE Log";
        Card: TestPage "TPAE Card";
    begin
        InitializeTrueRow(Row);

        Card.OpenEdit();
        Card.GoToRecord(Row);

        Assert.IsTrue(Card.ATextCompare.Enabled(),
            'Enabled = Rec.Value <> '''' reads true on a row whose Value is ''Filled''');
        Card.ATextCompare.Invoke();
        Card.Close();

        Assert.IsTrue(Log.Stamped('TEXT-COMPARE'),
            'the OnAction of an enabled text-comparison action must run');
    end;

    [Test]
    procedure TPAE_ActionEnabledTextCompare_FalseRow_IsDisabledAndItsTriggerIsSkipped()
    var
        Row: Record "TPAE Row";
        Log: Record "TPAE Log";
        Card: TestPage "TPAE Card";
    begin
        InitializeFalseRow(Row);

        Card.OpenEdit();
        Card.GoToRecord(Row);

        Assert.IsFalse(Card.ATextCompare.Enabled(),
            'Enabled = Rec.Value <> '''' reads false on a row whose Value is blank');
        Card.ATextCompare.Invoke();
        Card.Close();

        Assert.IsFalse(Log.Stamped('TEXT-COMPARE'),
            'the OnAction of a disabled text-comparison action must not run');
    end;

    // ---- an ACTION's Enabled bound to an Option compared against two of its members -----------

    [Test]
    procedure TPAE_ActionEnabledOptionCompare_TrueRow_IsEnabledAndItsTriggerRuns()
    var
        Row: Record "TPAE Row";
        Log: Record "TPAE Log";
        Card: TestPage "TPAE Card";
    begin
        InitializeTrueRow(Row);

        Card.OpenEdit();
        Card.GoToRecord(Row);

        Assert.IsTrue(Card.AOptionCompare.Enabled(),
            'an Option comparison reads true on a row whose LineType is One');
        Card.AOptionCompare.Invoke();
        Card.Close();

        Assert.IsTrue(Log.Stamped('OPTION-COMPARE'),
            'the OnAction of an enabled option-comparison action must run');
    end;

    [Test]
    procedure TPAE_ActionEnabledOptionCompare_FalseRow_IsDisabledAndItsTriggerIsSkipped()
    var
        Row: Record "TPAE Row";
        Log: Record "TPAE Log";
        Card: TestPage "TPAE Card";
    begin
        InitializeFalseRow(Row);

        Card.OpenEdit();
        Card.GoToRecord(Row);

        Assert.IsFalse(Card.AOptionCompare.Enabled(),
            'an Option comparison reads false on a row whose LineType is Zero');
        Card.AOptionCompare.Invoke();
        Card.Close();

        Assert.IsFalse(Log.Stamped('OPTION-COMPARE'),
            'the OnAction of a disabled option-comparison action must not run');
    end;

    // ---- a CONTROL's Enabled and Editable bound to a source-table field -----------------------
    //
    // The neighbour of codeunit 60755's Visible measurement, and the reason this suite exists as
    // a separate one: these two answer from the current row where Visible does not.

    [Test]
    procedure TPAE_ControlEnabledAndEditable_TrueRow_BothReadTrue()
    var
        Row: Record "TPAE Row";
        Card: TestPage "TPAE Card";
    begin
        InitializeTrueRow(Row);

        Card.OpenEdit();
        Card.GoToRecord(Row);
        Assert.AreEqual('Filled', Card.ValueCtl.Value(), 'the page must be on the inserted row');

        Assert.IsTrue(Card.EnabledCtl.Enabled(),
            'a control''s Enabled = Rec.Flag reads true on a row whose Flag is true');
        Assert.IsTrue(Card.EditableCtl.Editable(),
            'a control''s Editable = Rec.Flag reads true on a row whose Flag is true');

        Card.Close();
    end;

    [Test]
    procedure TPAE_ControlEnabledAndEditable_FalseRow_BothReadFalse()
    var
        Row: Record "TPAE Row";
        Card: TestPage "TPAE Card";
    begin
        InitializeFalseRow(Row);

        Card.OpenEdit();
        Card.GoToRecord(Row);

        Assert.IsFalse(Card.EnabledCtl.Enabled(),
            'a control''s Enabled = Rec.Flag reads false on a row whose Flag is false');
        Assert.IsFalse(Card.EditableCtl.Editable(),
            'a control''s Editable = Rec.Flag reads false on a row whose Flag is false');

        Card.Close();
    end;
}
