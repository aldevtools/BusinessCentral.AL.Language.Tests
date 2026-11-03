// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-extension-object
// Scope: in-scope
// Fixtures used: PXQ Row (69402), PXQ Logger (69401)
//
// Namespace PxqLocal. "Shipping Agent Services" reuses the name of Base Application page 5790,
// which lives in Microsoft.Foundation.Shipping; AL allows that because the namespaces differ.
// "PXQ Plain" has a name nothing else uses. The extension below names its page WITHOUT a
// qualifier, from inside the namespace that declares it.

namespace ALLanguage.Coverage.PxqLocal;

using ALLanguage.Coverage.PxqShared;

page 69403 "Shipping Agent Services"
{
    PageType = Card;
    SourceTable = "PXQ Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
        }
    }
}

page 69404 "PXQ Plain"
{
    PageType = Card;
    SourceTable = "PXQ Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
        }
    }
}

pageextension 69405 "PXQ Own Ext" extends "Shipping Agent Services"
{
    trigger OnOpenPage()
    var
        Logger: Codeunit "PXQ Logger";
    begin
        Logger.Log('local-own');
    end;
}
