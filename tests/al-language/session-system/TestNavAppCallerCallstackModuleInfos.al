// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/navapp/navapp-getcallercallstackmoduleinfos-method
// Scope: in-scope
// Fixtures used: "ALT Callstack Module Infos" (61011, AL Internals Test Fixture app)
//
// NavApp.GetCallerCallstackModuleInfos lists the apps of the methods on the call stack,
// skipping only the method that asks, each app once, nearest caller first. These tests call
// into the fixture app so two apps are on the stack. They do not assert the list's length:
// what calls the test method is the test runner's business, not this app's.

codeunit 67595 "Test NavApp Callstack Infos"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure CallerCallstack_FromOtherApp_FirstEntryIsTheCallingApp()
    var
        Callee: Codeunit "ALT Callstack Module Infos";
        Infos: List of [ModuleInfo];
        Own: ModuleInfo;
        First: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(Own);

        Infos := Callee.CallerInfos();

        Assert.IsTrue(Infos.Count() >= 1, 'The list must name at least the calling app.');
        First := Infos.Get(1);
        Assert.AreEqual(Own.Id, First.Id, 'The first entry must be the app of the immediate caller (this test app).');
        Assert.AreEqual(Own.Name, First.Name, 'The first entry must carry the calling app''s name.');
        Assert.AreEqual(Own.Publisher, First.Publisher, 'The first entry must carry the calling app''s publisher.');
    end;

    [Test]
    procedure CallerCallstack_FromOtherApp_OmitsTheAskingApp()
    var
        Callee: Codeunit "ALT Callstack Module Infos";
    begin
        // Only the asking method's frame is skipped; the fixture app has no other frame on this
        // stack, so it must not be listed.
        Assert.AreEqual(0, CountOf(Callee.CallerInfos(), Callee.OwnAppId()),
            'The asking app must not be listed when none of its other methods is on the stack.');
    end;

    [Test]
    procedure CallerCallstack_ThroughOwnFrame_ListsTheAskingAppThenTheCaller()
    var
        Callee: Codeunit "ALT Callstack Module Infos";
        Infos: List of [ModuleInfo];
        Own: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(Own);

        Infos := Callee.CallerInfosThroughOwnFrame();

        Assert.IsTrue(Infos.Count() >= 2, 'The list must name the fixture frame and the calling app.');
        Assert.AreEqual(Callee.OwnAppId(), Infos.Get(1).Id,
            'A caller frame in the asking app is listed: only the asking method itself is skipped.');
        Assert.AreEqual(Own.Id, Infos.Get(2).Id, 'The test app follows the fixture frame that called the asking method.');
    end;

    [Test]
    procedure CallerCallstack_SameAppFramesTwice_ListsTheAppOnce()
    var
        Own: ModuleInfo;
        Infos: List of [ModuleInfo];
    begin
        NavApp.GetCurrentModuleInfo(Own);

        // This test method and the helper are both frames of this app.
        Infos := AskThroughHelper();

        Assert.AreEqual(Own.Id, Infos.Get(1).Id, 'The first entry must be this app.');
        Assert.AreEqual(1, CountOf(Infos, Own.Id), 'An app with several frames on the stack is listed once.');
    end;

    local procedure AskThroughHelper(): List of [ModuleInfo]
    var
        Callee: Codeunit "ALT Callstack Module Infos";
    begin
        exit(Callee.CallerInfos());
    end;

    local procedure CountOf(Infos: List of [ModuleInfo]; AppId: Guid): Integer
    var
        Info: ModuleInfo;
        N: Integer;
    begin
        foreach Info in Infos do
            if Info.Id = AppId then
                N += 1;
        exit(N);
    end;
}
