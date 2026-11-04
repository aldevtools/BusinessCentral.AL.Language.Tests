// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object
// Scope: in-scope
// Fixtures used: Shipment Method (69422), TXN Local Own Ext (69423), TXN Logger (69421)
//
// Namespace TxnLocal. This "Shipment Method" reuses the name of Base Application table 291, which
// lives in Microsoft.Foundation.Shipping; AL allows that because the namespaces differ. The
// extension below names its table WITHOUT a qualifier, from inside the namespace that declares
// it, so the compiler resolves the name to this app's table and not to Base Application's.
// Its field 69423 reuses an id the extension of Base Application's table also declares: field
// ids are per table, so the two do not clash.

namespace ALLanguage.Coverage.TxnLocal;

using ALLanguage.Coverage.TxnShared;

table 69422 "Shipment Method"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Description; Text[100]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

tableextension 69423 "TXN Local Own Ext" extends "Shipment Method"
{
    fields
    {
        field(69423; "TXN Local Shared Id"; Integer)
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                Logger: Codeunit "TXN Logger";
            begin
                Logger.Log('local-validate');
            end;
        }
        field(69424; "TXN Local Only"; Integer) { DataClassification = CustomerContent; }
        modify("Code") { Caption = 'TXN Local Code'; }
    }

    keys
    {
        key(TXNLocalKey; "Code", Description) { }
    }

    trigger OnInsert()
    var
        Logger: Codeunit "TXN Logger";
    begin
        Logger.Log('local-own');
    end;
}
