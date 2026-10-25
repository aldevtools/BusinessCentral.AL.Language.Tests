// @expect AL0305 | The length of the application object identifier 'MNC SH Name Length Probe Object' cannot exceed 30 characters.
// A page whose name has 31 characters.
table 50000 "MNC SH Base Table"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50001 "MNC SH Name Length Probe Object"
{
    SourceTable = "MNC SH Base Table";
}
