// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-httpclient-mock-outbound-calls
// Scope: in-scope (OnPrem app: the [HttpClientHandler] attribute and TestHttpRequestMessage / TestHttpResponseMessage are Scope = OnPrem)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; own codeunit 98860
// Probe: observe probe; every literal asserted below is what the corpus CI service tiers produced.
// Facts: under TestHttpRequestPolicy = AllowOutboundFromHandler, a Get on an HttpClient after UseServerCertificateValidation(false), after the
//   property-assign form UseServerCertificateValidation := false, after UseResponseCookies(false) and after a Timeout change still reaches the
//   [HttpClientHandler]: the Boolean of Get, the status, the body the handler wrote, the number of handler calls and the URL the handler sees.
//   The Cloud-app twin is network/lt-httpclient-property-assign/Y6HttpSettingChanges.al (BlockOutboundRequests).
// BC versions: 27, 28, 29 (corpus CI); handler values asserted on 29 only: the Linux images of 27 and 28 do not give a request to the handler
//   (see AyHttpHandler.al, bc-linux issue 192).

codeunit 98860 "LT Y6 Http Handler Settings"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = AllowOutboundFromHandler;

    var
        Seen: Text;
        Calls: Integer;

    [HttpClientHandler]
    procedure EchoHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Calls += 1;
        Seen := Request.Path;
        Response.HttpStatusCode := 200;
        Response.Content.WriteFrom('ok');
        exit(false);
    end;

    local procedure Run(var Observer: Codeunit "Probe Observer"; var Client: HttpClient; ObsKey: Text)
    var
        Resp: HttpResponseMessage;
        Ret: Boolean;
        Body: Text;
    begin
        Seen := '';
        Calls := 0;
        Client.DefaultRequestHeaders().Add('X-Y6', '1');
        Ret := Client.Get('https://example.invalid/y6', Resp);
        Resp.Content.ReadAs(Body);
        Observer.Observe(ObsKey, 'ret=' + Format(Ret) + ' status=' + Format(Resp.HttpStatusCode) + ' body=' + Body + ' calls=' + Format(Calls) + ' path=' + Seen);
    end;

    [Test]
    [HandlerFunctions('EchoHandler')]
    procedure Get_AfterSettings_ReachesHandler()
    var
        Observer: Codeunit "Probe Observer";
        C1: HttpClient;
        C2: HttpClient;
        C3: HttpClient;
        C4: HttpClient;
    begin
        C1.UseServerCertificateValidation(false);
        Run(Observer, C1, 'validation false call');
        C2.UseServerCertificateValidation := false;
        Run(Observer, C2, 'validation false assign');
        C3.UseResponseCookies(false);
        Run(Observer, C3, 'cookies false');
        C4.Timeout := 1000;
        C4.UseServerCertificateValidation(false);
        C4.UseResponseCookies := true;
        Run(Observer, C4, 'timeout then both');
#if BC29PLUS
        Observer.Expect('validation false call', 'ret=Yes status=200 body=ok calls=1 path=https://example.invalid/y6');
        Observer.Expect('validation false assign', 'ret=Yes status=200 body=ok calls=1 path=https://example.invalid/y6');
        Observer.Expect('cookies false', 'ret=Yes status=200 body=ok calls=1 path=https://example.invalid/y6');
        Observer.Expect('timeout then both', 'ret=Yes status=200 body=ok calls=1 path=https://example.invalid/y6');
        Observer.Verify();
#else
        Observer.Discard();
#endif
    end;
}
