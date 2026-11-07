// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
// Scope: in-scope
// Probe (writer SO, al-runner issue 6924, reporter waldo): two apps of one publisher that do not depend on each other, the first with the lower app
//   id and name, subscribe to the same table event (Sales Header OnAfterCopyShipToCustomerAddressFieldsFromCustomer); on BC the subscriber of the
//   second ran first. Already pinned in BwSubscriberOrderTests.al: Company OnBeforeModifyEvent runs A F B D C M, one rule being "apps visited in
//   ascending app id, each app's dependencies placed before it". This file asks whether the other event kinds follow the same order.
//   Apps (CI publishes F, A, D, B, C, M): F f1e2d3c4 (AL Internals Test Fixture, no dependencies), A cd6a4292 (AL Language XApp A, none),
//   B c87ced6d (Zulu Probe Publisher, depends on F and A), D e92be076 (Mike Probe Publisher, depends on A), C 0df0fadc (Bravo Probe Publisher,
//   depends on B, A and D), M a1b2c3d4 (depends on F, A, B and C). Pairs without a dependency path: F and A, F and D, B and D.
//   F cannot subscribe to a Base Application event (it has no dependency on it), so the two Base Application events have five subscribers.
//   Predictions: depth first from the lowest app id (C), dependencies in ascending id: A F B D C M | publish order F A D B C M |
//   ascending id with ties among ready apps: A F D B C M... | app name F A B C D M.
// Observed: see the Expect lines (BC 27.5, 28.5, 29.0).
// Fixtures: SoOrderFixtures.al, tests/al-language-internals-fixture/SoXfOrder.al, tests/al-language-xapp-a|b|c|d/So*Order.al. Probe Observer (69160).
// BC versions: 27 - 29

codeunit 96317 "LT SO Subscriber Order Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure SubscriberOrder_CompanyOnAfterModifyEvent_SixApps()
    var
        Raiser: Codeunit "LT SO Raiser";
    begin
        Observer.Observe('order', Raiser.RaiseCompany());
        Observer.Observe('order again', Raiser.RaiseCompany());
        Observer.Expect('order', 'A;F;B;D;C;M;');
        Observer.Expect('order again', 'A;F;B;D;C;M;');
        Observer.Verify();
    end;

    [Test]
    procedure SubscriberOrder_ReasonCodeOnAfterModifyEvent_FiveApps()
    var
        Raiser: Codeunit "LT SO Raiser";
    begin
        Observer.Observe('order', Raiser.RaiseReasonCode());
        Observer.Observe('order again', Raiser.RaiseReasonCode());
        Observer.Expect('order', 'A;B;D;C;M;');
        Observer.Expect('order again', 'A;B;D;C;M;');
        Observer.Verify();
    end;

    [Test]
    procedure SubscriberOrder_SalesHeaderOnAfterCopyShipToCustomerAddressFields_FiveApps()
    var
        Raiser: Codeunit "LT SO Raiser";
        Result: Text;
        Result2: Text;
    begin
        Observer.Observe('raised', Format(Raiser.RaiseShipTo(Result)));
        Observer.Observe('order', Result);
        Observer.Observe('raised again', Format(Raiser.RaiseShipTo(Result2)));
        Observer.Observe('order again', Result2);
        Observer.Expect('raised', 'Yes');
        Observer.Expect('order', 'A;B;D;C;M;');
        Observer.Expect('raised again', 'Yes');
        Observer.Expect('order again', 'A;B;D;C;M;');
        Observer.Verify();
    end;
}
