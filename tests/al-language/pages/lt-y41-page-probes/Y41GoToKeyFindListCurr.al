// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-gotokey-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); log table 92800 (Y41Log.al); table 92810, page 92811, test codeunit 92812
// Probe: written against BC on the corpus CI matrix (27.5, 28.5, 29.0); every literal asserted below is what that tier produced.
// Facts: TestPage.GoToRecord / GoToKey on a list page that serves its rows from OnFindRecord and OnNextRecord AND has
//   OnAfterGetCurrRecord, onto a row past the first window of rows (30 rows R001..R030): the return value, the trigger log, the
//   shown row and the Visible of an action whose page global OnAfterGetCurrRecord sets. Also the last row, a missing key, a
//   start row other than the first, and Next/Previous after the move.
//   Log format: F:<Which>=<found> = OnFindRecord, N:<Steps>=<moved> = OnNextRecord, R:<No.> = OnAfterGetRecord, C:<No.> = OnAfterGetCurrRecord.
//   pages/lt-ai-list-order/AiListOrderTests.al Paging_GoToKey_Nav pins the same move without OnAfterGetCurrRecord.
// Measured (27.5, 28.5, 29.0 alike): OpenView reads a window of 20 rows forward, then '=' on the first row with OnAfterGetCurrRecord.
//   GoToKey / GoToRecord walk from the current row one row at a time; each step runs OnAfterGetRecord, OnFindRecord('='),
//   OnAfterGetRecord and OnAfterGetCurrRecord on the next row (no OnNextRecord), up to the key. GoToKey from R005 to R027 starts again
//   at R001. A missing key returns No after walking every row. The action's Visible follows OnAfterGetCurrRecord.
// BC versions: all (CI)

table 92810 "LT Y41 GK Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

page 92811 "LT Y41 GK List"
{
    PageType = List;
    SourceTable = "LT Y41 GK Row";
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

    actions
    {
        area(Processing)
        {
            action(ShownAction)
            {
                ApplicationArea = All;
                Visible = ShowAct;

                trigger OnAction()
                begin
                end;
            }
        }
    }

    var
        ShowAct: Boolean;

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Record "LT Y41 Log";
        Found: Boolean;
    begin
        Found := Rec.Find(Which);
        Log.AddLine('F:' + Which + '=' + Format(Found));
        exit(Found);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Log: Record "LT Y41 Log";
        Moved: Integer;
    begin
        Moved := Rec.Next(Steps);
        Log.AddLine('N:' + Format(Steps) + '=' + Format(Moved));
        exit(Moved);
    end;

    trigger OnAfterGetRecord()
    var
        Log: Record "LT Y41 Log";
    begin
        Log.AddLine('R:' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Record "LT Y41 Log";
    begin
        ShowAct := Rec."No." <> '';
        Log.AddLine('C:' + Rec."No.");
    end;
}

codeunit 92812 "LT Y41 GoToKey Find Curr"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";

    local procedure Seed()
    var
        Row: Record "LT Y41 GK Row";
        Log: Record "LT Y41 Log";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to 30 do begin
            Row.Init();
            Row."No." := 'R' + Format(i, 0, '<Integer,3><Filler Character,0>');
            Row.Name := 'name' + Format(i);
            Row.Insert();
        end;
        Log.ClearLog();
    end;

    local procedure OpenAndClear(var P: TestPage "LT Y41 GK List")
    var
        Log: Record "LT Y41 Log";
    begin
        P.OpenView();
        Log.ClearLog();
    end;

    local procedure ObserveStep(Prefix: Text; var P: TestPage "LT Y41 GK List")
    var
        Log: Record "LT Y41 Log";
    begin
        Obs.Observe(Prefix + 'log', Log.Dump());
        Obs.Observe(Prefix + 'no', P.NoCtl.Value());
        Obs.Observe(Prefix + 'visible', Format(P.ShownAction.Visible()));
        Log.ClearLog();
    end;

    [Test]
    procedure GK_FindList_Curr_OpenView()
    var
        Log: Record "LT Y41 Log";
        P: TestPage "LT Y41 GK List";
    begin
        Seed();
        P.OpenView();
        Obs.Observe('open log', Log.Dump());
        Obs.Observe('no', P.NoCtl.Value());
        Obs.Observe('visible', Format(P.ShownAction.Visible()));
        P.Close();
        Obs.Expect('open log', 'F:=><=Yes;R:R001;N:1=1;R:R002;N:1=1;R:R003;N:1=1;R:R004;N:1=1;R:R005;N:1=1;R:R006;N:1=1;R:R007;N:1=1;R:R008;N:1=1;R:R009;N:1=1;R:R010;N:1=1;R:R011;N:1=1;R:R012;N:1=1;R:R013;N:1=1;R:R014;N:1=1;R:R015;N:1=1;R:R016;N:1=1;R:R017;N:1=1;R:R018;N:1=1;R:R019;N:1=1;R:R020;R:R001;N:-1=0;F:==Yes;R:R001;C:R001');
        Obs.Expect('no', 'R001');
        Obs.Expect('visible', 'Yes');
        Obs.Verify();
    end;

    [Test]
    procedure GK_FindList_Curr_PastWindow_GoToRecord()
    var
        Row: Record "LT Y41 GK Row";
        P: TestPage "LT Y41 GK List";
    begin
        Seed();
        OpenAndClear(P);
        Row.Get('R027');
        Obs.Observe('ret', Format(P.GoToRecord(Row)));
        ObserveStep('', P);
        P.Close();
        Obs.Expect('ret', 'Yes');
        Obs.Expect('log', 'R:R002;F:==Yes;R:R002;C:R002;R:R003;F:==Yes;R:R003;C:R003;R:R004;F:==Yes;R:R004;C:R004;R:R005;F:==Yes;R:R005;C:R005;R:R006;F:==Yes;R:R006;C:R006;R:R007;F:==Yes;R:R007;C:R007;R:R008;F:==Yes;R:R008;C:R008;R:R009;F:==Yes;R:R009;C:R009;R:R010;F:==Yes;R:R010;C:R010;R:R011;F:==Yes;R:R011;C:R011;R:R012;F:==Yes;R:R012;C:R012;R:R013;F:==Yes;R:R013;C:R013;R:R014;F:==Yes;R:R014;C:R014;R:R015;F:==Yes;R:R015;C:R015;R:R016;F:==Yes;R:R016;C:R016;R:R017;F:==Yes;R:R017;C:R017;R:R018;F:==Yes;R:R018;C:R018;R:R019;F:==Yes;R:R019;C:R019;R:R020;N:1=1;R:R021;N:1=1;R:R022;N:1=1;R:R023;N:1=1;R:R024;N:1=1;R:R025;N:1=1;R:R026;N:1=1;R:R027;N:1=1;R:R028;N:1=1;R:R029;N:1=1;R:R030;N:1=0;R:R020;F:==Yes;R:R020;C:R020;R:R021;F:==Yes;R:R021;C:R021;R:R022;F:==Yes;R:R022;C:R022;R:R023;F:==Yes;R:R023;C:R023;R:R024;F:==Yes;R:R024;C:R024;R:R025;F:==Yes;R:R025;C:R025;R:R026;F:==Yes;R:R026;C:R026;R:R027;F:==Yes;R:R027;C:R027');
        Obs.Expect('no', 'R027');
        Obs.Expect('visible', 'Yes');
        Obs.Verify();
    end;

    [Test]
    procedure GK_FindList_Curr_PastWindow_GoToKey()
    var
        P: TestPage "LT Y41 GK List";
    begin
        Seed();
        OpenAndClear(P);
        Obs.Observe('ret', Format(P.GoToKey('R027')));
        ObserveStep('', P);
        P.Close();
        Obs.Expect('ret', 'Yes');
        Obs.Expect('log', 'R:R002;F:==Yes;R:R002;C:R002;R:R003;F:==Yes;R:R003;C:R003;R:R004;F:==Yes;R:R004;C:R004;R:R005;F:==Yes;R:R005;C:R005;R:R006;F:==Yes;R:R006;C:R006;R:R007;F:==Yes;R:R007;C:R007;R:R008;F:==Yes;R:R008;C:R008;R:R009;F:==Yes;R:R009;C:R009;R:R010;F:==Yes;R:R010;C:R010;R:R011;F:==Yes;R:R011;C:R011;R:R012;F:==Yes;R:R012;C:R012;R:R013;F:==Yes;R:R013;C:R013;R:R014;F:==Yes;R:R014;C:R014;R:R015;F:==Yes;R:R015;C:R015;R:R016;F:==Yes;R:R016;C:R016;R:R017;F:==Yes;R:R017;C:R017;R:R018;F:==Yes;R:R018;C:R018;R:R019;F:==Yes;R:R019;C:R019;R:R020;N:1=1;R:R021;N:1=1;R:R022;N:1=1;R:R023;N:1=1;R:R024;N:1=1;R:R025;N:1=1;R:R026;N:1=1;R:R027;N:1=1;R:R028;N:1=1;R:R029;N:1=1;R:R030;N:1=0;R:R020;F:==Yes;R:R020;C:R020;R:R021;F:==Yes;R:R021;C:R021;R:R022;F:==Yes;R:R022;C:R022;R:R023;F:==Yes;R:R023;C:R023;R:R024;F:==Yes;R:R024;C:R024;R:R025;F:==Yes;R:R025;C:R025;R:R026;F:==Yes;R:R026;C:R026;R:R027;F:==Yes;R:R027;C:R027');
        Obs.Expect('no', 'R027');
        Obs.Expect('visible', 'Yes');
        Obs.Verify();
    end;

    [Test]
    procedure GK_FindList_Curr_LastRow()
    var
        P: TestPage "LT Y41 GK List";
    begin
        Seed();
        OpenAndClear(P);
        Obs.Observe('ret', Format(P.GoToKey('R030')));
        ObserveStep('', P);
        P.Close();
        Obs.Expect('ret', 'Yes');
        Obs.Expect('log', 'R:R002;F:==Yes;R:R002;C:R002;R:R003;F:==Yes;R:R003;C:R003;R:R004;F:==Yes;R:R004;C:R004;R:R005;F:==Yes;R:R005;C:R005;R:R006;F:==Yes;R:R006;C:R006;R:R007;F:==Yes;R:R007;C:R007;R:R008;F:==Yes;R:R008;C:R008;R:R009;F:==Yes;R:R009;C:R009;R:R010;F:==Yes;R:R010;C:R010;R:R011;F:==Yes;R:R011;C:R011;R:R012;F:==Yes;R:R012;C:R012;R:R013;F:==Yes;R:R013;C:R013;R:R014;F:==Yes;R:R014;C:R014;R:R015;F:==Yes;R:R015;C:R015;R:R016;F:==Yes;R:R016;C:R016;R:R017;F:==Yes;R:R017;C:R017;R:R018;F:==Yes;R:R018;C:R018;R:R019;F:==Yes;R:R019;C:R019;R:R020;N:1=1;R:R021;N:1=1;R:R022;N:1=1;R:R023;N:1=1;R:R024;N:1=1;R:R025;N:1=1;R:R026;N:1=1;R:R027;N:1=1;R:R028;N:1=1;R:R029;N:1=1;R:R030;N:1=0;R:R020;F:==Yes;R:R020;C:R020;R:R021;F:==Yes;R:R021;C:R021;R:R022;F:==Yes;R:R022;C:R022;R:R023;F:==Yes;R:R023;C:R023;R:R024;F:==Yes;R:R024;C:R024;R:R025;F:==Yes;R:R025;C:R025;R:R026;F:==Yes;R:R026;C:R026;R:R027;F:==Yes;R:R027;C:R027;R:R028;F:==Yes;R:R028;C:R028;R:R029;F:==Yes;R:R029;C:R029;R:R030;F:==Yes;R:R030;C:R030');
        Obs.Expect('no', 'R030');
        Obs.Expect('visible', 'Yes');
        Obs.Verify();
    end;

    [Test]
    procedure GK_FindList_Curr_Missing()
    var
        P: TestPage "LT Y41 GK List";
    begin
        Seed();
        OpenAndClear(P);
        Obs.Observe('ret', Format(P.GoToKey('R999')));
        ObserveStep('', P);
        P.Close();
        Obs.Expect('ret', 'No');
        Obs.Expect('log', 'R:R002;F:==Yes;R:R002;C:R002;R:R003;F:==Yes;R:R003;C:R003;R:R004;F:==Yes;R:R004;C:R004;R:R005;F:==Yes;R:R005;C:R005;R:R006;F:==Yes;R:R006;C:R006;R:R007;F:==Yes;R:R007;C:R007;R:R008;F:==Yes;R:R008;C:R008;R:R009;F:==Yes;R:R009;C:R009;R:R010;F:==Yes;R:R010;C:R010;R:R011;F:==Yes;R:R011;C:R011;R:R012;F:==Yes;R:R012;C:R012;R:R013;F:==Yes;R:R013;C:R013;R:R014;F:==Yes;R:R014;C:R014;R:R015;F:==Yes;R:R015;C:R015;R:R016;F:==Yes;R:R016;C:R016;R:R017;F:==Yes;R:R017;C:R017;R:R018;F:==Yes;R:R018;C:R018;R:R019;F:==Yes;R:R019;C:R019;R:R020;N:1=1;R:R021;N:1=1;R:R022;N:1=1;R:R023;N:1=1;R:R024;N:1=1;R:R025;N:1=1;R:R026;N:1=1;R:R027;N:1=1;R:R028;N:1=1;R:R029;N:1=1;R:R030;N:1=0;R:R020;F:==Yes;R:R020;C:R020;R:R021;F:==Yes;R:R021;C:R021;R:R022;F:==Yes;R:R022;C:R022;R:R023;F:==Yes;R:R023;C:R023;R:R024;F:==Yes;R:R024;C:R024;R:R025;F:==Yes;R:R025;C:R025;R:R026;F:==Yes;R:R026;C:R026;R:R027;F:==Yes;R:R027;C:R027;R:R028;F:==Yes;R:R028;C:R028;R:R029;F:==Yes;R:R029;C:R029;R:R030;F:==Yes;R:R030;C:R030;R:R001;F:==Yes;R:R001;C:R001');
        Obs.Expect('no', 'R001');
        Obs.Expect('visible', 'Yes');
        Obs.Verify();
    end;

    [Test]
    procedure GK_FindList_Curr_FromOtherRow()
    var
        P: TestPage "LT Y41 GK List";
    begin
        Seed();
        OpenAndClear(P);
        Obs.Observe('ret1', Format(P.GoToKey('R005')));
        ObserveStep('first ', P);
        Obs.Observe('ret2', Format(P.GoToKey('R027')));
        ObserveStep('second ', P);
        P.Close();
        Obs.Expect('ret1', 'Yes');
        Obs.Expect('first log', 'R:R002;F:==Yes;R:R002;C:R002;R:R003;F:==Yes;R:R003;C:R003;R:R004;F:==Yes;R:R004;C:R004;R:R005;F:==Yes;R:R005;C:R005');
        Obs.Expect('first no', 'R005');
        Obs.Expect('first visible', 'Yes');
        Obs.Expect('ret2', 'Yes');
        Obs.Expect('second log', 'R:R001;F:==Yes;R:R001;C:R001;R:R002;F:==Yes;R:R002;C:R002;R:R003;F:==Yes;R:R003;C:R003;R:R004;F:==Yes;R:R004;C:R004;R:R005;F:==Yes;R:R005;C:R005;R:R006;F:==Yes;R:R006;C:R006;R:R007;F:==Yes;R:R007;C:R007;R:R008;F:==Yes;R:R008;C:R008;R:R009;F:==Yes;R:R009;C:R009;R:R010;F:==Yes;R:R010;C:R010;R:R011;F:==Yes;R:R011;C:R011;R:R012;F:==Yes;R:R012;C:R012;R:R013;F:==Yes;R:R013;C:R013;R:R014;F:==Yes;R:R014;C:R014;R:R015;F:==Yes;R:R015;C:R015;R:R016;F:==Yes;R:R016;C:R016;R:R017;F:==Yes;R:R017;C:R017;R:R018;F:==Yes;R:R018;C:R018;R:R019;F:==Yes;R:R019;C:R019;R:R020;N:1=1;R:R021;N:1=1;R:R022;N:1=1;R:R023;N:1=1;R:R024;N:1=1;R:R025;N:1=1;R:R026;N:1=1;R:R027;N:1=1;R:R028;N:1=1;R:R029;N:1=1;R:R030;N:1=0;R:R020;F:==Yes;R:R020;C:R020;R:R021;F:==Yes;R:R021;C:R021;R:R022;F:==Yes;R:R022;C:R022;R:R023;F:==Yes;R:R023;C:R023;R:R024;F:==Yes;R:R024;C:R024;R:R025;F:==Yes;R:R025;C:R025;R:R026;F:==Yes;R:R026;C:R026;R:R027;F:==Yes;R:R027;C:R027');
        Obs.Expect('second no', 'R027');
        Obs.Expect('second visible', 'Yes');
        Obs.Verify();
    end;

    [Test]
    procedure GK_FindList_Curr_ThenNext()
    var
        Row: Record "LT Y41 GK Row";
        P: TestPage "LT Y41 GK List";
    begin
        Seed();
        OpenAndClear(P);
        Row.Get('R027');
        Obs.Observe('ret', Format(P.GoToRecord(Row)));
        ObserveStep('goto ', P);
        Obs.Observe('next', Format(P.Next()));
        ObserveStep('next ', P);
        Obs.Observe('previous', Format(P.Previous()));
        ObserveStep('previous ', P);
        P.Close();
        Obs.Expect('ret', 'Yes');
        Obs.Expect('goto log', 'R:R002;F:==Yes;R:R002;C:R002;R:R003;F:==Yes;R:R003;C:R003;R:R004;F:==Yes;R:R004;C:R004;R:R005;F:==Yes;R:R005;C:R005;R:R006;F:==Yes;R:R006;C:R006;R:R007;F:==Yes;R:R007;C:R007;R:R008;F:==Yes;R:R008;C:R008;R:R009;F:==Yes;R:R009;C:R009;R:R010;F:==Yes;R:R010;C:R010;R:R011;F:==Yes;R:R011;C:R011;R:R012;F:==Yes;R:R012;C:R012;R:R013;F:==Yes;R:R013;C:R013;R:R014;F:==Yes;R:R014;C:R014;R:R015;F:==Yes;R:R015;C:R015;R:R016;F:==Yes;R:R016;C:R016;R:R017;F:==Yes;R:R017;C:R017;R:R018;F:==Yes;R:R018;C:R018;R:R019;F:==Yes;R:R019;C:R019;R:R020;N:1=1;R:R021;N:1=1;R:R022;N:1=1;R:R023;N:1=1;R:R024;N:1=1;R:R025;N:1=1;R:R026;N:1=1;R:R027;N:1=1;R:R028;N:1=1;R:R029;N:1=1;R:R030;N:1=0;R:R020;F:==Yes;R:R020;C:R020;R:R021;F:==Yes;R:R021;C:R021;R:R022;F:==Yes;R:R022;C:R022;R:R023;F:==Yes;R:R023;C:R023;R:R024;F:==Yes;R:R024;C:R024;R:R025;F:==Yes;R:R025;C:R025;R:R026;F:==Yes;R:R026;C:R026;R:R027;F:==Yes;R:R027;C:R027');
        Obs.Expect('goto no', 'R027');
        Obs.Expect('goto visible', 'Yes');
        Obs.Expect('next', 'Yes');
        Obs.Expect('next log', 'R:R028;F:==Yes;R:R028;C:R028');
        Obs.Expect('next no', 'R028');
        Obs.Expect('next visible', 'Yes');
        Obs.Expect('previous', 'Yes');
        Obs.Expect('previous log', 'R:R027;F:==Yes;R:R027;C:R027');
        Obs.Expect('previous no', 'R027');
        Obs.Expect('previous visible', 'Yes');
        Obs.Verify();
    end;
}
