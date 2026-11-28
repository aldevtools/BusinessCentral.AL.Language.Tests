// @expect AL0726 | An identifier, a literal, or an option access is expected as the value of a filter expression
// @expect AL0104 | Syntax error, ')' expected
// @expect AL0870 | Expected verbatim string literal.
// al-runner issue 8637 (review of al-runner PR 8816): a CalcFormula's filter(<>@) without quotes does not compile, as filter(@)
// does not (case 3805); the quoted filter('<>@') does, and CalcFields reads it as <>@ alone
// (tests/al-language/record/filters/AtSignAloneReads.al). Measured with the compiler of a local BC 29.1 container.
table 53807 "MNC Not At Row 3806"
{
    fields
    {
        field(1; "Group"; Code[20]) { }
        field(2; Kind; Code[20]) { }
        field(3; Amount; Decimal) { }
    }
    keys { key(PK; "Group") { Clustered = true; } }
}

table 53808 "MNC Not At Host 3806"
{
    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Total; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("MNC Not At Row 3806".Amount where("Group" = field("No."), Kind = filter(<>@)));
        }
    }
    keys { key(PK; "No.") { Clustered = true; } }
}
