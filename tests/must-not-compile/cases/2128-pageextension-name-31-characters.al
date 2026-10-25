// @expect AL0305 | The length of the application object identifier 'MNC SH Name Length Probe Object' cannot exceed 30 characters.
// A page extension whose name has 31 characters.
table 50000 "MNC SH Base Table"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50002 "MNC SH Base Page"
{
    SourceTable = "MNC SH Base Table";
}

pageextension 50001 "MNC SH Name Length Probe Object" extends "MNC SH Base Page"
{
}
