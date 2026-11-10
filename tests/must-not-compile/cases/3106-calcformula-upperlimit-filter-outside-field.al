// @expect AL0104 | Syntax error, 'field' expected
// @expect AL0292 | 'FIELD', 'CONST' or 'FILTER' keyword is expected.
// @expect AL0104 | Syntax error, ')' expected
// @expect AL0104 | Syntax error, ';' expected
// @expect AL0104 | Syntax error, '}' expected
// @expect AL0198 | Expected one of the application object keywords (table, tableextension, page, pageextension, pagecustomization, profile, profileextension, codeunit, report, reportextension, xmlport, query, controladdin, dotnet, enum, enumextension, interface, permissionset, permissionsetextension, entitlement)
// upperlimit is written inside field(): field(upperlimit(F)) and field(upperlimit(filter(F))) compile (queries/flowfields-filters and record/flowfields matrix); written as Qty = upperlimit(filter(2..5)) it is a syntax error.
table 53160 "MNC FFM D6"
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
table 53161 "MNC FFM H6"
{
    fields
    {
        field(1; Code; Code[10]) { }
        field(2; DateF; Date) { FieldClass = FlowFilter; }
        field(3; IntF; Integer) { FieldClass = FlowFilter; }
        field(10; X; Decimal) { FieldClass = FlowField; CalcFormula = sum("MNC FFM D6".Amt where(Qty = upperlimit(filter(2..5)))); }
    }
    keys { key(PK; Code) { Clustered = true; } }
}
