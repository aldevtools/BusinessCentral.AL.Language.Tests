// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/
//   dev-itpro/developer/methods-auto/httpclient/httpclient-data-type
// Scope: in-scope (Cloud-compatible)
// Fixtures used: none
// BC versions: 27.5+
//
// CLAIM: outbound HTTP is allowed from AL in BC Cloud. HttpClient.Get does not throw
// for a reachable endpoint -- it was previously assumed (wrongly) to be out-of-scope
// and tested as a throwing call; the real Cloud sandbox lets it through.
//
// No outbound-connection approval prompt (StrMenu Allow Always/Allow Once/Block Always/Block Once) appears: a
// Windows container never shows it (bc-linux 05752c9, #165), and the Windows nightly ran the HttpClient tests of
// LtDaSendFailure.al on BC 28.5 and 29.0 without a StrMenuHandler. The test therefore binds no handler: a prompt
// would surface as "Unhandled UI" and fail it. (Earlier bc-linux images showed the prompt; this test bound an
// Allow Once handler then, which bc-linux bcc60c1c reports as "UI handlers were not executed".)

codeunit 60874 "Test HttpClient"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure HttpClient_Get_ValidUrl_ReturnsSuccessResponse()
    var
        Client: HttpClient;
        Resp: HttpResponseMessage;
    begin
        Client.Get('http://example.com', Resp);

        Assert.IsTrue(Resp.IsSuccessStatusCode(), 'HttpClient.Get must succeed against a reachable URL in Cloud');
    end;
}
