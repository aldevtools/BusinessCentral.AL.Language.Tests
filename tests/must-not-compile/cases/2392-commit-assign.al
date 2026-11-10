// @expect AL0129 | The left-hand side of an assignment must be a variable or field
// Commit has no parameter: `Commit := true` is refused. (al-runner 7597)
codeunit 50000 "MNC C2392"
{
    procedure Run1()
    begin
        Commit := true;
    end;
}
