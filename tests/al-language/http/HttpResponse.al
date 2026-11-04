// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpresponsemessage/httpresponsemessage-data-type
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// HttpResponseMessage default values on a fresh instance, Content and Headers.
// Fixtures used: Probe Observer (codeunit 69160)
// BC versions: 29 (27 and 28 by CI)

codeunit 72025 "LT HtT Response"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure FreshDefaults()
    var
        Resp: HttpResponseMessage;
    begin
        Observer.Observe('status', Format(Resp.HttpStatusCode()));
        Observer.Observe('success', Format(Resp.IsSuccessStatusCode()));
        Observer.Observe('reason', '[' + Resp.ReasonPhrase() + ']');
        Observer.Observe('blocked', Format(Resp.IsBlockedByEnvironment()));
        Observer.Expect('status', '200');
        Observer.Expect('success', 'Yes');
        Observer.Expect('reason', '[OK]');
        Observer.Expect('blocked', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure FreshContent()
    var
        Resp: HttpResponseMessage;
        Txt: Text;
        InS: InStream;
    begin
        Txt := 'preset';
        Observer.Observe('ok', Format(Resp.Content.ReadAs(Txt)));
        Observer.Observe('text', Txt);
        Observer.Observe('okStream', Format(Resp.Content.ReadAs(InS)));
        Observer.Observe('eos', Format(InS.EOS()));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('text', '');
        Observer.Expect('okStream', 'Yes');
        Observer.Expect('eos', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure FreshHeaders()
    var
        Resp: HttpResponseMessage;
        Headers: HttpHeaders;
        Vals: array[5] of Text;
    begin
        Headers := Resp.Headers;
        Observer.Observe('keys', Format(Headers.Keys().Count()));
        asserterror Observer.Observe('contains', Format(Headers.Contains('Content-Type')));
        Observer.ObserveError('af52');
        Observer.Observe('get', Format(Headers.GetValues('Server', Vals)));
        Observer.Expect('keys', '0');
        Observer.Expect('af52|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('af52|code', 'InvalidHeader:InvalidOperation');
        Observer.Expect('get', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure ResponseHeadersAddAndRemove()
    var
        Resp: HttpResponseMessage;
        Headers: HttpHeaders;
        Vals: array[5] of Text;
    begin
        Headers := Resp.Headers;
        Observer.Observe('add', Format(Headers.Add('X-Resp', 'v')));
        Headers.GetValues('X-Resp', Vals);
        Observer.Observe('v1', Vals[1]);
        asserterror Headers.Add('Bad Name', 'v');
        Observer.ObserveError('badName');
        Observer.Observe('remove', Format(Headers.Remove('X-Resp')));
        Observer.Expect('add', 'Yes');
        Observer.Expect('v1', 'v');
        Observer.Expect('badName|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('badName|code', 'InvalidHeader:Format');
        Observer.Expect('remove', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ResponseHeaderRestrictions()
    var
        Resp: HttpResponseMessage;
        Headers: HttpHeaders;
    begin
        Headers := Resp.Headers;
        Observer.Observe('server', Format(Headers.Add('Server', 'LT')));
        asserterror Headers.Add('Content-Type', 'text/plain');
        Observer.ObserveError('contentType');
        Headers.Add('Location', 'not a uri with spaces');
        Observer.Observe('location', 'no error');
        Observer.Expect('server', 'Yes');
        Observer.Expect('contentType|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('contentType|code', 'InvalidOperation');
        Observer.Expect('location', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure ContentOfFreshResponseIsShared()
    var
        Resp: HttpResponseMessage;
        Txt: Text;
    begin
        Resp.Content.WriteFrom('written');
        Resp.Content.ReadAs(Txt);
        Observer.Observe('text', Txt);
        Observer.Expect('text', 'written');
        Observer.Verify();
    end;

    [Test]
    procedure StatusCodeOnTwoInstances()
    var
        R1: HttpResponseMessage;
        R2: HttpResponseMessage;
    begin
        Observer.Observe('r1', Format(R1.HttpStatusCode()));
        Observer.Observe('r2', Format(R2.HttpStatusCode()));
        Observer.Observe('r1Success', Format(R1.IsSuccessStatusCode()));
        Observer.Expect('r1', '200');
        Observer.Expect('r2', '200');
        Observer.Expect('r1Success', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure AssignedFreshResponse()
    var
        R1: HttpResponseMessage;
        R2: HttpResponseMessage;
    begin
        R2 := R1;
        Observer.Observe('status', Format(R2.HttpStatusCode()));
        Observer.Observe('reason', '[' + R2.ReasonPhrase() + ']');
        Observer.Expect('status', '200');
        Observer.Expect('reason', '[OK]');
        Observer.Verify();
    end;
}
