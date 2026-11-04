// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-part-control
// Scope: in-scope
// Fixtures used: own tables and pages
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a header card with a lines part; inserting a line runs table code that modifies the header (Info and Counter), so the header row stored changes after the card read it.
// BC versions: 29 (27 and 28 by CI)

table 71490 "LT Chg Head"
{
    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Descr; Text[30]) { }
        field(3; Info; Text[30]) { }
        field(4; Counter; Integer) { }
    }
    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 71491 "LT Chg Line"
{
    fields
    {
        field(1; "Head Code"; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Descr; Text[30]) { }
    }
    keys
    {
        key(PK; "Head Code", "Line No.") { Clustered = true; }
    }

    trigger OnInsert()
    var
        Head: Record "LT Chg Head";
    begin
        Head.Get("Head Code");
        Head.Counter += 1;
        Head.Info := 'by line insert';
        Head.Modify();
    end;
}

page 71492 "LT Chg Lines"
{
    PageType = ListPart;
    SourceTable = "LT Chg Line";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(LineNoF; Rec."Line No.") { ApplicationArea = All; }
                field(DescrF; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}

page 71493 "LT Chg Card"
{
    PageType = Card;
    SourceTable = "LT Chg Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(CodeF; Rec."Code") { ApplicationArea = All; }
            field(DescrF; Rec.Descr) { ApplicationArea = All; }
            field(InfoF; Rec.Info) { ApplicationArea = All; }
            field(CounterF; Rec.Counter) { ApplicationArea = All; }
            part(Lines; "LT Chg Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Head Code" = field("Code");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SaveRow)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    CurrPage.SaveRecord();
                end;
            }
            action(ModifyRow)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.Descr := 'by action';
                    Rec.Modify(true);
                end;
            }
        }
    }
}
