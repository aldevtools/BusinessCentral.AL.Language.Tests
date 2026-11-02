// @expect AL0126 | No overload for method 'ClearAll' takes 1 arguments. Candidates: built-in method 'ClearAll()'
// @expect AL0126 | No overload for method 'Clear' takes 0 arguments. Candidates: built-in method 'Clear(var array[] of Joker)', built-in method 'Clear(var Joker)', built-in method 'Clear(var SecretText)'
// @expect AL0126 | No overload for method 'Clear' takes 2 arguments. Candidates: built-in method 'Clear(var array[] of Joker)', built-in method 'Clear(var Joker)', built-in method 'Clear(var SecretText)'
// Clear takes exactly one argument and ClearAll none (al-runner issue 6656): Clear(), Clear(a, b) and ClearAll(a) are AL0126.
codeunit 52635 "MNC Y64 Clear Count"
{
    procedure P()
    var
        I: Integer;
    begin
        Clear();
        Clear(I, I);
        ClearAll(I);
    end;
}
