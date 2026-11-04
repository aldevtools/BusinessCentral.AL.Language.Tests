// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpclient/httpclient-data-type
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// HttpClient configuration members without sending any request. Send/Get/Post are never called.
// Fixtures used: Probe Observer (codeunit 69160)
// BC versions: 29 (27 and 28 by CI)

codeunit 72026 "LT HtT Client"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure FreshDefaults()
    var
        Client: HttpClient;
    begin
        Observer.Observe('timeout', Format(Client.Timeout()));
                Observer.Observe('baseAddress', '[' + Client.GetBaseAddress() + ']');
        Observer.Observe('defaultHeaders', Format(Client.DefaultRequestHeaders().Keys().Count()));
        Observer.Expect('timeout', '1 minute 40 seconds');
        Observer.Expect('baseAddress', '[]');
        Observer.Expect('defaultHeaders', '0');
        Observer.Verify();
    end;

    [Test]
    procedure TimeoutValues()
    var
        Client: HttpClient;
    begin
        Client.Timeout := 5000;
        Observer.Observe('5000', Format(Client.Timeout()));
        Client.Timeout(1);
        Observer.Observe('1', Format(Client.Timeout()));
        asserterror Client.Timeout := 2147483647;
        Observer.ObserveError('af36');
        Observer.Observe('max', Format(Client.Timeout()));
        Client.Timeout := -1;
        Observer.Observe('minusOne', 'no error');
        Observer.Observe('afterErrors', Format(Client.Timeout()));
        Observer.Expect('5000', '5 seconds');
        Observer.Expect('1', '1 millisecond');
        Observer.Expect('af36|text', 'The timeout value of ''31'' is larger than the maximum supported value of ''5'' minutes.');
        Observer.Expect('af36|code', 'HttpClientTimeoutTooLarge');
        Observer.Expect('max', '1 millisecond');
        Observer.Expect('minusOne', 'no error');
        Observer.Expect('afterErrors', '-1 millisecond');
        Observer.Verify();
    end;

    [Test]
    procedure BooleanSettings()
    var
        Client: HttpClient;
    begin
        Client.UseResponseCookies(false);
        Client.UseResponseCookies(true);
        Observer.Verify();
    end;

    [Test]
    procedure BaseAddress()
    var
        Client: HttpClient;
    begin
        Client.SetBaseAddress('https://example.invalid/api/');
        Observer.Observe('base', Client.GetBaseAddress());
        Client.SetBaseAddress('https://example.invalid');
        Observer.Observe('noSlash', Client.GetBaseAddress());
        Client.SetBaseAddress('HTTP://EXAMPLE.invalid:8080/A');
        Observer.Observe('upper', Client.GetBaseAddress());
        asserterror Client.SetBaseAddress('');
        Observer.ObserveError('af70');
        Observer.Observe('emptyAfter', '[' + Client.GetBaseAddress() + ']');
        Observer.Expect('base', 'https://example.invalid/api/');
        Observer.Expect('noSlash', 'https://example.invalid/');
        Observer.Expect('upper', 'http://example.invalid:8080/A');
        Observer.Expect('af70|text', 'Failed to create the URL for the request. Please, make sure to set a valid URL.');
        Observer.Expect('af70|code', 'CreateUrl:UriFormat');
        Observer.Expect('emptyAfter', '[http://example.invalid:8080/A]');
        Observer.Verify();
    end;

    local procedure Finish()
    begin
        Observer.Finish();
    end;

    [Test]
    procedure DefaultRequestHeaders()
    var
        Client: HttpClient;
        Headers: HttpHeaders;
        Vals: array[5] of Text;
    begin
        Headers := Client.DefaultRequestHeaders();
        Observer.Observe('add', Format(Headers.Add('X-Default', 'v')));
        Observer.Observe('viaClient', Format(Client.DefaultRequestHeaders().Contains('X-Default')));
        Headers.GetValues('X-Default', Vals);
        Observer.Observe('v1', Vals[1]);
        asserterror Headers.Add('Bad Name', 'v');
        Observer.ObserveError('badName');
        asserterror Headers.Add('Content-Type', 'text/plain');
        Observer.ObserveError('contentType');
        Observer.Observe('keys', Format(Headers.Keys().Count()));
        Observer.Expect('add', 'Yes');
        Observer.Expect('viaClient', 'Yes');
        Observer.Expect('v1', 'v');
        Observer.Expect('badName|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('badName|code', 'InvalidHeader:Format');
        Observer.Expect('contentType|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('contentType|code', 'InvalidOperation');
        Observer.Expect('keys', '1');
        Observer.Verify();
    end;

    [Test]
    procedure DefaultHeadersClear()
    var
        Client: HttpClient;
        Headers: HttpHeaders;
    begin
        Headers := Client.DefaultRequestHeaders();
        Headers.Add('X-Default', 'v');
        Headers.Add('User-Agent', 'LT/1.0');
        Observer.Observe('keysBefore', Format(Headers.Keys().Count()));
        Headers.Clear();
        Observer.Observe('keysAfter', Format(Client.DefaultRequestHeaders().Keys().Count()));
        Observer.Expect('keysBefore', '2');
        Observer.Expect('keysAfter', '0');
        Observer.Verify();
    end;

    [Test]
    procedure ClientClear()
    var
        Client: HttpClient;
    begin
        Client.Timeout := 1234;
        Client.UseResponseCookies(false);
        Client.SetBaseAddress('https://example.invalid/');
        Client.DefaultRequestHeaders().Add('X-Default', 'v');
        Client.Clear();
        Observer.Observe('timeout', Format(Client.Timeout()));
        Observer.Observe('base', '[' + Client.GetBaseAddress() + ']');
        Observer.Observe('header', Format(Client.DefaultRequestHeaders().Contains('X-Default')));
        Observer.Expect('timeout', '1 minute 40 seconds');
        Observer.Expect('base', '[]');
        Observer.Expect('header', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure ClearOnFresh()
    var
        Client: HttpClient;
    begin
        Client.Clear();
        Observer.Observe('timeout', Format(Client.Timeout()));
        Observer.Expect('timeout', '1 minute 40 seconds');
        Observer.Verify();
    end;

    [Test]
    procedure ClientCopyIsIndependent()
    var
        C1: HttpClient;
        C2: HttpClient;
    begin
        C1.Timeout := 4321;
        C2 := C1;
        Observer.Observe('copied', Format(C2.Timeout()));
        C2.Timeout := 99;
        Observer.Observe('original', Format(C1.Timeout()));
        Observer.Expect('copied', '4 seconds 321 milliseconds');
        Observer.Expect('original', '99 milliseconds');
        Observer.Verify();
    end;

    // Corpus issue #671 (odd AL behavior leads, part F) items 26 and 30: the other HttpHeaders members with Content-Type on the
    // client's default request headers, and a manual Cookie header there. Add with its Boolean used answers false; the same Add as a
    // statement raises 'The requested operation cannot be performed in this context.' (DefaultRequestHeaders above).
    [TryFunction]
    local procedure TryHeaderOp(var Headers: HttpHeaders; Op: Integer; Name: Text; Value: Text; var Result: Boolean)
    var
        Vals: array[5] of Text;
    begin
        case Op of
            1:
                Result := Headers.Contains(Name);
            2:
                Result := Headers.Remove(Name);
            3:
                Result := Headers.TryAddWithoutValidation(Name, Value);
            4:
                Result := Headers.GetValues(Name, Vals);
            5:
                Result := Headers.Add(Name, Value);
        end;
    end;

    local procedure HeaderOp(var Headers: HttpHeaders; Op: Integer; Name: Text; Value: Text): Text
    var
        Result: Boolean;
    begin
        ClearLastError();
        if TryHeaderOp(Headers, Op, Name, Value, Result) then
            exit(Format(Result));
        exit('E[' + GetLastErrorText() + '|' + GetLastErrorCode() + ']');
    end;

    [Test]
    procedure DefaultRequestHeaders_ContentTypeMembers_AndCookie()
    var
        Client: HttpClient;
        Headers: HttpHeaders;
        Vals: array[5] of Text;
    begin
        Headers := Client.DefaultRequestHeaders();
        Observer.Observe('contains', HeaderOp(Headers, 1, 'Content-Type', ''));
        Observer.Observe('remove', HeaderOp(Headers, 2, 'Content-Type', ''));
        Observer.Observe('raw', HeaderOp(Headers, 3, 'Content-Type', 'text/xml'));
        Observer.Observe('getValues', HeaderOp(Headers, 4, 'Content-Type', ''));
        Observer.Observe('addLower', HeaderOp(Headers, 5, 'content-type', 'application/json'));
        Observer.Observe('addUsed', HeaderOp(Headers, 5, 'Content-Type', 'text/plain'));
        Observer.Observe('containsLength', HeaderOp(Headers, 1, 'Content-Length', ''));
        Observer.Observe('keys', Format(Headers.Keys().Count()));
        Observer.Observe('cookieAdd', HeaderOp(Headers, 5, 'Cookie', 'a=b'));
        Headers.GetValues('Cookie', Vals);
        Observer.Observe('cookieValue', Vals[1]);
        Observer.Observe('cookieKeys', Format(Client.DefaultRequestHeaders().Keys().Count()));
        Observer.Expect('contains', 'E[Invalid HTTP header. Please, make sure the format of the header is correct.|InvalidHeader:InvalidOperation]');
        Observer.Expect('remove', 'No');
        Observer.Expect('raw', 'No');
        Observer.Expect('getValues', 'No');
        Observer.Expect('addLower', 'No');
        Observer.Expect('addUsed', 'No');
        Observer.Expect('containsLength', 'E[Invalid HTTP header. Please, make sure the format of the header is correct.|InvalidHeader:InvalidOperation]');
        Observer.Expect('keys', '0');
        Observer.Expect('cookieAdd', 'Yes');
        Observer.Expect('cookieValue', 'a=b');
        Observer.Expect('cookieKeys', '1');
        Observer.Verify();
    end;
}
