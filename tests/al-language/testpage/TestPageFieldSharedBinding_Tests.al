// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-value-method
// Scope: in-scope
// Fixtures used: TP Shared Bind Row (60771), TP Shared Bind Card (60772), Assert (60021)
//
// A page may show ONE value through MORE THAN ONE control, and the second control is as
// readable and as writable through a TestPage as the first. TestPageSharedSourceField already
// pins that for two controls over one SOURCE-TABLE field; this suite pins the other two
// bindings a control can carry, where the page's own state is what is shared:
//
//   * a page GLOBAL variable                    (GlobalFirst  / GlobalSecond)
//   * a field of a page-global temporary Record (BufferFirst  / BufferSecond)
//
// Both shapes are ordinary AL and both are common in Microsoft's own Base Application — page
// 1612 "Office Admin. Credentials" shows PasswordText through two controls, page 1327 "Adjust
// Inventory" shows each TempItemJournalLine field through two.
//
// Every test reads through the SECOND control, and the writes go in both directions, so an
// implementation that resolves only the first control of a binding — or that collapses the
// second one onto the source table — fails here while every single-control suite still passes.

codeunit 60773 "TP Shared Bind Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "TP Shared Bind Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'ROW1';
        Row.Value := 'row value';
        Row.Insert();
    end;

    // Baseline. If this fails, nothing below is about a SHARED binding.
    [Test]
    procedure FirstControlOverAPageGlobal_ShowsTheGlobalsValue()
    var
        Card: TestPage "TP Shared Bind Card";
    begin
        Initialize();

        Card.OpenEdit();
        Assert.AreEqual('seeded global', Card.GlobalFirst.Value(),
            'the first control over the page global must show what OnOpenPage assigned it');
        Card.Close();
    end;

    // The claim. The compiler is free to register ONE binding for the two controls; both must
    // still resolve, and both must show the value the page global actually holds.
    [Test]
    procedure SecondControlOverAPageGlobal_ShowsTheSameValue()
    var
        Card: TestPage "TP Shared Bind Card";
    begin
        Initialize();

        Card.OpenEdit();
        Assert.AreEqual('seeded global', Card.GlobalSecond.Value(),
            'the second control over the same page global must show the same value as the first');
        Card.Close();
    end;

    [Test]
    procedure WriteThroughTheFirstControlOverAPageGlobal_IsSeenByTheSecond()
    var
        Card: TestPage "TP Shared Bind Card";
    begin
        Initialize();

        Card.OpenEdit();
        Card.GlobalFirst.SetValue('written first');
        Assert.AreEqual('written first', Card.GlobalSecond.Value(),
            'both controls read one page global, so a write through one must be visible in the other');
        Card.Close();
    end;

    [Test]
    procedure WriteThroughTheSecondControlOverAPageGlobal_IsSeenByTheFirst()
    var
        Card: TestPage "TP Shared Bind Card";
    begin
        Initialize();

        Card.OpenEdit();
        Card.GlobalSecond.SetValue('written second');
        Assert.AreEqual('written second', Card.GlobalFirst.Value(),
            'the shared binding is one variable, so the write direction must not matter');
        Card.Close();
    end;

    // Discriminator: the shared binding is the page GLOBAL, not the source table. A write
    // through a global-bound control must leave the row alone, and the Rec-bound controls must
    // go on showing the row.
    [Test]
    procedure WriteThroughAPageGlobalControl_LeavesTheRowAlone()
    var
        Row: Record "TP Shared Bind Row";
        Card: TestPage "TP Shared Bind Card";
    begin
        Initialize();

        Card.OpenEdit();
        Card.GlobalFirst.SetValue('written first');
        Assert.AreEqual('row value', Card.RowValueSecond.Value(),
            'a write to the page global must not reach a control bound to the source table');
        Card.Close();

        Row.Get('ROW1');
        Assert.AreEqual('row value', Row.Value,
            'a write to the page global must not be persisted to the row');
    end;

    // The same shape one level further out: the shared binding is a FIELD OF a page-global
    // temporary Record, not a plain global.
    [Test]
    procedure SecondControlOverAGlobalRecordField_ShowsTheSameValue()
    var
        Card: TestPage "TP Shared Bind Card";
    begin
        Initialize();

        Card.OpenEdit();
        Assert.AreEqual('seeded buffer', Card.BufferFirst.Value(),
            'the first control over the page-global record field must show what OnOpenPage assigned');
        Assert.AreEqual('seeded buffer', Card.BufferSecond.Value(),
            'the second control over the same page-global record field must show the same value');
        Card.Close();
    end;

    [Test]
    procedure WriteThroughOneControlOverAGlobalRecordField_IsSeenByTheOther()
    var
        Card: TestPage "TP Shared Bind Card";
    begin
        Initialize();

        Card.OpenEdit();
        Card.BufferFirst.SetValue('written buffer');
        Assert.AreEqual('written buffer', Card.BufferSecond.Value(),
            'both controls read one page-global record field, so a write through one must be visible in the other');
        Card.Close();
    end;
}
