// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, ';' expected
// @expect AL0224 | Expression expected
// @expect AL0104 | Syntax error, ')' expected
// @expect AL0104 | Syntax error, '{' expected
// @expect AL0124 | The property 'Amount' cannot be used in this context
// @expect AL0104 | Syntax error, '=' expected
// @expect AL0104 | Syntax error, ';' expected
// A report extension column is named CueGroup, unquoted: `column(CueGroup; Amount)` (al-runner issue 8634).
// Quoted, as "CueGroup", the name compiles, and so does an ordinary name in its place.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 24 words.
table 53392 "MNC KS3392"
{
    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; Amount; Integer)
        {
        }
    }
    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
    }
}

report 53392 "MNC KS3392 Report"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "MNC KS3392")
        {
            column(No; "No.")
            {
            }
        }
    }
    requestpage
    {
        layout
        {
            area(Content)
            {
            }
        }
    }
}

reportextension 53392 "MNC KS3392 Ext" extends "MNC KS3392 Report"
{
    dataset
    {
        add(Row)
        {
            column(CueGroup; Amount)
            {
            }
        }
    }
}
