// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-runpagelink-property
// Scope: in-scope
// Fixtures for the QZ_* tests in codeunit "ARLG Tests" (TestActionRunPageLinkFilterGroup.al): tables 87696 and 87697, pages 87698-87700,
//   log codeunit 87701 (SingleInstance, used only by codeunit "ARLG Tests").
// Facts: an action with RunObject and RunPageLink = field(..) (two link fields) or const(..): what Rec holds during the target page's OnOpenPage
//   (the linked field values, the other fields, GetFilters) and in its first OnAfterGetCurrRecord, for a List and a Card target, with and without
//   a matching row, opened through a PageHandler, a TestPage Trap, and with neither.

table 87696 "LT QZ RL Parent"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Number; Integer) { }
    }

    keys { key(PK; Code, Number) { Clustered = true; } }
}

table 87697 "LT QZ RL Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; ParentCode; Code[20]) { }
        field(2; ParentNumber; Integer) { }
        field(3; LineNo; Integer) { }
        field(4; Note; Text[30]) { }
    }

    keys { key(PK; ParentCode, ParentNumber, LineNo) { Clustered = true; } }
}

codeunit 87701 "LT QZ RL Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Clear()
    begin
        Entries := '';
    end;

    procedure Add(Value: Text)
    begin
        Entries += Value + ';';
    end;

    procedure Get(): Text
    begin
        exit(Entries);
    end;

    procedure Describe(Child: Record "LT QZ RL Child"): Text
    begin
        exit('code=' + Child.ParentCode + ' number=' + Format(Child.ParentNumber) + ' line=' + Format(Child.LineNo) + ' note=' + Child.Note + ' filters=' + Child.GetFilters());
    end;
}

page 87698 "LT QZ RL Child List"
{
    PageType = List;
    SourceTable = "LT QZ RL Child";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(LineNo; Rec.LineNo) { ApplicationArea = All; }
                field(Note; Rec.Note) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT QZ RL Log";
    begin
        Log.Add('list open ' + Log.Describe(Rec));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT QZ RL Log";
    begin
        Log.Add('list agcr ' + Log.Describe(Rec));
    end;
}

page 87699 "LT QZ RL Child Card"
{
    PageType = Card;
    SourceTable = "LT QZ RL Child";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(LineNo; Rec.LineNo) { ApplicationArea = All; }
            field(Note; Rec.Note) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT QZ RL Log";
    begin
        Log.Add('card open ' + Log.Describe(Rec));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT QZ RL Log";
    begin
        Log.Add('card agcr ' + Log.Describe(Rec));
    end;
}

page 87700 "LT QZ RL Parent Card"
{
    PageType = Card;
    SourceTable = "LT QZ RL Parent";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Code; Rec.Code) { ApplicationArea = All; }
            field(Number; Rec.Number) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ChildList)
            {
                ApplicationArea = All;
                RunObject = page "LT QZ RL Child List";
                RunPageLink = ParentCode = field(Code), ParentNumber = field(Number);
            }
            action(ChildCard)
            {
                ApplicationArea = All;
                RunObject = page "LT QZ RL Child Card";
                RunPageLink = ParentCode = field(Code), ParentNumber = field(Number);
            }
            action(ChildListConst)
            {
                ApplicationArea = All;
                RunObject = page "LT QZ RL Child List";
                RunPageLink = ParentCode = const('P1'), ParentNumber = const(7);
            }
        }
    }
}
