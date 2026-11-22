// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, ';' expected
// @expect AL0224 | Expression expected
// @expect AL0104 | Syntax error, ')' expected
// @expect AL0104 | Syntax error, '{' expected
// @expect AL0124 | The property 'Opt' cannot be used in this context
// @expect AL0104 | Syntax error, '=' expected
// @expect AL0104 | Syntax error, ';' expected
// An xmlport request page field control is named Procedure, unquoted: `field(Procedure; Opt)` (al-runner issue 8634).
// Quoted, as "Procedure", the name compiles, and so does an ordinary name in its place.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 24 words.
table 53403 "MNC KS3403"
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

xmlport 53403 "MNC KS3403 Port"
{
    schema
    {
        textelement(Root)
        {

        }
    }
    requestpage
    {
        layout
        {
            area(Content)
            {
                field(Procedure; Opt)
                {
                }
            }
        }
    }

    var
        Opt: Integer;
}
