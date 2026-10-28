// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sourcetabletemporary-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 88266 - 88269 (writer RM)
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: a Worksheet over a temporary source (Insert/Modify/DeleteAllowed false, the shape of page 5530 "Item Availability by Event") that
//   empties and refills Rec (Reset, DeleteAll, insert numbered from 1, FindFirst) from a filter field's OnValidate and from an action, with
//   and without CurrPage.Update(false). It holds 27 rows (A1..A25 B1 B2), more than the client reads at once; the filter B leaves two rows.
//   What the page shows afterwards (the current row, the rows First/Next read, where Next/Previous go from the row the client stood on),
//   and which triggers ran (log: R:<name> = OnAfterGetRecord, C:<name> = OnAfterGetCurrRecord).
// Result (BC 27.5, 28.5, 29.0 alike): after a filter OnValidate or an action that refills Rec (no CurrPage.Update needed) the page shows the
//   row the refill left Rec on (B1, A1) and lists exactly the new rows (B1 B2, or all 27), wherever the client stood (row 2 or row 23).
//   An action first reads the row the client stood on (R:A23), then reads from Rec's row; a filter OnValidate does not. The next Next/Previous
//   moves from the new current row (A1 -> A2; Previous from A1 answers No).
// Source: al-runner issues 5779 (filter OnValidate refill) and 5780 (action refill after the client stood past row 20).
// BC versions: 27, 28, 29

table 88266 "LT RM Refill Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Group Code"; Code[10]) { }
        field(3; Name; Text[50]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

page 88267 "LT RM Refill Worksheet"
{
    PageType = Worksheet;
    SourceTable = "LT RM Refill Row";
    SourceTableTemporary = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                field(GroupFilter; GroupFilter)
                {
                    Caption = 'Group Filter';

                    trigger OnValidate()
                    begin
                        Refill();
                    end;
                }
            }
            repeater(Lines)
            {
                Editable = false;
                field(Name; NameText) { Caption = 'Name'; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Recalculate)
            {
                Caption = 'Recalculate';

                trigger OnAction()
                begin
                    Refill();
                end;
            }
            action(RecalculateAndUpdate)
            {
                Caption = 'Recalculate and Update';

                trigger OnAction()
                begin
                    Refill();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Refill();
    end;

    trigger OnAfterGetRecord()
    begin
        NameText := Rec.Name;
        Log.Add('R:' + Rec.Name);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        IsGroupA := Rec."Group Code" = 'A';
        Log.Add('C:' + Rec.Name);
    end;

    var
        Log: Codeunit "LT RM Refill Log";
        GroupFilter: Text;
        NameText: Text;
        IsGroupA: Boolean;

    local procedure Refill()
    var
        EntryNo: Integer;
        RowNo: Integer;
    begin
        Rec.Reset();
        Rec.DeleteAll();
        for RowNo := 1 to 25 do
            AddRow(EntryNo, 'A', StrSubstNo('A%1', RowNo));
        AddRow(EntryNo, 'B', 'B1');
        AddRow(EntryNo, 'B', 'B2');
        if Rec.FindFirst() then;
    end;

    local procedure AddRow(var EntryNo: Integer; GroupCode: Code[10]; NewName: Text[50])
    begin
        if (GroupFilter <> '') and (GroupFilter <> GroupCode) then
            exit;
        EntryNo += 1;
        Rec.Init();
        Rec."Entry No." := EntryNo;
        Rec."Group Code" := GroupCode;
        Rec.Name := NewName;
        Rec.Insert();
    end;
}

codeunit 88268 "LT RM Refill Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Reset()
    begin
        Entries := '';
    end;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;
}

codeunit 88269 "LT RM Refill Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT RM Refill Log";
        TdShortLog: Boolean;

    local procedure OpenByRun(var Ws: TestPage "LT RM Refill Worksheet")
    var
        WsPage: Page "LT RM Refill Worksheet";
    begin
        Log.Reset();
        Ws.Trap();
        WsPage.Run();
    end;

    local procedure GoToRow(var Ws: TestPage "LT RM Refill Worksheet"; RowNo: Integer)
    var
        I: Integer;
    begin
        Ws.First();
        for I := 2 to RowNo do
            Ws.Next();
    end;

    local procedure ReadRows(var Ws: TestPage "LT RM Refill Worksheet") Rows: Text
    begin
        if Ws.First() then
            repeat
                if Rows <> '' then
                    Rows += ' ';
                Rows += Ws.Name.Value();
            until not Ws.Next();
    end;

    local procedure CountRows(var Ws: TestPage "LT RM Refill Worksheet") RowCount: Integer
    begin
        if Ws.First() then
            repeat
                RowCount += 1;
            until not Ws.Next();
    end;

    [Test]
    procedure RM_Filter_B_FromOpen()
    var
        Ws: TestPage "LT RM Refill Worksheet";
    begin
        OpenByRun(Ws);
        Observer.Observe('open shown', Ws.Name.Value());
        Log.Take();
        Ws.GroupFilter.SetValue('B');
        Observer.Observe('validate log', Log.Take());
        Observer.Observe('shown after filter', Ws.Name.Value());
        Observer.Observe('rows', ReadRows(Ws));
        Ws.Close();
        Observer.Expect('open shown', 'A1');
        Observer.Expect('validate log', 'R:B1;R:B2;R:B1;R:B1;C:B1;');
        Observer.Expect('shown after filter', 'B1');
        Observer.Expect('rows', 'B1 B2');
        Observer.Verify();
    end;

    [Test]
    procedure RM_Filter_B_OpenEdit()
    var
        Ws: TestPage "LT RM Refill Worksheet";
    begin
        Log.Reset();
        Ws.OpenEdit();
        Log.Take();
        Ws.GroupFilter.SetValue('B');
        Observer.Observe('validate log', Log.Take());
        Observer.Observe('shown after filter', Ws.Name.Value());
        Observer.Observe('rows', ReadRows(Ws));
        Ws.Close();
        Observer.Expect('validate log', 'R:B1;R:B2;R:B1;R:B1;C:B1;');
        Observer.Expect('shown after filter', 'B1');
        Observer.Expect('rows', 'B1 B2');
        Observer.Verify();
    end;

    [Test]
    procedure RM_Filter_B_FromRow23()
    var
        Ws: TestPage "LT RM Refill Worksheet";
    begin
        OpenByRun(Ws);
        GoToRow(Ws, 23);
        Observer.Observe('before', Ws.Name.Value());
        Log.Take();
        Ws.GroupFilter.SetValue('B');
        Observer.Observe('validate log', Log.Take());
        Observer.Observe('shown after filter', Ws.Name.Value());
        Observer.Observe('next', Format(Ws.Next()) + '|' + Ws.Name.Value());
        Observer.Observe('next log', Log.Take());
        Observer.Observe('rows', ReadRows(Ws));
        Ws.Close();
        Observer.Expect('before', 'A23');
        Observer.Expect('validate log', 'R:B1;R:B2;R:B1;R:B1;C:B1;');
        Observer.Expect('shown after filter', 'B1');
        Observer.Expect('next', 'Yes|B2');
        Observer.Expect('next log', 'R:B2;R:B2;C:B2;');
        Observer.Expect('rows', 'B1 B2');
        Observer.Verify();
    end;

    [Test]
    procedure RM_Filter_B_FromRow2_Previous()
    var
        Ws: TestPage "LT RM Refill Worksheet";
    begin
        OpenByRun(Ws);
        GoToRow(Ws, 2);
        Log.Take();
        Ws.GroupFilter.SetValue('B');
        Observer.Observe('shown after filter', Ws.Name.Value());
        Observer.Observe('previous', Format(Ws.Previous()) + '|' + Ws.Name.Value());
        Observer.Observe('next', Format(Ws.Next()) + '|' + Ws.Name.Value());
        Observer.Observe('next2', Format(Ws.Next()) + '|' + Ws.Name.Value());
        Observer.Observe('moves log', Log.Take());
        Ws.Close();
        Observer.Expect('shown after filter', 'B2');
        Observer.Expect('previous', 'Yes|B1');
        Observer.Expect('next', 'Yes|B2');
        Observer.Expect('next2', 'No|B2');
        Observer.Expect('moves log', 'R:B2;R:B2;R:B1;R:B2;R:B2;C:B2;R:B1;R:B1;C:B1;R:B2;R:B2;C:B2;');
        Observer.Verify();
    end;

    [Test]
    procedure RM_Filter_BThenCleared()
    var
        Ws: TestPage "LT RM Refill Worksheet";
    begin
        OpenByRun(Ws);
        Ws.GroupFilter.SetValue('B');
        Log.Take();
        Ws.GroupFilter.SetValue('');
        Observer.Observe('validate log', Log.Take());
        Observer.Observe('shown after clear', Ws.Name.Value());
        Observer.Observe('row count', Format(CountRows(Ws)));
        Observer.Observe('last', Format(Ws.Last()) + '|' + Ws.Name.Value());
        Ws.Close();
        Observer.Expect('validate log', 'R:A1;R:A2;R:A3;R:A4;R:A5;R:A6;R:A7;R:A8;R:A9;R:A10;R:A11;R:A12;R:A13;R:A14;R:A15;R:A16;R:A17;R:A18;R:A19;R:A20;R:A1;R:A1;C:A1;');
        Observer.Expect('shown after clear', 'A1');
        Observer.Expect('row count', '27');
        Observer.Expect('last', 'Yes|B2');
        Observer.Verify();
    end;

    [Test]
    procedure RM_Action_Recalculate_FromRow23()
    var
        Ws: TestPage "LT RM Refill Worksheet";
    begin
        OpenByRun(Ws);
        GoToRow(Ws, 23);
        Observer.Observe('before', Ws.Name.Value());
        Log.Take();
        Ws.Recalculate.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown after action', Ws.Name.Value());
        Observer.Observe('rows', ReadRows(Ws));
        Ws.Close();
        Observer.Expect('before', 'A23');
        Observer.Expect('action log', 'R:A23;R:A1;R:A1;R:A2;R:A3;R:A4;R:A5;R:A6;R:A7;R:A8;R:A9;R:A10;R:A11;R:A12;R:A13;R:A14;R:A15;R:A16;R:A17;R:A18;R:A19;R:A20;R:A1;R:A1;C:A1;');
        Observer.Expect('shown after action', 'A1');
        Observer.Expect('rows', 'A1 A2 A3 A4 A5 A6 A7 A8 A9 A10 A11 A12 A13 A14 A15 A16 A17 A18 A19 A20 A21 A22 A23 A24 A25 B1 B2');
        Observer.Verify();
    end;

    [Test]
    procedure RM_Action_Recalculate_FromRow23_Next()
    var
        Ws: TestPage "LT RM Refill Worksheet";
    begin
        OpenByRun(Ws);
        GoToRow(Ws, 23);
        Ws.Recalculate.Invoke();
        Log.Take();
        Observer.Observe('next', Format(Ws.Next()) + '|' + Ws.Name.Value());
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', Format(Ws.Previous()) + '|' + Ws.Name.Value());
        Observer.Observe('previous2', Format(Ws.Previous()) + '|' + Ws.Name.Value());
        Observer.Observe('previous log', Log.Take());
        Ws.Close();
        Observer.Expect('next', 'Yes|A2');
        Observer.Expect('next log', 'R:A2;R:A2;C:A2;');
        Observer.Expect('previous', 'Yes|A1');
        Observer.Expect('previous2', 'No|A1');
        Observer.Expect('previous log', 'R:A1;R:A1;C:A1;');
        Observer.Verify();
    end;

    [Test]
    procedure RM_Action_RecalculateAndUpdate_FromRow23()
    var
        Ws: TestPage "LT RM Refill Worksheet";
    begin
        OpenByRun(Ws);
        GoToRow(Ws, 23);
        Log.Take();
        Ws.RecalculateAndUpdate.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown after action', Ws.Name.Value());
        Observer.Observe('next', Format(Ws.Next()) + '|' + Ws.Name.Value());
        Observer.Observe('rows', ReadRows(Ws));
        Ws.Close();
        Observer.Expect('action log', 'R:A23;R:A1;R:A1;R:A2;R:A3;R:A4;R:A5;R:A6;R:A7;R:A8;R:A9;R:A10;R:A11;R:A12;R:A13;R:A14;R:A15;R:A16;R:A17;R:A18;R:A19;R:A20;R:A1;R:A1;C:A1;');
        Observer.Expect('shown after action', 'A1');
        Observer.Expect('next', 'Yes|A2');
        Observer.Expect('rows', 'A1 A2 A3 A4 A5 A6 A7 A8 A9 A10 A11 A12 A13 A14 A15 A16 A17 A18 A19 A20 A21 A22 A23 A24 A25 B1 B2');
        Observer.Verify();
    end;

    [Test]
    procedure RM_Action_Recalculate_FromRow2()
    var
        Ws: TestPage "LT RM Refill Worksheet";
    begin
        OpenByRun(Ws);
        GoToRow(Ws, 2);
        Log.Take();
        Ws.Recalculate.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown after action', Ws.Name.Value());
        Observer.Observe('next', Format(Ws.Next()) + '|' + Ws.Name.Value());
        Ws.Close();
        Observer.Expect('action log', 'R:A2;R:A1;R:A1;R:A2;R:A3;R:A4;R:A5;R:A6;R:A7;R:A8;R:A9;R:A10;R:A11;R:A12;R:A13;R:A14;R:A15;R:A16;R:A17;R:A18;R:A19;R:A20;R:A1;R:A1;C:A1;');
        Observer.Expect('shown after action', 'A1');
        Observer.Expect('next', 'Yes|A2');
        Observer.Verify();
    end;

    [Test]
    procedure RM_Action_Recalculate_AfterFilterB()
    var
        Ws: TestPage "LT RM Refill Worksheet";
    begin
        OpenByRun(Ws);
        Ws.GroupFilter.SetValue('B');
        GoToRow(Ws, 2);
        Log.Take();
        Ws.Recalculate.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown after action', Ws.Name.Value());
        Observer.Observe('rows', ReadRows(Ws));
        Ws.Close();
        Observer.Expect('action log', 'R:B2;R:B1;R:B1;R:B2;R:B1;R:B1;C:B1;');
        Observer.Expect('shown after action', 'B1');
        Observer.Expect('rows', 'B1 B2');
        Observer.Verify();
    end;

    // ---- Writer SH, al-runner issue 5952: an action refills the temporary Rec with FEWER rows (one row, R1) and no CurrPage.Update, on a
    // Worksheet with and without OnAfterGetCurrRecord, opened with 3 or 25 rows (more than the client reads at once). Pages at the end of
    // this file.

    local procedure ShRunCur(RowsAtOpen: Integer; StandOn: Integer)
    var
        Ws: TestPage "LT SH Refill Fewer Cur";
        WsPage: Page "LT SH Refill Fewer Cur";
        Rows: Text;
        I: Integer;
    begin
        Log.Reset();
        Ws.Trap();
        WsPage.SetRowsAtOpen(RowsAtOpen);
        WsPage.Run();
        Ws.First();
        for I := 2 to StandOn do
            Ws.Next();
        Observer.Observe('before', Ws.Name.Value());
        Log.Take();
        Ws.RefillToOne.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown after action', Ws.Name.Value());
        if Ws.First() then
            repeat
                if Rows <> '' then
                    Rows += ' ';
                Rows += Ws.Name.Value();
            until not Ws.Next();
        Observer.Observe('rows', Rows);
        Ws.Close();
    end;

    local procedure ShRunNoCur(RowsAtOpen: Integer; StandOn: Integer)
    var
        Ws: TestPage "LT SH Refill Fewer NoCur";
        WsPage: Page "LT SH Refill Fewer NoCur";
        Rows: Text;
        I: Integer;
    begin
        Log.Reset();
        Ws.Trap();
        WsPage.SetRowsAtOpen(RowsAtOpen);
        WsPage.Run();
        Ws.First();
        for I := 2 to StandOn do
            Ws.Next();
        Observer.Observe('before', Ws.Name.Value());
        Log.Take();
        Ws.RefillToOne.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown after action', Ws.Name.Value());
        if Ws.First() then
            repeat
                if Rows <> '' then
                    Rows += ' ';
                Rows += Ws.Name.Value();
            until not Ws.Next();
        Observer.Observe('rows', Rows);
        Ws.Close();
    end;

    [Test]
    procedure SH_RefillFewer_WithCurrRecord_3To1()
    begin
        ShRunCur(3, 1);
        Observer.Expect('before', 'R1');
        Observer.Expect('action log', 'R:R1;R:R1;R:R1;R:R1;C:R1;');
        Observer.Expect('shown after action', 'R1');
        Observer.Expect('rows', 'R1');
        Observer.Verify();
    end;

    [Test]
    procedure SH_RefillFewer_WithCurrRecord_25To1()
    begin
        ShRunCur(25, 1);
        Observer.Expect('before', 'R1');
        Observer.Expect('action log', 'R:R1;R:R1;R:R1;R:R1;C:R1;');
        Observer.Expect('shown after action', 'R1');
        Observer.Expect('rows', 'R1');
        Observer.Verify();
    end;

    [Test]
    procedure SH_RefillFewer_WithCurrRecord_25To1_FromRow23()
    begin
        ShRunCur(25, 23);
        Observer.Expect('before', 'R23');
        Observer.Expect('action log', 'R:R23;R:R1;R:R1;R:R1;C:R1;');
        Observer.Expect('shown after action', 'R1');
        Observer.Expect('rows', 'R1');
        Observer.Verify();
    end;

    [Test]
    procedure SH_RefillFewer_NoCurrRecord_3To1()
    begin
        ShRunNoCur(3, 1);
        Observer.Expect('before', 'R1');
        Observer.Expect('action log', 'R:R1;R:R1;R:R1;');
        Observer.Expect('shown after action', 'R1');
        Observer.Expect('rows', 'R1');
        Observer.Verify();
    end;

    [Test]
    procedure SH_RefillFewer_NoCurrRecord_25To1()
    begin
        ShRunNoCur(25, 1);
        Observer.Expect('before', 'R1');
        Observer.Expect('action log', 'R:R1;R:R1;R:R1;');
        Observer.Expect('shown after action', 'R1');
        Observer.Expect('rows', 'R1');
        Observer.Verify();
    end;

    // ---- Writer TD, al-runner issue 6029 (follow-up to 5952): an action refills the temporary Rec with TWO rows, three rows or none (no
    // CurrPage.Update), on a Worksheet with and without OnAfterGetCurrRecord, opened with 3 or 25 rows. Pages at the end of this file.

    local procedure TdRunCur(RowsAtOpen: Integer; StandOn: Integer; RefillTo: Integer)
    var
        Ws: TestPage "LT TD Refill Cur";
        WsPage: Page "LT TD Refill Cur";
        Rows: Text;
        I: Integer;
    begin
        Log.Reset();
        Ws.Trap();
        WsPage.SetRows(RowsAtOpen, RefillTo);
        WsPage.Run();
        Ws.First();
        for I := 2 to StandOn do
            Ws.Next();
        Observer.Observe('before', Ws.Name.Value());
        Log.Take();
        Ws.RefillTo.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown after action', Ws.Name.Value());
        if Ws.First() then
            repeat
                if Rows <> '' then
                    Rows += ' ';
                Rows += Ws.Name.Value();
            until not Ws.Next();
        Observer.Observe('rows', Rows);
        if TdShortLog then
            Observer.Observe('walk log length', Format(StrLen(Log.Take())))
        else
            Observer.Observe('walk log', Log.Take());
        Observer.Observe('shown after walk', Ws.Name.Value());
        Ws.Close();
    end;

    local procedure TdRunNoCur(RowsAtOpen: Integer; StandOn: Integer; RefillTo: Integer)
    var
        Ws: TestPage "LT TD Refill NoCur";
        WsPage: Page "LT TD Refill NoCur";
        Rows: Text;
        I: Integer;
    begin
        Log.Reset();
        Ws.Trap();
        WsPage.SetRows(RowsAtOpen, RefillTo);
        WsPage.Run();
        Ws.First();
        for I := 2 to StandOn do
            Ws.Next();
        Observer.Observe('before', Ws.Name.Value());
        Log.Take();
        Ws.RefillTo.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown after action', Ws.Name.Value());
        if Ws.First() then
            repeat
                if Rows <> '' then
                    Rows += ' ';
                Rows += Ws.Name.Value();
            until not Ws.Next();
        Observer.Observe('rows', Rows);
        if TdShortLog then
            Observer.Observe('walk log length', Format(StrLen(Log.Take())))
        else
            Observer.Observe('walk log', Log.Take());
        Observer.Observe('shown after walk', Ws.Name.Value());
        Ws.Close();
    end;

    [Test]
    procedure TD_RefillFewer_WithCurrRecord_3To2()
    begin
        TdRunCur(3, 1, 2);
        Observer.Expect('before', 'R1');
        Observer.Expect('action log', 'R:R1;R:R1;R:R1;R:R2;R:R1;R:R1;C:R1;');
        Observer.Expect('shown after action', 'R1');
        Observer.Expect('rows', 'R1 R2');
        Observer.Expect('walk log', 'R:R2;R:R2;C:R2;');
        Observer.Expect('shown after walk', 'R2');
        Observer.Verify();
    end;

    [Test]
    procedure TD_RefillFewer_WithCurrRecord_25To2()
    begin
        TdRunCur(25, 1, 2);
        Observer.Expect('before', 'R1');
        Observer.Expect('action log', 'R:R1;R:R1;R:R1;R:R2;R:R1;R:R1;C:R1;');
        Observer.Expect('shown after action', 'R1');
        Observer.Expect('rows', 'R1 R2');
        Observer.Expect('walk log', 'R:R2;R:R2;C:R2;');
        Observer.Expect('shown after walk', 'R2');
        Observer.Verify();
    end;

    [Test]
    procedure TD_RefillFewer_WithCurrRecord_25To3()
    begin
        TdRunCur(25, 1, 3);
        Observer.Expect('before', 'R1');
        Observer.Expect('action log', 'R:R1;R:R1;R:R1;R:R2;R:R3;R:R1;R:R1;C:R1;');
        Observer.Expect('shown after action', 'R1');
        Observer.Expect('rows', 'R1 R2 R3');
        Observer.Expect('walk log', 'R:R2;R:R2;C:R2;R:R3;R:R3;C:R3;');
        Observer.Expect('shown after walk', 'R3');
        Observer.Verify();
    end;

    [Test]
    procedure TD_RefillFewer_WithCurrRecord_3To0()
    begin
        TdRunCur(3, 1, 0);
        Observer.Expect('before', 'R1');
        Observer.Expect('action log', 'R:R1;C:;');
        Observer.Expect('shown after action', '');
        Observer.Expect('rows', '');
        Observer.Expect('walk log', '');
        Observer.Expect('shown after walk', '');
        Observer.Verify();
    end;

    [Test]
    procedure TD_RefillFewer_WithCurrRecord_25To0()
    begin
        TdRunCur(25, 1, 0);
        Observer.Expect('before', 'R1');
        Observer.Expect('action log', 'R:R1;C:;');
        Observer.Expect('shown after action', '');
        Observer.Expect('rows', '');
        Observer.Expect('walk log', '');
        Observer.Expect('shown after walk', '');
        Observer.Verify();
    end;

    [Test]
    procedure TD_RefillFewer_WithCurrRecord_25To2_FromRow23()
    begin
        TdRunCur(25, 23, 2);
        Observer.Expect('before', 'R23');
        Observer.Expect('action log', 'R:R23;R:R1;R:R1;R:R2;R:R1;R:R1;C:R1;');
        Observer.Expect('shown after action', 'R1');
        Observer.Expect('rows', 'R1 R2');
        Observer.Expect('walk log', 'R:R2;R:R2;C:R2;');
        Observer.Expect('shown after walk', 'R2');
        Observer.Verify();
    end;

    [Test]
    procedure TD_RefillFewer_WithCurrRecord_3To2_FromRow3()
    begin
        TdRunCur(3, 3, 2);
        Observer.Expect('before', 'R3');
        Observer.Expect('action log', 'R:R3;R:R1;R:R1;R:R2;R:R1;R:R1;C:R1;');
        Observer.Expect('shown after action', 'R1');
        Observer.Expect('rows', 'R1 R2');
        Observer.Expect('walk log', 'R:R2;R:R2;C:R2;');
        Observer.Expect('shown after walk', 'R2');
        Observer.Verify();
    end;

    [Test]
    procedure TD_RefillFewer_NoCurrRecord_3To2()
    begin
        TdRunNoCur(3, 1, 2);
        Observer.Expect('before', 'R1');
        Observer.Expect('action log', 'R:R1;R:R1;R:R1;R:R2;R:R1;');
        Observer.Expect('shown after action', 'R1');
        Observer.Expect('rows', 'R1 R2');
        Observer.Expect('walk log', '');
        Observer.Expect('shown after walk', 'R2');
        Observer.Verify();
    end;

    [Test]
    procedure TD_RefillFewer_NoCurrRecord_25To2()
    begin
        TdRunNoCur(25, 1, 2);
        Observer.Expect('before', 'R1');
        Observer.Expect('action log', 'R:R1;R:R1;R:R1;R:R2;R:R1;');
        Observer.Expect('shown after action', 'R1');
        Observer.Expect('rows', 'R1 R2');
        Observer.Expect('walk log', '');
        Observer.Expect('shown after walk', 'R2');
        Observer.Verify();
    end;

    [Test]
    procedure TD_RefillFewer_NoCurrRecord_25To3()
    begin
        TdRunNoCur(25, 1, 3);
        Observer.Expect('before', 'R1');
        Observer.Expect('action log', 'R:R1;R:R1;R:R1;R:R2;R:R3;R:R1;');
        Observer.Expect('shown after action', 'R1');
        Observer.Expect('rows', 'R1 R2 R3');
        Observer.Expect('walk log', '');
        Observer.Expect('shown after walk', 'R3');
        Observer.Verify();
    end;

    [Test]
    procedure TD_RefillFewer_NoCurrRecord_3To0()
    begin
        TdRunNoCur(3, 1, 0);
        Observer.Expect('before', 'R1');
        Observer.Expect('action log', 'R:R1;');
        Observer.Expect('shown after action', '');
        Observer.Expect('rows', '');
        Observer.Expect('walk log', '');
        Observer.Expect('shown after walk', '');
        Observer.Verify();
    end;

    [Test]
    procedure TD_RefillFewer_NoCurrRecord_25To0()
    begin
        TdRunNoCur(25, 1, 0);
        Observer.Expect('before', 'R1');
        Observer.Expect('action log', 'R:R1;');
        Observer.Expect('shown after action', '');
        Observer.Expect('rows', '');
        Observer.Expect('walk log', '');
        Observer.Expect('shown after walk', '');
        Observer.Verify();
    end;

    [Test]
    procedure TD_RefillFewer_NoCurrRecord_25To2_FromRow23()
    begin
        TdRunNoCur(25, 23, 2);
        Observer.Expect('before', 'R23');
        Observer.Expect('action log', 'R:R23;R:R23;R:R1;R:R1;R:R2;R:R1;');
        Observer.Expect('shown after action', 'R1');
        Observer.Expect('rows', 'R1 R2');
        Observer.Expect('walk log', '');
        Observer.Expect('shown after walk', 'R2');
        Observer.Verify();
    end;

    [Test]
    procedure TD_RefillFewer_NoCurrRecord_3To2_FromRow3()
    begin
        TdRunNoCur(3, 3, 2);
        Observer.Expect('before', 'R3');
        Observer.Expect('action log', 'R:R3;R:R3;R:R1;R:R1;R:R2;R:R1;');
        Observer.Expect('shown after action', 'R1');
        Observer.Expect('rows', 'R1 R2');
        Observer.Expect('walk log', '');
        Observer.Expect('shown after walk', 'R2');
        Observer.Verify();
    end;

    [Test]
    procedure TD_RefillMany_WithCurrRecord_3To25()
    begin
        TdShortLog := true;
        TdRunCur(3, 1, 25);
        Observer.Finish();
    end;

    [Test]
    procedure TD_RefillMany_WithCurrRecord_25To22()
    begin
        TdShortLog := true;
        TdRunCur(25, 1, 22);
        Observer.Finish();
    end;

    [Test]
    procedure TD_RefillMany_WithCurrRecord_30To21_FromRow25()
    begin
        TdShortLog := true;
        TdRunCur(30, 25, 21);
        Observer.Finish();
    end;

    [Test]
    procedure TD_RefillMany_NoCurrRecord_3To25()
    begin
        TdShortLog := true;
        TdRunNoCur(3, 1, 25);
        Observer.Finish();
    end;

    [Test]
    procedure TD_RefillMany_NoCurrRecord_25To22()
    begin
        TdShortLog := true;
        TdRunNoCur(25, 1, 22);
        Observer.Finish();
    end;

    [Test]
    procedure TD_RefillMany_NoCurrRecord_30To21_FromRow25()
    begin
        TdShortLog := true;
        TdRunNoCur(30, 25, 21);
        Observer.Finish();
    end;
}

page 89437 "LT SH Refill Fewer Cur"
{
    PageType = Worksheet;
    SourceTable = "LT RM Refill Row";
    SourceTableTemporary = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                Editable = false;
                field(Name; Rec.Name) { Caption = 'Name'; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RefillToOne)
            {
                Caption = 'Refill To One Row';

                trigger OnAction()
                begin
                    Fill(1);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Fill(RowsAtOpen);
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Rec.Name);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Rec.Name);
    end;

    var
        Log: Codeunit "LT RM Refill Log";
        RowsAtOpen: Integer;

    procedure SetRowsAtOpen(NewRows: Integer)
    begin
        RowsAtOpen := NewRows;
    end;

    local procedure Fill(RowCount: Integer)
    var
        RowNo: Integer;
    begin
        Rec.Reset();
        Rec.DeleteAll();
        for RowNo := 1 to RowCount do begin
            Rec.Init();
            Rec."Entry No." := RowNo;
            Rec."Group Code" := 'R';
            Rec.Name := StrSubstNo('R%1', RowNo);
            Rec.Insert();
        end;
        if Rec.FindFirst() then;
    end;
}

page 89438 "LT SH Refill Fewer NoCur"
{
    PageType = Worksheet;
    SourceTable = "LT RM Refill Row";
    SourceTableTemporary = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                Editable = false;
                field(Name; Rec.Name) { Caption = 'Name'; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RefillToOne)
            {
                Caption = 'Refill To One Row';

                trigger OnAction()
                begin
                    Fill(1);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Fill(RowsAtOpen);
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Rec.Name);
    end;

    var
        Log: Codeunit "LT RM Refill Log";
        RowsAtOpen: Integer;

    procedure SetRowsAtOpen(NewRows: Integer)
    begin
        RowsAtOpen := NewRows;
    end;

    local procedure Fill(RowCount: Integer)
    var
        RowNo: Integer;
    begin
        Rec.Reset();
        Rec.DeleteAll();
        for RowNo := 1 to RowCount do begin
            Rec.Init();
            Rec."Entry No." := RowNo;
            Rec."Group Code" := 'R';
            Rec.Name := StrSubstNo('R%1', RowNo);
            Rec.Insert();
        end;
        if Rec.FindFirst() then;
    end;
}

page 89810 "LT TD Refill Cur"
{
    PageType = Worksheet;
    SourceTable = "LT RM Refill Row";
    SourceTableTemporary = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                Editable = false;
                field(Name; Rec.Name) { Caption = 'Name'; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RefillTo)
            {
                Caption = 'Refill';

                trigger OnAction()
                begin
                    Fill(RefillCount);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Fill(RowsAtOpen);
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Rec.Name);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Rec.Name);
    end;

    var
        Log: Codeunit "LT RM Refill Log";
        RowsAtOpen: Integer;
        RefillCount: Integer;

    procedure SetRows(NewRows: Integer; NewRefillTo: Integer)
    begin
        RowsAtOpen := NewRows;
        RefillCount := NewRefillTo;
    end;

    local procedure Fill(RowCount: Integer)
    var
        RowNo: Integer;
    begin
        Rec.Reset();
        Rec.DeleteAll();
        for RowNo := 1 to RowCount do begin
            Rec.Init();
            Rec."Entry No." := RowNo;
            Rec."Group Code" := 'R';
            Rec.Name := StrSubstNo('R%1', RowNo);
            Rec.Insert();
        end;
        if Rec.FindFirst() then;
    end;
}

page 89811 "LT TD Refill NoCur"
{
    PageType = Worksheet;
    SourceTable = "LT RM Refill Row";
    SourceTableTemporary = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                Editable = false;
                field(Name; Rec.Name) { Caption = 'Name'; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RefillTo)
            {
                Caption = 'Refill';

                trigger OnAction()
                begin
                    Fill(RefillCount);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Fill(RowsAtOpen);
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Rec.Name);
    end;

    var
        Log: Codeunit "LT RM Refill Log";
        RowsAtOpen: Integer;
        RefillCount: Integer;

    procedure SetRows(NewRows: Integer; NewRefillTo: Integer)
    begin
        RowsAtOpen := NewRows;
        RefillCount := NewRefillTo;
    end;

    local procedure Fill(RowCount: Integer)
    var
        RowNo: Integer;
    begin
        Rec.Reset();
        Rec.DeleteAll();
        for RowNo := 1 to RowCount do begin
            Rec.Init();
            Rec."Entry No." := RowNo;
            Rec."Group Code" := 'R';
            Rec.Name := StrSubstNo('R%1', RowNo);
            Rec.Insert();
        end;
        if Rec.FindFirst() then;
    end;
}
