// @expect AL0132 | 'Version' does not contain a definition for 'ToUpper'
// In a codeunit without TableNo, Version is the Version type, which has no ToUpper.
codeunit 53155 "MNC VT3155 C"
{
    procedure GetVersion(): Text
    begin
        exit(Version.ToUpper());
    end;
}
