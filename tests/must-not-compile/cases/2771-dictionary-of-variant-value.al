// @expect AL0408 | The type 'Variant' cannot be used as a type argument in this context.
// A Dictionary of [Text, Variant] is not allowed: Variant cannot be a type argument.
codeunit 50000 "MNC Dictionary Of Variant"
{
    procedure P()
    var
        D: Dictionary of [Text, Variant];
    begin
        D.Add('k', 1);
    end;
}
