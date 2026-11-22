// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, ';' expected
// @expect AL0224 | Expression expected
// @expect AL0104 | Syntax error, ')' expected
// @expect AL0104 | Syntax error, '{' expected
// @expect AL0124 | The property 'Opt' cannot be used in this context
// @expect AL0104 | Syntax error, '=' expected
// @expect AL0104 | Syntax error, ';' expected
// A report extension request page field control is named Event, unquoted: `field(Event; Opt)` (al-runner issue 8634).
// Quoted, as "Event", the name compiles, and so does an ordinary name in its place.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 24 words.
table 53394 "MNC KS3394"
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

report 53394 "MNC KS3394 Report"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "MNC KS3394")
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

reportextension 53394 "MNC KS3394 Ext" extends "MNC KS3394 Report"
{
    requestpage
    {
        layout
        {
            addlast(Content)
            {
                field(Event; Opt)
                {
                }
            }
        }
    }

    var
        Opt: Integer;
}
