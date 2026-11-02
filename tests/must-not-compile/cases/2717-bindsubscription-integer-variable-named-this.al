// @expect AL0133 | Argument 1: cannot convert from 'Integer' to 'Codeunit'
// A variable "this" of type Integer is not a codeunit for BindSubscription.
codeunit 50000 "MNC This Integer"
{
    var
        "this": Integer;

    procedure P()
    begin
        BindSubscription("this");
    end;
}
