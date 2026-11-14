// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-datacaptionexpression-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 78910-78916 (DCG Row, DCG Other, DCG Log, DCG WS Get, DCG WS Miss, DCG WS Own,
//   DCG Tests)
// Probe: from al-runner issue 6924 (an outside reporter's Worksheet whose DataCaptionExpression calls Record.Get; AL code opens it through a
//   page handler and reads the controls). DataCaptionExprPureOpen.al (the caption expressions that only read) and DataCaptionExprWorksheet.al
//   measured expressions that do not call Get and a handed record with one SetRange on one Code value. This file measures a Worksheet whose
//   expression calls Get, with six kinds of handed record (rows A Seq 1 Kind X, B Seq 2 Kind Y, C Seq 3 Kind X):
//   None (no filter, rows A B C), Two (SetRange Kind = X and SetRange Seq 1..3: rows A C), Range (SetFilter Code 'A..B': rows A B),
//   EmptyCode (SetRange Code = '': no row), IntRange (SetRange Seq = 2: row B).
//   Pages: DCG WS Get (Get of the other table's key K1, found), DCG WS Miss (Get of a key that does not exist, not guarded), DCG WS Own
//   (Get on a local copy of the page's own table with the key in Rec). Openings: Page.Run with a PageHandler, Page.RunModal with a
//   ModalPageHandler, and a TestPage Trap before Page.Run. Miss runs inside asserterror (the test raises its own error after the open).
// Log (DCG Log, SingleInstance): OnOpenPage, DC-start and DC=<value> of every run of the expression, H0 and H1 (the handler: caption and
//   controls) or T0 and T1 (the Trap). Facts: the log, the number of runs (a counter in the SingleInstance codeunit), the key of the record
//   a Get left in the SingleInstance codeunit, the test's record after the open (filters, Code), the page global the expression set.
// What BC did: see the assertions (measured by the pull request's CI run).
// BC versions: 27.5, 28.5, 29.0

table 78910 "DCG Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Name; Text[50]) { }
        field(3; Seq; Integer) { }
        field(4; Kind; Code[10]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 78911 "DCG Other"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Title; Text[50]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

page 78913 "DCG WS Get"
{
    PageType = Worksheet;
    SourceTable = "DCG Row";
    Caption = 'DCG WS Get';
    DataCaptionExpression = Cap();
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                field(GlobalCtl; G) { ApplicationArea = All; }
            }
            repeater(Lines)
            {
                field(CodeCtl; Rec."Code") { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    var
        Log: Codeunit "DCG Log";
        G: Text[30];

    local procedure Cap(): Text
    var
        Other: Record "DCG Other";
        V: Text;
    begin
        Log.Bump();
        Log.Add('DC-start');
        if Other.Get('K1') then begin
            V := Other.Title;
            Log.Hold(Other);
        end else
            V := 'none';
        G := 'cap-ran';
        Log.Add('DC=' + V);
        exit(V);
    end;

    trigger OnOpenPage()
    begin
        Log.Add('OnOpenPage');
    end;
}

page 78914 "DCG WS Miss"
{
    PageType = Worksheet;
    SourceTable = "DCG Row";
    Caption = 'DCG WS Miss';
    DataCaptionExpression = Cap();
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                field(GlobalCtl; G) { ApplicationArea = All; }
            }
            repeater(Lines)
            {
                field(CodeCtl; Rec."Code") { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    var
        Log: Codeunit "DCG Log";
        G: Text[30];

    local procedure Cap(): Text
    var
        Other: Record "DCG Other";
        V: Text;
    begin
        Log.Bump();
        Log.Add('DC-start');
        Other.Get('NOPE');
        V := Other.Title;
        G := 'cap-ran';
        Log.Add('DC=' + V);
        exit(V);
    end;

    trigger OnOpenPage()
    begin
        Log.Add('OnOpenPage');
    end;
}

page 78915 "DCG WS Own"
{
    PageType = Worksheet;
    SourceTable = "DCG Row";
    Caption = 'DCG WS Own';
    DataCaptionExpression = Cap();
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                field(GlobalCtl; G) { ApplicationArea = All; }
            }
            repeater(Lines)
            {
                field(CodeCtl; Rec."Code") { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    var
        Log: Codeunit "DCG Log";
        G: Text[30];

    local procedure Cap(): Text
    var
        Twin: Record "DCG Row";
        V: Text;
    begin
        Log.Bump();
        Log.Add('DC-start');
        if Twin.Get(Rec."Code") then
            V := Twin.Name
        else
            V := 'none';
        G := 'cap-ran';
        Log.Add('DC=' + V);
        exit(V);
    end;

    trigger OnOpenPage()
    begin
        Log.Add('OnOpenPage');
    end;
}

codeunit 78912 "DCG Log"
{
    SingleInstance = true;

    var
        Lines: List of [Text];
        Runs: Integer;
        Held: Record "DCG Other";

    procedure Wipe()
    begin
        Clear(Lines);
        Runs := 0;
        Clear(Held);
    end;

    procedure Add(Line: Text)
    begin
        Lines.Add(Line);
    end;

    procedure Bump()
    begin
        Runs += 1;
    end;

    procedure Count(): Integer
    begin
        exit(Runs);
    end;

    procedure Hold(var R: Record "DCG Other")
    begin
        Held := R;
    end;

    procedure HeldKey(): Text
    begin
        exit('held=' + Held."Code" + '/' + Held.Title);
    end;

    procedure Joined(): Text
    var
        Line: Text;
        Result: Text;
    begin
        foreach Line in Lines do begin
            if Result <> '' then
                Result += ' | ';
            Result += Line;
        end;
        exit(Result);
    end;
}

codeunit 78916 "DCG Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "DCG Log";

    local procedure Seed(Filt: Text; var Row: Record "DCG Row")
    var
        Seeded: Record "DCG Row";
        Other: Record "DCG Other";
    begin
        Seeded.DeleteAll();
        Other.DeleteAll();
        Log.Wipe();
        Seeded.Init();
        Seeded."Code" := 'A';
        Seeded.Name := 'Alpha';
        Seeded.Seq := 1;
        Seeded.Kind := 'X';
        Seeded.Insert();
        Seeded.Init();
        Seeded."Code" := 'B';
        Seeded.Name := 'Beta';
        Seeded.Seq := 2;
        Seeded.Kind := 'Y';
        Seeded.Insert();
        Seeded.Init();
        Seeded."Code" := 'C';
        Seeded.Name := 'Gamma';
        Seeded.Seq := 3;
        Seeded.Kind := 'X';
        Seeded.Insert();
        Other.Init();
        Other."Code" := 'K1';
        Other.Title := 'Title One';
        Other.Insert();
        Row.Reset();
        case Filt of
            'Two':
                begin
                    Row.SetRange(Kind, 'X');
                    Row.SetRange(Seq, 1, 3);
                end;
            'Range':
                Row.SetFilter("Code", 'A..B');
            'EmptyCode':
                Row.SetRange("Code", '');
            'IntRange':
                Row.SetRange(Seq, 2);
        end;
    end;

    local procedure Facts(var Observer: Codeunit "Probe Observer"; var Row: Record "DCG Row")
    var
        Store: Record "DCG Row";
    begin
        Observer.Observe('log', Log.Joined());
        Observer.Observe('runs', Format(Log.Count()));
        Observer.Observe('held', Log.HeldKey());
        Observer.Observe('rec', 'filters=' + Row.GetFilters + ' code=' + Row."Code");
        Observer.Observe('store', Format(Store.Count()));
    end;

    [Test]
    [HandlerFunctions('HGet')]
    procedure Get_None_Run()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCG Row";
    begin
        Seed('None', Row);
        Page.Run(Page::"DCG WS Get", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC-start | DC=Title One | DC-start | DC=Title One | DC-start | DC=Title One | H0 | H1 cap=DCG WS Get - Title One g= code=A name=Alpha | after open');
        Observer.Expect('runs', '3');
        Observer.Expect('held', 'held=K1/Title One');
        Observer.Expect('rec', 'filters= code=');
        Observer.Expect('store', '3');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHGet')]
    procedure Get_None_RunModal()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCG Row";
    begin
        Seed('None', Row);
        Page.RunModal(Page::"DCG WS Get", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC-start | DC=Title One | DC-start | DC=Title One | DC-start | DC=Title One | H0 | H1 cap=DCG WS Get - Title One g= code=A name=Alpha | after open');
        Observer.Expect('runs', '3');
        Observer.Expect('held', 'held=K1/Title One');
        Observer.Expect('rec', 'filters= code=');
        Observer.Expect('store', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Get_None_Trap()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCG Row";
        TP: TestPage "DCG WS Get";
        Cap: Text;
    begin
        Seed('None', Row);
        TP.Trap();
        Page.Run(Page::"DCG WS Get", Row);
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC-start | DC=Title One | DC-start | DC=Title One | DC-start | DC=Title One | T0 | T1 cap=DCG WS Get - Title One g= code=A name=Alpha | after open');
        Observer.Expect('runs', '3');
        Observer.Expect('held', 'held=K1/Title One');
        Observer.Expect('rec', 'filters= code=');
        Observer.Expect('store', '3');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HGet')]
    procedure Get_Two_Run()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCG Row";
    begin
        Seed('Two', Row);
        Page.Run(Page::"DCG WS Get", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC-start | DC=Title One | DC-start | DC=Title One | H0 | H1 cap=DCG WS Get - Title One g= code=A name=Alpha | after open');
        Observer.Expect('runs', '2');
        Observer.Expect('held', 'held=K1/Title One');
        Observer.Expect('rec', 'filters=Seq: 1..3, Kind: X code=');
        Observer.Expect('store', '3');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHGet')]
    procedure Get_Two_RunModal()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCG Row";
    begin
        Seed('Two', Row);
        Page.RunModal(Page::"DCG WS Get", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC-start | DC=Title One | DC-start | DC=Title One | H0 | H1 cap=DCG WS Get - Title One g= code=A name=Alpha | after open');
        Observer.Expect('runs', '2');
        Observer.Expect('held', 'held=K1/Title One');
        Observer.Expect('rec', 'filters=Seq: 1..3, Kind: X code=');
        Observer.Expect('store', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Get_Two_Trap()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCG Row";
        TP: TestPage "DCG WS Get";
        Cap: Text;
    begin
        Seed('Two', Row);
        TP.Trap();
        Page.Run(Page::"DCG WS Get", Row);
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC-start | DC=Title One | DC-start | DC=Title One | T0 | T1 cap=DCG WS Get - Title One g= code=A name=Alpha | after open');
        Observer.Expect('runs', '2');
        Observer.Expect('held', 'held=K1/Title One');
        Observer.Expect('rec', 'filters=Seq: 1..3, Kind: X code=');
        Observer.Expect('store', '3');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HGet')]
    procedure Get_Range_Run()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCG Row";
    begin
        Seed('Range', Row);
        Page.Run(Page::"DCG WS Get", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC-start | DC=Title One | DC-start | DC=Title One | H0 | H1 cap=DCG WS Get - Title One g= code=A name=Alpha | after open');
        Observer.Expect('runs', '2');
        Observer.Expect('held', 'held=K1/Title One');
        Observer.Expect('rec', 'filters=Code: A..B code=');
        Observer.Expect('store', '3');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHGet')]
    procedure Get_Range_RunModal()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCG Row";
    begin
        Seed('Range', Row);
        Page.RunModal(Page::"DCG WS Get", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC-start | DC=Title One | DC-start | DC=Title One | H0 | H1 cap=DCG WS Get - Title One g= code=A name=Alpha | after open');
        Observer.Expect('runs', '2');
        Observer.Expect('held', 'held=K1/Title One');
        Observer.Expect('rec', 'filters=Code: A..B code=');
        Observer.Expect('store', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Get_Range_Trap()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCG Row";
        TP: TestPage "DCG WS Get";
        Cap: Text;
    begin
        Seed('Range', Row);
        TP.Trap();
        Page.Run(Page::"DCG WS Get", Row);
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC-start | DC=Title One | DC-start | DC=Title One | T0 | T1 cap=DCG WS Get - Title One g= code=A name=Alpha | after open');
        Observer.Expect('runs', '2');
        Observer.Expect('held', 'held=K1/Title One');
        Observer.Expect('rec', 'filters=Code: A..B code=');
        Observer.Expect('store', '3');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HGet')]
    procedure Get_EmptyCode_Run()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCG Row";
    begin
        Seed('EmptyCode', Row);
        Page.Run(Page::"DCG WS Get", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC-start | DC=Title One | DC-start | DC=Title One | H0 | H1 cap=DCG WS Get - Title One g=cap-ran code= name= | after open');
        Observer.Expect('runs', '2');
        Observer.Expect('held', 'held=K1/Title One');
        Observer.Expect('rec', 'filters=Code: '''' code=');
        Observer.Expect('store', '3');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHGet')]
    procedure Get_EmptyCode_RunModal()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCG Row";
    begin
        Seed('EmptyCode', Row);
        Page.RunModal(Page::"DCG WS Get", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC-start | DC=Title One | DC-start | DC=Title One | H0 | H1 cap=DCG WS Get - Title One g=cap-ran code= name= | after open');
        Observer.Expect('runs', '2');
        Observer.Expect('held', 'held=K1/Title One');
        Observer.Expect('rec', 'filters=Code: '''' code=');
        Observer.Expect('store', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Get_EmptyCode_Trap()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCG Row";
        TP: TestPage "DCG WS Get";
        Cap: Text;
    begin
        Seed('EmptyCode', Row);
        TP.Trap();
        Page.Run(Page::"DCG WS Get", Row);
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC-start | DC=Title One | DC-start | DC=Title One | T0 | T1 cap=DCG WS Get - Title One g=cap-ran code= name= | after open');
        Observer.Expect('runs', '2');
        Observer.Expect('held', 'held=K1/Title One');
        Observer.Expect('rec', 'filters=Code: '''' code=');
        Observer.Expect('store', '3');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HGet')]
    procedure Get_IntRange_Run()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCG Row";
    begin
        Seed('IntRange', Row);
        Page.Run(Page::"DCG WS Get", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC-start | DC=Title One | H0 | H1 cap=DCG WS Get - Title One g= code=B name=Beta | after open');
        Observer.Expect('runs', '1');
        Observer.Expect('held', 'held=K1/Title One');
        Observer.Expect('rec', 'filters=Seq: 2 code=');
        Observer.Expect('store', '3');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHGet')]
    procedure Get_IntRange_RunModal()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCG Row";
    begin
        Seed('IntRange', Row);
        Page.RunModal(Page::"DCG WS Get", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC-start | DC=Title One | H0 | H1 cap=DCG WS Get - Title One g= code=B name=Beta | after open');
        Observer.Expect('runs', '1');
        Observer.Expect('held', 'held=K1/Title One');
        Observer.Expect('rec', 'filters=Seq: 2 code=');
        Observer.Expect('store', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Get_IntRange_Trap()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCG Row";
        TP: TestPage "DCG WS Get";
        Cap: Text;
    begin
        Seed('IntRange', Row);
        TP.Trap();
        Page.Run(Page::"DCG WS Get", Row);
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC-start | DC=Title One | T0 | T1 cap=DCG WS Get - Title One g= code=B name=Beta | after open');
        Observer.Expect('runs', '1');
        Observer.Expect('held', 'held=K1/Title One');
        Observer.Expect('rec', 'filters=Seq: 2 code=');
        Observer.Expect('store', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Miss_None_Run()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCG Row";
    begin
        Seed('None', Row);
        Commit();
        asserterror RunMiss(Row);
        Observer.ObserveError('open');
        Facts(Observer, Row);
        Observer.Expect('open|text', ': The DCG Other does not exist. Identification fields and values: Code=''NOPE''');
        Observer.Expect('open|code', 'TestWrapped');
        Observer.Expect('log', 'OnOpenPage | DC-start');
        Observer.Expect('runs', '1');
        Observer.Expect('held', 'held=/');
        Observer.Expect('rec', 'filters= code=');
        Observer.Expect('store', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Miss_None_RunModal()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCG Row";
    begin
        Seed('None', Row);
        Commit();
        asserterror RunModalMiss(Row);
        Observer.ObserveError('open');
        Facts(Observer, Row);
        Observer.Expect('open|text', ': The DCG Other does not exist. Identification fields and values: Code=''NOPE''');
        Observer.Expect('open|code', 'TestWrapped');
        Observer.Expect('log', 'OnOpenPage | DC-start');
        Observer.Expect('runs', '1');
        Observer.Expect('held', 'held=/');
        Observer.Expect('rec', 'filters= code=');
        Observer.Expect('store', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Miss_None_Trap()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCG Row";
    begin
        Seed('None', Row);
        Commit();
        asserterror TrapMiss(Row);
        Observer.ObserveError('open');
        Facts(Observer, Row);
        Observer.Expect('open|text', ': The DCG Other does not exist. Identification fields and values: Code=''NOPE''');
        Observer.Expect('open|code', 'TestWrapped');
        Observer.Expect('log', 'OnOpenPage | DC-start');
        Observer.Expect('runs', '1');
        Observer.Expect('held', 'held=/');
        Observer.Expect('rec', 'filters= code=');
        Observer.Expect('store', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Miss_Two_Run()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCG Row";
    begin
        Seed('Two', Row);
        Commit();
        asserterror RunMiss(Row);
        Observer.ObserveError('open');
        Facts(Observer, Row);
        Observer.Expect('open|text', ': The DCG Other does not exist. Identification fields and values: Code=''NOPE''');
        Observer.Expect('open|code', 'TestWrapped');
        Observer.Expect('log', 'OnOpenPage | DC-start');
        Observer.Expect('runs', '1');
        Observer.Expect('held', 'held=/');
        Observer.Expect('rec', 'filters=Seq: 1..3, Kind: X code=');
        Observer.Expect('store', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Miss_Two_RunModal()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCG Row";
    begin
        Seed('Two', Row);
        Commit();
        asserterror RunModalMiss(Row);
        Observer.ObserveError('open');
        Facts(Observer, Row);
        Observer.Expect('open|text', ': The DCG Other does not exist. Identification fields and values: Code=''NOPE''');
        Observer.Expect('open|code', 'TestWrapped');
        Observer.Expect('log', 'OnOpenPage | DC-start');
        Observer.Expect('runs', '1');
        Observer.Expect('held', 'held=/');
        Observer.Expect('rec', 'filters=Seq: 1..3, Kind: X code=');
        Observer.Expect('store', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Miss_Two_Trap()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCG Row";
    begin
        Seed('Two', Row);
        Commit();
        asserterror TrapMiss(Row);
        Observer.ObserveError('open');
        Facts(Observer, Row);
        Observer.Expect('open|text', ': The DCG Other does not exist. Identification fields and values: Code=''NOPE''');
        Observer.Expect('open|code', 'TestWrapped');
        Observer.Expect('log', 'OnOpenPage | DC-start');
        Observer.Expect('runs', '1');
        Observer.Expect('held', 'held=/');
        Observer.Expect('rec', 'filters=Seq: 1..3, Kind: X code=');
        Observer.Expect('store', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Miss_Range_Run()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCG Row";
    begin
        Seed('Range', Row);
        Commit();
        asserterror RunMiss(Row);
        Observer.ObserveError('open');
        Facts(Observer, Row);
        Observer.Expect('open|text', ': The DCG Other does not exist. Identification fields and values: Code=''NOPE''');
        Observer.Expect('open|code', 'TestWrapped');
        Observer.Expect('log', 'OnOpenPage | DC-start');
        Observer.Expect('runs', '1');
        Observer.Expect('held', 'held=/');
        Observer.Expect('rec', 'filters=Code: A..B code=');
        Observer.Expect('store', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Miss_Range_RunModal()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCG Row";
    begin
        Seed('Range', Row);
        Commit();
        asserterror RunModalMiss(Row);
        Observer.ObserveError('open');
        Facts(Observer, Row);
        Observer.Expect('open|text', ': The DCG Other does not exist. Identification fields and values: Code=''NOPE''');
        Observer.Expect('open|code', 'TestWrapped');
        Observer.Expect('log', 'OnOpenPage | DC-start');
        Observer.Expect('runs', '1');
        Observer.Expect('held', 'held=/');
        Observer.Expect('rec', 'filters=Code: A..B code=');
        Observer.Expect('store', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Miss_Range_Trap()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCG Row";
    begin
        Seed('Range', Row);
        Commit();
        asserterror TrapMiss(Row);
        Observer.ObserveError('open');
        Facts(Observer, Row);
        Observer.Expect('open|text', ': The DCG Other does not exist. Identification fields and values: Code=''NOPE''');
        Observer.Expect('open|code', 'TestWrapped');
        Observer.Expect('log', 'OnOpenPage | DC-start');
        Observer.Expect('runs', '1');
        Observer.Expect('held', 'held=/');
        Observer.Expect('rec', 'filters=Code: A..B code=');
        Observer.Expect('store', '3');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HMiss')]
    procedure Miss_EmptyCode_Run()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCG Row";
    begin
        Seed('EmptyCode', Row);
        Commit();
        asserterror RunMiss(Row);
        Observer.ObserveError('open');
        Facts(Observer, Row);
        Observer.Expect('open|text', 'no error at the open');
        Observer.Expect('open|code', 'Dialog');
        Observer.Expect('log', 'OnOpenPage | DC-start | DC-start | DC-start | H0 | H1 cap=DCG WS Miss g= code= name=');
        Observer.Expect('runs', '3');
        Observer.Expect('held', 'held=/');
        Observer.Expect('rec', 'filters=Code: '''' code=');
        Observer.Expect('store', '3');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHMiss')]
    procedure Miss_EmptyCode_RunModal()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCG Row";
    begin
        Seed('EmptyCode', Row);
        Commit();
        asserterror RunModalMiss(Row);
        Observer.ObserveError('open');
        Facts(Observer, Row);
        Observer.Expect('open|text', 'no error at the open');
        Observer.Expect('open|code', 'Dialog');
        Observer.Expect('log', 'OnOpenPage | DC-start | DC-start | DC-start | H0 | H1 cap=DCG WS Miss g= code= name=');
        Observer.Expect('runs', '3');
        Observer.Expect('held', 'held=/');
        Observer.Expect('rec', 'filters=Code: '''' code=');
        Observer.Expect('store', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Miss_EmptyCode_Trap()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCG Row";
    begin
        Seed('EmptyCode', Row);
        Commit();
        asserterror TrapMiss(Row);
        Observer.ObserveError('open');
        Facts(Observer, Row);
        Observer.Expect('open|text', 'no error at the open');
        Observer.Expect('open|code', 'Dialog');
        Observer.Expect('log', 'OnOpenPage | DC-start | DC-start | DC-start | T0 | T1 cap=DCG WS Miss g= code= name=');
        Observer.Expect('runs', '3');
        Observer.Expect('held', 'held=/');
        Observer.Expect('rec', 'filters=Code: '''' code=');
        Observer.Expect('store', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Miss_IntRange_Run()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCG Row";
    begin
        Seed('IntRange', Row);
        Commit();
        asserterror RunMiss(Row);
        Observer.ObserveError('open');
        Facts(Observer, Row);
        Observer.Expect('open|text', ': The DCG Other does not exist. Identification fields and values: Code=''NOPE''');
        Observer.Expect('open|code', 'TestWrapped');
        Observer.Expect('log', 'OnOpenPage | DC-start');
        Observer.Expect('runs', '1');
        Observer.Expect('held', 'held=/');
        Observer.Expect('rec', 'filters=Seq: 2 code=');
        Observer.Expect('store', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Miss_IntRange_RunModal()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCG Row";
    begin
        Seed('IntRange', Row);
        Commit();
        asserterror RunModalMiss(Row);
        Observer.ObserveError('open');
        Facts(Observer, Row);
        Observer.Expect('open|text', ': The DCG Other does not exist. Identification fields and values: Code=''NOPE''');
        Observer.Expect('open|code', 'TestWrapped');
        Observer.Expect('log', 'OnOpenPage | DC-start');
        Observer.Expect('runs', '1');
        Observer.Expect('held', 'held=/');
        Observer.Expect('rec', 'filters=Seq: 2 code=');
        Observer.Expect('store', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Miss_IntRange_Trap()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCG Row";
    begin
        Seed('IntRange', Row);
        Commit();
        asserterror TrapMiss(Row);
        Observer.ObserveError('open');
        Facts(Observer, Row);
        Observer.Expect('open|text', ': The DCG Other does not exist. Identification fields and values: Code=''NOPE''');
        Observer.Expect('open|code', 'TestWrapped');
        Observer.Expect('log', 'OnOpenPage | DC-start');
        Observer.Expect('runs', '1');
        Observer.Expect('held', 'held=/');
        Observer.Expect('rec', 'filters=Seq: 2 code=');
        Observer.Expect('store', '3');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HOwn')]
    procedure Own_None_Run()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCG Row";
    begin
        Seed('None', Row);
        Page.Run(Page::"DCG WS Own", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC-start | DC=Alpha | DC-start | DC=Beta | DC-start | DC=Gamma | H0 | H1 cap=DCG WS Own - Alpha g= code=A name=Alpha | after open');
        Observer.Expect('runs', '3');
        Observer.Expect('held', 'held=/');
        Observer.Expect('rec', 'filters= code=');
        Observer.Expect('store', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Own_None_Trap()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCG Row";
        TP: TestPage "DCG WS Own";
        Cap: Text;
    begin
        Seed('None', Row);
        TP.Trap();
        Page.Run(Page::"DCG WS Own", Row);
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC-start | DC=Alpha | DC-start | DC=Beta | DC-start | DC=Gamma | T0 | T1 cap=DCG WS Own - Alpha g= code=A name=Alpha | after open');
        Observer.Expect('runs', '3');
        Observer.Expect('held', 'held=/');
        Observer.Expect('rec', 'filters= code=');
        Observer.Expect('store', '3');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HOwn')]
    procedure Own_Two_Run()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCG Row";
    begin
        Seed('Two', Row);
        Page.Run(Page::"DCG WS Own", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC-start | DC=Alpha | DC-start | DC=Gamma | H0 | H1 cap=DCG WS Own - Alpha g= code=A name=Alpha | after open');
        Observer.Expect('runs', '2');
        Observer.Expect('held', 'held=/');
        Observer.Expect('rec', 'filters=Seq: 1..3, Kind: X code=');
        Observer.Expect('store', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Own_Two_Trap()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCG Row";
        TP: TestPage "DCG WS Own";
        Cap: Text;
    begin
        Seed('Two', Row);
        TP.Trap();
        Page.Run(Page::"DCG WS Own", Row);
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC-start | DC=Alpha | DC-start | DC=Gamma | T0 | T1 cap=DCG WS Own - Alpha g= code=A name=Alpha | after open');
        Observer.Expect('runs', '2');
        Observer.Expect('held', 'held=/');
        Observer.Expect('rec', 'filters=Seq: 1..3, Kind: X code=');
        Observer.Expect('store', '3');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HOwn')]
    procedure Own_Range_Run()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCG Row";
    begin
        Seed('Range', Row);
        Page.Run(Page::"DCG WS Own", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC-start | DC=Alpha | DC-start | DC=Beta | H0 | H1 cap=DCG WS Own - Alpha g= code=A name=Alpha | after open');
        Observer.Expect('runs', '2');
        Observer.Expect('held', 'held=/');
        Observer.Expect('rec', 'filters=Code: A..B code=');
        Observer.Expect('store', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Own_Range_Trap()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCG Row";
        TP: TestPage "DCG WS Own";
        Cap: Text;
    begin
        Seed('Range', Row);
        TP.Trap();
        Page.Run(Page::"DCG WS Own", Row);
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC-start | DC=Alpha | DC-start | DC=Beta | T0 | T1 cap=DCG WS Own - Alpha g= code=A name=Alpha | after open');
        Observer.Expect('runs', '2');
        Observer.Expect('held', 'held=/');
        Observer.Expect('rec', 'filters=Code: A..B code=');
        Observer.Expect('store', '3');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HOwn')]
    procedure Own_EmptyCode_Run()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCG Row";
    begin
        Seed('EmptyCode', Row);
        Page.Run(Page::"DCG WS Own", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC-start | DC=none | DC-start | DC=none | H0 | H1 cap=DCG WS Own - none g=cap-ran code= name= | after open');
        Observer.Expect('runs', '2');
        Observer.Expect('held', 'held=/');
        Observer.Expect('rec', 'filters=Code: '''' code=');
        Observer.Expect('store', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Own_EmptyCode_Trap()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCG Row";
        TP: TestPage "DCG WS Own";
        Cap: Text;
    begin
        Seed('EmptyCode', Row);
        TP.Trap();
        Page.Run(Page::"DCG WS Own", Row);
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC-start | DC=none | DC-start | DC=none | T0 | T1 cap=DCG WS Own - none g=cap-ran code= name= | after open');
        Observer.Expect('runs', '2');
        Observer.Expect('held', 'held=/');
        Observer.Expect('rec', 'filters=Code: '''' code=');
        Observer.Expect('store', '3');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HOwn')]
    procedure Own_IntRange_Run()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCG Row";
    begin
        Seed('IntRange', Row);
        Page.Run(Page::"DCG WS Own", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC-start | DC=Beta | H0 | H1 cap=DCG WS Own - Beta g= code=B name=Beta | after open');
        Observer.Expect('runs', '1');
        Observer.Expect('held', 'held=/');
        Observer.Expect('rec', 'filters=Seq: 2 code=');
        Observer.Expect('store', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Own_IntRange_Trap()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "DCG Row";
        TP: TestPage "DCG WS Own";
        Cap: Text;
    begin
        Seed('IntRange', Row);
        TP.Trap();
        Page.Run(Page::"DCG WS Own", Row);
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC-start | DC=Beta | T0 | T1 cap=DCG WS Own - Beta g= code=B name=Beta | after open');
        Observer.Expect('runs', '1');
        Observer.Expect('held', 'held=/');
        Observer.Expect('rec', 'filters=Seq: 2 code=');
        Observer.Expect('store', '3');
        Observer.Verify();
    end;

    [PageHandler]
    procedure HGet(var P: TestPage "DCG WS Get")
    var
        Cap: Text;
    begin
        Log.Add('H0');
        Cap := P.Caption();
        Log.Add('H1 cap=' + Cap + ' g=' + P.GlobalCtl.Value + ' code=' + P.CodeCtl.Value + ' name=' + P.NameCtl.Value);
    end;

    [ModalPageHandler]
    procedure MHGet(var P: TestPage "DCG WS Get")
    var
        Cap: Text;
    begin
        Log.Add('H0');
        Cap := P.Caption();
        Log.Add('H1 cap=' + Cap + ' g=' + P.GlobalCtl.Value + ' code=' + P.CodeCtl.Value + ' name=' + P.NameCtl.Value);
    end;

    [PageHandler]
    procedure HMiss(var P: TestPage "DCG WS Miss")
    var
        Cap: Text;
    begin
        Log.Add('H0');
        Cap := P.Caption();
        Log.Add('H1 cap=' + Cap + ' g=' + P.GlobalCtl.Value + ' code=' + P.CodeCtl.Value + ' name=' + P.NameCtl.Value);
    end;

    [ModalPageHandler]
    procedure MHMiss(var P: TestPage "DCG WS Miss")
    var
        Cap: Text;
    begin
        Log.Add('H0');
        Cap := P.Caption();
        Log.Add('H1 cap=' + Cap + ' g=' + P.GlobalCtl.Value + ' code=' + P.CodeCtl.Value + ' name=' + P.NameCtl.Value);
    end;

    local procedure RunMiss(var Row: Record "DCG Row")
    begin
        Page.Run(Page::"DCG WS Miss", Row);
        Error('no error at the open');
    end;

    local procedure RunModalMiss(var Row: Record "DCG Row")
    begin
        Page.RunModal(Page::"DCG WS Miss", Row);
        Error('no error at the open');
    end;

    local procedure TrapMiss(var Row: Record "DCG Row")
    var
        TP: TestPage "DCG WS Miss";
        Cap: Text;
    begin
        TP.Trap();
        Page.Run(Page::"DCG WS Miss", Row);
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Error('no error at the open');
    end;

    [PageHandler]
    procedure HOwn(var P: TestPage "DCG WS Own")
    var
        Cap: Text;
    begin
        Log.Add('H0');
        Cap := P.Caption();
        Log.Add('H1 cap=' + Cap + ' g=' + P.GlobalCtl.Value + ' code=' + P.CodeCtl.Value + ' name=' + P.NameCtl.Value);
    end;

    [ModalPageHandler]
    procedure MHOwn(var P: TestPage "DCG WS Own")
    var
        Cap: Text;
    begin
        Log.Add('H0');
        Cap := P.Caption();
        Log.Add('H1 cap=' + Cap + ' g=' + P.GlobalCtl.Value + ' code=' + P.CodeCtl.Value + ' name=' + P.NameCtl.Value);
    end;
}
