// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained codeunits 68340..68342
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins (1) that a static event subscriber (EventSubscriberInstance = StaticAutomatic, the default) that
// is not SingleInstance runs on a new instance for every event: its global variable is back to 0 on
// the next event; (2) that "Period Invariant Name" of the Date table equals "Period Name" for month
// and day periods; (3) the Name, Abbreviated Name and Language Tag of three Windows Language rows.
// BC versions: 27.5

codeunit 68340 "Probe Static Pub"
{
    [IntegrationEvent(false, false)]
    procedure OnPing(var Result: Text)
    begin
    end;

    procedure Ping(): Text
    var
        Result: Text;
    begin
        OnPing(Result);
        exit(Result);
    end;
}

codeunit 68341 "Probe Static Sub"
{
    var
        Seen: Integer;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Probe Static Pub", 'OnPing', '', false, false)]
    local procedure HandlePing(var Result: Text)
    begin
        Seen += 1;
        Result += Format(Seen) + ',';
    end;
}

codeunit 68342 "Probe Static Date Win Lang"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure StaticSubscriber_GlobalVariable_StartsAgainForEveryEvent()
    var
        Publisher: Codeunit "Probe Static Pub";
    begin
        Assert.AreEqual('1,', Publisher.Ping(), 'first event');
        Assert.AreEqual('1,', Publisher.Ping(), 'second event');
        Assert.AreEqual('1,', Publisher.Ping(), 'third event');
    end;

    [Test]
    procedure DateTable_PeriodInvariantName_EqualsPeriodName()
    var
        DateRec: Record Date;
        Names: Text;
    begin
        DateRec.SetRange("Period Type", DateRec."Period Type"::Month);
        DateRec.SetRange("Period Start", 20240101D, 20240401D);
        DateRec.FindSet();
        repeat
            Assert.AreEqual(DateRec."Period Name", DateRec."Period Invariant Name", 'month');
            Names += DateRec."Period Invariant Name" + ',';
        until DateRec.Next() = 0;
        Assert.AreEqual('January,February,March,April,', Names, 'month names');

        Names := '';
        DateRec.SetRange("Period Type", DateRec."Period Type"::Date);
        DateRec.SetRange("Period Start", 20240101D, 20240107D);
        DateRec.FindSet();
        repeat
            Assert.AreEqual(DateRec."Period Name", DateRec."Period Invariant Name", 'day');
            Names += DateRec."Period Invariant Name" + ',';
        until DateRec.Next() = 0;
        Assert.AreEqual('Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday,', Names, 'day names');
    end;

    [Test]
    procedure WindowsLanguage_ThreeRows_NameAbbreviationAndTag()
    var
        WinLang: Record "Windows Language";
    begin
        WinLang.Get(1031);
        Assert.AreEqual('German (Germany)', WinLang.Name, '1031 name');
        Assert.AreEqual('DEU', WinLang."Abbreviated Name", '1031 abbreviated name');
        Assert.AreEqual('de-DE', WinLang."Language Tag", '1031 tag');

        WinLang.Get(1033);
        Assert.AreEqual('English (United States)', WinLang.Name, '1033 name');
        Assert.AreEqual('ENU', WinLang."Abbreviated Name", '1033 abbreviated name');
        Assert.AreEqual('en-US', WinLang."Language Tag", '1033 tag');

        WinLang.Get(2057);
        Assert.AreEqual('English (United Kingdom)', WinLang.Name, '2057 name');
        Assert.AreEqual('ENG', WinLang."Abbreviated Name", '2057 abbreviated name');
        Assert.AreEqual('en-GB', WinLang."Language Tag", '2057 tag');
    end;
}
