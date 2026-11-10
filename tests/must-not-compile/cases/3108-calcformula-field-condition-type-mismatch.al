// @expect AL0204 | Field type Date is not convertible to field type Code.
// @expect AL0204 | Field type Code is not convertible to field type Date.
// @expect AL0186 | Reference 'Nope' in application object 'MNC FFM H8' does not exist
// @expect AL0204 | Field type Code is not convertible to field type Decimal.
// @expect AL0186 | Reference 'Nope' in application object 'MNC FFM D8' does not exist
// @expect AL0186 | Reference 'Nope' in application object 'MNC FFM D8' does not exist
// A field(F) condition needs a field of a convertible type: a Code field against a Date column, a Date FlowFilter against a Code column, and names that do not exist, are refused. (A FlowFilter of another type under field(filter(F)) compiles.)
table 53180 "MNC FFM D8"
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
table 53181 "MNC FFM H8"
{
    fields
    {
        field(1; Code; Code[10]) { }
        field(2; DateF; Date) { FieldClass = FlowFilter; }
        field(3; IntF; Integer) { FieldClass = FlowFilter; }
        field(10; DayVsCode; Decimal) { FieldClass = FlowField; CalcFormula = sum("MNC FFM D8".Amt where(Day = field(Code))); }
        field(11; OwnerVsDateF; Decimal) { FieldClass = FlowField; CalcFormula = sum("MNC FFM D8".Amt where(Owner = field(DateF))); }
        field(12; UnknownField; Decimal) { FieldClass = FlowField; CalcFormula = sum("MNC FFM D8".Amt where(Owner = field(Nope))); }
        field(13; SelfRef; Decimal) { FieldClass = FlowField; CalcFormula = sum("MNC FFM D8".Amt where(Owner = field(SelfRef))); }
        field(14; UnknownSource; Decimal) { FieldClass = FlowField; CalcFormula = sum("MNC FFM D8".Nope where(Owner = field(Code))); }
        field(15; UnknownCond; Decimal) { FieldClass = FlowField; CalcFormula = sum("MNC FFM D8".Amt where(Nope = field(Code))); }
    }
    keys { key(PK; Code) { Clustered = true; } }
}
