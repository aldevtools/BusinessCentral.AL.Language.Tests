// Install-order probe of cross-app fixture D (writer Y8): logs which rows of fixture A's table 61180 it sees during its own install, then writes
// row 10 with Insert(true). See tests/al-language-xapp-a/Y8XaInstallOrder.al. Install code must never fail: the helper writes only
// `if Insert(..) then;` into DataPerCompany = false tables.

codeunit 61190 "LT Y8 XD Install"
{
    Subtype = Install;

    trigger OnInstallAppPerDatabase()
    var
        Helper: Codeunit "LT Y8 XA Install Helper";
    begin
        Helper.LogAndWrite('D', 10);
    end;
}
