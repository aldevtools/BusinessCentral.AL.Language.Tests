// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extensible-enums
// Scope: in-scope
// Fixtures used: LT EMF Line (97997) of AL Language XApp A; LT EMF Kind (97055, EnumMemberFieldType_Twin.al); LT EMF Kind
//   (61110) of AL Language XApp B (tests/al-language-xapp-b/EnumMemberFieldTypeXbTwin.al).
// Namespace EmfTwins with a `using` of EmfTwin and of XApp B's EmfTwinB, which each declare an enum named like the enum of
// LT EMF Line.Kind (Production at ordinals 5 and 7), and none of the field's enum's namespace: the usings find the name
// twice, neither time as the field's enum. The reader names `Line.Kind::Production`.
// local object: the reader of EnumMemberFieldTypeShapes_Tests.al.

namespace ALLanguage.Coverage.EmfTwins;

using ALLanguage.Coverage.EmfData;
using ALLanguage.Coverage.EmfTwin;
using ALLanguage.Coverage.EmfTwinB;

codeunit 97050 "LT EMF Two Twins Reader"
{
    procedure ProductionOrdinal(): Integer
    var
        Line: Record "LT EMF Line";
    begin
        Line.Kind := Line.Kind::Production;
        exit(Line.Kind.AsInteger());
    end;
}
