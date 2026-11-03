// @expect AL0130 | A 'var' argument must be an assignable variable (field, variable, or parameter), not a constant or expression.
// Clear of the result of a procedure that returns an array (al-runner issue 6658, writer Y66). CopyArray and CompressArray accept such a
// result, even as the target: tests/al-language/collections/lt-y66-copyarray-fn-result/Y66CopyArrayFnResult.al. Clear of a scalar procedure
// result: case 2628.
codeunit 52640 "MNC Y66 Array Provider"
{
    procedure Get(): array[2] of Guid
    begin
    end;
}

codeunit 52641 "MNC Y66 Clear Array Result"
{
    procedure P()
    var
        Provider: Codeunit "MNC Y66 Array Provider";
    begin
        Clear(Provider.Get());
    end;
}
