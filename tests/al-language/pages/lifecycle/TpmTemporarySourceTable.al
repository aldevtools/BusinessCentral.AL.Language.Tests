// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sourcetabletemporary-property
// Scope: in-scope (Cloud). TestPage and Page.Run with page handlers, no other UI handlers.
// local object: a list with SourceTableTemporary, the logging triggers and the table are what is under test; the log is a SingleInstance codeunit
// Fixtures used: Probe Observer (codeunit 69160); own objects 97480-97485, test codeunit 97485
// Area (TestPage lifecycle matrix, shape "temporary source table filled before open"): the rows come either from OnOpenPage (a TestPage
//   OpenEdit / OpenView / OpenNew) or from a temporary record passed to Page.Run and shown to a [PageHandler]. Cells: First, Last, Next,
//   Previous, GoToKey, GoToRecord, SetValue (valid), New with a key, an action that deletes and refills the temporary rows with and
//   without CurrPage.Update, a control bound to an expression, Close and the close at the end of a test; 3 rows and 25 rows (more than one
//   window). Each cell Observes the shown row, whether the real table or the passed record changed, the trigger order and the error text.
// BC versions: 27, 28, 29

table 97480 "TPM Tmp Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Name; Text[30]) { }
        field(3; Amount; Integer) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }

    trigger OnInsert()
    var
        Log: Codeunit "TPM Tmp Log";
    begin
        Log.Add('T-I:' + "Code");
    end;

    trigger OnModify()
    var
        Log: Codeunit "TPM Tmp Log";
    begin
        Log.Add('T-M:' + "Code");
    end;
}

page 97481 "TPM Tmp List"
{
    PageType = List;
    SourceTable = "TPM Tmp Row";
    SourceTableTemporary = true;
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
                field(Shout; Rec.Name + '!') { ApplicationArea = All; Editable = false; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Refill)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Fill(2, 'n');
                    CurrPage.Update(false);
                end;
            }
            action(RefillNoUpdate)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Fill(2, 'n');
                end;
            }
            action(DeleteCurrent)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.Delete(false);
                end;
            }
        }
    }

    local procedure Fill(Count: Integer; Prefix: Text)
    var
        i: Integer;
    begin
        Rec.Reset();
        Rec.DeleteAll(false);
        for i := 1 to Count do begin
            Rec.Init();
            Rec."Code" := UpperCase(Prefix) + Format(i);
            Rec.Name := Prefix + Format(i);
            Rec.Amount := i;
            Rec.Insert(false);
        end;
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "TPM Tmp Log";
    begin
        if Log.FillCount() > 0 then
            Fill(Log.FillCount(), 'o');
        Log.Add('P-OOP:' + Rec."Code");
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "TPM Tmp Log";
    begin
        Log.Add('P-AGC:' + Rec."Code");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "TPM Tmp Log";
    begin
        Log.Add('P-NEW:' + Rec."Code");
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Log: Codeunit "TPM Tmp Log";
    begin
        Log.Add('P-INS:' + Rec."Code");
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    var
        Log: Codeunit "TPM Tmp Log";
    begin
        Log.Add('P-MOD:' + Rec."Code");
        exit(true);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "TPM Tmp Log";
    begin
        Log.Add('P-QC:' + Format(CloseAction));
        exit(true);
    end;
}

codeunit 97484 "TPM Tmp Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        Rows: Integer;

    procedure FillCount(): Integer
    begin
        exit(Rows);
    end;

    procedure SetFillCount(Count: Integer)
    begin
        Rows := Count;
    end;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ' ';
    end;

    procedure Take() Result: Text
    begin
        Result := Entries.TrimEnd();
        Entries := '';
    end;
}

codeunit 97485 "TPM Tmp Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "TPM Tmp Log";
        HandlerCase: Text;

    local procedure RealRows(): Text
    var
        Row: Record "TPM Tmp Row";
    begin
        exit(Format(Row.Count()));
    end;

    local procedure Shown(var P: TestPage "TPM Tmp List"): Text
    begin
        exit(P."Code".Value() + '|' + P.Name.Value() + '|' + P.Shout.Value());
    end;

    local procedure Dump(var Temp: Record "TPM Tmp Row" temporary): Text
    var
        Result: Text;
    begin
        Temp.Reset();
        if Temp.FindSet() then
            repeat
                Result += Temp."Code" + '=' + Temp.Name + ' ';
            until Temp.Next() = 0;
        exit(Result.TrimEnd());
    end;

    local procedure FillTemp(var Temp: Record "TPM Tmp Row" temporary; Count: Integer)
    var
        i: Integer;
    begin
        Temp.DeleteAll(false);
        for i := 1 to Count do begin
            Temp.Init();
            Temp."Code" := 'R' + Format(i);
            Temp.Name := 'name' + Format(i);
            Temp.Amount := i;
            Temp.Insert(false);
        end;
        Log.Take();
    end;

    [TryFunction]
    local procedure TrySetName(var P: TestPage "TPM Tmp List"; Value: Text)
    begin
        P.Name.SetValue(Value);
    end;

    [TryFunction]
    local procedure TrySetCode(var P: TestPage "TPM Tmp List"; Value: Text)
    begin
        P."Code".SetValue(Value);
    end;

    // Rows made in OnOpenPage

    [Test]
    procedure TPM_Temp_OpenEdit_NothingFilled_ShowsBlankRow()
    var
        P: TestPage "TPM Tmp List";
    begin
        Log.SetFillCount(0);
        Log.Take();
        P.OpenEdit();
        Observer.Observe('shown', Shown(P));
        Observer.Observe('First', Format(P.First()));
        Observer.Observe('Next', Format(P.Next()));
        Observer.Observe('log after OpenEdit', Log.Take());
        P.Close();
        Observer.Observe('real rows', RealRows());
        Observer.Finish();
    end;

    [Test]
    procedure TPM_Temp_OpenEditAndOpenView_3Rows_ShownRowAndTriggers()
    var
        P: TestPage "TPM Tmp List";
    begin
        Log.SetFillCount(3);
        Log.Take();
        P.OpenEdit();
        Observer.Observe('OpenEdit shown', Shown(P));
        Observer.Observe('OpenEdit log', Log.Take());
        P.Close();
        Observer.Observe('Close log', Log.Take());
        P.OpenView();
        Observer.Observe('OpenView shown', Shown(P));
        Observer.Observe('OpenView log', Log.Take());
        if not TrySetName(P, 'viewed') then
            Observer.ObserveError('SetValue in view mode');
        P.Close();
        Observer.Observe('real rows', RealRows());
        Observer.Finish();
    end;

    [Test]
    procedure TPM_Temp_OpenNew_3Rows_BlankRowAndNothingStored()
    var
        P: TestPage "TPM Tmp List";
    begin
        Log.SetFillCount(3);
        Log.Take();
        P.OpenNew();
        Observer.Observe('shown', Shown(P));
        Observer.Observe('log after OpenNew', Log.Take());
        Observer.Observe('Code ok', Format(TrySetCode(P, 'X1')));
        Observer.Observe('log after Code', Log.Take());
        P.Close();
        Observer.Observe('log after Close', Log.Take());
        Observer.Observe('real rows', RealRows());
        Observer.Finish();
    end;

    [Test]
    procedure TPM_Temp_Navigation_3Rows_ReturnValuesAndShownRow()
    var
        P: TestPage "TPM Tmp List";
    begin
        Log.SetFillCount(3);
        P.OpenEdit();
        Log.Take();
        Observer.Observe('Last', Format(P.Last()) + ' ' + Shown(P));
        Observer.Observe('Next past the end', Format(P.Next()) + ' ' + Shown(P));
        Observer.Observe('Previous', Format(P.Previous()) + ' ' + Shown(P));
        Observer.Observe('Previous', Format(P.Previous()) + ' ' + Shown(P));
        Observer.Observe('Previous before the start', Format(P.Previous()) + ' ' + Shown(P));
        Observer.Observe('First', Format(P.First()) + ' ' + Shown(P));
        Observer.Observe('log', Log.Take());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TPM_Temp_GoToKeyAndGoToRecord_3Rows_FoundAndMissing()
    var
        P: TestPage "TPM Tmp List";
        Row: Record "TPM Tmp Row" temporary;
    begin
        Log.SetFillCount(3);
        P.OpenEdit();
        Log.Take();
        Observer.Observe('GoToKey O3', Format(P.GoToKey('O3')) + ' ' + Shown(P));
        Observer.Observe('GoToKey missing', Format(P.GoToKey('NOPE')) + ' ' + Shown(P));
        Row."Code" := 'O2';
        Observer.Observe('GoToRecord O2', Format(P.GoToRecord(Row)) + ' ' + Shown(P));
        Row."Code" := 'NOPE';
        Observer.Observe('GoToRecord missing', Format(P.GoToRecord(Row)) + ' ' + Shown(P));
        Observer.Observe('log', Log.Take());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TPM_Temp_SetValue_Name_ChangesTheTemporaryRowOnly()
    var
        P: TestPage "TPM Tmp List";
    begin
        Log.SetFillCount(3);
        P.OpenEdit();
        P.GoToKey('O2');
        Log.Take();
        Observer.Observe('Name ok', Format(TrySetName(P, 'changed')));
        Observer.Observe('shown', Shown(P));
        Observer.Observe('log after SetValue', Log.Take());
        P.Next();
        P.Previous();
        Observer.Observe('shown after Next and Previous', Shown(P));
        Observer.Observe('log after Next and Previous', Log.Take());
        P.Close();
        Observer.Observe('real rows', RealRows());
        Observer.Finish();
    end;

    [Test]
    procedure TPM_Temp_New_KeyAndName_RowAddedToTheTemporaryRowsOnly()
    var
        P: TestPage "TPM Tmp List";
    begin
        Log.SetFillCount(3);
        P.OpenEdit();
        Log.Take();
        P.New();
        Observer.Observe('log after New', Log.Take());
        Observer.Observe('Code ok', Format(TrySetCode(P, 'X1')));
        Observer.Observe('Name ok', Format(TrySetName(P, 'nx')));
        Observer.Observe('log after SetValue', Log.Take());
        Observer.Observe('First', Format(P.First()));
        Observer.Observe('log after First', Log.Take());
        Observer.Observe('GoToKey X1', Format(P.GoToKey('X1')) + ' ' + Shown(P));
        Observer.Observe('Last', Format(P.Last()) + ' ' + Shown(P));
        P.Close();
        Observer.Observe('real rows', RealRows());
        Observer.Finish();
    end;

    [Test]
    procedure TPM_Temp_Action_RefillWithUpdate_ShownRowAndGoToKey()
    var
        P: TestPage "TPM Tmp List";
    begin
        Log.SetFillCount(3);
        P.OpenEdit();
        P.GoToKey('O2');
        Log.Take();
        P.Refill.Invoke();
        Observer.Observe('log after Refill', Log.Take());
        Observer.Observe('shown', Shown(P));
        Observer.Observe('First', Format(P.First()) + ' ' + Shown(P));
        Observer.Observe('Next', Format(P.Next()) + ' ' + Shown(P));
        Observer.Observe('GoToKey N2', Format(P.GoToKey('N2')) + ' ' + Shown(P));
        Observer.Observe('GoToKey O2 (gone)', Format(P.GoToKey('O2')));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TPM_Temp_Action_RefillWithoutUpdate_ShownRowAndExpressionControl()
    var
        P: TestPage "TPM Tmp List";
    begin
        Log.SetFillCount(3);
        P.OpenEdit();
        P.GoToKey('O2');
        Log.Take();
        P.RefillNoUpdate.Invoke();
        Observer.Observe('log after RefillNoUpdate', Log.Take());
        Observer.Observe('shown', Shown(P));
        Observer.Observe('First', Format(P.First()) + ' ' + Shown(P));
        Observer.Observe('log after First', Log.Take());
        Observer.Observe('Next', Format(P.Next()) + ' ' + Shown(P));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TPM_Temp_Action_DeleteCurrent_ShownRowAfter()
    var
        P: TestPage "TPM Tmp List";
    begin
        Log.SetFillCount(3);
        P.OpenEdit();
        P.GoToKey('O2');
        Log.Take();
        P.DeleteCurrent.Invoke();
        Observer.Observe('log after DeleteCurrent', Log.Take());
        Observer.Observe('shown', Shown(P));
        Observer.Observe('Next', Format(P.Next()) + ' ' + Shown(P));
        Observer.Observe('GoToKey O2 (deleted)', Format(P.GoToKey('O2')));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TPM_Temp_25Rows_OpenWalkGoToKeyAndRefill()
    var
        P: TestPage "TPM Tmp List";
        Count: Integer;
    begin
        Log.SetFillCount(25);
        P.OpenEdit();
        Observer.Observe('shown', Shown(P));
        Observer.Observe('Last', Format(P.Last()) + ' ' + Shown(P));
        Observer.Observe('GoToKey O12', Format(P.GoToKey('O12')) + ' ' + Shown(P));
        Observer.Observe('GoToKey O25', Format(P.GoToKey('O25')) + ' ' + Shown(P));
        P.First();
        Count := 1;
        while P.Next() do
            Count += 1;
        Observer.Observe('rows walked with Next', Format(Count));
        P.GoToKey('O20');
        P.Refill.Invoke();
        Observer.Observe('shown after Refill', Shown(P));
        Observer.Observe('Last after Refill', Format(P.Last()) + ' ' + Shown(P));
        P.Close();
        Observer.Finish();
    end;

    // The list stays open when this test ends with a changed temporary row; the next test reads the real table.
    [Test]
    procedure TPM_Temp_EndOfTest_LeftOpenAfterSetValue_Write()
    var
        P: TestPage "TPM Tmp List";
    begin
        Log.SetFillCount(3);
        P.OpenEdit();
        P.GoToKey('O2');
        P.Name.SetValue('left open');
        Log.Take();
    end;

    [Test]
    procedure TPM_Temp_EndOfTest_LeftOpenAfterSetValue_Read()
    begin
        Observer.Observe('real rows', RealRows());
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    // A temporary record passed to Page.Run, seen by a page handler

    [Test]
    [HandlerFunctions('RunHandler')]
    procedure TPM_Temp_PageRun_3Rows_HandlerSeesRowsAndSetValueReachesTheRecord()
    var
        Temp: Record "TPM Tmp Row" temporary;
    begin
        Log.SetFillCount(0);
        FillTemp(Temp, 3);
        HandlerCase := 'a';
        Page.Run(Page::"TPM Tmp List", Temp);
        Observer.Observe('record after Run', Dump(Temp));
        Observer.Observe('log after Run', Log.Take());
        Observer.Observe('real rows', RealRows());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('RunHandler')]
    procedure TPM_Temp_PageRun_25Rows_HandlerWalksAndGoesToKey()
    var
        Temp: Record "TPM Tmp Row" temporary;
    begin
        Log.SetFillCount(0);
        FillTemp(Temp, 25);
        HandlerCase := 'b';
        Page.Run(Page::"TPM Tmp List", Temp);
        Observer.Observe('log after Run', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('RunHandler')]
    procedure TPM_Temp_PageRun_PositionedRecord_OpensOnTheRecordOrTheFirstRow()
    var
        Temp: Record "TPM Tmp Row" temporary;
    begin
        Log.SetFillCount(0);
        FillTemp(Temp, 3);
        Temp.Get('R3');
        HandlerCase := 'c';
        Page.Run(Page::"TPM Tmp List", Temp);
        Observer.Observe('log after Run', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('RunHandler')]
    procedure TPM_Temp_PageRun_FilteredRecord_HandlerSeesOnlyFilteredRows()
    var
        Temp: Record "TPM Tmp Row" temporary;
    begin
        Log.SetFillCount(0);
        FillTemp(Temp, 5);
        Temp.SetFilter("Code", 'R2..R4');
        HandlerCase := 'd';
        Page.Run(Page::"TPM Tmp List", Temp);
        Observer.Observe('log after Run', Log.Take());
        Observer.Finish();
    end;

    [PageHandler]
    procedure RunHandler(var P: TestPage "TPM Tmp List")
    var
        Count: Integer;
    begin
        Observer.Observe(HandlerCase + ' shown on open', Shown(P));
        case HandlerCase of
            'a':
                begin
                    Observer.Observe('a GoToKey R2', Format(P.GoToKey('R2')) + ' ' + Shown(P));
                    Observer.Observe('a Name ok', Format(TrySetName(P, 'changed')));
                    Observer.Observe('a Last', Format(P.Last()) + ' ' + Shown(P));
                    Observer.Observe('a log', Log.Take());
                end;
            'b':
                begin
                    Observer.Observe('b Last', Format(P.Last()) + ' ' + Shown(P));
                    Observer.Observe('b GoToKey R12', Format(P.GoToKey('R12')) + ' ' + Shown(P));
                    P.First();
                    Count := 1;
                    while P.Next() do
                        Count += 1;
                    Observer.Observe('b rows walked with Next', Format(Count));
                end;
            'c':
                Observer.Observe('c Previous', Format(P.Previous()) + ' ' + Shown(P));
            'd':
                begin
                    Observer.Observe('d First', Format(P.First()) + ' ' + Shown(P));
                    Count := 1;
                    while P.Next() do
                        Count += 1;
                    Observer.Observe('d rows walked with Next', Format(Count));
                    Observer.Observe('d GoToKey R1 (outside the filter)', Format(P.GoToKey('R1')));
                end;
        end;
    end;
}
