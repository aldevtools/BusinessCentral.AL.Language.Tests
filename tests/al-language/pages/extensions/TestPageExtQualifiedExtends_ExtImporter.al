// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-extension-object
// Scope: in-scope
// Fixtures used: PXQ Plain (69404), PXQ Logger (69401)
//
// A file in a THIRD namespace that reaches "PXQ Plain" two ways: unqualified through a
// `using`, and written out with its namespace. The unqualified form is the positive control.

namespace ALLanguage.Coverage.PxqImporter;

using ALLanguage.Coverage.PxqLocal;
using ALLanguage.Coverage.PxqShared;

pageextension 69410 "PXQ Imported Ext" extends "PXQ Plain"
{
    trigger OnOpenPage()
    var
        Logger: Codeunit "PXQ Logger";
    begin
        Logger.Log('plain-imported');
    end;
}

pageextension 69411 "PXQ Qualified Plain Ext" extends ALLanguage.Coverage.PxqLocal."PXQ Plain"
{
    trigger OnOpenPage()
    var
        Logger: Codeunit "PXQ Logger";
    begin
        Logger.Log('plain-qualified');
    end;
}
