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

    local procedure Dump(From: Integer; Count: Integer; Objects: Boolean): Text
    var
        Row: Record "LT Y79 XA Seen";
        Result: Text;
        Index: Integer;
    begin
        Row.SetRange("Company", 'CRONUS USA, Inc.');
        if Row.FindSet() then
            repeat
                if Row.Tag.Contains('objects|') = Objects then begin
                    Index += 1;
                    if (Index >= From) and (Index < From + Count) then
                        Result += Format(Row.Seq) + ':' + Row.Tag + ' ## ';
                end;
            until Row.Next() = 0;
        exit(Result);
    end;

    local procedure Total(): Text
    var
        Row: Record "LT Y79 XA Seen";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                if StrPos(Result, '[' + Row."Company" + ']') = 0 then
                    Result += '[' + Row."Company" + ']';
            until Row.Next() = 0;
        exit(Format(Row.Count()) + Result);
    end;

    [Test]
    procedure Y79_Dump1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('dump', Dump(1, 14, false));
        Observer.Finish();
    end;

    [Test]
    procedure Y79_Dump2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('dump', Dump(15, 14, false));
        Observer.Finish();
    end;

    [Test]
    procedure Y79_Dump3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('dump', Dump(29, 14, false));
        Observer.Finish();
    end;

    [Test]
    procedure Y79_Dump4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('dump', Dump(43, 14, false));
        Observer.Finish();
    end;

    [Test]
    procedure Y79_Dump5()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('dump', Dump(57, 14, false));
        Observer.Finish();
    end;

    [Test]
    procedure Y79_Dump6()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('dump', Dump(71, 14, false));
        Observer.Finish();
    end;

    [Test]
    procedure Y79_Dump7()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('dump', Dump(85, 14, false));
        Observer.Finish();
    end;

    [Test]
    procedure Y79_Dump8()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('dump', Dump(99, 14, false));
        Observer.Finish();
    end;

    [Test]
    procedure Y79_Dump9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('dump', Dump(113, 14, false));
        Observer.Finish();
    end;

    [Test]
    procedure Y79_Objects1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('objects', Dump(1, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure Y79_Objects2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('objects', Dump(2, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure Y79_Objects3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('objects', Dump(3, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure Y79_Objects4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('objects', Dump(4, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure Y79_Objects5()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('objects', Dump(5, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure Y79_Objects6()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('objects', Dump(6, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure Y79_Objects7()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('objects', Dump(7, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure Y79_Objects8()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('objects', Dump(8, 1, true));
        Observer.Finish();
    end;

    [Test]
    procedure Y79_Total()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('total', Total());
        Observer.Finish();
    end;
}
