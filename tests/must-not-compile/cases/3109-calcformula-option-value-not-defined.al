// @expect AL0383 | The option value 'Z' is not defined on field 'Opt'.
// @expect AL0383 | The option value 'Z' is not defined on field 'Opt'.
// An option member that the field does not define is refused in const() and in filter().
table 53190 "MNC FFM D9"
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
table 53191 "MNC FFM H9"
{
    fields
    {
        field(1; Code; Code[10]) { }
        field(2; DateF; Date) { FieldClass = FlowFilter; }
        field(3; IntF; Integer) { FieldClass = FlowFilter; }
        field(10; OptBad; Decimal) { FieldClass = FlowField; CalcFormula = sum("MNC FFM D9".Amt where(Opt = const(Z))); }
        field(11; OptFilterBad; Decimal) { FieldClass = FlowField; CalcFormula = sum("MNC FFM D9".Amt where(Opt = filter(A|Z))); }
    }
    keys { key(PK; Code) { Clustered = true; } }
}
