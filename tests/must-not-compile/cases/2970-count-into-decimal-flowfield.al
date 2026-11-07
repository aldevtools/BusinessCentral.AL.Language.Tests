// @expect AL0202 | The DocCount FlowField is not an Integer field. If a FlowField CalcFormula starts with 'Count', then the FlowField must be an Integer type field.
// count() into a Decimal FlowField (al-runner issue 6986). An Integer or a BigInteger FlowField takes a count(); a Decimal does not.
table 50000 "MNC Count Doc"
{
    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Type No."; Code[20]) { }
    }
    keys { key(PK; "No.") { } }
}

table 50001 "MNC Count Type"
{
    fields
    {
        field(1; "No."; Code[20]) { }
        field(10; DocCount; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = count("MNC Count Doc" where("Type No." = field("No.")));
        }
    }
    keys { key(PK; "No.") { } }
}
