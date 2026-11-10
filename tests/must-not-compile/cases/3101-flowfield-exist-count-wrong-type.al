// @expect AL0201 | The ExInt FlowField is not a Boolean field. If a FlowField CalcFormula starts with 'Exist', then the FlowField must be a Boolean type field.
// @expect AL0201 | The ExDec FlowField is not a Boolean field. If a FlowField CalcFormula starts with 'Exist', then the FlowField must be a Boolean type field.
// @expect AL0201 | The ExText FlowField is not a Boolean field. If a FlowField CalcFormula starts with 'Exist', then the FlowField must be a Boolean type field.
// @expect AL0201 | The NExInt FlowField is not a Boolean field. If a FlowField CalcFormula starts with 'Exist', then the FlowField must be a Boolean type field.
// @expect AL0202 | The CntBool FlowField is not an Integer field. If a FlowField CalcFormula starts with 'Count', then the FlowField must be an Integer type field.
// @expect AL0202 | The CntText FlowField is not an Integer field. If a FlowField CalcFormula starts with 'Count', then the FlowField must be an Integer type field.
// @expect AL0202 | The NCntDec FlowField is not an Integer field. If a FlowField CalcFormula starts with 'Count', then the FlowField must be an Integer type field.
// An exist FlowField must be Boolean and a count FlowField must be Integer, with and without the minus sign, whatever other type is declared (count into Decimal: 2970-count-into-decimal-flowfield).
table 53110 "MNC FFM D1"
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
table 53111 "MNC FFM H1"
{
    fields
    {
        field(1; Code; Code[10]) { }
        field(2; DateF; Date) { FieldClass = FlowFilter; }
        field(3; IntF; Integer) { FieldClass = FlowFilter; }
        field(10; ExInt; Integer) { FieldClass = FlowField; CalcFormula = exist("MNC FFM D1" where(Owner = field(Code))); }
        field(11; ExDec; Decimal) { FieldClass = FlowField; CalcFormula = exist("MNC FFM D1" where(Owner = field(Code))); }
        field(12; ExText; Text[30]) { FieldClass = FlowField; CalcFormula = exist("MNC FFM D1" where(Owner = field(Code))); }
        field(13; NExInt; Integer) { FieldClass = FlowField; CalcFormula = -exist("MNC FFM D1" where(Owner = field(Code))); }
        field(14; CntBool; Boolean) { FieldClass = FlowField; CalcFormula = count("MNC FFM D1" where(Owner = field(Code))); }
        field(15; CntText; Text[30]) { FieldClass = FlowField; CalcFormula = count("MNC FFM D1" where(Owner = field(Code))); }
        field(16; NCntDec; Decimal) { FieldClass = FlowField; CalcFormula = -count("MNC FFM D1" where(Owner = field(Code))); }
    }
    keys { key(PK; Code) { Clustered = true; } }
}
