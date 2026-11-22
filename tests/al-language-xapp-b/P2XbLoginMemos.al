// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events
// Scope: in-scope
// Probe (al-runner issue 8239, probe P2; tests: tests/al-language/events/platform-triggers/P2LoginMemoTests.al): the "System Initialization".OnAfterLogin
//   subscriber of a second dependency app (XApp B, not the app under test, not Microsoft) fills or changes memos that live in another app (XApp A,
//   tests/al-language-xapp-a/P2XaLoginMemos.al): "LT P2 XA Bool Memo Other" (two Booleans, filled on first use), "LT P2 XA Mixed Memo" (Text,
//   Integer, List of [Text]) and "LT P2 XA Two Subs Memo" (also changed by the XApp A subscriber). The subscriber never fails.
// Install code is not used here (check-install-triggers.py).
// BC versions: 27 - 29

codeunit 98500 "LT P2 XB Login Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure OnAfterLogin()
    var
        BoolMemoOther: Codeunit "LT P2 XA Bool Memo Other";
        Mixed: Codeunit "LT P2 XA Mixed Memo";
        TwoSubs: Codeunit "LT P2 XA Two Subs Memo";
    begin
        if BoolMemoOther.IsOn() then;
        Mixed.SetFromLogin();
        TwoSubs.AddFrom('B');
    end;
}
