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
// Measured (27.5, 28.5, 29.0 and SaaS 29 alike): the find list walks one row at a time from the current row as in Y41GoToKeyFindListCurr
//   (also into the second block of 45 rows); GoToKey of the current first row reads nothing; GoToKey of the current row N010 starts
//   again at the first row. The current-only list answers a miss with No and runs OnAfterGetCurrRecord on every other row and back to
//   the start row (from the first row) or ends on the last row read; one row or no row: No and nothing runs. With the result unused a
//   miss raises 'The row does not exist on the TestPage.' (TestRowNotFound).
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
        Observer.Expect('open log', 'F:=><=Yes;R:001;N:1=1;R:002;N:1=1;R:003;N:1=1;R:004;N:1=1;R:005;N:1=1;R:006;N:1=1;R:007;N:1=1;R:008;N:1=1;R:009;N:1=1;R:010;N:1=1;R:011;N:1=1;R:012;N:1=1;R:013;N:1=1;R:014;N:1=1;R:015;N:1=1;R:016;N:1=1;R:017;N:1=1;R:018;N:1=1;R:019;N:1=1;R:020;R:001;N:-1=0;F:==Yes;R:001;C:001');
        Observer.Expect('open no', 'N001');
        Observer.Expect('ret', 'Yes');
        Observer.Expect('log', 'R:002;F:==Yes;R:002;C:002;R:003;F:==Yes;R:003;C:003;R:004;F:==Yes;R:004;C:004;R:005;F:==Yes;R:005;C:005;R:006;F:==Yes;R:006;C:006;R:007;F:==Yes;R:007;C:007;R:008;F:==Yes;R:008;C:008;R:009;F:==Yes;R:009;C:009;R:010;F:==Yes;R:010;C:010;R:011;F:==Yes;R:011;C:011;R:012;F:==Yes;R:012;C:012;R:013;F:==Yes;R:013;C:013;R:014;F:==Yes;R:014;C:014;R:015;F:==Yes;R:015;C:015;R:016;F:==Yes;R:016;C:016;R:017;F:==Yes;R:017;C:017;R:018;F:==Yes;R:018;C:018;R:019;F:==Yes;R:019;C:019;R:020;N:1=1;R:021;N:1=1;R:022;N:1=1;R:023;N:1=1;R:024;N:1=1;R:025;N:1=1;R:026;N:1=1;R:027;N:1=1;R:028;N:1=1;R:029;N:1=1;R:030;N:1=1;R:031;N:1=1;R:032;N:1=1;R:033;N:1=1;R:034;N:1=1;R:035;N:1=1;R:036;N:1=1;R:037;N:1=1;R:038;N:1=1;R:039;N:1=1;R:040;R:020;F:==Yes;R:020;C:020;R:021;F:==Yes;R:021;C:021;R:022;F:==Yes;R:022;C:022;R:023;F:==Yes;R:023;C:023;R:024;F:==Yes;R:024;C:024;R:025;F:==Yes;R:025;C:025;R:026;F:==Yes;R:026;C:026;R:027;F:==Yes;R:027;C:027;R:028;F:==Yes;R:028;C:028;R:029;F:==Yes;R:029;C:029;R:030;F:==Yes;R:030;C:030;R:031;F:==Yes;R:031;C:031;R:032;F:==Yes;R:032;C:032;R:033;F:==Yes;R:033;C:033');
        Observer.Expect('no', 'N033');
        Observer.Expect('next', 'Yes');
        Observer.Expect('next log', 'R:034;F:==Yes;R:034;C:034');
        Observer.Expect('next no', 'N034');
        Observer.Verify();
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
        Observer.Expect('first ret', 'Yes');
        Observer.Expect('first log', '');
        Observer.Expect('first no', 'N001');
        Observer.Expect('to10 ret', 'Yes');
        Observer.Expect('to10 log', 'R:002;F:==Yes;R:002;C:002;R:003;F:==Yes;R:003;C:003;R:004;F:==Yes;R:004;C:004;R:005;F:==Yes;R:005;C:005;R:006;F:==Yes;R:006;C:006;R:007;F:==Yes;R:007;C:007;R:008;F:==Yes;R:008;C:008;R:009;F:==Yes;R:009;C:009;R:010;F:==Yes;R:010;C:010');
        Observer.Expect('back ret', 'Yes');
        Observer.Expect('back log', 'R:001;F:==Yes;R:001;C:001');
        Observer.Expect('back no', 'N001');
        Observer.Verify();
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
        Observer.Expect('to10 ret', 'Yes');
        Observer.Expect('to10 log', 'R:002;F:==Yes;R:002;C:002;R:003;F:==Yes;R:003;C:003;R:004;F:==Yes;R:004;C:004;R:005;F:==Yes;R:005;C:005;R:006;F:==Yes;R:006;C:006;R:007;F:==Yes;R:007;C:007;R:008;F:==Yes;R:008;C:008;R:009;F:==Yes;R:009;C:009;R:010;F:==Yes;R:010;C:010');
        Observer.Expect('again ret', 'Yes');
        Observer.Expect('again log', 'R:001;F:==Yes;R:001;C:001;R:002;F:==Yes;R:002;C:002;R:003;F:==Yes;R:003;C:003;R:004;F:==Yes;R:004;C:004;R:005;F:==Yes;R:005;C:005;R:006;F:==Yes;R:006;C:006;R:007;F:==Yes;R:007;C:007;R:008;F:==Yes;R:008;C:008;R:009;F:==Yes;R:009;C:009;R:010;F:==Yes;R:010;C:010');
        Observer.Expect('again no', 'N010');
        Observer.Expect('next', 'Yes');
        Observer.Expect('next log', 'R:011;F:==Yes;R:011;C:011');
        Observer.Expect('next no', 'N011');
        Observer.Verify();
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
        Observer.Expect('miss ret', 'No');
        Observer.Expect('miss log', 'R:001;F:==Yes;R:001;C:001;R:002;F:==Yes;R:002;C:002;R:003;F:==Yes;R:003;C:003;R:004;F:==Yes;R:004;C:004;R:005;F:==Yes;R:005;C:005;R:006;F:==Yes;R:006;C:006;R:007;F:==Yes;R:007;C:007;R:008;F:==Yes;R:008;C:008;R:009;F:==Yes;R:009;C:009;R:010;F:==Yes;R:010;C:010;R:011;F:==Yes;R:011;C:011;R:012;F:==Yes;R:012;C:012;R:013;F:==Yes;R:013;C:013;R:014;F:==Yes;R:014;C:014;R:015;F:==Yes;R:015;C:015;R:016;F:==Yes;R:016;C:016;R:017;F:==Yes;R:017;C:017;R:018;F:==Yes;R:018;C:018;R:019;F:==Yes;R:019;C:019;R:020;N:1=1;R:021;N:1=1;R:022;N:1=1;R:023;N:1=1;R:024;N:1=1;R:025;N:1=0;R:020;F:==Yes;R:020;C:020;R:021;F:==Yes;R:021;C:021;R:022;F:==Yes;R:022;C:022;R:023;F:==Yes;R:023;C:023;R:024;F:==Yes;R:024;C:024;R:025;F:==Yes;R:025;C:025;R:010;F:==Yes;R:010;C:010');
        Observer.Expect('miss no', 'N010');
        Observer.Expect('unused ok', 'No');
        Observer.Expect('unused|text', 'The row does not exist on the TestPage.');
        Observer.Expect('unused|code', 'TestRowNotFound');
        Observer.Expect('unused log', 'R:001;F:==Yes;R:001;C:001;R:002;F:==Yes;R:002;C:002;R:003;F:==Yes;R:003;C:003;R:004;F:==Yes;R:004;C:004;R:005;F:==Yes;R:005;C:005;R:006;F:==Yes;R:006;C:006;R:007;F:==Yes;R:007;C:007;R:008;F:==Yes;R:008;C:008;R:009;F:==Yes;R:009;C:009;R:010;F:==Yes;R:010;C:010;R:011;F:==Yes;R:011;C:011;R:012;F:==Yes;R:012;C:012;R:013;F:==Yes;R:013;C:013;R:014;F:==Yes;R:014;C:014;R:015;F:==Yes;R:015;C:015;R:016;F:==Yes;R:016;C:016;R:017;F:==Yes;R:017;C:017;R:018;F:==Yes;R:018;C:018;R:019;F:==Yes;R:019;C:019;R:020;F:==Yes;R:020;C:020;R:021;F:==Yes;R:021;C:021;R:022;F:==Yes;R:022;C:022;R:023;F:==Yes;R:023;C:023;R:024;F:==Yes;R:024;C:024;R:025;F:==Yes;R:025;C:025;R:010;F:==Yes;R:010;C:010');
        Observer.Expect('unused no', 'N010');
        Observer.Verify();
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
        Observer.Expect('open log', 'C:001');
        Observer.Expect('miss ret', 'No');
        Observer.Expect('miss log', 'C:002;C:003;C:001');
        Observer.Expect('miss no', 'N001');
        Observer.Expect('unused ok', 'No');
        Observer.Expect('unused|text', 'The row does not exist on the TestPage.');
        Observer.Expect('unused|code', 'TestRowNotFound');
        Observer.Expect('unused log', 'C:002;C:003;C:001');
        Observer.Expect('unused no', 'N001');
        Observer.Verify();
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
        Observer.Expect('open log', 'C:1');
        Observer.Expect('open no', 'E1');
        Observer.Expect('hit ret', 'Yes');
        Observer.Expect('hit log', 'C:2');
        Observer.Expect('hit no', 'E2');
        Observer.Expect('miss ret', 'No');
        Observer.Expect('miss log', 'C:1;C:2');
        Observer.Expect('miss no', 'E2');
        Observer.Expect('unused ok', 'No');
        Observer.Expect('unused|text', 'The row does not exist on the TestPage.');
        Observer.Expect('unused|code', 'TestRowNotFound');
        Observer.Expect('unused log', 'C:1;C:2');
        Observer.Expect('unused no', 'E2');
        Observer.Verify();
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
        Observer.Expect('to3 ret', 'Yes');
        Observer.Expect('to3 log', 'C:002;C:003');
        Observer.Expect('miss ret', 'No');
        Observer.Expect('miss log', 'C:001;C:002;C:003');
        Observer.Expect('miss no', 'N003');
        Observer.Expect('unused ok', 'No');
        Observer.Expect('unused|text', 'The row does not exist on the TestPage.');
        Observer.Expect('unused|code', 'TestRowNotFound');
        Observer.Expect('unused log', 'C:001;C:002;C:003;C:002');
        Observer.Expect('unused no', 'N002');
        Observer.Verify();
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
        Observer.Expect('open log', 'C:001');
        Observer.Expect('miss ret', 'No');
        Observer.Expect('miss log', '');
        Observer.Expect('miss no', 'N001');
        Observer.Verify();
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
        Observer.Expect('open log', '');
        Observer.Expect('miss ret', 'No');
        Observer.Expect('miss log', '');
        Observer.Expect('miss no', '');
        Observer.Verify();
    end;
}
