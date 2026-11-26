// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, 'end' expected
// @expect AL0111 | Semicolon expected
// @expect AL0224 | Expression expected
// @expect AL0104 | Syntax error, ')' expected
// The member is an interface method, `V := Iface.Of();`, unquoted (al-runner issue 8635).
// Quoted, as "Of", the member compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words.
interface "MNC KM3452 I"
{
    procedure "Of"(): Integer;
}

codeunit 53452 "MNC KM3452 Impl" implements "MNC KM3452 I"
{
    procedure "Of"(): Integer
    begin
        exit(1);
    end;
}

codeunit 58452 "MNC KM3452 Use"
{
    procedure P(Iface: Interface "MNC KM3452 I")
    var
        V: Integer;

    begin
        V := Iface.Of();
    end;
}
