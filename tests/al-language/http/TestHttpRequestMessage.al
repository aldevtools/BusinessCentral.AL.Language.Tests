// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/
//   dev-itpro/developer/methods-auto/httprequestmessage/httprequestmessage-data-type
// Scope: in-scope (no outbound network call — construction and local configuration only)
// Fixtures used: none
// BC versions: 27.5+
//
// CLAIM: constructing an HttpRequestMessage and configuring it (Method, adding headers,
// setting content) locally must not throw, whether or not the message is ever sent. This is
// distinct from TestHttpClient.al's outbound-call test — no network access happens here.

codeunit 60876 "Test HttpRequestMessage"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure HttpRequestMessage_Construction_SetMethod_DoesNotThrow()
    var
        Req: HttpRequestMessage;
    begin
        Req.Method := 'GET';

        Assert.AreEqual('GET', Req.Method, 'HttpRequestMessage.Method must round-trip after construction');
    end;

    [Test]
    procedure HttpRequestMessage_SetContentAndHeaders_DoesNotThrow()
    var
        Req: HttpRequestMessage;
        Content: HttpContent;
        Headers: HttpHeaders;
        Body: Text;
    begin
        Req.Method := 'POST';
        Content.WriteFrom('{"probe":true}');
        Req.Content := Content;
        Req.Content.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/json');

        Req.Content.ReadAs(Body);
        Assert.AreEqual('{"probe":true}', Body, 'HttpRequestMessage.Content must round-trip the written body');
    end;

    [Test]
    procedure HttpRequestMessage_SetRequestUri_DoesNotThrow()
    var
        Req: HttpRequestMessage;
    begin
        Req.SetRequestUri('https://example.invalid/probe');

        Assert.AreEqual('https://example.invalid/probe', Req.GetRequestUri(), 'HttpRequestMessage.GetRequestUri must return the URI that was set');
    end;
}
