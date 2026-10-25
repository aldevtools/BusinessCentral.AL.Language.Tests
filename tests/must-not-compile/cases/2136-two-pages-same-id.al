// @expect AL0264 | An application object of type 'Page' with ID '50001' is already declared by the extension 'Must Not Compile by AL Language (1.0.0.0)'
// @expect AL0264 | An application object of type 'Page' with ID '50001' is already declared by the extension 'Must Not Compile by AL Language (1.0.0.0)'
// Two pages with the same id (0036 is codeunits, 0296 tables). Both declarations are reported.
table 50000 "MNC SH Base Table"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

page 50001 "MNC SH Page A"
{
    SourceTable = "MNC SH Base Table";
}

page 50001 "MNC SH Page B"
{
    SourceTable = "MNC SH Base Table";
}
