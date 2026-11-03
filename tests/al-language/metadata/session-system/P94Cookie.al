// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/cookie/cookie-data-type
// Scope: in-scope
// Fixtures used: Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Cookie.Name, Value (get and set), Domain, Path, Expires, Secure, HttpOnly (get) on a cookie built in AL and on cookies read with HttpResponseMessage.GetCookie / GetCookieNames from a response built locally with Set-Cookie headers. No request is sent.
// BC versions: 29 (27 and 28 by CI)

codeunit 73085 "LT P94 Cookie"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure ErrText(): Text
    begin
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryAddSetCookie(var Resp: HttpResponseMessage; Header: Text)
    var
        Headers: HttpHeaders;
    begin
        Headers := Resp.Headers;
        Headers.Add('Set-Cookie', Header);
    end;

    local procedure SetName(var C: Cookie; NewName: Text)
    var
        Ignore: Text;
    begin
        Ignore := C.Name(NewName);
    end;

    local procedure SetValue(var C: Cookie; NewValue: Text)
    var
        Ignore: Text;
    begin
        Ignore := C.Value(NewValue);
    end;

    local procedure Describe(var C: Cookie): Text
    begin
        exit('name=[' + C.Name() + '];value=[' + C.Value() + '];domain=[' + C.Domain() + '];path=[' + C.Path() + '];secure=' + Format(C.Secure()) + ';httpOnly=' + Format(C.HttpOnly()) + ';expires=' + Format(C.Expires(), 0, 9));
    end;

    local procedure ReadCookie(Header: Text; CookieName: Text): Text
    var
        Resp: HttpResponseMessage;
        C: Cookie;
        Names: List of [Text];
    begin
        if not TryAddSetCookie(Resp, Header) then
            exit('add ' + ErrText());
        Names := Resp.GetCookieNames();
        if not Resp.GetCookie(CookieName, C) then
            exit('not found; names=' + Format(Names.Count()));
        exit(Describe(C));
    end;

    [Test]
    procedure Fresh_Defaults()
    var
        C: Cookie;
    begin
        Observer.Observe('name', '[' + C.Name() + ']');
        Observer.Observe('value', '[' + C.Value() + ']');
        Observer.Observe('domain', '[' + C.Domain() + ']');
        Observer.Observe('path', '[' + C.Path() + ']');
        Observer.Observe('secure', Format(C.Secure()));
        Observer.Observe('httpOnly', Format(C.HttpOnly()));
        Observer.Observe('expires', Format(C.Expires(), 0, 9));
        Observer.Observe('expiresIsZero', Format(C.Expires() = 0DT));
        Observer.Expect('name', '[]');
        Observer.Expect('value', '[]');
        Observer.Expect('domain', '[]');
        Observer.Expect('path', '[]');
        Observer.Expect('secure', 'No');
        Observer.Expect('httpOnly', 'No');
        Observer.Expect('expires', '');
        Observer.Expect('expiresIsZero', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SetName_DoesNotTouchOtherMembers()
    var
        C: Cookie;
    begin
        SetName(C, 'n');
        SetValue(C, 'v');
        Observer.Observe('all', Describe(C));
        SetName(C, 'n2');
        Observer.Observe('afterRename', Describe(C));
        Observer.Expect('all', 'name=[n];value=[v];domain=[];path=[];secure=No;httpOnly=No;expires=');
        Observer.Expect('afterRename', 'name=[n2];value=[v];domain=[];path=[];secure=No;httpOnly=No;expires=');
        Observer.Verify();
    end;

    [Test]
    procedure Copy_AndClear()
    var
        A: Cookie;
        B: Cookie;
    begin
        SetName(A, 'n');
        SetValue(A, 'v');
        B := A;
        Observer.Observe('copy', Describe(B));
        SetValue(B, 'changed');
        Observer.Observe('originalAfterChange', Describe(A));
        Observer.Observe('copyAfterChange', Describe(B));
        Clear(A);
        Observer.Observe('cleared', Describe(A));
        Observer.Observe('copyAfterClear', Describe(B));
        Observer.Expect('copy', 'name=[n];value=[v];domain=[];path=[];secure=No;httpOnly=No;expires=');
        Observer.Expect('originalAfterChange', 'name=[n];value=[changed];domain=[];path=[];secure=No;httpOnly=No;expires=');
        Observer.Expect('copyAfterChange', 'name=[n];value=[changed];domain=[];path=[];secure=No;httpOnly=No;expires=');
        Observer.Expect('cleared', 'name=[];value=[];domain=[];path=[];secure=No;httpOnly=No;expires=');
        Observer.Expect('copyAfterClear', 'name=[n];value=[changed];domain=[];path=[];secure=No;httpOnly=No;expires=');
        Observer.Verify();
    end;

    [Test]
    procedure Response_NoCookies()
    var
        Resp: HttpResponseMessage;
        C: Cookie;
        Names: List of [Text];
    begin
        Names := Resp.GetCookieNames();
        Observer.Observe('names', Format(Names.Count()));
        SetName(C, 'keep');
        Observer.Observe('found', Format(Resp.GetCookie('sid', C)));
        Observer.Observe('afterMiss', Describe(C));
        Observer.Expect('names', '0');
        Observer.Expect('found', 'No');
        Observer.Expect('afterMiss', 'name=[keep];value=[];domain=[];path=[];secure=No;httpOnly=No;expires=');
        Observer.Verify();
    end;

    [Test]
    procedure Response_AddSetCookieHeader()
    var
        Resp: HttpResponseMessage;
        Headers: HttpHeaders;
        Names: List of [Text];
    begin
        Headers := Resp.Headers;
        Observer.Observe('add', Format(TryAddSetCookie(Resp, 'sid=abc123')));
        Observer.Observe('headerKeys', Format(Headers.Keys().Count()));
        Observer.Observe('hasHeader', Format(Headers.Contains('Set-Cookie')));
        Names := Resp.GetCookieNames();
        Observer.Observe('names', Format(Names.Count()));
        Observer.Expect('add', 'Yes');
        Observer.Expect('headerKeys', '1');
        Observer.Expect('hasHeader', 'Yes');
        Observer.Expect('names', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Response_SimpleCookie()
    begin
        Observer.Observe('simple', ReadCookie('sid=abc123', 'sid'));
        Observer.Observe('caseName', ReadCookie('sid=abc123', 'SID'));
        Observer.Observe('missing', ReadCookie('sid=abc123', 'other'));
        Observer.Expect('simple', 'name=[sid];value=[abc123];domain=[];path=[/];secure=No;httpOnly=No;expires=');
        Observer.Expect('caseName', 'not found; names=1');
        Observer.Expect('missing', 'not found; names=1');
        Observer.Verify();
    end;

    [Test]
    procedure Response_AllAttributes()
    begin
        asserterror Observer.Observe('all', ReadCookie('sid=abc; Path=/app; Domain=example.com; Secure; HttpOnly; Expires=Wed, 21 Oct 2037 07:28:00 GMT', 'sid'));
        Observer.ObserveError('af199');
        Observer.Expect('af199|text', 'An error occurred when parsing the Cookie header for Uri ''https://bccookie.microsoft.com/''.');
        Observer.Expect('af199|code', 'AL:Cookie');
        Observer.Verify();
    end;

    [Test]
    procedure Response_AttributeCaseInsensitive()
    begin
        asserterror Observer.Observe('lower', ReadCookie('sid=abc; path=/x; domain=example.org; secure; httponly', 'sid'));
        Observer.ObserveError('af207');
        asserterror Observer.Observe('upper', ReadCookie('sid=abc; PATH=/y; DOMAIN=example.net; SECURE; HTTPONLY', 'sid'));
        Observer.ObserveError('af210');
        Observer.Expect('af207|text', 'An error occurred when parsing the Cookie header for Uri ''https://bccookie.microsoft.com/''.');
        Observer.Expect('af207|code', 'AL:Cookie');
        Observer.Expect('af210|text', 'An error occurred when parsing the Cookie header for Uri ''https://bccookie.microsoft.com/''.');
        Observer.Expect('af210|code', 'AL:Cookie');
        Observer.Verify();
    end;

    [Test]
    procedure Response_OneAttributeEach()
    begin
        Observer.Observe('path', ReadCookie('sid=abc; Path=/only', 'sid'));
        asserterror Observer.Observe('domain', ReadCookie('sid=abc; Domain=example.com', 'sid'));
        Observer.ObserveError('af217');
        Observer.Observe('secure', ReadCookie('sid=abc; Secure', 'sid'));
        Observer.Observe('httpOnly', ReadCookie('sid=abc; HttpOnly', 'sid'));
        Observer.Observe('expires', ReadCookie('sid=abc; Expires=Wed, 21 Oct 2037 07:28:00 GMT', 'sid'));
        Observer.Observe('sameSite', ReadCookie('sid=abc; SameSite=Lax', 'sid'));
        Observer.Expect('path', 'not found; names=0');
        Observer.Expect('af217|text', 'An error occurred when parsing the Cookie header for Uri ''https://bccookie.microsoft.com/''.');
        Observer.Expect('af217|code', 'AL:Cookie');
        Observer.Expect('secure', 'name=[sid];value=[abc];domain=[];path=[/];secure=Yes;httpOnly=No;expires=');
        Observer.Expect('httpOnly', 'name=[sid];value=[abc];domain=[];path=[/];secure=No;httpOnly=Yes;expires=');
        Observer.Expect('expires', 'name=[sid];value=[abc];domain=[];path=[/];secure=No;httpOnly=No;expires=2037-10-21T07:28:00Z');
        Observer.Expect('sameSite', 'name=[sid];value=[abc];domain=[];path=[/];secure=No;httpOnly=No;expires=');
        Observer.Verify();
    end;

    [Test]
    procedure Response_MaxAge()
    var
        Resp: HttpResponseMessage;
        C: Cookie;
    begin
        TryAddSetCookie(Resp, 'sid=abc; Max-Age=3600');
        Observer.Observe('found', Format(Resp.GetCookie('sid', C)));
        Observer.Observe('expiresSet', Format(C.Expires() <> 0DT));
        Observer.Observe('expiresInFuture', Format(C.Expires() > CurrentDateTime()));
        Observer.Expect('found', 'Yes');
        Observer.Expect('expiresSet', 'Yes');
        Observer.Expect('expiresInFuture', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Response_ExpiresInPast()
    var
        Resp: HttpResponseMessage;
        C: Cookie;
    begin
        TryAddSetCookie(Resp, 'old=1; Expires=Thu, 01 Jan 1970 00:00:01 GMT');
        Observer.Observe('found', Format(Resp.GetCookie('old', C)));
        Observer.Observe('describe', Describe(C));
        Observer.Expect('found', 'No');
        Observer.Expect('describe', 'name=[];value=[];domain=[];path=[];secure=No;httpOnly=No;expires=');
        Observer.Verify();
    end;

    [Test]
    procedure Response_ValueForms()
    begin
        Observer.Observe('empty', ReadCookie('sid=', 'sid'));
        Observer.Observe('quoted', ReadCookie('sid="abc def"', 'sid'));
        Observer.Observe('equalsInValue', ReadCookie('sid=a=b=c', 'sid'));
        Observer.Observe('noEquals', ReadCookie('sid', 'sid'));
        Observer.Observe('spaces', ReadCookie('sid = abc', 'sid'));
        Observer.Expect('empty', 'name=[sid];value=[];domain=[];path=[/];secure=No;httpOnly=No;expires=');
        Observer.Expect('quoted', 'name=[sid];value=["abc def"];domain=[];path=[/];secure=No;httpOnly=No;expires=');
        Observer.Expect('equalsInValue', 'name=[sid];value=[a=b=c];domain=[];path=[/];secure=No;httpOnly=No;expires=');
        Observer.Expect('noEquals', 'name=[sid];value=[];domain=[];path=[/];secure=No;httpOnly=No;expires=');
        Observer.Expect('spaces', 'name=[sid];value=[abc];domain=[];path=[/];secure=No;httpOnly=No;expires=');
        Observer.Verify();
    end;

    [Test]
    procedure Response_MultipleCookies()
    var
        Resp: HttpResponseMessage;
        C: Cookie;
        Names: List of [Text];
        N: Text;
        i: Integer;
    begin
        TryAddSetCookie(Resp, 'a=1; Path=/a');
        TryAddSetCookie(Resp, 'b=2; Secure');
        TryAddSetCookie(Resp, 'c=3; HttpOnly');
        Names := Resp.GetCookieNames();
        Observer.Observe('count', Format(Names.Count()));
        foreach N in Names do begin
            i += 1;
            Observer.Observe('name' + Format(i), N);
        end;
        Observer.Observe('getB', Format(Resp.GetCookie('b', C)));
        Observer.Observe('describeB', Describe(C));
        Observer.Observe('getA', Format(Resp.GetCookie('a', C)));
        Observer.Observe('describeA', Describe(C));
        Observer.Expect('count', '2');
        Observer.Expect('name1', 'b');
        Observer.Expect('name2', 'c');
        Observer.Expect('getB', 'Yes');
        Observer.Expect('describeB', 'name=[b];value=[2];domain=[];path=[/];secure=Yes;httpOnly=No;expires=');
        Observer.Expect('getA', 'No');
        Observer.Expect('describeA', 'name=[b];value=[2];domain=[];path=[/];secure=Yes;httpOnly=No;expires=');
        Observer.Verify();
    end;

    [Test]
    procedure Response_SameNameTwice()
    var
        Resp: HttpResponseMessage;
        C: Cookie;
        Names: List of [Text];
    begin
        TryAddSetCookie(Resp, 'dup=first; Path=/1');
        TryAddSetCookie(Resp, 'dup=second; Path=/2');
        Names := Resp.GetCookieNames();
        Observer.Observe('count', Format(Names.Count()));
        Observer.Observe('found', Format(Resp.GetCookie('dup', C)));
        Observer.Observe('describe', Describe(C));
        Observer.Expect('count', '0');
        Observer.Expect('found', 'No');
        Observer.Expect('describe', 'name=[];value=[];domain=[];path=[];secure=No;httpOnly=No;expires=');
        Observer.Verify();
    end;

    [Test]
    procedure Response_ReadCookieIsIndependentCopy()
    var
        Resp: HttpResponseMessage;
        C1: Cookie;
        C2: Cookie;
    begin
        TryAddSetCookie(Resp, 'sid=abc');
        Resp.GetCookie('sid', C1);
        SetValue(C1, 'changed');
        Resp.GetCookie('sid', C2);
        Observer.Observe('first', Describe(C1));
        Observer.Observe('second', Describe(C2));
        Observer.Expect('first', 'name=[sid];value=[changed];domain=[];path=[/];secure=No;httpOnly=No;expires=');
        Observer.Expect('second', 'name=[sid];value=[abc];domain=[];path=[/];secure=No;httpOnly=No;expires=');
        Observer.Verify();
    end;

    [Test]
    procedure Response_EmptyAndBlankNames()
    var
        Resp: HttpResponseMessage;
        C: Cookie;
    begin
        TryAddSetCookie(Resp, 'sid=abc');
        Observer.Observe('emptyName', Format(Resp.GetCookie('', C)));
        Observer.Observe('blankName', Format(Resp.GetCookie(' ', C)));
        Observer.Expect('emptyName', 'No');
        Observer.Expect('blankName', 'No');
        Observer.Verify();
    end;

    // Corpus issue #671 (odd AL behavior leads, part F) item 24: the value the setter form returns when it is used as an expression.
    // As a statement (C.Name('n');) the AL 30.0.42.60748-beta compiler accepts it, but publishing to BC 29.0 fails with
    // "error AL0192: The return value must be used for the method 'Name'" (and 'Value'), so it cannot be in this app.
    [Test]
    procedure Setter_ReturnValue()
    var
        C: Cookie;
        R: Text;
    begin
        R := C.Name('n1');
        Observer.Observe('nameFirst', '[' + R + ']');
        R := C.Name('n2');
        Observer.Observe('nameSecond', '[' + R + ']');
        Observer.Observe('nameNow', '[' + C.Name() + ']');
        R := C.Value('v1');
        Observer.Observe('valueFirst', '[' + R + ']');
        R := C.Value('v2');
        Observer.Observe('valueSecond', '[' + R + ']');
        Observer.Observe('valueNow', '[' + C.Value() + ']');
        Observer.Observe('inExpression', C.Name('n3') + '|' + C.Value('v3'));
        Observer.Observe('afterExpression', C.Name() + '=' + C.Value());
        Observer.Expect('nameFirst', '[n1]');
        Observer.Expect('nameSecond', '[n2]');
        Observer.Expect('nameNow', '[n2]');
        Observer.Expect('valueFirst', '[v1]');
        Observer.Expect('valueSecond', '[v2]');
        Observer.Expect('valueNow', '[v2]');
        Observer.Expect('inExpression', 'n3|v3');
        Observer.Expect('afterExpression', 'n3=v3');
        Observer.Verify();
    end;
}
