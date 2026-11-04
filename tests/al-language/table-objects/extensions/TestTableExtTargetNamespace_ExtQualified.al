// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object
// Scope: in-scope
// Fixtures used: Shipment Method (69422), TXN Local Qualified Ext (69424),
//                TXN Base Qualified Ext (69425), TXN Logger (69421)
//
// A file with NO namespace of its own, whose tableextensions name their table with the namespace
// written out: once for this app's "Shipment Method", once for Base Application's table of the same
// name. It imports only the logger's namespace, so neither table is reachable unqualified from
// here. The extension of Base Application's table declares field 69423 as Text, where the
// extension of this app's table declares it as Integer.

using ALLanguage.Coverage.TxnShared;

tableextension 69424 "TXN Local Qualified Ext" extends ALLanguage.Coverage.TxnLocal."Shipment Method"
{
    fields
    {
        field(69426; "TXN Local Qualified"; Integer) { DataClassification = CustomerContent; }
    }

    trigger OnInsert()
    var
        Logger: Codeunit "TXN Logger";
    begin
        Logger.Log('local-qualified');
    end;
}

tableextension 69425 "TXN Base Qualified Ext" extends Microsoft.Foundation.Shipping."Shipment Method"
{
    fields
    {
        field(69423; "TXN Base Shared Id"; Text[20])
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                Logger: Codeunit "TXN Logger";
            begin
                Logger.Log('base-validate');
            end;
        }
        field(69425; "TXN Base Only"; Integer) { DataClassification = CustomerContent; }
        modify("Code") { Caption = 'TXN Base Code'; }
    }

    keys
    {
        key(TXNBaseKey; Description, "Code") { }
    }

    trigger OnInsert()
    var
        Logger: Codeunit "TXN Logger";
    begin
        Logger.Log('base-qualified');
    end;
}
