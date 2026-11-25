// @expect AL0130 | A 'var' argument must be an assignable variable (field, variable, or parameter), not a constant or expression.
// Clear of a global Label of a codeunit (case 2628 is the local Label; al-runner issue 8912).
codeunit 50171 "MNC C3831"
{
    var
        Lbl: Label 'abc';

    procedure Run1()
    begin
        Clear(Lbl);
    end;
}
