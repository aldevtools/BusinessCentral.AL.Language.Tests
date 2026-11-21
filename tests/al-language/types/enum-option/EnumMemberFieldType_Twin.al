// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extensible-enums
// Scope: in-scope
// Fixtures used: LT EMF Line (97997) of AL Language XApp A.
// Namespace EmfTwin declares its own enum "LT EMF Kind", the name of the enum of XApp A's LT EMF Line.Kind,
// with Production at ordinal 5 (XApp A's has it at 1). The reader codeunit in this namespace names
// `Line.Kind::Production`, where the file's own namespace finds the twin first.
// local object: the twin enum and the own-namespace reader of EnumMemberFieldType_Tests.al.

namespace ALLanguage.Coverage.EmfTwin;

using ALLanguage.Coverage.EmfData;

enum 97055 "LT EMF Kind"
{
    Extensible = true;

    value(0; " ") { }
    value(5; Production) { }
}

codeunit 97056 "LT EMF Own Namespace Reader"
{
    procedure ProductionOrdinal(): Integer
    var
        Line: Record "LT EMF Line";
    begin
        Line.Kind := Line.Kind::Production;
        exit(Line.Kind.AsInteger());
    end;

    procedure IsProduction(var Line: Record "LT EMF Line"): Boolean
    begin
        exit(Line.Kind = Line.Kind::Production);
    end;
}
