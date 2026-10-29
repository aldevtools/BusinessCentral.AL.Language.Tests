// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
//   and https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extension-install-code
// Scope: in-scope
// Probe (writer BW): the order in which BC runs the subscribers of one event, inside one app and across apps (corpus #664 item 152;
//   al-runtime-rs ADR-046 amendment 1, probes Q1, Q2 and Q3). Pinned before: inside one app, ordinary events run their subscriber
//   codeunits in ascending codeunit id (record/TestTableEventSequenceContracts.al, handlers/ProbeEventSubscriberOrder.al).
//
// Q2, across apps. One event of cross-app fixture A ("LT BW XA Order Publisher".OnBwOrder) has subscribers in four apps:
//   app                          | app id                               | publisher             | subscriber codeunits (tag)
//   A  AL Language XApp A        | cd6a4292-f27b-4af9-89bc-15a5956f5c71 | AL Language           | 61105 (A1), 61135 (A2)
//   B  AL Language XApp B        | c87ced6d-11a6-4ad2-87c7-ac10083d0a2f | Zulu Probe Publisher  | 61115 (B1), 61145 (B2)
//   C  AL Language XApp C        | 0df0fadc-d339-4b0f-a1d5-51dc51f10900 | Bravo Probe Publisher | 61125 (C1), 61155 (C2)
//   M  AL Language Coverage Tests| a1b2c3d4-e5f6-7890-abcd-ef1234567890 | AL Language           | 83960..83964 (P Q R S T)
//   Dependencies: B on A, C on A and B, M on A, B and C; CI publishes A, B, C, then M. Order of the apps each candidate rule predicts:
//     dependency/publish ABCM (reverse MCBA) | app id as text CMBA (ABMC) | app id as Guid.ToByteArray bytes BAMC (CMAB)
//     app id as SQL Server uniqueidentifier ACBM (MBCA) | app name MABC (CBAM) | publisher, then name MACB (BCAM)
//     codeunit id ignoring the app: A1 B1 C1 A2 B2 C2 P Q R S T (the only rule that splits one app's subscribers).
// Q1, inside one app. The five subscriber codeunits P..T of this app (folders a-order, b-order, c-order) subscribe to the event above,
//   to an event of this app ("LT BW Order Publisher".OnBwLocalOrder) and to the two install events of "Extension Triggers":
//   P 83960 "LT BW M Subs" (b-order, 2nd in its file) | Q 83961 "LT BW b Subs" (a-order, 1st file) | R 83962 "LT BW C Subs" (b-order, 1st)
//   S 83963 "LT BW A Subs" (namespace Zzz.Probe, a-order, 2nd file) | T 83964 "LT BW Y Subs" (c-order)
//   Predictions: ascending id PQRST; descending id TSRQP; descending name, ordinal QTPRS; descending name ignoring case TPRQS;
//   descending name with namespace S first; ascending name ignoring case SQRPT; file order QSRPT.
// Q3: a subscriber of cross-app fixture A to Company Triggers counts its calls per session; A's and this app's install routines log the count.
// Observed on BC 27.5, 28.5 and 29.0 (same on every leg and on a second raise):
//   Q2: A1 A2 B1 B2 C1 C2 P Q R S T = apps in dependency/publish order (A B C M), ascending codeunit id inside each app.
//     Not told apart by this setup: dependency order vs publish order (CI publishes in dependency order), and apps ordered by
//     their lowest subscriber codeunit id (A 61105 < B 61115 < C 61125 < M 83960).
//   Q1: P Q R S T = ascending codeunit id, for an event of this app and for the event of app A.
//   Q3: each app's install routines run in one session that is not the test session; app A's install and this app's install run in
//     different sessions. Each app runs OnInstallAppPerCompany for every company (the current company, then 'My Company') before
//     OnInstallAppPerDatabase. App A's Company Triggers subscribers (OnCompanyOpen + OnCompanyOpenCompleted) ran twice before each
//     per-company install row (the SingleInstance counter starts again per company) and not before the per-database rows
//     (company name empty there), in app A's own install and in this app's install.
// Install rows are written when the apps are installed (CI publish), so Initialize deletes nothing here.
// Fixtures: BwOrderFixtures.al, a-order/, b-order/, c-order/, tests/al-language-xapp-a|b|c. Probe Observer (69160).
// BC versions: 27 - 29

codeunit 83950 "LT BW Subscriber Order Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure SubscriberOrder_OneEventOfADependencyApp_AcrossFourApps()
    var
        Publisher: Codeunit "LT BW XA Order Publisher";
    begin
        Initialize();
        Observer.Observe('order', Publisher.Raise());
        Observer.Observe('order again', Publisher.Raise());
        Observer.Expect('order', 'A1;A2;B1;B2;C1;C2;P;Q;R;S;T;');
        Observer.Expect('order again', 'A1;A2;B1;B2;C1;C2;P;Q;R;S;T;');
        Observer.Verify();
    end;

    [Test]
    procedure SubscriberOrder_OneEventOfThisApp_FiveSubscriberCodeunits()
    var
        Publisher: Codeunit "LT BW Order Publisher";
    begin
        Initialize();
        Observer.Observe('order', Publisher.Raise());
        Observer.Observe('order again', Publisher.Raise());
        Observer.Expect('order', 'P;Q;R;S;T;');
        Observer.Expect('order again', 'P;Q;R;S;T;');
        Observer.Verify();
    end;

    [Test]
    procedure InstallOrder_ThisApp_FiveSubscribersPerCompanyAndPerDatabase()
    var
        Row: Record "LT BW Install Log";
        Rows: Text;
        Counts: Text;
        Contexts: Text;
        FirstSession: Integer;
        OneSession: Boolean;
    begin
        Initialize();
        OneSession := true;
        Row.SetCurrentKey(Id);
        if Row.FindSet() then begin
            FirstSession := Row."Session Id";
            repeat
                Rows += Row.Routine + '@' + Row.Part + '|' + Row.Company + ';';
                Counts += Row.Routine + '=' + Format(Row."XA Company Open Calls") + ';';
                Contexts += Row.Context + ';';
                if Row."Session Id" <> FirstSession then
                    OneSession := false;
            until Row.Next() = 0;
        end;
        Observer.Observe('rows', Format(Row.Count()));
        Observer.Observe('order', Rows);
        Observer.Observe('A company open calls', Counts);
        Observer.Observe('contexts', Contexts);
        Observer.Observe('one session', Format(OneSession));
        Observer.Observe('session is the test session', Format(FirstSession = SessionId()));
        Observer.Expect('rows', '15');
        Observer.Expect('order', 'P@company|<Company>;Q@company|<Company>;R@company|<Company>;S@company|<Company>;T@company|<Company>;P@company|My Company;Q@company|My Company;R@company|My Company;S@company|My Company;T@company|My Company;P@database|;Q@database|;R@database|;S@database|;T@database|;');
        Observer.Expect('A company open calls', 'P=2;Q=2;R=2;S=2;T=2;P=2;Q=2;R=2;S=2;T=2;P=0;Q=0;R=0;S=0;T=0;');
        Observer.Expect('contexts', 'Install;Install;Install;Install;Install;Install;Install;Install;Install;Install;Install;Install;Install;Install;Install;');
        Observer.Expect('one session', 'Yes');
        Observer.Expect('session is the test session', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure InstallOrder_DependencyAppA_TwoSubscribersAndCompanyOpenCalls()
    var
        Row: Record "LT BW XA Install Log";
        MainRow: Record "LT BW Install Log";
        Rows: Text;
        FirstSession: Integer;
        OneSession: Boolean;
    begin
        Initialize();
        OneSession := true;
        Row.SetCurrentKey(Id);
        if Row.FindSet() then begin
            FirstSession := Row."Session Id";
            repeat
                Rows += Row.Routine + '|' + Row.Company + '|calls=' + Format(Row."Company Open Calls") + '|' + Row.Context + ';';
                if Row."Session Id" <> FirstSession then
                    OneSession := false;
            until Row.Next() = 0;
        end;
        Observer.Observe('rows', Format(Row.Count()));
        Observer.Observe('order', Rows);
        Observer.Observe('one session', Format(OneSession));
        if MainRow.FindFirst() then
            Observer.Observe('same session as the install of this app', Format(MainRow."Session Id" = FirstSession));
        Observer.Expect('rows', '6');
        Observer.Expect('order', 'A1|<Company>|calls=2|Install;A2|<Company>|calls=2|Install;A1|My Company|calls=2|Install;A2|My Company|calls=2|Install;A1||calls=0|Install;A2||calls=0|Install;');
        Observer.Expect('one session', 'Yes');
        Observer.Expect('same session as the install of this app', 'No');
        Observer.Verify();
    end;

    // Writer QY (al-runtime-rs backlog "PROBES from multiapp-runtime", item 1): one event of cross-app fixture A
    // ("LT QY XA Order Publisher".OnQyOrder) whose subscriber apps are in another order by lowest subscriber codeunit id than by dependency:
    //   A 61138 (A) | B 61117 (B1), 61147 (B2) | C 61127 (C) | main app 87620 (M); B depends on A, C on A and B, the main app on all three.
    //   Predictions: dependency/publish order A;B1;B2;C;M; | apps by lowest subscriber id B1;B2;C;A;M; | codeunit id ignoring the app B1;C;A;B2;M;
    // Observed (BC 27.5, 28.5, 29.0): A;B1;B2;C;M; = apps in dependency/publish order; the lower subscriber ids of B and C do not move them before A.
    // Fixtures: tests/al-language-xapp-a|b|c/Qy*Objects.al, QyOrderFixtures.al.
    [Test]
    procedure SubscriberOrder_DependentAppsWithLowerSubscriberIds_AcrossFourApps()
    var
        Publisher: Codeunit "LT QY XA Order Publisher";
    begin
        Initialize();
        Observer.Observe('order', Publisher.RaiseOrder());
        Observer.Observe('order again', Publisher.RaiseOrder());
        Observer.Expect('order', 'A;B1;B2;C;M;');
        Observer.Expect('order again', 'A;B1;B2;C;M;');
        Observer.Verify();
    end;

    // Writer QY (al-runtime-rs backlog "PROBES from multiapp-runtime", item 2): apps that do not depend on each other. Cross-app fixture D
    // (tests/al-language-xapp-d, depends on A only) subscribes to "LT QY XA Order Publisher".OnQyIndep, as do A (61138), B (61117, 61147),
    // C (61127) and this app (87620). D and B, C and this app do not depend on each other. Needs D in app_dirs (publish order fixture, A, D, B, C).
    //   Predictions: publish order A;D;B1;B2;C;M; | lowest subscriber id B1;B2;C;A;D;M; | app name M A B C D | publisher, then name M A C D B
    // Observed (BC 27.5, 28.5, 29.0): A;B1;B2;C;M;D; = none of these predictions. D is published right after A, before B, but its subscriber
    // runs last, after the main app. Fixtures: tests/al-language-xapp-a|b|c|d/Qy*Objects.al, QyOrderFixtures.al.
    [Test]
    procedure SubscriberOrder_AppsThatDoNotDependOnEachOther_FiveApps()
    var
        Publisher: Codeunit "LT QY XA Order Publisher";
    begin
        Initialize();
        Observer.Observe('order', Publisher.RaiseIndep());
        Observer.Observe('order again', Publisher.RaiseIndep());
        Observer.Expect('order', 'A;B1;B2;C;M;D;');
        Observer.Expect('order again', 'A;B1;B2;C;M;D;');
        Observer.Verify();
    end;

    // Writer UA (al-runner NP Retail install refusal: Tests-TestLibraries and NP Retail, which do not depend on each other, both subscribe
    // to OnAfterGetDatabaseTableTriggerSetup; the test app depends on both). A platform table event (Company OnBeforeModifyEvent on a
    // temporary record) has two subscribers in each of six apps:
    //   app                             | app id (first group) | publisher    | subscriber ids (tags)
    //   F AL Internals Test Fixture     | f1e2d3c4             | AL Language  | 61095 (F1), 61096 (F2)
    //   A AL Language XApp A            | cd6a4292             | AL Language  | 61107 (A1), 61136 (A2)
    //   B AL Language XApp B            | c87ced6d             | Zulu Probe   | 61118 (B1), 61146 (B2)
    //   C AL Language XApp C            | 0df0fadc             | Bravo Probe  | 61121 (C1), 61151 (C2)
    //   D AL Language XApp D            | e92be076             | Mike Probe   | 61161 (D1), 61162 (D2)
    //   M AL Language Coverage Tests    | a1b2c3d4             | AL Language  | 90240 (M1), 90241 (M2)
    //   Dependencies: F and A depend on nothing (and not on each other), B on F and A, C on A and B, D on A, M on F, A, B and C.
    //   CI publishes F, A, D, B, C, M. F and A are the pair of interest: two apps that do not depend on each other, a third app (B, M)
    //   depends on both. Predictions: dependency order, ties by app name or lowest subscriber id: F A B C M D (F before A) |
    //   ties by app id: A before F | publish order: F A D B C M.
    // Fixtures: tests/al-language-internals-fixture/UaXfOrder.al, tests/al-language-xapp-a|b|c|d/Ua*Order.al, UaOrderFixtures.al.
    [Test]
    procedure SubscriberOrder_PlatformTableEvent_AppsThatDoNotDependOnEachOther_SixApps()
    var
        Raiser: Codeunit "LT UA Order Raiser";
    begin
        Initialize();
        Observer.Observe('order', Raiser.Raise());
        Observer.Observe('order again', Raiser.Raise());
        Observer.Expect('order', 'F1;F2;A1;A2;B1;B2;C1;C2;M1;M2;D1;D2;');
        Observer.Expect('order again', 'F1;F2;A1;A2;B1;B2;C1;C2;M1;M2;D1;D2;');
        Observer.Verify();
    end;

    // Writer UA: the same event raised once from this app's install routine (OnInstallAppPerCompany of "LT UA Install", 90243), in the
    // install session, with the order kept in "LT UA Install Order" for the current company.
    [Test]
    procedure SubscriberOrder_PlatformTableEvent_DuringInstallOfTheTestApp()
    var
        Row: Record "LT UA Install Order";
    begin
        Initialize();
        Observer.Observe('install row', Format(Row.Get(1)));
        Observer.Observe('order', Row."Order");
        Observer.Expect('install row', 'Yes');
        Observer.Expect('order', 'F1;F2;A1;A2;B1;B2;C1;C2;M1;M2;D1;D2;');
        Observer.Verify();
    end;

    local procedure Initialize()
    begin
        // The install logs hold rows written at install time; nothing to delete.
    end;
}
