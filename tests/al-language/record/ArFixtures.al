// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-data-type
// Scope: in-scope
// Fixtures used: none (the tables of the LT AR record probes, corpus issue 643)
// BC versions: 27, 28, 29

table 79800 "LT AR Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Pic; Media) { }
        field(4; Pics; MediaSet) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    var
        Counter: Integer;

    procedure Bump()
    begin
        Counter += 1;
    end;

    procedure GetCounter(): Integer
    begin
        exit(Counter);
    end;
}

table 79801 "LT AR Other"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

// FlowFilter FltA is declared before the FlowField Cnt, FlowFilter FltB after it, and the FlowField Total after FltB.
table 79802 "LT AR Fmt"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; FltA; Integer)
        {
            FieldClass = FlowFilter;
        }
        field(3; Cnt; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT AR Fmt Line" where(Owner = field(Id)));
        }
        field(4; FltB; Integer)
        {
            FieldClass = FlowFilter;
        }
        field(5; Name; Text[10]) { }
        field(6; Total; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT AR Fmt Line".Qty where(Owner = field(Id)));
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 79803 "LT AR Fmt Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Owner; Integer) { }
        field(3; Qty; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}
