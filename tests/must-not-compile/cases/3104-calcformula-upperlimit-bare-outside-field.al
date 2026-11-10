// @expect AL0104 | Syntax error, 'field' expected
// @expect AL0292 | 'FIELD', 'CONST' or 'FILTER' keyword is expected.
// @expect AL0104 | Syntax error, ')' expected
// upperlimit is written inside field(): field(upperlimit(F)) and field(upperlimit(filter(F))) compile (queries/flowfields-filters and record/flowfields matrix); written as Day = upperlimit(DateF) it is a syntax error.
table 53140 "MNC FFM D4"
{
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Owner; Code[10]) { }
        field(3; Qty; Integer) { }
        field(4; Amt; Decimal) { }
        field(5; Day; Date) { }
        field(6; Kind; Code[10]) { }
        field(7; Opt; Option) { OptionMembers = A,B,C; }
        field(8; Name; Text[30]) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}
table 53141 "MNC FFM H4"
{
    fields
    {
        field(1; Code; Code[10]) { }
        field(2; DateF; Date) { FieldClass = FlowFilter; }
        field(3; IntF; Integer) { FieldClass = FlowFilter; }
        field(10; X; Decimal) { FieldClass = FlowField; CalcFormula = sum("MNC FFM D4".Amt where(Day = upperlimit(DateF))); }
    }
    keys { key(PK; Code) { Clustered = true; } }
}
