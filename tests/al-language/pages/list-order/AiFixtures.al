// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-update-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 78850 - 78859
// Probe: the order in which a list page calls OnFindRecord(Which), OnNextRecord(Steps), OnAfterGetRecord and OnAfterGetCurrRecord in situations F3ListTests.al does not pin.
// Log format: F:<Which> = OnFindRecord, N:<Steps>=<moved> = OnNextRecord, R:<no> = OnAfterGetRecord, C:<no> = OnAfterGetCurrRecord, A:<name> = an action step.
// BC versions: 27.0+

table 78850 "LT AI Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Qty; Integer) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 78851 "LT AI Log"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[100]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 78852 "LT AI Log Mgt"
{
    // The start key of the Pos list lives in the row with Id = -1 of the log table (no SingleInstance state).
    procedure SetStartKey(NewKey: Code[20])
    var
        Log: Record "LT AI Log";
    begin
        if Log.Get(-1) then
            Log.Delete();
        if NewKey = '' then
            exit;
        Log.Init();
        Log.Id := -1;
        Log.Txt := NewKey;
        Log.Insert();
    end;

    procedure GetStartKey(): Code[20]
    var
        Log: Record "LT AI Log";
    begin
        if Log.Get(-1) then
            exit(CopyStr(Log.Txt, 1, 20));
    end;

    procedure Clear()
    var
        Log: Record "LT AI Log";
    begin
        Log.SetFilter(Id, '>0');
        Log.DeleteAll();
    end;

    procedure Add(Value: Text)
    var
        Log: Record "LT AI Log";
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
        Log: Record "LT AI Log";
        Result: Text;
    begin
        Log.SetFilter(Id, '>0');
        if Log.FindSet() then
            repeat
                if Result <> '' then
                    Result += ';';
                Result += Log.Txt;
            until Log.Next() = 0;
        exit(Result);
    end;

    procedure Seed(Count: Integer)
    var
        Row: Record "LT AI Row";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to Count do begin
            Row.Init();
            Row."No." := 'R' + Format(1000 + i);
            Row.Qty := i;
            Row.Insert();
        end;
    end;
}

page 78853 "LT AI List"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "LT AI Row";

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
            action(KeepFilter)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT AI Log Mgt";
                begin
                    Log.Add('A:filter');
                    Rec.SetFilter(Qty, '<=%1', 4);
                    CurrPage.Update(false);
                    Log.Add('A:done');
                end;
            }
            action(SameView)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT AI Log Mgt";
                begin
                    Log.Add('A:update');
                    CurrPage.Update(false);
                    Log.Add('A:done');
                end;
            }
            action(DropCurrentRowsAfter)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT AI Log Mgt";
                begin
                    Log.Add('A:filter');
                    Rec.SetFilter(Qty, '>%1', Rec.Qty);
                    CurrPage.Update(false);
                    Log.Add('A:done');
                end;
            }
            action(DropCurrentNoRowsAfter)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT AI Log Mgt";
                begin
                    Log.Add('A:filter');
                    Rec.SetFilter(Qty, '<%1', Rec.Qty);
                    CurrPage.Update(false);
                    Log.Add('A:done');
                end;
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT AI Log Mgt";
        Found: Boolean;
    begin
        Found := Rec.Find(Which);
        Log.Add('F:' + Which + '=' + Format(Found));
        exit(Found);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Log: Codeunit "LT AI Log Mgt";
        Moved: Integer;
    begin
        Moved := Rec.Next(Steps);
        Log.Add('N:' + Format(Steps) + '=' + Format(Moved));
        exit(Moved);
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT AI Log Mgt";
    begin
        Log.Add('R:' + Rec."No.");
    end;
}

page 78854 "LT AI List Curr"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "LT AI Row";

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
            action(KeepFilter)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT AI Log Mgt";
                begin
                    Log.Add('A:filter');
                    Rec.SetFilter(Qty, '<=%1', 4);
                    CurrPage.Update(false);
                    Log.Add('A:done');
                end;
            }
            action(SameView)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT AI Log Mgt";
                begin
                    Log.Add('A:update');
                    CurrPage.Update(false);
                    Log.Add('A:done');
                end;
            }
            action(DropCurrentRowsAfter)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT AI Log Mgt";
                begin
                    Log.Add('A:filter');
                    Rec.SetFilter(Qty, '>%1', Rec.Qty);
                    CurrPage.Update(false);
                    Log.Add('A:done');
                end;
            }
            action(DropCurrentNoRowsAfter)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT AI Log Mgt";
                begin
                    Log.Add('A:filter');
                    Rec.SetFilter(Qty, '<%1', Rec.Qty);
                    CurrPage.Update(false);
                    Log.Add('A:done');
                end;
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT AI Log Mgt";
        Found: Boolean;
    begin
        Found := Rec.Find(Which);
        Log.Add('F:' + Which + '=' + Format(Found));
        exit(Found);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Log: Codeunit "LT AI Log Mgt";
        Moved: Integer;
    begin
        Moved := Rec.Next(Steps);
        Log.Add('N:' + Format(Steps) + '=' + Format(Moved));
        exit(Moved);
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT AI Log Mgt";
    begin
        Log.Add('R:' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT AI Log Mgt";
    begin
        Log.Add('C:' + Rec."No.");
    end;
}

page 78855 "LT AI List FindOnly"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "LT AI Row";

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
            action(KeepFilter)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT AI Log Mgt";
                begin
                    Log.Add('A:filter');
                    Rec.SetFilter(Qty, '<=%1', 4);
                    CurrPage.Update(false);
                    Log.Add('A:done');
                end;
            }
            action(SameView)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT AI Log Mgt";
                begin
                    Log.Add('A:update');
                    CurrPage.Update(false);
                    Log.Add('A:done');
                end;
            }
            action(DropCurrentRowsAfter)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT AI Log Mgt";
                begin
                    Log.Add('A:filter');
                    Rec.SetFilter(Qty, '>%1', Rec.Qty);
                    CurrPage.Update(false);
                    Log.Add('A:done');
                end;
            }
            action(DropCurrentNoRowsAfter)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT AI Log Mgt";
                begin
                    Log.Add('A:filter');
                    Rec.SetFilter(Qty, '<%1', Rec.Qty);
                    CurrPage.Update(false);
                    Log.Add('A:done');
                end;
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT AI Log Mgt";
        Found: Boolean;
    begin
        Found := Rec.Find(Which);
        Log.Add('F:' + Which + '=' + Format(Found));
        exit(Found);
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT AI Log Mgt";
    begin
        Log.Add('R:' + Rec."No.");
    end;
}

page 78856 "LT AI List Plain"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "LT AI Row";

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
            action(KeepFilter)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT AI Log Mgt";
                begin
                    Log.Add('A:filter');
                    Rec.SetFilter(Qty, '<=%1', 4);
                    CurrPage.Update(false);
                    Log.Add('A:done');
                end;
            }
            action(SameView)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT AI Log Mgt";
                begin
                    Log.Add('A:update');
                    CurrPage.Update(false);
                    Log.Add('A:done');
                end;
            }
            action(DropCurrentRowsAfter)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT AI Log Mgt";
                begin
                    Log.Add('A:filter');
                    Rec.SetFilter(Qty, '>%1', Rec.Qty);
                    CurrPage.Update(false);
                    Log.Add('A:done');
                end;
            }
            action(DropCurrentNoRowsAfter)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT AI Log Mgt";
                begin
                    Log.Add('A:filter');
                    Rec.SetFilter(Qty, '<%1', Rec.Qty);
                    CurrPage.Update(false);
                    Log.Add('A:done');
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT AI Log Mgt";
    begin
        Log.Add('R:' + Rec."No.");
    end;
}

page 78857 "LT AI List PlainCurr"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "LT AI Row";

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
            action(KeepFilter)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT AI Log Mgt";
                begin
                    Log.Add('A:filter');
                    Rec.SetFilter(Qty, '<=%1', 4);
                    CurrPage.Update(false);
                    Log.Add('A:done');
                end;
            }
            action(SameView)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT AI Log Mgt";
                begin
                    Log.Add('A:update');
                    CurrPage.Update(false);
                    Log.Add('A:done');
                end;
            }
            action(DropCurrentRowsAfter)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT AI Log Mgt";
                begin
                    Log.Add('A:filter');
                    Rec.SetFilter(Qty, '>%1', Rec.Qty);
                    CurrPage.Update(false);
                    Log.Add('A:done');
                end;
            }
            action(DropCurrentNoRowsAfter)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT AI Log Mgt";
                begin
                    Log.Add('A:filter');
                    Rec.SetFilter(Qty, '<%1', Rec.Qty);
                    CurrPage.Update(false);
                    Log.Add('A:done');
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT AI Log Mgt";
    begin
        Log.Add('R:' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT AI Log Mgt";
    begin
        Log.Add('C:' + Rec."No.");
    end;
}

page 78858 "LT AI List Pos"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "LT AI Row";

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
            action(KeepFilter)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT AI Log Mgt";
                begin
                    Log.Add('A:filter');
                    Rec.SetFilter(Qty, '<=%1', 4);
                    CurrPage.Update(false);
                    Log.Add('A:done');
                end;
            }
            action(SameView)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT AI Log Mgt";
                begin
                    Log.Add('A:update');
                    CurrPage.Update(false);
                    Log.Add('A:done');
                end;
            }
            action(DropCurrentRowsAfter)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT AI Log Mgt";
                begin
                    Log.Add('A:filter');
                    Rec.SetFilter(Qty, '>%1', Rec.Qty);
                    CurrPage.Update(false);
                    Log.Add('A:done');
                end;
            }
            action(DropCurrentNoRowsAfter)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT AI Log Mgt";
                begin
                    Log.Add('A:filter');
                    Rec.SetFilter(Qty, '<%1', Rec.Qty);
                    CurrPage.Update(false);
                    Log.Add('A:done');
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT AI Log Mgt";
    begin
        if Log.GetStartKey() <> '' then begin
            Rec."No." := Log.GetStartKey();
            Rec.SetPosition(Rec.GetPosition());
            Rec.Get(Log.GetStartKey());
        end;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT AI Log Mgt";
        Found: Boolean;
    begin
        Found := Rec.Find(Which);
        Log.Add('F:' + Which + '=' + Format(Found));
        exit(Found);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Log: Codeunit "LT AI Log Mgt";
        Moved: Integer;
    begin
        Moved := Rec.Next(Steps);
        Log.Add('N:' + Format(Steps) + '=' + Format(Moved));
        exit(Moved);
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT AI Log Mgt";
    begin
        Log.Add('R:' + Rec."No.");
    end;
}
