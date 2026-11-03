// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object
// Scope: in-scope
// Fixtures used: TXN Base Imported Ext (69427), TXN Logger (69421)
//
// A file in a THIRD namespace that imports Base Application's Microsoft.Foundation.Shipping and
// not the namespace of this app's "Shipment Method". Its bare `extends "Shipment Method"` can only
// mean Base Application's table.

namespace ALLanguage.Coverage.TxnImporter;

using ALLanguage.Coverage.TxnShared;
using Microsoft.Foundation.Shipping;

tableextension 69427 "TXN Base Imported Ext" extends "Shipment Method"
{
    fields
    {
        field(69427; "TXN Base Imported"; Integer) { DataClassification = CustomerContent; }
    }

    trigger OnInsert()
    var
        Logger: Codeunit "TXN Logger";
    begin
        Logger.Log('base-imported');
    end;
}
