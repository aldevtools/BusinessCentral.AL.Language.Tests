// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extensible-enums
// Scope: in-scope
// Fixtures used: LT EMF Kind (97997) and LT EMF Line (97997) of AL Language XApp A; LT EMF Kind (97055,
//   EnumMemberFieldType_Twin.al).
// Namespace EmfBoth with a `using` of the namespace of LT EMF Line.Kind's enum and of EmfTwin, whose enum has the same name:
// the usings find the name twice, once as the field's enum. The reader names `Line.Kind::Production`.
// local object: the reader of EnumMemberFieldTypeShapes_Tests.al.

namespace ALLanguage.Coverage.EmfBoth;

using ALLanguage.Coverage.EmfData;
using ALLanguage.Coverage.EmfEnums;
using ALLanguage.Coverage.EmfTwin;

codeunit 97049 "LT EMF Both Usings Reader"
{
    procedure ProductionOrdinal(): Integer
    var
        Line: Record "LT EMF Line";
    begin
        Line.Kind := Line.Kind::Production;
        exit(Line.Kind.AsInteger());
    end;
}
