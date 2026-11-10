// @expect AL0256 | The flowfield 'FS' cannot be part of the keys for table 'MNC FFM H0'.
// @expect AL0256 | The flowfield 'FN' cannot be part of the keys for table 'MNC FFM H0'.
// @expect AL0256 | The flowfield 'FC' cannot be part of the keys for table 'MNC FFM H0'.
// @expect AL0256 | The flowfield 'FE' cannot be part of the keys for table 'MNC FFM H0'.
// @expect AL0256 | The flowfield 'FL' cannot be part of the keys for table 'MNC FFM H0'.
// @expect AL0256 | The flowfield 'FA' cannot be part of the keys for table 'MNC FFM H0'.
// @expect AL0256 | The flowfield 'FM' cannot be part of the keys for table 'MNC FFM H0'.
// @expect AL0256 | The flowfield 'FX' cannot be part of the keys for table 'MNC FFM H0'.
// A FlowField of any CalcFormula kind (sum, -sum, count, exist, lookup, average, min, max) as a key field of the table is refused.
// A key chosen in code, Record.SetCurrentKey(FlowField), is not a table key and compiles (record/keys-sorting/PwFlowFieldKeyRule.al).
table 53100 "MNC FFM D0"
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
table 53101 "MNC FFM H0"
{
    fields
    {
        field(1; Code; Code[10]) { }
        field(2; DateF; Date) { FieldClass = FlowFilter; }
        field(3; IntF; Integer) { FieldClass = FlowFilter; }
        field(10; FS; Decimal) { FieldClass = FlowField; CalcFormula = sum("MNC FFM D0".Amt where(Owner = field(Code))); }
        field(11; FN; Decimal) { FieldClass = FlowField; CalcFormula = -sum("MNC FFM D0".Amt where(Owner = field(Code))); }
        field(12; FC; Integer) { FieldClass = FlowField; CalcFormula = count("MNC FFM D0" where(Owner = field(Code))); }
        field(13; FE; Boolean) { FieldClass = FlowField; CalcFormula = exist("MNC FFM D0" where(Owner = field(Code))); }
        field(14; FL; Text[30]) { FieldClass = FlowField; CalcFormula = lookup("MNC FFM D0".Name where(Owner = field(Code))); }
        field(15; FA; Decimal) { FieldClass = FlowField; CalcFormula = average("MNC FFM D0".Amt where(Owner = field(Code))); }
        field(16; FM; Decimal) { FieldClass = FlowField; CalcFormula = min("MNC FFM D0".Amt where(Owner = field(Code))); }
        field(17; FX; Decimal) { FieldClass = FlowField; CalcFormula = max("MNC FFM D0".Amt where(Owner = field(Code))); }
    }
    keys { key(PK; Code) { Clustered = true; } key(KS; FS) { } key(KN; FN) { } key(KC; FC) { } key(KE; FE) { } key(KL; FL) { } key(KA; FA) { } key(KM; FM) { } key(KX; FX) { } }
}
