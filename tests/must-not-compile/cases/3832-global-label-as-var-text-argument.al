// @expect AL0133 | Argument 1: cannot convert from 'Label' to 'var Text'
// A global Label of a codeunit as the argument of a var Text parameter (al-runner issue 8912).
codeunit 50172 "MNC C3832"
{
    var
        Lbl: Label 'abc';

    procedure Run1()
    begin
        SetText(Lbl);
    end;

    local procedure SetText(var T: Text)
    begin
        T := 'x';
    end;
}
