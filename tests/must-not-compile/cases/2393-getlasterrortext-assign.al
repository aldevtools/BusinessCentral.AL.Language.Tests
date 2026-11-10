// @expect AL0129 | The left-hand side of an assignment must be a variable or field
// GetLastErrorText has an overload without a parameter: `GetLastErrorText := true` picks it and is refused, although GetLastErrorText(true) compiles. (al-runner 7597)
codeunit 50000 "MNC C2393"
{
    procedure Run1()
    begin
        GetLastErrorText := true;
    end;
}
