// @expect AL0107 | Syntax error, identifier expected
// @expect AL0111 | Semicolon expected
// @expect AL0224 | Expression expected
// @expect AL0104 | Syntax error, ')' expected
// The member is a codeunit method called as a statement, `Callee.Exit();`, unquoted (al-runner issue 8635).
// Quoted, as "Exit", the member compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words.

codeunit 53444 "MNC KM3444 Callee"
{
    procedure "Exit"(): Integer
    begin
        exit(1);
    end;
}

codeunit 58444 "MNC KM3444 Use"
{
    procedure P()
    var
        Callee: Codeunit "MNC KM3444 Callee";

    begin
        Callee.Exit();
    end;
}
