// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/isolatedstorage/isolatedstorage-data-type
// Scope: in-scope
// Fixtures used: codeunit 61010 "ALT Isolated Storage Owner" (al-language-internals-fixture),
//                codeunit 67581 "ALT IS Store Subscriber"
//
// IsolatedStorage's default DataScope is Module, and a module is the app that owns the code
// calling it. So a key one app stores is invisible to another app, and the same key can hold
// a different value in each. The fixture codeunit runs inside the dependency app; this
// codeunit runs inside the main app. The same boundary holds for DataScope::Company: the
// primary key of table 2000000107 starts with the app id whatever the scope.

codeunit 67580 "Test Isolated Storage Per App"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Owner: Codeunit "ALT Isolated Storage Owner";

    [Test]
    procedure IsolatedStorage_KeySetByAnotherApp_IsNotVisibleHere()
    // CLAIM: a key the dependency app stores is contained there and not here.
    var
        Value: Text;
    begin
        Initialize();

        Assert.IsTrue(Owner.SetValue('ispa-theirs', 'dependency value'), 'the dependency app must store its key.');
        Assert.IsTrue(Owner.Contains('ispa-theirs'), 'the dependency app must see the key it stored.');

        Assert.IsFalse(IsolatedStorage.Contains('ispa-theirs'), 'another app''s module key must not be contained here.');
        Assert.IsFalse(IsolatedStorage.Get('ispa-theirs', Value), 'another app''s module key must not be readable here.');
        Assert.AreEqual('', Value, 'a failed Get must leave the value empty.');
    end;

    [Test]
    procedure IsolatedStorage_KeySetHere_IsNotVisibleToAnotherApp()
    // CLAIM: a key this app stores is contained here and not in the dependency app.
    begin
        Initialize();

        Assert.IsTrue(IsolatedStorage.Set('ispa-ours', 'main value'), 'this app must store its key.');
        Assert.IsTrue(IsolatedStorage.Contains('ispa-ours'), 'this app must see the key it stored.');

        Assert.IsFalse(Owner.Contains('ispa-ours'), 'this app''s module key must not be contained in the dependency app.');
    end;

    [Test]
    procedure IsolatedStorage_SameKeyInTwoApps_HoldsEachAppsOwnValue()
    // CLAIM: one key name holds an independent value per app; neither write overwrites the other.
    var
        OurValue: Text;
        TheirValue: Text;
    begin
        Initialize();

        IsolatedStorage.Set('ispa-shared', 'main value');
        Owner.SetValue('ispa-shared', 'dependency value');

        Assert.IsTrue(IsolatedStorage.Get('ispa-shared', OurValue), 'this app must read its own value.');
        Assert.IsTrue(Owner.GetValue('ispa-shared', TheirValue), 'the dependency app must read its own value.');
        Assert.AreEqual('main value', OurValue, 'the dependency app''s write must not overwrite this app''s value.');
        Assert.AreEqual('dependency value', TheirValue, 'this app''s write must not overwrite the dependency app''s value.');
    end;

    [Test]
    procedure IsolatedStorage_CompanyKeySetByAnotherApp_IsNotVisibleHere()
    // CLAIM: the app boundary holds for DataScope::Company too -- a company-scoped key the
    // dependency app stores is contained there and not here, in the same company.
    var
        Value: Text;
    begin
        Initialize();

        Assert.IsTrue(Owner.SetCompanyValue('ispa-company', 'dependency company value'), 'the dependency app must store its company key.');
        Assert.IsTrue(Owner.ContainsCompany('ispa-company'), 'the dependency app must see the company key it stored.');

        Assert.IsFalse(IsolatedStorage.Contains('ispa-company', DataScope::Company), 'another app''s company key must not be contained here.');
        Assert.IsFalse(IsolatedStorage.Get('ispa-company', DataScope::Company, Value), 'another app''s company key must not be readable here.');
        Assert.AreEqual('', Value, 'a failed Get must leave the value empty.');
    end;

    [Test]
    procedure IsolatedStorage_SubscriberInThisApp_WritesThisAppsStore()
    // CLAIM: the module is the app owning the code that calls IsolatedStorage, not the app that
    // raised the event -- a subscriber here, handling the dependency app's event, stores here.
    var
        Subscriber: Codeunit "ALT IS Store Subscriber";
        Value: Text;
    begin
        Initialize();

        BindSubscription(Subscriber);
        Owner.RaiseStoreRequested('ispa-event', 'subscriber value');
        UnbindSubscription(Subscriber);

        Assert.IsTrue(IsolatedStorage.Get('ispa-event', Value), 'the subscriber''s write must land in the subscriber''s app.');
        Assert.AreEqual('subscriber value', Value, 'the subscriber''s value must be readable here.');
        Assert.IsFalse(Owner.Contains('ispa-event'), 'the raising app must not see a key its subscriber stored in another app.');
    end;

    local procedure Initialize()
    begin
        DeleteIfPresent('ispa-theirs');
        DeleteIfPresent('ispa-ours');
        DeleteIfPresent('ispa-shared');
        DeleteIfPresent('ispa-event');
        Owner.DeleteIfPresent('ispa-event');
        Owner.DeleteIfPresent('ispa-theirs');
        Owner.DeleteIfPresent('ispa-ours');
        Owner.DeleteIfPresent('ispa-shared');
        Owner.DeleteCompanyIfPresent('ispa-company');
        if IsolatedStorage.Contains('ispa-company', DataScope::Company) then
            IsolatedStorage.Delete('ispa-company', DataScope::Company);
    end;

    local procedure DeleteIfPresent(StorageKey: Text)
    begin
        if IsolatedStorage.Contains(StorageKey) then
            IsolatedStorage.Delete(StorageKey);
    end;
}
