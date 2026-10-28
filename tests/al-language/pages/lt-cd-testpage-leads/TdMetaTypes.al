// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sourcetableview-property
// Scope: in-scope
// Fixtures used: own objects 89790 - 89809 (writer TD)
// Facts: al-runner issue 6030 (follow-up to 5957): the SourceTableView text of Page Metadata for where(<field> = const(...)) and
//   where(<field> = filter(...)) on Decimal, BigInteger, Boolean, Code, Guid, Duration, DateTime and Time fields. Tests: SourceTableView_*
//   in CdTestPageLeads.al (codeunit LT CD TestPage Leads).
// BC versions: all (CI)

table 89790 "LT TD Meta Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Dec; Decimal) { }
        field(3; Big; BigInteger) { }
        field(4; Flag; Boolean) { }
        field(5; Cd; Code[10]) { }
        field(6; Gd; Guid) { }
        field(7; Dur; Duration) { }
        field(8; Dt; DateTime) { }
        field(9; Tm; Time) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 89791 "LT TD Meta Dec0"
{
    PageType = List;
    SourceTable = "LT TD Meta Row";
    ApplicationArea = All;
    UsageCategory = None;
    SourceTableView = where(Dec = const(0));

    layout
    {
        area(Content)
        {
            repeater(Rows) { field(IdCtl; Rec.Id) { ApplicationArea = All; } }
        }
    }
}

page 89792 "LT TD Meta Dec15"
{
    PageType = List;
    SourceTable = "LT TD Meta Row";
    ApplicationArea = All;
    UsageCategory = None;
    SourceTableView = where(Dec = const(1.5));

    layout
    {
        area(Content)
        {
            repeater(Rows) { field(IdCtl; Rec.Id) { ApplicationArea = All; } }
        }
    }
}

page 89793 "LT TD Meta DecNeg2"
{
    PageType = List;
    SourceTable = "LT TD Meta Row";
    ApplicationArea = All;
    UsageCategory = None;
    SourceTableView = where(Dec = const(-2));

    layout
    {
        area(Content)
        {
            repeater(Rows) { field(IdCtl; Rec.Id) { ApplicationArea = All; } }
        }
    }
}

page 89794 "LT TD Meta Big"
{
    PageType = List;
    SourceTable = "LT TD Meta Row";
    ApplicationArea = All;
    UsageCategory = None;
    SourceTableView = where(Big = const(5));

    layout
    {
        area(Content)
        {
            repeater(Rows) { field(IdCtl; Rec.Id) { ApplicationArea = All; } }
        }
    }
}

page 89795 "LT TD Meta Bool"
{
    PageType = List;
    SourceTable = "LT TD Meta Row";
    ApplicationArea = All;
    UsageCategory = None;
    SourceTableView = where(Flag = const(true));

    layout
    {
        area(Content)
        {
            repeater(Rows) { field(IdCtl; Rec.Id) { ApplicationArea = All; } }
        }
    }
}

page 89796 "LT TD Meta Code"
{
    PageType = List;
    SourceTable = "LT TD Meta Row";
    ApplicationArea = All;
    UsageCategory = None;
    SourceTableView = where(Cd = const('A1'));

    layout
    {
        area(Content)
        {
            repeater(Rows) { field(IdCtl; Rec.Id) { ApplicationArea = All; } }
        }
    }
}

page 89797 "LT TD Meta Guid"
{
    PageType = List;
    SourceTable = "LT TD Meta Row";
    ApplicationArea = All;
    UsageCategory = None;
    SourceTableView = where(Gd = const('00000000-0000-0000-0000-000000000001'));

    layout
    {
        area(Content)
        {
            repeater(Rows) { field(IdCtl; Rec.Id) { ApplicationArea = All; } }
        }
    }
}

page 89798 "LT TD Meta Dur"
{
    PageType = List;
    SourceTable = "LT TD Meta Row";
    ApplicationArea = All;
    UsageCategory = None;
    SourceTableView = where(Dur = const(1000));

    layout
    {
        area(Content)
        {
            repeater(Rows) { field(IdCtl; Rec.Id) { ApplicationArea = All; } }
        }
    }
}

page 89799 "LT TD Meta DateTime"
{
    PageType = List;
    SourceTable = "LT TD Meta Row";
    ApplicationArea = All;
    UsageCategory = None;
    SourceTableView = where(Dt = const(0DT));

    layout
    {
        area(Content)
        {
            repeater(Rows) { field(IdCtl; Rec.Id) { ApplicationArea = All; } }
        }
    }
}

page 89800 "LT TD Meta Time"
{
    PageType = List;
    SourceTable = "LT TD Meta Row";
    ApplicationArea = All;
    UsageCategory = None;
    SourceTableView = where(Tm = const(120000T));

    layout
    {
        area(Content)
        {
            repeater(Rows) { field(IdCtl; Rec.Id) { ApplicationArea = All; } }
        }
    }
}

page 89801 "LT TD Meta DecFilter"
{
    PageType = List;
    SourceTable = "LT TD Meta Row";
    ApplicationArea = All;
    UsageCategory = None;
    SourceTableView = where(Dec = filter(>0));

    layout
    {
        area(Content)
        {
            repeater(Rows) { field(IdCtl; Rec.Id) { ApplicationArea = All; } }
        }
    }
}

page 89802 "LT TD Meta DecRange"
{
    PageType = List;
    SourceTable = "LT TD Meta Row";
    ApplicationArea = All;
    UsageCategory = None;
    SourceTableView = where(Dec = filter(1.5..3));

    layout
    {
        area(Content)
        {
            repeater(Rows) { field(IdCtl; Rec.Id) { ApplicationArea = All; } }
        }
    }
}

page 89803 "LT TD Meta BigRange"
{
    PageType = List;
    SourceTable = "LT TD Meta Row";
    ApplicationArea = All;
    UsageCategory = None;
    SourceTableView = where(Big = filter(1..5));

    layout
    {
        area(Content)
        {
            repeater(Rows) { field(IdCtl; Rec.Id) { ApplicationArea = All; } }
        }
    }
}

page 89804 "LT TD Meta BoolFilter"
{
    PageType = List;
    SourceTable = "LT TD Meta Row";
    ApplicationArea = All;
    UsageCategory = None;
    SourceTableView = where(Flag = filter(true));

    layout
    {
        area(Content)
        {
            repeater(Rows) { field(IdCtl; Rec.Id) { ApplicationArea = All; } }
        }
    }
}

page 89805 "LT TD Meta CodeRange"
{
    PageType = List;
    SourceTable = "LT TD Meta Row";
    ApplicationArea = All;
    UsageCategory = None;
    SourceTableView = where(Cd = filter(A1..C9));

    layout
    {
        area(Content)
        {
            repeater(Rows) { field(IdCtl; Rec.Id) { ApplicationArea = All; } }
        }
    }
}

page 89806 "LT TD Meta GuidFilter"
{
    PageType = List;
    SourceTable = "LT TD Meta Row";
    ApplicationArea = All;
    UsageCategory = None;
    SourceTableView = where(Gd = filter(<>''));

    layout
    {
        area(Content)
        {
            repeater(Rows) { field(IdCtl; Rec.Id) { ApplicationArea = All; } }
        }
    }
}

page 89807 "LT TD Meta DurFilter"
{
    PageType = List;
    SourceTable = "LT TD Meta Row";
    ApplicationArea = All;
    UsageCategory = None;
    SourceTableView = where(Dur = filter(>0));

    layout
    {
        area(Content)
        {
            repeater(Rows) { field(IdCtl; Rec.Id) { ApplicationArea = All; } }
        }
    }
}

page 89808 "LT TD Meta DtFilter"
{
    PageType = List;
    SourceTable = "LT TD Meta Row";
    ApplicationArea = All;
    UsageCategory = None;
    SourceTableView = where(Dt = filter(<>0DT));

    layout
    {
        area(Content)
        {
            repeater(Rows) { field(IdCtl; Rec.Id) { ApplicationArea = All; } }
        }
    }
}

page 89809 "LT TD Meta TmFilter"
{
    PageType = List;
    SourceTable = "LT TD Meta Row";
    ApplicationArea = All;
    UsageCategory = None;
    SourceTableView = where(Tm = filter(<>0T));

    layout
    {
        area(Content)
        {
            repeater(Rows) { field(IdCtl; Rec.Id) { ApplicationArea = All; } }
        }
    }
}
