// Two Option members named " " (one space) in an Option variable are refused.
// @expect AL0152 | The value ' ' is used more than once
codeunit 53301 "MNC OB C2"
{
    procedure P()
    var
        O: Option " ",A," ";
    begin
        O := O::A;
    end;
}
