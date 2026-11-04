// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-pages-overview
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 67075 - 67082
// Probe: shared fixtures of the page probes in this folder: row table, log, list / card / dialog pages with open and close triggers, a list with find and next triggers, a deletable list
// BC versions: 27.0+

table 67075 "LT F3 Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[50]) { }
        field(3; Qty; Integer) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
        key(K2; Qty) { }
    }
}

table 67076 "LT F3 Log"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[250]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 67077 "LT F3 Log Mgt"
{
    procedure Clear()
    var
        Log: Record "LT F3 Log";
    begin
        Log.DeleteAll();
    end;

    procedure Add(Value: Text)
    var
        Log: Record "LT F3 Log";
        NextId: Integer;
    begin
        if Log.FindLast() then
            NextId := Log.Id;
        Log.Init();
        Log.Id := NextId + 1;
        Log.Txt := CopyStr(Value, 1, MaxStrLen(Log.Txt));
        Log.Insert();
    end;

    procedure Dump(): Text
    var
        Log: Record "LT F3 Log";
        Result: Text;
    begin
        if Log.FindSet() then
            repeat
                Result += Log.Txt + ' | ';
            until Log.Next() = 0;
        exit(Result);
    end;

    procedure Seed(Count: Integer)
    var
        Row: Record "LT F3 Row";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to Count do begin
            Row.Init();
            Row."No." := 'R' + Format(1000 + i);
            Row.Name := 'Name ' + Format(i);
            Row.Qty := i;
            Row.Insert();
        end;
    end;
}

page 67078 "LT F3 List"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "LT F3 Row";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT F3 Log Mgt";
    begin
        Log.Add('List.OnOpenPage');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "LT F3 Log Mgt";
    begin
        Log.Add('List.OnQueryClosePage(' + Format(CloseAction) + ')');
        exit(true);
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "LT F3 Log Mgt";
    begin
        Log.Add('List.OnClosePage');
    end;
}

page 67079 "LT F3 Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "LT F3 Row";

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT F3 Log Mgt";
    begin
        Log.Add('Card.OnOpenPage(' + Rec."No." + ')');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "LT F3 Log Mgt";
    begin
        Log.Add('Card.OnQueryClosePage(' + Format(CloseAction) + ')');
        exit(true);
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "LT F3 Log Mgt";
    begin
        Log.Add('Card.OnClosePage(' + Rec."No." + ')');
    end;
}

page 67080 "LT F3 Dialog"
{
    PageType = StandardDialog;
    ApplicationArea = All;
    SourceTable = "LT F3 Row";

    layout
    {
        area(Content)
        {
            field(NameCtl; Rec.Name) { ApplicationArea = All; }
            field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
        }
    }
}

// A list that logs the way the client reads it: OnFindRecord(Which) and OnNextRecord(Steps).
page 67081 "LT F3 Nav List"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "LT F3 Row";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OnlyBig)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT F3 Log Mgt";
                begin
                    Rec.SetFilter(Qty, '>=%1', 8);
                    CurrPage.Update(false);
                    Log.Add('OnlyBig done');
                end;
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT F3 Log Mgt";
        Found: Boolean;
    begin
        Found := Rec.Find(Which);
        Log.Add('Find(' + Which + ')=' + Format(Found));
        exit(Found);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Log: Codeunit "LT F3 Log Mgt";
        Moved: Integer;
    begin
        Moved := Rec.Next(Steps);
        Log.Add('Next(' + Format(Steps) + ')=' + Format(Moved));
        exit(Moved);
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT F3 Log Mgt";
    begin
        Log.Add('AGR(' + Rec."No." + ')');
    end;
}

// A list whose action deletes the current row without CurrPage.Update.
page 67082 "LT F3 Delete List"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "LT F3 Row";

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
            action(DeleteRow)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.Delete();
                end;
            }
            action(DeleteRowUpdate)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.Delete();
                    CurrPage.Update(false);
                end;
            }
            action(SelectionFilter)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Row: Record "LT F3 Row";
                    Log: Codeunit "LT F3 Log Mgt";
                begin
                    CurrPage.SetSelectionFilter(Row);
                    Log.Add('Selection count=' + Format(Row.Count()) + ' filter=[' + Row.GetFilters() + ']');
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT F3 Log Mgt";
    begin
        Log.Add('AGCR(' + Rec."No." + ')');
    end;

    procedure SelectedFilterCount(): Text
    var
        Row: Record "LT F3 Row";
    begin
        CurrPage.SetSelectionFilter(Row);
        exit('count=' + Format(Row.Count()) + ' filter=[' + Row.GetFilters() + ']');
    end;
}
