// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpheaders/httpheaders-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), LT P87 Helper (codeunit 74228)
// Probe: written against BC 29 (runtime 16); every value is observed through Probe Observer and measured later on real BC 29. No request is ever sent.
// Facts: header values with line breaks, spaces, commas and quotes; a header added twice
// BC versions: 29

codeunit 74223 "LT P87 Header Values"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT P87 Helper";

    local procedure Line(Kind: Integer; N: Text; V: Text): Text
    var
        H: HttpHeaders;
        H2: HttpHeaders;
        Res: Text;
    begin
        Helper.GetH(Kind, H);
        Res := 'add=' + Helper.DoAdd(H, N, V);
        Res += ';get=' + Helper.DoGet(H, N);
        Helper.GetH(Kind, H2);
        Res += ';raw=' + Helper.DoRaw(H2, N, V);
        Res += ';get2=' + Helper.DoGet(H2, N);
        exit(Res);
    end;

    local procedure Special(var Observer: Codeunit "Probe Observer"; Kind: Integer; FromIdx: Integer; ToIdx: Integer)
    var
        Cr: Text[1];
        Lf: Text[1];
        Tab: Text[1];
        Idx: Integer;
    begin
        Cr[1] := 13;
        Lf[1] := 10;
        Tab[1] := 9;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('plain', Line(Kind, 'X-Custom', 'abc'));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('lf', Line(Kind, 'X-Custom', 'a' + Lf + 'b'));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('crlf', Line(Kind, 'X-Custom', 'a' + Cr + Lf + 'b'));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('cr', Line(Kind, 'X-Custom', 'a' + Cr + 'b'));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('crlfSpace', Line(Kind, 'X-Custom', 'a' + Cr + Lf + ' b'));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('trailingLf', Line(Kind, 'X-Custom', 'a' + Lf));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('leadingSpaces', Line(Kind, 'X-Custom', '   lead'));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('trailingSpaces', Line(Kind, 'X-Custom', 'trail   '));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('bothSpaces', Line(Kind, 'X-Custom', '  both  '));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('onlySpaces', Line(Kind, 'X-Custom', '   '));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('empty', Line(Kind, 'X-Custom', ''));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('tab', Line(Kind, 'X-Custom', 'a' + Tab + 'b'));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('innerSpaces', Line(Kind, 'X-Custom', 'a   b'));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('comma', Line(Kind, 'X-Custom', 'a,b'));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('commaSpaces', Line(Kind, 'X-Custom', 'a, b ,c'));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('quoted', Line(Kind, 'X-Custom', '"quoted"'));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('quotedComma', Line(Kind, 'X-Custom', '"a,b"'));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('unbalancedQuote', Line(Kind, 'X-Custom', '"abc'));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('semicolon', Line(Kind, 'X-Custom', 'a;b=c'));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('unicode', Line(Kind, 'X-Custom', 'äö€'));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('colon', Line(Kind, 'X-Custom', 'a:b'));
        Idx += 1;
        if (Idx >= FromIdx) and (Idx <= ToIdx) then
            Observer.Observe('digitZero', Line(Kind, 'X-Custom', 'a' + Format(0) + 'b'));
        Idx += 1;
    end;

    [Test]
    procedure SpecialValues_RequestHeaders_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Special(Observer, 1, 0, 5);
        Observer.Expect('plain', 'add=added;get=Yes/n=1/1=abc/2=;raw=Yes;get2=Yes/n=1/1=abc/2=');
        Observer.Expect('lf', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=No/n=0/1=/2=;raw=Yes;get2=Yes/n=1/1=a\nb/2=');
        Observer.Expect('crlf', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=No/n=0/1=/2=;raw=Yes;get2=Yes/n=1/1=a\r\nb/2=');
        Observer.Expect('cr', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=No/n=0/1=/2=;raw=Yes;get2=Yes/n=1/1=a\rb/2=');
        Observer.Expect('crlfSpace', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=No/n=0/1=/2=;raw=Yes;get2=Yes/n=1/1=a\r\n b/2=');
        Observer.Expect('trailingLf', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=No/n=0/1=/2=;raw=Yes;get2=Yes/n=1/1=a\n/2=');
        Observer.Verify();
    end;

    [Test]
    procedure SpecialValues_RequestHeaders_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Special(Observer, 1, 6, 11);
        Observer.Expect('leadingSpaces', 'add=added;get=Yes/n=1/1=   lead/2=;raw=Yes;get2=Yes/n=1/1=   lead/2=');
        Observer.Expect('trailingSpaces', 'add=added;get=Yes/n=1/1=trail   /2=;raw=Yes;get2=Yes/n=1/1=trail   /2=');
        Observer.Expect('bothSpaces', 'add=added;get=Yes/n=1/1=  both  /2=;raw=Yes;get2=Yes/n=1/1=  both  /2=');
        Observer.Expect('onlySpaces', 'add=added;get=Yes/n=1/1=   /2=;raw=Yes;get2=Yes/n=1/1=   /2=');
        Observer.Expect('empty', 'add=added;get=Yes/n=0/1=/2=;raw=Yes;get2=Yes/n=0/1=/2=');
        Observer.Expect('tab', 'add=added;get=Yes/n=1/1=a\tb/2=;raw=Yes;get2=Yes/n=1/1=a\tb/2=');
        Observer.Verify();
    end;

    [Test]
    procedure SpecialValues_RequestHeaders_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Special(Observer, 1, 12, 17);
        Observer.Expect('innerSpaces', 'add=added;get=Yes/n=1/1=a   b/2=;raw=Yes;get2=Yes/n=1/1=a   b/2=');
        Observer.Expect('comma', 'add=added;get=Yes/n=1/1=a,b/2=;raw=Yes;get2=Yes/n=1/1=a,b/2=');
        Observer.Expect('commaSpaces', 'add=added;get=Yes/n=1/1=a, b ,c/2=;raw=Yes;get2=Yes/n=1/1=a, b ,c/2=');
        Observer.Expect('quoted', 'add=added;get=Yes/n=1/1="quoted"/2=;raw=Yes;get2=Yes/n=1/1="quoted"/2=');
        Observer.Expect('quotedComma', 'add=added;get=Yes/n=1/1="a,b"/2=;raw=Yes;get2=Yes/n=1/1="a,b"/2=');
        Observer.Expect('unbalancedQuote', 'add=added;get=Yes/n=1/1="abc/2=;raw=Yes;get2=Yes/n=1/1="abc/2=');
        Observer.Verify();
    end;

    [Test]
    procedure SpecialValues_RequestHeaders_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Special(Observer, 1, 18, 23);
        Observer.Expect('semicolon', 'add=added;get=Yes/n=1/1=a;b=c/2=;raw=Yes;get2=Yes/n=1/1=a;b=c/2=');
        Observer.Expect('unicode', 'add=added;get=Yes/n=1/1=äö€/2=;raw=Yes;get2=Yes/n=1/1=äö€/2=');
        Observer.Expect('colon', 'add=added;get=Yes/n=1/1=a:b/2=;raw=Yes;get2=Yes/n=1/1=a:b/2=');
        Observer.Expect('digitZero', 'add=added;get=Yes/n=1/1=a0b/2=;raw=Yes;get2=Yes/n=1/1=a0b/2=');
        Observer.Verify();
    end;

    [Test]
    procedure SpecialValues_ContentHeaders_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Special(Observer, 3, 0, 5);
        Observer.Expect('plain', 'add=added;get=Yes/n=1/1=abc/2=;raw=Yes;get2=Yes/n=1/1=abc/2=');
        Observer.Expect('lf', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=No/n=0/1=/2=;raw=Yes;get2=Yes/n=1/1=a\nb/2=');
        Observer.Expect('crlf', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=No/n=0/1=/2=;raw=Yes;get2=Yes/n=1/1=a\r\nb/2=');
        Observer.Expect('cr', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=No/n=0/1=/2=;raw=Yes;get2=Yes/n=1/1=a\rb/2=');
        Observer.Expect('crlfSpace', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=No/n=0/1=/2=;raw=Yes;get2=Yes/n=1/1=a\r\n b/2=');
        Observer.Expect('trailingLf', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=No/n=0/1=/2=;raw=Yes;get2=Yes/n=1/1=a\n/2=');
        Observer.Verify();
    end;

    [Test]
    procedure SpecialValues_ContentHeaders_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Special(Observer, 3, 6, 11);
        Observer.Expect('leadingSpaces', 'add=added;get=Yes/n=1/1=   lead/2=;raw=Yes;get2=Yes/n=1/1=   lead/2=');
        Observer.Expect('trailingSpaces', 'add=added;get=Yes/n=1/1=trail   /2=;raw=Yes;get2=Yes/n=1/1=trail   /2=');
        Observer.Expect('bothSpaces', 'add=added;get=Yes/n=1/1=  both  /2=;raw=Yes;get2=Yes/n=1/1=  both  /2=');
        Observer.Expect('onlySpaces', 'add=added;get=Yes/n=1/1=   /2=;raw=Yes;get2=Yes/n=1/1=   /2=');
        Observer.Expect('empty', 'add=added;get=Yes/n=0/1=/2=;raw=Yes;get2=Yes/n=0/1=/2=');
        Observer.Expect('tab', 'add=added;get=Yes/n=1/1=a\tb/2=;raw=Yes;get2=Yes/n=1/1=a\tb/2=');
        Observer.Verify();
    end;

    [Test]
    procedure SpecialValues_ContentHeaders_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Special(Observer, 3, 12, 17);
        Observer.Expect('innerSpaces', 'add=added;get=Yes/n=1/1=a   b/2=;raw=Yes;get2=Yes/n=1/1=a   b/2=');
        Observer.Expect('comma', 'add=added;get=Yes/n=1/1=a,b/2=;raw=Yes;get2=Yes/n=1/1=a,b/2=');
        Observer.Expect('commaSpaces', 'add=added;get=Yes/n=1/1=a, b ,c/2=;raw=Yes;get2=Yes/n=1/1=a, b ,c/2=');
        Observer.Expect('quoted', 'add=added;get=Yes/n=1/1="quoted"/2=;raw=Yes;get2=Yes/n=1/1="quoted"/2=');
        Observer.Expect('quotedComma', 'add=added;get=Yes/n=1/1="a,b"/2=;raw=Yes;get2=Yes/n=1/1="a,b"/2=');
        Observer.Expect('unbalancedQuote', 'add=added;get=Yes/n=1/1="abc/2=;raw=Yes;get2=Yes/n=1/1="abc/2=');
        Observer.Verify();
    end;

    [Test]
    procedure SpecialValues_ContentHeaders_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Special(Observer, 3, 18, 23);
        Observer.Expect('semicolon', 'add=added;get=Yes/n=1/1=a;b=c/2=;raw=Yes;get2=Yes/n=1/1=a;b=c/2=');
        Observer.Expect('unicode', 'add=added;get=Yes/n=1/1=äö€/2=;raw=Yes;get2=Yes/n=1/1=äö€/2=');
        Observer.Expect('colon', 'add=added;get=Yes/n=1/1=a:b/2=;raw=Yes;get2=Yes/n=1/1=a:b/2=');
        Observer.Expect('digitZero', 'add=added;get=Yes/n=1/1=a0b/2=;raw=Yes;get2=Yes/n=1/1=a0b/2=');
        Observer.Verify();
    end;

    [Test]
    procedure SpecialValues_ResponseHeaders_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Special(Observer, 4, 0, 5);
        Observer.Expect('plain', 'add=added;get=Yes/n=1/1=abc/2=;raw=Yes;get2=Yes/n=1/1=abc/2=');
        Observer.Expect('lf', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=No/n=0/1=/2=;raw=Yes;get2=Yes/n=1/1=a\nb/2=');
        Observer.Expect('crlf', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=No/n=0/1=/2=;raw=Yes;get2=Yes/n=1/1=a\r\nb/2=');
        Observer.Expect('cr', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=No/n=0/1=/2=;raw=Yes;get2=Yes/n=1/1=a\rb/2=');
        Observer.Expect('crlfSpace', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=No/n=0/1=/2=;raw=Yes;get2=Yes/n=1/1=a\r\n b/2=');
        Observer.Expect('trailingLf', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=No/n=0/1=/2=;raw=Yes;get2=Yes/n=1/1=a\n/2=');
        Observer.Verify();
    end;

    [Test]
    procedure SpecialValues_ResponseHeaders_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Special(Observer, 4, 6, 11);
        Observer.Expect('leadingSpaces', 'add=added;get=Yes/n=1/1=   lead/2=;raw=Yes;get2=Yes/n=1/1=   lead/2=');
        Observer.Expect('trailingSpaces', 'add=added;get=Yes/n=1/1=trail   /2=;raw=Yes;get2=Yes/n=1/1=trail   /2=');
        Observer.Expect('bothSpaces', 'add=added;get=Yes/n=1/1=  both  /2=;raw=Yes;get2=Yes/n=1/1=  both  /2=');
        Observer.Expect('onlySpaces', 'add=added;get=Yes/n=1/1=   /2=;raw=Yes;get2=Yes/n=1/1=   /2=');
        Observer.Expect('empty', 'add=added;get=Yes/n=0/1=/2=;raw=Yes;get2=Yes/n=0/1=/2=');
        Observer.Expect('tab', 'add=added;get=Yes/n=1/1=a\tb/2=;raw=Yes;get2=Yes/n=1/1=a\tb/2=');
        Observer.Verify();
    end;

    [Test]
    procedure SpecialValues_ResponseHeaders_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Special(Observer, 4, 12, 17);
        Observer.Expect('innerSpaces', 'add=added;get=Yes/n=1/1=a   b/2=;raw=Yes;get2=Yes/n=1/1=a   b/2=');
        Observer.Expect('comma', 'add=added;get=Yes/n=1/1=a,b/2=;raw=Yes;get2=Yes/n=1/1=a,b/2=');
        Observer.Expect('commaSpaces', 'add=added;get=Yes/n=1/1=a, b ,c/2=;raw=Yes;get2=Yes/n=1/1=a, b ,c/2=');
        Observer.Expect('quoted', 'add=added;get=Yes/n=1/1="quoted"/2=;raw=Yes;get2=Yes/n=1/1="quoted"/2=');
        Observer.Expect('quotedComma', 'add=added;get=Yes/n=1/1="a,b"/2=;raw=Yes;get2=Yes/n=1/1="a,b"/2=');
        Observer.Expect('unbalancedQuote', 'add=added;get=Yes/n=1/1="abc/2=;raw=Yes;get2=Yes/n=1/1="abc/2=');
        Observer.Verify();
    end;

    [Test]
    procedure SpecialValues_ResponseHeaders_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Special(Observer, 4, 18, 23);
        Observer.Expect('semicolon', 'add=added;get=Yes/n=1/1=a;b=c/2=;raw=Yes;get2=Yes/n=1/1=a;b=c/2=');
        Observer.Expect('unicode', 'add=added;get=Yes/n=1/1=äö€/2=;raw=Yes;get2=Yes/n=1/1=äö€/2=');
        Observer.Expect('colon', 'add=added;get=Yes/n=1/1=a:b/2=;raw=Yes;get2=Yes/n=1/1=a:b/2=');
        Observer.Expect('digitZero', 'add=added;get=Yes/n=1/1=a0b/2=;raw=Yes;get2=Yes/n=1/1=a0b/2=');
        Observer.Verify();
    end;

    [Test]
    procedure KnownHeaderLists_Request_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('accept2', Line(1, 'Accept', 'text/html, application/json;q=0.9'));
        Observer.Observe('acceptComma', Line(1, 'Accept', 'text/html,application/json'));
        Observer.Observe('acceptStar', Line(1, 'Accept', '*/*'));
        Observer.Observe('acceptSpaces', Line(1, 'Accept', '  text/html  '));
        Observer.Observe('cache2', Line(1, 'Cache-Control', 'no-cache, no-store'));
        Observer.Observe('cacheMaxAge', Line(1, 'Cache-Control', 'max-age=60'));
        Observer.Expect('accept2', 'add=added;get=Yes/n=2/1=text/html/2=application/json; q=0.9;raw=Yes;get2=Yes/n=2/1=text/html/2=application/json; q=0.9');
        Observer.Expect('acceptComma', 'add=added;get=Yes/n=2/1=text/html/2=application/json;raw=Yes;get2=Yes/n=2/1=text/html/2=application/json');
        Observer.Expect('acceptStar', 'add=added;get=Yes/n=1/1=*/*/2=;raw=Yes;get2=Yes/n=1/1=*/*/2=');
        Observer.Expect('acceptSpaces', 'add=added;get=Yes/n=1/1=text/html/2=;raw=Yes;get2=Yes/n=1/1=text/html/2=');
        Observer.Expect('cache2', 'add=added;get=Yes/n=1/1=no-store, no-cache/2=;raw=Yes;get2=Yes/n=1/1=no-store, no-cache/2=');
        Observer.Expect('cacheMaxAge', 'add=added;get=Yes/n=1/1=max-age=60/2=;raw=Yes;get2=Yes/n=1/1=max-age=60/2=');
        Observer.Verify();
    end;

    [Test]
    procedure KnownHeaderLists_Request_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('cacheBad', Line(1, 'Cache-Control', 'no cache'));
        Observer.Observe('acceptEnc2', Line(1, 'Accept-Encoding', 'gzip, deflate'));
        Observer.Observe('acceptEncQ', Line(1, 'Accept-Encoding', 'gzip;q=0.5'));
        Observer.Observe('ifMatch2', Line(1, 'If-Match', '"a", "b"'));
        Observer.Observe('ifMatchStar', Line(1, 'If-Match', '*'));
        Observer.Observe('ifMatchUnquoted', Line(1, 'If-Match', 'abc'));
        Observer.Expect('cacheBad', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=No/n=0/1=/2=;raw=Yes;get2=Yes/n=1/1=no cache/2=');
        Observer.Expect('acceptEnc2', 'add=added;get=Yes/n=2/1=gzip/2=deflate;raw=Yes;get2=Yes/n=2/1=gzip/2=deflate');
        Observer.Expect('acceptEncQ', 'add=added;get=Yes/n=1/1=gzip; q=0.5/2=;raw=Yes;get2=Yes/n=1/1=gzip; q=0.5/2=');
        Observer.Expect('ifMatch2', 'add=added;get=Yes/n=2/1="a"/2="b";raw=Yes;get2=Yes/n=2/1="a"/2="b"');
        Observer.Expect('ifMatchStar', 'add=added;get=Yes/n=1/1=*/2=;raw=Yes;get2=Yes/n=1/1=*/2=');
        Observer.Expect('ifMatchUnquoted', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=No/n=0/1=/2=;raw=Yes;get2=Yes/n=1/1=abc/2=');
        Observer.Verify();
    end;

    [Test]
    procedure KnownHeaderLists_Request_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('ifNoneMatchWeak', Line(1, 'If-None-Match', 'W/"abc"'));
        Observer.Observe('ua', Line(1, 'User-Agent', 'A/1 (comment) B/2'));
        Observer.Observe('uaBad', Line(1, 'User-Agent', '(((('));
        Observer.Observe('authBasic', Line(1, 'Authorization', 'Basic  abc'));
        Observer.Observe('authNoScheme', Line(1, 'Authorization', 'abc'));
        Observer.Observe('authBearerSpaces', Line(1, 'Authorization', '  Bearer abc  '));
        Observer.Expect('ifNoneMatchWeak', 'add=added;get=Yes/n=1/1=W/"abc"/2=;raw=Yes;get2=Yes/n=1/1=W/"abc"/2=');
        Observer.Expect('ua', 'add=added;get=Yes/n=3/1=A/1/2=(comment);raw=Yes;get2=Yes/n=3/1=A/1/2=(comment)');
        Observer.Expect('uaBad', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=No/n=0/1=/2=;raw=Yes;get2=Yes/n=1/1=((((/2=');
        Observer.Expect('authBasic', 'add=added;get=Yes/n=1/1=Basic abc/2=;raw=Yes;get2=Yes/n=1/1=Basic abc/2=');
        Observer.Expect('authNoScheme', 'add=added;get=Yes/n=1/1=abc/2=;raw=Yes;get2=Yes/n=1/1=abc/2=');
        Observer.Expect('authBearerSpaces', 'add=added;get=Yes/n=1/1=Bearer abc/2=;raw=Yes;get2=Yes/n=1/1=Bearer abc/2=');
        Observer.Verify();
    end;

    [Test]
    procedure KnownHeaderLists_Request_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('connection2', Line(1, 'Connection', 'close, keep-alive'));
        Observer.Observe('range', Line(1, 'Range', 'bytes=0-9, 20-29'));
        Observer.Observe('rangeBad', Line(1, 'Range', 'bytes'));
        Observer.Observe('hostPort', Line(1, 'Host', 'a.example:8080'));
        Observer.Observe('hostBad', Line(1, 'Host', 'a b'));
        Observer.Observe('te', Line(1, 'Transfer-Encoding', 'chunked'));
        Observer.Expect('connection2', 'add=added;get=Yes/n=2/1=close/2=keep-alive;raw=Yes;get2=Yes/n=2/1=close/2=keep-alive');
        Observer.Expect('range', 'add=added;get=Yes/n=1/1=bytes=0-9, 20-29/2=;raw=Yes;get2=Yes/n=1/1=bytes=0-9, 20-29/2=');
        Observer.Expect('rangeBad', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=No/n=0/1=/2=;raw=Yes;get2=Yes/n=1/1=bytes/2=');
        Observer.Expect('hostPort', 'add=added;get=Yes/n=1/1=a.example:8080/2=;raw=Yes;get2=Yes/n=1/1=a.example:8080/2=');
        Observer.Expect('hostBad', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=No/n=0/1=/2=;raw=Yes;get2=Yes/n=1/1=a b/2=');
        Observer.Expect('te', 'add=added;get=Yes/n=1/1=chunked/2=;raw=Yes;get2=Yes/n=1/1=chunked/2=');
        Observer.Verify();
    end;

    [Test]
    procedure KnownHeaderLists_Content_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('type', Line(3, 'Content-Type', 'text/plain'));
        Observer.Observe('typeCharset', Line(3, 'Content-Type', 'text/plain; charset=utf-8'));
        Observer.Observe('typeNoSpace', Line(3, 'Content-Type', 'text/plain;charset=UTF-8'));
        Observer.Observe('typeUpper', Line(3, 'Content-Type', 'TEXT/PLAIN'));
        Observer.Observe('typeBoundary', Line(3, 'Content-Type', 'multipart/form-data; boundary="a b"'));
        Observer.Observe('typeNoSlash', Line(3, 'Content-Type', 'text'));
        Observer.Expect('type', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=Yes/n=1/1=text/plain; charset=utf-8/2=;raw=Yes;get2=Yes/n=2/1=text/plain; charset=utf-8/2=text/plain');
        Observer.Expect('typeCharset', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=Yes/n=1/1=text/plain; charset=utf-8/2=;raw=Yes;get2=Yes/n=2/1=text/plain; charset=utf-8/2=text/plain; charset=utf-8');
        Observer.Expect('typeNoSpace', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=Yes/n=1/1=text/plain; charset=utf-8/2=;raw=Yes;get2=Yes/n=2/1=text/plain; charset=utf-8/2=text/plain;charset=UTF-8');
        Observer.Expect('typeUpper', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=Yes/n=1/1=text/plain; charset=utf-8/2=;raw=Yes;get2=Yes/n=2/1=text/plain; charset=utf-8/2=TEXT/PLAIN');
        Observer.Expect('typeBoundary', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=Yes/n=1/1=text/plain; charset=utf-8/2=;raw=Yes;get2=Yes/n=2/1=text/plain; charset=utf-8/2=multipart/form-data; boundary="a b"');
        Observer.Expect('typeNoSlash', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=Yes/n=1/1=text/plain; charset=utf-8/2=;raw=Yes;get2=Yes/n=2/1=text/plain; charset=utf-8/2=text');
        Observer.Verify();
    end;

    [Test]
    procedure KnownHeaderLists_Content_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('typeSpaces', Line(3, 'Content-Type', '  text/plain  '));
        Observer.Observe('typeBadCharset', Line(3, 'Content-Type', 'text/plain; charset=nonsense'));
        Observer.Observe('typeTwo', Line(3, 'Content-Type', 'text/plain, text/html'));
        Observer.Observe('encoding2', Line(3, 'Content-Encoding', 'gzip, deflate'));
        Observer.Observe('encodingBad', Line(3, 'Content-Encoding', 'gzip deflate'));
        Observer.Observe('language2', Line(3, 'Content-Language', 'en, de'));
        Observer.Expect('typeSpaces', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=Yes/n=1/1=text/plain; charset=utf-8/2=;raw=Yes;get2=Yes/n=2/1=text/plain; charset=utf-8/2=  text/plain  ');
        Observer.Expect('typeBadCharset', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=Yes/n=1/1=text/plain; charset=utf-8/2=;raw=Yes;get2=Yes/n=2/1=text/plain; charset=utf-8/2=text/plain; charset=nonsense');
        Observer.Expect('typeTwo', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=Yes/n=1/1=text/plain; charset=utf-8/2=;raw=Yes;get2=Yes/n=2/1=text/plain; charset=utf-8/2=text/plain, text/html');
        Observer.Expect('encoding2', 'add=added;get=Yes/n=2/1=gzip/2=deflate;raw=Yes;get2=Yes/n=2/1=gzip/2=deflate');
        Observer.Expect('encodingBad', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=No/n=0/1=/2=;raw=Yes;get2=Yes/n=1/1=gzip deflate/2=');
        Observer.Expect('language2', 'add=added;get=Yes/n=2/1=en/2=de;raw=Yes;get2=Yes/n=2/1=en/2=de');
        Observer.Verify();
    end;

    [Test]
    procedure KnownHeaderLists_Content_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('languageBad', Line(3, 'Content-Language', 'en_US'));
        Observer.Observe('disp', Line(3, 'Content-Disposition', 'attachment; filename="a.txt"'));
        Observer.Observe('dispInline', Line(3, 'Content-Disposition', 'inline'));
        Observer.Observe('dispBad', Line(3, 'Content-Disposition', ';;'));
        Observer.Observe('expires', Line(3, 'Expires', 'Tue, 15 Nov 1994 08:12:31 GMT'));
        Observer.Observe('expiresBad', Line(3, 'Expires', 'tomorrow'));
        Observer.Expect('languageBad', 'add=added;get=Yes/n=1/1=en_US/2=;raw=Yes;get2=Yes/n=1/1=en_US/2=');
        Observer.Expect('disp', 'add=added;get=Yes/n=1/1=attachment; filename="a.txt"/2=;raw=Yes;get2=Yes/n=1/1=attachment; filename="a.txt"/2=');
        Observer.Expect('dispInline', 'add=added;get=Yes/n=1/1=inline/2=;raw=Yes;get2=Yes/n=1/1=inline/2=');
        Observer.Expect('dispBad', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=No/n=0/1=/2=;raw=Yes;get2=Yes/n=1/1=;;/2=');
        Observer.Expect('expires', 'add=added;get=Yes/n=1/1=Tue, 15 Nov 1994 08:12:31 GMT/2=;raw=Yes;get2=Yes/n=1/1=Tue, 15 Nov 1994 08:12:31 GMT/2=');
        Observer.Expect('expiresBad', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=No/n=0/1=/2=;raw=Yes;get2=Yes/n=1/1=tomorrow/2=');
        Observer.Verify();
    end;

    [Test]
    procedure KnownHeaderLists_Content_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('expiresZero', Line(3, 'Expires', '0'));
        Observer.Observe('lastMod', Line(3, 'Last-Modified', 'Tue, 15 Nov 1994 08:12:31 GMT'));
        Observer.Observe('lastModBad', Line(3, 'Last-Modified', '2020-01-01'));
        Observer.Observe('length', Line(3, 'Content-Length', '5'));
        Observer.Observe('lengthBad', Line(3, 'Content-Length', 'five'));
        Observer.Observe('lengthNeg', Line(3, 'Content-Length', '-1'));
        Observer.Expect('expiresZero', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=No/n=0/1=/2=;raw=Yes;get2=Yes/n=1/1=0/2=');
        Observer.Expect('lastMod', 'add=added;get=Yes/n=1/1=Tue, 15 Nov 1994 08:12:31 GMT/2=;raw=Yes;get2=Yes/n=1/1=Tue, 15 Nov 1994 08:12:31 GMT/2=');
        Observer.Expect('lastModBad', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=No/n=0/1=/2=;raw=Yes;get2=Yes/n=1/1=2020-01-01/2=');
        Observer.Expect('length', 'add=added;get=Yes/n=1/1=5/2=;raw=Yes;get2=Yes/n=1/1=5/2=');
        Observer.Expect('lengthBad', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=No/n=0/1=/2=;raw=Yes;get2=Yes/n=1/1=five/2=');
        Observer.Expect('lengthNeg', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=No/n=0/1=/2=;raw=Yes;get2=Yes/n=1/1=-1/2=');
        Observer.Verify();
    end;

    // Corpus issue #671 (odd AL behavior leads, part F) item 28: a Date header in ISO 8601 form and in RFC 1123 form, on every header collection.
    [Test]
    procedure DateHeader_Iso8601_AllKinds()
    var
        Observer: Codeunit "Probe Observer";
        Kind: Integer;
    begin
        for Kind := 1 to 5 do begin
            Observer.Observe('iso' + Format(Kind), Line(Kind, 'Date', '2020-07-14T08:17:00Z'));
            Observer.Observe('rfc' + Format(Kind), Line(Kind, 'Date', 'Tue, 14 Jul 2020 08:17:00 GMT'));
        end;
        Observer.Expect('iso1', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=No/n=0/1=/2=;raw=Yes;get2=Yes/n=1/1=2020-07-14T08:17:00Z/2=');
        Observer.Expect('rfc1', 'add=added;get=Yes/n=1/1=Tue, 14 Jul 2020 08:17:00 GMT/2=;raw=Yes;get2=Yes/n=1/1=Tue, 14 Jul 2020 08:17:00 GMT/2=');
        Observer.Expect('iso2', 'add=E[The requested operation cannot be perfor|InvalidOperation];get=No/n=0/1=/2=;raw=No;get2=No/n=0/1=/2=');
        Observer.Expect('rfc2', 'add=E[The requested operation cannot be perfor|InvalidOperation];get=No/n=0/1=/2=;raw=No;get2=No/n=0/1=/2=');
        Observer.Expect('iso3', 'add=E[The requested operation cannot be perfor|InvalidOperation];get=No/n=0/1=/2=;raw=No;get2=No/n=0/1=/2=');
        Observer.Expect('rfc3', 'add=E[The requested operation cannot be perfor|InvalidOperation];get=No/n=0/1=/2=;raw=No;get2=No/n=0/1=/2=');
        Observer.Expect('iso4', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=No/n=0/1=/2=;raw=Yes;get2=Yes/n=1/1=2020-07-14T08:17:00Z/2=');
        Observer.Expect('rfc4', 'add=added;get=Yes/n=1/1=Tue, 14 Jul 2020 08:17:00 GMT/2=;raw=Yes;get2=Yes/n=1/1=Tue, 14 Jul 2020 08:17:00 GMT/2=');
        Observer.Expect('iso5', 'add=E[The requested operation cannot be perfor|InvalidOperation];get=No/n=0/1=/2=;raw=No;get2=No/n=0/1=/2=');
        Observer.Expect('rfc5', 'add=E[The requested operation cannot be perfor|InvalidOperation];get=No/n=0/1=/2=;raw=No;get2=No/n=0/1=/2=');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryAddFull(var H: HttpHeaders; N: Text; V: Text)
    begin
        H.Add(N, V);
    end;

    // Corpus issue #671 item 29: an Authorization value with a colon and no scheme, full error text and code.
    [Test]
    procedure Authorization_ValueWithColon()
    var
        Observer: Codeunit "Probe Observer";
        H: HttpHeaders;
    begin
        Observer.Observe('lower', Line(1, 'authorization', '1:e6c6699e-aa52-4cdc-b493-7f097fa53a9f'));
        Observer.Observe('upper', Line(1, 'Authorization', '1:e6c6699e-aa52-4cdc-b493-7f097fa53a9f'));
        Observer.Observe('schemeColon', Line(1, 'Authorization', 'Token 1:e6c6699e'));
        Observer.Observe('colonOnly', Line(1, 'Authorization', ':'));
        Helper.GetH(1, H);
        ClearLastError();
        if TryAddFull(H, 'authorization', '1:e6c6699e-aa52-4cdc-b493-7f097fa53a9f') then
            Observer.Observe('full', 'added')
        else
            Observer.ObserveError('full');
        Observer.Expect('lower', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=No/n=0/1=/2=;raw=Yes;get2=Yes/n=1/1=1:e6c6699e-aa52-4cdc-b493-7f097fa53a9f/2=');
        Observer.Expect('upper', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=No/n=0/1=/2=;raw=Yes;get2=Yes/n=1/1=1:e6c6699e-aa52-4cdc-b493-7f097fa53a9f/2=');
        Observer.Expect('schemeColon', 'add=added;get=Yes/n=1/1=Token 1:e6c6699e/2=;raw=Yes;get2=Yes/n=1/1=Token 1:e6c6699e/2=');
        Observer.Expect('colonOnly', 'add=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=No/n=0/1=/2=;raw=Yes;get2=Yes/n=1/1=:/2=');
        Observer.Expect('full|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('full|code', 'InvalidHeader:Format');
        Observer.Verify();
    end;
}
