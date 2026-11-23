// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-singleinstance-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); XApp A tests/al-language-xapp-a/SirNdXaTriggerState.al (SingleInstance
//   codeunit 98496, subscribers of GlobalTriggerManagement); XApp B tests/al-language-xapp-b/SirNdXbEventState.al
//   (SingleInstance codeunit 98501, subscriber of an event of the AL Internals Test Fixture); AL Internals Test Fixture
//   tests/al-language-internals-fixture/SirNdLoginEvents.al (event publisher 61098); XApp E
//   tests/al-language-xapp-e/SirNdLoginSubs.al (subscriber 98034 of "System Initialization".OnAfterLogin, tables 98032, 98033).
// Probe (al-runner issue 8696, login without a dependency): XApp E's OnAfterLogin subscriber changes the globals of
//   SingleInstance codeunits of two apps it does NOT depend on. It reads table 98032 and reads and writes table 98033, so the
//   platform asks the trigger setup and raises the insert or modify event that XApp A's SingleInstance codeunit subscribes
//   to (the shape of a partner login that reaches Microsoft's Backup Management, codeunit 130011). It raises an event of a
//   shared dependency that XApp B's SingleInstance codeunit subscribes to. The test app depends on XApp A and XApp B, not on
//   XApp E. Test 1 and test 2 read the globals into locals, overwrite the globals, then observe the locals and the globals.
//   Test 3 (next in declaration order) observes the globals again.
// BC versions: 27 - 29

codeunit 73481 "SIR Login No Dep"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure T1_TriggerState_KeepThenOverwrite()
    var
        S: Codeunit "SIR ND XA Trigger State";
        Observer: Codeunit "Probe Observer";
        SeenReadSetups: Integer;
        SeenWriteSetups: Integer;
        SeenWrites: Integer;
        SeenTxt: Text;
        SeenNames: List of [Text];
        SeenSawWrite: Boolean;
    begin
        SeenReadSetups := S.GetReadSetups();
        SeenWriteSetups := S.GetWriteSetups();
        SeenWrites := S.GetWrites();
        SeenTxt := S.GetTxt();
        SeenNames := S.GetNames();
        SeenSawWrite := S.GetSawWrite();
        S.SetWrites(20);
        S.SetTxt('second');
        S.AddName('y');
        S.SetSawWrite(not SeenSawWrite);
        Observer.Observe('seen read setups', Format(SeenReadSetups));
        Observer.Observe('seen write setups', Format(SeenWriteSetups));
        Observer.Observe('seen writes', Format(SeenWrites));
        Observer.Observe('seen txt', SeenTxt);
        Observer.Observe('seen names', Format(SeenNames.Count()));
        Observer.Observe('seen saw write', Format(SeenSawWrite));
        Observer.Observe('global read setups', Format(S.GetReadSetups()));
        Observer.Observe('global write setups', Format(S.GetWriteSetups()));
        Observer.Observe('global writes', Format(S.GetWrites()));
        Observer.Observe('global txt', S.GetTxt());
        Observer.Observe('global names', Format(S.NameCount()));
        Observer.Observe('global saw write', Format(S.GetSawWrite()));
        Observer.Finish();
    end;

    [Test]
    procedure T2_EventState_KeepThenOverwrite()
    var
        S: Codeunit "SIR ND XB Event State";
        Observer: Codeunit "Probe Observer";
        SeenCnt: Integer;
        SeenTxt: Text;
        SeenNames: List of [Text];
        SeenCalls: Integer;
    begin
        SeenCnt := S.GetCnt();
        SeenTxt := S.GetTxt();
        SeenNames := S.GetNames();
        SeenCalls := S.GetCalls();
        S.SetCnt(20);
        S.SetTxt('second');
        S.AddName('y');
        Observer.Observe('seen cnt', Format(SeenCnt));
        Observer.Observe('seen txt', SeenTxt);
        Observer.Observe('seen names', Format(SeenNames.Count()));
        Observer.Observe('seen calls', Format(SeenCalls));
        Observer.Observe('global cnt', Format(S.GetCnt()));
        Observer.Observe('global txt', S.GetTxt());
        Observer.Observe('global names', Format(S.NameCount()));
        Observer.Observe('global calls', Format(S.GetCalls()));
        Observer.Finish();
    end;

    [Test]
    procedure T3_NextTestSeesTheOverwrites()
    var
        A: Codeunit "SIR ND XA Trigger State";
        B: Codeunit "SIR ND XB Event State";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('a read setups', Format(A.GetReadSetups()));
        Observer.Observe('a write setups', Format(A.GetWriteSetups()));
        Observer.Observe('a writes', Format(A.GetWrites()));
        Observer.Observe('a txt', A.GetTxt());
        Observer.Observe('a names', Format(A.NameCount()));
        Observer.Observe('a saw write', Format(A.GetSawWrite()));
        Observer.Observe('b cnt', Format(B.GetCnt()));
        Observer.Observe('b txt', B.GetTxt());
        Observer.Observe('b names', Format(B.NameCount()));
        Observer.Observe('b calls', Format(B.GetCalls()));
        Observer.Finish();
    end;
}
