// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/cookie/cookie-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: cookie shapes platform/lt-xmlport-session-navapp-cookie/P94Cookie.al and xml/lt-xml-attr-doc-http-members/P97ReqCookie*.al do not pin.
//   A response is built locally with Set-Cookie headers (no request is sent) and read with HttpResponseMessage.GetCookieNames / GetCookie.
// Facts: Expires in other date forms and invalid; Max-Age 0, negative, not a number, with Expires; two cookies in one header value; names that are not
//   tokens; attributes Version, Comment, Port, Discard, Priority, Partitioned, a repeated Path, Secure with a value; names that differ in case.
//   Cookie.Name / Cookie.Value setters with characters a cookie name or value may not hold, and HttpRequestMessage.SetCookie(Cookie) of such a cookie.
//   Expires values are years ahead or 1970, so no assertion depends on the run date; Max-Age results are compared with CurrentDateTime.
// BC versions: 27 - 29

codeunit 90820 "LT Http Cookie Forms"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ErrText(): Text
    var
        T: Text;
    begin
        T := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        ClearLastError();
        exit(T);
    end;

    [TryFunction]
    local procedure TryAddSetCookie(var Resp: HttpResponseMessage; Header: Text)
    var
        Headers: HttpHeaders;
    begin
        Headers := Resp.Headers;
        Headers.Add('Set-Cookie', Header);
    end;

    [TryFunction]
    local procedure TryNames(var Resp: HttpResponseMessage; var Result: Text)
    var
        Names: List of [Text];
        N: Text;
    begin
        Names := Resp.GetCookieNames();
        Result := Format(Names.Count()) + ':';
        foreach N in Names do
            Result += N + ';';
    end;

    [TryFunction]
    local procedure TryGet(var Resp: HttpResponseMessage; Name: Text; var C: Cookie; var Found: Boolean)
    begin
        Found := Resp.GetCookie(Name, C);
    end;

    local procedure Describe(var C: Cookie): Text
    begin
        exit('name=[' + C.Name() + '];value=[' + C.Value() + '];domain=[' + C.Domain() + '];path=[' + C.Path() + '];secure=' + Format(C.Secure()) + ';httpOnly=' + Format(C.HttpOnly()) + ';expires=' + Format(C.Expires(), 0, 9));
    end;

    local procedure ExpiresRel(var C: Cookie): Text
    begin
        if C.Expires() = 0DT then
            exit('none');
        if C.Expires() > CurrentDateTime() then
            exit('future');
        exit('past');
    end;

    // One Set-Cookie header value: the names the response has, then the cookie of that name.
    local procedure Read(Header: Text; CookieName: Text; RelativeExpires: Boolean): Text
    var
        Resp: HttpResponseMessage;
        C: Cookie;
        Names: Text;
        Found: Boolean;
    begin
        if not TryAddSetCookie(Resp, Header) then
            exit('add ' + ErrText());
        if not TryNames(Resp, Names) then
            exit('names ' + ErrText());
        if not TryGet(Resp, CookieName, C, Found) then
            exit('get ' + ErrText());
        if not Found then
            exit('names=' + Names + ' found=No');
        if RelativeExpires then
            exit('names=' + Names + ' found=Yes value=[' + C.Value() + '] expires=' + ExpiresRel(C));
        exit('names=' + Names + ' ' + Describe(C));
    end;

    [Test]
    procedure Response_ExpiresForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('rfc850', Read('sid=a; Expires=Wednesday, 21-Oct-37 07:28:00 GMT', 'sid', false));
        Observer.Observe('dashes4', Read('sid=a; Expires=Wed, 21-Oct-2037 07:28:00 GMT', 'sid', false));
        Observer.Observe('asctime', Read('sid=a; Expires=Wed Oct 21 07:28:00 2037', 'sid', false));
        Observer.Observe('utc', Read('sid=a; Expires=Wed, 21 Oct 2037 07:28:00 UTC', 'sid', false));
        Observer.Observe('offset', Read('sid=a; Expires=Wed, 21 Oct 2037 07:28:00 +0200', 'sid', false));
        Observer.Observe('noZone', Read('sid=a; Expires=Wed, 21 Oct 2037 07:28:00', 'sid', false));
        Observer.Observe('wrongWeekday', Read('sid=a; Expires=Mon, 21 Oct 2037 07:28:00 GMT', 'sid', false));
        Observer.Observe('lowerMonth', Read('sid=a; Expires=Wed, 21 oct 2037 07:28:00 GMT', 'sid', false));
        Observer.Observe('iso', Read('sid=a; Expires=2037-10-21T07:28:00Z', 'sid', false));
        Observer.Observe('garbage', Read('sid=a; Expires=garbage', 'sid', false));
        Observer.Observe('empty', Read('sid=a; Expires=', 'sid', false));
        Observer.Observe('noValue', Read('sid=a; Expires', 'sid', false));
        Observer.Expect('rfc850', 'names=1:sid; name=[sid];value=[a];domain=[];path=[/];secure=No;httpOnly=No;expires=2037-10-21T07:28:00Z');
        Observer.Expect('dashes4', 'names=1:sid; name=[sid];value=[a];domain=[];path=[/];secure=No;httpOnly=No;expires=2037-10-21T07:28:00Z');
        Observer.Expect('asctime', 'names error:An error occurred when parsing the Cookie header for Uri ''https://bccookie.microsoft.com/''.|AL:Cookie');
        Observer.Expect('utc', 'names error:An error occurred when parsing the Cookie header for Uri ''https://bccookie.microsoft.com/''.|AL:Cookie');
        Observer.Expect('offset', 'names=1:sid; name=[sid];value=[a];domain=[];path=[/];secure=No;httpOnly=No;expires=2037-10-21T05:28:00Z');
        Observer.Expect('noZone', 'names=1:sid; name=[sid];value=[a];domain=[];path=[/];secure=No;httpOnly=No;expires=2037-10-21T07:28:00Z');
        Observer.Expect('wrongWeekday', 'names=1:sid; name=[sid];value=[a];domain=[];path=[/];secure=No;httpOnly=No;expires=2037-10-21T07:28:00Z');
        Observer.Expect('lowerMonth', 'names=1:sid; name=[sid];value=[a];domain=[];path=[/];secure=No;httpOnly=No;expires=2037-10-21T07:28:00Z');
        Observer.Expect('iso', 'names=1:sid; name=[sid];value=[a];domain=[];path=[/];secure=No;httpOnly=No;expires=2037-10-21T07:28:00Z');
        Observer.Expect('garbage', 'names error:An error occurred when parsing the Cookie header for Uri ''https://bccookie.microsoft.com/''.|AL:Cookie');
        Observer.Expect('empty', 'names error:An error occurred when parsing the Cookie header for Uri ''https://bccookie.microsoft.com/''.|AL:Cookie');
        Observer.Expect('noValue', 'names=1:sid; name=[sid];value=[a];domain=[];path=[/];secure=No;httpOnly=No;expires=');
        Observer.Verify();
    end;

    [Test]
    procedure Response_MaxAgeForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('zero', Read('sid=a; Max-Age=0', 'sid', true));
        Observer.Observe('minus', Read('sid=a; Max-Age=-1', 'sid', true));
        Observer.Observe('text', Read('sid=a; Max-Age=abc', 'sid', true));
        Observer.Observe('decimal', Read('sid=a; Max-Age=1.5', 'sid', true));
        Observer.Observe('empty', Read('sid=a; Max-Age=', 'sid', true));
        Observer.Observe('plus', Read('sid=a; Max-Age=+3600', 'sid', true));
        Observer.Observe('huge', Read('sid=a; Max-Age=99999999999', 'sid', true));
        Observer.Observe('lowerName', Read('sid=a; max-age=3600', 'sid', true));
        Observer.Observe('futureThenPastExpires', Read('sid=a; Max-Age=3600; Expires=Thu, 01 Jan 1970 00:00:01 GMT', 'sid', true));
        Observer.Observe('pastExpiresThenFuture', Read('sid=a; Expires=Thu, 01 Jan 1970 00:00:01 GMT; Max-Age=3600', 'sid', true));
        Observer.Observe('zeroWithFutureExpires', Read('sid=a; Max-Age=0; Expires=Wed, 21 Oct 2037 07:28:00 GMT', 'sid', true));
        Observer.Expect('zero', 'names=0: found=No');
        Observer.Expect('minus', 'names=0: found=No');
        Observer.Expect('text', 'names error:An error occurred when parsing the Cookie header for Uri ''https://bccookie.microsoft.com/''.|AL:Cookie');
        Observer.Expect('decimal', 'names error:An error occurred when parsing the Cookie header for Uri ''https://bccookie.microsoft.com/''.|AL:Cookie');
        Observer.Expect('empty', 'names error:An error occurred when parsing the Cookie header for Uri ''https://bccookie.microsoft.com/''.|AL:Cookie');
        Observer.Expect('plus', 'names=1:sid; found=Yes value=[a] expires=future');
        Observer.Expect('huge', 'names error:An error occurred when parsing the Cookie header for Uri ''https://bccookie.microsoft.com/''.|AL:Cookie');
        Observer.Expect('lowerName', 'names=1:sid; found=Yes value=[a] expires=future');
        Observer.Expect('futureThenPastExpires', 'names=1:sid; found=Yes value=[a] expires=future');
        Observer.Expect('pastExpiresThenFuture', 'names=0: found=No');
        Observer.Expect('zeroWithFutureExpires', 'names=0: found=No');
        Observer.Verify();
    end;

    [Test]
    procedure Response_TwoCookiesInOneValue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('comma a', Read('a=1, b=2', 'a', false));
        Observer.Observe('comma b', Read('a=1, b=2', 'b', false));
        Observer.Observe('comma no space', Read('a=1,b=2', 'b', false));
        Observer.Observe('comma after expires', Read('a=1; Expires=Wed, 21 Oct 2037 07:28:00 GMT, b=2', 'b', false));
        Observer.Observe('comma in value', Read('a=x,y', 'a', false));
        Observer.Observe('semicolon pair', Read('a=1; b=2', 'b', false));
        Observer.Expect('comma a', 'names=2:a;b; name=[a];value=[1];domain=[];path=[/];secure=No;httpOnly=No;expires=');
        Observer.Expect('comma b', 'names=2:a;b; name=[b];value=[2];domain=[];path=[/];secure=No;httpOnly=No;expires=');
        Observer.Expect('comma no space', 'names=2:a;b; name=[b];value=[2];domain=[];path=[/];secure=No;httpOnly=No;expires=');
        Observer.Expect('comma after expires', 'names=2:a;b; name=[b];value=[2];domain=[];path=[/];secure=No;httpOnly=No;expires=');
        Observer.Expect('comma in value', 'names=2:a;y; name=[a];value=[x];domain=[];path=[/];secure=No;httpOnly=No;expires=');
        Observer.Expect('semicolon pair', 'names=1:a; found=No');
        Observer.Verify();
    end;

    [Test]
    procedure Response_NamesThatAreNotTokens()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('dollar', Read('$x=1', '$x', false));
        Observer.Observe('space inside', Read('a b=1', 'a b', false));
        Observer.Observe('empty name', Read('=abc', '', false));
        Observer.Observe('unicode', Read('café=1', 'café', false));
        Observer.Observe('value unicode', Read('sid=café', 'sid', false));
        Observer.Observe('value space', Read('sid=a b', 'sid', false));
        Observer.Observe('value quote inside', Read('sid=a"b', 'sid', false));
        Observer.Expect('dollar', 'names error:An error occurred when parsing the Cookie header for Uri ''https://bccookie.microsoft.com/''.|AL:Cookie');
        Observer.Expect('space inside', 'names=1:a b; name=[a b];value=[1];domain=[];path=[/];secure=No;httpOnly=No;expires=');
        Observer.Expect('empty name', 'names error:An error occurred when parsing the Cookie header for Uri ''https://bccookie.microsoft.com/''.|AL:Cookie');
        Observer.Expect('unicode', 'names=1:café; name=[café];value=[1];domain=[];path=[/];secure=No;httpOnly=No;expires=');
        Observer.Expect('value unicode', 'names=1:sid; name=[sid];value=[café];domain=[];path=[/];secure=No;httpOnly=No;expires=');
        Observer.Expect('value space', 'names=1:sid; name=[sid];value=[a b];domain=[];path=[/];secure=No;httpOnly=No;expires=');
        Observer.Expect('value quote inside', 'names=1:sid; name=[sid];value=[a"b];domain=[];path=[/];secure=No;httpOnly=No;expires=');
        Observer.Verify();
    end;

    [Test]
    procedure Response_OtherAttributes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('version', Read('sid=a; Version=1', 'sid', false));
        Observer.Observe('comment', Read('sid=a; Comment=hello', 'sid', false));
        Observer.Observe('port', Read('sid=a; Port="443"', 'sid', false));
        Observer.Observe('discard', Read('sid=a; Discard', 'sid', false));
        Observer.Observe('priority', Read('sid=a; Priority=High', 'sid', false));
        Observer.Observe('partitioned', Read('sid=a; Partitioned', 'sid', false));
        Observer.Observe('path twice', Read('sid=a; Path=/x; Path=/', 'sid', false));
        Observer.Observe('path slash', Read('sid=a; Path=/', 'sid', false));
        Observer.Observe('path empty', Read('sid=a; Path=', 'sid', false));
        Observer.Observe('secure false', Read('sid=a; Secure=false', 'sid', false));
        Observer.Observe('httponly value', Read('sid=a; HttpOnly=0', 'sid', false));
        Observer.Observe('trailing semicolon', Read('sid=a;', 'sid', false));
        Observer.Expect('version', 'names=1:sid; name=[sid];value=[a];domain=[];path=[];secure=No;httpOnly=No;expires=');
        Observer.Expect('comment', 'names=1:sid; name=[sid];value=[a];domain=[];path=[/];secure=No;httpOnly=No;expires=');
        Observer.Expect('port', 'names=1:sid; name=[sid];value=[a];domain=[];path=[];secure=No;httpOnly=No;expires=');
        Observer.Expect('discard', 'names=1:sid; name=[sid];value=[a];domain=[];path=[/];secure=No;httpOnly=No;expires=');
        Observer.Expect('priority', 'names=1:sid; name=[sid];value=[a];domain=[];path=[/];secure=No;httpOnly=No;expires=');
        Observer.Expect('partitioned', 'names=1:sid; name=[sid];value=[a];domain=[];path=[/];secure=No;httpOnly=No;expires=');
        Observer.Expect('path twice', 'names=0: found=No');
        Observer.Expect('path slash', 'names=1:sid; name=[sid];value=[a];domain=[];path=[/];secure=No;httpOnly=No;expires=');
        Observer.Expect('path empty', 'names=1:sid; name=[sid];value=[a];domain=[];path=[];secure=No;httpOnly=No;expires=');
        Observer.Expect('secure false', 'names=1:sid; name=[sid];value=[a];domain=[];path=[/];secure=No;httpOnly=No;expires=');
        Observer.Expect('httponly value', 'names=1:sid; name=[sid];value=[a];domain=[];path=[/];secure=No;httpOnly=No;expires=');
        Observer.Expect('trailing semicolon', 'names=1:sid; name=[sid];value=[a];domain=[];path=[/];secure=No;httpOnly=No;expires=');
        Observer.Verify();
    end;

    [Test]
    procedure Response_NamesDifferInCase()
    var
        Observer: Codeunit "Probe Observer";
        Resp: HttpResponseMessage;
        C: Cookie;
        Names: Text;
        Found: Boolean;
    begin
        TryAddSetCookie(Resp, 'SID=upper');
        TryAddSetCookie(Resp, 'sid=lower');
        if TryNames(Resp, Names) then
            Observer.Observe('names', Names)
        else
            Observer.Observe('names', ErrText());
        if TryGet(Resp, 'SID', C, Found) then
            Observer.Observe('get SID', Format(Found) + '|' + C.Value())
        else
            Observer.Observe('get SID', ErrText());
        Clear(C);
        if TryGet(Resp, 'sid', C, Found) then
            Observer.Observe('get sid', Format(Found) + '|' + C.Value())
        else
            Observer.Observe('get sid', ErrText());
        Observer.Expect('names', '1:sid;');
        Observer.Expect('get SID', 'No|');
        Observer.Expect('get sid', 'Yes|lower');
        Observer.Verify();
    end;

    local procedure SetName(NewName: Text): Text
    var
        C: Cookie;
    begin
        if not TrySetName(C, NewName) then
            exit(ErrText());
        exit('ok|[' + C.Name() + ']');
    end;

    [TryFunction]
    local procedure TrySetName(var C: Cookie; NewName: Text)
    var
        Ignore: Text;
    begin
        Ignore := C.Name(NewName);
    end;

    local procedure SetValue(NewValue: Text): Text
    var
        C: Cookie;
    begin
        if not TrySetValue(C, NewValue) then
            exit(ErrText());
        exit('ok|[' + C.Value() + ']');
    end;

    [TryFunction]
    local procedure TrySetValue(var C: Cookie; NewValue: Text)
    var
        Ignore: Text;
    begin
        Ignore := C.Value(NewValue);
    end;

    [Test]
    procedure CookieSetter_InvalidCharacters()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('name space', SetName('a b'));
        Observer.Observe('name semicolon', SetName('a;b'));
        Observer.Observe('name comma', SetName('a,b'));
        Observer.Observe('name equals', SetName('a=b'));
        Observer.Observe('name dollar', SetName('$a'));
        Observer.Observe('name blank', SetName(' '));
        Observer.Observe('name padded', SetName(' a '));
        Observer.Observe('value semicolon', SetValue('a;b'));
        Observer.Observe('value comma', SetValue('a,b'));
        Observer.Observe('value space', SetValue('a b'));
        Observer.Observe('value padded', SetValue(' a '));
        Observer.Expect('name space', 'ok|[a b]');
        Observer.Expect('name semicolon', 'error:The ''Name''=''a;b'' part of the cookie is invalid.|AL:Cookie');
        Observer.Expect('name comma', 'error:The ''Name''=''a,b'' part of the cookie is invalid.|AL:Cookie');
        Observer.Expect('name equals', 'error:The ''Name''=''a=b'' part of the cookie is invalid.|AL:Cookie');
        Observer.Expect('name dollar', 'error:The ''Name''=''$a'' part of the cookie is invalid.|AL:Cookie');
        Observer.Expect('name blank', 'error:The ''Name''='' '' part of the cookie is invalid.|AL:Cookie');
        Observer.Expect('name padded', 'error:The ''Name''='' a '' part of the cookie is invalid.|AL:Cookie');
        Observer.Expect('value semicolon', 'ok|[a;b]');
        Observer.Expect('value comma', 'ok|[a,b]');
        Observer.Expect('value space', 'ok|[a b]');
        Observer.Expect('value padded', 'ok|[ a ]');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TrySetCookieObj(var Req: HttpRequestMessage; var C: Cookie; var Result: Boolean)
    begin
        Result := Req.SetCookie(C);
    end;

    local procedure RequestWithValue(NewValue: Text): Text
    var
        Req: HttpRequestMessage;
        C: Cookie;
        Back: Cookie;
        Ignore: Text;
        Ok: Boolean;
    begin
        Ignore := C.Name('obj');
        Ignore := C.Value(NewValue);
        if not TrySetCookieObj(Req, C, Ok) then
            exit('set ' + ErrText());
        if not Req.GetCookie('obj', Back) then
            exit(Format(Ok) + '|get=No');
        exit(Format(Ok) + '|get=Yes|[' + Back.Value() + ']');
    end;

    [Test]
    procedure RequestSetCookieObject_InvalidValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('semicolon', RequestWithValue('a;b'));
        Observer.Observe('comma', RequestWithValue('a,b'));
        Observer.Observe('space', RequestWithValue('a b'));
        Observer.Observe('quoted', RequestWithValue('"q"'));
        Observer.Expect('semicolon', 'No|get=No');
        Observer.Expect('comma', 'No|get=No');
        Observer.Expect('space', 'Yes|get=Yes|[a b]');
        Observer.Expect('quoted', 'Yes|get=Yes|["q"]');
        Observer.Verify();
    end;
}
