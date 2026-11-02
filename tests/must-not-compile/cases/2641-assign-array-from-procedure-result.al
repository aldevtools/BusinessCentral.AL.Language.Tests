// @expect AL0145 | Direct assignment is not valid for arrays. Use array indexing to assign individual elements or a loop to copy elements.
// An array variable assigned the result of a procedure that returns an array of the same type (al-runner issue 6658, writer Y66); CopyArray
// is the way: tests/al-language/collections/lt-y66-copyarray-fn-result/Y66CopyArrayFnResult.al. A scalar into an array: case 0291.
codeunit 52642 "MNC Y66 Array Provider B"
{
    procedure Get(): array[2] of Guid
    begin
    end;
}

codeunit 52643 "MNC Y66 Assign Array Result"
{
    procedure P()
    var
        Provider: Codeunit "MNC Y66 Array Provider B";
        Target: array[2] of Guid;
    begin
        Target := Provider.Get();
    end;
}
