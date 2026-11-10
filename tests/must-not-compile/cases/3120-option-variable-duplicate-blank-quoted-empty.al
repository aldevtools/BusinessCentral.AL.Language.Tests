// Two Option members named "" (quoted empty) in an Option variable are refused. Evaluate and Format of a single "" member: tests/al-language/format-evaluate/format-matrix/FMOptionBlankVar.al.
// @expect AL0152 | The value '' is used more than once
codeunit 53300 "MNC OB C1"
{
    procedure P()
    var
        O: Option "",A,"";
    begin
        O := O::A;
    end;
}
