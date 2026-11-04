// @expect AL0129 | The left-hand side of an assignment must be a variable or field
// The this keyword is not assignable (no variable involved).
codeunit 50000 "MNC This Self Assign"
{
    procedure P()
    begin
        this := this;
    end;
}
