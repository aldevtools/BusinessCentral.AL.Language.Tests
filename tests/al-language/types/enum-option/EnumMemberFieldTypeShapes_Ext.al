// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extensible-enums
// Scope: in-scope
// Fixtures used: LT EMF Kind (97997) and LT EMF Line (97997) of AL Language XApp A.
// An enum extension of XApp A's LT EMF Kind (member Recall, ordinal 30, which no enum of that name in another namespace
// has) and a table extension that adds the Enum field "Ext Kind" of that enum to LT EMF Line, for
// EnumMemberFieldTypeShapes_Tests.al. This file names the enum through a `using` of its namespace.
// local object: fixtures of EnumMemberFieldTypeShapes_Tests.al.

namespace ALLanguage.Coverage.EmfExt;

using ALLanguage.Coverage.EmfData;
using ALLanguage.Coverage.EmfEnums;

enumextension 97048 "LT EMF Kind Recall" extends "LT EMF Kind"
{
    value(30; Recall) { }
}

tableextension 97049 "LT EMF Ext Kind Field" extends "LT EMF Line"
{
    fields
    {
        field(97048; "Ext Kind"; Enum "LT EMF Kind") { DataClassification = CustomerContent; }
    }
}
