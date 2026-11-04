// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object
// Scope: in-scope
// Fixtures used: PXQ Logger (69401)
//
// The table-side twin: a tableextension whose `extends` clause writes the table's namespace.

namespace ALLanguage.Coverage.PxqLocal;

using ALLanguage.Coverage.PxqShared;

table 69412 "PXQ Table"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

tableextension 69413 "PXQ Table Ext" extends ALLanguage.Coverage.PxqLocal."PXQ Table"
{
    fields
    {
        field(69413; "PXQ Added"; Integer) { DataClassification = CustomerContent; }
    }

    trigger OnInsert()
    var
        Logger: Codeunit "PXQ Logger";
    begin
        Logger.Log('table-qualified');
    end;
}
