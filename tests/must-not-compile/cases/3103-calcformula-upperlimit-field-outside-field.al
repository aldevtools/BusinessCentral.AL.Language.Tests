// @expect AL0104 | Syntax error, 'field' expected
// @expect AL0292 | 'FIELD', 'CONST' or 'FILTER' keyword is expected.
// @expect AL0104 | Syntax error, ')' expected
// @expect AL0104 | Syntax error, ';' expected
// @expect AL0104 | Syntax error, '}' expected
// @expect AL0114 | Syntax error, integer literal expected. Provide a numeric value (e.g., 0, 1, 42).
// @expect AL0104 | Syntax error, ';' expected
// @expect AL0104 | Syntax error, ';' expected
// @expect AL0107 | Syntax error, identifier expected. Provide a valid name (letters, digits, and underscores only).
// @expect AL0104 | Syntax error, '{' expected
// @expect AL0104 | Syntax error, '}' expected
// @expect AL0198 | Expected one of the application object keywords (table, tableextension, page, pageextension, pagecustomization, profile, profileextension, codeunit, report, reportextension, xmlport, query, controladdin, dotnet, enum, enumextension, interface, permissionset, permissionsetextension, entitlement)
// upperlimit is written inside field(): field(upperlimit(F)) and field(upperlimit(filter(F))) compile (queries/flowfields-filters and record/flowfields matrix); written as Day = upperlimit(field(DateF)) it is a syntax error.
table 53130 "MNC FFM D3"
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
table 53131 "MNC FFM H3"
{
    fields
    {
        field(1; Code; Code[10]) { }
        field(2; DateF; Date) { FieldClass = FlowFilter; }
        field(3; IntF; Integer) { FieldClass = FlowFilter; }
        field(10; X; Decimal) { FieldClass = FlowField; CalcFormula = sum("MNC FFM D3".Amt where(Day = upperlimit(field(DateF)))); }
    }
    keys { key(PK; Code) { Clustered = true; } }
}
