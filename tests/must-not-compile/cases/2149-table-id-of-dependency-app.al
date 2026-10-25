// @expect AL0264 | An application object of type 'Table' with ID '61101' is already declared by the extension 'AL Language XApp A by AL Language (1.0.0.0)'
// @depends AL Language XApp A
// @appjson {"idRanges": [{"from": 61100, "to": 61101}]}
// Cross-app: a table with the id of a table of the app it depends on (AL Language XApp A, table 61101).
// Needs the compiled cross-app fixture A in the symbols folder (CONTRIBUTING.md, "Multi-app fixtures").
table 61101 "MNC SH Same Id As XApp A"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}
