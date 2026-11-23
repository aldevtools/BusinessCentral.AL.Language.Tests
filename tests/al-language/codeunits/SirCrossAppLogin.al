// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-singleinstance-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); AL Internals Test Fixture tests/al-language-internals-fixture/SirXeLoginState.al
//   (SingleInstance codeunit 61097); XApp E tests/al-language-xapp-e/SirXeLoginSubs.al (subscriber 98031 of
//   "System Initialization".OnAfterLogin).
// Probe (al-runner issue 8696, cross-app cell): an app that this test app does NOT depend on (XApp E) sets the globals of a
//   SingleInstance codeunit of a shared dependency in its OnAfterLogin subscriber (Cnt := 10, Txt += 'L', one List.Add, a call
//   counter). Test 1 reads the globals into locals, overwrites the globals, then observes the locals and the globals. Test 2
//   (same codeunit, next in declaration order) observes the globals again. This is the shape of a partner test suite that reads
//   a SingleInstance global another app's login subscriber changed.
// BC versions: 27 - 29
// BC result (27.5, 28.5, 29.0, identical): the login subscriber of XApp E ran once before the tests (login calls 1), and the
//   test app reads its values (cnt 10, txt 'L'). The locals keep the read values after the overwrite (cnt 10, txt 'L'); the
//   List local is the same list as the global (List of is a reference type: 2 entries after AddName). Test 2 sees the
//   overwrite of test 1 (cnt 20, txt 'second', 2 names); the login subscriber did not run again.

codeunit 73480 "SIR Cross App Login"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure T1_ReadLoginState_KeepThenOverwrite()
    var
        S: Codeunit "SIR XE Login State";
        Observer: Codeunit "Probe Observer";
        SeenCnt: Integer;
        SeenTxt: Text;
        SeenNames: List of [Text];
        SeenLogins: Integer;
    begin
        SeenCnt := S.GetCnt();
        SeenTxt := S.GetTxt();
        SeenNames := S.GetNames();
        SeenLogins := S.GetLoginCalls();
        S.SetCnt(20);
        S.SetTxt('second');
        S.AddName('y');
        Observer.Observe('seen cnt', Format(SeenCnt));
        Observer.Observe('seen txt', SeenTxt);
        Observer.Observe('seen names', Format(SeenNames.Count()));
        Observer.Observe('seen login calls', Format(SeenLogins));
        Observer.Observe('global cnt', Format(S.GetCnt()));
        Observer.Observe('global txt', S.GetTxt());
        Observer.Observe('global names', Format(S.NameCount()));
        Observer.Observe('global login calls', Format(S.GetLoginCalls()));
        Observer.Expect('seen cnt', '10');
        Observer.Expect('seen txt', 'L');
        Observer.Expect('seen names', '2');
        Observer.Expect('seen login calls', '1');
        Observer.Expect('global cnt', '20');
        Observer.Expect('global txt', 'second');
        Observer.Expect('global names', '2');
        Observer.Expect('global login calls', '1');
        Observer.Verify();
    end;

    [Test]
    procedure T2_NextTestSeesTheOverwrite()
    var
        S: Codeunit "SIR XE Login State";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('global cnt', Format(S.GetCnt()));
        Observer.Observe('global txt', S.GetTxt());
        Observer.Observe('global names', Format(S.NameCount()));
        Observer.Observe('global login calls', Format(S.GetLoginCalls()));
        Observer.Expect('global cnt', '20');
        Observer.Expect('global txt', 'second');
        Observer.Expect('global names', '2');
        Observer.Expect('global login calls', '1');
        Observer.Verify();
    end;
}
