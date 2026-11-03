// Fixtures for CgQueryLeads.al (writer CG, corpus #667 query leads).
// Tables 84460-84462, table extensions 84460-84461, enum 84460, queries 84460-84474.

enum 84460 "LT CG Q Kind Enum"
{
    Extensible = false;
    value(0; " ") { }
    value(1; Quote) { }
    value(2; "Order") { }
    value(3; Invoice) { }
}

table 84460 "LT CG Q Header"
{
    DataClassification = CustomerContent;
    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Grp; Code[10]) { }
        field(3; Posted; DateTime) { }
        field(4; PDate; Date) { }
        field(5; Qty; Integer) { }
        field(6; Kind; Option) { OptionMembers = " ",Quote,"Order",Invoice; }
        field(7; EKind; Enum "LT CG Q Kind Enum") { }
        field(8; Big; BigInteger) { }
        field(10; LineSum; Decimal) { FieldClass = FlowField; CalcFormula = sum("LT CG Q Line".Amount where("Header No." = field("No."))); }
        field(11; HasLines; Boolean) { FieldClass = FlowField; CalcFormula = exist("LT CG Q Line" where("Header No." = field("No."))); }
        field(12; NoLines; Boolean) { FieldClass = FlowField; CalcFormula = - exist("LT CG Q Line" where("Header No." = field("No."))); }
        field(13; DeepSum; Decimal) { FieldClass = FlowField; CalcFormula = sum("LT CG Q Line".SubSum where("Header No." = field("No."))); }
    }
    keys { key(PK; "No.") { Clustered = true; } }
}

table 84461 "LT CG Q Line"
{
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Header No."; Code[20]) { }
        field(3; Amount; Decimal) { }
        // A FlowField of the line: DeepSum on the header sums this FlowField (a FlowField over a FlowField).
        field(4; SubSum; Decimal) { FieldClass = FlowField; CalcFormula = sum("LT CG Q Line".Amount where("Entry No." = field("Entry No."))); }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 84462 "LT CG Q Shared"
{
    DataClassification = CustomerContent;
    DataPerCompany = false;
    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Amount; Decimal) { }
    }
    keys { key(PK; "No.") { Clustered = true; } }
}

tableextension 84460 "LT CG Q Header Ext" extends "LT CG Q Header"
{
    fields
    {
        field(84460; ExtFlag; Boolean) { DataClassification = CustomerContent; }
        field(84461; ExtCode; Code[10]) { DataClassification = CustomerContent; }
    }
}

tableextension 84461 "LT CG Q Line Ext" extends "LT CG Q Line"
{
    fields
    {
        field(84460; ExtA; Code[10]) { DataClassification = CustomerContent; }
        field(84461; ExtB; Decimal) { DataClassification = CustomerContent; }
    }
}

query 84460 "LT CG Q Agg"
{
    elements
    {
        dataitem(H; "LT CG Q Header")
        {
            column(Grp; Grp) { }
            column(SumQty; Qty) { Method = Sum; }
            column(AvgQty; Qty) { Method = Average; }
            column(MinQty; Qty) { Method = Min; }
            column(MaxQty; Qty) { Method = Max; }
            column(SumBig; Big) { Method = Sum; }
            column(AvgBig; Big) { Method = Average; }
        }
    }
}

query 84461 "LT CG Q DateM"
{
    OrderBy = ascending(No);
    elements
    {
        dataitem(H; "LT CG Q Header")
        {
            column(No; "No.") { }
            column(DtDay; Posted) { Method = Day; }
            column(DtMonth; Posted) { Method = Month; }
            column(DtYear; Posted) { Method = Year; }
            column(DDay; PDate) { Method = Day; }
            column(DMonth; PDate) { Method = Month; }
            column(DYear; PDate) { Method = Year; }
        }
    }
}

query 84462 "LT CG Q Deep"
{
    elements
    {
        dataitem(H; "LT CG Q Header")
        {
            column(No; "No.") { }
            column(DeepSum; DeepSum) { }
        }
    }
}

query 84463 "LT CG Q Exist"
{
    OrderBy = ascending(No);
    elements
    {
        dataitem(H; "LT CG Q Header")
        {
            column(No; "No.") { }
            column(HasLines; HasLines) { }
            column(NoLines; NoLines) { }
        }
    }
}

query 84464 "LT CG Q Item BOM"
{
    elements
    {
        dataitem(Item; Item)
        {
            column(No; "No.") { }
            column(Assembly_BOM; "Assembly BOM") { }
        }
    }
}

query 84465 "LT CG Q Link FF Parent"
{
    elements
    {
        dataitem(H; "LT CG Q Header")
        {
            column(No; "No.") { }
            dataitem(L; "LT CG Q Line")
            {
                // AL0910 (warning below runtime 30.0): the parent side of the link is a FlowField.
                DataItemLink = Amount = H.LineSum;
                SqlJoinType = InnerJoin;
                column(EntryNo; "Entry No.") { }
            }
        }
    }
}

query 84466 "LT CG Q Link FF Child"
{
    elements
    {
        dataitem(H; "LT CG Q Header")
        {
            column(No; "No.") { }
            dataitem(L; "LT CG Q Line")
            {
                // AL0910 (warning below runtime 30.0): the child side of the link is a FlowField.
                DataItemLink = SubSum = H.Qty;
                SqlJoinType = InnerJoin;
                column(EntryNo; "Entry No.") { }
            }
        }
    }
}

query 84467 "LT CG Q Date Num Filter"
{
    elements
    {
        dataitem(H; "LT CG Q Header")
        {
            DataItemTableFilter = PDate = filter(29082018);
            column(No; "No.") { }
        }
    }
}

query 84468 "LT CG Q Date Lit Filter"
{
    elements
    {
        dataitem(H; "LT CG Q Header")
        {
            DataItemTableFilter = PDate = filter(20180829D);
            column(No; "No.") { }
        }
    }
}

query 84469 "LT CG Q Kind"
{
    OrderBy = ascending(No);
    elements
    {
        dataitem(H; "LT CG Q Header")
        {
            column(No; "No.") { }
            column(Kind; Kind) { }
            column(EKind; EKind) { }
        }
    }
}

query 84470 "LT CG Q Shared"
{
    elements
    {
        dataitem(S; "LT CG Q Shared")
        {
            column(No; "No.") { }
            column(Amount; Amount) { }
        }
    }
}

query 84471 "LT CG Q Grp"
{
    OrderBy = ascending(No);
    elements
    {
        dataitem(H; "LT CG Q Header")
        {
            column(No; "No.") { }
            column(Grp; Grp) { }
        }
    }
}

query 84472 "LT CG Q Ext Filter"
{
    OrderBy = ascending(No);
    elements
    {
        dataitem(H; "LT CG Q Header")
        {
            DataItemTableFilter = ExtFlag = const(false);
            column(No; "No.") { }
            column(ExtCode; ExtCode) { }
        }
    }
}

query 84473 "LT CG Q Ext Join"
{
    OrderBy = ascending(EntryNo);
    elements
    {
        dataitem(H; "LT CG Q Header")
        {
            DataItemTableFilter = Kind = const(Invoice);
            column(No; "No.") { }
            column(LineSum; LineSum) { }
            dataitem(L; "LT CG Q Line")
            {
                DataItemLink = "Header No." = H."No.";
                SqlJoinType = InnerJoin;
                column(EntryNo; "Entry No.") { }
                column(ExtA; ExtA) { }
                column(ExtB; ExtB) { }
                column(Amount; Amount) { }
            }
        }
    }
}

query 84474 "LT CG Q Ext Link"
{
    OrderBy = ascending(EntryNo);
    elements
    {
        dataitem(H; "LT CG Q Header")
        {
            column(No; "No.") { }
            column(ExtCode; ExtCode) { }
            dataitem(L; "LT CG Q Line")
            {
                // The link pairs an extension field of the child with an extension field of the parent.
                DataItemLink = ExtA = H.ExtCode;
                SqlJoinType = InnerJoin;
                column(EntryNo; "Entry No.") { }
            }
        }
    }
}
