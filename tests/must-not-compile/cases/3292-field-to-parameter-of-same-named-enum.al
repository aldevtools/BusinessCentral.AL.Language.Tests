// @expect AL0133 | Argument 1: cannot convert from 'Enum ALLanguage.Coverage.EmfEnums."LT EMF Kind"' to 'Enum MncEmf.Twin3292."LT EMF Kind"'
// @depends Base Application,System Application,AL Language XApp A
// al-runner issue 8317 (review of pull request 8319): a file in a namespace that declares its own enum named like the enum of
// XApp A's LT EMF Line.Kind (namespace EmfEnums). There `Line.Kind::Production` is the field's enum's member and
// `Line.Kind := Line.Kind::Production` compiles (tests/al-language/types/enum-option/EnumMemberFieldType_Twin.al): the
// field `Line.Kind` itself is of the field's enum type, not of the enum the file finds by the name.
// So the field is no argument for a parameter of the file's enum: AL0133.
// The enum here has the field's enum's name on purpose (the MNC prefix would make it another name).
namespace MncEmf.Twin3292;

using ALLanguage.Coverage.EmfData;

enum 53292 "LT EMF Kind"
{
    value(0; " ") { }
    value(5; Production) { }
    value(6; OnlyTwin) { }
}

codeunit 53292 "MNC EMF Twin 3292"
{
    procedure Read()
    var
        Line: Record "LT EMF Line";
    begin
        Take(Line.Kind);
    end;

    procedure Take(Value: Enum "LT EMF Kind")
    begin
    end;
}
