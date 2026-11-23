// @expect AL0726 | An identifier, a literal, or an option access is expected as the value of a filter expression
// @expect AL0104 | Syntax error, ')' expected
// @expect AL0870 | Expected verbatim string literal.
// @expect AL0870 | Expected verbatim string literal.
// @expect AL0224 | Expression expected. Provide a valid expression (variable, constant, calculation, or method call).
// al-runner issue 8637 (review of al-runner PR 8816): blanks anywhere in a CalcFormula's unquoted filter(<>@) or filter(@) change
// nothing; filter(< > @) gives the diagnostics of filter(<>@) (case 3806) and filter( @ ) those of filter(@) (case 3805). Measured
// with the compiler of a local BC 29.1 container.
table 53811 "MNC At Row 3808"
{
    fields
    {
        field(1; "Group"; Code[20]) { }
        field(2; Kind; Code[20]) { }
        field(3; Amount; Decimal) { }
    }
    keys { key(PK; "Group") { Clustered = true; } }
}

table 53812 "MNC At Host 3808"
{
    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; NotAtTotal; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("MNC At Row 3808".Amount where("Group" = field("No."), Kind = filter(< > @)));
        }
        field(3; AtTotal; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("MNC At Row 3808".Amount where("Group" = field("No."), Kind = filter( @ )));
        }
    }
    keys { key(PK; "No.") { Clustered = true; } }
}
