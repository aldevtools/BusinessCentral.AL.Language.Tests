codeunit 97802 "HPAllowFromHandler"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = AllowOutboundFromHandler;

    [Test]
    procedure UnhandledGet()
    var
        Client: HttpClient;
        Response: HttpResponseMessage;
    begin
        asserterror Client.Get('http://localhost:1/x', Response);
        Error('PROBE[HPAllowFromHandler] code=[%1] text=[%2]', GetLastErrorCode(), GetLastErrorText());
    end;
}
