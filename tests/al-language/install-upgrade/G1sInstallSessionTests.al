// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-filtergroup-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); XApp A tests/al-language-xapp-a/G1sXaInstall.al (tables 98470, 98471, 98474, codeunits 98472,
//   98473); XApp B tests/al-language-xapp-b/G1sXbInstall.al (install codeunit 98475); main app install codeunit 98482 below.
// Probe (al-runner issue 8071): a filter in filter group 1 set in one app's install session (XApp A), read with a new record (a) in a
//   later app's install session (XApp B), (b) in the main app's install session, (d) in the test session. Cell c (al-runner issue 7586
//   comment): an OnAfterLogin subscriber sets a group 1 filter on table 98474 in every session; XApp B's install code clears it; what
//   the main app's install code and the test session see. Each entry is 'count=<n>;g1=<group 1 filters>'; each table holds two rows,
//   one with Qty >= 3.
// Measured in the CI run of the pull request (BC 27.5, 28.5 and 29.0 gave the same values); the Expect lines are what BC did.
//   G1S_PerCompany_AllSessions repeats a, b, d and the main app on table 98485 (DataPerCompany = true, install code from OnInstallAppPerCompany).
// BC versions: 27 - 29

codeunit 98482 "LT G1S Main Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        Item: Record "LT G1S Item";
        LoginItem: Record "LT G1S Login Item";
        CoItem: Record "LT G1S Company Item";
        Log: Codeunit "LT G1S XA Log";
    begin
        Log.Log('Main company other session', Log.SeenCompany(CoItem));
        Log.Log('Main other session', Log.Seen(Item));
        Log.Log('Main login item', Log.SeenLogin(LoginItem));
    end;
}

codeunit 98480 "LT G1S Install Session Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Entry(Name: Text): Text
    var
        L: Record "LT G1S Log";
    begin
        if not L.Get(CopyStr(Name, 1, MaxStrLen(L.Entry))) then
            exit('No entry');
        exit(L.Detail);
    end;

    [Test]
    procedure G1S_A_SameInstallSession()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('A same session', Entry('A same session'));
        Observer.Expect('A same session', 'count=1;g1=Qty: >=3');
        Observer.Verify();
    end;

    [Test]
    procedure G1S_B_OtherAppInstallSession()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('B other session', Entry('B other session'));
        Observer.Expect('B other session', 'count=2;g1=');
        Observer.Verify();
    end;

    [Test]
    procedure G1S_Main_InstallSession()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('Main other session', Entry('Main other session'));
        Observer.Expect('Main other session', 'count=2;g1=');
        Observer.Verify();
    end;

    [Test]
    procedure G1S_TestSession()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT G1S Item";
        Log: Codeunit "LT G1S XA Log";
    begin
        Observer.Observe('test session', Log.Seen(Item));
        Observer.Expect('test session', 'count=2;g1=');
        Observer.Verify();
    end;

    [Test]
    procedure G1S_LoginFilter_ClearedInInstallCode()
    var
        Observer: Codeunit "Probe Observer";
        LoginItem: Record "LT G1S Login Item";
        Log: Codeunit "LT G1S XA Log";
    begin
        Observer.Observe('A login item', Entry('A login item'));
        Observer.Observe('B before clear', Entry('B login item before clear'));
        Observer.Observe('B after clear', Entry('B login item after clear'));
        Observer.Observe('Main login item', Entry('Main login item'));
        Observer.Observe('test session login item', Log.SeenLogin(LoginItem));
        Observer.Expect('A login item', 'count=1;g1=Qty: >=3');
        Observer.Expect('B before clear', 'count=1;g1=Qty: >=3');
        Observer.Expect('B after clear', 'count=2;g1=');
        Observer.Expect('Main login item', 'count=1;g1=Qty: >=3');
        Observer.Expect('test session login item', 'count=1;g1=Qty: >=3');
        Observer.Verify();
    end;

    [Test]
    procedure G1S_PerCompany_AllSessions()
    var
        Observer: Codeunit "Probe Observer";
        CoItem: Record "LT G1S Company Item";
        Log: Codeunit "LT G1S XA Log";
    begin
        Observer.Observe('company A same session', Entry('A company same session'));
        Observer.Observe('company B other session', Entry('B company other session'));
        Observer.Observe('company Main other session', Entry('Main company other session'));
        Observer.Observe('company test session', Log.SeenCompany(CoItem));
        Observer.Expect('company A same session', 'count=1;g1=Qty: >=3');
        Observer.Expect('company B other session', 'count=2;g1=');
        Observer.Expect('company Main other session', 'count=2;g1=');
        Observer.Expect('company test session', 'count=2;g1=');
        Observer.Verify();
    end;
}
