// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfilter/testfilter-setfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); WEQ Row (table 76410), WEQ Temp Worksheet (page 76411) from WorksheetEnumEqFilter.al; own
//   objects 78900-78903 (WOE Temp WS Act, WOE Temp WS Open, WOE Temp WS Shown, WOE Tests)
// Probe: from al-runner issue 6924 (an outside reporter's search Worksheet over a temporary table, opened with OpenEdit; an action fills the
//   rows; the test filters a Boolean field with '=0' and '=1', then walks the rows). WorksheetEnumEqFilter.al measured OpenView only; this
//   file measures OpenEdit and OpenView on four Worksheets over the temporary table WEQ Row (rows 1 Quote No, 2 Order No, 3 Invoice Yes,
//   4 Order Yes):
//   - WEQ Temp Worksheet: Editable = false, action Fill, IsHist without a control (the existing page);
//   - WOE Temp WS Act: editable, action Fill, IsHist without a control;
//   - WOE Temp WS Shown: editable, action Fill, IsHist with a control;
//   - WOE Temp WS Open: editable, fills the rows in OnOpenPage, no action.
// Area: TestPage.Filter.SetFilter(IsHist, text) then GetFilter and a walk with First()/Next() (id:name per row, 'none' when First() is false).
//   AfterFill: Fill, then '=0', '=1', '0', '1'. BeforeFill: the filter first ('=0', '=1'), then Fill. GoToKey: Fill, filter, then GoToKey(3)
//   and GoToKey(1) ('=1' and '=0'), each followed by the current Id.
// local object: the page shapes (Worksheet, SourceTableTemporary, a Boolean field with or without a control) are what the test checks.
// What BC did: see the assertions (measured by the pull request's CI run).
// BC versions: 27.5, 28.5, 29.0

page 78900 "WOE Temp WS Act"
{
    PageType = Worksheet;
    SourceTable = "WEQ Row";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'WOE Temp WS Act';

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(DocTypeCtl; Rec.DocType) { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Fill)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.FourRows();
                    if Rec.FindFirst() then;
                    CurrPage.Update(false);
                end;
            }
        }
    }
}

page 78901 "WOE Temp WS Open"
{
    PageType = Worksheet;
    SourceTable = "WEQ Row";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'WOE Temp WS Open';

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(DocTypeCtl; Rec.DocType) { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.FourRows();
        if Rec.FindFirst() then;
    end;
}

page 78902 "WOE Temp WS Shown"
{
    PageType = Worksheet;
    SourceTable = "WEQ Row";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'WOE Temp WS Shown';

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(IsHistCtl; Rec.IsHist) { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Fill)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.FourRows();
                    if Rec.FindFirst() then;
                    CurrPage.Update(false);
                end;
            }
        }
    }
}

codeunit 78903 "WOE Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Initialize()
    var
        Row: Record "WEQ Row";
    begin
        Row.DeleteAll();
        ClearLastError();
    end;

    local procedure WalkEq(var P: TestPage "WEQ Temp Worksheet"): Text
    var
        Rows: Text;
    begin
        if not P.First() then
            exit('none');
        repeat
            Rows += P.IdCtl.Value() + ':' + P.NameCtl.Value() + ',';
        until not P.Next();
        exit(Rows);
    end;

    [TryFunction]
    local procedure SetFEq(var P: TestPage "WEQ Temp Worksheet"; FilterText: Text)
    begin
        P.Filter.SetFilter(IsHist, FilterText);
    end;

    [TryFunction]
    local procedure GoKeyEq(var P: TestPage "WEQ Temp Worksheet"; KeyValue: Integer)
    begin
        P.GoToKey(KeyValue);
    end;

    local procedure Err(): Text
    begin
        exit('error=' + GetLastErrorCode() + ':' + GetLastErrorText());
    end;

    local procedure AfterEq(Mode: Text; FilterText: Text): Text
    var
        P: TestPage "WEQ Temp Worksheet";
        Result: Text;
    begin
        if Mode = 'Edit' then
            P.OpenEdit()
        else
            P.OpenView();
        P.Fill.Invoke();
        ClearLastError();
        if SetFEq(P, FilterText) then
            Result := 'filter=' + P.Filter.GetFilter(IsHist) + ' rows=' + WalkEq(P)
        else
            Result := Err();
        P.Close();
        exit(Result);
    end;

    local procedure BeforeEq(Mode: Text; FilterText: Text): Text
    var
        P: TestPage "WEQ Temp Worksheet";
        Result: Text;
    begin
        if Mode = 'Edit' then
            P.OpenEdit()
        else
            P.OpenView();
        ClearLastError();
        if not SetFEq(P, FilterText) then begin
            Result := Err();
            P.Close();
            exit(Result);
        end;
        P.Fill.Invoke();
        Result := 'filter=' + P.Filter.GetFilter(IsHist) + ' rows=' + WalkEq(P);
        P.Close();
        exit(Result);
    end;

    local procedure GoToEq(Mode: Text; FilterText: Text; KeyValue: Integer): Text
    var
        P: TestPage "WEQ Temp Worksheet";
        Result: Text;
    begin
        if Mode = 'Edit' then
            P.OpenEdit()
        else
            P.OpenView();
        P.Fill.Invoke();
        ClearLastError();
        if not SetFEq(P, FilterText) then begin
            Result := Err();
            P.Close();
            exit(Result);
        end;
        Result := 'filter=' + P.Filter.GetFilter(IsHist);
        ClearLastError();
        if GoKeyEq(P, KeyValue) then
            Result += ' goto=ok cur=' + P.IdCtl.Value()
        else
            Result += ' goto=' + Err();
        Result += ' rows=' + WalkEq(P);
        P.Close();
        exit(Result);
    end;

    local procedure WalkAct(var P: TestPage "WOE Temp WS Act"): Text
    var
        Rows: Text;
    begin
        if not P.First() then
            exit('none');
        repeat
            Rows += P.IdCtl.Value() + ':' + P.NameCtl.Value() + ',';
        until not P.Next();
        exit(Rows);
    end;

    [TryFunction]
    local procedure SetFAct(var P: TestPage "WOE Temp WS Act"; FilterText: Text)
    begin
        P.Filter.SetFilter(IsHist, FilterText);
    end;

    [TryFunction]
    local procedure GoKeyAct(var P: TestPage "WOE Temp WS Act"; KeyValue: Integer)
    begin
        P.GoToKey(KeyValue);
    end;

    local procedure Err(): Text
    begin
        exit('error=' + GetLastErrorCode() + ':' + GetLastErrorText());
    end;

    local procedure AfterAct(Mode: Text; FilterText: Text): Text
    var
        P: TestPage "WOE Temp WS Act";
        Result: Text;
    begin
        if Mode = 'Edit' then
            P.OpenEdit()
        else
            P.OpenView();
        P.Fill.Invoke();
        ClearLastError();
        if SetFAct(P, FilterText) then
            Result := 'filter=' + P.Filter.GetFilter(IsHist) + ' rows=' + WalkAct(P)
        else
            Result := Err();
        P.Close();
        exit(Result);
    end;

    local procedure BeforeAct(Mode: Text; FilterText: Text): Text
    var
        P: TestPage "WOE Temp WS Act";
        Result: Text;
    begin
        if Mode = 'Edit' then
            P.OpenEdit()
        else
            P.OpenView();
        ClearLastError();
        if not SetFAct(P, FilterText) then begin
            Result := Err();
            P.Close();
            exit(Result);
        end;
        P.Fill.Invoke();
        Result := 'filter=' + P.Filter.GetFilter(IsHist) + ' rows=' + WalkAct(P);
        P.Close();
        exit(Result);
    end;

    local procedure GoToAct(Mode: Text; FilterText: Text; KeyValue: Integer): Text
    var
        P: TestPage "WOE Temp WS Act";
        Result: Text;
    begin
        if Mode = 'Edit' then
            P.OpenEdit()
        else
            P.OpenView();
        P.Fill.Invoke();
        ClearLastError();
        if not SetFAct(P, FilterText) then begin
            Result := Err();
            P.Close();
            exit(Result);
        end;
        Result := 'filter=' + P.Filter.GetFilter(IsHist);
        ClearLastError();
        if GoKeyAct(P, KeyValue) then
            Result += ' goto=ok cur=' + P.IdCtl.Value()
        else
            Result += ' goto=' + Err();
        Result += ' rows=' + WalkAct(P);
        P.Close();
        exit(Result);
    end;

    local procedure WalkShown(var P: TestPage "WOE Temp WS Shown"): Text
    var
        Rows: Text;
    begin
        if not P.First() then
            exit('none');
        repeat
            Rows += P.IdCtl.Value() + ':' + P.NameCtl.Value() + ',';
        until not P.Next();
        exit(Rows);
    end;

    [TryFunction]
    local procedure SetFShown(var P: TestPage "WOE Temp WS Shown"; FilterText: Text)
    begin
        P.Filter.SetFilter(IsHist, FilterText);
    end;

    [TryFunction]
    local procedure GoKeyShown(var P: TestPage "WOE Temp WS Shown"; KeyValue: Integer)
    begin
        P.GoToKey(KeyValue);
    end;

    local procedure Err(): Text
    begin
        exit('error=' + GetLastErrorCode() + ':' + GetLastErrorText());
    end;

    local procedure AfterShown(Mode: Text; FilterText: Text): Text
    var
        P: TestPage "WOE Temp WS Shown";
        Result: Text;
    begin
        if Mode = 'Edit' then
            P.OpenEdit()
        else
            P.OpenView();
        P.Fill.Invoke();
        ClearLastError();
        if SetFShown(P, FilterText) then
            Result := 'filter=' + P.Filter.GetFilter(IsHist) + ' rows=' + WalkShown(P)
        else
            Result := Err();
        P.Close();
        exit(Result);
    end;

    local procedure BeforeShown(Mode: Text; FilterText: Text): Text
    var
        P: TestPage "WOE Temp WS Shown";
        Result: Text;
    begin
        if Mode = 'Edit' then
            P.OpenEdit()
        else
            P.OpenView();
        ClearLastError();
        if not SetFShown(P, FilterText) then begin
            Result := Err();
            P.Close();
            exit(Result);
        end;
        P.Fill.Invoke();
        Result := 'filter=' + P.Filter.GetFilter(IsHist) + ' rows=' + WalkShown(P);
        P.Close();
        exit(Result);
    end;

    local procedure GoToShown(Mode: Text; FilterText: Text; KeyValue: Integer): Text
    var
        P: TestPage "WOE Temp WS Shown";
        Result: Text;
    begin
        if Mode = 'Edit' then
            P.OpenEdit()
        else
            P.OpenView();
        P.Fill.Invoke();
        ClearLastError();
        if not SetFShown(P, FilterText) then begin
            Result := Err();
            P.Close();
            exit(Result);
        end;
        Result := 'filter=' + P.Filter.GetFilter(IsHist);
        ClearLastError();
        if GoKeyShown(P, KeyValue) then
            Result += ' goto=ok cur=' + P.IdCtl.Value()
        else
            Result += ' goto=' + Err();
        Result += ' rows=' + WalkShown(P);
        P.Close();
        exit(Result);
    end;

    local procedure WalkOpen(var P: TestPage "WOE Temp WS Open"): Text
    var
        Rows: Text;
    begin
        if not P.First() then
            exit('none');
        repeat
            Rows += P.IdCtl.Value() + ':' + P.NameCtl.Value() + ',';
        until not P.Next();
        exit(Rows);
    end;

    [TryFunction]
    local procedure SetFOpen(var P: TestPage "WOE Temp WS Open"; FilterText: Text)
    begin
        P.Filter.SetFilter(IsHist, FilterText);
    end;

    [TryFunction]
    local procedure GoKeyOpen(var P: TestPage "WOE Temp WS Open"; KeyValue: Integer)
    begin
        P.GoToKey(KeyValue);
    end;

    local procedure Err(): Text
    begin
        exit('error=' + GetLastErrorCode() + ':' + GetLastErrorText());
    end;

    local procedure AfterOpen(Mode: Text; FilterText: Text): Text
    var
        P: TestPage "WOE Temp WS Open";
        Result: Text;
    begin
        if Mode = 'Edit' then
            P.OpenEdit()
        else
            P.OpenView();

        ClearLastError();
        if SetFOpen(P, FilterText) then
            Result := 'filter=' + P.Filter.GetFilter(IsHist) + ' rows=' + WalkOpen(P)
        else
            Result := Err();
        P.Close();
        exit(Result);
    end;

    local procedure GoToOpen(Mode: Text; FilterText: Text; KeyValue: Integer): Text
    var
        P: TestPage "WOE Temp WS Open";
        Result: Text;
    begin
        if Mode = 'Edit' then
            P.OpenEdit()
        else
            P.OpenView();

        ClearLastError();
        if not SetFOpen(P, FilterText) then begin
            Result := Err();
            P.Close();
            exit(Result);
        end;
        Result := 'filter=' + P.Filter.GetFilter(IsHist);
        ClearLastError();
        if GoKeyOpen(P, KeyValue) then
            Result += ' goto=ok cur=' + P.IdCtl.Value()
        else
            Result += ' goto=' + Err();
        Result += ' rows=' + WalkOpen(P);
        P.Close();
        exit(Result);
    end;


    [Test]
    procedure AfterFill_Eq_OpenEdit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('after|=0', AfterEq('Edit', '=0'));
        Observer.Observe('after|=1', AfterEq('Edit', '=1'));
        Observer.Observe('after|0', AfterEq('Edit', '0'));
        Observer.Observe('after|1', AfterEq('Edit', '1'));
        Observer.Finish();
    end;

    [Test]
    procedure BeforeFill_Eq_OpenEdit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('before|=0', BeforeEq('Edit', '=0'));
        Observer.Observe('before|=1', BeforeEq('Edit', '=1'));
        Observer.Finish();
    end;

    [Test]
    procedure GoToKey_Eq_OpenEdit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('goto|=1|3', GoToEq('Edit', '=1', 3));
        Observer.Observe('goto|=1|1', GoToEq('Edit', '=1', 1));
        Observer.Observe('goto|=0|1', GoToEq('Edit', '=0', 1));
        Observer.Observe('goto|=0|3', GoToEq('Edit', '=0', 3));
        Observer.Finish();
    end;

    [Test]
    procedure AfterFill_Eq_OpenView()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('after|=0', AfterEq('View', '=0'));
        Observer.Observe('after|=1', AfterEq('View', '=1'));
        Observer.Observe('after|0', AfterEq('View', '0'));
        Observer.Observe('after|1', AfterEq('View', '1'));
        Observer.Finish();
    end;

    [Test]
    procedure BeforeFill_Eq_OpenView()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('before|=0', BeforeEq('View', '=0'));
        Observer.Observe('before|=1', BeforeEq('View', '=1'));
        Observer.Finish();
    end;

    [Test]
    procedure GoToKey_Eq_OpenView()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('goto|=1|3', GoToEq('View', '=1', 3));
        Observer.Observe('goto|=1|1', GoToEq('View', '=1', 1));
        Observer.Observe('goto|=0|1', GoToEq('View', '=0', 1));
        Observer.Observe('goto|=0|3', GoToEq('View', '=0', 3));
        Observer.Finish();
    end;

    [Test]
    procedure AfterFill_Act_OpenEdit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('after|=0', AfterAct('Edit', '=0'));
        Observer.Observe('after|=1', AfterAct('Edit', '=1'));
        Observer.Observe('after|0', AfterAct('Edit', '0'));
        Observer.Observe('after|1', AfterAct('Edit', '1'));
        Observer.Finish();
    end;

    [Test]
    procedure BeforeFill_Act_OpenEdit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('before|=0', BeforeAct('Edit', '=0'));
        Observer.Observe('before|=1', BeforeAct('Edit', '=1'));
        Observer.Finish();
    end;

    [Test]
    procedure GoToKey_Act_OpenEdit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('goto|=1|3', GoToAct('Edit', '=1', 3));
        Observer.Observe('goto|=1|1', GoToAct('Edit', '=1', 1));
        Observer.Observe('goto|=0|1', GoToAct('Edit', '=0', 1));
        Observer.Observe('goto|=0|3', GoToAct('Edit', '=0', 3));
        Observer.Finish();
    end;

    [Test]
    procedure AfterFill_Act_OpenView()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('after|=0', AfterAct('View', '=0'));
        Observer.Observe('after|=1', AfterAct('View', '=1'));
        Observer.Observe('after|0', AfterAct('View', '0'));
        Observer.Observe('after|1', AfterAct('View', '1'));
        Observer.Finish();
    end;

    [Test]
    procedure BeforeFill_Act_OpenView()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('before|=0', BeforeAct('View', '=0'));
        Observer.Observe('before|=1', BeforeAct('View', '=1'));
        Observer.Finish();
    end;

    [Test]
    procedure GoToKey_Act_OpenView()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('goto|=1|3', GoToAct('View', '=1', 3));
        Observer.Observe('goto|=1|1', GoToAct('View', '=1', 1));
        Observer.Observe('goto|=0|1', GoToAct('View', '=0', 1));
        Observer.Observe('goto|=0|3', GoToAct('View', '=0', 3));
        Observer.Finish();
    end;

    [Test]
    procedure AfterFill_Shown_OpenEdit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('after|=0', AfterShown('Edit', '=0'));
        Observer.Observe('after|=1', AfterShown('Edit', '=1'));
        Observer.Observe('after|0', AfterShown('Edit', '0'));
        Observer.Observe('after|1', AfterShown('Edit', '1'));
        Observer.Finish();
    end;

    [Test]
    procedure BeforeFill_Shown_OpenEdit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('before|=0', BeforeShown('Edit', '=0'));
        Observer.Observe('before|=1', BeforeShown('Edit', '=1'));
        Observer.Finish();
    end;

    [Test]
    procedure GoToKey_Shown_OpenEdit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('goto|=1|3', GoToShown('Edit', '=1', 3));
        Observer.Observe('goto|=1|1', GoToShown('Edit', '=1', 1));
        Observer.Observe('goto|=0|1', GoToShown('Edit', '=0', 1));
        Observer.Observe('goto|=0|3', GoToShown('Edit', '=0', 3));
        Observer.Finish();
    end;

    [Test]
    procedure AfterFill_Shown_OpenView()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('after|=0', AfterShown('View', '=0'));
        Observer.Observe('after|=1', AfterShown('View', '=1'));
        Observer.Observe('after|0', AfterShown('View', '0'));
        Observer.Observe('after|1', AfterShown('View', '1'));
        Observer.Finish();
    end;

    [Test]
    procedure BeforeFill_Shown_OpenView()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('before|=0', BeforeShown('View', '=0'));
        Observer.Observe('before|=1', BeforeShown('View', '=1'));
        Observer.Finish();
    end;

    [Test]
    procedure GoToKey_Shown_OpenView()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('goto|=1|3', GoToShown('View', '=1', 3));
        Observer.Observe('goto|=1|1', GoToShown('View', '=1', 1));
        Observer.Observe('goto|=0|1', GoToShown('View', '=0', 1));
        Observer.Observe('goto|=0|3', GoToShown('View', '=0', 3));
        Observer.Finish();
    end;

    [Test]
    procedure AfterFill_Open_OpenEdit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('after|=0', AfterOpen('Edit', '=0'));
        Observer.Observe('after|=1', AfterOpen('Edit', '=1'));
        Observer.Observe('after|0', AfterOpen('Edit', '0'));
        Observer.Observe('after|1', AfterOpen('Edit', '1'));
        Observer.Finish();
    end;

    [Test]
    procedure GoToKey_Open_OpenEdit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('goto|=1|3', GoToOpen('Edit', '=1', 3));
        Observer.Observe('goto|=1|1', GoToOpen('Edit', '=1', 1));
        Observer.Observe('goto|=0|1', GoToOpen('Edit', '=0', 1));
        Observer.Observe('goto|=0|3', GoToOpen('Edit', '=0', 3));
        Observer.Finish();
    end;

    [Test]
    procedure AfterFill_Open_OpenView()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('after|=0', AfterOpen('View', '=0'));
        Observer.Observe('after|=1', AfterOpen('View', '=1'));
        Observer.Observe('after|0', AfterOpen('View', '0'));
        Observer.Observe('after|1', AfterOpen('View', '1'));
        Observer.Finish();
    end;

    [Test]
    procedure GoToKey_Open_OpenView()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('goto|=1|3', GoToOpen('View', '=1', 3));
        Observer.Observe('goto|=1|1', GoToOpen('View', '=1', 1));
        Observer.Observe('goto|=0|1', GoToOpen('View', '=0', 1));
        Observer.Observe('goto|=0|3', GoToOpen('View', '=0', 3));
        Observer.Finish();
    end;
}
