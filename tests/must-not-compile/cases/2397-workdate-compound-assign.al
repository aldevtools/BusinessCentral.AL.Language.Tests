// @expect AL0129 | The left-hand side of an assignment must be a variable or field
// A compound assignment to a bare system function: `WorkDate += 1` is refused; `WorkDate := D` compiles. (al-runner 7597)
codeunit 50000 "MNC C2397"
{
    procedure Run1()
    begin
        WorkDate += 1;
    end;
}
