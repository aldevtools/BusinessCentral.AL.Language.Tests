// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpclient/httpclient-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 85601
// Leads: corpus issue #671 (HTTP client, requests and responses). These tests make real outbound requests (no TestHttpRequestPolicy) to
// example.com, badssl.com, httpbin.org and github.com. No outbound-connection approval prompt (StrMenu) appears, so no test binds a StrMenuHandler:
// a Windows container never shows it (bc-linux 05752c9, #165; the Windows nightly ran LtDaSendFailure.al on BC 28.5 and 29.0 without a handler).
// Earlier bc-linux images showed it and these tests bound an Allow Once handler; bc-linux bcc60c1c reports that handler as not executed.
// Probe: measured on a local BC 29.0 service tier, then on the corpus CI legs.
// Facts:
//  - Internal addresses (127.x, localhost, ::1, 10.x, 172.16.x, 192.168.x, 169.254.169.254) are refused before any connection: Get answers false,
//    status 0, IsBlockedByEnvironment false, last error code HttpRequest:Security. 0.0.0.0 gives HttpRequest:Argument.
//  - A failed certificate check (expired, wrong host, self-signed) makes Get answer false with code HttpRequest:HttpRequest (SecureConnectionError);
//    with UseServerCertificateValidation(false) the same hosts answer 200.
//  - GET and DELETE with a body, and GET with content headers but no body, are sent (no error).
//  - Sending one HttpRequestMessage a second time answers false with InvalidOperation, also after SetRequestUri.
//  - A response filled in a callee (var parameter) is readable in the caller, twice.
//  - No baggage header reaches an echo endpoint. A traceparent header does on BC 27.5 and 28.5, not on BC 29.0.
//  - 301, 302, 307 and 308 are followed: the caller sees the final 200. The Authorization default header is dropped on the redirected request.
//  - A SecretText default header (Authorization) is copied into the request's headers by Send as plain text: GetValues returns the value,
//    ContainsSecret is false. The client's default header stays secret.
codeunit 85601 "LT CZ Http Outbound"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Sec(Value: Text) Result: SecretText
    begin
        Result := Value;
    end;

    local procedure Short(Value: Text): Text
    begin
        exit(CopyStr(Value, 1, 300));
    end;

    [TryFunction]
    local procedure TryGet(var Client: HttpClient; Url: Text; var Resp: HttpResponseMessage; var Ok: Boolean)
    begin
        Ok := Client.Get(Url, Resp);
    end;

    [TryFunction]
    local procedure TrySend(var Client: HttpClient; var Req: HttpRequestMessage; var Resp: HttpResponseMessage; var Ok: Boolean)
    begin
        Ok := Client.Send(Req, Resp);
    end;

    local procedure GetOutcome(var Client: HttpClient; Url: Text): Text
    var
        Resp: HttpResponseMessage;
        Ok: Boolean;
        Raised: Boolean;
        Err: Text;
    begin
        ClearLastError();
        Raised := not TryGet(Client, Url, Resp, Ok);
        Err := GetLastErrorText();
        exit('raised=' + Format(Raised) + ' ok=' + Format(Ok) + ' status=' + Format(Resp.HttpStatusCode) + ' blocked=' + Format(Resp.IsBlockedByEnvironment) + ' err=[' + Short(Err) + '] code=[' + GetLastErrorCode() + ']');
    end;

    local procedure SendOutcome(var Client: HttpClient; var Req: HttpRequestMessage): Text
    var
        Resp: HttpResponseMessage;
        Ok: Boolean;
        Raised: Boolean;
        Err: Text;
    begin
        ClearLastError();
        Raised := not TrySend(Client, Req, Resp, Ok);
        Err := GetLastErrorText();
        exit('raised=' + Format(Raised) + ' ok=' + Format(Ok) + ' status=' + Format(Resp.HttpStatusCode) + ' blocked=' + Format(Resp.IsBlockedByEnvironment) + ' err=[' + Short(Err) + '] code=[' + GetLastErrorCode() + ']');
    end;

    local procedure Brief(var Client: HttpClient; Url: Text): Text
    var
        Resp: HttpResponseMessage;
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := Client.Get(Url, Resp);
        exit('ok=' + Format(Ok) + ' status=' + Format(Resp.HttpStatusCode) + ' blocked=' + Format(Resp.IsBlockedByEnvironment) + ' code=' + GetLastErrorCode());
    end;

    [Test]
    procedure InternalAddresses()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
    begin
        Client.Timeout := 5000;
        Observer.Observe('loopback', GetOutcome(Client, 'http://127.0.0.1:1/'));
        Observer.Observe('localhost', Brief(Client, 'http://localhost:1/'));
        Observer.Observe('loopback_other', Brief(Client, 'http://127.10.20.30/'));
        Observer.Observe('ipv6_loopback', Brief(Client, 'http://[::1]:1/'));
        Observer.Observe('ten', Brief(Client, 'http://10.255.255.1/'));
        Observer.Observe('lan', Brief(Client, 'http://192.168.255.1/'));
        Observer.Observe('lan172', Brief(Client, 'http://172.16.255.1/'));
        Observer.Observe('imds', Brief(Client, 'http://169.254.169.254/metadata/instance'));
        Observer.Observe('zero', Brief(Client, 'http://0.0.0.0:1/'));
        Observer.Observe('public', Brief(Client, 'https://example.com/'));
        Observer.Expect('loopback', 'raised=No ok=No status=0 blocked=No err=[There was an error while executing the HTTP request, the connecting endpoint violates security requirements. Make sure you are connecting to a valid endpoint.] code=[HttpRequest:Security]');
        Observer.Expect('localhost', 'ok=No status=0 blocked=No code=HttpRequest:Security');
        Observer.Expect('loopback_other', 'ok=No status=0 blocked=No code=HttpRequest:Security');
        Observer.Expect('ipv6_loopback', 'ok=No status=0 blocked=No code=HttpRequest:Security');
        Observer.Expect('ten', 'ok=No status=0 blocked=No code=HttpRequest:Security');
        Observer.Expect('lan', 'ok=No status=0 blocked=No code=HttpRequest:Security');
        Observer.Expect('lan172', 'ok=No status=0 blocked=No code=HttpRequest:Security');
        Observer.Expect('imds', 'ok=No status=0 blocked=No code=HttpRequest:Security');
        Observer.Expect('zero', 'ok=No status=0 blocked=No code=HttpRequest:Argument');
        Observer.Expect('public', 'ok=Yes status=200 blocked=No code=');
        Observer.Verify();
    end;

    // Held (publisher, bump 29): this test depends on third-party hosts (badssl.com, httpbin.org, github.com) that the corpus CI
    // cannot control; httpbin answered 502 for one redirect in the full run 39315232637 (BC 28.5). Not a test until the hosts are
    // replaced by something the CI owns. Define LT_HELD_EXTERNAL_HOSTS to run it.
#if LT_HELD_EXTERNAL_HOSTS
    [Test]
#endif
    procedure CertificateValidation()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Loose: HttpClient;
    begin
        Observer.Observe('expired', GetOutcome(Client, 'https://expired.badssl.com/'));
        Observer.Observe('wrong_host', GetOutcome(Client, 'https://wrong.host.badssl.com/'));
        Observer.Observe('self_signed', GetOutcome(Client, 'https://self-signed.badssl.com/'));
        Observer.Observe('good', GetOutcome(Client, 'https://badssl.com/'));
        Loose.UseServerCertificateValidation(false);
        Observer.Observe('off_expired', GetOutcome(Loose, 'https://expired.badssl.com/'));
        Observer.Observe('off_wrong_host', GetOutcome(Loose, 'https://wrong.host.badssl.com/'));
        Observer.Observe('off_self_signed', GetOutcome(Loose, 'https://self-signed.badssl.com/'));
        Observer.Expect('expired', 'raised=No ok=No status=0 blocked=No err=[There was an error while executing the HTTP request, error request: SecureConnectionError. Make sure you are connecting to a valid endpoint.] code=[HttpRequest:HttpRequest]');
        Observer.Expect('wrong_host', 'raised=No ok=No status=0 blocked=No err=[There was an error while executing the HTTP request, error request: SecureConnectionError. Make sure you are connecting to a valid endpoint.] code=[HttpRequest:HttpRequest]');
        Observer.Expect('self_signed', 'raised=No ok=No status=0 blocked=No err=[There was an error while executing the HTTP request, error request: SecureConnectionError. Make sure you are connecting to a valid endpoint.] code=[HttpRequest:HttpRequest]');
        Observer.Expect('good', 'raised=No ok=Yes status=200 blocked=No err=[] code=[]');
        Observer.Expect('off_expired', 'raised=No ok=Yes status=200 blocked=No err=[] code=[]');
        Observer.Expect('off_wrong_host', 'raised=No ok=Yes status=200 blocked=No err=[] code=[]');
        Observer.Expect('off_self_signed', 'raised=No ok=Yes status=200 blocked=No err=[] code=[]');
        Observer.Verify();
    end;

    [Test]
    procedure GetAndDeleteWithBody()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Req: HttpRequestMessage;
        Req2: HttpRequestMessage;
        Req3: HttpRequestMessage;
        Content: HttpContent;
        Content2: HttpContent;
        Content3: HttpContent;
        Headers: HttpHeaders;
    begin
        Content.WriteFrom('{}');
        Content.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/json');
        Req.Method := 'GET';
        Req.SetRequestUri('https://example.com/');
        Req.Content := Content;
        Observer.Observe('get_body', SendOutcome(Client, Req));
        Content2.WriteFrom('{}');
        Req2.Method := 'DELETE';
        Req2.SetRequestUri('https://example.com/');
        Req2.Content := Content2;
        Observer.Observe('delete_body', SendOutcome(Client, Req2));
        Content3.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/json');
        Req3.Method := 'GET';
        Req3.SetRequestUri('https://example.com/');
        Req3.Content := Content3;
        Observer.Observe('get_headers_no_body', SendOutcome(Client, Req3));
        Observer.Expect('get_body', 'raised=No ok=Yes status=200 blocked=No err=[] code=[]');
        Observer.Expect('delete_body', 'raised=No ok=Yes status=405 blocked=No err=[] code=[]');
        Observer.Expect('get_headers_no_body', 'raised=No ok=Yes status=200 blocked=No err=[] code=[]');
        Observer.Verify();
    end;

    [Test]
    procedure SameRequestMessageSentTwice()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Req: HttpRequestMessage;
    begin
        Req.Method := 'GET';
        Req.SetRequestUri('https://example.com/');
        Observer.Observe('first', SendOutcome(Client, Req));
        Observer.Observe('second_same_uri', SendOutcome(Client, Req));
        Req.SetRequestUri('https://example.com/other');
        Observer.Observe('third_new_uri', SendOutcome(Client, Req));
        Observer.Observe('uri_after', Req.GetRequestUri());
        Observer.Expect('first', 'raised=No ok=Yes status=200 blocked=No err=[] code=[]');
        Observer.Expect('second_same_uri', 'raised=No ok=No status=0 blocked=No err=[The requested operation cannot be performed in this context.] code=[InvalidOperation]');
        Observer.Expect('third_new_uri', 'raised=No ok=No status=0 blocked=No err=[The requested operation cannot be performed in this context.] code=[InvalidOperation]');
        Observer.Expect('uri_after', 'https://example.com/other');
        Observer.Verify();
    end;

    local procedure GetInto(var Response: HttpResponseMessage): Boolean
    var
        Client: HttpClient;
    begin
        exit(Client.Get('https://example.com/', Response));
    end;

    [Test]
    procedure ResponseFilledInCallee_ReadInCaller()
    var
        Observer: Codeunit "Probe Observer";
        Response: HttpResponseMessage;
        Body: Text;
    begin
        Observer.Observe('ok', Format(GetInto(Response)));
        Observer.Observe('status', Format(Response.HttpStatusCode));
        Response.Content.ReadAs(Body);
        Observer.Observe('has_body', Format(Body.Contains('Example Domain')));
        Body := '';
        Response.Content.ReadAs(Body);
        Observer.Observe('second_read_has_body', Format(Body.Contains('Example Domain')));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('status', '200');
        Observer.Expect('has_body', 'Yes');
        Observer.Expect('second_read_has_body', 'Yes');
        Observer.Verify();
    end;

    // Held (publisher, bump 29): this test depends on third-party hosts (badssl.com, httpbin.org, github.com) that the corpus CI
    // cannot control; httpbin answered 502 for one redirect in the full run 39315232637 (BC 28.5). Not a test until the hosts are
    // replaced by something the CI owns. Define LT_HELD_EXTERNAL_HOSTS to run it.
#if LT_HELD_EXTERNAL_HOSTS
    [Test]
#endif
    procedure EchoedRequestHeaders()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Headers: HttpHeaders;
        Resp: HttpResponseMessage;
        Body: Text;
    begin
        Headers := Client.DefaultRequestHeaders();
        Client.UseServerCertificateValidation(false);
        Headers.Add('X-Test', '1');
        Observer.Observe('ok', Format(Client.Get('https://httpbin.org/headers', Resp)));
        Observer.Observe('status', Format(Resp.HttpStatusCode));
        Resp.Content.ReadAs(Body);
        Observer.Observe('baggage', Format(Body.ToLower().Contains('"baggage"')));
        Observer.Observe('traceparent', Format(Body.ToLower().Contains('"traceparent"')));
        Observer.Observe('x_test', Format(Body.ToLower().Contains('"x-test": "1"')));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('status', '200');
        Observer.Expect('baggage', 'No');
#if BC29PLUS
        Observer.Expect('traceparent', 'No');
#else
        Observer.Expect('traceparent', 'Yes');
#endif
        Observer.Expect('x_test', 'No');
        Observer.Verify();
    end;

    local procedure EchoHasAuth(var Client: HttpClient; Url: Text): Text
    var
        Resp: HttpResponseMessage;
        Body: Text;
        Ok: Boolean;
    begin
        Ok := Client.Get(Url, Resp);
        Resp.Content.ReadAs(Body);
        exit('ok=' + Format(Ok) + ' status=' + Format(Resp.HttpStatusCode) + ' auth=' + Format(Body.Contains('"Authorization": "Bearer visible"')));
    end;

    // Held (publisher, bump 29): this test depends on third-party hosts (badssl.com, httpbin.org, github.com) that the corpus CI
    // cannot control; httpbin answered 502 for one redirect in the full run 39315232637 (BC 28.5). Not a test until the hosts are
    // replaced by something the CI owns. Define LT_HELD_EXTERNAL_HOSTS to run it.
#if LT_HELD_EXTERNAL_HOSTS
    [Test]
#endif
    procedure Redirects()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
    begin
        Observer.Observe('http_github', GetOutcome(Client, 'http://github.com/'));
        Observer.Observe('httpbin_302', GetOutcome(Client, 'https://httpbin.org/redirect-to?url=https%3A%2F%2Fexample.com%2F&status_code=302'));
        Observer.Observe('httpbin_307', GetOutcome(Client, 'https://httpbin.org/redirect-to?url=https%3A%2F%2Fexample.com%2F&status_code=307'));
        Observer.Observe('httpbin_308', GetOutcome(Client, 'https://httpbin.org/redirect-to?url=https%3A%2F%2Fexample.com%2F&status_code=308'));
        Client.DefaultRequestHeaders().Add('Authorization', 'Bearer visible');
        Observer.Observe('auth_direct', EchoHasAuth(Client, 'https://httpbin.org/headers'));
        Observer.Observe('auth_after_302_same_host', EchoHasAuth(Client, 'https://httpbin.org/redirect-to?url=https%3A%2F%2Fhttpbin.org%2Fheaders&status_code=302'));
        Observer.Observe('auth_after_307_same_host', EchoHasAuth(Client, 'https://httpbin.org/redirect-to?url=https%3A%2F%2Fhttpbin.org%2Fheaders&status_code=307'));
        Observer.Observe('httpbin_301', GetOutcome(Client, 'https://httpbin.org/redirect-to?url=https%3A%2F%2Fexample.com%2F&status_code=301'));
        Observer.Expect('http_github', 'raised=No ok=Yes status=200 blocked=No err=[] code=[]');
        Observer.Expect('httpbin_302', 'raised=No ok=Yes status=200 blocked=No err=[] code=[]');
        Observer.Expect('httpbin_307', 'raised=No ok=Yes status=200 blocked=No err=[] code=[]');
        Observer.Expect('httpbin_308', 'raised=No ok=Yes status=200 blocked=No err=[] code=[]');
        Observer.Expect('auth_direct', 'ok=Yes status=200 auth=Yes');
        Observer.Expect('auth_after_302_same_host', 'ok=Yes status=200 auth=No');
        Observer.Expect('auth_after_307_same_host', 'ok=Yes status=200 auth=No');
        Observer.Expect('httpbin_301', 'raised=No ok=Yes status=200 blocked=No err=[] code=[]');
        Observer.Verify();
    end;

    [Test]
    procedure SecretDefaultHeader_AfterSend()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Req: HttpRequestMessage;
        Resp: HttpResponseMessage;
        H: HttpHeaders;
        Values: List of [Text];
        Secrets: List of [SecretText];
    begin
        Client.DefaultRequestHeaders().Add('Authorization', Sec('Bearer abc'));
        Observer.Observe('client_before_secret', Format(Client.DefaultRequestHeaders().ContainsSecret('Authorization')));
        Req.Method := 'GET';
        Req.SetRequestUri('https://example.com/');
        Observer.Observe('send', Format(Client.Send(Req, Resp)));
        Req.GetHeaders(H);
        Observer.Observe('req_contains', Format(H.Contains('Authorization')));
        Observer.Observe('req_contains_secret', Format(H.ContainsSecret('Authorization')));
        if H.GetValues('Authorization', Values) then
            Observer.Observe('req_values', Format(Values.Count()) + ' [' + Values.Get(1) + ']')
        else
            Observer.Observe('req_values', 'none');
        Observer.Observe('req_secret_values', Format(H.GetSecretValues('Authorization', Secrets)) + ' ' + Format(Secrets.Count()));
        Observer.Observe('client_after_secret', Format(Client.DefaultRequestHeaders().ContainsSecret('Authorization')));
        Observer.Observe('client_after_plain', Format(Client.DefaultRequestHeaders().Contains('Authorization')));
        Observer.Expect('client_before_secret', 'Yes');
        Observer.Expect('send', 'Yes');
        Observer.Expect('req_contains', 'Yes');
        Observer.Expect('req_contains_secret', 'No');
        Observer.Expect('req_values', '1 [Bearer abc]');
        Observer.Expect('req_secret_values', 'No 0');
        Observer.Expect('client_after_secret', 'Yes');
        Observer.Expect('client_after_plain', 'No');
        Observer.Verify();
    end;
}
