// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-update-method
// Scope: in-scope
// Fixtures used: own objects 88900 - 88914 (writer RZ)
// Probe: fixtures of RzUpdateFromValidate.al, RzWorksheetSecondaryKeyOpen.al and RzRunPageLinkView.al (al-runner issues 5824, 5825, 5826).
// Log format (LT RZ Log, a table, no SingleInstance state): F:<Which>=<found> = OnFindRecord, N:<Steps>=<moved> = OnNextRecord,
//   R:<key> = OnAfterGetRecord, C:<key> = OnAfterGetCurrRecord, O:<key> = Rec at the end of OnOpenPage, A:<name> = a step of a field trigger.
// BC versions: 27, 28, 29

table 88900 "LT RZ Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Group Code"; Code[20]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 88901 "LT RZ Log"
{
    DataClassification = SystemMetadata;

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

codeunit 88902 "LT RZ Log Mgt"
{
    // The mode of the demand worksheet lives in the row with Id = -1 (a TestPage cannot call a page procedure before it opens).
    procedure SetMode(NewMode: Integer)
    var
        Log: Record "LT RZ Log";
    begin
        if Log.Get(-1) then
            Log.Delete();
        Log.Init();
        Log.Id := -1;
        Log.Txt := Format(NewMode);
        Log.Insert();
    end;

    procedure GetMode() Mode: Integer
    var
        Log: Record "LT RZ Log";
    begin
        if Log.Get(-1) then
            Evaluate(Mode, Log.Txt);
    end;

    procedure Clear()
    var
        Log: Record "LT RZ Log";
    begin
        Log.SetFilter(Id, '>0');
        Log.DeleteAll();
    end;

    procedure Add(Value: Text)
    var
        Log: Record "LT RZ Log";
        NextId: Integer;
    begin
        if Log.FindLast() then
            NextId := Log.Id;
        if NextId < 0 then
            NextId := 0;
        Log.Init();
        Log.Id := NextId + 1;
        Log.Txt := CopyStr(Value, 1, MaxStrLen(Log.Txt));
        Log.Insert();
    end;

    // The log so far, then cleared.
    procedure Take() Result: Text
    var
        Log: Record "LT RZ Log";
    begin
        Log.SetFilter(Id, '>0');
        if Log.FindSet() then
            repeat
                if Result <> '' then
                    Result += ';';
                Result += Log.Txt;
            until Log.Next() = 0;
        Log.DeleteAll();
    end;

    // Rows A G1, B G2, C G1, D G2, E G1, F G2 (the data of issue 5824).
    procedure SeedLines()
    var
        Line: Record "LT RZ Line";
    begin
        Line.DeleteAll();
        AddLine('A', 'G1');
        AddLine('B', 'G2');
        AddLine('C', 'G1');
        AddLine('D', 'G2');
        AddLine('E', 'G1');
        AddLine('F', 'G2');
    end;

    local procedure AddLine(No: Code[20]; GroupCode: Code[20])
    var
        Line: Record "LT RZ Line";
    begin
        Line.Init();
        Line."No." := No;
        Line."Group Code" := GroupCode;
        Line.Insert();
    end;
}

// A Worksheet with a header field whose OnValidate filters Rec and calls CurrPage.Update(false) (GroupFilter) or Update(true) (GroupFilterSave),
// and every record trigger logged, OnFindRecord and OnNextRecord included.
page 88903 "LT RZ Update Ws"
{
    PageType = Worksheet;
    SourceTable = "LT RZ Line";
    ApplicationArea = All;
    UsageCategory = None;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                field(GroupFilter; GroupFilter)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        ApplyFilter(GroupFilter, false);
                    end;
                }
                field(GroupFilterSave; GroupFilterSave)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        ApplyFilter(GroupFilterSave, true);
                    end;
                }
            }
            repeater(Lines)
            {
                Editable = false;
                field("No."; Rec."No.") { ApplicationArea = All; }
                field("Group Code"; Rec."Group Code") { ApplicationArea = All; }
            }
        }
    }

    var
        GroupFilter: Code[20];
        GroupFilterSave: Code[20];

    local procedure ApplyFilter(NewFilter: Code[20]; SaveRecord: Boolean)
    var
        Log: Codeunit "LT RZ Log Mgt";
    begin
        Log.Add('A:filter ' + Rec."No.");
        if NewFilter = '' then
            Rec.SetRange("Group Code")
        else
            Rec.SetRange("Group Code", NewFilter);
        CurrPage.Update(SaveRecord);
        Log.Add('A:done ' + Rec."No.");
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "LT RZ Log Mgt";
        Found: Boolean;
    begin
        Found := Rec.Find(Which);
        Log.Add('F:' + Which + '=' + Format(Found));
        exit(Found);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Log: Codeunit "LT RZ Log Mgt";
        Moved: Integer;
    begin
        Moved := Rec.Next(Steps);
        Log.Add('N:' + Format(Steps) + '=' + Format(Moved));
        exit(Moved);
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT RZ Log Mgt";
    begin
        Log.Add('R:' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT RZ Log Mgt";
    begin
        Log.Add('C:' + Rec."No.");
    end;
}

// The reporter's shape (issue 5824): no OnFindRecord and no OnNextRecord; OnAfterGetRecord and OnAfterGetCurrRecord are logged.
page 88904 "LT RZ Update Ws Plain"
{
    PageType = Worksheet;
    SourceTable = "LT RZ Line";
    ApplicationArea = All;
    UsageCategory = None;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                field(GroupFilter; GroupFilter)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        ApplyFilter(GroupFilter, false);
                    end;
                }
                field(GroupFilterSave; GroupFilterSave)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        ApplyFilter(GroupFilterSave, true);
                    end;
                }
            }
            repeater(Lines)
            {
                Editable = false;
                field("No."; Rec."No.") { ApplicationArea = All; }
                field("Group Code"; Rec."Group Code") { ApplicationArea = All; }
            }
        }
    }

    var
        GroupFilter: Code[20];
        GroupFilterSave: Code[20];

    local procedure ApplyFilter(NewFilter: Code[20]; SaveRecord: Boolean)
    var
        Log: Codeunit "LT RZ Log Mgt";
    begin
        Log.Add('A:filter ' + Rec."No.");
        if NewFilter = '' then
            Rec.SetRange("Group Code")
        else
            Rec.SetRange("Group Code", NewFilter);
        CurrPage.Update(SaveRecord);
        Log.Add('A:done ' + Rec."No.");
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT RZ Log Mgt";
    begin
        Log.Add('R:' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT RZ Log Mgt";
    begin
        Log.Add('C:' + Rec."No.");
    end;
}

// A List of the plain shape: the filter field is a repeater field that is not bound to the table (a List shows no header group).
page 88905 "LT RZ Update List Plain"
{
    PageType = List;
    SourceTable = "LT RZ Line";
    ApplicationArea = All;
    UsageCategory = None;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("No."; Rec."No.") { ApplicationArea = All; Editable = false; }
                field("Group Code"; Rec."Group Code") { ApplicationArea = All; Editable = false; }
                field(GroupFilter; GroupFilter)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    var
                        Log: Codeunit "LT RZ Log Mgt";
                    begin
                        Log.Add('A:filter ' + Rec."No.");
                        if GroupFilter = '' then
                            Rec.SetRange("Group Code")
                        else
                            Rec.SetRange("Group Code", GroupFilter);
                        CurrPage.Update(false);
                        Log.Add('A:done ' + Rec."No.");
                    end;
                }
            }
        }
    }

    var
        GroupFilter: Code[20];

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT RZ Log Mgt";
    begin
        Log.Add('R:' + Rec."No.");
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT RZ Log Mgt";
    begin
        Log.Add('C:' + Rec."No.");
    end;
}

table 88906 "LT RZ Demand Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Line No."; Integer) { }
        field(2; Level; Integer) { }
        field(3; "Item Code"; Code[20]) { }
    }

    keys
    {
        key(PK; "Line No.") { Clustered = true; }
        key(ByItem; "Item Code") { }
    }
}

// The shape of issue 5825 (page 1328 "Purch. Order From Sales Order"): a database Worksheet whose OnOpenPage fills the table through Rec,
// leaves Rec on a row under a key and then filters Level = 1.
// Rows (Line No., Level, Item Code): 10000 0 HDR, 20000 1 X, 25000 0 XM, 30000 1 Y, 40000 0 TRL, 50000 0 ZZZ.
//   By Item Code: HDR, TRL, X, XM, Y, ZZZ. The view (Level = 1): X, Y.
// Mode (from LT RZ Log Mgt.SetMode or SetMode below):
//   1 = SetCurrentKey("Item Code"), FindFirst: HDR, before the view in that key.
//   2 = SetCurrentKey("Item Code"), Get(30000): Y, inside the view, not its first row.
//   3 = SetCurrentKey("Item Code"), Get(50000): ZZZ, after the view in that key.
//   4 = SetCurrentKey("Item Code"), Get(25000): XM, between X and Y in that key.
//   5 = SetCurrentKey("Item Code"), Get(40000): TRL, before the view by Item Code, after it by Line No.
//   6 = SetCurrentKey("Item Code"), Get(20000): X, the first row of the view.
page 88907 "LT RZ Demand Ws"
{
    PageType = Worksheet;
    SourceTable = "LT RZ Demand Line";
    InsertAllowed = false;
    DeleteAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Level; Rec.Level) { ApplicationArea = All; }
                field("Item Code"; Rec."Item Code") { ApplicationArea = All; }
            }
        }
    }

    var
        Mode: Integer;

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT RZ Log Mgt";
    begin
        if Mode = 0 then
            Mode := Log.GetMode();
        Rec.DeleteAll();
        AddLine(10000, 0, 'HDR');
        AddLine(20000, 1, 'X');
        AddLine(25000, 0, 'XM');
        AddLine(30000, 1, 'Y');
        AddLine(40000, 0, 'TRL');
        AddLine(50000, 0, 'ZZZ');
        Rec.Reset();
        Rec.SetCurrentKey("Item Code");
        case Mode of
            1:
                Rec.FindFirst();
            2:
                Rec.Get(30000);
            3:
                Rec.Get(50000);
            4:
                Rec.Get(25000);
            5:
                Rec.Get(40000);
            6:
                Rec.Get(20000);
        end;
        Rec.SetRange(Level, 1);
        Log.Add('O:' + Rec."Item Code");
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT RZ Log Mgt";
    begin
        Log.Add('R:' + Rec."Item Code");
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT RZ Log Mgt";
    begin
        Log.Add('C:' + Rec."Item Code");
    end;

    local procedure AddLine(LineNo: Integer; NewLevel: Integer; ItemCode: Code[20])
    begin
        Rec.Init();
        Rec."Line No." := LineNo;
        Rec.Level := NewLevel;
        Rec."Item Code" := ItemCode;
        Rec.Insert();
    end;
}

codeunit 88908 "LT RZ Demand Runner"
{
    procedure RunLookup(NewMode: Integer; var Picked: Record "LT RZ Demand Line"): Action
    var
        DemandWs: Page "LT RZ Demand Ws";
        Result: Action;
    begin
        DemandWs.SetMode(NewMode);
        DemandWs.LookupMode(true);
        Result := DemandWs.RunModal();
        if Result = Action::LookupOK then
            DemandWs.GetRecord(Picked);
        exit(Result);
    end;

    procedure RunModalPlain(NewMode: Integer): Action
    var
        DemandWs: Page "LT RZ Demand Ws";
    begin
        DemandWs.SetMode(NewMode);
        exit(DemandWs.RunModal());
    end;
}

table 88909 "LT RZ Stock Item"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 88910 "LT RZ Stock Entry"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Item Code"; Code[20]) { }
        field(3; Quantity; Decimal) { }
        field(4; Positive; Boolean) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

// The host list of issue 5826: actions open an entry list through RunObject + RunPageLink "Item Code" = field("Code").
page 88911 "LT RZ Stock Items"
{
    PageType = List;
    SourceTable = "LT RZ Stock Item";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Items)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(NewestFirst)
            {
                ApplicationArea = All;
                RunObject = page "LT RZ Entries Newest First";
                RunPageLink = "Item Code" = field("Code");
            }
            action(PositiveOnly)
            {
                ApplicationArea = All;
                RunObject = page "LT RZ Positive Entries";
                RunPageLink = "Item Code" = field("Code");
            }
            action(PositiveNewestFirst)
            {
                ApplicationArea = All;
                RunObject = page "LT RZ Positive Newest First";
                RunPageLink = "Item Code" = field("Code");
            }
            // RunPageView beside the link, on a target whose SourceTableView sorts descending.
            action(NewestFirstViewAscending)
            {
                ApplicationArea = All;
                RunObject = page "LT RZ Entries Newest First";
                RunPageLink = "Item Code" = field("Code");
                RunPageView = sorting("Entry No.") order(ascending);
            }
            action(NewestFirstViewPositive)
            {
                ApplicationArea = All;
                RunObject = page "LT RZ Entries Newest First";
                RunPageLink = "Item Code" = field("Code");
                RunPageView = where(Positive = const(true));
            }
            // A link on the field the target's view filters too.
            action(PositiveLinkPositive)
            {
                ApplicationArea = All;
                RunObject = page "LT RZ Positive Entries";
                RunPageLink = "Item Code" = field("Code"), Positive = const(false);
            }
        }
    }
}

page 88912 "LT RZ Entries Newest First"
{
    PageType = List;
    SourceTable = "LT RZ Stock Entry";
    SourceTableView = sorting("Entry No.") order(descending);
    Editable = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Entries)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Item Code"; Rec."Item Code") { ApplicationArea = All; }
            }
        }
    }
}

page 88913 "LT RZ Positive Entries"
{
    PageType = List;
    SourceTable = "LT RZ Stock Entry";
    SourceTableView = where(Positive = const(true));
    Editable = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Entries)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Item Code"; Rec."Item Code") { ApplicationArea = All; }
            }
        }
    }
}

page 88914 "LT RZ Positive Newest First"
{
    PageType = List;
    SourceTable = "LT RZ Stock Entry";
    SourceTableView = sorting("Entry No.") order(descending) where(Positive = const(true));
    Editable = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Entries)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Item Code"; Rec."Item Code") { ApplicationArea = All; }
            }
        }
    }
}
