// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-setvalue-method
// Scope: in-scope
// Fixtures used: Test Page Variable Control Row (60714), Test Page Variable Control (60715),
//   Assert (60021)
//
// Pins TestPage access to a control bound to a page GLOBAL VARIABLE rather than to a
// source-table field. This is ordinary AL — the standard way to put a mode/filter selector
// above a repeater.
//
// The negatives carry real weight here. A runner that satisfied the positives by stashing
// control values in one shared dictionary — the obvious cheap fix — would fail both of them:
// writing the page variable must not disturb the record's own fields, and the variable must
// not survive into a second, independent page instance.
//
// CodeField/DateField extend the same page with the other two primitive TestPage control
// types besides Text/Option: a page-global control's SetValue/Value dispatch must not assume
// every non-Option, non-Boolean control is Text-shaped underneath.

codeunit 60716 "Test Page Variable Ctrl Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "Test Page Variable Control Row";
    begin
        Row.DeleteAll();
    end;

    local procedure SeedRows()
    var
        Row: Record "Test Page Variable Control Row";
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

    // Positive: the control round-trips the page's own variable.
    [Test]
    procedure PageVariableControl_RoundTripsItsValue()
    var
        PgvList: TestPage "Test Page Variable Control";
    begin
        Initialize();
        SeedRows();

        PgvList.OpenEdit();
        PgvList.Mode.SetValue('Blocks');
        Assert.AreEqual('Blocks', PgvList.Mode.Value(),
            'the control bound to the page variable SelectedMode must read back what was written to it');
        PgvList.Close();
    end;

    // Positive: setting the control runs the page's AL. Asserting on a row the trigger
    // wrote — observed from OUTSIDE the page — is what separates "the value was stashed
    // and handed back" from "the page actually validated it".
    [Test]
    procedure PageVariableControl_FiresItsOnValidateTrigger()
    var
        Row: Record "Test Page Variable Control Row";
        PgvList: TestPage "Test Page Variable Control";
    begin
        Initialize();
        SeedRows();

        PgvList.OpenEdit();
        PgvList.Mode.SetValue('Fonts');
        PgvList.Close();

        Assert.IsTrue(Row.Get('ECHO'),
            'the control''s OnValidate trigger must have run and inserted the ECHO row');
        Assert.AreEqual('Fonts', Row.Descr,
            'OnValidate must have seen the value that was just assigned to the page variable');
    end;

    // Positive: Rec-bound controls on the same page keep working. A fix that routed every
    // control to the page instance would break these.
    [Test]
    procedure RecBoundControlsStillReadTheRecord()
    var
        PgvList: TestPage "Test Page Variable Control";
    begin
        Initialize();
        SeedRows();

        PgvList.OpenEdit();
        Assert.IsTrue(PgvList.First(), 'the page must be positioned on the first seeded row');
        Assert.AreEqual('A', PgvList."No.".Value(), 'the Rec-bound key control must read the record');
        Assert.AreEqual('Alpha', PgvList.Descr.Value(), 'the Rec-bound non-key control must read the record');
        PgvList.Close();
    end;

    // Negative: the page variable is NOT a record field. Writing it must leave the
    // current row untouched — a runner that resolved the control to some table field
    // (or wrote through to the record) would corrupt Descr here.
    [Test]
    procedure WritingThePageVariableDoesNotTouchTheRecord()
    var
        Row: Record "Test Page Variable Control Row";
        PgvList: TestPage "Test Page Variable Control";
    begin
        Initialize();
        SeedRows();

        PgvList.OpenEdit();
        Assert.IsTrue(PgvList.First(), 'the page must be positioned on the first seeded row');
        PgvList.Mode.SetValue('Images');
        Assert.AreEqual('Alpha', PgvList.Descr.Value(),
            'writing the page variable must not overwrite the current row''s Descr');
        PgvList.Close();

        Row.Get('A');
        Assert.AreEqual('Alpha', Row.Descr,
            'writing the page variable must not have been persisted into row A');
    end;

    // Positive: an Option control is set by its CAPTION, not by its member name. Asserting
    // on Format(SelectedKind) — written by OnValidate and read from outside the page —
    // proves the caption resolved to the right ORDINAL. A runner that stashed the string
    // 'Blocks', or that matched captions against member names positionally by accident,
    // would not produce 'Block' here.
    [Test]
    procedure OptionControl_SetByCaptionResolvesToTheRightMember()
    var
        Row: Record "Test Page Variable Control Row";
        PgvList: TestPage "Test Page Variable Control";
    begin
        Initialize();
        SeedRows();

        PgvList.OpenEdit();
        PgvList.KindSelector.SetValue('Blocks');
        PgvList.Close();

        Assert.IsTrue(Row.Get('KIND'), 'the option control''s OnValidate trigger must have run');
        Assert.AreEqual('Block', Row.Descr,
            'the caption ''Blocks'' must resolve to option member Block, not to its own text');
    end;

    // Positive: a caption whose position differs from the member it names. 'Custom Fields'
    // is caption #5 and must select member Custom — the case that catches an off-by-one or
    // a member-name-only lookup, since no member is called 'Custom Fields'.
    [Test]
    procedure OptionControl_MultiWordCaptionResolvesToItsMember()
    var
        Row: Record "Test Page Variable Control Row";
        PgvList: TestPage "Test Page Variable Control";
    begin
        Initialize();
        SeedRows();

        PgvList.OpenEdit();
        PgvList.KindSelector.SetValue('Custom Fields');
        PgvList.Close();

        Assert.IsTrue(Row.Get('KIND'), 'the option control''s OnValidate trigger must have run');
        Assert.AreEqual('Custom', Row.Descr,
            'the multi-word caption ''Custom Fields'' must resolve to option member Custom');
    end;

    // Negative: a value that is neither a caption nor a member name must be refused, not
    // silently coerced to the first member (ordinal 0), which would make every typo in a
    // test look like a pass.
    [Test]
    procedure OptionControl_RejectsAValueThatIsNeitherCaptionNorMember()
    var
        Row: Record "Test Page Variable Control Row";
        PgvList: TestPage "Test Page Variable Control";
    begin
        Initialize();
        SeedRows();
        // asserterror rolls back to the last commit; without this, that rollback also
        // undoes Initialize()'s DeleteAll (this codeunit has no TestIsolation = Function),
        // reverting to the 'KIND' row the previous test in this shared transaction left
        // behind — which is exactly what made Row.Get('KIND') below wrongly return true.
        Commit();

        PgvList.OpenEdit();
        asserterror PgvList.KindSelector.SetValue('Sprockets');
        Assert.ExpectedError('Sprockets');

        Assert.IsFalse(Row.Get('KIND'),
            'a rejected value must not have run OnValidate, i.e. must not have been assigned at all');
    end;

    // Negative: page state is per-instance. A second page starts with its variable at the
    // AL default, not at whatever the previous instance left behind.
    [Test]
    procedure PageVariableDoesNotLeakIntoASecondPageInstance()
    var
        First: TestPage "Test Page Variable Control";
        Second: TestPage "Test Page Variable Control";
    begin
        Initialize();
        SeedRows();

        First.OpenEdit();
        First.Mode.SetValue('Custom Fields');
        First.Close();

        Second.OpenEdit();
        Assert.AreEqual('', Second.Mode.Value(),
            'a freshly opened page must start with its own variable at the AL default, not the previous instance''s value');
        Second.Close();
    end;

    // Positive: a Code-typed page-global control round-trips its value.
    [Test]
    procedure CodeControl_RoundTripsItsValue()
    var
        PgvList: TestPage "Test Page Variable Control";
    begin
        Initialize();
        SeedRows();

        PgvList.OpenEdit();
        PgvList.CodeField.SetValue('CONF-001');
        Assert.AreEqual('CONF-001', PgvList.CodeField.Value(),
            'the control bound to the page variable SelectedCode must read back what was written to it');
        PgvList.Close();
    end;

    // Positive: setting the Code control runs the page's AL, observed from OUTSIDE the page —
    // the same proof PageVariableControl_FiresItsOnValidateTrigger uses for the Text control.
    [Test]
    procedure CodeControl_FiresItsOnValidateTrigger()
    var
        Row: Record "Test Page Variable Control Row";
        PgvList: TestPage "Test Page Variable Control";
    begin
        Initialize();
        SeedRows();

        PgvList.OpenEdit();
        PgvList.CodeField.SetValue('CONF-002');
        PgvList.Close();

        Assert.IsTrue(Row.Get('CODE'), 'the Code control''s OnValidate trigger must have run and inserted the CODE row');
        Assert.AreEqual('CONF-002', Row.Descr,
            'OnValidate must have seen the value that was just assigned to the Code page variable');
    end;

    // Positive: a Date-typed page-global control round-trips its value. Read back via
    // Evaluate() rather than a hardcoded string spelling, so the assertion holds no matter
    // which of BC's own date text formats Value() answers with, while still failing outright
    // if SetValue silently dropped the date or produced a different one.
    [Test]
    procedure DateControl_RoundTripsItsValue()
    var
        PgvList: TestPage "Test Page Variable Control";
        ReadBack: Date;
    begin
        Initialize();
        SeedRows();

        PgvList.OpenEdit();
        PgvList.DateField.SetValue(DMY2Date(31, 12, 2026));
        Evaluate(ReadBack, PgvList.DateField.Value());
        Assert.AreEqual(DMY2Date(31, 12, 2026), ReadBack,
            'the control bound to the page variable SelectedDate must read back the exact date that was written to it');
        PgvList.Close();
    end;

    // Positive: setting the Date control runs the page's AL, observed from OUTSIDE the page.
    [Test]
    procedure DateControl_FiresItsOnValidateTrigger()
    var
        Row: Record "Test Page Variable Control Row";
        PgvList: TestPage "Test Page Variable Control";
    begin
        Initialize();
        SeedRows();

        PgvList.OpenEdit();
        PgvList.DateField.SetValue(DMY2Date(15, 6, 2025));
        PgvList.Close();

        Assert.IsTrue(Row.Get('DATE'), 'the Date control''s OnValidate trigger must have run and inserted the DATE row');
        Assert.AreEqual(Format(DMY2Date(15, 6, 2025)), Row.Descr,
            'OnValidate must have seen the date that was just assigned to the Date page variable');
    end;
}
