// Fixture objects of the AZ query probes (corpus issue 651, writer AZ); the tests are in AzQueryTests.al.

table 80660 "LT AZ Q Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Cat; Code[10]) { }
        field(3; Sub; Code[10]) { }
        field(4; Amount; Decimal) { }
        field(5; Kind; Code[10]) { }
        field(6; Ref; RecordId) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 80661 "LT AZ Q Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Cat; Code[10]) { }
        field(2; Lines; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT AZ Q Row" where(Cat = field(Cat), Kind = field("Kind Filter")));
        }
        field(3; "Kind Filter"; Code[10]) { FieldClass = FlowFilter; }
        field(4; Grp; Code[10]) { }
    }

    keys
    {
        key(PK; Cat) { Clustered = true; }
    }
}

// Groups by Cat and Sub, no OrderBy (item 1).
query 80662 "LT AZ Q Two Groups"
{
    elements
    {
        dataitem(Row; "LT AZ Q Row")
        {
            column(Cat; Cat) { }
            column(Sub; Sub) { }
            column(Total; Amount) { Method = Sum; }
        }
    }
}

// Groups by Cat only, Sum and Count, no OrderBy (item 1).
query 80663 "LT AZ Q One Group"
{
    elements
    {
        dataitem(Row; "LT AZ Q Row")
        {
            column(Cat; Cat) { }
            column(Total; Amount) { Method = Sum; }
            column(N) { Method = Count; }
        }
    }
}

// Sum over a count FlowField, grouped by Grp (item 3).
query 80664 "LT AZ Q Sum Count FF"
{
    elements
    {
        dataitem(Head; "LT AZ Q Head")
        {
            filter(KindFilter; "Kind Filter") { }
            column(Grp; Grp) { }
            column(SumLines; Lines) { Method = Sum; }
            column(N) { Method = Count; }
        }
    }
}

// Sum over a count FlowField, not grouped (item 3).
query 80665 "LT AZ Q Sum Count FF All"
{
    elements
    {
        dataitem(Head; "LT AZ Q Head")
        {
            filter(KindFilter; "Kind Filter") { }
            filter(CatFilter; Cat) { }
            column(SumLines; Lines) { Method = Sum; }
        }
    }
}

// A RecordId column grouped with Count, ordered by the RecordId (item 5).
query 80666 "LT AZ Q Rid Group"
{
    OrderBy = descending(Ref);

    elements
    {
        dataitem(Row; "LT AZ Q Row")
        {
            column(Ref; Ref) { }
            column(N) { Method = Count; }
        }
    }
}

// A plain RecordId column (item 5: SetFilter, SaveAsCsv).
query 80667 "LT AZ Q Rid Plain"
{
    OrderBy = ascending(Id);

    elements
    {
        dataitem(Row; "LT AZ Q Row")
        {
            column(Id; Id) { }
            column(Ref; Ref) { }
        }
    }
}

// A procedure that reads a filter element by its bare name (item 7).
query 80668 "LT AZ Q Filter Proc"
{
    elements
    {
        dataitem(Row; "LT AZ Q Row")
        {
            filter(KindF; Kind) { }
            column(Id; Id) { }
        }
    }

    procedure ReadKindF(): Text
    begin
        exit('[' + Format(KindF) + ']');
    end;
}

// Plain rows for TopNumberOfRows and SecurityFiltering after Open (item 8).
query 80669 "LT AZ Q Rows"
{
    OrderBy = ascending(Id);

    elements
    {
        dataitem(Row; "LT AZ Q Row")
        {
            column(Id; Id) { }
        }
    }
}

// Writer SG (al-runtime-rs assumption grouped-query-ties-in-grouping-order): aggregated queries whose OrderBy column most groups share.
// Grouping columns Sub, Cat (declared in that order, unlike the table's field order), OrderBy Kind.
query 89090 "LT SG Q Ties SubCat"
{
    OrderBy = ascending(Kind);

    elements
    {
        dataitem(Row; "LT AZ Q Row")
        {
            column(Sub; Sub) { }
            column(Cat; Cat) { }
            column(Kind; Kind) { }
            column(Total; Amount) { Method = Sum; }
        }
    }
}

// Grouping columns Cat, Sub, OrderBy Kind.
query 89091 "LT SG Q Ties CatSub"
{
    OrderBy = ascending(Kind);

    elements
    {
        dataitem(Row; "LT AZ Q Row")
        {
            column(Cat; Cat) { }
            column(Sub; Sub) { }
            column(Kind; Kind) { }
            column(Total; Amount) { Method = Sum; }
        }
    }
}

// Grouping columns Sub, Cat, OrderBy the descending Sum (ties on the aggregate).
query 89092 "LT SG Q Ties SumDesc"
{
    OrderBy = descending(Total);

    elements
    {
        dataitem(Row; "LT AZ Q Row")
        {
            column(Sub; Sub) { }
            column(Cat; Cat) { }
            column(Total; Amount) { Method = Sum; }
        }
    }
}

// Grouping columns Sub, Cat, OrderBy Kind descending.
query 89093 "LT SG Q Ties KindDesc"
{
    OrderBy = descending(Kind);

    elements
    {
        dataitem(Row; "LT AZ Q Row")
        {
            column(Sub; Sub) { }
            column(Cat; Cat) { }
            column(Kind; Kind) { }
            column(Total; Amount) { Method = Sum; }
        }
    }
}
