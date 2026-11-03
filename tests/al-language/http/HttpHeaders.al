// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpheaders/httpheaders-data-type
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// HttpHeaders: Add, Remove, Contains, GetValues, Keys, TryAddWithoutValidation, ContainsSecret, Clear; names are case insensitive; invalid headers raise.
// Fixtures used: Probe Observer (codeunit 69160)
// BC versions: 29 (27 and 28 by CI)

codeunit 72021 "LT HtT Headers Basic"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure NewHeaders(var Headers: HttpHeaders)
    var
        Req: HttpRequestMessage;
    begin
        Req.GetHeaders(Headers);
    end;

    [Test]
    procedure FreshRequestHeaders()
    var
        Headers: HttpHeaders;
        Vals: array[5] of Text;
    begin
        NewHeaders(Headers);
        Observer.Observe('keys', Format(Headers.Keys().Count()));
        Observer.Observe('contains', Format(Headers.Contains('Accept')));
        Observer.Observe('getValues', Format(Headers.GetValues('Accept', Vals)));
        Observer.Observe('remove', Format(Headers.Remove('Accept')));
        Observer.Observe('secret', Format(Headers.ContainsSecret('Accept')));
        Observer.Expect('keys', '0');
        Observer.Expect('contains', 'No');
        Observer.Expect('getValues', 'No');
        Observer.Expect('remove', 'Yes');
        Observer.Expect('secret', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure AddAndGet()
    var
        Headers: HttpHeaders;
        Vals: array[5] of Text;
    begin
        NewHeaders(Headers);
        Observer.Observe('add', Format(Headers.Add('X-Test', 'one')));
        Observer.Observe('contains', Format(Headers.Contains('X-Test')));
        Observer.Observe('get', Format(Headers.GetValues('X-Test', Vals)));
        Observer.Observe('v1', Vals[1]);
        Observer.Observe('v2', Vals[2]);
        Observer.Observe('keys', Format(Headers.Keys().Count()));
        Observer.Expect('add', 'Yes');
        Observer.Expect('contains', 'Yes');
        Observer.Expect('get', 'Yes');
        Observer.Expect('v1', 'one');
        Observer.Expect('v2', '');
        Observer.Expect('keys', '1');
        Observer.Verify();
    end;

    [Test]
    procedure AddSameNameTwice()
    var
        Headers: HttpHeaders;
        Vals: array[5] of Text;
    begin
        NewHeaders(Headers);
        Headers.Add('X-Multi', 'a');
        Observer.Observe('addAgain', Format(Headers.Add('X-Multi', 'b')));
        Observer.Observe('get', Format(Headers.GetValues('X-Multi', Vals)));
        Observer.Observe('v1', Vals[1]);
        Observer.Observe('v2', Vals[2]);
        Observer.Observe('v3', Vals[3]);
        Observer.Observe('keys', Format(Headers.Keys().Count()));
        Observer.Expect('addAgain', 'Yes');
        Observer.Expect('get', 'Yes');
        Observer.Expect('v1', 'a');
        Observer.Expect('v2', 'b');
        Observer.Expect('v3', '');
        Observer.Expect('keys', '1');
        Observer.Verify();
    end;

    [Test]
    procedure AddSameValueTwice()
    var
        Headers: HttpHeaders;
        Vals: array[5] of Text;
    begin
        NewHeaders(Headers);
        Headers.Add('X-Same', 'a');
        Observer.Observe('addAgain', Format(Headers.Add('X-Same', 'a')));
        Headers.GetValues('X-Same', Vals);
        Observer.Observe('v1', Vals[1]);
        Observer.Observe('v2', Vals[2]);
        Observer.Expect('addAgain', 'Yes');
        Observer.Expect('v1', 'a');
        Observer.Expect('v2', 'a');
        Observer.Verify();
    end;

    [Test]
    procedure CaseInsensitiveNames()
    var
        Headers: HttpHeaders;
        Vals: array[5] of Text;
        Keys: List of [Text];
        K: Text;
    begin
        NewHeaders(Headers);
        Headers.Add('X-Case', 'v');
        Observer.Observe('lower', Format(Headers.Contains('x-case')));
        Observer.Observe('upper', Format(Headers.Contains('X-CASE')));
        Observer.Observe('getLower', Format(Headers.GetValues('x-case', Vals)));
        Observer.Observe('v1', Vals[1]);
        Headers.Add('x-CASE', 'w');
        Observer.Observe('keys', Format(Headers.Keys().Count()));
        Keys := Headers.Keys();
        foreach K in Keys do
            Observer.Observe('key', K);
        Observer.Observe('removeUpper', Format(Headers.Remove('X-CASE')));
        Observer.Observe('afterRemove', Format(Headers.Contains('X-Case')));
        Observer.Expect('lower', 'Yes');
        Observer.Expect('upper', 'Yes');
        Observer.Expect('getLower', 'Yes');
        Observer.Expect('v1', 'v');
        Observer.Expect('keys', '1');
        Observer.Expect('key', 'X-Case');
        Observer.Expect('removeUpper', 'Yes');
        Observer.Expect('afterRemove', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure RemoveBehaviour()
    var
        Headers: HttpHeaders;
    begin
        NewHeaders(Headers);
        Headers.Add('X-A', '1');
        Headers.Add('X-B', '2');
        Observer.Observe('removeA', Format(Headers.Remove('X-A')));
        Observer.Observe('removeAAgain', Format(Headers.Remove('X-A')));
        Observer.Observe('removeUnknown', Format(Headers.Remove('X-Unknown')));
        Observer.Observe('containsA', Format(Headers.Contains('X-A')));
        Observer.Observe('containsB', Format(Headers.Contains('X-B')));
        Observer.Observe('keys', Format(Headers.Keys().Count()));
        Observer.Expect('removeA', 'Yes');
        Observer.Expect('removeAAgain', 'Yes');
        Observer.Expect('removeUnknown', 'Yes');
        Observer.Expect('containsA', 'No');
        Observer.Expect('containsB', 'Yes');
        Observer.Expect('keys', '1');
        Observer.Verify();
    end;

    [Test]
    procedure RemoveAllValuesOfName()
    var
        Headers: HttpHeaders;
    begin
        NewHeaders(Headers);
        Headers.Add('X-M', 'a');
        Headers.Add('X-M', 'b');
        Observer.Observe('remove', Format(Headers.Remove('X-M')));
        Observer.Observe('contains', Format(Headers.Contains('X-M')));
        Observer.Expect('remove', 'Yes');
        Observer.Expect('contains', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure ClearHeaders()
    var
        Headers: HttpHeaders;
    begin
        NewHeaders(Headers);
        Headers.Add('X-A', '1');
        Headers.Add('X-B', '2');
        Headers.Clear();
        Observer.Observe('keys', Format(Headers.Keys().Count()));
        Observer.Observe('containsA', Format(Headers.Contains('X-A')));
        Headers.Clear();
        Observer.Observe('clearEmpty', 'ok');
        Observer.Expect('keys', '0');
        Observer.Expect('containsA', 'No');
        Observer.Expect('clearEmpty', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure KeysList()
    var
        Headers: HttpHeaders;
        Keys: List of [Text];
        K: Text;
        Joined: Text;
    begin
        NewHeaders(Headers);
        Headers.Add('X-Keys-A', '1');
        Headers.Add('X-Keys-B', '2');
        Headers.Add('X-Keys-A', '3');
        Keys := Headers.Keys();
        Observer.Observe('count', Format(Keys.Count()));
        Observer.Observe('hasA', Format(Keys.Contains('X-Keys-A')));
        Observer.Observe('hasLowerA', Format(Keys.Contains('x-keys-a')));
        foreach K in Keys do
            Joined += K + ';';
        Observer.Observe('keys', Joined);
        Observer.Expect('count', '2');
        Observer.Expect('hasA', 'Yes');
        Observer.Expect('hasLowerA', 'No');
        Observer.Expect('keys', 'X-Keys-A;X-Keys-B;');
        Observer.Verify();
    end;

    [Test]
    procedure ValuesWithSpecials()
    var
        Headers: HttpHeaders;
        Vals: array[5] of Text;
    begin
        NewHeaders(Headers);
        Headers.Add('X-V1', 'a, b');
        Headers.GetValues('X-V1', Vals);
        Observer.Observe('comma', Vals[1]);
        Observer.Observe('comma2', Vals[2]);
        Headers.Add('X-V2', '  padded  ');
        Headers.GetValues('X-V2', Vals);
        Observer.Observe('padded', '[' + Vals[1] + ']');
        Headers.Add('X-V3', '');
        Observer.Observe('emptyContains', Format(Headers.Contains('X-V3')));
        Headers.GetValues('X-V3', Vals);
        Observer.Observe('emptyValue', '[' + Vals[1] + ']');
        Headers.Add('X-V4', 'a;q=0.5');
        Headers.GetValues('X-V4', Vals);
        Observer.Observe('semicolon', Vals[1]);
        Observer.Expect('comma', 'a, b');
        Observer.Expect('comma2', '');
        Observer.Expect('padded', '[  padded  ]');
        Observer.Expect('emptyContains', 'Yes');
        Observer.Expect('emptyValue', '[]');
        Observer.Expect('semicolon', 'a;q=0.5');
        Observer.Verify();
    end;

    [Test]
    procedure GetValuesOnMissingLeavesArray()
    var
        Headers: HttpHeaders;
        Vals: array[5] of Text;
    begin
        NewHeaders(Headers);
        Vals[1] := 'preset';
        Observer.Observe('get', Format(Headers.GetValues('X-Missing', Vals)));
        Observer.Observe('v1', Vals[1]);
        Observer.Expect('get', 'No');
        Observer.Expect('v1', 'preset');
        Observer.Verify();
    end;
}

codeunit 72022 "LT HtT Headers Errors"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure NewHeaders(var Headers: HttpHeaders)
    var
        Req: HttpRequestMessage;
    begin
        Req.GetHeaders(Headers);
    end;

#if BC28PLUS
    [Test]
    procedure InvalidNames()
    var
        Headers: HttpHeaders;
    begin
        NewHeaders(Headers);
        asserterror Headers.Add('', 'v');
        Observer.ObserveError('emptyName');
        asserterror Headers.Add(' ', 'v');
        Observer.ObserveError('blankName');
        asserterror Headers.Add('Bad Name', 'v');
        Observer.ObserveError('spaceInName');
        asserterror Headers.Add('Bad:Name', 'v');
        Observer.ObserveError('colonInName');
        asserterror Headers.Add('Bäd', 'v');
        Observer.ObserveError('umlautName');
        asserterror Headers.Add('Bad(Name)', 'v');
        Observer.ObserveError('parenName');
        Observer.Expect('emptyName|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('emptyName|code', 'InvalidHeader:Argument');
        Observer.Expect('blankName|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
#if BC29PLUS
        Observer.Expect('blankName|code', 'InvalidHeader:Format');
#else
        Observer.Expect('blankName|code', 'InvalidHeader:Argument');
#endif
        Observer.Expect('spaceInName|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('spaceInName|code', 'InvalidHeader:Format');
        Observer.Expect('colonInName|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('colonInName|code', 'InvalidHeader:Format');
        Observer.Expect('umlautName|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('umlautName|code', 'InvalidHeader:Format');
        Observer.Expect('parenName|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('parenName|code', 'InvalidHeader:Format');
        Observer.Verify();
    end;
#endif

    [Test]
    procedure InvalidValues()
    var
        Headers: HttpHeaders;
        Lf: Text[1];
    begin
        Lf[1] := 10;
        NewHeaders(Headers);
        asserterror Headers.Add('X-Bad', 'a' + Lf + 'b');
        Observer.ObserveError('newlineValue');
        Observer.Observe('containsAfter', Format(Headers.Contains('X-Bad')));
        Observer.Expect('newlineValue|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('newlineValue|code', 'InvalidHeader:Format');
        Observer.Expect('containsAfter', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure RestrictedSingleValueHeaders()
    var
        Headers: HttpHeaders;
        Vals: array[5] of Text;
    begin
        NewHeaders(Headers);
        Headers.Add('User-Agent', 'LT/1.0');
        Headers.Add('Host', 'a.example');
        Observer.Observe('host', 'no error');
        Headers.Add('Date', 'Tue, 15 Nov 1994 08:12:31 GMT');
        asserterror Headers.Add('Date', 'Tue, 15 Nov 1994 08:12:32 GMT');
        Observer.ObserveError('dateTwice');
        asserterror Headers.Add('Date', 'not a date');
        Observer.ObserveError('dateInvalid');
        Observer.Expect('host', 'no error');
        Observer.Expect('dateTwice|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('dateTwice|code', 'InvalidHeader:Format');
        Observer.Expect('dateInvalid|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('dateInvalid|code', 'InvalidHeader:Format');
        Observer.Verify();
    end;

    [Test]
    procedure KnownHeaderValidation()
    var
        Headers: HttpHeaders;
        Vals: array[5] of Text;
    begin
        NewHeaders(Headers);
        asserterror Headers.Add('Accept', 'bad');
        Observer.ObserveError('acceptBad');
        asserterror Headers.Add('Authorization', '');
        Observer.ObserveError('authEmpty');
        Observer.Observe('add', Format(Headers.Add('Accept', 'application/json')));
        Headers.GetValues('Accept', Vals);
        Observer.Observe('accept', Vals[1]);
        Observer.Observe('addAuth', Format(Headers.Add('Authorization', 'Bearer abc')));
        Headers.GetValues('Authorization', Vals);
        Observer.Observe('auth', Vals[1]);
        asserterror Headers.Add('Content-Type', 'text/plain');
        Observer.ObserveError('contentTypeOnRequestHeaders');
        asserterror Headers.Add('Content-Length', '5');
        Observer.ObserveError('contentLengthOnRequestHeaders');
        Observer.Expect('acceptBad|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('acceptBad|code', 'InvalidHeader:Format');
        Observer.Expect('authEmpty|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('authEmpty|code', 'InvalidHeader:Format');
        Observer.Expect('add', 'Yes');
        Observer.Expect('accept', 'application/json');
        Observer.Expect('addAuth', 'Yes');
        Observer.Expect('auth', 'Bearer abc');
        Observer.Expect('contentTypeOnRequestHeaders|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('contentTypeOnRequestHeaders|code', 'InvalidOperation');
        Observer.Expect('contentLengthOnRequestHeaders|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('contentLengthOnRequestHeaders|code', 'InvalidOperation');
        Observer.Verify();
    end;

    [Test]
    procedure TryAddWithoutValidationBasics()
    var
        Headers: HttpHeaders;
        Vals: array[5] of Text;
    begin
        NewHeaders(Headers);
        Observer.Observe('ok', Format(Headers.TryAddWithoutValidation('X-Raw', 'a b c')));
        Headers.GetValues('X-Raw', Vals);
        Observer.Observe('value', Vals[1]);
        Observer.Observe('badName', Format(Headers.TryAddWithoutValidation('Bad Name', 'v')));
        Observer.Observe('emptyName', Format(Headers.TryAddWithoutValidation('', 'v')));
        asserterror Observer.Observe('containsBad', Format(Headers.Contains('Bad Name')));
        Observer.ObserveError('af320');
        Observer.Observe('acceptBad', Format(Headers.TryAddWithoutValidation('Accept', 'bad')));
        Observer.Observe('containsAccept', Format(Headers.Contains('Accept')));
        Observer.Observe('twice', Format(Headers.TryAddWithoutValidation('X-Raw', 'd')));
        Headers.GetValues('X-Raw', Vals);
        Observer.Observe('v1', Vals[1]);
        Observer.Observe('v2', Vals[2]);
        Observer.Expect('ok', 'Yes');
        Observer.Expect('value', 'a b c');
        Observer.Expect('badName', 'No');
        Observer.Expect('emptyName', 'No');
        Observer.Expect('af320|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('af320|code', 'InvalidHeader:Format');
        Observer.Expect('acceptBad', 'Yes');
        Observer.Expect('containsAccept', 'Yes');
        Observer.Expect('twice', 'Yes');
        Observer.Expect('v1', 'a b c');
        Observer.Expect('v2', 'd');
        Observer.Verify();
    end;

    [Test]
    procedure TryAddWithoutValidationRestricted()
    var
        Headers: HttpHeaders;
        Lf: Text[1];
    begin
        Lf[1] := 10;
        NewHeaders(Headers);
        Observer.Observe('newline', Format(Headers.TryAddWithoutValidation('X-Nl', 'a' + Lf + 'b')));
        Observer.Observe('host', Format(Headers.TryAddWithoutValidation('Host', 'a.example')));
        Observer.Observe('contentType', Format(Headers.TryAddWithoutValidation('Content-Type', 'text/plain')));
        asserterror Observer.Observe('containsContentType', Format(Headers.Contains('Content-Type')));
        Observer.ObserveError('af342');
        Observer.Expect('newline', 'Yes');
        Observer.Expect('host', 'Yes');
        Observer.Expect('contentType', 'No');
        Observer.Expect('af342|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('af342|code', 'InvalidHeader:InvalidOperation');
        Observer.Verify();
    end;
#if not BC28PLUS
    // Writer PW: docs/probes-needed.md "Values and builtins": HttpHeaders.Add with a name of blanks on BC 27 (InvalidNames above, a BC28PLUS
    // test, pins BC 28 and 29). The same calls as InvalidNames.
    [Test]
    procedure PW_InvalidNames_Bc27()
    var
        Headers: HttpHeaders;
    begin
        NewHeaders(Headers);
        asserterror Headers.Add('', 'v');
        Observer.ObserveError('emptyName');
        asserterror Headers.Add(' ', 'v');
        Observer.ObserveError('blankName');
        asserterror Headers.Add('   ', 'v');
        Observer.ObserveError('threeBlanksName');
        asserterror Headers.Add('Bad Name', 'v');
        Observer.ObserveError('spaceInName');
        asserterror Headers.Add('Bad:Name', 'v');
        Observer.ObserveError('colonInName');
        Observer.Expect('emptyName|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('emptyName|code', 'InvalidHeader:Argument');
        Observer.Expect('blankName|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('blankName|code', 'InvalidHeader:Argument');
        Observer.Expect('threeBlanksName|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('threeBlanksName|code', 'InvalidHeader:Argument');
        Observer.Expect('spaceInName|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('spaceInName|code', 'InvalidHeader:Format');
        Observer.Expect('colonInName|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('colonInName|code', 'InvalidHeader:Format');
        Observer.Verify();
    end;
#endif
}

codeunit 72023 "LT HtT Headers Secret"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure ContainsSecretPlain()
    var
        Req: HttpRequestMessage;
        Headers: HttpHeaders;
    begin
        Req.GetHeaders(Headers);
        Headers.Add('X-Plain', 'v');
        Observer.Observe('plain', Format(Headers.ContainsSecret('X-Plain')));
        Observer.Observe('missing', Format(Headers.ContainsSecret('X-Missing')));
        Observer.Observe('containsPlain', Format(Headers.Contains('X-Plain')));
        Observer.Expect('plain', 'No');
        Observer.Expect('missing', 'No');
        Observer.Expect('containsPlain', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure EmptySecret()
    var
        Req: HttpRequestMessage;
        Headers: HttpHeaders;
        Secret: SecretText;
    begin
        Req.GetHeaders(Headers);
        Observer.Observe('add', Format(Headers.Add('X-Empty', Secret)));
        Observer.Observe('secret', Format(Headers.ContainsSecret('X-Empty')));
        Observer.Observe('contains', Format(Headers.Contains('X-Empty')));
        Observer.Expect('add', 'Yes');
        Observer.Expect('secret', 'Yes');
        Observer.Expect('contains', 'No');
        Observer.Verify();
    end;
}
