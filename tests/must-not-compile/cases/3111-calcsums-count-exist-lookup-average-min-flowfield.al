// @expect AL0827 | Argument 1: The argument 1 of field class FlowField is not supported. Allowed field class types are 'Normal'.
// @expect AL0827 | Argument 1: The argument 1 of field class FlowField is not supported. Allowed field class types are 'Normal'.
// @expect AL0827 | Argument 1: The argument 1 of field class FlowField is not supported. Allowed field class types are 'Normal'.
// @expect AL0827 | Argument 1: The argument 1 of field class FlowField is not supported. Allowed field class types are 'Normal'.
// @expect AL0827 | Argument 1: The argument 1 of field class FlowField is not supported. Allowed field class types are 'Normal'.
// Record.CalcSums with a Count, Exist, Lookup, Average or Min FlowField is refused like a Sum FlowField (1470-calcsums-flowfield-argument).
table 53210 "MNC FFM D11"
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
table 53211 "MNC FFM H11"
{
    fields
    {
        field(1; Code; Code[10]) { }
        field(2; DateF; Date) { FieldClass = FlowFilter; }
        field(3; IntF; Integer) { FieldClass = FlowFilter; }
        field(10; Cnt; Integer) { FieldClass = FlowField; CalcFormula = count("MNC FFM D11" where(Owner = field(Code))); }
        field(11; Ex; Boolean) { FieldClass = FlowField; CalcFormula = exist("MNC FFM D11" where(Owner = field(Code))); }
        field(12; Lk; Text[30]) { FieldClass = FlowField; CalcFormula = lookup("MNC FFM D11".Name where(Owner = field(Code))); }
        field(13; Avg; Decimal) { FieldClass = FlowField; CalcFormula = average("MNC FFM D11".Amt where(Owner = field(Code))); }
        field(14; Mn; Decimal) { FieldClass = FlowField; CalcFormula = min("MNC FFM D11".Amt where(Owner = field(Code))); }
    }
    keys { key(PK; Code) { Clustered = true; } }
}
codeunit 53212 "MNC FFM C11"
{
    procedure P()
    var
        H: Record "MNC FFM H11";
    begin
        H.CalcSums(Cnt);
        H.CalcSums(Ex);
        H.CalcSums(Lk);
        H.CalcSums(Avg);
        H.CalcSums(Mn);
    end;
}
