// The member "" of an Option variable has no name to write after O:: (O::"" is not defined, so "" is the empty member, not a name).
// @expect AL0132 | 'O' does not contain a definition for ''
codeunit 53306 "MNC OB C7"
{
    procedure P()
    var
        O: Option A,B,"";
    begin
        O := O::"";
    end;
}
