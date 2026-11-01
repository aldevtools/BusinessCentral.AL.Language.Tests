// @expect AL0130 | A 'var' argument must be an assignable variable (field, variable, or parameter), not a constant or expression.
// @expect AL0130 | A 'var' argument must be an assignable variable (field, variable, or parameter), not a constant or expression.
// @expect AL0130 | A 'var' argument must be an assignable variable (field, variable, or parameter), not a constant or expression.
// @expect AL0130 | A 'var' argument must be an assignable variable (field, variable, or parameter), not a constant or expression.
// @expect AL0130 | A 'var' argument must be an assignable variable (field, variable, or parameter), not a constant or expression.
// Clear needs an assignable variable (al-runner issue 6656, Clear of every type): a Label, a TextConst, a literal, a procedure result and an
// expression are AL0130. Clear of a variable of every other type compiles: tests/al-language/types/lt-y64-clear-types/Y64ClearTypes.al.
codeunit 52634 "MNC Y64 Clear"
{
    var
        Lbl: Label 'abc';
        TCo: TextConst ENU = 'x';

    procedure P()
    var
        I: Integer;
    begin
        Clear(Lbl);
        Clear(TCo);
        Clear(5);
        Clear(F());
        Clear(I + 1);
    end;

    procedure F(): Integer
    begin
    end;
}
