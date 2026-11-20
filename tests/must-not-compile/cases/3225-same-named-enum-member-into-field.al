// @expect AL0122 | Cannot implicitly convert type 'Enum MncEmf.Twin3225."LT EMF Kind"' to 'Enum ALLanguage.Coverage.EmfEnums."LT EMF Kind"'.
// @depends Base Application,System Application,AL Language XApp A
// al-runner issue 8317 (review of pull request 8319): a file in a namespace that declares its own enum named like the enum of
// XApp A's LT EMF Line.Kind (namespace EmfEnums). There `Line.Kind::Production` is the field's enum's member and
// `Line.Kind := Line.Kind::Production` compiles (tests/al-language/types/enum-option/EnumMemberFieldType_Twin.al): the
// field `Line.Kind` itself is of the field's enum type, not of the enum the file finds by the name.
// So a member of the file's enum does not convert to the field: AL0122.
// The enum here has the field's enum's name on purpose (the MNC prefix would make it another name).
namespace MncEmf.Twin3225;

using ALLanguage.Coverage.EmfData;

enum 53225 "LT EMF Kind"
{
    value(0; " ") { }
    value(5; Production) { }
    value(6; OnlyTwin) { }
}

codeunit 53225 "MNC EMF Twin 3225"
{
    procedure Read()
    var
        Line: Record "LT EMF Line";
    begin
        Line.Kind := "LT EMF Kind"::Production;
    end;
}
