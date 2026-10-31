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
        Obs.Observe('open log', Log.Dump());
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
        Obs.Finish();
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
        Obs.Finish();
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
        Obs.Finish();
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
        Obs.Finish();
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
        Obs.Finish();
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
        Obs.Finish();
    end;
}
