// @expect AL0104 | Syntax error, 'begin' expected
// @expect AL0104 | Syntax error, 'end' expected
// @expect AL0104 | Syntax error, 'end' expected
// @expect AL0104 | Syntax error, ';' expected
// The OnBeforePassVariable trigger of an xmlport textelement declares a variable named Key, unquoted (al-runner issue 8539).
// Quoted, as "Key", the name compiles.
// Measured with the AL compilers of BC 27.4, 28.5 and 29.1 (AL 16.4, 17.0, 18.1): same codes on each; AL 16 ends the AL0107 text after the first sentence.
xmlport 53275 "MNC KV3275"
{
    schema
    {
        textelement(Root)
        {
            trigger OnBeforePassVariable()
            var
                Key: Integer;
            begin
            end;
        }
    }
}
