// @expect AL0264 | An application object of type 'PageExtension' with ID '50001' is already declared by the extension 'Must Not Compile by AL Language (1.0.0.0)'
// @expect AL0264 | An application object of type 'PageExtension' with ID '50001' is already declared by the extension 'Must Not Compile by AL Language (1.0.0.0)'
// Two page extensions of one page with the same id.
table 50000 "MNC SH Base Table"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

page 50000 "MNC SH Base Page"
{
    SourceTable = "MNC SH Base Table";
}

pageextension 50001 "MNC SH Page Ext A" extends "MNC SH Base Page"
{
}

pageextension 50001 "MNC SH Page Ext B" extends "MNC SH Base Page"
{
}
