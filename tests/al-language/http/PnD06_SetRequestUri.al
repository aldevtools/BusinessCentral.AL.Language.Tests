// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httprequestmessage/httprequestmessage-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained objects codeunit 72038
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles docs/probes-needed.md row: Builtins refused until a probe pins them: HttpRequestMessage.Method, GetRequestUri read before a set - Probe wanted: SetRequestUri of a relative uri, of http:, of text without white space and without a scheme
// Facts: result of SetRequestUri and the uri GetRequestUri returns afterwards, for relative uris, scheme-only text, text without scheme, white space; error text and code when it raises
// BC versions: 29 (27 and 28 by CI)

codeunit 72038 "LT PnD SetRequestUri"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure TrySet(Uri: Text): Text
    var
        Request: HttpRequestMessage;
        Ok: Boolean;
    begin
        if not TrySetImpl(Request, Uri, Ok) then
            exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode() + ' uri=[' + Request.GetRequestUri() + ']');
        exit('result=' + Format(Ok) + ' uri=[' + Request.GetRequestUri() + ']');
    end;

    [TryFunction]
    local procedure TrySetImpl(var Request: HttpRequestMessage; Uri: Text; var Ok: Boolean)
    begin
        Ok := Request.SetRequestUri(Uri);
    end;

    [Test]
    procedure SetRequestUri_Relative()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('relPath', TrySet('/api/v1/items'));
        Observer.Observe('relNoSlash', TrySet('api/v1/items'));
        Observer.Observe('relDot', TrySet('./items'));
        Observer.Observe('relParent', TrySet('../items'));
        Observer.Observe('relQuery', TrySet('?a=1'));
        Observer.Observe('relFragment', TrySet('#top'));
        Observer.Observe('relSlash', TrySet('/'));
        Observer.Expect('relPath', 'result=No uri=[]');
        Observer.Expect('relNoSlash', 'result=No uri=[]');
        Observer.Expect('relDot', 'result=No uri=[]');
        Observer.Expect('relParent', 'result=No uri=[]');
        Observer.Expect('relQuery', 'result=No uri=[]');
        Observer.Expect('relFragment', 'result=No uri=[]');
        Observer.Expect('relSlash', 'result=No uri=[]');
        Observer.Verify();
    end;

    [Test]
    procedure SetRequestUri_SchemeOnlyAndOddSchemes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('httpColon', TrySet('http:'));
        Observer.Observe('httpsColon', TrySet('https:'));
        Observer.Observe('httpColonSlashes', TrySet('http://'));
        Observer.Observe('httpHostOnly', TrySet('http://host'));
        Observer.Observe('ftp', TrySet('ftp://host/file'));
        Observer.Observe('mailto', TrySet('mailto:a@b.c'));
        Observer.Observe('file', TrySet('file:///x'));
        Observer.Observe('upper', TrySet('HTTP://HOST/Path'));
        Observer.Expect('httpColon', 'result=No uri=[]');
        Observer.Expect('httpsColon', 'result=No uri=[]');
        Observer.Expect('httpColonSlashes', 'result=No uri=[]');
        Observer.Expect('httpHostOnly', 'result=Yes uri=[http://host/]');
        Observer.Expect('ftp', 'result=Yes uri=[ftp://host/file]');
        Observer.Expect('mailto', 'result=Yes uri=[mailto:a@b.c]');
        Observer.Expect('file', 'result=Yes uri=[file:///x]');
        Observer.Expect('upper', 'result=Yes uri=[http://host/Path]');
        Observer.Verify();
    end;

    [Test]
    procedure SetRequestUri_NoSchemeNoWhiteSpace()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('word', TrySet('abc'));
        Observer.Observe('host', TrySet('example.com'));
        Observer.Observe('hostPath', TrySet('example.com/path'));
        Observer.Observe('hostPort', TrySet('localhost:8080'));
        Observer.Observe('colonOnly', TrySet(':'));
        Observer.Observe('slashes', TrySet('//host/path'));
        Observer.Observe('percent', TrySet('%'));
        Observer.Expect('word', 'result=No uri=[]');
        Observer.Expect('host', 'result=No uri=[]');
        Observer.Expect('hostPath', 'result=No uri=[]');
        Observer.Expect('hostPort', 'result=Yes uri=[localhost:8080]');
        Observer.Expect('colonOnly', 'result=No uri=[]');
        Observer.Expect('slashes', 'result=Yes uri=[file://host/path]');
        Observer.Expect('percent', 'result=No uri=[]');
        Observer.Verify();
    end;

    [Test]
    procedure SetRequestUri_EmptyAndWhiteSpace()
    var
        Observer: Codeunit "Probe Observer";
        Tab: Text[1];
    begin
        Observer.Observe('empty', TrySet(''));
        Observer.Observe('space', TrySet(' '));
        Observer.Observe('spaces', TrySet('a b'));
        Observer.Observe('leadingSpace', TrySet(' http://host'));
        Observer.Observe('trailingSpace', TrySet('http://host '));
        Observer.Observe('innerSpaceWithScheme', TrySet('http://host/a b'));
        Tab[1] := 9;
        Observer.Observe('tab', TrySet('a' + Tab + 'b'));
        Observer.Expect('empty', 'result=No uri=[]');
        Observer.Expect('space', 'result=No uri=[]');
        Observer.Expect('spaces', 'result=No uri=[]');
        Observer.Expect('leadingSpace', 'result=Yes uri=[http://host/]');
        Observer.Expect('trailingSpace', 'result=Yes uri=[http://host/]');
        Observer.Expect('innerSpaceWithScheme', 'result=Yes uri=[http://host/a%20b]');
        Observer.Expect('tab', 'result=No uri=[]');
        Observer.Verify();
    end;

    [Test]
    procedure SetRequestUri_SecondCallReplaces()
    var
        Observer: Codeunit "Probe Observer";
        Request: HttpRequestMessage;
    begin
        Observer.Observe('first', Format(Request.SetRequestUri('http://one.example/a')));
        Observer.Observe('second', Format(Request.SetRequestUri('/relative')));
        Observer.Observe('uriAfterRelative', Request.GetRequestUri());
        Observer.Observe('third', Format(Request.SetRequestUri('http://two.example/b')));
        Observer.Observe('uriAfterThird', Request.GetRequestUri());
        Observer.Expect('first', 'Yes');
        Observer.Expect('second', 'No');
        Observer.Expect('uriAfterRelative', 'http://one.example/a');
        Observer.Expect('third', 'Yes');
        Observer.Expect('uriAfterThird', 'http://two.example/b');
        Observer.Verify();
    end;
    // Writer PW: docs/probes-needed.md "Values and builtins": http: or https: followed by something other than // (http: and https: alone are
    // invalid, SetRequestUri_SchemeOnlyAndOddSchemes).
    [Test]
    procedure PW_SetRequestUri_SchemeWithoutSlashes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('http:x', TrySet('http:x'));
        Observer.Observe('http:/x', TrySet('http:/x'));
        Observer.Observe('https:x.y', TrySet('https:x.y'));
        Observer.Observe('http:x/p?q=1', TrySet('http:x/p?q=1'));
        Observer.Observe('https:/x.y/p', TrySet('https:/x.y/p'));
        Observer.Observe('http:///x', TrySet('http:///x'));
        Observer.Observe('http:\\x', TrySet('http:\\x'));
        Observer.Observe('HTTP:x', TrySet('HTTP:x'));
        Observer.Expect('http:x', 'result=No uri=[]');
        Observer.Expect('http:/x', 'result=No uri=[]');
        Observer.Expect('https:x.y', 'result=No uri=[]');
        Observer.Expect('http:x/p?q=1', 'result=No uri=[]');
        Observer.Expect('https:/x.y/p', 'result=No uri=[]');
        Observer.Expect('http:///x', 'result=No uri=[]');
        Observer.Expect('http:\\x', 'result=Yes uri=[http://x/]');
        Observer.Expect('HTTP:x', 'result=No uri=[]');
        Observer.Verify();
    end;
}
