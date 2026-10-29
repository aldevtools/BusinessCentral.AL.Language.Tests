// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sourcetabletemporary-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 90390, 90391, 90402, 90405 (writer UJ)
// Probe: a List page over a temporary source table without the new-row line (InsertAllowed = false, ModifyAllowed = false, DeleteAllowed =
//   false) that holds one row. An action deletes every row of Rec and rebuilds it: nothing, three other rows, one row with another key, or one
//   row with the same key; with and without CurrPage.Update(false); OpenEdit and OpenView; run modally through a ModalPageHandler (the shape of
//   a history list whose actions load another period). After the action: the control value, First / Next / Last, a filter set on the TestPage
//   (Filter.SetFilter) and First, and the triggers that ran (log: R:<key> = OnAfterGetRecord, C:<key> = OnAfterGetCurrRecord).
// Source: al-runner issue 6180 (a history list over a temporary table; "a list without the new-row line that lost its only row to an action").
// BC versions: 27, 28, 29

table 90390 "LT UJ Hist Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Field No."; Integer) { }
        field(3; "Old Value"; Text[30]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

codeunit 90405 "LT UJ Hist Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        UpdateAfterAction: Boolean;

    procedure Reset(NewUpdate: Boolean)
    begin
        Entries := '';
        UpdateAfterAction := NewUpdate;
    end;

    procedure UpdateAfter(): Boolean
    begin
        exit(UpdateAfterAction);
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

page 90391 "LT UJ Hist List"
{
    PageType = List;
    SourceTable = "LT UJ Hist Row";
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
            repeater(Rows)
            {
                field(EntryNoCtl; Rec."Entry No.") { }
                field(FieldNoCtl; Rec."Field No.") { }
                field(OldValueCtl; Rec."Old Value") { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(EmptyAll)
            {
                trigger OnAction()
                begin
                    Rec.Reset();
                    Rec.DeleteAll();
                    Finish();
                end;
            }
            action(ThreeNewRows)
            {
                trigger OnAction()
                begin
                    Rec.Reset();
                    Rec.DeleteAll();
                    AddRow(21, 7, 'twenty-one');
                    AddRow(22, 8, 'twenty-two');
                    AddRow(23, 7, 'twenty-three');
                    Rec.FindFirst();
                    Finish();
                end;
            }
            action(ThreeNewRowsNoFind)
            {
                trigger OnAction()
                begin
                    Rec.Reset();
                    Rec.DeleteAll();
                    AddRow(21, 7, 'twenty-one');
                    AddRow(22, 8, 'twenty-two');
                    AddRow(23, 7, 'twenty-three');
                    Finish();
                end;
            }
            action(OneOtherKey)
            {
                trigger OnAction()
                begin
                    Rec.Reset();
                    Rec.DeleteAll();
                    AddRow(9, 7, 'nine');
                    Finish();
                end;
            }
            action(OneSameKey)
            {
                trigger OnAction()
                begin
                    Rec.Reset();
                    Rec.DeleteAll();
                    AddRow(1, 7, 'one again');
                    Finish();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        Rec.DeleteAll();
        AddRow(1, 7, 'one');
        Rec.FindFirst();
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT UJ Hist Log";
    begin
        Log.Add('R:' + Format(Rec."Entry No."));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT UJ Hist Log";
    begin
        Log.Add('C:' + Format(Rec."Entry No."));
    end;

    local procedure AddRow(EntryNo: Integer; FieldNo: Integer; OldValue: Text[30])
    begin
        Rec.Init();
        Rec."Entry No." := EntryNo;
        Rec."Field No." := FieldNo;
        Rec."Old Value" := OldValue;
        Rec.Insert();
    end;

    local procedure Finish()
    var
        Log: Codeunit "LT UJ Hist Log";
    begin
        if Log.UpdateAfter() then
            CurrPage.Update(false);
    end;
}

codeunit 90402 "LT UJ Temp List Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT UJ Hist Log";
        ModalAction: Text;

    local procedure Invoke(var H: TestPage "LT UJ Hist List"; ActionName: Text)
    begin
        case ActionName of
            'EmptyAll':
                H.EmptyAll.Invoke();
            'ThreeNewRows':
                H.ThreeNewRows.Invoke();
            'ThreeNewRowsNoFind':
                H.ThreeNewRowsNoFind.Invoke();
            'OneOtherKey':
                H.OneOtherKey.Invoke();
            'OneSameKey':
                H.OneSameKey.Invoke();
        end;
    end;

    local procedure Current(var H: TestPage "LT UJ Hist List"): Text
    begin
        exit(H.EntryNoCtl.Value() + '/' + H.OldValueCtl.Value());
    end;

    // Everything the page shows after the action; the steps are written in the order they run.
    local procedure AfterAction(var H: TestPage "LT UJ Hist List"): Text
    var
        Result: Text;
        Rows: Text;
        More: Boolean;
    begin
        Result := 'cur=' + Current(H);
        Result += '|first=' + Format(H.First()) + ':' + Current(H);
        More := true;
        while More do begin
            Rows += Current(H) + ',';
            More := H.Next();
        end;
        Result += '|rows=' + Rows;
        Result += '|last=' + Format(H.Last()) + ':' + Current(H);
        Result += '|next=' + Format(H.Next());
        exit(Result);
    end;

    local procedure RunCase(ActionName: Text; UpdateAfter: Boolean; Edit: Boolean): Text
    var
        H: TestPage "LT UJ Hist List";
        Before: Text;
        Result: Text;
    begin
        Log.Reset(UpdateAfter);
        if Edit then
            H.OpenEdit()
        else
            H.OpenView();
        Before := Current(H);
        Log.Add('invoke');
        Invoke(H, ActionName);
        Result := 'open=' + Before + '|' + AfterAction(H) + '|log=' + Log.Take();
        H.Close();
        exit(Result);
    end;

    [Test]
    procedure UJ_Temp_List_EmptyAll()
    begin
        Observer.Observe('edit no update', RunCase('EmptyAll', false, true));
        Observer.Observe('edit update', RunCase('EmptyAll', true, true));
        Observer.Observe('view no update', RunCase('EmptyAll', false, false));
        Observer.Observe('view update', RunCase('EmptyAll', true, false));
        Observer.Finish();
    end;

    [Test]
    procedure UJ_Temp_List_ThreeNewRows()
    begin
        Observer.Observe('edit no update', RunCase('ThreeNewRows', false, true));
        Observer.Observe('edit update', RunCase('ThreeNewRows', true, true));
        Observer.Observe('no find', RunCase('ThreeNewRowsNoFind', false, true));
        Observer.Observe('no find update', RunCase('ThreeNewRowsNoFind', true, true));
        Observer.Finish();
    end;

    [Test]
    procedure UJ_Temp_List_OneRowRebuilt()
    begin
        Observer.Observe('other key', RunCase('OneOtherKey', false, true));
        Observer.Observe('other key update', RunCase('OneOtherKey', true, true));
        Observer.Observe('same key', RunCase('OneSameKey', false, true));
        Observer.Observe('same key update', RunCase('OneSameKey', true, true));
        Observer.Finish();
    end;

    // The history list shape: modal, an action loads other rows, then the handler filters, goes to the first row and reads it.
    local procedure RunModalCase(ActionName: Text; FilterValue: Text): Text
    var
        H: Page "LT UJ Hist List";
    begin
        ModalAction := ActionName + '|' + FilterValue;
        Log.Reset(true);
        H.RunModal();
        exit(Log.Take());
    end;

    [ModalPageHandler]
    procedure HistoryHandler(var H: TestPage "LT UJ Hist List")
    var
        Result: Text;
        ActionName: Text;
        FilterValue: Text;
    begin
        ActionName := ModalAction.Substring(1, ModalAction.IndexOf('|') - 1);
        FilterValue := ModalAction.Substring(ModalAction.IndexOf('|') + 1);
        Invoke(H, ActionName);
        Result := 'after action=' + Current(H);
        H.Filter.SetFilter("Field No.", FilterValue);
        Result += '|first=' + Format(H.First()) + ':' + Current(H);
        Result += '|next=' + Format(H.Next()) + ':' + Current(H);
        Observer.Observe('handler ' + ModalAction, Result);
        H.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('HistoryHandler')]
    procedure UJ_Temp_List_Modal_FilterAfterRebuild()
    begin
        RunModalCase('ThreeNewRows', '7');
        RunModalCase('ThreeNewRows', '8');
        RunModalCase('ThreeNewRows', '5');
        RunModalCase('OneOtherKey', '7');
        RunModalCase('OneOtherKey', '8');
        RunModalCase('EmptyAll', '7');
        Observer.Finish();
    end;
}
