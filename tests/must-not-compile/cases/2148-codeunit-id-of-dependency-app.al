// @expect AL0264 | An application object of type 'Codeunit' with ID '61100' is already declared by the extension 'AL Language XApp A by AL Language (1.0.0.0)'
// @depends AL Language XApp A
// @appjson {"idRanges": [{"from": 61100, "to": 61101}]}
// Cross-app: a codeunit with the id of a codeunit of the app it depends on (AL Language XApp A, codeunit 61100).
// Only this app's declaration is reported, and the text names the other app. Without the dependency the same file compiles.
// Needs the compiled cross-app fixture A in the symbols folder (CONTRIBUTING.md, "Multi-app fixtures").
codeunit 61100 "MNC SH Same Id As XApp A"
{
}
