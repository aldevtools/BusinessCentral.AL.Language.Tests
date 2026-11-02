// @expect AL0130 | A 'var' argument must be an assignable variable (field, variable, or parameter), not a constant or expression.
// Clear(this) does not compile although a variable "this" exists: unquoted this is the keyword.
codeunit 50000 "MNC This Clear"
{
    var
        "this": Codeunit "MNC This Clear";

    procedure P()
    begin
        Clear(this);
    end;
}
