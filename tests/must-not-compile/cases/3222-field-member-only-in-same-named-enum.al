// @expect AL0132 | 'Kind' does not contain a definition for 'OnlyTwin'
// @depends Base Application,System Application,AL Language XApp A
// al-runner issue 8317 (review of pull request 8319): a file in a namespace that declares its own enum named like the enum of
// XApp A's LT EMF Line.Kind (namespace EmfEnums). There `Line.Kind::Production` is the field's enum's member and
// `Line.Kind := Line.Kind::Production` compiles (tests/al-language/types/enum-option/EnumMemberFieldType_Twin.al): the
// field `Line.Kind` itself is of the field's enum type, not of the enum the file finds by the name.
// So a member only the file's enum has is no member of the field: AL0132.
// The enum here has the field's enum's name on purpose (the MNC prefix would make it another name).
namespace MncEmf.Twin3222;

using ALLanguage.Coverage.EmfData;

enum 53222 "LT EMF Kind"
{
    value(0; " ") { }
    value(5; Production) { }
    value(6; OnlyTwin) { }
}

codeunit 53222 "MNC EMF Twin 3222"
{
    procedure Read()
    var
        Line: Record "LT EMF Line";
    begin
        Line.Kind := Line.Kind::OnlyTwin;
    end;
}
