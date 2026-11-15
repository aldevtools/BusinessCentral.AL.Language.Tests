// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-filtergroup-method
// Scope: in-scope
// Probe (see tests/al-language-xapp-a/G1sXaInstall.al): XApp B's install session, after XApp A's. 98475 counts table 98470 with a new
//   record (does A's group 1 filter reach B's install session?), then clears the OnAfterLogin group 1 filter on table 98474
//   (cell c) and counts before and after.
// Install code must never fail (check-install-triggers.py): it writes only `if Insert() then;` into DataPerCompany = false tables.
//   Tests: tests/al-language/install-upgrade/G1sInstallSessionTests.al.
// BC versions: 27 - 29

codeunit 98475 "LT G1S XB Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        Item: Record "LT G1S Item";
        LoginItem: Record "LT G1S Login Item";
        Cleared: Record "LT G1S Login Item";
        CoItem: Record "LT G1S Company Item";
        Log: Codeunit "LT G1S XA Log";
    begin
        Log.Log('B other session', Log.Seen(Item));
        Log.Log('B company other session', Log.SeenCompany(CoItem));
        Log.Log('B login item before clear', Log.SeenLogin(LoginItem));
        LoginItem.FilterGroup(1);
        LoginItem.SetRange(Qty);
        LoginItem.FilterGroup(0);
        Log.Log('B login item after clear', Log.SeenLogin(Cleared));
    end;
}
