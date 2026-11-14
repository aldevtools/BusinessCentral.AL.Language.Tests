// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-triggers
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 78920-78924 (TRG Row, TRG Log, TRG WS, TRG WS NoCap, TRG Tests)
// Probe: from al-runner issue 6924 (Worksheet pages with page triggers beyond OnInit, OnOpenPage and OnQueryClosePage). The runner refuses a
//   Worksheet with a DataCaptionExpression that AL code opens through a handler or a Trap when the page has another trigger. This file
//   measures the order of OnInit, OnOpenPage, OnAfterGetRecord, OnAfterGetCurrRecord, OnNewRecord, OnQueryClosePage and OnClosePage on a
//   Worksheet, with (TRG WS) and without (TRG WS NoCap) a DataCaptionExpression (the expression reads Rec.Name and logs DC=<value>), on a view
//   with three rows (A, B, C) and on an empty view, opened by Page.Run with a PageHandler, Page.RunModal with a ModalPageHandler, a TestPage
//   Trap before Page.Run, TestPage.OpenEdit and TestPage.OpenView. The handler, the Trap and the TestPage steps read the caption and the
//   controls, then First() and Next(). The _New tests add TestPage.New() after OpenEdit.
// Log (TRG Log, SingleInstance): every trigger as it runs (INIT, OPEN, AGR <code>, AGC <code>, NEW, QCP <CloseAction>, CLOSE, DC=<value>) and
//   the test's steps (H0..H3 handler, T0..T3 Trap, O0..O3 OpenEdit and OpenView, 'closed').
// What BC did: see the assertions (measured by the pull request's CI run).
// BC versions: 27.5, 28.5, 29.0

table 78920 "TRG Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Name; Text[50]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

page 78922 "TRG WS"
{
    PageType = Worksheet;
    SourceTable = "TRG Row";
    Caption = 'TRG WS';
    DataCaptionExpression = Cap();
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(CodeCtl; Rec."Code") { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    var
        Log: Codeunit "TRG Log";

    local procedure Cap(): Text
    var
        V: Text;
    begin
        V := 'Cap ' + Rec.Name;
        Log.Add('DC=' + V);
        exit(V);
    end;

    trigger OnInit()
    begin
        Log.Add('INIT');
    end;

    trigger OnOpenPage()
    begin
        Log.Add('OPEN');
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('AGR ' + Rec."Code");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('AGC ' + Rec."Code");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('NEW');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log.Add('QCP ' + Format(CloseAction));
        exit(true);
    end;

    trigger OnClosePage()
    begin
        Log.Add('CLOSE');
    end;
}

page 78923 "TRG WS NoCap"
{
    PageType = Worksheet;
    SourceTable = "TRG Row";
    Caption = 'TRG WS NoCap';
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(CodeCtl; Rec."Code") { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    var
        Log: Codeunit "TRG Log";

    trigger OnInit()
    begin
        Log.Add('INIT');
    end;

    trigger OnOpenPage()
    begin
        Log.Add('OPEN');
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('AGR ' + Rec."Code");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('AGC ' + Rec."Code");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('NEW');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log.Add('QCP ' + Format(CloseAction));
        exit(true);
    end;

    trigger OnClosePage()
    begin
        Log.Add('CLOSE');
    end;
}

codeunit 78921 "TRG Log"
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

codeunit 78924 "TRG Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "TRG Log";

    local procedure Seed(View: Text)
    var
        Seeded: Record "TRG Row";
        i: Integer;
    begin
        Seeded.DeleteAll();
        Log.Wipe();
        if View = 'Three' then
            for i := 1 to 3 do begin
                Seeded.Init();
                Seeded."Code" := CopyStr('ABC', i, 1);
                Seeded.Name := 'Row' + CopyStr('ABC', i, 1);
                Seeded.Insert();
            end;
    end;

    local procedure Facts(var Observer: Codeunit "Probe Observer"; var Row: Record "TRG Row")
    var
        Store: Record "TRG Row";
    begin
        Observer.Observe('log', Log.Joined());
        Observer.Observe('rec', 'filters=' + Row.GetFilters + ' code=' + Row."Code");
        Observer.Observe('store', Format(Store.Count()));
    end;

    [Test]
    [HandlerFunctions('HCap')]
    procedure Cap_Three_Run()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "TRG Row";
    begin
        Seed('Three');
        Page.Run(Page::"TRG WS", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('MHCap')]
    procedure Cap_Three_RunModal()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "TRG Row";
    begin
        Seed('Three');
        Page.RunModal(Page::"TRG WS", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Finish();
    end;

    [Test]
    procedure Cap_Three_Trap()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "TRG Row";
        TP: TestPage "TRG WS";
        Cap: Text;
    begin
        Seed('Three');
        TP.Trap();
        Page.Run(Page::"TRG WS", Row);
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' code=' + TP.CodeCtl.Value);
        if TP.First() then
            Log.Add('T2 first=' + TP.CodeCtl.Value)
        else
            Log.Add('T2 first=none');
        if TP.Next() then
            Log.Add('T3 next=' + TP.CodeCtl.Value)
        else
            Log.Add('T3 next=none');
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Finish();
    end;

    [Test]
    procedure Cap_Three_Edit()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "TRG Row";
        TP: TestPage "TRG WS";
        Cap: Text;
    begin
        Seed('Three');
        TP.OpenEdit();
        Log.Add('O0');
        Cap := TP.Caption();
        Log.Add('O1 cap=' + Cap + ' code=' + TP.CodeCtl.Value);
        if TP.First() then
            Log.Add('O2 first=' + TP.CodeCtl.Value)
        else
            Log.Add('O2 first=none');
        if TP.Next() then
            Log.Add('O3 next=' + TP.CodeCtl.Value)
        else
            Log.Add('O3 next=none');
        TP.Close();
        Log.Add('closed');
        Facts(Observer, Row);
        Observer.Finish();
    end;

    [Test]
    procedure Cap_Three_View()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "TRG Row";
        TP: TestPage "TRG WS";
        Cap: Text;
    begin
        Seed('Three');
        TP.OpenView();
        Log.Add('O0');
        Cap := TP.Caption();
        Log.Add('O1 cap=' + Cap + ' code=' + TP.CodeCtl.Value);
        if TP.First() then
            Log.Add('O2 first=' + TP.CodeCtl.Value)
        else
            Log.Add('O2 first=none');
        if TP.Next() then
            Log.Add('O3 next=' + TP.CodeCtl.Value)
        else
            Log.Add('O3 next=none');
        TP.Close();
        Log.Add('closed');
        Facts(Observer, Row);
        Observer.Finish();
    end;

    [Test]
    procedure Cap_Three_EditNew()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "TRG Row";
        TP: TestPage "TRG WS";
    begin
        Seed('Three');
        TP.OpenEdit();
        Log.Add('O0');
        TP.New();
        Log.Add('O1 code=' + TP.CodeCtl.Value);
        TP.Close();
        Log.Add('closed');
        Facts(Observer, Row);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HCap')]
    procedure Cap_Empty_Run()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "TRG Row";
    begin
        Seed('Empty');
        Page.Run(Page::"TRG WS", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('MHCap')]
    procedure Cap_Empty_RunModal()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "TRG Row";
    begin
        Seed('Empty');
        Page.RunModal(Page::"TRG WS", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Finish();
    end;

    [Test]
    procedure Cap_Empty_Trap()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "TRG Row";
        TP: TestPage "TRG WS";
        Cap: Text;
    begin
        Seed('Empty');
        TP.Trap();
        Page.Run(Page::"TRG WS", Row);
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' code=' + TP.CodeCtl.Value);
        if TP.First() then
            Log.Add('T2 first=' + TP.CodeCtl.Value)
        else
            Log.Add('T2 first=none');
        if TP.Next() then
            Log.Add('T3 next=' + TP.CodeCtl.Value)
        else
            Log.Add('T3 next=none');
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Finish();
    end;

    [Test]
    procedure Cap_Empty_Edit()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "TRG Row";
        TP: TestPage "TRG WS";
        Cap: Text;
    begin
        Seed('Empty');
        TP.OpenEdit();
        Log.Add('O0');
        Cap := TP.Caption();
        Log.Add('O1 cap=' + Cap + ' code=' + TP.CodeCtl.Value);
        if TP.First() then
            Log.Add('O2 first=' + TP.CodeCtl.Value)
        else
            Log.Add('O2 first=none');
        if TP.Next() then
            Log.Add('O3 next=' + TP.CodeCtl.Value)
        else
            Log.Add('O3 next=none');
        TP.Close();
        Log.Add('closed');
        Facts(Observer, Row);
        Observer.Finish();
    end;

    [Test]
    procedure Cap_Empty_View()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "TRG Row";
        TP: TestPage "TRG WS";
        Cap: Text;
    begin
        Seed('Empty');
        TP.OpenView();
        Log.Add('O0');
        Cap := TP.Caption();
        Log.Add('O1 cap=' + Cap + ' code=' + TP.CodeCtl.Value);
        if TP.First() then
            Log.Add('O2 first=' + TP.CodeCtl.Value)
        else
            Log.Add('O2 first=none');
        if TP.Next() then
            Log.Add('O3 next=' + TP.CodeCtl.Value)
        else
            Log.Add('O3 next=none');
        TP.Close();
        Log.Add('closed');
        Facts(Observer, Row);
        Observer.Finish();
    end;

    [Test]
    procedure Cap_Empty_EditNew()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "TRG Row";
        TP: TestPage "TRG WS";
    begin
        Seed('Empty');
        TP.OpenEdit();
        Log.Add('O0');
        TP.New();
        Log.Add('O1 code=' + TP.CodeCtl.Value);
        TP.Close();
        Log.Add('closed');
        Facts(Observer, Row);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HNoCap')]
    procedure NoCap_Three_Run()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "TRG Row";
    begin
        Seed('Three');
        Page.Run(Page::"TRG WS NoCap", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('MHNoCap')]
    procedure NoCap_Three_RunModal()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "TRG Row";
    begin
        Seed('Three');
        Page.RunModal(Page::"TRG WS NoCap", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Finish();
    end;

    [Test]
    procedure NoCap_Three_Trap()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "TRG Row";
        TP: TestPage "TRG WS NoCap";
        Cap: Text;
    begin
        Seed('Three');
        TP.Trap();
        Page.Run(Page::"TRG WS NoCap", Row);
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' code=' + TP.CodeCtl.Value);
        if TP.First() then
            Log.Add('T2 first=' + TP.CodeCtl.Value)
        else
            Log.Add('T2 first=none');
        if TP.Next() then
            Log.Add('T3 next=' + TP.CodeCtl.Value)
        else
            Log.Add('T3 next=none');
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Finish();
    end;

    [Test]
    procedure NoCap_Three_Edit()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "TRG Row";
        TP: TestPage "TRG WS NoCap";
        Cap: Text;
    begin
        Seed('Three');
        TP.OpenEdit();
        Log.Add('O0');
        Cap := TP.Caption();
        Log.Add('O1 cap=' + Cap + ' code=' + TP.CodeCtl.Value);
        if TP.First() then
            Log.Add('O2 first=' + TP.CodeCtl.Value)
        else
            Log.Add('O2 first=none');
        if TP.Next() then
            Log.Add('O3 next=' + TP.CodeCtl.Value)
        else
            Log.Add('O3 next=none');
        TP.Close();
        Log.Add('closed');
        Facts(Observer, Row);
        Observer.Finish();
    end;

    [Test]
    procedure NoCap_Three_View()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "TRG Row";
        TP: TestPage "TRG WS NoCap";
        Cap: Text;
    begin
        Seed('Three');
        TP.OpenView();
        Log.Add('O0');
        Cap := TP.Caption();
        Log.Add('O1 cap=' + Cap + ' code=' + TP.CodeCtl.Value);
        if TP.First() then
            Log.Add('O2 first=' + TP.CodeCtl.Value)
        else
            Log.Add('O2 first=none');
        if TP.Next() then
            Log.Add('O3 next=' + TP.CodeCtl.Value)
        else
            Log.Add('O3 next=none');
        TP.Close();
        Log.Add('closed');
        Facts(Observer, Row);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HNoCap')]
    procedure NoCap_Empty_Run()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "TRG Row";
    begin
        Seed('Empty');
        Page.Run(Page::"TRG WS NoCap", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('MHNoCap')]
    procedure NoCap_Empty_RunModal()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "TRG Row";
    begin
        Seed('Empty');
        Page.RunModal(Page::"TRG WS NoCap", Row);
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Finish();
    end;

    [Test]
    procedure NoCap_Empty_Trap()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "TRG Row";
        TP: TestPage "TRG WS NoCap";
        Cap: Text;
    begin
        Seed('Empty');
        TP.Trap();
        Page.Run(Page::"TRG WS NoCap", Row);
        Log.Add('T0');
        Cap := TP.Caption();
        Log.Add('T1 cap=' + Cap + ' code=' + TP.CodeCtl.Value);
        if TP.First() then
            Log.Add('T2 first=' + TP.CodeCtl.Value)
        else
            Log.Add('T2 first=none');
        if TP.Next() then
            Log.Add('T3 next=' + TP.CodeCtl.Value)
        else
            Log.Add('T3 next=none');
        TP.Close();
        Log.Add('after open');
        Facts(Observer, Row);
        Observer.Finish();
    end;

    [Test]
    procedure NoCap_Empty_Edit()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "TRG Row";
        TP: TestPage "TRG WS NoCap";
        Cap: Text;
    begin
        Seed('Empty');
        TP.OpenEdit();
        Log.Add('O0');
        Cap := TP.Caption();
        Log.Add('O1 cap=' + Cap + ' code=' + TP.CodeCtl.Value);
        if TP.First() then
            Log.Add('O2 first=' + TP.CodeCtl.Value)
        else
            Log.Add('O2 first=none');
        if TP.Next() then
            Log.Add('O3 next=' + TP.CodeCtl.Value)
        else
            Log.Add('O3 next=none');
        TP.Close();
        Log.Add('closed');
        Facts(Observer, Row);
        Observer.Finish();
    end;

    [Test]
    procedure NoCap_Empty_View()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "TRG Row";
        TP: TestPage "TRG WS NoCap";
        Cap: Text;
    begin
        Seed('Empty');
        TP.OpenView();
        Log.Add('O0');
        Cap := TP.Caption();
        Log.Add('O1 cap=' + Cap + ' code=' + TP.CodeCtl.Value);
        if TP.First() then
            Log.Add('O2 first=' + TP.CodeCtl.Value)
        else
            Log.Add('O2 first=none');
        if TP.Next() then
            Log.Add('O3 next=' + TP.CodeCtl.Value)
        else
            Log.Add('O3 next=none');
        TP.Close();
        Log.Add('closed');
        Facts(Observer, Row);
        Observer.Finish();
    end;

    [PageHandler]
    procedure HCap(var P: TestPage "TRG WS")
    var
        Cap: Text;
    begin
        Log.Add('H0');
        Cap := P.Caption();
        Log.Add('H1 cap=' + Cap + ' code=' + P.CodeCtl.Value);
        if P.First() then
            Log.Add('H2 first=' + P.CodeCtl.Value)
        else
            Log.Add('H2 first=none');
        if P.Next() then
            Log.Add('H3 next=' + P.CodeCtl.Value)
        else
            Log.Add('H3 next=none');
    end;

    [ModalPageHandler]
    procedure MHCap(var P: TestPage "TRG WS")
    var
        Cap: Text;
    begin
        Log.Add('H0');
        Cap := P.Caption();
        Log.Add('H1 cap=' + Cap + ' code=' + P.CodeCtl.Value);
        if P.First() then
            Log.Add('H2 first=' + P.CodeCtl.Value)
        else
            Log.Add('H2 first=none');
        if P.Next() then
            Log.Add('H3 next=' + P.CodeCtl.Value)
        else
            Log.Add('H3 next=none');
    end;

    [PageHandler]
    procedure HNoCap(var P: TestPage "TRG WS NoCap")
    var
        Cap: Text;
    begin
        Log.Add('H0');
        Cap := P.Caption();
        Log.Add('H1 cap=' + Cap + ' code=' + P.CodeCtl.Value);
        if P.First() then
            Log.Add('H2 first=' + P.CodeCtl.Value)
        else
            Log.Add('H2 first=none');
        if P.Next() then
            Log.Add('H3 next=' + P.CodeCtl.Value)
        else
            Log.Add('H3 next=none');
    end;

    [ModalPageHandler]
    procedure MHNoCap(var P: TestPage "TRG WS NoCap")
    var
        Cap: Text;
    begin
        Log.Add('H0');
        Cap := P.Caption();
        Log.Add('H1 cap=' + Cap + ' code=' + P.CodeCtl.Value);
        if P.First() then
            Log.Add('H2 first=' + P.CodeCtl.Value)
        else
            Log.Add('H2 first=none');
        if P.Next() then
            Log.Add('H3 next=' + P.CodeCtl.Value)
        else
            Log.Add('H3 next=none');
    end;
}
