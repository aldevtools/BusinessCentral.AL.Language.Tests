// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-gotokey-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); log table 93240 (Y61Log.al); table 93243, pages 93244-93246, test codeunit 93243
// Probe: written against BC on the corpus CI matrix (27.5, 28.5, 29.0); every literal asserted below is what that tier produced.
// Facts: TestPage.GoToKey / GoToRecord at the edges of the client's row scan: on a list that serves its rows from OnFindRecord and
//   OnNextRecord and has OnAfterGetRecord and OnAfterGetCurrRecord (45 rows: a key in the second block of rows; 25 rows: the key is the
//   first row, the key is the current row, a missing key from a later row), and on a list with OnAfterGetCurrRecord as its only row
//   trigger (a missing key from the first row and from a later row, with one row, with no row; a temporary source filled in OnOpenPage
//   with GoToRecord of a row it holds and of a record it does not hold). A missing key is asked with the result used and, inside a
//   TryFunction, with the result unused.
//   Log format: F:<Which>=<found> = OnFindRecord, N:<Steps>=<moved> = OnNextRecord, R:<n> = OnAfterGetRecord, C:<n> = OnAfterGetCurrRecord,
//   where <n> is the row's "No." without its first letter (N033 is logged 033).
// Neighbours: pages/lt-y41-page-probes/Y41GoToKeyFindListCurr.al (30 rows, hit past the first window, last row, miss from the first row),
//   pages/lt-ai-list-order/AiListOrderTests.al Paging_GoToKey_Nav, misc/lt-probes-needed-7/PnGGoToScan.al (miss with OnAfterGetRecord).
// BC versions: all (CI)

table 93243 "LT Y61 GK Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

page 93244 "LT Y61 GK Find List"
{
    PageType = List;
    SourceTable = "LT Y61 GK Row";
    Editable = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Record "LT Y61 Log";
        Found: Boolean;
    begin
        Found := Rec.Find(Which);
        Log.AddLine('F:' + Which + '=' + Format(Found));
        exit(Found);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Log: Record "LT Y61 Log";
        Moved: Integer;
    begin
        Moved := Rec.Next(Steps);
        Log.AddLine('N:' + Format(Steps) + '=' + Format(Moved));
        exit(Moved);
    end;

    trigger OnAfterGetRecord()
    var
        Log: Record "LT Y61 Log";
    begin
        Log.AddLine('R:' + CopyStr(Rec."No.", 2));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Record "LT Y61 Log";
    begin
        Log.AddLine('C:' + CopyStr(Rec."No.", 2));
    end;
}

page 93245 "LT Y61 GK Curr List"
{
    PageType = List;
    SourceTable = "LT Y61 GK Row";
    Editable = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Log: Record "LT Y61 Log";
    begin
        Log.AddLine('C:' + CopyStr(Rec."No.", 2));
    end;
}

page 93246 "LT Y61 GK Curr Temp List"
{
    PageType = List;
    SourceTable = "LT Y61 GK Row";
    SourceTableTemporary = true;
    Editable = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Init();
        Rec."No." := 'E1';
        Rec.Name := 'one';
        Rec.Insert();
        Rec.Init();
        Rec."No." := 'E2';
        Rec.Name := 'two';
        Rec.Insert();
        Rec.FindFirst();
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Record "LT Y61 Log";
    begin
        Log.AddLine('C:' + CopyStr(Rec."No.", 2));
    end;
}

codeunit 93243 "LT Y61 GoToKey Edges"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed(Rows: Integer)
    var
        Row: Record "LT Y61 GK Row";
        Log: Record "LT Y61 Log";
        i: Integer;
    begin
        ClearLastError();
        Observer.Discard();
        Row.DeleteAll();
        for i := 1 to Rows do begin
            Row.Init();
            Row."No." := 'N' + Format(i, 0, '<Integer,3><Filler Character,0>');
            Row.Name := 'name' + Format(i);
            Row.Insert();
        end;
        Log.ClearLog();
    end;

    local procedure TakeLog(): Text
    var
        Log: Record "LT Y61 Log";
    begin
        exit(Log.Take());
    end;

    [TryFunction]
    local procedure TryGoToKeyFind(var P: TestPage "LT Y61 GK Find List"; No: Code[20])
    begin
        P.GoToKey(No);
    end;

    [TryFunction]
    local procedure TryGoToKeyCurr(var P: TestPage "LT Y61 GK Curr List"; No: Code[20])
    begin
        P.GoToKey(No);
    end;

    [TryFunction]
    local procedure TryGoToRecordTemp(var P: TestPage "LT Y61 GK Curr Temp List"; var Row: Record "LT Y61 GK Row")
    begin
        P.GoToRecord(Row);
    end;

    [Test]
    procedure G613_Find_45Rows_KeyInSecondBlock()
    var
        P: TestPage "LT Y61 GK Find List";
    begin
        Seed(45);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('open no', P.NoCtl.Value());
        Observer.Observe('ret', Format(P.GoToKey('N033')));
        Observer.Observe('log', TakeLog());
        Observer.Observe('no', P.NoCtl.Value());
        Observer.Observe('next', Format(P.Next()));
        Observer.Observe('next log', TakeLog());
        Observer.Observe('next no', P.NoCtl.Value());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure G613_Find_45Rows_KeyInSecondBlock_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure G613_Find_45Rows_KeyInSecondBlock_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure G613_Find_25Rows_KeyIsFirstRow()
    var
        P: TestPage "LT Y61 GK Find List";
    begin
        Seed(25);
        P.OpenView();
        TakeLog();
        Observer.Observe('first ret', Format(P.GoToKey('N001')));
        Observer.Observe('first log', TakeLog());
        Observer.Observe('first no', P.NoCtl.Value());
        Observer.Observe('to10 ret', Format(P.GoToKey('N010')));
        Observer.Observe('to10 log', TakeLog());
        Observer.Observe('back ret', Format(P.GoToKey('N001')));
        Observer.Observe('back log', TakeLog());
        Observer.Observe('back no', P.NoCtl.Value());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure G613_Find_25Rows_KeyIsFirstRow_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure G613_Find_25Rows_KeyIsCurrentRow_NotFirst()
    var
        P: TestPage "LT Y61 GK Find List";
    begin
        Seed(25);
        P.OpenView();
        TakeLog();
        Observer.Observe('to10 ret', Format(P.GoToKey('N010')));
        Observer.Observe('to10 log', TakeLog());
        Observer.Observe('again ret', Format(P.GoToKey('N010')));
        Observer.Observe('again log', TakeLog());
        Observer.Observe('again no', P.NoCtl.Value());
        Observer.Observe('next', Format(P.Next()));
        Observer.Observe('next log', TakeLog());
        Observer.Observe('next no', P.NoCtl.Value());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure G613_Find_25Rows_KeyIsCurrentRow_NotFirst_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure G613_Find_25Rows_Miss_FromLaterRow()
    var
        P: TestPage "LT Y61 GK Find List";
        Ok: Boolean;
    begin
        Seed(25);
        P.OpenView();
        P.GoToKey('N010');
        TakeLog();
        Observer.Observe('miss ret', Format(P.GoToKey('NOPE')));
        Observer.Observe('miss log', TakeLog());
        Observer.Observe('miss no', P.NoCtl.Value());
        P.GoToKey('N010');
        TakeLog();
        Ok := TryGoToKeyFind(P, 'NOPE');
        Observer.Observe('unused ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('unused');
        Observer.Observe('unused log', TakeLog());
        Observer.Observe('unused no', P.NoCtl.Value());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure G613_Find_25Rows_Miss_FromLaterRow_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure G613_Find_25Rows_Miss_FromLaterRow_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure G613_Current_Miss_FromFirstRow()
    var
        P: TestPage "LT Y61 GK Curr List";
        Ok: Boolean;
    begin
        Seed(3);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('miss ret', Format(P.GoToKey('NOPE')));
        Observer.Observe('miss log', TakeLog());
        Observer.Observe('miss no', P.NoCtl.Value());
        Ok := TryGoToKeyCurr(P, 'NOPE');
        Observer.Observe('unused ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('unused');
        Observer.Observe('unused log', TakeLog());
        Observer.Observe('unused no', P.NoCtl.Value());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure G613_Current_Temp_GoToRecord_HitAndMiss()
    var
        P: TestPage "LT Y61 GK Curr Temp List";
        Row: Record "LT Y61 GK Row";
        Ok: Boolean;
    begin
        Seed(0);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('open no', P.NoCtl.Value());
        Row.Init();
        Row."No." := 'E2';
        Observer.Observe('hit ret', Format(P.GoToRecord(Row)));
        Observer.Observe('hit log', TakeLog());
        Observer.Observe('hit no', P.NoCtl.Value());
        Row."No." := 'E9';
        Observer.Observe('miss ret', Format(P.GoToRecord(Row)));
        Observer.Observe('miss log', TakeLog());
        Observer.Observe('miss no', P.NoCtl.Value());
        Ok := TryGoToRecordTemp(P, Row);
        Observer.Observe('unused ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('unused');
        Observer.Observe('unused log', TakeLog());
        Observer.Observe('unused no', P.NoCtl.Value());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure G613_Current_Miss_FromLaterRow()
    var
        P: TestPage "LT Y61 GK Curr List";
        Ok: Boolean;
    begin
        Seed(3);
        P.OpenView();
        TakeLog();
        Observer.Observe('to3 ret', Format(P.GoToKey('N003')));
        Observer.Observe('to3 log', TakeLog());
        Observer.Observe('miss ret', Format(P.GoToKey('NOPE')));
        Observer.Observe('miss log', TakeLog());
        Observer.Observe('miss no', P.NoCtl.Value());
        P.GoToKey('N002');
        TakeLog();
        Ok := TryGoToKeyCurr(P, 'NOPE');
        Observer.Observe('unused ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('unused');
        Observer.Observe('unused log', TakeLog());
        Observer.Observe('unused no', P.NoCtl.Value());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure G613_Current_Miss_OneRow()
    var
        P: TestPage "LT Y61 GK Curr List";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('miss ret', Format(P.GoToKey('NOPE')));
        Observer.Observe('miss log', TakeLog());
        Observer.Observe('miss no', P.NoCtl.Value());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure G613_Current_Miss_Empty()
    var
        P: TestPage "LT Y61 GK Curr List";
    begin
        Seed(0);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('miss ret', Format(P.GoToKey('NOPE')));
        Observer.Observe('miss log', TakeLog());
        Observer.Observe('miss no', P.NoCtl.Value());
        P.Close();
        Observer.Finish();
    end;
}
