// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-datacaptionexpression-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 76900-76912 (CPO Row, CPO Log, ten CPO WS pages, CPO Tests)
// Probe: for al-runner's assumption data-caption-pure-expression-open-skipped. A Worksheet with a DataCaptionExpression of its own, opened by
//   AL code: Page.Run(Id, Rec) and Page.RunModal(Id, Rec) with a page handler, a page variable with SetTableView and Run or RunModal with a
//   page handler, and a TestPage Trap before Page.Run or before a page variable's Run. The view is empty (no rows) or holds one row (rows A
//   and B, filter Code = A, plus a FlowFilter Date Filter range). Each page's expression computes one value the way the test name says
//   (Lit: 'Cap ' + Rec.Name; FmtOption, FmtDecimal, FmtDate, FmtBlob: Format of a Rec field of that type; SubstLabel: StrSubstNo of a label
//   with Rec fields; ReadProc: a procedure that only reads Rec fields and locals; FlowFilter: Rec.GetFilter of a FlowFilter field; Next5:
//   Next(5) on a fresh local record; FindNext: FindFirst and Next on a local record), then logs it as DC=<value> in a SingleInstance log.
// Log: OnOpenPage, every run of the expression (DC=...), H0 when the handler starts and H1 with the caption and the controls it reads
//   (T0 and T1 for a Trap), and "after open". Facts: the log, the test's record after the open, the row count, and for a page variable
//   its globals, filters and current record read after the close.
// What BC did (measured by the pull request's CI run; identical on 27.5, 28.5 and 29.0):
//   - No open raises, for every expression, opening and view. Inside asserterror (Lit and FmtBlob, Page.Run) the only error is the
//     test's own one raised after the open.
//   - Empty view: the expression runs twice before the handler starts (H0) or before the test's first Trap read (T0); Rec holds the
//     filter value (Code A) and blank other fields. One-row view: it runs once, on row A.
//   - Reading TestPage.Caption() does not run it again. The caption is '<page caption> - <value>'; a value that is blank or only spaces
//     gives the page caption alone, and a trailing space of the value is dropped ('CPO Lit - Cap').
//   - The same counts for Page.Run, Page.RunModal, a page variable's Run and RunModal, Trap before Page.Run and Trap before a page
//     variable's Run.
//   - Values: Format of an Option field 'A' (blank row) or 'B'; Decimal '0' or '1,234.5'; Date '' or '01/15/26'; StrSubstNo with the
//     label 'Row  (A)' or 'Row Alpha (A)'; GetFilter of the FlowFilter '01/01/26..12/31/26' on both views; Next(5) on a fresh local
//     record '0' (no rows) or '2' (rows A and B); FindFirst and Next on a local record 'No//0/' or 'Yes/A/1/B'.
//   - Format of a Blob field gives '*' when the row's Blob holds data and ' ' (one space) when it is empty or the view is empty; it
//     does not raise.
//   - The handler and the Trap read g=open (set in OnOpenPage) and code=A on both views. The test's record after the open keeps its
//     filters and has an empty Code; the store keeps its rows.
//   - The page variable after the close: after Run (with a handler or a Trap) its globals, filters and record are empty; after RunModal
//     they are g=open, the filters of SetTableView, and code=A on both views.
//   - Inside asserterror the rows Seed inserted are rolled back with the error (store 0 after it).
// BC versions: 27.5, 28.5, 29.0

table 76900 "CPO Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Name; Text[50]) { }
        field(3; Kind; Option) { OptionMembers = A,B,C; }
        field(4; Amount; Decimal) { }
        field(5; Posted; Date) { }
        field(6; Pic; Blob) { }
        field(7; "Date Filter"; Date) { FieldClass = FlowFilter; }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

page 76902 "CPO WS Lit"
{
    PageType = Worksheet;
    SourceTable = "CPO Row";
    Caption = 'CPO Lit';
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
        Log: Codeunit "CPO Log";
        G: Text[30];
        CapLbl: Label 'Row %1 (%2)';

    // The caption expression: computes V the way the test name says, then logs it (the log is the only write).
    local procedure Cap(): Text
    var
        R: Record "CPO Row";
        V: Text;
    begin
        V := 'Cap ' + Rec.Name;
        Log.Add('DC=' + V);
        exit(V);
    end;

    procedure State(): Text
    begin
        exit('g=' + G + ' filters=' + Rec.GetFilters + ' code=' + Rec."Code");
    end;

    trigger OnOpenPage()
    begin
        G := 'open';
        Log.Add('OnOpenPage');
    end;
}

page 76903 "CPO WS FmtOption"
{
    PageType = Worksheet;
    SourceTable = "CPO Row";
    Caption = 'CPO FmtOption';
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
        Log: Codeunit "CPO Log";
        G: Text[30];
        CapLbl: Label 'Row %1 (%2)';

    // The caption expression: computes V the way the test name says, then logs it (the log is the only write).
    local procedure Cap(): Text
    var
        R: Record "CPO Row";
        V: Text;
    begin
        V := Format(Rec.Kind);
        Log.Add('DC=' + V);
        exit(V);
    end;

    procedure State(): Text
    begin
        exit('g=' + G + ' filters=' + Rec.GetFilters + ' code=' + Rec."Code");
    end;

    trigger OnOpenPage()
    begin
        G := 'open';
        Log.Add('OnOpenPage');
    end;
}

page 76904 "CPO WS FmtDecimal"
{
    PageType = Worksheet;
    SourceTable = "CPO Row";
    Caption = 'CPO FmtDecimal';
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
        Log: Codeunit "CPO Log";
        G: Text[30];
        CapLbl: Label 'Row %1 (%2)';

    // The caption expression: computes V the way the test name says, then logs it (the log is the only write).
    local procedure Cap(): Text
    var
        R: Record "CPO Row";
        V: Text;
    begin
        V := Format(Rec.Amount);
        Log.Add('DC=' + V);
        exit(V);
    end;

    procedure State(): Text
    begin
        exit('g=' + G + ' filters=' + Rec.GetFilters + ' code=' + Rec."Code");
    end;

    trigger OnOpenPage()
    begin
        G := 'open';
        Log.Add('OnOpenPage');
    end;
}

page 76905 "CPO WS FmtDate"
{
    PageType = Worksheet;
    SourceTable = "CPO Row";
    Caption = 'CPO FmtDate';
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
        Log: Codeunit "CPO Log";
        G: Text[30];
        CapLbl: Label 'Row %1 (%2)';

    // The caption expression: computes V the way the test name says, then logs it (the log is the only write).
    local procedure Cap(): Text
    var
        R: Record "CPO Row";
        V: Text;
    begin
        V := Format(Rec.Posted);
        Log.Add('DC=' + V);
        exit(V);
    end;

    procedure State(): Text
    begin
        exit('g=' + G + ' filters=' + Rec.GetFilters + ' code=' + Rec."Code");
    end;

    trigger OnOpenPage()
    begin
        G := 'open';
        Log.Add('OnOpenPage');
    end;
}

page 76906 "CPO WS SubstLabel"
{
    PageType = Worksheet;
    SourceTable = "CPO Row";
    Caption = 'CPO SubstLabel';
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
        Log: Codeunit "CPO Log";
        G: Text[30];
        CapLbl: Label 'Row %1 (%2)';

    // The caption expression: computes V the way the test name says, then logs it (the log is the only write).
    local procedure Cap(): Text
    var
        R: Record "CPO Row";
        V: Text;
    begin
        V := StrSubstNo(CapLbl, Rec.Name, Rec.Code);
        Log.Add('DC=' + V);
        exit(V);
    end;

    procedure State(): Text
    begin
        exit('g=' + G + ' filters=' + Rec.GetFilters + ' code=' + Rec."Code");
    end;

    trigger OnOpenPage()
    begin
        G := 'open';
        Log.Add('OnOpenPage');
    end;
}

page 76907 "CPO WS ReadProc"
{
    PageType = Worksheet;
    SourceTable = "CPO Row";
    Caption = 'CPO ReadProc';
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
        Log: Codeunit "CPO Log";
        G: Text[30];
        CapLbl: Label 'Row %1 (%2)';

    // The caption expression: computes V the way the test name says, then logs it (the log is the only write).
    local procedure Cap(): Text
    var
        R: Record "CPO Row";
        V: Text;
    begin
        V := ReadOnlyCap();
        Log.Add('DC=' + V);
        exit(V);
    end;

    local procedure ReadOnlyCap(): Text
    var
        T: Text;
    begin
        T := Rec.Code;
        if Rec.Amount > 100 then
            T := T + ' big'
        else
            T := T + ' small';
        case Rec.Kind of
            Rec.Kind::A:
                T := T + ' a';
            Rec.Kind::B:
                T := T + ' b';
        end;
        exit(T);
    end;

    procedure State(): Text
    begin
        exit('g=' + G + ' filters=' + Rec.GetFilters + ' code=' + Rec."Code");
    end;

    trigger OnOpenPage()
    begin
        G := 'open';
        Log.Add('OnOpenPage');
    end;
}

page 76908 "CPO WS FlowFilter"
{
    PageType = Worksheet;
    SourceTable = "CPO Row";
    Caption = 'CPO FlowFilter';
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
        Log: Codeunit "CPO Log";
        G: Text[30];
        CapLbl: Label 'Row %1 (%2)';

    // The caption expression: computes V the way the test name says, then logs it (the log is the only write).
    local procedure Cap(): Text
    var
        R: Record "CPO Row";
        V: Text;
    begin
        V := Rec.GetFilter("Date Filter");
        Log.Add('DC=' + V);
        exit(V);
    end;

    procedure State(): Text
    begin
        exit('g=' + G + ' filters=' + Rec.GetFilters + ' code=' + Rec."Code");
    end;

    trigger OnOpenPage()
    begin
        G := 'open';
        Log.Add('OnOpenPage');
    end;
}

page 76909 "CPO WS Next5"
{
    PageType = Worksheet;
    SourceTable = "CPO Row";
    Caption = 'CPO Next5';
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
        Log: Codeunit "CPO Log";
        G: Text[30];
        CapLbl: Label 'Row %1 (%2)';

    // The caption expression: computes V the way the test name says, then logs it (the log is the only write).
    local procedure Cap(): Text
    var
        R: Record "CPO Row";
        V: Text;
    begin
        V := Format(R.Next(5));
        Log.Add('DC=' + V);
        exit(V);
    end;

    procedure State(): Text
    begin
        exit('g=' + G + ' filters=' + Rec.GetFilters + ' code=' + Rec."Code");
    end;

    trigger OnOpenPage()
    begin
        G := 'open';
        Log.Add('OnOpenPage');
    end;
}

page 76910 "CPO WS FindNext"
{
    PageType = Worksheet;
    SourceTable = "CPO Row";
    Caption = 'CPO FindNext';
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
        Log: Codeunit "CPO Log";
        G: Text[30];
        CapLbl: Label 'Row %1 (%2)';

    // The caption expression: computes V the way the test name says, then logs it (the log is the only write).
    local procedure Cap(): Text
    var
        R: Record "CPO Row";
        V: Text;
    begin
        V := Format(R.FindFirst()) + '/' + R.Code + '/' + Format(R.Next()) + '/' + R.Code;
        Log.Add('DC=' + V);
        exit(V);
    end;

    procedure State(): Text
    begin
        exit('g=' + G + ' filters=' + Rec.GetFilters + ' code=' + Rec."Code");
    end;

    trigger OnOpenPage()
    begin
        G := 'open';
        Log.Add('OnOpenPage');
    end;
}

page 76911 "CPO WS FmtBlob"
{
    PageType = Worksheet;
    SourceTable = "CPO Row";
    Caption = 'CPO FmtBlob';
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
        Log: Codeunit "CPO Log";
        G: Text[30];
        CapLbl: Label 'Row %1 (%2)';

    // The caption expression: computes V the way the test name says, then logs it (the log is the only write).
    local procedure Cap(): Text
    var
        R: Record "CPO Row";
        V: Text;
    begin
        V := Format(Rec.Pic);
        Log.Add('DC=' + V);
        exit(V);
    end;

    procedure State(): Text
    begin
        exit('g=' + G + ' filters=' + Rec.GetFilters + ' code=' + Rec."Code");
    end;

    trigger OnOpenPage()
    begin
        G := 'open';
        Log.Add('OnOpenPage');
    end;
}

codeunit 76901 "CPO Log"
{
    SingleInstance = true;

    var
        Lines: List of [Text];

    procedure Wipe()
    begin
        Clear(Lines);
    end;

    procedure Add(Line: Text)
    begin
        Lines.Add(Line);
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

codeunit 76912 "CPO Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "CPO Log";

    // Empty: the table has no rows. OneRow: rows A and B; the view (Code = A) holds A only. Pic of A holds 'hello' unless BlobEmpty.
    local procedure Seed(View: Text; var Row: Record "CPO Row")
    var
        Seeded: Record "CPO Row";
        OutS: OutStream;
    begin
        Seeded.DeleteAll();
        Log.Wipe();
        if View <> 'Empty' then begin
            Seeded.Init();
            Seeded."Code" := 'A';
            Seeded.Name := 'Alpha';
            Seeded.Kind := Seeded.Kind::B;
            Seeded.Amount := 1234.5;
            Seeded.Posted := 20260115D;
            if View <> 'OneRowBlobEmpty' then begin
                Seeded.Pic.CreateOutStream(OutS);
                OutS.WriteText('hello');
            end;
            Seeded.Insert();
            Seeded.Init();
            Seeded."Code" := 'B';
            Seeded.Name := 'Beta';
            Seeded.Insert();
        end;
        Row.Reset();
        Row.SetRange("Code", 'A');
        Row.SetRange("Date Filter", 20260101D, 20261231D);
    end;

    local procedure Facts(var Observer: Codeunit "Probe Observer"; var Row: Record "CPO Row")
    var
        Store: Record "CPO Row";
    begin
        Observer.Observe('log', Log.Joined());
        Observer.Observe('rec', 'filters=' + Row.GetFilters + ' code=' + Row."Code");
        Observer.Observe('store', Format(Store.Count()));
    end;

    [Test]
    [HandlerFunctions('HLit')]
    procedure Lit_Run_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('Empty', Row);
        Page.Run(Page::"CPO WS Lit", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=Cap  | DC=Cap  | H0 | H1 cap=CPO Lit - Cap g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HLit')]
    procedure Lit_Run_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('OneRow', Row);
        Page.Run(Page::"CPO WS Lit", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=Cap Alpha | H0 | H1 cap=CPO Lit - Cap Alpha g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHLit')]
    procedure Lit_RunModal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('Empty', Row);
        Page.RunModal(Page::"CPO WS Lit", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=Cap  | DC=Cap  | H0 | H1 cap=CPO Lit - Cap g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHLit')]
    procedure Lit_RunModal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('OneRow', Row);
        Page.RunModal(Page::"CPO WS Lit", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=Cap Alpha | H0 | H1 cap=CPO Lit - Cap Alpha g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HLit')]
    procedure Lit_VarRun_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS Lit";
    begin
        Seed('Empty', Row);
        PV.SetTableView(Row);
        PV.Run();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=Cap  | DC=Cap  | H0 | H1 cap=CPO Lit - Cap g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Expect('pagevar', 'g= filters= code=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HLit')]
    procedure Lit_VarRun_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS Lit";
    begin
        Seed('OneRow', Row);
        PV.SetTableView(Row);
        PV.Run();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=Cap Alpha | H0 | H1 cap=CPO Lit - Cap Alpha g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Expect('pagevar', 'g= filters= code=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHLit')]
    procedure Lit_VarRunModal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS Lit";
    begin
        Seed('Empty', Row);
        PV.SetTableView(Row);
        PV.RunModal();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=Cap  | DC=Cap  | H0 | H1 cap=CPO Lit - Cap g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Expect('pagevar', 'g=open filters=Code: A, Date Filter: 01/01/26..12/31/26 code=A');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHLit')]
    procedure Lit_VarRunModal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS Lit";
    begin
        Seed('OneRow', Row);
        PV.SetTableView(Row);
        PV.RunModal();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=Cap Alpha | H0 | H1 cap=CPO Lit - Cap Alpha g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Expect('pagevar', 'g=open filters=Code: A, Date Filter: 01/01/26..12/31/26 code=A');
        Observer.Verify();
    end;

    [Test]
    procedure Lit_Trap_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        TP: TestPage "CPO WS Lit";
        Cap: Text;
    begin
        Seed('Empty', Row);
        TP.Trap();
        Page.Run(Page::"CPO WS Lit", Row);
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=Cap  | DC=Cap  | T0 | T1 cap=CPO Lit - Cap g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Lit_Trap_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        TP: TestPage "CPO WS Lit";
        Cap: Text;
    begin
        Seed('OneRow', Row);
        TP.Trap();
        Page.Run(Page::"CPO WS Lit", Row);
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=Cap Alpha | T0 | T1 cap=CPO Lit - Cap Alpha g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Lit_TrapVarRun_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS Lit";
        TP: TestPage "CPO WS Lit";
        Cap: Text;
    begin
        Seed('Empty', Row);
        TP.Trap();
        PV.SetTableView(Row);
        PV.Run();
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=Cap  | DC=Cap  | T0 | T1 cap=CPO Lit - Cap g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Expect('pagevar', 'g= filters= code=');
        Observer.Verify();
    end;

    [Test]
    procedure Lit_TrapVarRun_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS Lit";
        TP: TestPage "CPO WS Lit";
        Cap: Text;
    begin
        Seed('OneRow', Row);
        TP.Trap();
        PV.SetTableView(Row);
        PV.Run();
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=Cap Alpha | T0 | T1 cap=CPO Lit - Cap Alpha g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Expect('pagevar', 'g= filters= code=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HFmtOption')]
    procedure FmtOption_Run_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('Empty', Row);
        Page.Run(Page::"CPO WS FmtOption", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=A | DC=A | H0 | H1 cap=CPO FmtOption - A g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HFmtOption')]
    procedure FmtOption_Run_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('OneRow', Row);
        Page.Run(Page::"CPO WS FmtOption", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=B | H0 | H1 cap=CPO FmtOption - B g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHFmtOption')]
    procedure FmtOption_RunModal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('Empty', Row);
        Page.RunModal(Page::"CPO WS FmtOption", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=A | DC=A | H0 | H1 cap=CPO FmtOption - A g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHFmtOption')]
    procedure FmtOption_RunModal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('OneRow', Row);
        Page.RunModal(Page::"CPO WS FmtOption", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=B | H0 | H1 cap=CPO FmtOption - B g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HFmtOption')]
    procedure FmtOption_VarRun_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS FmtOption";
    begin
        Seed('Empty', Row);
        PV.SetTableView(Row);
        PV.Run();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=A | DC=A | H0 | H1 cap=CPO FmtOption - A g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Expect('pagevar', 'g= filters= code=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HFmtOption')]
    procedure FmtOption_VarRun_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS FmtOption";
    begin
        Seed('OneRow', Row);
        PV.SetTableView(Row);
        PV.Run();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=B | H0 | H1 cap=CPO FmtOption - B g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Expect('pagevar', 'g= filters= code=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHFmtOption')]
    procedure FmtOption_VarRunModal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS FmtOption";
    begin
        Seed('Empty', Row);
        PV.SetTableView(Row);
        PV.RunModal();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=A | DC=A | H0 | H1 cap=CPO FmtOption - A g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Expect('pagevar', 'g=open filters=Code: A, Date Filter: 01/01/26..12/31/26 code=A');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHFmtOption')]
    procedure FmtOption_VarRunModal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS FmtOption";
    begin
        Seed('OneRow', Row);
        PV.SetTableView(Row);
        PV.RunModal();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=B | H0 | H1 cap=CPO FmtOption - B g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Expect('pagevar', 'g=open filters=Code: A, Date Filter: 01/01/26..12/31/26 code=A');
        Observer.Verify();
    end;

    [Test]
    procedure FmtOption_Trap_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        TP: TestPage "CPO WS FmtOption";
        Cap: Text;
    begin
        Seed('Empty', Row);
        TP.Trap();
        Page.Run(Page::"CPO WS FmtOption", Row);
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=A | DC=A | T0 | T1 cap=CPO FmtOption - A g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Verify();
    end;

    [Test]
    procedure FmtOption_Trap_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        TP: TestPage "CPO WS FmtOption";
        Cap: Text;
    begin
        Seed('OneRow', Row);
        TP.Trap();
        Page.Run(Page::"CPO WS FmtOption", Row);
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=B | T0 | T1 cap=CPO FmtOption - B g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Verify();
    end;

    [Test]
    procedure FmtOption_TrapVarRun_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS FmtOption";
        TP: TestPage "CPO WS FmtOption";
        Cap: Text;
    begin
        Seed('Empty', Row);
        TP.Trap();
        PV.SetTableView(Row);
        PV.Run();
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=A | DC=A | T0 | T1 cap=CPO FmtOption - A g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Expect('pagevar', 'g= filters= code=');
        Observer.Verify();
    end;

    [Test]
    procedure FmtOption_TrapVarRun_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS FmtOption";
        TP: TestPage "CPO WS FmtOption";
        Cap: Text;
    begin
        Seed('OneRow', Row);
        TP.Trap();
        PV.SetTableView(Row);
        PV.Run();
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=B | T0 | T1 cap=CPO FmtOption - B g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Expect('pagevar', 'g= filters= code=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HFmtDecimal')]
    procedure FmtDecimal_Run_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('Empty', Row);
        Page.Run(Page::"CPO WS FmtDecimal", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=0 | DC=0 | H0 | H1 cap=CPO FmtDecimal - 0 g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HFmtDecimal')]
    procedure FmtDecimal_Run_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('OneRow', Row);
        Page.Run(Page::"CPO WS FmtDecimal", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=1,234.5 | H0 | H1 cap=CPO FmtDecimal - 1,234.5 g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHFmtDecimal')]
    procedure FmtDecimal_RunModal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('Empty', Row);
        Page.RunModal(Page::"CPO WS FmtDecimal", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=0 | DC=0 | H0 | H1 cap=CPO FmtDecimal - 0 g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHFmtDecimal')]
    procedure FmtDecimal_RunModal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('OneRow', Row);
        Page.RunModal(Page::"CPO WS FmtDecimal", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=1,234.5 | H0 | H1 cap=CPO FmtDecimal - 1,234.5 g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HFmtDecimal')]
    procedure FmtDecimal_VarRun_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS FmtDecimal";
    begin
        Seed('Empty', Row);
        PV.SetTableView(Row);
        PV.Run();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=0 | DC=0 | H0 | H1 cap=CPO FmtDecimal - 0 g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Expect('pagevar', 'g= filters= code=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HFmtDecimal')]
    procedure FmtDecimal_VarRun_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS FmtDecimal";
    begin
        Seed('OneRow', Row);
        PV.SetTableView(Row);
        PV.Run();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=1,234.5 | H0 | H1 cap=CPO FmtDecimal - 1,234.5 g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Expect('pagevar', 'g= filters= code=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHFmtDecimal')]
    procedure FmtDecimal_VarRunModal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS FmtDecimal";
    begin
        Seed('Empty', Row);
        PV.SetTableView(Row);
        PV.RunModal();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=0 | DC=0 | H0 | H1 cap=CPO FmtDecimal - 0 g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Expect('pagevar', 'g=open filters=Code: A, Date Filter: 01/01/26..12/31/26 code=A');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHFmtDecimal')]
    procedure FmtDecimal_VarRunModal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS FmtDecimal";
    begin
        Seed('OneRow', Row);
        PV.SetTableView(Row);
        PV.RunModal();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=1,234.5 | H0 | H1 cap=CPO FmtDecimal - 1,234.5 g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Expect('pagevar', 'g=open filters=Code: A, Date Filter: 01/01/26..12/31/26 code=A');
        Observer.Verify();
    end;

    [Test]
    procedure FmtDecimal_Trap_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        TP: TestPage "CPO WS FmtDecimal";
        Cap: Text;
    begin
        Seed('Empty', Row);
        TP.Trap();
        Page.Run(Page::"CPO WS FmtDecimal", Row);
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=0 | DC=0 | T0 | T1 cap=CPO FmtDecimal - 0 g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Verify();
    end;

    [Test]
    procedure FmtDecimal_Trap_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        TP: TestPage "CPO WS FmtDecimal";
        Cap: Text;
    begin
        Seed('OneRow', Row);
        TP.Trap();
        Page.Run(Page::"CPO WS FmtDecimal", Row);
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=1,234.5 | T0 | T1 cap=CPO FmtDecimal - 1,234.5 g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Verify();
    end;

    [Test]
    procedure FmtDecimal_TrapVarRun_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS FmtDecimal";
        TP: TestPage "CPO WS FmtDecimal";
        Cap: Text;
    begin
        Seed('Empty', Row);
        TP.Trap();
        PV.SetTableView(Row);
        PV.Run();
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=0 | DC=0 | T0 | T1 cap=CPO FmtDecimal - 0 g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Expect('pagevar', 'g= filters= code=');
        Observer.Verify();
    end;

    [Test]
    procedure FmtDecimal_TrapVarRun_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS FmtDecimal";
        TP: TestPage "CPO WS FmtDecimal";
        Cap: Text;
    begin
        Seed('OneRow', Row);
        TP.Trap();
        PV.SetTableView(Row);
        PV.Run();
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=1,234.5 | T0 | T1 cap=CPO FmtDecimal - 1,234.5 g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Expect('pagevar', 'g= filters= code=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HFmtDate')]
    procedure FmtDate_Run_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('Empty', Row);
        Page.Run(Page::"CPO WS FmtDate", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC= | DC= | H0 | H1 cap=CPO FmtDate g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HFmtDate')]
    procedure FmtDate_Run_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('OneRow', Row);
        Page.Run(Page::"CPO WS FmtDate", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=01/15/26 | H0 | H1 cap=CPO FmtDate - 01/15/26 g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHFmtDate')]
    procedure FmtDate_RunModal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('Empty', Row);
        Page.RunModal(Page::"CPO WS FmtDate", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC= | DC= | H0 | H1 cap=CPO FmtDate g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHFmtDate')]
    procedure FmtDate_RunModal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('OneRow', Row);
        Page.RunModal(Page::"CPO WS FmtDate", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=01/15/26 | H0 | H1 cap=CPO FmtDate - 01/15/26 g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HFmtDate')]
    procedure FmtDate_VarRun_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS FmtDate";
    begin
        Seed('Empty', Row);
        PV.SetTableView(Row);
        PV.Run();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC= | DC= | H0 | H1 cap=CPO FmtDate g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Expect('pagevar', 'g= filters= code=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HFmtDate')]
    procedure FmtDate_VarRun_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS FmtDate";
    begin
        Seed('OneRow', Row);
        PV.SetTableView(Row);
        PV.Run();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=01/15/26 | H0 | H1 cap=CPO FmtDate - 01/15/26 g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Expect('pagevar', 'g= filters= code=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHFmtDate')]
    procedure FmtDate_VarRunModal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS FmtDate";
    begin
        Seed('Empty', Row);
        PV.SetTableView(Row);
        PV.RunModal();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC= | DC= | H0 | H1 cap=CPO FmtDate g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Expect('pagevar', 'g=open filters=Code: A, Date Filter: 01/01/26..12/31/26 code=A');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHFmtDate')]
    procedure FmtDate_VarRunModal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS FmtDate";
    begin
        Seed('OneRow', Row);
        PV.SetTableView(Row);
        PV.RunModal();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=01/15/26 | H0 | H1 cap=CPO FmtDate - 01/15/26 g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Expect('pagevar', 'g=open filters=Code: A, Date Filter: 01/01/26..12/31/26 code=A');
        Observer.Verify();
    end;

    [Test]
    procedure FmtDate_Trap_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        TP: TestPage "CPO WS FmtDate";
        Cap: Text;
    begin
        Seed('Empty', Row);
        TP.Trap();
        Page.Run(Page::"CPO WS FmtDate", Row);
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC= | DC= | T0 | T1 cap=CPO FmtDate g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Verify();
    end;

    [Test]
    procedure FmtDate_Trap_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        TP: TestPage "CPO WS FmtDate";
        Cap: Text;
    begin
        Seed('OneRow', Row);
        TP.Trap();
        Page.Run(Page::"CPO WS FmtDate", Row);
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=01/15/26 | T0 | T1 cap=CPO FmtDate - 01/15/26 g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Verify();
    end;

    [Test]
    procedure FmtDate_TrapVarRun_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS FmtDate";
        TP: TestPage "CPO WS FmtDate";
        Cap: Text;
    begin
        Seed('Empty', Row);
        TP.Trap();
        PV.SetTableView(Row);
        PV.Run();
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC= | DC= | T0 | T1 cap=CPO FmtDate g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Expect('pagevar', 'g= filters= code=');
        Observer.Verify();
    end;

    [Test]
    procedure FmtDate_TrapVarRun_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS FmtDate";
        TP: TestPage "CPO WS FmtDate";
        Cap: Text;
    begin
        Seed('OneRow', Row);
        TP.Trap();
        PV.SetTableView(Row);
        PV.Run();
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=01/15/26 | T0 | T1 cap=CPO FmtDate - 01/15/26 g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Expect('pagevar', 'g= filters= code=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HSubstLabel')]
    procedure SubstLabel_Run_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('Empty', Row);
        Page.Run(Page::"CPO WS SubstLabel", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=Row  (A) | DC=Row  (A) | H0 | H1 cap=CPO SubstLabel - Row  (A) g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HSubstLabel')]
    procedure SubstLabel_Run_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('OneRow', Row);
        Page.Run(Page::"CPO WS SubstLabel", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=Row Alpha (A) | H0 | H1 cap=CPO SubstLabel - Row Alpha (A) g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHSubstLabel')]
    procedure SubstLabel_RunModal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('Empty', Row);
        Page.RunModal(Page::"CPO WS SubstLabel", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=Row  (A) | DC=Row  (A) | H0 | H1 cap=CPO SubstLabel - Row  (A) g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHSubstLabel')]
    procedure SubstLabel_RunModal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('OneRow', Row);
        Page.RunModal(Page::"CPO WS SubstLabel", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=Row Alpha (A) | H0 | H1 cap=CPO SubstLabel - Row Alpha (A) g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HSubstLabel')]
    procedure SubstLabel_VarRun_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS SubstLabel";
    begin
        Seed('Empty', Row);
        PV.SetTableView(Row);
        PV.Run();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=Row  (A) | DC=Row  (A) | H0 | H1 cap=CPO SubstLabel - Row  (A) g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Expect('pagevar', 'g= filters= code=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HSubstLabel')]
    procedure SubstLabel_VarRun_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS SubstLabel";
    begin
        Seed('OneRow', Row);
        PV.SetTableView(Row);
        PV.Run();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=Row Alpha (A) | H0 | H1 cap=CPO SubstLabel - Row Alpha (A) g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Expect('pagevar', 'g= filters= code=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHSubstLabel')]
    procedure SubstLabel_VarRunModal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS SubstLabel";
    begin
        Seed('Empty', Row);
        PV.SetTableView(Row);
        PV.RunModal();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=Row  (A) | DC=Row  (A) | H0 | H1 cap=CPO SubstLabel - Row  (A) g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Expect('pagevar', 'g=open filters=Code: A, Date Filter: 01/01/26..12/31/26 code=A');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHSubstLabel')]
    procedure SubstLabel_VarRunModal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS SubstLabel";
    begin
        Seed('OneRow', Row);
        PV.SetTableView(Row);
        PV.RunModal();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=Row Alpha (A) | H0 | H1 cap=CPO SubstLabel - Row Alpha (A) g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Expect('pagevar', 'g=open filters=Code: A, Date Filter: 01/01/26..12/31/26 code=A');
        Observer.Verify();
    end;

    [Test]
    procedure SubstLabel_Trap_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        TP: TestPage "CPO WS SubstLabel";
        Cap: Text;
    begin
        Seed('Empty', Row);
        TP.Trap();
        Page.Run(Page::"CPO WS SubstLabel", Row);
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=Row  (A) | DC=Row  (A) | T0 | T1 cap=CPO SubstLabel - Row  (A) g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SubstLabel_Trap_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        TP: TestPage "CPO WS SubstLabel";
        Cap: Text;
    begin
        Seed('OneRow', Row);
        TP.Trap();
        Page.Run(Page::"CPO WS SubstLabel", Row);
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=Row Alpha (A) | T0 | T1 cap=CPO SubstLabel - Row Alpha (A) g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Verify();
    end;

    [Test]
    procedure SubstLabel_TrapVarRun_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS SubstLabel";
        TP: TestPage "CPO WS SubstLabel";
        Cap: Text;
    begin
        Seed('Empty', Row);
        TP.Trap();
        PV.SetTableView(Row);
        PV.Run();
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=Row  (A) | DC=Row  (A) | T0 | T1 cap=CPO SubstLabel - Row  (A) g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Expect('pagevar', 'g= filters= code=');
        Observer.Verify();
    end;

    [Test]
    procedure SubstLabel_TrapVarRun_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS SubstLabel";
        TP: TestPage "CPO WS SubstLabel";
        Cap: Text;
    begin
        Seed('OneRow', Row);
        TP.Trap();
        PV.SetTableView(Row);
        PV.Run();
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=Row Alpha (A) | T0 | T1 cap=CPO SubstLabel - Row Alpha (A) g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Expect('pagevar', 'g= filters= code=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HReadProc')]
    procedure ReadProc_Run_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('Empty', Row);
        Page.Run(Page::"CPO WS ReadProc", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=A small a | DC=A small a | H0 | H1 cap=CPO ReadProc - A small a g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HReadProc')]
    procedure ReadProc_Run_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('OneRow', Row);
        Page.Run(Page::"CPO WS ReadProc", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=A big b | H0 | H1 cap=CPO ReadProc - A big b g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHReadProc')]
    procedure ReadProc_RunModal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('Empty', Row);
        Page.RunModal(Page::"CPO WS ReadProc", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=A small a | DC=A small a | H0 | H1 cap=CPO ReadProc - A small a g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHReadProc')]
    procedure ReadProc_RunModal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('OneRow', Row);
        Page.RunModal(Page::"CPO WS ReadProc", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=A big b | H0 | H1 cap=CPO ReadProc - A big b g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HReadProc')]
    procedure ReadProc_VarRun_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS ReadProc";
    begin
        Seed('Empty', Row);
        PV.SetTableView(Row);
        PV.Run();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=A small a | DC=A small a | H0 | H1 cap=CPO ReadProc - A small a g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Expect('pagevar', 'g= filters= code=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HReadProc')]
    procedure ReadProc_VarRun_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS ReadProc";
    begin
        Seed('OneRow', Row);
        PV.SetTableView(Row);
        PV.Run();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=A big b | H0 | H1 cap=CPO ReadProc - A big b g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Expect('pagevar', 'g= filters= code=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHReadProc')]
    procedure ReadProc_VarRunModal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS ReadProc";
    begin
        Seed('Empty', Row);
        PV.SetTableView(Row);
        PV.RunModal();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=A small a | DC=A small a | H0 | H1 cap=CPO ReadProc - A small a g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Expect('pagevar', 'g=open filters=Code: A, Date Filter: 01/01/26..12/31/26 code=A');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHReadProc')]
    procedure ReadProc_VarRunModal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS ReadProc";
    begin
        Seed('OneRow', Row);
        PV.SetTableView(Row);
        PV.RunModal();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=A big b | H0 | H1 cap=CPO ReadProc - A big b g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Expect('pagevar', 'g=open filters=Code: A, Date Filter: 01/01/26..12/31/26 code=A');
        Observer.Verify();
    end;

    [Test]
    procedure ReadProc_Trap_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        TP: TestPage "CPO WS ReadProc";
        Cap: Text;
    begin
        Seed('Empty', Row);
        TP.Trap();
        Page.Run(Page::"CPO WS ReadProc", Row);
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=A small a | DC=A small a | T0 | T1 cap=CPO ReadProc - A small a g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Verify();
    end;

    [Test]
    procedure ReadProc_Trap_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        TP: TestPage "CPO WS ReadProc";
        Cap: Text;
    begin
        Seed('OneRow', Row);
        TP.Trap();
        Page.Run(Page::"CPO WS ReadProc", Row);
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=A big b | T0 | T1 cap=CPO ReadProc - A big b g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Verify();
    end;

    [Test]
    procedure ReadProc_TrapVarRun_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS ReadProc";
        TP: TestPage "CPO WS ReadProc";
        Cap: Text;
    begin
        Seed('Empty', Row);
        TP.Trap();
        PV.SetTableView(Row);
        PV.Run();
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=A small a | DC=A small a | T0 | T1 cap=CPO ReadProc - A small a g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Expect('pagevar', 'g= filters= code=');
        Observer.Verify();
    end;

    [Test]
    procedure ReadProc_TrapVarRun_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS ReadProc";
        TP: TestPage "CPO WS ReadProc";
        Cap: Text;
    begin
        Seed('OneRow', Row);
        TP.Trap();
        PV.SetTableView(Row);
        PV.Run();
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=A big b | T0 | T1 cap=CPO ReadProc - A big b g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Expect('pagevar', 'g= filters= code=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HFlowFilter')]
    procedure FlowFilter_Run_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('Empty', Row);
        Page.Run(Page::"CPO WS FlowFilter", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=01/01/26..12/31/26 | DC=01/01/26..12/31/26 | H0 | H1 cap=CPO FlowFilter - 01/01/26..12/31/26 g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HFlowFilter')]
    procedure FlowFilter_Run_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('OneRow', Row);
        Page.Run(Page::"CPO WS FlowFilter", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=01/01/26..12/31/26 | H0 | H1 cap=CPO FlowFilter - 01/01/26..12/31/26 g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHFlowFilter')]
    procedure FlowFilter_RunModal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('Empty', Row);
        Page.RunModal(Page::"CPO WS FlowFilter", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=01/01/26..12/31/26 | DC=01/01/26..12/31/26 | H0 | H1 cap=CPO FlowFilter - 01/01/26..12/31/26 g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHFlowFilter')]
    procedure FlowFilter_RunModal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('OneRow', Row);
        Page.RunModal(Page::"CPO WS FlowFilter", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=01/01/26..12/31/26 | H0 | H1 cap=CPO FlowFilter - 01/01/26..12/31/26 g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HFlowFilter')]
    procedure FlowFilter_VarRun_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS FlowFilter";
    begin
        Seed('Empty', Row);
        PV.SetTableView(Row);
        PV.Run();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=01/01/26..12/31/26 | DC=01/01/26..12/31/26 | H0 | H1 cap=CPO FlowFilter - 01/01/26..12/31/26 g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Expect('pagevar', 'g= filters= code=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HFlowFilter')]
    procedure FlowFilter_VarRun_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS FlowFilter";
    begin
        Seed('OneRow', Row);
        PV.SetTableView(Row);
        PV.Run();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=01/01/26..12/31/26 | H0 | H1 cap=CPO FlowFilter - 01/01/26..12/31/26 g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Expect('pagevar', 'g= filters= code=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHFlowFilter')]
    procedure FlowFilter_VarRunModal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS FlowFilter";
    begin
        Seed('Empty', Row);
        PV.SetTableView(Row);
        PV.RunModal();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=01/01/26..12/31/26 | DC=01/01/26..12/31/26 | H0 | H1 cap=CPO FlowFilter - 01/01/26..12/31/26 g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Expect('pagevar', 'g=open filters=Code: A, Date Filter: 01/01/26..12/31/26 code=A');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHFlowFilter')]
    procedure FlowFilter_VarRunModal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS FlowFilter";
    begin
        Seed('OneRow', Row);
        PV.SetTableView(Row);
        PV.RunModal();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=01/01/26..12/31/26 | H0 | H1 cap=CPO FlowFilter - 01/01/26..12/31/26 g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Expect('pagevar', 'g=open filters=Code: A, Date Filter: 01/01/26..12/31/26 code=A');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFilter_Trap_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        TP: TestPage "CPO WS FlowFilter";
        Cap: Text;
    begin
        Seed('Empty', Row);
        TP.Trap();
        Page.Run(Page::"CPO WS FlowFilter", Row);
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=01/01/26..12/31/26 | DC=01/01/26..12/31/26 | T0 | T1 cap=CPO FlowFilter - 01/01/26..12/31/26 g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFilter_Trap_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        TP: TestPage "CPO WS FlowFilter";
        Cap: Text;
    begin
        Seed('OneRow', Row);
        TP.Trap();
        Page.Run(Page::"CPO WS FlowFilter", Row);
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=01/01/26..12/31/26 | T0 | T1 cap=CPO FlowFilter - 01/01/26..12/31/26 g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFilter_TrapVarRun_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS FlowFilter";
        TP: TestPage "CPO WS FlowFilter";
        Cap: Text;
    begin
        Seed('Empty', Row);
        TP.Trap();
        PV.SetTableView(Row);
        PV.Run();
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=01/01/26..12/31/26 | DC=01/01/26..12/31/26 | T0 | T1 cap=CPO FlowFilter - 01/01/26..12/31/26 g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Expect('pagevar', 'g= filters= code=');
        Observer.Verify();
    end;

    [Test]
    procedure FlowFilter_TrapVarRun_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS FlowFilter";
        TP: TestPage "CPO WS FlowFilter";
        Cap: Text;
    begin
        Seed('OneRow', Row);
        TP.Trap();
        PV.SetTableView(Row);
        PV.Run();
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=01/01/26..12/31/26 | T0 | T1 cap=CPO FlowFilter - 01/01/26..12/31/26 g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Expect('pagevar', 'g= filters= code=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HNext5')]
    procedure Next5_Run_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('Empty', Row);
        Page.Run(Page::"CPO WS Next5", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=0 | DC=0 | H0 | H1 cap=CPO Next5 - 0 g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HNext5')]
    procedure Next5_Run_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('OneRow', Row);
        Page.Run(Page::"CPO WS Next5", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=2 | H0 | H1 cap=CPO Next5 - 2 g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHNext5')]
    procedure Next5_RunModal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('Empty', Row);
        Page.RunModal(Page::"CPO WS Next5", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=0 | DC=0 | H0 | H1 cap=CPO Next5 - 0 g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHNext5')]
    procedure Next5_RunModal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('OneRow', Row);
        Page.RunModal(Page::"CPO WS Next5", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=2 | H0 | H1 cap=CPO Next5 - 2 g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HNext5')]
    procedure Next5_VarRun_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS Next5";
    begin
        Seed('Empty', Row);
        PV.SetTableView(Row);
        PV.Run();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=0 | DC=0 | H0 | H1 cap=CPO Next5 - 0 g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Expect('pagevar', 'g= filters= code=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HNext5')]
    procedure Next5_VarRun_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS Next5";
    begin
        Seed('OneRow', Row);
        PV.SetTableView(Row);
        PV.Run();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=2 | H0 | H1 cap=CPO Next5 - 2 g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Expect('pagevar', 'g= filters= code=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHNext5')]
    procedure Next5_VarRunModal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS Next5";
    begin
        Seed('Empty', Row);
        PV.SetTableView(Row);
        PV.RunModal();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=0 | DC=0 | H0 | H1 cap=CPO Next5 - 0 g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Expect('pagevar', 'g=open filters=Code: A, Date Filter: 01/01/26..12/31/26 code=A');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHNext5')]
    procedure Next5_VarRunModal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS Next5";
    begin
        Seed('OneRow', Row);
        PV.SetTableView(Row);
        PV.RunModal();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=2 | H0 | H1 cap=CPO Next5 - 2 g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Expect('pagevar', 'g=open filters=Code: A, Date Filter: 01/01/26..12/31/26 code=A');
        Observer.Verify();
    end;

    [Test]
    procedure Next5_Trap_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        TP: TestPage "CPO WS Next5";
        Cap: Text;
    begin
        Seed('Empty', Row);
        TP.Trap();
        Page.Run(Page::"CPO WS Next5", Row);
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=0 | DC=0 | T0 | T1 cap=CPO Next5 - 0 g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Next5_Trap_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        TP: TestPage "CPO WS Next5";
        Cap: Text;
    begin
        Seed('OneRow', Row);
        TP.Trap();
        Page.Run(Page::"CPO WS Next5", Row);
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=2 | T0 | T1 cap=CPO Next5 - 2 g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Next5_TrapVarRun_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS Next5";
        TP: TestPage "CPO WS Next5";
        Cap: Text;
    begin
        Seed('Empty', Row);
        TP.Trap();
        PV.SetTableView(Row);
        PV.Run();
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=0 | DC=0 | T0 | T1 cap=CPO Next5 - 0 g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Expect('pagevar', 'g= filters= code=');
        Observer.Verify();
    end;

    [Test]
    procedure Next5_TrapVarRun_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS Next5";
        TP: TestPage "CPO WS Next5";
        Cap: Text;
    begin
        Seed('OneRow', Row);
        TP.Trap();
        PV.SetTableView(Row);
        PV.Run();
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=2 | T0 | T1 cap=CPO Next5 - 2 g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Expect('pagevar', 'g= filters= code=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HFindNext')]
    procedure FindNext_Run_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('Empty', Row);
        Page.Run(Page::"CPO WS FindNext", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=No//0/ | DC=No//0/ | H0 | H1 cap=CPO FindNext - No//0/ g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HFindNext')]
    procedure FindNext_Run_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('OneRow', Row);
        Page.Run(Page::"CPO WS FindNext", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=Yes/A/1/B | H0 | H1 cap=CPO FindNext - Yes/A/1/B g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHFindNext')]
    procedure FindNext_RunModal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('Empty', Row);
        Page.RunModal(Page::"CPO WS FindNext", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=No//0/ | DC=No//0/ | H0 | H1 cap=CPO FindNext - No//0/ g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHFindNext')]
    procedure FindNext_RunModal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('OneRow', Row);
        Page.RunModal(Page::"CPO WS FindNext", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=Yes/A/1/B | H0 | H1 cap=CPO FindNext - Yes/A/1/B g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HFindNext')]
    procedure FindNext_VarRun_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS FindNext";
    begin
        Seed('Empty', Row);
        PV.SetTableView(Row);
        PV.Run();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=No//0/ | DC=No//0/ | H0 | H1 cap=CPO FindNext - No//0/ g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Expect('pagevar', 'g= filters= code=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HFindNext')]
    procedure FindNext_VarRun_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS FindNext";
    begin
        Seed('OneRow', Row);
        PV.SetTableView(Row);
        PV.Run();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=Yes/A/1/B | H0 | H1 cap=CPO FindNext - Yes/A/1/B g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Expect('pagevar', 'g= filters= code=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHFindNext')]
    procedure FindNext_VarRunModal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS FindNext";
    begin
        Seed('Empty', Row);
        PV.SetTableView(Row);
        PV.RunModal();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=No//0/ | DC=No//0/ | H0 | H1 cap=CPO FindNext - No//0/ g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Expect('pagevar', 'g=open filters=Code: A, Date Filter: 01/01/26..12/31/26 code=A');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHFindNext')]
    procedure FindNext_VarRunModal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS FindNext";
    begin
        Seed('OneRow', Row);
        PV.SetTableView(Row);
        PV.RunModal();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=Yes/A/1/B | H0 | H1 cap=CPO FindNext - Yes/A/1/B g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Expect('pagevar', 'g=open filters=Code: A, Date Filter: 01/01/26..12/31/26 code=A');
        Observer.Verify();
    end;

    [Test]
    procedure FindNext_Trap_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        TP: TestPage "CPO WS FindNext";
        Cap: Text;
    begin
        Seed('Empty', Row);
        TP.Trap();
        Page.Run(Page::"CPO WS FindNext", Row);
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=No//0/ | DC=No//0/ | T0 | T1 cap=CPO FindNext - No//0/ g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Verify();
    end;

    [Test]
    procedure FindNext_Trap_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        TP: TestPage "CPO WS FindNext";
        Cap: Text;
    begin
        Seed('OneRow', Row);
        TP.Trap();
        Page.Run(Page::"CPO WS FindNext", Row);
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=Yes/A/1/B | T0 | T1 cap=CPO FindNext - Yes/A/1/B g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Verify();
    end;

    [Test]
    procedure FindNext_TrapVarRun_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS FindNext";
        TP: TestPage "CPO WS FindNext";
        Cap: Text;
    begin
        Seed('Empty', Row);
        TP.Trap();
        PV.SetTableView(Row);
        PV.Run();
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=No//0/ | DC=No//0/ | T0 | T1 cap=CPO FindNext - No//0/ g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Expect('pagevar', 'g= filters= code=');
        Observer.Verify();
    end;

    [Test]
    procedure FindNext_TrapVarRun_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS FindNext";
        TP: TestPage "CPO WS FindNext";
        Cap: Text;
    begin
        Seed('OneRow', Row);
        TP.Trap();
        PV.SetTableView(Row);
        PV.Run();
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=Yes/A/1/B | T0 | T1 cap=CPO FindNext - Yes/A/1/B g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Expect('pagevar', 'g= filters= code=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HFmtBlob')]
    procedure FmtBlob_Run_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('Empty', Row);
        Page.Run(Page::"CPO WS FmtBlob", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=  | DC=  | H0 | H1 cap=CPO FmtBlob g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HFmtBlob')]
    procedure FmtBlob_Run_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('OneRow', Row);
        Page.Run(Page::"CPO WS FmtBlob", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=* | H0 | H1 cap=CPO FmtBlob - * g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHFmtBlob')]
    procedure FmtBlob_RunModal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('Empty', Row);
        Page.RunModal(Page::"CPO WS FmtBlob", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=  | DC=  | H0 | H1 cap=CPO FmtBlob g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHFmtBlob')]
    procedure FmtBlob_RunModal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('OneRow', Row);
        Page.RunModal(Page::"CPO WS FmtBlob", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=* | H0 | H1 cap=CPO FmtBlob - * g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HFmtBlob')]
    procedure FmtBlob_VarRun_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS FmtBlob";
    begin
        Seed('Empty', Row);
        PV.SetTableView(Row);
        PV.Run();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=  | DC=  | H0 | H1 cap=CPO FmtBlob g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Expect('pagevar', 'g= filters= code=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HFmtBlob')]
    procedure FmtBlob_VarRun_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS FmtBlob";
    begin
        Seed('OneRow', Row);
        PV.SetTableView(Row);
        PV.Run();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=* | H0 | H1 cap=CPO FmtBlob - * g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Expect('pagevar', 'g= filters= code=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHFmtBlob')]
    procedure FmtBlob_VarRunModal_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS FmtBlob";
    begin
        Seed('Empty', Row);
        PV.SetTableView(Row);
        PV.RunModal();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=  | DC=  | H0 | H1 cap=CPO FmtBlob g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Expect('pagevar', 'g=open filters=Code: A, Date Filter: 01/01/26..12/31/26 code=A');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MHFmtBlob')]
    procedure FmtBlob_VarRunModal_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS FmtBlob";
    begin
        Seed('OneRow', Row);
        PV.SetTableView(Row);
        PV.RunModal();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=* | H0 | H1 cap=CPO FmtBlob - * g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Expect('pagevar', 'g=open filters=Code: A, Date Filter: 01/01/26..12/31/26 code=A');
        Observer.Verify();
    end;

    [Test]
    procedure FmtBlob_Trap_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        TP: TestPage "CPO WS FmtBlob";
        Cap: Text;
    begin
        Seed('Empty', Row);
        TP.Trap();
        Page.Run(Page::"CPO WS FmtBlob", Row);
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=  | DC=  | T0 | T1 cap=CPO FmtBlob g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Verify();
    end;

    [Test]
    procedure FmtBlob_Trap_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        TP: TestPage "CPO WS FmtBlob";
        Cap: Text;
    begin
        Seed('OneRow', Row);
        TP.Trap();
        Page.Run(Page::"CPO WS FmtBlob", Row);
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=* | T0 | T1 cap=CPO FmtBlob - * g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Verify();
    end;

    [Test]
    procedure FmtBlob_TrapVarRun_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS FmtBlob";
        TP: TestPage "CPO WS FmtBlob";
        Cap: Text;
    begin
        Seed('Empty', Row);
        TP.Trap();
        PV.SetTableView(Row);
        PV.Run();
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=  | DC=  | T0 | T1 cap=CPO FmtBlob g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Expect('pagevar', 'g= filters= code=');
        Observer.Verify();
    end;

    [Test]
    procedure FmtBlob_TrapVarRun_OneRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        PV: Page "CPO WS FmtBlob";
        TP: TestPage "CPO WS FmtBlob";
        Cap: Text;
    begin
        Seed('OneRow', Row);
        TP.Trap();
        PV.SetTableView(Row);
        PV.Run();
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Observe('pagevar', PV.State());
        Observer.Expect('log', 'OnOpenPage | DC=* | T0 | T1 cap=CPO FmtBlob - * g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Expect('pagevar', 'g= filters= code=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HFmtBlob')]
    procedure FmtBlob_Run_OneRowBlobEmpty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('OneRowBlobEmpty', Row);
        Page.Run(Page::"CPO WS FmtBlob", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=  | H0 | H1 cap=CPO FmtBlob g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Verify();
    end;

    [Test]
    procedure FmtBlob_Trap_OneRowBlobEmpty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
        TP: TestPage "CPO WS FmtBlob";
        Cap: Text;
    begin
        Seed('OneRowBlobEmpty', Row);
        TP.Trap();
        Page.Run(Page::"CPO WS FmtBlob", Row);
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' g=' + TP.GlobalCtl.Value + ' code=' + TP.CodeCtl.Value + ' name=' + TP.NameCtl.Value);
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('log', 'OnOpenPage | DC=  | T0 | T1 cap=CPO FmtBlob g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HLit')]
    procedure Lit_Run_Empty_InAsserterror()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('Empty', Row);
        Commit();
        asserterror OpenLitRun(Row);
        Observer.ObserveError('open');
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('open|text', 'no error at the open');
        Observer.Expect('open|code', 'Dialog');
        Observer.Expect('log', 'OnOpenPage | DC=Cap  | DC=Cap  | H0 | H1 cap=CPO Lit - Cap g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HLit')]
    procedure Lit_Run_OneRow_InAsserterror()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('OneRow', Row);
        Commit();
        asserterror OpenLitRun(Row);
        Observer.ObserveError('open');
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('open|text', 'no error at the open');
        Observer.Expect('open|code', 'Dialog');
        Observer.Expect('log', 'OnOpenPage | DC=Cap Alpha | H0 | H1 cap=CPO Lit - Cap Alpha g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HFmtBlob')]
    procedure FmtBlob_Run_Empty_InAsserterror()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('Empty', Row);
        Commit();
        asserterror OpenFmtBlobRun(Row);
        Observer.ObserveError('open');
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('open|text', 'no error at the open');
        Observer.Expect('open|code', 'Dialog');
        Observer.Expect('log', 'OnOpenPage | DC=  | DC=  | H0 | H1 cap=CPO FmtBlob g=open code=A name= | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HFmtBlob')]
    procedure FmtBlob_Run_OneRow_InAsserterror()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "CPO Row";
    begin
        Seed('OneRow', Row);
        Commit();
        asserterror OpenFmtBlobRun(Row);
        Observer.ObserveError('open');
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Expect('open|text', 'no error at the open');
        Observer.Expect('open|code', 'Dialog');
        Observer.Expect('log', 'OnOpenPage | DC=* | H0 | H1 cap=CPO FmtBlob - * g=open code=A name=Alpha | after open');
        Observer.Expect('rec', 'filters=Code: A, Date Filter: 01/01/26..12/31/26 code=');
        Observer.Expect('store', '2');
        Observer.Verify();
    end;

    local procedure OpenLitRun(var Row: Record "CPO Row")
    begin
        Page.Run(Page::"CPO WS Lit", Row);
        Error('no error at the open');
    end;

    local procedure OpenFmtBlobRun(var Row: Record "CPO Row")
    begin
        Page.Run(Page::"CPO WS FmtBlob", Row);
        Error('no error at the open');
    end;

    [PageHandler]
    procedure HLit(var P: TestPage "CPO WS Lit")
    var
        Cap: Text;
    begin
        Log.Add('H0');
        Cap := P.Caption();
        Log.Add('H1 cap=' + Cap + ' g=' + P.GlobalCtl.Value + ' code=' + P.CodeCtl.Value + ' name=' + P.NameCtl.Value);
    end;

    [ModalPageHandler]
    procedure MHLit(var P: TestPage "CPO WS Lit")
    var
        Cap: Text;
    begin
        Log.Add('H0');
        Cap := P.Caption();
        Log.Add('H1 cap=' + Cap + ' g=' + P.GlobalCtl.Value + ' code=' + P.CodeCtl.Value + ' name=' + P.NameCtl.Value);
    end;

    [PageHandler]
    procedure HFmtOption(var P: TestPage "CPO WS FmtOption")
    var
        Cap: Text;
    begin
        Log.Add('H0');
        Cap := P.Caption();
        Log.Add('H1 cap=' + Cap + ' g=' + P.GlobalCtl.Value + ' code=' + P.CodeCtl.Value + ' name=' + P.NameCtl.Value);
    end;

    [ModalPageHandler]
    procedure MHFmtOption(var P: TestPage "CPO WS FmtOption")
    var
        Cap: Text;
    begin
        Log.Add('H0');
        Cap := P.Caption();
        Log.Add('H1 cap=' + Cap + ' g=' + P.GlobalCtl.Value + ' code=' + P.CodeCtl.Value + ' name=' + P.NameCtl.Value);
    end;

    [PageHandler]
    procedure HFmtDecimal(var P: TestPage "CPO WS FmtDecimal")
    var
        Cap: Text;
    begin
        Log.Add('H0');
        Cap := P.Caption();
        Log.Add('H1 cap=' + Cap + ' g=' + P.GlobalCtl.Value + ' code=' + P.CodeCtl.Value + ' name=' + P.NameCtl.Value);
    end;

    [ModalPageHandler]
    procedure MHFmtDecimal(var P: TestPage "CPO WS FmtDecimal")
    var
        Cap: Text;
    begin
        Log.Add('H0');
        Cap := P.Caption();
        Log.Add('H1 cap=' + Cap + ' g=' + P.GlobalCtl.Value + ' code=' + P.CodeCtl.Value + ' name=' + P.NameCtl.Value);
    end;

    [PageHandler]
    procedure HFmtDate(var P: TestPage "CPO WS FmtDate")
    var
        Cap: Text;
    begin
        Log.Add('H0');
        Cap := P.Caption();
        Log.Add('H1 cap=' + Cap + ' g=' + P.GlobalCtl.Value + ' code=' + P.CodeCtl.Value + ' name=' + P.NameCtl.Value);
    end;

    [ModalPageHandler]
    procedure MHFmtDate(var P: TestPage "CPO WS FmtDate")
    var
        Cap: Text;
    begin
        Log.Add('H0');
        Cap := P.Caption();
        Log.Add('H1 cap=' + Cap + ' g=' + P.GlobalCtl.Value + ' code=' + P.CodeCtl.Value + ' name=' + P.NameCtl.Value);
    end;

    [PageHandler]
    procedure HSubstLabel(var P: TestPage "CPO WS SubstLabel")
    var
        Cap: Text;
    begin
        Log.Add('H0');
        Cap := P.Caption();
        Log.Add('H1 cap=' + Cap + ' g=' + P.GlobalCtl.Value + ' code=' + P.CodeCtl.Value + ' name=' + P.NameCtl.Value);
    end;

    [ModalPageHandler]
    procedure MHSubstLabel(var P: TestPage "CPO WS SubstLabel")
    var
        Cap: Text;
    begin
        Log.Add('H0');
        Cap := P.Caption();
        Log.Add('H1 cap=' + Cap + ' g=' + P.GlobalCtl.Value + ' code=' + P.CodeCtl.Value + ' name=' + P.NameCtl.Value);
    end;

    [PageHandler]
    procedure HReadProc(var P: TestPage "CPO WS ReadProc")
    var
        Cap: Text;
    begin
        Log.Add('H0');
        Cap := P.Caption();
        Log.Add('H1 cap=' + Cap + ' g=' + P.GlobalCtl.Value + ' code=' + P.CodeCtl.Value + ' name=' + P.NameCtl.Value);
    end;

    [ModalPageHandler]
    procedure MHReadProc(var P: TestPage "CPO WS ReadProc")
    var
        Cap: Text;
    begin
        Log.Add('H0');
        Cap := P.Caption();
        Log.Add('H1 cap=' + Cap + ' g=' + P.GlobalCtl.Value + ' code=' + P.CodeCtl.Value + ' name=' + P.NameCtl.Value);
    end;

    [PageHandler]
    procedure HFlowFilter(var P: TestPage "CPO WS FlowFilter")
    var
        Cap: Text;
    begin
        Log.Add('H0');
        Cap := P.Caption();
        Log.Add('H1 cap=' + Cap + ' g=' + P.GlobalCtl.Value + ' code=' + P.CodeCtl.Value + ' name=' + P.NameCtl.Value);
    end;

    [ModalPageHandler]
    procedure MHFlowFilter(var P: TestPage "CPO WS FlowFilter")
    var
        Cap: Text;
    begin
        Log.Add('H0');
        Cap := P.Caption();
        Log.Add('H1 cap=' + Cap + ' g=' + P.GlobalCtl.Value + ' code=' + P.CodeCtl.Value + ' name=' + P.NameCtl.Value);
    end;

    [PageHandler]
    procedure HNext5(var P: TestPage "CPO WS Next5")
    var
        Cap: Text;
    begin
        Log.Add('H0');
        Cap := P.Caption();
        Log.Add('H1 cap=' + Cap + ' g=' + P.GlobalCtl.Value + ' code=' + P.CodeCtl.Value + ' name=' + P.NameCtl.Value);
    end;

    [ModalPageHandler]
    procedure MHNext5(var P: TestPage "CPO WS Next5")
    var
        Cap: Text;
    begin
        Log.Add('H0');
        Cap := P.Caption();
        Log.Add('H1 cap=' + Cap + ' g=' + P.GlobalCtl.Value + ' code=' + P.CodeCtl.Value + ' name=' + P.NameCtl.Value);
    end;

    [PageHandler]
    procedure HFindNext(var P: TestPage "CPO WS FindNext")
    var
        Cap: Text;
    begin
        Log.Add('H0');
        Cap := P.Caption();
        Log.Add('H1 cap=' + Cap + ' g=' + P.GlobalCtl.Value + ' code=' + P.CodeCtl.Value + ' name=' + P.NameCtl.Value);
    end;

    [ModalPageHandler]
    procedure MHFindNext(var P: TestPage "CPO WS FindNext")
    var
        Cap: Text;
    begin
        Log.Add('H0');
        Cap := P.Caption();
        Log.Add('H1 cap=' + Cap + ' g=' + P.GlobalCtl.Value + ' code=' + P.CodeCtl.Value + ' name=' + P.NameCtl.Value);
    end;

    [PageHandler]
    procedure HFmtBlob(var P: TestPage "CPO WS FmtBlob")
    var
        Cap: Text;
    begin
        Log.Add('H0');
        Cap := P.Caption();
        Log.Add('H1 cap=' + Cap + ' g=' + P.GlobalCtl.Value + ' code=' + P.CodeCtl.Value + ' name=' + P.NameCtl.Value);
    end;

    [ModalPageHandler]
    procedure MHFmtBlob(var P: TestPage "CPO WS FmtBlob")
    var
        Cap: Text;
    begin
        Log.Add('H0');
        Cap := P.Caption();
        Log.Add('H1 cap=' + Cap + ' g=' + P.GlobalCtl.Value + ' code=' + P.CodeCtl.Value + ' name=' + P.NameCtl.Value);
    end;

}
