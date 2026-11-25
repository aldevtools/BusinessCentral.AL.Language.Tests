// @expect AL0726 | An identifier, a literal, or an option access is expected as the value of a filter expression
// @expect AL0104 | Syntax error, ')' expected
// @expect AL0870 | Expected verbatim string literal.
// @expect AL0726 | An identifier, a literal, or an option access is expected as the value of a filter expression
// @expect AL0104 | Syntax error, ')' expected
// @expect AL0870 | Expected verbatim string literal.
// al-runner issue 8637 (review of al-runner PR 8816): a CalcFormula's unquoted filter(<> @), with a blank before the @, does not
// compile over a Code field nor over a Text field, as filter(<>@) does not (case 3806). Measured with the compiler of a local BC
// 29.1 container.
table 53809 "MNC Not At Row 3807"
{
    fields
    {
        field(1; "Group"; Code[20]) { }
        field(2; Kind; Code[20]) { }
        field(3; Note; Text[50]) { }
        field(4; Amount; Decimal) { }
    }
    keys { key(PK; "Group") { Clustered = true; } }
}

table 53810 "MNC Not At Host 3807"
{
    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; CodeTotal; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("MNC Not At Row 3807".Amount where("Group" = field("No."), Kind = filter(<> @)));
        }
        field(3; TextTotal; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("MNC Not At Row 3807".Amount where("Group" = field("No."), Note = filter(<> @)));
        }
    }
    keys { key(PK; "No.") { Clustered = true; } }
}
