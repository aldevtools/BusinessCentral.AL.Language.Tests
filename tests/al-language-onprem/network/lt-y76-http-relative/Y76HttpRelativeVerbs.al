// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-httpclient-mock-outbound-calls
// Scope: in-scope (OnPrem app: the [HttpClientHandler] attribute and TestHttpRequestMessage are Scope = OnPrem)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; own codeunit 98890
// Probe (writer Y76, al-runtime-rs assumption http-relative-request-path): the Request.Path and RequestType an [HttpClientHandler] sees for a path that
// is not an absolute uri, with a base address set by SetBaseAddress, for the verbs Post, Put, Patch, Delete and for Send of an HttpRequestMessage whose
// RequestUri is relative. Get is pinned by network/lt-ay-http-handler/AyHttpHandler.al (BaseAddress_RelativePaths_1/_2, PY_BaseAddress_Joins_1..3).
// Facts: every verb joins the path to the base address as Get does (a rooted path replaces the base path, any other joins the base path's directory,
// dot segments are removed, a trailing slash of the base keeps its last segment).
// BC versions: 27, 28, 29. On the Linux images of BC 27 and 28 a request is not given to the handler (bc-linux issue 192), so the values are asserted on 29.

codeunit 98890 "LT Y76 Http Relative Verbs"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = AllowOutboundFromHandler;

    var
        Seen: Text;

    [HttpClientHandler]
    procedure SeenHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Seen += Format(Request.RequestType) + ' [' + Request.Path + ']';
        Response.HttpStatusCode := 200;
        exit(false);
    end;

    [TryFunction]
    local procedure TryVerb(Verb: Text; var Client: HttpClient; Url: Text; var Ret: Boolean)
    var
        Content: HttpContent;
        Resp: HttpResponseMessage;
    begin
        Content.WriteFrom('x');
        case Verb of
            'Post':
                Ret := Client.Post(Url, Content, Resp);
            'Put':
                Ret := Client.Put(Url, Content, Resp);
            'Patch':
                Ret := Client.Patch(Url, Content, Resp);
            'Delete':
                Ret := Client.Delete(Url, Resp);
        end;
    end;

    [TryFunction]
    local procedure TrySend(Method: Text; var Client: HttpClient; Url: Text; var Ret: Boolean)
    var
        Req: HttpRequestMessage;
        Resp: HttpResponseMessage;
    begin
        Req.Method := Method;
        Req.SetRequestUri(Url);
        Ret := Client.Send(Req, Resp);
    end;

    local procedure Verb(var Observer: Codeunit "Probe Observer"; Base: Text; ObsKey: Text; VerbName: Text; Url: Text)
    var
        Client: HttpClient;
        Ret: Boolean;
    begin
        Seen := '';
        if Base <> '' then
            Client.SetBaseAddress(Base);
        ClearLastError();
        if TryVerb(VerbName, Client, Url, Ret) then
            Observer.Observe(ObsKey, Format(Ret) + ' ' + Seen)
        else
            Observer.Observe(ObsKey, 'E[' + CopyStr(GetLastErrorText(), 1, 70) + '|' + GetLastErrorCode() + '] ' + Seen);
    end;

    local procedure SendVia(var Observer: Codeunit "Probe Observer"; Base: Text; ObsKey: Text; Method: Text; Url: Text)
    var
        Client: HttpClient;
        Ret: Boolean;
    begin
        Seen := '';
        if Base <> '' then
            Client.SetBaseAddress(Base);
        ClearLastError();
        if TrySend(Method, Client, Url, Ret) then
            Observer.Observe(ObsKey, Format(Ret) + ' ' + Seen)
        else
            Observer.Observe(ObsKey, 'E[' + CopyStr(GetLastErrorText(), 1, 70) + '|' + GetLastErrorCode() + '] ' + Seen);
    end;

    [Test]
    [HandlerFunctions('SeenHandler')]
    procedure Y76_Post_Put_RelativePaths()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Verb(Observer, 'https://example.invalid/api/v1/', 'post_plain', 'Post', 'orders');
        Verb(Observer, 'https://example.invalid/api/v1/', 'post_rooted', 'Post', '/orders');
        Verb(Observer, 'https://example.invalid/api/v1/', 'put_sub', 'Put', 'a/b');
        Verb(Observer, 'https://example.invalid/api/v1/', 'put_dot', 'Put', './x');
        Verb(Observer, 'https://example.invalid/api/v1', 'post_noslash', 'Post', 'orders');
        Verb(Observer, 'https://example.invalid/api/v1', 'put_noslash_rooted', 'Put', '/orders');
        Verb(Observer, '', 'post_nobase', 'Post', 'orders');
#if BC29PLUS
        Observer.Expect('post_plain', 'Yes Post [https://example.invalid/api/v1/orders]');
        Observer.Expect('post_rooted', 'Yes Post [https://example.invalid/orders]');
        Observer.Expect('put_sub', 'Yes Put [https://example.invalid/api/v1/a/b]');
        Observer.Expect('put_dot', 'Yes Put [https://example.invalid/api/v1/x]');
        Observer.Expect('post_noslash', 'Yes Post [https://example.invalid/api/orders]');
        Observer.Expect('put_noslash_rooted', 'Yes Put [https://example.invalid/orders]');
        Observer.Expect('post_nobase', 'E[Invalid URI: The URI is empty.|AL:UriFormat] ');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too, with the same values (writer Y76, 2026-11-02); the Linux images of 27 and 28 do not call it (bc-linux issue 192).
        Observer.Discard();
#endif
    end;

    [Test]
    [HandlerFunctions('SeenHandler')]
    procedure Y76_Patch_Delete_RelativePaths()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Verb(Observer, 'https://example.invalid/api/v1/', 'patch_plain', 'Patch', 'orders');
        Verb(Observer, 'https://example.invalid/api/v1/', 'patch_up', 'Patch', '../x');
        Verb(Observer, 'https://example.invalid/api/v1/', 'delete_plain', 'Delete', 'orders/5');
        Verb(Observer, 'https://example.invalid/api/v1/', 'delete_middle', 'Delete', 'a/../b');
        Verb(Observer, 'https://example.invalid/api/v1/', 'delete_query', 'Delete', 'orders?x=1#f');
        Verb(Observer, 'https://example.invalid/api/v1/', 'delete_absolute', 'Delete', 'https://other.invalid/abs');
        Verb(Observer, '', 'delete_nobase', 'Delete', 'orders');
#if BC29PLUS
        Observer.Expect('patch_plain', 'Yes Patch [https://example.invalid/api/v1/orders]');
        Observer.Expect('patch_up', 'Yes Patch [https://example.invalid/api/x]');
        Observer.Expect('delete_plain', 'Yes Delete [https://example.invalid/api/v1/orders/5]');
        Observer.Expect('delete_middle', 'Yes Delete [https://example.invalid/api/v1/b]');
        Observer.Expect('delete_query', 'Yes Delete [https://example.invalid/api/v1/orders]');
        Observer.Expect('delete_absolute', 'Yes Delete [https://other.invalid/abs]');
        Observer.Expect('delete_nobase', 'E[Invalid URI: The URI is empty.|AL:UriFormat] ');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too, with the same values (writer Y76, 2026-11-02); the Linux images of 27 and 28 do not call it (bc-linux issue 192).
        Observer.Discard();
#endif
    end;

    // Linux suspect, not a test: the Linux CI containers (27, 28 and 29) end Send of a relative uri with the CreateUrl error BEFORE the HttpClientHandler runs,
    // so the handler is reported as not executed; the Windows 27.5 and 28.5 containers call it with the same values. Needs the Windows nightly to decide.
    procedure Suspect_Send_RelativeRequestUri()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SendVia(Observer, 'https://example.invalid/api/v1/', 'send_get_plain', 'GET', 'orders');
        SendVia(Observer, 'https://example.invalid/api/v1/', 'send_post_rooted', 'POST', '/orders');
        SendVia(Observer, 'https://example.invalid/api/v1/', 'send_put_up', 'PUT', '../x');
        SendVia(Observer, 'https://example.invalid/api/v1', 'send_get_noslash', 'GET', 'orders');
        SendVia(Observer, 'https://example.invalid/api/v1/', 'send_get_query', 'GET', '?q=1');
        SendVia(Observer, '', 'send_get_nobase', 'GET', 'orders');
#if BC29PLUS
        Observer.Expect('send_get_plain', 'E[Failed to create the URL for the request. Please, make sure to set a v|CreateUrl:UriFormat] ');
        Observer.Expect('send_post_rooted', 'E[Failed to create the URL for the request. Please, make sure to set a v|CreateUrl:UriFormat] ');
        Observer.Expect('send_put_up', 'E[Failed to create the URL for the request. Please, make sure to set a v|CreateUrl:UriFormat] ');
        Observer.Expect('send_get_noslash', 'E[Failed to create the URL for the request. Please, make sure to set a v|CreateUrl:UriFormat] ');
        Observer.Expect('send_get_query', 'E[Failed to create the URL for the request. Please, make sure to set a v|CreateUrl:UriFormat] ');
        Observer.Expect('send_get_nobase', 'E[Failed to create the URL for the request. Please, make sure to set a v|CreateUrl:UriFormat] ');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too, with the same values (writer Y76, 2026-11-02); the Linux images of 27 and 28 do not call it (bc-linux issue 192).
        Observer.Discard();
#endif
    end;
}
