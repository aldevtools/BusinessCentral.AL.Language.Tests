// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, ';' expected
// @expect AL0104 | Syntax error, ')' expected
// @expect AL0104 | Syntax error, '{' expected
// @expect AL0124 | The property 'Rec' cannot be used in this context
// @expect AL0104 | Syntax error, '=' expected
// @expect AL0104 | Syntax error, ';' expected
// A page field control is named False, unquoted: `field(False; Rec.Amount)` (al-runner issue 8634).
// Quoted, as "False", the name compiles, and so does an ordinary name in its place.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 24 words.
table 53348 "MNC KS3348"
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

page 53348 "MNC KS3348 Page"
{
    PageType = Card;
    SourceTable = "MNC KS3348";

    layout
    {
        area(Content)
        {
            field(False; Rec.Amount)
            {
            }
        }
    }
}
