// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-update-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-setselectionfilter-method
// Scope: in-scope (Cloud). TestPage.
// Fixtures used: Probe Observer (codeunit 69160); own table 64785, log codeunit 64786, pages 64787 64788 64789, test codeunit 64790
// Probe: observe-only. Area: which row a page shows after CurrPage.Update when it stood on no row while its view has rows, and when the
//   row it stood on left its filters outside an action; and Page.SetSelectionFilter on a page that stands on no row of a table with rows.
//   Cells: a List opened on an empty table (new-row line) whose action inserts two rows through another record variable and runs
//   CurrPage.Update(false); the same after New() on a list with rows; a Card opened on an empty table with the same action; a List
//   filtered on Status (SourceTableView) whose Status control's OnValidate runs CurrPage.Update(true) or CurrPage.Update(false) after the
//   row left the filter; SetSelectionFilter in an action of a List on its new-row line (OpenNew) and after New().
//   Not pinned (al-runner refuses each with "CurrPage.Update on a page that shows no row ...", "CurrPage.Update on a list whose filters
//   left the row it stands on, outside an action", "Page.SetSelectionFilter of a page on no row of a table that has rows").
// Observed: the row shown after the step (Entry No., blank on the new-row line), whether the next move works, the log (R:<n>
//   OnAfterGetRecord, C:<n> OnAfterGetCurrRecord, N = OnNewRecord, A:<step>) and the stored rows.
// local object: the page triggers and the view filters are what the test checks
// BC versions: 27, 28, 29

table 64785 "PGA UR Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { DataClassification = SystemMetadata; }
        field(2; Status; Code[10]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

codeunit 64786 "PGA UR Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        UpdateSaves: Boolean;

    procedure Reset(NewUpdateSaves: Boolean)
    begin
        Entries := '';
        UpdateSaves := NewUpdateSaves;
    end;

    procedure Saves(): Boolean
    begin
        exit(UpdateSaves);
    end;

    procedure Add(Line: Text)
    begin
        if Entries <> '' then
            Entries += ';';
        Entries += Line;
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;

    procedure InsertTwo()
    var
        Row: Record "PGA UR Row";
    begin
        Row.Init();
        Row."Entry No." := 10;
        Row.Status := 'OPEN';
        if Row.Insert() then;
        Row."Entry No." := 20;
        if Row.Insert() then;
    end;
}

page 64787 "PGA UR List"
{
    PageType = List;
    SourceTable = "PGA UR Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
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
                    Log.Add('A:fill');
                    Log.InsertTwo();
                    CurrPage.Update(false);
                end;
            }
            action(Sel)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Row: Record "PGA UR Row";
                begin
                    CurrPage.SetSelectionFilter(Row);
                    Log.Add('A:sel(' + Format(Row.Count()) + ' ' + Row.GetFilters() + ')');
                end;
            }
        }
    }

    var
        Log: Codeunit "PGA UR Log";

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('N');
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Format(Rec."Entry No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Format(Rec."Entry No."));
    end;
}

page 64788 "PGA UR Open List"
{
    PageType = List;
    SourceTable = "PGA UR Row";
    SourceTableView = where(Status = const('OPEN'));
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('A:status(' + Rec.Status + ')');
                        CurrPage.Update(Log.Saves());
                    end;
                }
            }
        }
    }

    var
        Log: Codeunit "PGA UR Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Format(Rec."Entry No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Format(Rec."Entry No."));
    end;
}

page 64789 "PGA UR Card"
{
    PageType = Card;
    SourceTable = "PGA UR Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
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
                    Log.Add('A:fill');
                    Log.InsertTwo();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        Log: Codeunit "PGA UR Log";

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('N');
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Format(Rec."Entry No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Format(Rec."Entry No."));
    end;
}

codeunit 64790 "PGA UR Update Row Choice"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "PGA UR Log";

    local procedure Initialize(Count: Integer; UpdateSaves: Boolean)
    var
        Row: Record "PGA UR Row";
        i: Integer;
    begin
        Observer.Discard();
        Row.DeleteAll();
        for i := 1 to Count do begin
            Row.Init();
            Row."Entry No." := i;
            Row.Status := 'OPEN';
            Row.Insert();
        end;
        Log.Reset(UpdateSaves);
    end;

    local procedure Stored(): Text
    var
        Row: Record "PGA UR Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Format(Row."Entry No.") + ':' + Row.Status + ';';
            until Row.Next() = 0;
        exit('[' + Result + ']');
    end;

    [Test]
    procedure List_EmptyTable_ActionInsertsThenUpdateFalse()
    var
        P: TestPage "PGA UR List";
    begin
        Initialize(0, false);
        P.OpenEdit();
        Observer.Observe('log-open', Log.Take());
        P.Fill.Invoke();
        Observer.Observe('log-fill', Log.Take());
        Observer.Observe('shown', P."Entry No.".Value());
        Observer.Observe('next', Format(P.Next()));
        Observer.Observe('shown after next', P."Entry No.".Value());
        P.Close();
        Observer.Observe('stored', Stored());
        Observer.Finish();
    end;

    [Test]
    procedure List_NewLineAfterNew_ActionInsertsThenUpdateFalse()
    var
        P: TestPage "PGA UR List";
    begin
        Initialize(2, false);
        P.OpenEdit();
        P.New();
        Observer.Observe('log-new', Log.Take());
        P.Fill.Invoke();
        Observer.Observe('log-fill', Log.Take());
        Observer.Observe('shown', P."Entry No.".Value());
        P.Close();
        Observer.Observe('stored', Stored());
        Observer.Finish();
    end;

    [Test]
    procedure Card_EmptyTable_ActionInsertsThenUpdateFalse()
    var
        P: TestPage "PGA UR Card";
    begin
        Initialize(0, false);
        P.OpenEdit();
        Observer.Observe('log-open', Log.Take());
        P.Fill.Invoke();
        Observer.Observe('log-fill', Log.Take());
        Observer.Observe('shown', P."Entry No.".Value());
        Observer.Observe('next', Format(P.Next()));
        Observer.Observe('shown after next', P."Entry No.".Value());
        P.Close();
        Observer.Observe('stored', Stored());
        Observer.Finish();
    end;

    [Test]
    procedure FilteredList_RowLeavesFilter_UpdateTrueInOnValidate()
    var
        P: TestPage "PGA UR Open List";
    begin
        Initialize(3, true);
        P.OpenEdit();
        P.GoToKey(2);
        Log.Take();
        P.Status.SetValue('DONE');
        Observer.Observe('log-setvalue', Log.Take());
        Observer.Observe('shown', P."Entry No.".Value());
        P.Close();
        Observer.Observe('stored', Stored());
        Observer.Finish();
    end;

    [Test]
    procedure FilteredList_RowLeavesFilter_UpdateFalseInOnValidate()
    var
        P: TestPage "PGA UR Open List";
    begin
        Initialize(3, false);
        P.OpenEdit();
        P.GoToKey(2);
        Log.Take();
        P.Status.SetValue('DONE');
        Observer.Observe('log-setvalue', Log.Take());
        Observer.Observe('shown', P."Entry No.".Value());
        P.Close();
        Observer.Observe('stored', Stored());
        Observer.Finish();
    end;

    [Test]
    procedure List_OpenNewOnRows_SetSelectionFilterInAction()
    var
        P: TestPage "PGA UR List";
    begin
        Initialize(2, false);
        P.OpenNew();
        Log.Take();
        P.Sel.Invoke();
        Observer.Observe('log-sel', Log.Take());
        P.Close();
        Observer.Observe('stored', Stored());
        Observer.Finish();
    end;

    [Test]
    procedure List_NewLineAfterNew_SetSelectionFilterInAction()
    var
        P: TestPage "PGA UR List";
    begin
        Initialize(2, false);
        P.OpenEdit();
        P.Last();
        P.New();
        Log.Take();
        P.Sel.Invoke();
        Observer.Observe('log-sel', Log.Take());
        P.Close();
        Observer.Observe('stored', Stored());
        Observer.Finish();
    end;
}
