// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-installation-codeunit
// Scope: in-scope
// Fixtures used: Install Event Seed (60832), Install Event Publisher (60833),
//                Install Event Subscriber (60834), Install Seeder (60618), Assert (60021)
//
// Does an integration event raised from INSIDE an install trigger reach its
// static subscribers?
//
// TestInstallTriggerSeed_Tests (60620) already proves that install triggers
// fire before the first [Test]. This file asks the next question, which that
// one does not cover: at the moment OnInstallAppPerCompany runs, is the app's
// own event-subscriber wiring live? The pattern matters because letting other
// code contribute setup rows through an event during install is the ordinary
// reason an app has an install trigger at all.
//
// The subscriber records WHICH mechanism reached it ('install-trigger'), so a
// pass cannot be produced by the subscriber merely running later from test
// code — the row would not exist at all in that case, and these tests never
// raise the event themselves.
//
// NOTE: deliberately no Initialize()/DeleteAll() — like its sibling file,
// this suite exists to observe rows written BEFORE any test code runs.

codeunit 60835 "Test Install Event Dispatch"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    trigger OnRun()
    begin
    end;

    [Test]
    procedure TestInstallEvent_SubscriberRanDuringInstall()
    var
        Seed: Record "Install Event Seed";
    begin
        Assert.IsTrue(Seed.Get('FROMEVENT'),
            'a subscriber to an integration event raised from OnInstallAppPerCompany must have run during install');
        Assert.AreEqual('install-trigger', Seed."Source",
            'the row must have been written by the install-trigger dispatch, not by anything else');
    end;

    [Test]
    procedure TestInstallEvent_SeededExactlyOneRow()
    var
        Seed: Record "Install Event Seed";
    begin
        // Guards the other direction from the Get() above: a dispatch that fired
        // repeatedly, or a subscriber invoked once per company without the Get
        // guard, would show up here rather than passing silently.
        Assert.AreEqual(1, Seed.Count(),
            'the install-trigger event subscriber must have seeded exactly one row');
    end;

    [Test]
    procedure TestInstallEvent_UnseededRowRaisesExpectedError()
    var
        Seed: Record "Install Event Seed";
    begin
        // Negative direction: the table really is queryable and a MISSING key
        // really does fail, so the passing assertions above are about the row
        // existing rather than about Get() answering true for anything.
        asserterror Seed.Get('NOSUCHROW');
        Assert.ExpectedError('Install Event Seed');
    end;
}
