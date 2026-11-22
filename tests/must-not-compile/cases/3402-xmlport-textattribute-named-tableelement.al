// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, ')' expected
// @expect AL0104 | Syntax error, '{' expected
// @expect AL0104 | Syntax error, '(' expected
// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, ';' expected
// @expect AL0104 | Syntax error, '}' expected
// An xmlport text attribute is named TableElement, unquoted: `textattribute(TableElement)` (al-runner issue 8634).
// Quoted, as "TableElement", the name compiles, and so does an ordinary name in its place.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 24 words.
table 53402 "MNC KS3402"
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

xmlport 53402 "MNC KS3402 Port"
{
    schema
    {
        textelement(Root)
        {
            textattribute(TableElement)
            {
            }
        }
    }
}
