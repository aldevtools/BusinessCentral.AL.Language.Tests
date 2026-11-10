// The member " " of an Option variable is not named "": O::"" is not defined when only " " exists.
// @expect AL0132 | 'O' does not contain a definition for ''
codeunit 53308 "MNC OB C9"
{
    procedure P()
    var
        O: Option " ",A,B;
    begin
        O := O::"";
    end;
}
