// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httprequestmessage/httprequestmessage-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: HttpRequestMessage SetCookie(Name, Value), GetCookie, GetCookieNames, RemoveCookie on a request built locally
// BC versions: 29 (27 and 28 by CI)

codeunit 74813 "LT P97 Req Cookie"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySet(var Req: HttpRequestMessage; Name: Text; Value: Text; var Result: Boolean)
    begin
        Result := Req.SetCookie(Name, Value);
    end;

    [TryFunction]
    local procedure TryGet(var Req: HttpRequestMessage; Name: Text; var Result: Text)
    var
        C: Cookie;
        Found: Boolean;
    begin
        Found := Req.GetCookie(Name, C);
        Result := Format(Found);
        if Found then
            Result += '|' + C.Name() + '|' + C.Value();
    end;

    [TryFunction]
    local procedure TryNames(var Req: HttpRequestMessage; var Result: Text)
    var
        L: List of [Text];
        N: Text;
    begin
        L := Req.GetCookieNames();
        Result := Format(L.Count()) + ':';
        foreach N in L do
            Result += N + ';';
    end;

    [TryFunction]
    local procedure TryRemove(var Req: HttpRequestMessage; Name: Text; var Result: Boolean)
    begin
        Result := Req.RemoveCookie(Name);
    end;

    local procedure SetObs(var Observer: Codeunit "Probe Observer"; Name: Text; var Req: HttpRequestMessage; CName: Text; CValue: Text)
    var
        R: Boolean;
        G: Text;
    begin
        if TrySet(Req, CName, CValue, R) then begin
            Observer.Observe(Name, Format(R));
            if TryGet(Req, CName, G) then
                Observer.Observe(Name + '_get', G)
            else
                Observer.ObserveError(Name + '_get');
        end else
            Observer.ObserveError(Name);
    end;

    local procedure Names(var Observer: Codeunit "Probe Observer"; Name: Text; var Req: HttpRequestMessage)
    var
        R: Text;
    begin
        if TryNames(Req, R) then
            Observer.Observe(Name, R)
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure SetCookie_NoUri()
    var
        Observer: Codeunit "Probe Observer";
        Req: HttpRequestMessage;
    begin
        Names(Observer, 'names_new', Req);
        SetObs(Observer, 'plain', Req, 'a', '1');
        SetObs(Observer, 'second', Req, 'b', '2');
        SetObs(Observer, 'overwrite', Req, 'a', '9');
        Names(Observer, 'names', Req);
        SetObs(Observer, 'upper_case_name', Req, 'A', 'upper');
        Names(Observer, 'names_after_case', Req);
        SetObs(Observer, 'empty_value', Req, 'e', '');
        Names(Observer, 'names_after_empty', Req);
        Observer.Expect('names_new', '0:');
        Observer.Expect('plain', 'Yes');
        Observer.Expect('plain_get', 'Yes|a|1');
        Observer.Expect('second', 'Yes');
        Observer.Expect('second_get', 'Yes|b|2');
        Observer.Expect('overwrite', 'Yes');
        Observer.Expect('overwrite_get', 'Yes|a|9');
        Observer.Expect('names', '2:a;b;');
        Observer.Expect('upper_case_name', 'Yes');
        Observer.Expect('upper_case_name_get', 'Yes|A|upper');
        Observer.Expect('names_after_case', '2:A;b;');
        Observer.Expect('empty_value', 'Yes');
        Observer.Expect('empty_value_get', 'Yes|e|');
        Observer.Expect('names_after_empty', '3:A;b;e;');
        Observer.Verify();
    end;

    [Test]
    procedure SetCookie_WithUri()
    var
        Observer: Codeunit "Probe Observer";
        Req: HttpRequestMessage;
    begin
        Req.SetRequestUri('https://example.invalid/path');
        Names(Observer, 'names_new', Req);
        SetObs(Observer, 'plain', Req, 'a', '1');
        SetObs(Observer, 'second', Req, 'b', '2');
        SetObs(Observer, 'overwrite', Req, 'a', '9');
        Names(Observer, 'names', Req);
        SetObs(Observer, 'upper_case_name', Req, 'A', 'upper');
        Names(Observer, 'names_after_case', Req);
        SetObs(Observer, 'empty_value', Req, 'e', '');
        Names(Observer, 'names_after_empty', Req);
        Observer.Expect('names_new', '0:');
        Observer.Expect('plain', 'Yes');
        Observer.Expect('plain_get', 'Yes|a|1');
        Observer.Expect('second', 'Yes');
        Observer.Expect('second_get', 'Yes|b|2');
        Observer.Expect('overwrite', 'Yes');
        Observer.Expect('overwrite_get', 'Yes|a|9');
        Observer.Expect('names', '2:a;b;');
        Observer.Expect('upper_case_name', 'Yes');
        Observer.Expect('upper_case_name_get', 'Yes|A|upper');
        Observer.Expect('names_after_case', '2:A;b;');
        Observer.Expect('empty_value', 'Yes');
        Observer.Expect('empty_value_get', 'Yes|e|');
        Observer.Expect('names_after_empty', '3:A;b;e;');
        Observer.Verify();
    end;

    [Test]
    procedure SetCookie_InvalidNamesAndValues()
    var
        Observer: Codeunit "Probe Observer";
        Req: HttpRequestMessage;
    begin
        Req.SetRequestUri('https://example.invalid/');
        SetObs(Observer, 'empty_name', Req, '', 'v');
        SetObs(Observer, 'space_name', Req, 'a b', 'v');
        SetObs(Observer, 'semicolon_name', Req, 'a;b', 'v');
        SetObs(Observer, 'equals_name', Req, 'a=b', 'v');
        SetObs(Observer, 'comma_name', Req, 'a,b', 'v');
        SetObs(Observer, 'dollar_name', Req, '$a', 'v');
        SetObs(Observer, 'semicolon_value', Req, 'sv', 'a;b');
        SetObs(Observer, 'equals_value', Req, 'ev', 'a=b');
        SetObs(Observer, 'space_value', Req, 'spv', 'a b');
        SetObs(Observer, 'quote_value', Req, 'qv', '"quoted"');
        SetObs(Observer, 'unicode_value', Req, 'uv', 'caf' + 'é');
        SetObs(Observer, 'unicode_name', Req, 'caf' + 'é', 'v');
        Names(Observer, 'names', Req);
        Observer.Expect('empty_name', 'No');
        Observer.Expect('empty_name_get', 'No');
        Observer.Expect('space_name', 'Yes');
        Observer.Expect('space_name_get', 'Yes|a b|v');
        Observer.Expect('semicolon_name', 'No');
        Observer.Expect('semicolon_name_get', 'No');
        Observer.Expect('equals_name', 'No');
        Observer.Expect('equals_name_get', 'No');
        Observer.Expect('comma_name', 'No');
        Observer.Expect('comma_name_get', 'No');
        Observer.Expect('dollar_name', 'No');
        Observer.Expect('dollar_name_get', 'No');
        Observer.Expect('semicolon_value', 'No');
        Observer.Expect('semicolon_value_get', 'No');
        Observer.Expect('equals_value', 'Yes');
        Observer.Expect('equals_value_get', 'Yes|ev|a=b');
        Observer.Expect('space_value', 'Yes');
        Observer.Expect('space_value_get', 'Yes|spv|a b');
        Observer.Expect('quote_value', 'Yes');
        Observer.Expect('quote_value_get', 'Yes|qv|"quoted"');
        Observer.Expect('unicode_value', 'Yes');
        Observer.Expect('unicode_value_get', 'Yes|uv|café');
        Observer.Expect('unicode_name', 'Yes');
        Observer.Expect('unicode_name_get', 'Yes|café|v');
        Observer.Expect('names', '6:a b;ev;spv;qv;uv;café;');
        Observer.Verify();
    end;

    [Test]
    procedure RemoveCookie_Results()
    var
        Observer: Codeunit "Probe Observer";
        Req: HttpRequestMessage;
        R: Boolean;
        G: Text;
    begin
        Req.SetRequestUri('https://example.invalid/');
        Req.SetCookie('a', '1');
        Req.SetCookie('b', '2');
        if TryRemove(Req, 'a', R) then
            Observer.Observe('remove_existing', Format(R))
        else
            Observer.ObserveError('remove_existing');
        if TryRemove(Req, 'a', R) then
            Observer.Observe('remove_again', Format(R))
        else
            Observer.ObserveError('remove_again');
        if TryRemove(Req, 'zzz', R) then
            Observer.Observe('remove_missing', Format(R))
        else
            Observer.ObserveError('remove_missing');
        if TryRemove(Req, 'B', R) then
            Observer.Observe('remove_other_case', Format(R))
        else
            Observer.ObserveError('remove_other_case');
        if TryRemove(Req, '', R) then
            Observer.Observe('remove_empty', Format(R))
        else
            Observer.ObserveError('remove_empty');
        Names(Observer, 'names', Req);
        if TryGet(Req, 'a', G) then
            Observer.Observe('get_removed', G)
        else
            Observer.ObserveError('get_removed');
        Observer.Expect('remove_existing', 'Yes');
        Observer.Expect('remove_again', 'No');
        Observer.Expect('remove_missing', 'No');
        Observer.Expect('remove_other_case', 'No');
        Observer.Expect('remove_empty', 'No');
        Observer.Expect('names', '1:b;');
        Observer.Expect('get_removed', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure GetCookie_Missing_And_Case()
    var
        Observer: Codeunit "Probe Observer";
        Req: HttpRequestMessage;
        G: Text;
    begin
        Req.SetRequestUri('https://example.invalid/');
        Req.SetCookie('Abc', 'v');
        if TryGet(Req, 'Abc', G) then
            Observer.Observe('exact', G)
        else
            Observer.ObserveError('exact');
        if TryGet(Req, 'abc', G) then
            Observer.Observe('lower', G)
        else
            Observer.ObserveError('lower');
        if TryGet(Req, 'missing', G) then
            Observer.Observe('missing', G)
        else
            Observer.ObserveError('missing');
        if TryGet(Req, '', G) then
            Observer.Observe('empty_name', G)
        else
            Observer.ObserveError('empty_name');
        Observer.Expect('exact', 'Yes|Abc|v');
        Observer.Expect('lower', 'No');
        Observer.Expect('missing', 'No');
        Observer.Expect('empty_name', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Cookie_And_HeaderInteraction()
    var
        Observer: Codeunit "Probe Observer";
        Req: HttpRequestMessage;
        H: HttpHeaders;
        Vals: array[3] of Text;
        Ok: Boolean;
    begin
        Req.SetRequestUri('https://example.invalid/');
        Req.GetHeaders(H);
        Req.SetCookie('a', '1');
        Observer.Observe('header_cookie', Format(H.Contains('Cookie')));
        Observer.Observe('keys', Format(H.Keys().Count()));
        Ok := H.Add('Cookie', 'manual=1');
        Observer.Observe('add_cookie_header', Format(Ok));
        Names(Observer, 'names_after_manual', Req);
        Observer.Expect('header_cookie', 'Yes');
        Observer.Expect('keys', '1');
        Observer.Expect('add_cookie_header', 'Yes');
        Observer.Expect('names_after_manual', '2:a;manual;');
        Observer.Verify();
    end;
}
