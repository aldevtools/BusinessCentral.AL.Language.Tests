// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagegotorecord-method
// Scope: in-scope
// Fixtures used: TPCF Row (60753), TPCF Card (60754), Assert (60021)

codeunit 60755 "TPCF Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize(var Row: Record "TPCF Row")
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'ROW1';
        Row.Flag := true;
        Row.Value := 'Filled';
        Row.Insert();
    end;

    // ---- the baseline, formalised in the corpus -----------------------------------------------
    //
    // Reproduces the informal finding this suite exists to settle: opened the ordinary way
    // (OpenView then GoToRecord), a control's Visible bound to a source-table field expression
    // reads as if the field held its type default, on a row where it plainly does not.

    [Test]
    procedure AtOpen_SourceFieldVisible_IsBlank_EvenOnANonDefaultRow()
    var
        Row: Record "TPCF Row";
        Card: TestPage "TPCF Card";
    begin
        Initialize(Row);

        Card.OpenView();
        Card.GoToRecord(Row);

        // Confirms the page actually navigated to the row this test just wrote — without this,
        // the two assertions below would mean nothing.
        Assert.AreEqual('Filled', Card.ValueCtl.Value(),
            'the page must be on the row just inserted before Visible means anything');

        Assert.IsFalse(Card.BoolVisible.Visible(),
            'Visible = Rec.Flag reads default(Boolean) = false even though Flag is true');
        Assert.IsFalse(Card.CmpVisible.Visible(),
            'Visible = (Rec.Value <> '''') reads false as if Value were blank, even though Value is ''Filled''');

        Card.Close();
    end;

    // ---- open question 1: is "blank" an artifact of evaluating before the record loads? -------
    //
    // The informal finding always navigated with GoToRecord AFTER OpenView. TestPage has no
    // SetRecord (that method exists only on the untestable Page type), so the closest ordering
    // variation the testability layer actually exposes is opening with NO GoToRecord call at
    // all: the table holds exactly the one row under test, so OpenView lands on it directly. If
    // the reading is still blank without GoToRecord ever running, GoToRecord itself is ruled out
    // as the explanation.

    [Test]
    procedure DirectOpenOnTheOnlyRow_SourceFieldVisible_IsStillBlank()
    var
        Row: Record "TPCF Row";
        Card: TestPage "TPCF Card";
    begin
        Initialize(Row);

        Card.OpenView();

        Assert.AreEqual('Filled', Card.ValueCtl.Value(),
            'the only row in the table must be the one OpenView lands on with no GoToRecord call');

        Assert.IsFalse(Card.CmpVisible.Visible(),
            'opening with NO GoToRecord at all still reads Visible = (Rec.Value <> '''') as blank — ' +
            'GoToRecord itself is not what causes the stale reading');

        Card.Close();
    end;

    // ---- open question 2: does anything ever unfreeze it? ------------------------------------
    //
    // Not an external Rec.Modify — an edit made THROUGH the page, the same way a user would make
    // it, to the exact field the expression reads. Starts from a row where the blank reading and
    // the real reading agree (both false), so the edit is the only thing that can move either.

    [Test]
    procedure EditingTheFieldThroughThePage_DoesNotUnfreezeSourceFieldVisible()
    var
        Row: Record "TPCF Row";
        Card: TestPage "TPCF Card";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'ROW1';
        Row.Flag := false;
        Row.Value := '';
        Row.Insert();

        Card.OpenView();
        Card.GoToRecord(Row);
        Assert.IsFalse(Card.BoolVisible.Visible(), 'baseline: both the blank and the real reading agree here');
        Assert.IsFalse(Card.CmpVisible.Visible(), 'baseline: both the blank and the real reading agree here');

        Card.FlagCtl.SetValue(true);
        Card.ValueCtl.SetValue('Filled');

        Assert.IsFalse(Card.BoolVisible.Visible(),
            'editing Flag through the page (not Rec.Modify) does not unfreeze Visible = Rec.Flag either');
        Assert.IsFalse(Card.CmpVisible.Visible(),
            'editing Value through the page does not unfreeze Visible = (Rec.Value <> '''') either');

        Card.Close();
    end;

    // ---- and the blank reading is not a session-scoped freeze ---------------------------------
    //
    // The row above now genuinely has Flag = true and Value = 'Filled' saved to the database — the
    // page edit committed it. A FRESH page instance, opened after the fact, still reads blank.
    // That rules out "the freeze just needs a session to end before a new one sees real data": the
    // blank reading recurs on every open, not only the one where the record was first bound.

    [Test]
    procedure ReopeningThePage_StillReadsBlank_EvenThoughTheRowNowHasRealData()
    var
        Row: Record "TPCF Row";
        Card: TestPage "TPCF Card";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'ROW1';
        Row.Flag := true;
        Row.Value := 'Filled';
        Row.Insert();

        Card.OpenView();
        Card.GoToRecord(Row);
        Card.Close();

        Card.OpenView();
        Card.GoToRecord(Row);
        Assert.AreEqual('Filled', Card.ValueCtl.Value(), 'the reopened page must be on the same row');
        Assert.IsFalse(Card.CmpVisible.Visible(),
            'a freshly reopened page still reads Visible = (Rec.Value <> '''') as blank, ' +
            'even though Value is genuinely ''Filled'' on disk');

        Card.Close();
    end;
}
