// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-data-type
// Scope: in-scope (Cloud). TestPage only, no UI handlers.
// local object: the page shape (every page trigger logs) and the table (every table trigger logs, a validate that fails) are what is under test; the log is a SingleInstance codeunit
// Fixtures used: Probe Observer (codeunit 69160); own objects 97400-97405, test codeunit 97405
// Area (TestPage lifecycle matrix, shape "plain editable list"): OpenEdit, OpenView, OpenNew, New, First, Last, Next, Previous, GoToKey,
//   GoToRecord, SetValue (valid, failing validate), an action that inserts, deletes or refills rows, Close and the close at the end of a test,
//   on a list over a real table with 3 rows and with 25 rows (more than one window). Each cell Observes the row the page shows (key fields),
//   whether a row was inserted, modified or deleted in the table, the order of the page and table triggers, and the error text.
// BC versions: 27, 28, 29

table 97400 "TPM Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Name; Text[30])
        {
            trigger OnValidate()
            var
                Log: Codeunit "TPM Log";
            begin
                Log.Add('T-V:' + "Code");
                if Name = 'bad' then
                    Error('Name must not be bad.');
            end;
        }
        field(3; Amount; Integer) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }

    trigger OnInsert()
    var
        Log: Codeunit "TPM Log";
    begin
        Log.Add('T-I:' + "Code");
    end;

    trigger OnModify()
    var
        Log: Codeunit "TPM Log";
    begin
        Log.Add('T-M:' + "Code");
    end;

    trigger OnDelete()
    var
        Log: Codeunit "TPM Log";
    begin
        Log.Add('T-D:' + "Code");
    end;
}

page 97401 "TPM Plain List"
{
    PageType = List;
    SourceTable = "TPM Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Amount; Rec.Amount) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AddRow)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    New: Record "TPM Row";
                begin
                    New."Code" := 'R2';
                    New.Name := 'added';
                    New.Insert(true);
                end;
            }
            action(AddRowAndUpdate)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    New: Record "TPM Row";
                begin
                    New."Code" := 'R2';
                    New.Name := 'added';
                    New.Insert(true);
                    CurrPage.Update(false);
                end;
            }
            action(DeleteCurrent)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.Delete(true);
                end;
            }
            action(DeleteCurrentAndUpdate)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.Delete(true);
                    CurrPage.Update(false);
                end;
            }
            action(Refill)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    New: Record "TPM Row";
                begin
                    New.DeleteAll(false);
                    New."Code" := 'N1';
                    New.Insert(false);
                    New."Code" := 'N2';
                    New.Insert(false);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "TPM Log";
    begin
        Log.Add('P-OOP:' + Rec."Code");
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "TPM Log";
    begin
        Log.AddRow('P-AGR:' + Rec."Code");
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "TPM Log";
    begin
        Log.Add('P-AGC:' + Rec."Code");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "TPM Log";
    begin
        Log.Add('P-NEW:' + Rec."Code");
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Log: Codeunit "TPM Log";
    begin
        Log.Add('P-INS:' + Rec."Code");
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    var
        Log: Codeunit "TPM Log";
    begin
        Log.Add('P-MOD:' + Rec."Code");
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    var
        Log: Codeunit "TPM Log";
    begin
        Log.Add('P-DEL:' + Rec."Code");
        exit(true);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "TPM Log";
    begin
        Log.Add('P-QC:' + Format(CloseAction));
        exit(true);
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "TPM Log";
    begin
        Log.Add('P-CLOSE:' + Rec."Code");
    end;
}

codeunit 97404 "TPM Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        RowReads: Integer;
        LastRow: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ' ';
    end;

    // OnAfterGetRecord runs for every row a window reads: count them, log the first and the last one
    procedure AddRow(Entry: Text)
    begin
        RowReads += 1;
        if RowReads = 1 then
            Entries += Entry + ' ';
        LastRow := Entry;
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        if RowReads > 1 then
            Result += '... ' + LastRow + ' (' + Format(RowReads) + ' reads)';
        Entries := '';
        RowReads := 0;
        LastRow := '';
        Result := Result.TrimEnd();
    end;
}

codeunit 97405 "TPM Plain Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "TPM Log";

    local procedure Seed(Count: Integer)
    var
        Row: Record "TPM Row";
        i: Integer;
    begin
        Row.DeleteAll(false);
        for i := 1 to Count do begin
            Row.Init();
            Row."Code" := 'R' + Format(i);
            Row.Name := 'name' + Format(i);
            Row.Amount := i;
            Row.Insert(false);
        end;
        Log.Take();
    end;

    local procedure Rows(): Text
    var
        Row: Record "TPM Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Row."Code" + '=' + Row.Name + '/' + Format(Row.Amount) + ' ';
            until Row.Next() = 0;
        exit(Result.TrimEnd());
    end;

    local procedure Shown(var P: TestPage "TPM Plain List"): Text
    begin
        exit(P."Code".Value() + '|' + P.Name.Value());
    end;

    [TryFunction]
    local procedure TrySetName(var P: TestPage "TPM Plain List"; Value: Text)
    begin
        P.Name.SetValue(Value);
    end;

    [TryFunction]
    local procedure TrySetCode(var P: TestPage "TPM Plain List"; Value: Text)
    begin
        P."Code".SetValue(Value);
    end;

    [Test]
    procedure TPM_Plain_OpenEdit_ShowsFirstRow_TriggerOrder()
    var
        P: TestPage "TPM Plain List";
    begin
        Seed(3);
        P.OpenEdit();
        Observer.Observe('shown after OpenEdit', Shown(P));
        Observer.Observe('log after OpenEdit', Log.Take());
        P.Close();
        Observer.Observe('log after Close', Log.Take());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure TPM_Plain_OpenView_ShowsFirstRow_SetValueRefused()
    var
        P: TestPage "TPM Plain List";
    begin
        Seed(3);
        P.OpenView();
        Observer.Observe('shown after OpenView', Shown(P));
        Observer.Observe('log after OpenView', Log.Take());
        Observer.Observe('editable', Format(P.Name.Editable()));
        if not TrySetName(P, 'viewed') then
            Observer.ObserveError('SetValue in view mode');
        Observer.Observe('log after SetValue', Log.Take());
        P.Close();
        Observer.Observe('log after Close', Log.Take());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure TPM_Plain_OpenNew_BlankRow_NothingInserted()
    var
        P: TestPage "TPM Plain List";
    begin
        Seed(3);
        P.OpenNew();
        Observer.Observe('shown after OpenNew', Shown(P));
        Observer.Observe('log after OpenNew', Log.Take());
        P.Close();
        Observer.Observe('log after Close', Log.Take());
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure TPM_Plain_OpenNew_KeyAndNameThenClose_InsertsRow()
    var
        P: TestPage "TPM Plain List";
    begin
        Seed(3);
        P.OpenNew();
        Log.Take();
        Observer.Observe('set Code ok', Format(TrySetCode(P, 'X1')));
        Observer.Observe('log after Code', Log.Take());
        Observer.Observe('rows after Code', Rows());
        Observer.Observe('set Name ok', Format(TrySetName(P, 'nx')));
        Observer.Observe('log after Name', Log.Take());
        Observer.Observe('rows after Name', Rows());
        P.Close();
        Observer.Observe('log after Close', Log.Take());
        Observer.Observe('rows after Close', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure TPM_Plain_OpenEdit_NewThenFirst_InsertsRowAtLeave()
    var
        P: TestPage "TPM Plain List";
    begin
        Seed(3);
        P.OpenEdit();
        Log.Take();
        P.New();
        Observer.Observe('log after New', Log.Take());
        Observer.Observe('shown after New', Shown(P));
        TrySetCode(P, 'X1');
        Observer.Observe('log after Code', Log.Take());
        Observer.Observe('rows before leaving', Rows());
        Observer.Observe('First', Format(P.First()));
        Observer.Observe('log after First', Log.Take());
        Observer.Observe('shown after First', Shown(P));
        Observer.Observe('rows after First', Rows());
        P.Close();
        Observer.Observe('log after Close', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure TPM_Plain_OpenEdit_NewWithoutKeyThenNext_ErrorText()
    var
        P: TestPage "TPM Plain List";
    begin
        Seed(3);
        P.OpenEdit();
        Log.Take();
        P.New();
        Log.Take();
        TrySetName(P, 'nokey');
        Log.Take();
        if not P.First() then
            Observer.ObserveError('First leaving a row with a blank key');
        Observer.Observe('log', Log.Take());
        Observer.Observe('rows', Rows());
        P.Close();
        Observer.Observe('log after Close', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure TPM_Plain_Navigation_FirstLastNextPrevious_ReturnValuesAndRows()
    var
        P: TestPage "TPM Plain List";
    begin
        Seed(3);
        P.OpenEdit();
        Log.Take();
        Observer.Observe('Last', Format(P.Last()) + ' ' + Shown(P));
        Observer.Observe('Next past the end', Format(P.Next()) + ' ' + Shown(P));
        Observer.Observe('Previous', Format(P.Previous()) + ' ' + Shown(P));
        Observer.Observe('Previous', Format(P.Previous()) + ' ' + Shown(P));
        Observer.Observe('Previous before the start', Format(P.Previous()) + ' ' + Shown(P));
        Observer.Observe('Next', Format(P.Next()) + ' ' + Shown(P));
        Observer.Observe('First', Format(P.First()) + ' ' + Shown(P));
        Observer.Observe('log', Log.Take());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TPM_Plain_GoToKeyAndGoToRecord_FoundAndMissing()
    var
        P: TestPage "TPM Plain List";
        Row: Record "TPM Row";
    begin
        Seed(3);
        P.OpenEdit();
        Log.Take();
        Observer.Observe('GoToKey R3', Format(P.GoToKey('R3')) + ' ' + Shown(P));
        Observer.Observe('GoToKey missing', Format(P.GoToKey('NOPE')) + ' ' + Shown(P));
        Row.Get('R2');
        Observer.Observe('GoToRecord R2', Format(P.GoToRecord(Row)) + ' ' + Shown(P));
        Row."Code" := 'NOPE';
        Observer.Observe('GoToRecord missing', Format(P.GoToRecord(Row)) + ' ' + Shown(P));
        Observer.Observe('log', Log.Take());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TPM_Plain_SetValue_Name_ModifiesRowAtOnceOrAtLeave()
    var
        P: TestPage "TPM Plain List";
    begin
        Seed(3);
        P.OpenEdit();
        P.GoToKey('R2');
        Log.Take();
        P.Name.SetValue('changed');
        Observer.Observe('log after SetValue', Log.Take());
        Observer.Observe('rows after SetValue', Rows());
        P.Next();
        Observer.Observe('log after Next', Log.Take());
        Observer.Observe('rows after Next', Rows());
        P.Close();
        Observer.Observe('log after Close', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure TPM_Plain_SetValue_FailingValidate_ErrorTextRowUnchanged()
    var
        P: TestPage "TPM Plain List";
    begin
        Seed(3);
        P.OpenEdit();
        P.GoToKey('R2');
        Log.Take();
        if not TrySetName(P, 'bad') then
            Observer.ObserveError('SetValue bad');
        Observer.Observe('log', Log.Take());
        Observer.Observe('shown', Shown(P));
        Observer.Observe('rows', Rows());
        P.Next();
        Observer.Observe('log after Next', Log.Take());
        Observer.Observe('rows after Next', Rows());
        P.Close();
        Observer.Observe('log after Close', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure TPM_Plain_SetValue_KeyOfExistingRow_ErrorTextAndRows()
    var
        P: TestPage "TPM Plain List";
    begin
        Seed(3);
        P.OpenEdit();
        P.New();
        Log.Take();
        TrySetCode(P, 'R1');
        Observer.Observe('log after Code R1', Log.Take());
        if not P.Next() then
            Observer.ObserveError('Next leaving the duplicate key');
        Observer.Observe('log', Log.Take());
        Observer.Observe('rows', Rows());
        Observer.Observe('shown', Shown(P));
        P.Close();
        Observer.Observe('log after Close', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure TPM_Plain_Action_InsertsRow_PageWithAndWithoutUpdate()
    var
        P: TestPage "TPM Plain List";
    begin
        Seed(1);
        P.OpenEdit();
        Log.Take();
        P.AddRow.Invoke();
        Observer.Observe('log after AddRow', Log.Take());
        Observer.Observe('shown', Shown(P));
        Observer.Observe('Next', Format(P.Next()) + ' ' + Shown(P));
        Observer.Observe('GoToKey R2', Format(P.GoToKey('R2')) + ' ' + Shown(P));
        P.Close();
        Seed(1);
        P.OpenEdit();
        Log.Take();
        P.AddRowAndUpdate.Invoke();
        Observer.Observe('log after AddRowAndUpdate', Log.Take());
        Observer.Observe('shown with update', Shown(P));
        Observer.Observe('Next with update', Format(P.Next()) + ' ' + Shown(P));
        Observer.Observe('rows', Rows());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TPM_Plain_Action_DeletesCurrentRow_ShownRowAfter()
    var
        P: TestPage "TPM Plain List";
    begin
        Seed(3);
        P.OpenEdit();
        P.GoToKey('R2');
        Log.Take();
        P.DeleteCurrent.Invoke();
        Observer.Observe('log after DeleteCurrent', Log.Take());
        Observer.Observe('shown', Shown(P));
        Observer.Observe('Next', Format(P.Next()) + ' ' + Shown(P));
        Observer.Observe('rows', Rows());
        P.Close();
        Seed(3);
        P.OpenEdit();
        P.GoToKey('R3');
        Log.Take();
        P.DeleteCurrentAndUpdate.Invoke();
        Observer.Observe('log after delete of the last row and update', Log.Take());
        Observer.Observe('shown after delete of the last row and update', Shown(P));
        Observer.Observe('Previous', Format(P.Previous()) + ' ' + Shown(P));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TPM_Plain_Action_RefillsAllRows_ShownRowAfter()
    var
        P: TestPage "TPM Plain List";
    begin
        Seed(3);
        P.OpenEdit();
        P.GoToKey('R2');
        Log.Take();
        P.Refill.Invoke();
        Observer.Observe('log after Refill', Log.Take());
        Observer.Observe('shown', Shown(P));
        Observer.Observe('First', Format(P.First()) + ' ' + Shown(P));
        Observer.Observe('Next', Format(P.Next()) + ' ' + Shown(P));
        Observer.Observe('GoToKey old row R2', Format(P.GoToKey('R2')));
        Observer.Observe('rows', Rows());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TPM_Plain_LongList_25Rows_OpenAndWalk()
    var
        P: TestPage "TPM Plain List";
        Count: Integer;
    begin
        Seed(25);
        P.OpenEdit();
        Observer.Observe('shown after OpenEdit', Shown(P));
        Observer.Observe('log after OpenEdit', Log.Take());
        Observer.Observe('Last', Format(P.Last()) + ' ' + Shown(P));
        Observer.Observe('log after Last', Log.Take());
        Observer.Observe('Previous', Format(P.Previous()) + ' ' + Shown(P));
        Observer.Observe('GoToKey R12', Format(P.GoToKey('R12')) + ' ' + Shown(P));
        Observer.Observe('GoToKey R25', Format(P.GoToKey('R25')) + ' ' + Shown(P));
        P.First();
        Count := 1;
        while P.Next() do
            Count += 1;
        Observer.Observe('rows walked with Next', Format(Count));
        Observer.Observe('shown at the end', Shown(P));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TPM_Plain_LongList_25Rows_ActionInsertsAndDeletes()
    var
        P: TestPage "TPM Plain List";
    begin
        Seed(25);
        P.OpenEdit();
        P.GoToKey('R22');
        Log.Take();
        P.AddRow.Invoke();
        Observer.Observe('log after AddRow', Log.Take());
        Observer.Observe('shown', Shown(P));
        Observer.Observe('GoToKey R2', Format(P.GoToKey('R2')) + ' ' + Shown(P));
        Observer.Observe('GoToKey R22', Format(P.GoToKey('R22')) + ' ' + Shown(P));
        P.DeleteCurrent.Invoke();
        Observer.Observe('shown after delete', Shown(P));
        Observer.Observe('GoToKey R22 after delete', Format(P.GoToKey('R22')));
        Observer.Observe('Next', Format(P.Next()) + ' ' + Shown(P));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TPM_Plain_LongList_25Rows_SetValueOnLastWindowRowThenClose()
    var
        P: TestPage "TPM Plain List";
    begin
        Seed(25);
        P.OpenEdit();
        P.GoToKey('R24');
        Log.Take();
        P.Name.SetValue('far');
        Observer.Observe('log after SetValue', Log.Take());
        P.Close();
        Observer.Observe('log after Close', Log.Take());
        Observer.Observe('R24', Rows().Substring(Rows().IndexOf('R24=')));
        Observer.Finish();
    end;

    // The list stays open when this test ends; the next test reads the row.
    [Test]
    procedure TPM_Plain_EndOfTest_LeftOpenAfterSetValue_Write()
    var
        P: TestPage "TPM Plain List";
    begin
        Seed(3);
        P.OpenEdit();
        P.GoToKey('R2');
        P.Name.SetValue('left open');
        Log.Take();
    end;

    [Test]
    procedure TPM_Plain_EndOfTest_LeftOpenAfterSetValue_Read()
    begin
        Observer.Observe('rows', Rows());
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;
}
