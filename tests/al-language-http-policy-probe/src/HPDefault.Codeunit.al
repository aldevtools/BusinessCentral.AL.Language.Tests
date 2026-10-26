codeunit 97800 "HPDefault"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure UnhandledGet()
    var
        Client: HttpClient;
        Response: HttpResponseMessage;
    begin
        asserterror Client.Get('http://localhost:1/x', Response);
        Error('PROBE[HPDefault] code=[%1] text=[%2]', GetLastErrorCode(), GetLastErrorText());
    end;
}
