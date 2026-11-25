// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, ':' expected
// @expect AL0224 | Expression expected
// @expect AL0111 | Semicolon expected
// @expect AL0224 | Expression expected
// @expect AL0104 | Syntax error, ':' expected
// The name after `::` is an enum value as a case label, `K::To:`, unquoted (al-runner issue 8649).
// Quoted, as "To", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words.
enum 53495 "MNC KS3495"
{
    value(0; Zero)
    {
    }
    value(1; "To")
    {
    }
}

codeunit 58495 "MNC KS3495 Use"
{
    procedure P(K: Enum "MNC KS3495"): Integer
    begin
        case K of
            K::To:
                exit(1);
        end;
        exit(0);
    end;
}
