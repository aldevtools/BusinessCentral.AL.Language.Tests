// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onfindrecord-page-trigger
// Scope: in-scope (Cloud). TestPage only, no UI handlers.
// local object: the pages whose OnFindRecord and OnNextRecord serve the rows (one over a real table, one generating rows of a temporary table) and the logs of those triggers are what is under test; the log is a SingleInstance codeunit
// Fixtures used: Probe Observer (codeunit 69160); own objects 97460-97466, test codeunit 97466
// Area (TestPage lifecycle matrix, shape "OnFindRecord / OnNextRecord page"): OpenEdit, OpenView, OpenNew, New, First, Last, Next, Previous,
//   GoToKey and GoToRecord (found, missing, outside the generated range), SetValue on a field of a served row, an action that inserts,
//   deletes or refills the rows, Close and the close at the end of a test; a list served from a real table with 3 and with 25 rows (more
//   than one window) and a list that generates 30 rows. Each cell Observes the row the page shows, the calls of OnFindRecord (the Which
//   argument) and OnNextRecord (the Steps argument) in order, whether a row was inserted or modified, and the error text.
// BC versions: 27, 28, 29

table 97460 "TPM FR Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }

    trigger OnInsert()
    var
        Log: Codeunit "TPM FR Log";
    begin
        Log.Add('T-I:' + "Code");
    end;

    trigger OnModify()
    var
        Log: Codeunit "TPM FR Log";
    begin
        Log.Add('T-M:' + "Code");
    end;
}

table 97461 "TPM FR Gen"
{
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; Number; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Number) { Clustered = true; }
    }
}

page 97462 "TPM FR Passthrough"
{
    PageType = List;
    SourceTable = "TPM FR Row";
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
                    New: Record "TPM FR Row";
                begin
                    New."Code" := 'R2A';
                    New.Name := 'added';
                    New.Insert(true);
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

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "TPM FR Log";
    begin
        Log.Find(Which);
        exit(Rec.Find(Which));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Log: Codeunit "TPM FR Log";
    begin
        Log.Next(Steps);
        exit(Rec.Next(Steps));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "TPM FR Log";
    begin
        Log.Add('P-AGC:' + Rec."Code");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "TPM FR Log";
    begin
        Log.Add('P-NEW:' + Rec."Code");
    end;
}

page 97463 "TPM FR Generated"
{
    PageType = List;
    SourceTable = "TPM FR Gen";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Number; Rec.Number) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Grow)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "TPM FR Log";
                begin
                    Log.SetTotal(Log.GetTotal() + 5);
                    CurrPage.Update(false);
                end;
            }
            action(GrowNoUpdate)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "TPM FR Log";
                begin
                    Log.SetTotal(Log.GetTotal() + 5);
                end;
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "TPM FR Log";
        Target: Integer;
    begin
        Log.Find(Which);
        case Which of
            '-':
                Target := 1;
            '+':
                Target := Log.GetTotal();
            else
                Target := Rec.Number;
        end;
        if (Target < 1) or (Target > Log.GetTotal()) then
            exit(false);
        Rec.Number := Target;
        Rec.Name := 'g' + Format(Target);
        exit(true);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Log: Codeunit "TPM FR Log";
        Target: Integer;
    begin
        Log.Next(Steps);
        Target := Rec.Number + Steps;
        if Target < 1 then
            Target := 1;
        if Target > Log.GetTotal() then
            Target := Log.GetTotal();
        Steps := Target - Rec.Number;
        Rec.Number := Target;
        Rec.Name := 'g' + Format(Target);
        exit(Steps);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "TPM FR Log";
    begin
        Log.Add('P-NEW:' + Format(Rec.Number));
    end;
}

codeunit 97465 "TPM FR Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        Finds: Integer;
        Nexts: Integer;
        FindList: Text;
        NextList: Text;
        TotalRows: Integer;

    procedure GetTotal(): Integer
    begin
        if TotalRows = 0 then
            TotalRows := 30;
        exit(TotalRows);
    end;

    procedure SetTotal(NewTotal: Integer)
    begin
        TotalRows := NewTotal;
    end;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ' ';
    end;

    procedure Find(Which: Text)
    begin
        Finds += 1;
        if Finds <= 8 then
            FindList += Which + ',';
    end;

    procedure Next(Steps: Integer)
    begin
        Nexts += 1;
        if Nexts <= 8 then
            NextList += Format(Steps) + ',';
    end;

    procedure Take() Result: Text
    begin
        Result := Entries + 'Find x' + Format(Finds) + ' [' + FindList + '] Next x' + Format(Nexts) + ' [' + NextList + ']';
        Entries := '';
        Finds := 0;
        Nexts := 0;
        FindList := '';
        NextList := '';
    end;
}

codeunit 97466 "TPM FR Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "TPM FR Log";

    local procedure Seed(Count: Integer)
    var
        Row: Record "TPM FR Row";
        i: Integer;
    begin
        Row.DeleteAll(false);
        for i := 1 to Count do begin
            Row.Init();
            Row."Code" := 'R' + Format(i);
            Row.Name := 'name' + Format(i);
            Row.Insert(false);
        end;
        Log.Take();
    end;

    local procedure Rows(): Text
    var
        Row: Record "TPM FR Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Row."Code" + '=' + Row.Name + ' ';
            until Row.Next() = 0;
        exit(Result.TrimEnd());
    end;

    local procedure Shown(var P: TestPage "TPM FR Passthrough"): Text
    begin
        exit(P."Code".Value() + '|' + P.Name.Value());
    end;

    local procedure ShownGen(var P: TestPage "TPM FR Generated"): Text
    begin
        exit(P.Number.Value() + '|' + P.Name.Value());
    end;

    [TryFunction]
    local procedure TryGoToGenKey(var P: TestPage "TPM FR Generated"; Key: Integer)
    begin
        if not P.GoToKey(Key) then
            Error('GoToKey returned false');
    end;

    [TryFunction]
    local procedure TryOpenGenEdit(var P: TestPage "TPM FR Generated")
    begin
        P.OpenEdit();
    end;

    [TryFunction]
    local procedure TryNextGen(var P: TestPage "TPM FR Generated")
    begin
        P.Next();
    end;

    [TryFunction]
    local procedure TryPreviousGen(var P: TestPage "TPM FR Generated")
    begin
        P.Previous();
    end;

    [TryFunction]
    local procedure TrySetName(var P: TestPage "TPM FR Passthrough"; Value: Text)
    begin
        P.Name.SetValue(Value);
    end;

    [TryFunction]
    local procedure TrySetGenName(var P: TestPage "TPM FR Generated"; Value: Text)
    begin
        P.Name.SetValue(Value);
    end;

    [TryFunction]
    local procedure TrySetGenNumber(var P: TestPage "TPM FR Generated"; Value: Text)
    begin
        P.Number.SetValue(Value);
    end;

    // Passthrough list (OnFindRecord = Rec.Find, OnNextRecord = Rec.Next) over a real table

    [Test]
    procedure TPM_FindRecord_Passthrough_OpenEdit_3Rows_CallsAndShownRow()
    var
        P: TestPage "TPM FR Passthrough";
    begin
        Seed(3);
        P.OpenEdit();
        Observer.Observe('shown', Shown(P));
        Observer.Observe('log after OpenEdit', Log.Take());
        P.Close();
        Observer.Observe('log after Close', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure TPM_FindRecord_Passthrough_OpenView_OpenNew_ShownRow()
    var
        P: TestPage "TPM FR Passthrough";
    begin
        Seed(3);
        P.OpenView();
        Observer.Observe('OpenView shown', Shown(P));
        Observer.Observe('OpenView log', Log.Take());
        if not TrySetName(P, 'viewed') then
            Observer.ObserveError('SetValue in view mode');
        P.Close();
        P.OpenNew();
        Observer.Observe('OpenNew shown', Shown(P));
        Observer.Observe('OpenNew log', Log.Take());
        P.Close();
        Observer.Observe('rows', Rows());
        Observer.Finish();
    end;

    [Test]
    procedure TPM_FindRecord_Passthrough_Navigation_3Rows_ReturnValuesAndCalls()
    var
        P: TestPage "TPM FR Passthrough";
    begin
        Seed(3);
        P.OpenEdit();
        Log.Take();
        Observer.Observe('Last', Format(P.Last()) + ' ' + Shown(P));
        Observer.Observe('log after Last', Log.Take());
        Observer.Observe('Next past the end', Format(P.Next()) + ' ' + Shown(P));
        Observer.Observe('log after Next', Log.Take());
        Observer.Observe('Previous', Format(P.Previous()) + ' ' + Shown(P));
        Observer.Observe('Previous', Format(P.Previous()) + ' ' + Shown(P));
        Observer.Observe('Previous before the start', Format(P.Previous()) + ' ' + Shown(P));
        Observer.Observe('First', Format(P.First()) + ' ' + Shown(P));
        Observer.Observe('log after the rest', Log.Take());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TPM_FindRecord_Passthrough_GoToKeyAndGoToRecord_3Rows()
    var
        P: TestPage "TPM FR Passthrough";
        Row: Record "TPM FR Row";
    begin
        Seed(3);
        P.OpenEdit();
        Log.Take();
        Observer.Observe('GoToKey R3', Format(P.GoToKey('R3')) + ' ' + Shown(P));
        Observer.Observe('log', Log.Take());
        Observer.Observe('GoToKey missing', Format(P.GoToKey('NOPE')) + ' ' + Shown(P));
        Observer.Observe('log', Log.Take());
        Row.Get('R2');
        Observer.Observe('GoToRecord R2', Format(P.GoToRecord(Row)) + ' ' + Shown(P));
        Observer.Observe('log', Log.Take());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TPM_FindRecord_Passthrough_SetValue_ModifiesRow()
    var
        P: TestPage "TPM FR Passthrough";
    begin
        Seed(3);
        P.OpenEdit();
        P.GoToKey('R2');
        Log.Take();
        Observer.Observe('Name ok', Format(TrySetName(P, 'changed')));
        Observer.Observe('log after SetValue', Log.Take());
        Observer.Observe('rows after SetValue', Rows());
        P.Next();
        Observer.Observe('log after Next', Log.Take());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TPM_FindRecord_Passthrough_Action_InsertsAndDeletes_3Rows()
    var
        P: TestPage "TPM FR Passthrough";
    begin
        Seed(3);
        P.OpenEdit();
        P.GoToKey('R2');
        Log.Take();
        P.AddRow.Invoke();
        Observer.Observe('log after AddRow', Log.Take());
        Observer.Observe('shown', Shown(P));
        Observer.Observe('GoToKey R2A', Format(P.GoToKey('R2A')) + ' ' + Shown(P));
        Observer.Observe('log', Log.Take());
        P.DeleteCurrent.Invoke();
        Observer.Observe('shown after delete', Shown(P));
        Observer.Observe('log after delete', Log.Take());
        Observer.Observe('Next', Format(P.Next()) + ' ' + Shown(P));
        Observer.Observe('rows', Rows());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TPM_FindRecord_Passthrough_25Rows_OpenWalkAndGoToKey()
    var
        P: TestPage "TPM FR Passthrough";
        Count: Integer;
    begin
        Seed(25);
        P.OpenEdit();
        Observer.Observe('shown', Shown(P));
        Observer.Observe('log after OpenEdit', Log.Take());
        Observer.Observe('Last', Format(P.Last()) + ' ' + Shown(P));
        Observer.Observe('log after Last', Log.Take());
        Observer.Observe('GoToKey R12', Format(P.GoToKey('R12')) + ' ' + Shown(P));
        Observer.Observe('log after GoToKey', Log.Take());
        Observer.Observe('GoToKey R25', Format(P.GoToKey('R25')) + ' ' + Shown(P));
        P.First();
        Count := 1;
        while P.Next() do
            Count += 1;
        Observer.Observe('rows walked with Next', Format(Count));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TPM_FindRecord_Passthrough_25Rows_ActionInsertsRowGoToKeyOfIt()
    var
        P: TestPage "TPM FR Passthrough";
    begin
        Seed(25);
        P.OpenEdit();
        P.GoToKey('R22');
        Log.Take();
        P.AddRow.Invoke();
        Observer.Observe('log after AddRow', Log.Take());
        Observer.Observe('shown', Shown(P));
        Observer.Observe('GoToKey R2A', Format(P.GoToKey('R2A')) + ' ' + Shown(P));
        Observer.Observe('log', Log.Take());
        Observer.Observe('GoToKey R22', Format(P.GoToKey('R22')) + ' ' + Shown(P));
        P.Close();
        Observer.Finish();
    end;

    // Generated list: 30 rows made by OnFindRecord and OnNextRecord, temporary source table

    [Test]
    procedure TPM_FindRecord_Generated_OpenEdit_30Rows_CallsAndShownRow()
    var
        P: TestPage "TPM FR Generated";
    begin
        Log.SetTotal(30);
        Log.Take();
        P.OpenEdit();
        Observer.Observe('shown', ShownGen(P));
        Observer.Observe('log after OpenEdit', Log.Take());
        P.Close();
        Observer.Observe('log after Close', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure TPM_FindRecord_Generated_Navigation_30Rows_ReturnValuesAndCalls()
    var
        P: TestPage "TPM FR Generated";
    begin
        Log.SetTotal(30);
        P.OpenEdit();
        Log.Take();
        Observer.Observe('Next', Format(P.Next()) + ' ' + ShownGen(P));
        Observer.Observe('Last', Format(P.Last()) + ' ' + ShownGen(P));
        Observer.Observe('log after Last', Log.Take());
        Observer.Observe('Next past the end', Format(P.Next()) + ' ' + ShownGen(P));
        Observer.Observe('Previous', Format(P.Previous()) + ' ' + ShownGen(P));
        Observer.Observe('First', Format(P.First()) + ' ' + ShownGen(P));
        Observer.Observe('Previous before the start', Format(P.Previous()) + ' ' + ShownGen(P));
        Observer.Observe('log', Log.Take());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TPM_FindRecord_Generated_GoToKey_InsideAndOutsideTheRange()
    var
        P: TestPage "TPM FR Generated";
    begin
        Log.SetTotal(30);
        P.OpenEdit();
        Log.Take();
        Observer.Observe('GoToKey 17', Format(P.GoToKey(17)) + ' ' + ShownGen(P));
        Observer.Observe('log', Log.Take());
        Observer.Observe('GoToKey 30', Format(P.GoToKey(30)) + ' ' + ShownGen(P));
        Observer.Observe('GoToKey 31', Format(P.GoToKey(31)) + ' ' + ShownGen(P));
        Observer.Observe('GoToKey 0', Format(P.GoToKey(0)) + ' ' + ShownGen(P));
        Observer.Observe('log', Log.Take());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TPM_FindRecord_Generated_SetValue_NameOfServedRow()
    var
        P: TestPage "TPM FR Generated";
    begin
        Log.SetTotal(30);
        if not TryOpenGenEdit(P) then
            Observer.ObserveError('OpenEdit');
        if not TryGoToGenKey(P, 5) then
            Observer.ObserveError('GoToKey 5');
        Log.Take();
        Observer.Observe('Name ok', Format(TrySetGenName(P, 'typed')));
        Observer.Observe('shown after SetValue', ShownGen(P));
        Observer.Observe('log after SetValue', Log.Take());
        if not TryNextGen(P) then
            Observer.ObserveError('Next');
        if not TryPreviousGen(P) then
            Observer.ObserveError('Previous');
        Observer.Observe('shown after Next and Previous', ShownGen(P));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TPM_FindRecord_Generated_SetValue_NumberOfServedRow()
    var
        P: TestPage "TPM FR Generated";
    begin
        Log.SetTotal(30);
        if not TryOpenGenEdit(P) then
            Observer.ObserveError('OpenEdit');
        if not TryGoToGenKey(P, 5) then
            Observer.ObserveError('GoToKey 5');
        Log.Take();
        if not TrySetGenNumber(P, '9') then
            Observer.ObserveError('SetValue Number 9');
        Observer.Observe('shown', ShownGen(P));
        Observer.Observe('log', Log.Take());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TPM_FindRecord_Generated_Action_GrowsTheList_WithAndWithoutUpdate()
    var
        P: TestPage "TPM FR Generated";
    begin
        Log.SetTotal(30);
        P.OpenEdit();
        P.Last();
        Log.Take();
        P.GrowNoUpdate.Invoke();
        Observer.Observe('shown after GrowNoUpdate', ShownGen(P));
        Observer.Observe('log after GrowNoUpdate', Log.Take());
        Observer.Observe('Next', Format(P.Next()) + ' ' + ShownGen(P));
        Observer.Observe('log after Next', Log.Take());
        P.Grow.Invoke();
        Observer.Observe('shown after Grow', ShownGen(P));
        Observer.Observe('log after Grow', Log.Take());
        Observer.Observe('Last', Format(P.Last()) + ' ' + ShownGen(P));
        Observer.Observe('GoToKey 40', Format(P.GoToKey(40)) + ' ' + ShownGen(P));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TPM_FindRecord_Generated_OpenNew_NewRowAndNewMethod()
    var
        P: TestPage "TPM FR Generated";
    begin
        Log.SetTotal(30);
        P.OpenNew();
        Observer.Observe('OpenNew shown', ShownGen(P));
        Observer.Observe('OpenNew log', Log.Take());
        P.Close();
        P.OpenEdit();
        Log.Take();
        P.New();
        Observer.Observe('New shown', ShownGen(P));
        Observer.Observe('New log', Log.Take());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TPM_FindRecord_Generated_OpenView_SetValueRefused()
    var
        P: TestPage "TPM FR Generated";
    begin
        Log.SetTotal(30);
        P.OpenView();
        Observer.Observe('shown', ShownGen(P));
        if not TrySetGenName(P, 'viewed') then
            Observer.ObserveError('SetValue in view mode');
        P.Close();
        Observer.Finish();
    end;
}
