// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/session/session-setdocumentservicetoken-method
// Scope: in-scope (OnPrem app only: Session.SetDocumentServiceToken)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; codeunit 61254
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY: sets a token on the own session; every test ends with an empty token again
//
// SetDocumentServiceToken(Token) with an empty token and a plain text, then reset with an empty token: outcome and error text only.
// BC versions: 29 (27 and 28 by CI)
codeunit 61254 "LT P109 DocServiceToken"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySet(Token: Text)
    begin
        Session.SetDocumentServiceToken(Token);
    end;

    local procedure Outcome(Token: Text): Text
    begin
        if TrySet(Token) then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure P109_SetDocumentServiceToken()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('empty', Outcome(''));
        Observer.Observe('text', Outcome('ltp109-token'));
        Observer.Observe('long', Outcome(PadStr('', 800, 'x')));
        Observer.Observe('reset', Outcome(''));
        Observer.Expect('empty', 'ok');
        Observer.Expect('text', 'ok');
        Observer.Expect('long', 'ok');
        Observer.Expect('reset', 'ok');
        Observer.Verify();
    end;
}
