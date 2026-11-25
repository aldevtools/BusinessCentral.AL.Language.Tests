// @expect AL0129 | The left-hand side of an assignment must be a variable or field
// A global Label of a codeunit is assigned to (case 0350 is the local Label; al-runner issue 8912).
codeunit 50170 "MNC C3830"
{
    var
        Lbl: Label 'abc';

    procedure Run1()
    begin
        Lbl := 'x';
    end;
}
