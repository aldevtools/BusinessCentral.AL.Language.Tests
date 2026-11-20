// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extensible-enums
// Scope: in-scope
// Fixtures used: LT EMF Line (97997) of AL Language XApp A; LT EMF Kind (97055, EnumMemberFieldType_Twin.al).
// Namespace EmfUsing with a `using` of EmfTwin, whose enum has the name of LT EMF Line.Kind's enum, and none of the
// field's enum's namespace: `Line.Kind::Production` here, where the using finds the twin.
// local object: the using reader of EnumMemberFieldType_Tests.al.

namespace ALLanguage.Coverage.EmfUsing;

using ALLanguage.Coverage.EmfData;
using ALLanguage.Coverage.EmfTwin;

codeunit 97057 "LT EMF Using Reader"
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
