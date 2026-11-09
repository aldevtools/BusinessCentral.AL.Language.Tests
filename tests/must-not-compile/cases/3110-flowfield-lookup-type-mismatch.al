// @expect AL0427 | Field LkTextInt cannot be converted to type Text[30].
// @expect AL0427 | Field LkIntDec cannot be converted to type Integer.
// @expect AL0427 | Field LkDecInt cannot be converted to type Decimal.
// @expect AL0427 | Field NLkTextInt cannot be converted to type Text[30].
// A lookup FlowField must have the type of the looked-up field (Text into Integer, Integer into Decimal, Decimal into Integer are refused); the minus sign does not change that. Lookup of a Date into a Date and -lookup into Text or Decimal compile.
table 53200 "MNC FFM D10"
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
table 53201 "MNC FFM H10"
{
    fields
    {
        field(1; Code; Code[10]) { }
        field(2; DateF; Date) { FieldClass = FlowFilter; }
        field(3; IntF; Integer) { FieldClass = FlowFilter; }
        field(10; LkTextInt; Integer) { FieldClass = FlowField; CalcFormula = lookup("MNC FFM D10".Name where(Owner = field(Code))); }
        field(11; LkIntDec; Decimal) { FieldClass = FlowField; CalcFormula = lookup("MNC FFM D10".Qty where(Owner = field(Code))); }
        field(12; LkDecInt; Integer) { FieldClass = FlowField; CalcFormula = lookup("MNC FFM D10".Amt where(Owner = field(Code))); }
        field(13; NLkTextInt; Integer) { FieldClass = FlowField; CalcFormula = -lookup("MNC FFM D10".Name where(Owner = field(Code))); }
    }
    keys { key(PK; Code) { Clustered = true; } }
}
