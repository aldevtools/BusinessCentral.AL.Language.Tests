// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extension-install-code
// Scope: in-scope
// Fixtures used: Probe Observer (69160); cross-app fixtures tests/al-language-xapp-a/Y79XaObjects.al, xapp-b/Y79XbSubs.al, xapp-d/Y79XdSubs.al and the
//   install codeunits in Y8XaInstallOrder.al, Y8XbInstallOrder.al, Y8XdInstallOrder.al; the install sequence of Y8 (table 61181 "LT Y8 XA Install Log").
// Probe (writer Y79, al-runner issues 6644 and 6755, rt-install-1102 "needs probe"): what runs during the install of an app when another app
//   with no dependency path to it (B and D) has subscribers or table extensions. Per database AND per company.
codeunit 94170 "LT Y79 Install Unrelated"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Dump(From: Integer; Count: Integer): Text
    var
        Row: Record "LT Y79 XA Seen";
        Result: Text;
        Index: Integer;
    begin
        if Row.FindSet() then
            repeat
                Index += 1;
                if (Index >= From) and (Index < From + Count) then
                    Result += Format(Row.Seq) + '/' + CopyStr(Row."Company", 1, 4) + ':' + Row.Tag + ' ## ';
            until Row.Next() = 0;
        exit(Result);
    end;

    [Test]
    procedure Y79_Dump1()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y79 XA Seen";
    begin
        Observer.Observe('count', Format(Row.Count()));
        Observer.Observe('dump', Dump(1, 12));
        Observer.Finish();
    end;

    [Test]
    procedure Y79_Dump2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('dump', Dump(13, 12));
        Observer.Finish();
    end;

    [Test]
    procedure Y79_Dump3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('dump', Dump(25, 12));
        Observer.Finish();
    end;

    [Test]
    procedure Y79_Dump4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('dump', Dump(37, 12));
        Observer.Finish();
    end;

    [Test]
    procedure Y79_Dump5()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('dump', Dump(49, 12));
        Observer.Finish();
    end;

    [Test]
    procedure Y79_Dump6()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('dump', Dump(61, 12));
        Observer.Finish();
    end;
}
