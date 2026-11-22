// @expect AL0870 | Expected verbatim string literal.
// @expect AL0224 | Expression expected. Provide a valid expression (variable, constant, calculation, or method call).
// al-runner issue 8637 (review of al-runner PR 8816): a CalcFormula's filter(@) without quotes does not compile; the quoted
// filter('@') does, and CalcFields reads it as @ alone (tests/al-language/record/filters/AtSignAloneReads.al). Measured with the
// compiler of a local BC 29.1 container.
table 53805 "MNC At Row 3805"
{
    fields
    {
        field(1; "Group"; Code[20]) { }
        field(2; Kind; Code[20]) { }
        field(3; Amount; Decimal) { }
    }
    keys { key(PK; "Group") { Clustered = true; } }
}

table 53806 "MNC At Host 3805"
{
    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Total; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("MNC At Row 3805".Amount where("Group" = field("No."), Kind = filter(@)));
        }
    }
    keys { key(PK; "No.") { Clustered = true; } }
}
