// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
// Scope: in-scope
// Probe (writer TT, al-runner issue 6924, reporter waldo): does BC order the subscribers of different apps by walking from EVERY app in
//   ascending app id (placing each app's dependencies before it), or only from the apps that no other app depends on? The apps already
//   in the corpus have one such top-level app (M), so both readings gave the same order (SoSubscriberOrderTests.al, BwSubscriberOrderTests.al).
//   This probe adds a second top-level app and a dependency app whose id is out of line with its dependent.
//   Subscribers (Company OnAfterModifyEvent on a temporary record named 'LT TT ORDER', each appends its letter): A, N, T, M.
//   Apps, with their ids (compared as text), publisher and publish order (CI publishes F, A, D, B, C, N, T, M):
//     N 01a5e2c7 Yankee Probe Publisher, depends on nothing; lowest id of all corpus apps; only T depends on it.
//     C 0df0fadc, M a1b2c3d4 (AL Language, depends on F, A, B, C), A cd6a4292 (AL Language, depends on nothing), and the apps B, D, F of the
//     earlier probes (they have no subscriber on this event).
//     T f7c3b9d2 Aaa Probe Publisher, depends on N only; highest id of all corpus apps; nothing depends on it.
//   Top-level apps (no app depends on them): M and T. N is not one (T depends on it). A is not one (D, B, C, M depend on it).
//   Predictions (al-runner crates/al-vm/src/dispatch.rs visit_orders, plus the rules the corpus already ruled out for four apps):
//     every app in ascending id, dependencies first (depth first)   N A M T   (N is the lowest id, then C's walk places A, then M, then T)
//     only top-level apps in ascending id (M, then T)              A M N T   (M's walk places A, then M, then T's walk places N, then T)
//     only top-level apps, by publisher then id (T, then M)         N T A M   (T's walk places N, then T, then M's walk places A, then M)
//     publish order                                                 A N T M
//     app id as text, ignoring dependencies                         N M A T
//     app name                                                      M A N T
//     publisher, then name                                          T M A N
//   All seven differ, so the observed order tells which one BC follows.
// Observed: see the Expect lines (BC 27.5, 28.5, 29.0).
// Fixtures: TtOrderFixtures.al, tests/al-language-xapp-a/TtXaOrder.al, tests/al-language-xapp-n, tests/al-language-xapp-t. Probe Observer (69160).
// BC versions: 27 - 29

codeunit 97802 "LT TT Subscriber Order Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure SubscriberOrder_CompanyOnAfterModifyEvent_TwoTopLevelApps()
    var
        Raiser: Codeunit "LT TT Raiser";
    begin
        Observer.Observe('order', Raiser.RaiseCompany());
        Observer.Observe('order again', Raiser.RaiseCompany());
        Observer.Finish();
    end;
}
