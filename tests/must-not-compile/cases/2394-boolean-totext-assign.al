// @expect AL0129 | The left-hand side of an assignment must be a variable or field
// Boolean.ToText has an overload without a parameter: `B.ToText := true` picks it and is refused. (al-runner 7597)
codeunit 50000 "MNC C2394"
{
    procedure Run1()
    var
        B: Boolean;
    begin
        B.ToText := true;
    end;
}
