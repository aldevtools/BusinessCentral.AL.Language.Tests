// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extension-install-code
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); cross-app fixtures tests/al-language-xapp-a/Y64XaObjects.al (hub 61351, table 61354),
//   xapp-b/Y8XbInstallOrder.al (install 61356) and Y64XbObjects.al (subscriber 61355), xapp-d/Y8XdInstallOrder.al (install 61365, subscribers
//   61366); the install sequence of Y8 (table 61181 "LT Y8 XA Install Log", tests/al-language-xapp-a/Y8XaInstallOrder.al).
// Probe (writer Y64, al-runner issue 6644): do event subscribers of an app run while another app installs that has no dependency path to it
//   (B and D)? The install code of B and of D (per database and per company) raises an integration event of A and logs telemetry
//   (Telemetry.LogMessage, which raises the System Application event OnRegisterTelemetryLogger); B and D subscribe to A's event, D also to
//   OnRegisterTelemetryLogger. Each subscriber notes '<subscriber app>-sub|<installing app>|<db or co>' (D-tel for telemetry). The corpus CI
//   installs A, D, B, C; other hosts may install B before D. So the facts are asserted as relations to the install order that Y8's log records
//   (a subscriber of the other app ran exactly when that app was installed first), plus the own-app subscribers.
// Already pinned: table extension triggers of such an app during another app's install (install/lt-y8-install-order/Y8InstallOrderTests.al).
// BC versions: 27-29

codeunit 93328 "LT Y64 Install Subscribers"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure SeqOf(App: Text): Integer
    var
        Log: Record "LT Y8 XA Install Log";
    begin
        Log.SetRange(App, App);
        if Log.FindFirst() then
            exit(Log.Seq);
        exit(-1);
    end;

    local procedure Noted(Tag: Text): Boolean
    var
        Row: Record "LT Y64 XA Install Subs";
    begin
        exit(Row.Get(Tag));
    end;

    local procedure AllNoted(): Text
    var
        Row: Record "LT Y64 XA Install Subs";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Row.Tag + ';';
            until Row.Next() = 0;
        exit(Result);
    end;

    [Test]
    procedure Y64_InstallSubscribers_Observed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('noted', AllNoted());
        Observer.Observe('B before D', Format(SeqOf('B') < SeqOf('D')));
        Observer.Observe('seq known', Format((SeqOf('B') > 0) and (SeqOf('D') > 0)));
        Observer.Finish();
    end;

    [Test]
    procedure Y64_InstallSubscribers_Relations()
    var
        Observer: Codeunit "Probe Observer";
        BFirst: Boolean;
        Phase: Text;
        Phases: List of [Text];
    begin
        BFirst := SeqOf('B') < SeqOf('D');
        Phases.Add('db');
        Phases.Add('co');
        foreach Phase in Phases do begin
            Observer.Observe('own B ' + Phase, Format(Noted('B-sub|B|' + Phase)));
            Observer.Observe('own D ' + Phase, Format(Noted('D-sub|D|' + Phase)));
            Observer.Observe('own D telemetry ' + Phase, Format(Noted('D-tel|D|' + Phase)));
            Observer.Observe('B sub in D install iff B first ' + Phase, Format(Noted('B-sub|D|' + Phase) = BFirst));
            Observer.Observe('D sub in B install iff D first ' + Phase, Format(Noted('D-sub|B|' + Phase) = not BFirst));
            Observer.Observe('D telemetry sub in B install iff D first ' + Phase, Format(Noted('D-tel|B|' + Phase) = not BFirst));
        end;
        Observer.Finish();
    end;
}
