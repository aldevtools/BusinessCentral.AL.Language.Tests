// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope
// Fixtures used: self-contained table 73660 and pages 73661, 73662, 73663 (opened by the handler probes P131Handler*.al)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: none (three small pages with a source table, a public SetResult / GetResult pair and an OnOpenPage flag)
// BC versions: 29 (27 and 28 by CI)

table 73660 "LT P131 HRow"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[20]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 73661 "LT P131 Card"
{
    PageType = Card;
    SourceTable = "LT P131 HRow";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Name; Rec.Name)
            {
                ApplicationArea = All;
            }
        }
    }

    var
        ResultValue: Integer;
        OpenedCount: Integer;

    trigger OnOpenPage()
    begin
        OpenedCount += 1;
    end;

    procedure SetResult(Value: Integer)
    begin
        ResultValue := Value;
    end;

    procedure GetResult(): Integer
    begin
        exit(ResultValue);
    end;

    procedure GetOpened(): Integer
    begin
        exit(OpenedCount);
    end;
}

page 73662 "LT P131 List"
{
    PageType = List;
    SourceTable = "LT P131 HRow";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    var
        ResultValue: Integer;
        OpenedCount: Integer;

    trigger OnOpenPage()
    begin
        OpenedCount += 1;
    end;

    procedure SetResult(Value: Integer)
    begin
        ResultValue := Value;
    end;

    procedure GetResult(): Integer
    begin
        exit(ResultValue);
    end;

    procedure GetOpened(): Integer
    begin
        exit(OpenedCount);
    end;
}

page 73663 "LT P131 Nav"
{
    PageType = Card;
    SourceTable = "LT P131 HRow";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Name; Rec.Name)
            {
                ApplicationArea = All;
            }
        }
    }

    var
        ResultValue: Integer;
        OpenedCount: Integer;

    trigger OnOpenPage()
    begin
        OpenedCount += 1;
    end;

    procedure SetResult(Value: Integer)
    begin
        ResultValue := Value;
    end;

    procedure GetResult(): Integer
    begin
        exit(ResultValue);
    end;

    procedure GetOpened(): Integer
    begin
        exit(OpenedCount);
    end;
}
