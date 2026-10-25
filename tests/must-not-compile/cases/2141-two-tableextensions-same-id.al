// @expect AL0264 | An application object of type 'TableExtension' with ID '50001' is already declared by the extension 'Must Not Compile by AL Language (1.0.0.0)'
// @expect AL0264 | An application object of type 'TableExtension' with ID '50001' is already declared by the extension 'Must Not Compile by AL Language (1.0.0.0)'
// Two table extensions of one table with the same id.
table 50000 "MNC SH Base Table"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

tableextension 50001 "MNC SH Table Ext A" extends "MNC SH Base Table"
{
}

tableextension 50001 "MNC SH Table Ext B" extends "MNC SH Base Table"
{
}
