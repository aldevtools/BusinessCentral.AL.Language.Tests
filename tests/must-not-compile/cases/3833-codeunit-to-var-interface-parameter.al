// @expect AL0133 | Argument 1: cannot convert from 'Codeunit "MNC C3833"' to 'var Interface "MNC I3833"'
// A codeunit that implements the interface is passed to a var Interface parameter. (al-runner issue 8912)
interface "MNC I3833"
{
    procedure Calc(): Integer;
}

codeunit 50171 "MNC C3833" implements "MNC I3833"
{
    procedure Calc(): Integer
    begin
        exit(1);
    end;
}

codeunit 50172 "MNC D3833"
{
    procedure Take(var I: Interface "MNC I3833")
    begin
    end;

    procedure Run1()
    var
        C: Codeunit "MNC C3833";
    begin
        Take(C);
    end;
}
