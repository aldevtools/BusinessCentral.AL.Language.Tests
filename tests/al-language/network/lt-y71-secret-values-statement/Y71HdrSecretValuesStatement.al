// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpheaders/httpheaders-getsecretvalues-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); test codeunit 93835 (writer Y71, gap cycle 7 spec G7-11d)
// Probe: HttpHeaders.GetSecretValues called as a STATEMENT (the result is not used), into a List of [SecretText] and into an array, on request
//        headers and on content headers, for a secret name, a plain (non-secret) name, a missing name, an empty name and an array that is too small.
//        The used-result form is pinned in xml/lt-xml-attr-doc-http-members/P97HdrSecretValues.al.
//        Per call: ok and the list count with the IsEmpty answer of each element, or the error text and code.
//        SecretText values are never printed; Unwrap has Scope OnPrem, so only IsEmpty is observed.

codeunit 93835 "LT Y71 Hdr SecretValues Stmt"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";

    local procedure Secret(Value: Text): SecretText
    var
        S: SecretText;
    begin
        S := SecretText.SecretStrSubstNo(Value);
        exit(S);
    end;

    local procedure Describe(Vals: List of [SecretText]) Result: Text
    var
        V: SecretText;
    begin
        Result := 'count=' + Format(Vals.Count());
        foreach V in Vals do
            Result += ' empty=' + Format(V.IsEmpty());
    end;

    [TryFunction]
    local procedure TryListStatement(var Headers: HttpHeaders; HdrKey: Text; var Vals: List of [SecretText])
    begin
        Headers.GetSecretValues(HdrKey, Vals);
    end;

    [TryFunction]
    local procedure TryArrayStatement(var Headers: HttpHeaders; HdrKey: Text; var Result: Text)
    var
        Vals: array[2] of SecretText;
    begin
        Headers.GetSecretValues(HdrKey, Vals);
        Result := Format(Vals[1].IsEmpty()) + '|' + Format(Vals[2].IsEmpty());
    end;

    local procedure ListCase(Name: Text; var Headers: HttpHeaders; HdrKey: Text)
    var
        Vals: List of [SecretText];
    begin
        if TryListStatement(Headers, HdrKey, Vals) then
            Obs.Observe(Name, 'ok ' + Describe(Vals))
        else begin
            Obs.Observe(Name, 'error');
            Obs.ObserveError(Name);
        end;
    end;

    local procedure ArrayCase(Name: Text; var Headers: HttpHeaders; HdrKey: Text)
    var
        Result: Text;
    begin
        if TryArrayStatement(Headers, HdrKey, Result) then
            Obs.Observe(Name, 'ok ' + Result)
        else begin
            Obs.Observe(Name, 'error');
            Obs.ObserveError(Name);
        end;
    end;

    [Test]
    procedure GetSecretValues_Statement_Found()
    var
        Req: HttpRequestMessage;
        Headers: HttpHeaders;
    begin
        Req.GetHeaders(Headers);
        Headers.Add('X-Secret-Header', Secret('s1'));
        Headers.Add('X-Two', Secret('a'));
        Headers.Add('X-Two', Secret('b'));
        ListCase('single', Headers, 'X-Secret-Header');
        ListCase('two_values', Headers, 'X-Two');
        ListCase('lower_case_name', Headers, 'x-secret-header');
        Obs.Observe('contains_secret', Format(Headers.ContainsSecret('X-Secret-Header')));
        Obs.Finish();
    end;

    [Test]
    procedure GetSecretValues_Statement_ContentHeaders()
    var
        Req: HttpRequestMessage;
        Content: HttpContent;
        Headers: HttpHeaders;
        ContentHeaders: HttpHeaders;
    begin
        Req.GetHeaders(Headers);
        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Add('X-Secret-Header', Secret('s1'));
        Req.Content(Content);
        Req.Content().GetHeaders(ContentHeaders);
        ListCase('content_single', ContentHeaders, 'X-Secret-Header');
        Obs.Observe('content_contains_secret', Format(ContentHeaders.ContainsSecret('X-Secret-Header')));
        Obs.Finish();
    end;

    [Test]
    procedure GetSecretValues_Statement_NotFound()
    var
        Req: HttpRequestMessage;
        Headers: HttpHeaders;
        Vals: List of [SecretText];
    begin
        Req.GetHeaders(Headers);
        Headers.Add('X-Plain', 'p1');
        Headers.Add('X-Secret-Header', Secret('s1'));
        ListCase('missing', Headers, 'X-Missing');
        ListCase('plain', Headers, 'X-Plain');
        ListCase('empty_name', Headers, '');
        Vals.Add(Secret('keep'));
        if TryListStatement(Headers, 'X-Missing', Vals) then
            Obs.Observe('prefilled_missing', 'ok ' + Describe(Vals))
        else
            Obs.Observe('prefilled_missing', 'error');
        Obs.Finish();
    end;

    [Test]
    procedure GetSecretValues_Statement_ArrayTooSmall()
    var
        Req: HttpRequestMessage;
        Headers: HttpHeaders;
    begin
        Req.GetHeaders(Headers);
        Headers.Add('X-One', Secret('a'));
        Headers.Add('X-Three', Secret('a'));
        Headers.Add('X-Three', Secret('b'));
        Headers.Add('X-Three', Secret('c'));
        Headers.Add('X-Plain', 'p1');
        ArrayCase('one_value', Headers, 'X-One');
        ArrayCase('three_into_two', Headers, 'X-Three');
        ArrayCase('plain', Headers, 'X-Plain');
        ArrayCase('missing', Headers, 'X-Missing');
        Obs.Finish();
    end;
}
