// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-close-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 93645, pages 93646 and 93649, codeunit 93647 (log, used by this test codeunit only), test codeunit 93648 (writer Y67)
// Probe (al-runner NP lane probe R1): TestPage.Close() on an Edit page whose save is refused by an AL error (an error in the table's OnModify
//   after a SetValue, an error in the page's OnModifyRecord, an error in OnQueryClosePage), inside asserterror. Then: the error text and code,
//   whether the page is still open (a field read, a second Close()), what a second Close() does after the cause is removed, and, when the
//   page is LEFT OPEN at the end of the test, whether the save, OnModify, OnQueryClosePage and OnClosePage run again then and what the next
//   test sees in the table. A page without close triggers is run as the control. Each "left open" test is followed by a test that reads the
//   SingleInstance log (tests of one codeunit run in declaration order in one session). The explicit Close() of a clean page and the
//   test end Close() of an open page are pinned by testpageclose/Y47CloseAtTestEnd.al; an error in OnQueryClosePage without asserterror by
//   handlers/TestPageQueryCloseError_Tests.al.
// BC versions: 27, 28, 29

table 93645 "LT Y67 CS Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Name; Text[30]) { }
        field(3; Note; Text[30]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }

    trigger OnModify()
    var
        Log: Codeunit "LT Y67 CS Log";
    begin
        Log.Add('table modify ' + Rec."Code" + ' name=' + Rec.Name);
        if Rec.Name = 'FAILMOD' then
            Error('Table modify refused for %1.', Rec."Code");
    end;
}

page 93646 "LT Y67 CS Card"
{
    PageType = Card;
    SourceTable = "LT Y67 CS Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
            field(Note; Rec.Note) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT Y67 CS Log";
    begin
        Log.Add('open');
    end;

    trigger OnModifyRecord(): Boolean
    var
        Log: Codeunit "LT Y67 CS Log";
    begin
        Log.Add('page modify ' + Rec."Code" + ' name=' + Rec.Name);
        if Rec.Name = 'FAILPAGE' then
            Error('Page modify refused for %1.', Rec."Code");
        exit(true);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "LT Y67 CS Log";
    begin
        Log.Add('queryclose ' + Format(CloseAction) + ' ' + Rec."Code");
        if Rec.Note = 'QCERR' then
            Error('Close refused for %1.', Rec."Code");
        exit(true);
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "LT Y67 CS Log";
    begin
        Log.Add('close ' + Rec."Code");
    end;
}

page 93649 "LT Y67 CS Plain"
{
    PageType = Card;
    SourceTable = "LT Y67 CS Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
            field(Note; Rec.Note) { ApplicationArea = All; }
        }
    }
}

codeunit 93647 "LT Y67 CS Log"
{
    SingleInstance = true;

    var
        Lines: Text;

    procedure Add(Line: Text)
    begin
        Lines += Line + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Lines;
        Lines := '';
        exit(Result);
    end;
}

codeunit 93648 "LT Y67 CS Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT Y67 CS Row";
        Log: Codeunit "LT Y67 CS Log";
    begin
        Row.DeleteAll();
        Row."Code" := 'R1';
        Row.Name := 'start';
        Row.Note := '';
        Row.Insert();
        Row."Code" := 'QC';
        Row.Name := 'start';
        Row.Note := 'QCERR';
        Row.Insert();
        Log.Take();
    end;

    local procedure Err(): Text
    var
        Result: Text;
    begin
        Result := GetLastErrorText() + '|' + GetLastErrorCode();
        ClearLastError();
        exit(Result);
    end;

    local procedure Names(): Text
    var
        Row: Record "LT Y67 CS Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Row."Code" + '=' + Row.Name + ' ';
            until Row.Next() = 0;
        exit(Result);
    end;

    [TryFunction]
    local procedure TryRead(var Card: TestPage "LT Y67 CS Card"; var Value: Text)
    begin
        Value := Card.Name.Value();
    end;

    [TryFunction]
    local procedure TryClose(var Card: TestPage "LT Y67 CS Card")
    begin
        Card.Close();
    end;

    [TryFunction]
    local procedure TryReadPlain(var Card: TestPage "LT Y67 CS Plain"; var Value: Text)
    begin
        Value := Card.Name.Value();
    end;

    [TryFunction]
    local procedure TryClosePlain(var Card: TestPage "LT Y67 CS Plain")
    begin
        Card.Close();
    end;

    local procedure Failing(var Observer: Codeunit "Probe Observer"; var Card: TestPage "LT Y67 CS Card"; NewName: Text; SecondClose: Boolean)
    var
        Log: Codeunit "LT Y67 CS Log";
        Row: Record "LT Y67 CS Row";
        Value: Text;
    begin
        Seed();
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.Name.SetValue(NewName);
        Log.Add('before close');
        ClearLastError();
        asserterror Card.Close();
        Observer.Observe('close error', Err());
        Observer.Observe('log after close', Log.Take());
        Observer.Observe('db after close', Names());
        if TryRead(Card, Value) then
            Observer.Observe('field read', 'ok ' + Value)
        else
            Observer.Observe('field read', 'error ' + Err());
        if SecondClose then begin
            if TryClose(Card) then
                Observer.Observe('second close', 'ok')
            else
                Observer.Observe('second close', 'error ' + Err());
            Observer.Observe('log after second close', Log.Take());
            Observer.Observe('db after second close', Names());
        end;
    end;

    [Test]
    procedure R1_TableModifyError_SecondClose()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT Y67 CS Card";
    begin
        Failing(Observer, Card, 'FAILMOD', true);
        Observer.Finish();
    end;

    [Test]
    procedure R1_TableModifyError_CorrectedThenClose()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT Y67 CS Card";
        Log: Codeunit "LT Y67 CS Log";
        Value: Text;
    begin
        Failing(Observer, Card, 'FAILMOD', false);
        ClearLastError();
        asserterror Card.Name.SetValue('fixed');
        Observer.Observe('setvalue after failed close', Err());
        if TryClose(Card) then
            Observer.Observe('close after fix', 'ok')
        else
            Observer.Observe('close after fix', 'error ' + Err());
        Observer.Observe('log after fix', Log.Take());
        Observer.Observe('db after fix', Names());
        Value := '';
        Observer.Finish();
    end;

    [Test]
    procedure R1_TableModifyError_LeftOpen()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT Y67 CS Card";
        Log: Codeunit "LT Y67 CS Log";
    begin
        Failing(Observer, Card, 'FAILMOD', false);
        Log.Add('test body end');
        Observer.Discard();
        // no more Close(): the page is left open when the test ends
    end;

    [Test]
    procedure R1_TableModifyError_LeftOpen_Read()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y67 CS Log";
    begin
        Observer.Observe('log', Log.Take());
        Observer.Observe('db', Names());
        Observer.Finish();
    end;

    [Test]
    procedure R1_PageModifyError_LeftOpen()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT Y67 CS Card";
        Log: Codeunit "LT Y67 CS Log";
    begin
        Failing(Observer, Card, 'FAILPAGE', false);
        Log.Add('test body end');
        Observer.Discard();
    end;

    [Test]
    procedure R1_PageModifyError_LeftOpen_Read()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y67 CS Log";
    begin
        Observer.Observe('log', Log.Take());
        Observer.Observe('db', Names());
        Observer.Finish();
    end;

    [Test]
    procedure R1_PageModifyError_SecondClose()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT Y67 CS Card";
    begin
        Failing(Observer, Card, 'FAILPAGE', true);
        Observer.Finish();
    end;

    [Test]
    procedure R1_QueryCloseError_Close_And_LeftOpen()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT Y67 CS Card";
        Log: Codeunit "LT Y67 CS Log";
        Row: Record "LT Y67 CS Row";
        Value: Text;
    begin
        Seed();
        Row.Get('QC');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        ClearLastError();
        asserterror Card.Close();
        Observer.Observe('close error', Err());
        Observer.Observe('log after close', Log.Take());
        if TryRead(Card, Value) then
            Observer.Observe('field read', 'ok ' + Value)
        else
            Observer.Observe('field read', 'error ' + Err());
        if TryClose(Card) then
            Observer.Observe('second close', 'ok')
        else
            Observer.Observe('second close', 'error ' + Err());
        Observer.Observe('log after second close', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure R1_QueryCloseError_LeftOpen()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT Y67 CS Card";
        Log: Codeunit "LT Y67 CS Log";
        Row: Record "LT Y67 CS Row";
    begin
        Seed();
        Row.Get('QC');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        ClearLastError();
        asserterror Card.Close();
        ClearLastError();
        Log.Add('test body end');
        Observer.Discard();
    end;

    [Test]
    procedure R1_QueryCloseError_LeftOpen_Read()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y67 CS Log";
    begin
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure R1_NoCloseTriggers_TableModifyError()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT Y67 CS Plain";
        Log: Codeunit "LT Y67 CS Log";
        Row: Record "LT Y67 CS Row";
        Value: Text;
    begin
        Seed();
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.Name.SetValue('FAILMOD');
        ClearLastError();
        asserterror Card.Close();
        Observer.Observe('close error', Err());
        Observer.Observe('log', Log.Take());
        if TryReadPlain(Card, Value) then
            Observer.Observe('field read', 'ok ' + Value)
        else
            Observer.Observe('field read', 'error ' + Err());
        if TryClosePlain(Card) then
            Observer.Observe('second close', 'ok')
        else
            Observer.Observe('second close', 'error ' + Err());
        Observer.Observe('log after second', Log.Take());
        Observer.Observe('db', Names());
        Observer.Finish();
    end;

    [Test]
    procedure R1_NoCloseTriggers_LeftOpen()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT Y67 CS Plain";
        Log: Codeunit "LT Y67 CS Log";
        Row: Record "LT Y67 CS Row";
    begin
        Seed();
        Row.Get('R1');
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.Name.SetValue('FAILMOD');
        ClearLastError();
        asserterror Card.Close();
        ClearLastError();
        Log.Add('test body end');
        Observer.Discard();
    end;

    [Test]
    procedure R1_NoCloseTriggers_LeftOpen_Read()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y67 CS Log";
    begin
        Observer.Observe('log', Log.Take());
        Observer.Observe('db', Names());
        Observer.Finish();
    end;
}
