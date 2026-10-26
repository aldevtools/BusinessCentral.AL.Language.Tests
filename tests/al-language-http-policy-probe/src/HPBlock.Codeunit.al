codeunit 97801 "HPBlock"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;

    [Test]
    procedure UnhandledGet()
    var
        Client: HttpClient;
        Response: HttpResponseMessage;
    begin
        asserterror Client.Get('http://localhost:1/x', Response);
        Error('PROBE[HPBlock] code=[%1] text=[%2]', GetLastErrorCode(), GetLastErrorText());
    end;
}
