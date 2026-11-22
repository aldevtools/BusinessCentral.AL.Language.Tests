// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, ';' expected
// @expect AL0105 | Syntax error, identifier expected; 'tableelement' is a keyword
// @expect AL0104 | Syntax error, ')' expected
// @expect AL0104 | Syntax error, '{' expected
// @expect AL0124 | The property '"No."' cannot be used in this context
// @expect AL0104 | Syntax error, '=' expected
// @expect AL0104 | Syntax error, ';' expected
// A table field group is named TableElement, unquoted: `fieldgroup(TableElement; "No.")` (al-runner issue 8634).
// Quoted, as "TableElement", the name compiles, and so does an ordinary name in its place.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 24 words.
table 53405 "MNC KS3405"
{
    fields
    {
        field(1; "No."; Code[20])
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
    fieldgroups
    {
        fieldgroup(TableElement; "No.")
        {
        }
    }
}
