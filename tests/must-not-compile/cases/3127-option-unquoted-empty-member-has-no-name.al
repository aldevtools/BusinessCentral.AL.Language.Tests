// An unquoted empty member of an Option variable has no name to write after O:: (O::"" is not defined).
// @expect AL0132 | 'O' does not contain a definition for ''
codeunit 53307 "MNC OB C8"
{
    procedure P()
    var
        O: Option ,A,B;
    begin
        O := O::"";
    end;
}
