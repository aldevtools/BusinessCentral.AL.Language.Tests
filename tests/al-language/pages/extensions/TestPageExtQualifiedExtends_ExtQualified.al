// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-extension-object
// Scope: in-scope
// Fixtures used: Shipping Agent Services (69403), PXQ Logger (69401)
//
// A file with NO namespace of its own, whose pageextensions name their base page with the
// namespace written out: once for this app's "Shipping Agent Services", once for Base
// Application's page of the same name. It imports only the logger's namespace, so neither page
// is reachable unqualified from here.

using ALLanguage.Coverage.PxqShared;

pageextension 69408 "PXQ Qualified Local Ext" extends ALLanguage.Coverage.PxqLocal."Shipping Agent Services"
{
    trigger OnOpenPage()
    var
        Logger: Codeunit "PXQ Logger";
    begin
        Logger.Log('local-qualified');
    end;
}

pageextension 69409 "PXQ Qualified Base Ext" extends Microsoft.Foundation.Shipping."Shipping Agent Services"
{
    trigger OnOpenPage()
    var
        Logger: Codeunit "PXQ Logger";
    begin
        Logger.Log('base-qualified');
    end;
}
