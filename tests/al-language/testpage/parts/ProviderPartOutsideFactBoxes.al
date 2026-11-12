// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-provider-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); PVD Header (69140), PVD Line (69141), PVD Detail (69142); own log 77410, part pages 77411 77412,
//   host pages 77413 77415 77417, page extensions 77414 77416, test codeunit 77418
// Probe: observe-only. ProviderLinkedPartsMatrix.al pins a Provider chain in the base page (Provider in Content, linked part in FactBoxes) and a chain
//   that a page extension adds to the FactBoxes area. This file records the Provider chains it does not cover:
//   host A: the base page has the Provider part in Content, a page extension adds the linked part after it, outside FactBoxes (al-runner 7748);
//   host B: the base page declares both the Provider and the linked part in its FactBoxes area;
//   host C: a page extension adds both the Provider and the linked part to the Content area.
// Facts: per host, the rows the two parts stand on when read without a move, and the part triggers that ran (OnOpenPage with the part's filter,
//   OnAfterGetCurrRecord), after OpenView, OpenEdit, GoToRecord, GoToKey (a header with lines and one without), Next and First on the Provider part,
//   OpenNew with SetValue of the key, and Close.
// Result (BC 27.5, 28.5 and 29.0 alike): the three hosts read the same rows and run the same triggers, except on OpenNew, where the
//   chain in the base FactBoxes reads its blank line once and the key typed into the host inserts the row (as the chain a page
//   extension adds to FactBoxes in ProviderLinkedPartsMatrix.al), while the two Content chains read it twice and do not insert.
// local object: the host pages are the fixtures under test (where their Provider chain is declared), the log records the part triggers.
// BC versions: 27, 28, 29

codeunit 77410 "LT PX Log"
{
    SingleInstance = true;

    var
        Lines: List of [Text];

    procedure Reset()
    begin
        Clear(Lines);
    end;

    procedure Add(Line: Text)
    begin
        Lines.Add(Line);
    end;

    procedure Dump(): Text
    var
        Line: Text;
        Result: Text;
    begin
        foreach Line in Lines do begin
            if Result <> '' then
                Result += ' | ';
            Result += Line;
        end;
        exit('[' + Result + ']');
    end;
}

page 77411 "LT PX Lines Part"
{
    PageType = ListPart;
    SourceTable = "PVD Line";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(LineNo; Rec."Line No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT PX Log";
    begin
        Log.Add('lines-open(' + Rec.GetFilters() + ')');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT PX Log";
    begin
        Log.Add('lines-row(' + Format(Rec."Line No.") + ')');
    end;
}

page 77412 "LT PX Detail Part"
{
    PageType = ListPart;
    SourceTable = "PVD Detail";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Info; Rec.Info) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT PX Log";
    begin
        Log.Add('detail-open(' + Rec.GetFilters() + ')');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT PX Log";
    begin
        Log.Add('detail-row(' + Rec.Info + ')');
    end;
}

page 77413 "LT PX Host Ext Content"
{
    PageType = Card;
    SourceTable = "PVD Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "LT PX Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = field("No.");
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT PX Log";
    begin
        Log.Add('host-row(' + Rec."No." + ')');
    end;
}

pageextension 77414 "LT PX Host Ext Content X" extends "LT PX Host Ext Content"
{
    layout
    {
        addafter(Lines)
        {
            part(Detail; "LT PX Detail Part")
            {
                ApplicationArea = All;
                Provider = Lines;
                SubPageLink = "Line Ref" = field("Line No.");
            }
        }
    }
}

page 77415 "LT PX Host Base FB"
{
    PageType = Card;
    SourceTable = "PVD Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
        }
        area(FactBoxes)
        {
            part(Lines; "LT PX Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = field("No.");
            }
            part(Detail; "LT PX Detail Part")
            {
                ApplicationArea = All;
                Provider = Lines;
                SubPageLink = "Line Ref" = field("Line No.");
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT PX Log";
    begin
        Log.Add('host-row(' + Rec."No." + ')');
    end;
}

page 77417 "LT PX Host Both Ext"
{
    PageType = Card;
    SourceTable = "PVD Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT PX Log";
    begin
        Log.Add('host-row(' + Rec."No." + ')');
    end;
}

pageextension 77416 "LT PX Host Both Ext Ext" extends "LT PX Host Both Ext"
{
    layout
    {
        addlast(Content)
        {
            part(Lines; "LT PX Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = field("No.");
            }
            part(Detail; "LT PX Detail Part")
            {
                ApplicationArea = All;
                Provider = Lines;
                SubPageLink = "Line Ref" = field("Line No.");
            }
        }
    }
}

codeunit 77418 "LT PX Provider Outside FB"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PX Log";

    local procedure Seed()
    var
        Header: Record "PVD Header";
        Line: Record "PVD Line";
        Detail: Record "PVD Detail";
    begin
        Detail.DeleteAll();
        Line.DeleteAll();
        Header.DeleteAll();
        Header.Init();
        Header."No." := 'H1';
        Header."Line No." := 1;
        Header.Insert();
        Header.Init();
        Header."No." := 'H2';
        Header."Line No." := 1;
        Header.Insert();
        InsertLine('H1', 10);
        InsertLine('H1', 20);
        InsertDetail(1, 10, 'ten');
        InsertDetail(2, 20, 'twenty');
        InsertDetail(3, 0, 'zero');
        Log.Reset();
    end;

    local procedure InsertLine(HeaderNo: Code[20]; LineNo: Integer)
    var
        Line: Record "PVD Line";
    begin
        Line.Init();
        Line."Header No." := HeaderNo;
        Line."Line No." := LineNo;
        Line.Insert();
    end;

    local procedure InsertDetail(EntryNo: Integer; LineRef: Integer; Info: Text[30])
    var
        Detail: Record "PVD Detail";
    begin
        Detail.Init();
        Detail."Entry No." := EntryNo;
        Detail."Line Ref" := LineRef;
        Detail.Info := Info;
        Detail.Insert();
    end;

    local procedure Say(Name: Text; Rows: Text)
    begin
        Observer.Observe(Name, Rows + ' log=' + Log.Dump());
        Log.Reset();
    end;

    local procedure ErrorOr(Ok: Boolean; Value: Text): Text
    begin
        if Ok then
            exit(Value);
        exit('ERR[' + GetLastErrorText() + ']');
    end;

    // Host A: Provider in the base page's Content, linked part added by a page extension after it.
    [TryFunction]
    local procedure TryLinesA(var Card: TestPage "LT PX Host Ext Content"; var Value: Text)
    begin
        Value := Card.Lines.LineNo.Value();
    end;

    [TryFunction]
    local procedure TryDetailA(var Card: TestPage "LT PX Host Ext Content"; var Value: Text)
    begin
        Value := Card.Detail.Info.Value();
    end;

    local procedure SnapA(Name: Text; var Card: TestPage "LT PX Host Ext Content")
    var
        Value: Text;
        Result: Text;
    begin
        Result := 'lines=' + ErrorOr(TryLinesA(Card, Value), Value);
        Result += ' detail=' + ErrorOr(TryDetailA(Card, Value), Value);
        Say(Name, Result);
    end;

    // Host B: Provider and linked part both declared in the base page's FactBoxes.
    [TryFunction]
    local procedure TryLinesB(var Card: TestPage "LT PX Host Base FB"; var Value: Text)
    begin
        Value := Card.Lines.LineNo.Value();
    end;

    [TryFunction]
    local procedure TryDetailB(var Card: TestPage "LT PX Host Base FB"; var Value: Text)
    begin
        Value := Card.Detail.Info.Value();
    end;

    local procedure SnapB(Name: Text; var Card: TestPage "LT PX Host Base FB")
    var
        Value: Text;
        Result: Text;
    begin
        Result := 'lines=' + ErrorOr(TryLinesB(Card, Value), Value);
        Result += ' detail=' + ErrorOr(TryDetailB(Card, Value), Value);
        Say(Name, Result);
    end;

    // Host C: Provider and linked part both added to Content by a page extension.
    [TryFunction]
    local procedure TryLinesC(var Card: TestPage "LT PX Host Both Ext"; var Value: Text)
    begin
        Value := Card.Lines.LineNo.Value();
    end;

    [TryFunction]
    local procedure TryDetailC(var Card: TestPage "LT PX Host Both Ext"; var Value: Text)
    begin
        Value := Card.Detail.Info.Value();
    end;

    local procedure SnapC(Name: Text; var Card: TestPage "LT PX Host Both Ext")
    var
        Value: Text;
        Result: Text;
    begin
        Result := 'lines=' + ErrorOr(TryLinesC(Card, Value), Value);
        Result += ' detail=' + ErrorOr(TryDetailC(Card, Value), Value);
        Say(Name, Result);
    end;

    // The reporter's shape (al-runner 7748): OpenView, GoToRecord on a header with lines, read both parts.
    [Test]
    procedure ExtContent_OpenViewGoToRecord()
    var
        Header: Record "PVD Header";
        Card: TestPage "LT PX Host Ext Content";
    begin
        Seed();
        Header.Get('H1');
        Card.OpenView();
        SnapA('open', Card);
        Card.GoToRecord(Header);
        SnapA('h1', Card);
        Card.Lines.Next();
        SnapA('next', Card);
        Card.Lines.First();
        SnapA('first', Card);
        Card.Close();
        Observer.Expect('open', 'lines=10 detail=ten log=[lines-open() | detail-open() | host-row(H1) | lines-row(10) | detail-row(ten)]');
        Observer.Expect('h1', 'lines=10 detail=ten log=[host-row(H1)]');
        Observer.Expect('next', 'lines=20 detail=twenty log=[lines-row(20) | detail-row(twenty)]');
        Observer.Expect('first', 'lines=10 detail=ten log=[lines-row(10) | detail-row(ten)]');
        Observer.Verify();
    end;

    [Test]
    procedure ExtContent_OpenEditGoToKey()
    var
        Card: TestPage "LT PX Host Ext Content";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H2');
        SnapA('h2', Card);
        Card.GoToKey('H1');
        SnapA('h1', Card);
        Card.Next();
        SnapA('next-host', Card);
        Card.Close();
        Observer.Expect('h2', 'lines= detail= log=[lines-open() | detail-open() | host-row(H1) | lines-row(10) | detail-row(ten) | host-row(H1) | host-row(H2) | lines-row(0) | detail-row()]');
        Observer.Expect('h1', 'lines=20 detail=twenty log=[host-row(H1) | lines-row(20) | detail-row(twenty)]');
        Observer.Expect('next-host', 'lines= detail= log=[host-row(H2) | lines-row(0) | detail-row()]');
        Observer.Verify();
    end;

    [Test]
    procedure ExtContent_OpenNew()
    var
        Header: Record "PVD Header";
        Card: TestPage "LT PX Host Ext Content";
    begin
        Seed();
        Card.OpenNew();
        SnapA('new', Card);
        Card."No.".SetValue('H3');
        SnapA('keyed', Card);
        Card.Close();
        Observer.Observe('inserted', Format(Header.Get('H3')));
        Observer.Expect('new', 'lines= detail= log=[lines-open() | detail-open() | host-row() | lines-row(0) | detail-row() | lines-row(0)]');
        Observer.Expect('keyed', 'lines= detail= log=[]');
        Observer.Expect('inserted', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure BaseFactBoxes_OpenViewGoToRecord()
    var
        Header: Record "PVD Header";
        Card: TestPage "LT PX Host Base FB";
    begin
        Seed();
        Header.Get('H1');
        Card.OpenView();
        SnapB('open', Card);
        Card.GoToRecord(Header);
        SnapB('h1', Card);
        Card.Lines.Next();
        SnapB('next', Card);
        Card.Lines.First();
        SnapB('first', Card);
        Card.Close();
        Observer.Expect('open', 'lines=10 detail=ten log=[lines-open() | detail-open() | host-row(H1) | lines-row(10) | detail-row(ten)]');
        Observer.Expect('h1', 'lines=10 detail=ten log=[host-row(H1)]');
        Observer.Expect('next', 'lines=20 detail=twenty log=[lines-row(20) | detail-row(twenty)]');
        Observer.Expect('first', 'lines=10 detail=ten log=[lines-row(10) | detail-row(ten)]');
        Observer.Verify();
    end;

    [Test]
    procedure BaseFactBoxes_OpenEditGoToKey()
    var
        Card: TestPage "LT PX Host Base FB";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H2');
        SnapB('h2', Card);
        Card.GoToKey('H1');
        SnapB('h1', Card);
        Card.Next();
        SnapB('next-host', Card);
        Card.Close();
        Observer.Expect('h2', 'lines= detail= log=[lines-open() | detail-open() | host-row(H1) | lines-row(10) | detail-row(ten) | host-row(H1) | host-row(H2) | lines-row(0) | detail-row()]');
        Observer.Expect('h1', 'lines=20 detail=twenty log=[host-row(H1) | lines-row(20) | detail-row(twenty)]');
        Observer.Expect('next-host', 'lines= detail= log=[host-row(H2) | lines-row(0) | detail-row()]');
        Observer.Verify();
    end;

    [Test]
    procedure BaseFactBoxes_OpenNew()
    var
        Header: Record "PVD Header";
        Card: TestPage "LT PX Host Base FB";
    begin
        Seed();
        Card.OpenNew();
        SnapB('new', Card);
        Card."No.".SetValue('H3');
        SnapB('keyed', Card);
        Card.Close();
        Observer.Observe('inserted', Format(Header.Get('H3')));
        Observer.Expect('new', 'lines= detail= log=[lines-open() | detail-open() | host-row() | lines-row(0) | detail-row()]');
        Observer.Expect('keyed', 'lines= detail= log=[lines-row(0)]');
        Observer.Expect('inserted', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure BothExt_OpenViewGoToRecord()
    var
        Header: Record "PVD Header";
        Card: TestPage "LT PX Host Both Ext";
    begin
        Seed();
        Header.Get('H1');
        Card.OpenView();
        SnapC('open', Card);
        Card.GoToRecord(Header);
        SnapC('h1', Card);
        Card.Lines.Next();
        SnapC('next', Card);
        Card.Lines.First();
        SnapC('first', Card);
        Card.Close();
        Observer.Expect('open', 'lines=10 detail=ten log=[lines-open() | detail-open() | host-row(H1) | lines-row(10) | detail-row(ten)]');
        Observer.Expect('h1', 'lines=10 detail=ten log=[host-row(H1)]');
        Observer.Expect('next', 'lines=20 detail=twenty log=[lines-row(20) | detail-row(twenty)]');
        Observer.Expect('first', 'lines=10 detail=ten log=[lines-row(10) | detail-row(ten)]');
        Observer.Verify();
    end;

    [Test]
    procedure BothExt_OpenEditGoToKey()
    var
        Card: TestPage "LT PX Host Both Ext";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('H2');
        SnapC('h2', Card);
        Card.GoToKey('H1');
        SnapC('h1', Card);
        Card.Next();
        SnapC('next-host', Card);
        Card.Close();
        Observer.Expect('h2', 'lines= detail= log=[lines-open() | detail-open() | host-row(H1) | lines-row(10) | detail-row(ten) | host-row(H1) | host-row(H2) | lines-row(0) | detail-row()]');
        Observer.Expect('h1', 'lines=20 detail=twenty log=[host-row(H1) | lines-row(20) | detail-row(twenty)]');
        Observer.Expect('next-host', 'lines= detail= log=[host-row(H2) | lines-row(0) | detail-row()]');
        Observer.Verify();
    end;

    [Test]
    procedure BothExt_OpenNew()
    var
        Header: Record "PVD Header";
        Card: TestPage "LT PX Host Both Ext";
    begin
        Seed();
        Card.OpenNew();
        SnapC('new', Card);
        Card."No.".SetValue('H3');
        SnapC('keyed', Card);
        Card.Close();
        Observer.Observe('inserted', Format(Header.Get('H3')));
        Observer.Expect('new', 'lines= detail= log=[lines-open() | detail-open() | host-row() | lines-row(0) | detail-row() | lines-row(0)]');
        Observer.Expect('keyed', 'lines= detail= log=[]');
        Observer.Expect('inserted', 'No');
        Observer.Verify();
    end;
}
