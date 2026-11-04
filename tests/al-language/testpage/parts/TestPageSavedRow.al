// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-saverecord-method
// Scope: in-scope
// Fixtures used: PSR Header (60412), PSR Line (60413), PSR Header Card (60412),
//                PSR Lines Part (60413), Assert (60021)
//
// WHEN a page's own AL saves the row being edited (CurrPage.SaveRecord() from a field's
// OnValidate), what happens to the values typed after it, and to the host's own edit?
//
// Once the page has written the row it is an existing row: later values reach it as a Modify
// when the page closes, and the table's OnInsert does not run a second time. And a part saving
// its own row saves nothing on behalf of the host, whose pending edit is still written at close.
//
// The New() arms (leaving an edited row by starting another) were filed from AlRunner#4632.
//
// Filed from AlRunner#4577 (Microsoft's Tests-SINGLESERVER "Prepayments Plan-based E2E" orders
// lost their unit price this way: "Sales Order Subform" saves the line when Quantity is
// validated, and "Unit Price" is typed after).
codeunit 60412 "PSR Page Saved Row Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize(var Header: Record "PSR Header")
    var
        Line: Record "PSR Line";
    begin
        Line.DeleteAll();
        Header.DeleteAll();

        Header.Init();
        Header."Code" := 'H1';
        Header.Descr := 'Host';
        Header.Insert();
    end;

    local procedure CountLines(HeaderCode: Code[20]): Integer
    var
        Line: Record "PSR Line";
    begin
        Line.SetRange("Header Code", HeaderCode);
        exit(Line.Count());
    end;

    // CLAIM: a part row the part's own trigger saved keeps a value typed into it afterwards.
    [Test]
    procedure PartRowSavedByItsOwnTrigger_KeepsTheValueTypedAfterIt()
    var
        Header: Record "PSR Header";
        Line: Record "PSR Line";
        Card: TestPage "PSR Header Card";
    begin
        Initialize(Header);

        Card.OpenEdit();
        Card.GoToRecord(Header);
        Card.Lines.New();
        Card.Lines."Saved Field".SetValue('A');
        Assert.AreEqual(1, CountLines('H1'),
            'CurrPage.SaveRecord() in OnValidate must have written the DelayedInsert row already.');
        Card.Lines."Later Field".SetValue('B');
        Card.OK().Invoke();

        Assert.AreEqual(1, CountLines('H1'), 'The row must be saved once, not twice.');
        Line.SetRange("Header Code", 'H1');
        Line.FindFirst();
        Assert.AreEqual('A', Line."Saved Field", 'The value the page saved must stay.');
        Assert.AreEqual('B', Line."Later Field",
            'The value typed after the page saved the row must reach the table.');
    end;

    // CONTRAST: the same two values with no page save in between go in with the row's insert.
    [Test]
    procedure PartRowNotSavedByATrigger_KeepsBothValues()
    var
        Header: Record "PSR Header";
        Line: Record "PSR Line";
        Card: TestPage "PSR Header Card";
    begin
        Initialize(Header);

        Card.OpenEdit();
        Card.GoToRecord(Header);
        Card.Lines.New();
        Card.Lines."Later Field".SetValue('B');
        Assert.AreEqual(0, CountLines('H1'), 'A DelayedInsert row is not written before it is left.');
        Card.OK().Invoke();

        Assert.AreEqual(1, CountLines('H1'), 'The typed row must be saved.');
        Line.SetRange("Header Code", 'H1');
        Line.FindFirst();
        Assert.AreEqual('B', Line."Later Field", 'The typed value must reach the table.');
    end;

    // CLAIM: a part saving its own row does not mark the host's pending edit as saved.
    [Test]
    procedure HostEdit_SurvivesAPartSavingItsOwnRow()
    var
        Header: Record "PSR Header";
        Card: TestPage "PSR Header Card";
    begin
        Initialize(Header);

        Card.OpenEdit();
        Card.GoToRecord(Header);
        Card.Descr.SetValue('Changed');
        Card.Lines.New();
        Card.Lines."Saved Field".SetValue('A');
        Card.OK().Invoke();

        Header.Get('H1');
        Assert.AreEqual('Changed', Header.Descr, 'The host''s own edit must be saved.');
        Assert.AreEqual(1, CountLines('H1'), 'The part row must be saved.');
    end;

    // CLAIM: a new host row the page's own trigger saved is not inserted again when focus moves
    // on, so the table's OnInsert runs once, and a later value reaches the row.
    [Test]
    procedure NewHostRowSavedByItsOwnTrigger_IsInsertedOnce()
    var
        Header: Record "PSR Header";
        Card: TestPage "PSR Header Card";
    begin
        Initialize(Header);

        Card.OpenNew();
        Card."Code".SetValue('H2');
        Card.Descr.SetValue('Second');
        Card.Close();

        Header.Get('H2');
        Assert.AreEqual(1, Header."Insert Runs", 'OnInsert must run once for a row the page saved.');
        Assert.AreEqual('Second', Header.Descr, 'The value typed after the save must reach the row.');
    end;

    local procedure InsertLine(HeaderCode: Code[20]; LineNo: Integer; SavedValue: Text[30])
    var
        Line: Record "PSR Line";
    begin
        Line.Init();
        Line."Header Code" := HeaderCode;
        Line."Line No." := LineNo;
        Line."Saved Field" := SavedValue;
        Line.Insert();
    end;

    local procedure LaterFieldOf(HeaderCode: Code[20]; SavedValue: Text[30]): Text
    var
        Line: Record "PSR Line";
    begin
        Line.SetRange("Header Code", HeaderCode);
        Line.SetRange("Saved Field", SavedValue);
        Line.FindFirst();
        exit(Line."Later Field");
    end;

    // CLAIM: New() leaves the row the cursor was on, and an edit made to that existing row is
    // saved, exactly as when the cursor leaves it by moving to another row. (AlRunner#4632)
    [Test]
    procedure ExistingPartRowEdit_IsSavedWhenNewLeavesIt()
    var
        Header: Record "PSR Header";
        Card: TestPage "PSR Header Card";
    begin
        Initialize(Header);
        InsertLine('H1', 10000, 'X');

        Card.OpenEdit();
        Card.GoToRecord(Header);
        Card.Lines.First();
        Card.Lines."Later Field".SetValue('E');
        Card.Lines.New();
        Card.Lines."Later Field".SetValue('N');
        Card.OK().Invoke();

        Assert.AreEqual(2, CountLines('H1'), 'The existing row and the new row must both be in the table.');
        Assert.AreEqual('E', LaterFieldOf('H1', 'X'),
            'The edit to the existing row must be saved when New() leaves it.');
        Assert.AreEqual('N', LaterFieldOf('H1', ''), 'The new row must be saved with its own value.');
    end;

    // CONTRAST: the same edit to the existing row, left by moving the cursor instead of New().
    [Test]
    procedure ExistingPartRowEdit_IsSavedWhenNextLeavesIt()
    var
        Header: Record "PSR Header";
        Card: TestPage "PSR Header Card";
    begin
        Initialize(Header);
        InsertLine('H1', 10000, 'X');
        InsertLine('H1', 20000, 'Y');

        Card.OpenEdit();
        Card.GoToRecord(Header);
        Card.Lines.First();
        Card.Lines."Later Field".SetValue('E');
        Card.Lines.Next();
        Card.OK().Invoke();

        Assert.AreEqual('E', LaterFieldOf('H1', 'X'),
            'The edit to the existing row must be saved when Next() leaves it.');
        Assert.AreEqual('', LaterFieldOf('H1', 'Y'), 'The row that was not edited must stay as it was.');
    end;

    // CLAIM: a new row the part's own trigger saved is an existing row from then on, so a value
    // typed after the save is kept when New() leaves the row for another one. (AlRunner#4632)
    [Test]
    procedure PartRowSavedByItsOwnTrigger_KeepsTheLaterValueWhenNewLeavesIt()
    var
        Header: Record "PSR Header";
        Card: TestPage "PSR Header Card";
    begin
        Initialize(Header);

        Card.OpenEdit();
        Card.GoToRecord(Header);
        Card.Lines.New();
        Card.Lines."Saved Field".SetValue('A');
        Card.Lines."Later Field".SetValue('B');
        Card.Lines.New();
        Card.Lines."Saved Field".SetValue('C');
        Card.Lines."Later Field".SetValue('D');
        Card.OK().Invoke();

        Assert.AreEqual(2, CountLines('H1'), 'Each row must be saved once.');
        Assert.AreEqual('B', LaterFieldOf('H1', 'A'),
            'The value typed after the page saved the first row must be kept when New() leaves it.');
        Assert.AreEqual('D', LaterFieldOf('H1', 'C'), 'The second row must keep its later value.');
    end;
}
