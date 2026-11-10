// @expect AL0203 | Cannot calculate Sum or Average for the field Name because it is not a numeric field (Decimal, BigInteger, Integer, or Duration data type).
// @expect AL0203 | Cannot calculate Sum or Average for the field Day because it is not a numeric field (Decimal, BigInteger, Integer, or Duration data type).
// @expect AL0203 | Cannot calculate Sum or Average for the field Name because it is not a numeric field (Decimal, BigInteger, Integer, or Duration data type).
// @expect AL0203 | Cannot calculate Sum or Average for the field Kind because it is not a numeric field (Decimal, BigInteger, Integer, or Duration data type).
// @expect AL0203 | Cannot calculate Sum or Average for the field SumIntoText because it is not a numeric field (Decimal, BigInteger, Integer, or Duration data type).
// @expect AL0203 | Cannot calculate Sum or Average for the field Name because it is not a numeric field (Decimal, BigInteger, Integer, or Duration data type).
// Sum and average (and the minus forms) need a numeric source field and a numeric FlowField; a Text, Code or Date source, or a Text FlowField, is refused. Sum into an Integer FlowField, and min and max of a Date or Text field, compile.
table 53120 "MNC FFM D2"
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
table 53121 "MNC FFM H2"
{
    fields
    {
        field(1; Code; Code[10]) { }
        field(2; DateF; Date) { FieldClass = FlowFilter; }
        field(3; IntF; Integer) { FieldClass = FlowFilter; }
        field(10; SumText; Decimal) { FieldClass = FlowField; CalcFormula = sum("MNC FFM D2".Name where(Owner = field(Code))); }
        field(11; SumDate; Decimal) { FieldClass = FlowField; CalcFormula = sum("MNC FFM D2".Day where(Owner = field(Code))); }
        field(12; AvgText; Decimal) { FieldClass = FlowField; CalcFormula = average("MNC FFM D2".Name where(Owner = field(Code))); }
        field(13; NSumCode; Decimal) { FieldClass = FlowField; CalcFormula = -sum("MNC FFM D2".Kind where(Owner = field(Code))); }
        field(14; SumIntoText; Text[30]) { FieldClass = FlowField; CalcFormula = sum("MNC FFM D2".Amt where(Owner = field(Code))); }
        field(15; AvgBool; Decimal) { FieldClass = FlowField; CalcFormula = average("MNC FFM D2".Name where(Owner = field(Code))); }
    }
    keys { key(PK; Code) { Clustered = true; } }
}
