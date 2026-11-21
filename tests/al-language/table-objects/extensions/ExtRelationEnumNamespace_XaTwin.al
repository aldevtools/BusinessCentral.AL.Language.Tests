// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extensible-enums
// Scope: in-scope
// Fixtures used: LT ERN XA Line (97996) and LT ERN XA Kind (97996) of AL Language XApp A
//   (tests/al-language-xapp-a/table-objects/ExtRelationEnumNamespaceXaEnum.al and _XaTable.al); LT ERN Order (97044)
//
// Namespace ErnXaTwin declares its own enum "LT ERN XA Kind", the name of the enum of XApp A's
// LT ERN XA Line.Kind, with Production at ordinal 2 (XApp A's has it at 1). The table extension in
// this namespace relates "Twin Ref" on `Kind = const(Production)`: the probe shows which enum the
// member is taken from. (Two enums of one name cannot be in one app, AL0197, so the field's enum
// lives in XApp A.)
// local object: the enum and table extension of the same-named enum cell of ExtRelationEnumNamespace_Tests.al.

namespace ALLanguage.Coverage.ErnXaTwin;

using ALLanguage.Coverage.ErnTargets;
using ALLanguage.Coverage.ErnXa;

enum 97047 "LT ERN XA Kind"
{
    Extensible = true;

    value(0; " ") { }
    value(2; Production) { }
}

tableextension 97046 "LT ERN XA Line Twin" extends "LT ERN XA Line"
{
    fields
    {
        field(97046; "Twin Ref"; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = if (Kind = const(Production)) "LT ERN Order"."No." where(Status = const(Released));
        }
    }
}
