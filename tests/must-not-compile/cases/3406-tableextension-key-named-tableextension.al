// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, ';' expected
// @expect AL0105 | Syntax error, identifier expected; 'tableextension' is a keyword
// @expect AL0104 | Syntax error, ')' expected
// @expect AL0104 | Syntax error, '{' expected
// @expect AL0124 | The property 'Extra' cannot be used in this context
// @expect AL0104 | Syntax error, '=' expected
// @expect AL0104 | Syntax error, ';' expected
// A table extension key is named TableExtension, unquoted: `key(TableExtension; Extra)` (al-runner issue 8634).
// Quoted, as "TableExtension", the name compiles, and so does an ordinary name in its place.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 24 words.
table 53406 "MNC KS3406"
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

tableextension 53406 "MNC KS3406 Ext" extends "MNC KS3406"
{
    fields
    {
        field(50000; Extra; Integer)
        {
        }
    }
    keys
    {
        key(TableExtension; Extra)
        {
        }
    }
}
