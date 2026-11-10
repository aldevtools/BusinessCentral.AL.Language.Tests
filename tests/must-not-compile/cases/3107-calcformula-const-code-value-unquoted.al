// @expect AL0186 | Reference 'Kind' in application object 'MNC FFM D7' does not exist
// @expect AL0204 | Field type Code is not convertible to field type Option.
// @expect AL0204 | Field type Code is not convertible to field type Integer.
// const() of a Code or Text field needs a quoted literal: const('K1') compiles, const(K1) is read as an option name and refused; const(1) on a Code field is refused too.
table 53170 "MNC FFM D7"
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
table 53171 "MNC FFM H7"
{
    fields
    {
        field(1; Code; Code[10]) { }
        field(2; DateF; Date) { FieldClass = FlowFilter; }
        field(3; IntF; Integer) { FieldClass = FlowFilter; }
        field(10; ConstCode; Decimal) { FieldClass = FlowField; CalcFormula = sum("MNC FFM D7".Amt where(Kind = const(K1))); }
        field(11; ConstNum; Decimal) { FieldClass = FlowField; CalcFormula = sum("MNC FFM D7".Amt where(Kind = const(1))); }
    }
    keys { key(PK; Code) { Clustered = true; } }
}
