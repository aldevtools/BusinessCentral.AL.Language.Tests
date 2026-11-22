// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, ';' expected
// @expect AL0104 | Syntax error, ')' expected
// @expect AL0104 | Syntax error, '{' expected
// @expect AL0104 | Syntax error, '}' expected
// @expect AL0104 | Syntax error, '(' expected
// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, ')' expected
// @expect AL0104 | Syntax error, '{' expected
// @expect AL0124 | The property '"MNC KS3368 Part"' cannot be used in this context
// @expect AL0104 | Syntax error, '=' expected
// @expect AL0104 | Syntax error, ';' expected
// A page part is named CueGroup, unquoted: `part(CueGroup; "MNC KS3368 Part")` (al-runner issue 8634).
// Quoted, as "CueGroup", the name compiles, and so does an ordinary name in its place.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 24 words.
table 53368 "MNC KS3368"
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

page 53368 "MNC KS3368 Page"
{
    PageType = Card;
    SourceTable = "MNC KS3368";

    layout
    {
        area(Content)
        {
            part(CueGroup; "MNC KS3368 Part")
            {
            }
        }
    }
}

page 58368 "MNC KS3368 Part"
{
    PageType = ListPart;
    SourceTable = "MNC KS3368";

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("No."; Rec."No.")
                {
                }
            }
        }
    }
}
