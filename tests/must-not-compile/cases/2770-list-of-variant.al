// @expect AL0408 | The type 'Variant' cannot be used as a type argument in this context.
// A List of [Variant] is not allowed: Variant cannot be a type argument.
codeunit 50000 "MNC List Of Variant"
{
    procedure P()
    var
        L: List of [Variant];
    begin
        L.Add(1);
    end;
}
