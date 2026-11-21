// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, 'end' expected
// @expect AL0111 | Semicolon expected
// @expect AL0224 | Expression expected
// @expect AL0104 | Syntax error, ')' expected
// The member is a codeunit method called through a codeunit variable, `V := Callee.Do();`, unquoted (al-runner issue 8635).
// Quoted, as "Do", the member compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words.

codeunit 53443 "MNC KM3443 Callee"
{
    procedure "Do"(): Integer
    begin
        exit(1);
    end;
}

codeunit 58443 "MNC KM3443 Use"
{
    procedure P()
    var
        Callee: Codeunit "MNC KM3443 Callee";
        V: Integer;

    begin
        V := Callee.Do();
    end;
}
