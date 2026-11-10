// An Enum value named "" has no name to write after E::"" (not defined).
// @expect AL0132 | 'E' does not contain a definition for ''
enum 53312 "MNC OB E13"
{
    value(0; "") { }
    value(1; A) { }
}
codeunit 53313 "MNC OB C14"
{
    procedure P()
    var
        E: Enum "MNC OB E13";
    begin
        E := E::"";
    end;
}
