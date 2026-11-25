// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, ';' expected
// @expect AL0105 | Syntax error, identifier expected; 'trigger' is a keyword
// @expect AL0104 | Syntax error, ')' expected
// @expect AL0104 | Syntax error, '{' expected
// @expect AL0162 | '' is not a valid trigger
// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, '(' expected
// @expect AL0104 | Syntax error, ':' expected
// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, 'begin' expected
// @expect AL0104 | Syntax error, 'end' expected
// @expect AL0104 | Syntax error, 'end' expected
// @expect AL0104 | Syntax error, ';' expected
// A table declares a field named Trigger, unquoted: `field(2; Trigger; Integer)` (al-runner issue 8630).
// Quoted, as "Trigger", the name compiles. The same diagnostics come when the field follows another field (case 3327 for Key).
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL 16 ends the AL0107 text after the first sentence.
table 53321 "MNC KF3321"
{
    fields
    {
        field(2; Trigger; Integer)
        {
        }
    }
}
