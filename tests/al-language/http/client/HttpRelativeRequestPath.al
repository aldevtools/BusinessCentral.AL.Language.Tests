// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpclient/httpclient-get-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: no request leaves the test (TestHttpRequestPolicy = BlockOutboundRequests, no handler; the Cloud app cannot declare [HttpClientHandler]). The error of the blocked request is read for the address it names: a relative path joined to the base address (rooted, plain, parent, query), the same through Post / Put / Patch / Delete / Send, and with no base address. The lead keeps only the observations whose text carries the resolved address; a text without it is dropped.
// BC versions: 29 (27 and 28 by CI)

codeunit 74842 "LT P168 Http Relative Path"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;

    local procedure NewClient(var Client: HttpClient)
    begin
        Clear(Client);
        Client.SetBaseAddress('https://example.invalid/api/v1/');
    end;

    [Test]
    procedure P168_Get_RelativePathsAgainstBaseAddress()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Response: HttpResponseMessage;
    begin
        NewClient(Client);
        asserterror Client.Get('orders', Response);
        Observer.ObserveError('plain');
        asserterror Client.Get('/orders', Response);
        Observer.ObserveError('rooted');
        asserterror Client.Get('../x', Response);
        Observer.ObserveError('parent');
        asserterror Client.Get('?q=1', Response);
        Observer.ObserveError('query');
        asserterror Client.Get('sub/orders?a=1', Response);
        Observer.ObserveError('sub-with-query');
        asserterror Client.Get('', Response);
        Observer.ObserveError('empty');
        asserterror Client.Get('https://other.invalid/abs', Response);
        Observer.ObserveError('absolute');
        Observer.Expect('plain|text', 'Unhandled outbound HTTP requests are not permitted when the TestHttpRequestPolicy property is set to ''BlockOutboundRequests''. Please ensure that an HTTP client handler is configured.');
        Observer.Expect('plain|code', 'TestCodeunitUnhandledHttpRequest');
        Observer.Expect('rooted|text', 'Unhandled outbound HTTP requests are not permitted when the TestHttpRequestPolicy property is set to ''BlockOutboundRequests''. Please ensure that an HTTP client handler is configured.');
        Observer.Expect('rooted|code', 'TestCodeunitUnhandledHttpRequest');
        Observer.Expect('parent|text', 'Unhandled outbound HTTP requests are not permitted when the TestHttpRequestPolicy property is set to ''BlockOutboundRequests''. Please ensure that an HTTP client handler is configured.');
        Observer.Expect('parent|code', 'TestCodeunitUnhandledHttpRequest');
        Observer.Expect('query|text', 'Unhandled outbound HTTP requests are not permitted when the TestHttpRequestPolicy property is set to ''BlockOutboundRequests''. Please ensure that an HTTP client handler is configured.');
        Observer.Expect('query|code', 'TestCodeunitUnhandledHttpRequest');
        Observer.Expect('sub-with-query|text', 'Unhandled outbound HTTP requests are not permitted when the TestHttpRequestPolicy property is set to ''BlockOutboundRequests''. Please ensure that an HTTP client handler is configured.');
        Observer.Expect('sub-with-query|code', 'TestCodeunitUnhandledHttpRequest');
        Observer.Expect('empty|text', 'Unhandled outbound HTTP requests are not permitted when the TestHttpRequestPolicy property is set to ''BlockOutboundRequests''. Please ensure that an HTTP client handler is configured.');
        Observer.Expect('empty|code', 'TestCodeunitUnhandledHttpRequest');
        Observer.Expect('absolute|text', 'Unhandled outbound HTTP requests are not permitted when the TestHttpRequestPolicy property is set to ''BlockOutboundRequests''. Please ensure that an HTTP client handler is configured.');
        Observer.Expect('absolute|code', 'TestCodeunitUnhandledHttpRequest');
        Observer.Verify();
    end;

    [Test]
    procedure P168_Get_BaseAddressWithoutTrailingSlash()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Response: HttpResponseMessage;
    begin
        Client.SetBaseAddress('https://example.invalid/api/v1');
        asserterror Client.Get('orders', Response);
        Observer.ObserveError('plain');
        asserterror Client.Get('/orders', Response);
        Observer.ObserveError('rooted');
        asserterror Client.Get('../x', Response);
        Observer.ObserveError('parent');
        Observer.Expect('plain|text', 'Unhandled outbound HTTP requests are not permitted when the TestHttpRequestPolicy property is set to ''BlockOutboundRequests''. Please ensure that an HTTP client handler is configured.');
        Observer.Expect('plain|code', 'TestCodeunitUnhandledHttpRequest');
        Observer.Expect('rooted|text', 'Unhandled outbound HTTP requests are not permitted when the TestHttpRequestPolicy property is set to ''BlockOutboundRequests''. Please ensure that an HTTP client handler is configured.');
        Observer.Expect('rooted|code', 'TestCodeunitUnhandledHttpRequest');
        Observer.Expect('parent|text', 'Unhandled outbound HTTP requests are not permitted when the TestHttpRequestPolicy property is set to ''BlockOutboundRequests''. Please ensure that an HTTP client handler is configured.');
        Observer.Expect('parent|code', 'TestCodeunitUnhandledHttpRequest');
        Observer.Verify();
    end;

    [Test]
    procedure P168_Get_NoBaseAddress()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Response: HttpResponseMessage;
    begin
        asserterror Client.Get('orders', Response);
        Observer.ObserveError('relative');
        asserterror Client.Get('/orders', Response);
        Observer.ObserveError('rooted');
        asserterror Client.Get('https://example.invalid/abs', Response);
        Observer.ObserveError('absolute');
        Observer.Expect('relative|text', 'Unhandled outbound HTTP requests are not permitted when the TestHttpRequestPolicy property is set to ''BlockOutboundRequests''. Please ensure that an HTTP client handler is configured.');
        Observer.Expect('relative|code', 'TestCodeunitUnhandledHttpRequest');
        Observer.Expect('rooted|text', 'Unhandled outbound HTTP requests are not permitted when the TestHttpRequestPolicy property is set to ''BlockOutboundRequests''. Please ensure that an HTTP client handler is configured.');
        Observer.Expect('rooted|code', 'TestCodeunitUnhandledHttpRequest');
        Observer.Expect('absolute|text', 'Unhandled outbound HTTP requests are not permitted when the TestHttpRequestPolicy property is set to ''BlockOutboundRequests''. Please ensure that an HTTP client handler is configured.');
        Observer.Expect('absolute|code', 'TestCodeunitUnhandledHttpRequest');
        Observer.Verify();
    end;

    [Test]
    procedure P168_OtherVerbs_RelativePath()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Response: HttpResponseMessage;
        Content: HttpContent;
    begin
        NewClient(Client);
        Content.WriteFrom('x');
        asserterror Client.Post('orders', Content, Response);
        Observer.ObserveError('post');
        asserterror Client.Put('/orders', Content, Response);
        Observer.ObserveError('put-rooted');
        asserterror Client.Patch('../orders', Content, Response);
        Observer.ObserveError('patch-parent');
        asserterror Client.Delete('orders/1', Response);
        Observer.ObserveError('delete');
        Observer.Expect('post|text', 'Unhandled outbound HTTP requests are not permitted when the TestHttpRequestPolicy property is set to ''BlockOutboundRequests''. Please ensure that an HTTP client handler is configured.');
        Observer.Expect('post|code', 'TestCodeunitUnhandledHttpRequest');
        Observer.Expect('put-rooted|text', 'Unhandled outbound HTTP requests are not permitted when the TestHttpRequestPolicy property is set to ''BlockOutboundRequests''. Please ensure that an HTTP client handler is configured.');
        Observer.Expect('put-rooted|code', 'TestCodeunitUnhandledHttpRequest');
        Observer.Expect('patch-parent|text', 'Unhandled outbound HTTP requests are not permitted when the TestHttpRequestPolicy property is set to ''BlockOutboundRequests''. Please ensure that an HTTP client handler is configured.');
        Observer.Expect('patch-parent|code', 'TestCodeunitUnhandledHttpRequest');
        Observer.Expect('delete|text', 'Unhandled outbound HTTP requests are not permitted when the TestHttpRequestPolicy property is set to ''BlockOutboundRequests''. Please ensure that an HTTP client handler is configured.');
        Observer.Expect('delete|code', 'TestCodeunitUnhandledHttpRequest');
        Observer.Verify();
    end;

    [Test]
    procedure P168_Send_RelativeRequestUri()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Response: HttpResponseMessage;
        Request: HttpRequestMessage;
    begin
        NewClient(Client);
        Request.Method := 'GET';
        asserterror Request.SetRequestUri('orders');
        Observer.ObserveError('af109');
        asserterror Client.Send(Request, Response);
        Observer.ObserveError('send-relative');
        asserterror Request.SetRequestUri('/orders');
        Observer.ObserveError('af113');
        asserterror Client.Send(Request, Response);
        Observer.ObserveError('send-rooted');
        Observer.Expect('af109|text', 'Failed to create the URL for the request. Please, make sure to set a valid URL.');
        Observer.Expect('af109|code', 'CreateUrl:UriFormat');
        Observer.Expect('send-relative|text', 'Unhandled outbound HTTP requests are not permitted when the TestHttpRequestPolicy property is set to ''BlockOutboundRequests''. Please ensure that an HTTP client handler is configured.');
        Observer.Expect('send-relative|code', 'TestCodeunitUnhandledHttpRequest');
        Observer.Expect('af113|text', 'Failed to create the URL for the request. Please, make sure to set a valid URL.');
        Observer.Expect('af113|code', 'CreateUrl:UriFormat');
        Observer.Expect('send-rooted|text', 'Unhandled outbound HTTP requests are not permitted when the TestHttpRequestPolicy property is set to ''BlockOutboundRequests''. Please ensure that an HTTP client handler is configured.');
        Observer.Expect('send-rooted|code', 'TestCodeunitUnhandledHttpRequest');
        Observer.Verify();
    end;
}
