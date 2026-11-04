// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object
// Scope: in-scope
// Fixtures used: TXN Own Namespace Ext (69429), TXN Logger (69421)
//
// A file in the namespace of Base Application's "Shipment Method" that also imports the namespace of
// this app's table of the same name. Its bare `extends "Shipment Method"` resolves in the file's own
// namespace first, so it extends Base Application's table and not the imported one: writing the
// extension's field on Base Application's record compiles, and on this app's record it does not.

namespace Microsoft.Foundation.Shipping;

using ALLanguage.Coverage.TxnLocal;
using ALLanguage.Coverage.TxnShared;

tableextension 69429 "TXN Own Namespace Ext" extends "Shipment Method"
{
    fields
    {
        field(69429; "TXN Own Namespace Added"; Integer) { DataClassification = CustomerContent; }
    }

    trigger OnInsert()
    var
        Logger: Codeunit "TXN Logger";
    begin
        Logger.Log('base-own-namespace');
    end;
}
