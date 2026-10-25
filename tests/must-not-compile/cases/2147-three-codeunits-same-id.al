// @expect AL0264 | An application object of type 'Codeunit' with ID '50001' is already declared by the extension 'Must Not Compile by AL Language (1.0.0.0)'
// @expect AL0264 | An application object of type 'Codeunit' with ID '50001' is already declared by the extension 'Must Not Compile by AL Language (1.0.0.0)'
// @expect AL0264 | An application object of type 'Codeunit' with ID '50001' is already declared by the extension 'Must Not Compile by AL Language (1.0.0.0)'
// Three codeunits with the same id: each of the three declarations is reported once.
codeunit 50001 "MNC SH C A"
{
}

codeunit 50001 "MNC SH C B"
{
}

codeunit 50001 "MNC SH C C"
{
}
