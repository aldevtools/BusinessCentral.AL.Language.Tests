// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpheaders/httpheaders-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), LT P87 Helper (codeunit 74228)
// Probe: written against BC 29 (runtime 16); every value is observed through Probe Observer and measured later on real BC 29. No request is ever sent.
// Facts: a header added twice (same value, different value, different case), GetValues count, Keys count
// BC versions: 29

codeunit 74224 "LT P87 Header Twice"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT P87 Helper";

    local procedure Twice(Kind: Integer; N: Text; V1: Text; V2: Text): Text
    var
        H: HttpHeaders;
        Res: Text;
    begin
        Helper.GetH(Kind, H);
        Res := 'a1=' + Helper.DoAdd(H, N, V1);
        Res += ';a2=' + Helper.DoAdd(H, N, V2);
        Res += ';get=' + Helper.DoGet(H, N);
        Res += ';keys=' + Helper.Keys(H);
        Res += ';raw=' + Helper.DoRaw(H, N, V1);
        Res += ';get2=' + Helper.DoGet(H, N);
        Res += ';rm=' + Helper.DoRemove(H, N);
        Res += ';has=' + Helper.DoContains(H, N);
        exit(Res);
    end;

    [Test]
    procedure Twice_RequestHeaders_Custom()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('customSame', Twice(1, 'X-Custom', 'a', 'a'));
        Observer.Observe('customDiff', Twice(1, 'X-Custom', 'a', 'b'));
        Observer.Observe('customCase', Twice(1, 'X-Custom', 'a', 'A'));
        Observer.Observe('customEmpty', Twice(1, 'X-Custom', '', ''));
        Observer.Observe('customComma', Twice(1, 'X-Custom', 'a,b', 'c'));
        Observer.Expect('customSame', 'a1=added;a2=added;get=Yes/n=2/1=a/2=a;keys=1:X-Custom,;raw=Yes;get2=Yes/n=3/1=a/2=a;rm=Yes;has=No');
        Observer.Expect('customDiff', 'a1=added;a2=added;get=Yes/n=2/1=a/2=b;keys=1:X-Custom,;raw=Yes;get2=Yes/n=3/1=a/2=b;rm=Yes;has=No');
        Observer.Expect('customCase', 'a1=added;a2=added;get=Yes/n=2/1=a/2=A;keys=1:X-Custom,;raw=Yes;get2=Yes/n=3/1=a/2=A;rm=Yes;has=No');
        Observer.Expect('customEmpty', 'a1=added;a2=added;get=Yes/n=0/1=/2=;keys=1:X-Custom,;raw=Yes;get2=Yes/n=0/1=/2=;rm=Yes;has=No');
        Observer.Expect('customComma', 'a1=added;a2=added;get=Yes/n=2/1=a,b/2=c;keys=1:X-Custom,;raw=Yes;get2=Yes/n=3/1=a,b/2=c;rm=Yes;has=No');
        Observer.Verify();
    end;

    [Test]
    procedure Twice_RequestHeaders_Known_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('accept', Twice(1, 'Accept', 'text/html', 'application/json'));
        Observer.Observe('acceptSame', Twice(1, 'Accept', 'text/html', 'text/html'));
        Observer.Observe('cache', Twice(1, 'Cache-Control', 'no-cache', 'no-store'));
        Observer.Observe('acceptEnc', Twice(1, 'Accept-Encoding', 'gzip', 'deflate'));
        Observer.Observe('ifMatch', Twice(1, 'If-Match', '"a"', '"b"'));
        Observer.Observe('ifNoneMatch', Twice(1, 'If-None-Match', '"a"', '"b"'));
        Observer.Expect('accept', 'a1=added;a2=added;get=Yes/n=2/1=text/html/2=application/json;keys=1:Accept,;raw=Yes;get2=Yes/n=3/1=text/html/2=application/json;rm=Yes;has=No');
        Observer.Expect('acceptSame', 'a1=added;a2=added;get=Yes/n=2/1=text/html/2=text/html;keys=1:Accept,;raw=Yes;get2=Yes/n=3/1=text/html/2=text/html;rm=Yes;has=No');
        Observer.Expect('cache', 'a1=added;a2=added;get=Yes/n=1/1=no-store, no-cache/2=;keys=1:Cache-Control,;raw=Yes;get2=Yes/n=1/1=no-store, no-cache/2=;rm=Yes;has=No');
        Observer.Expect('acceptEnc', 'a1=added;a2=added;get=Yes/n=2/1=gzip/2=deflate;keys=1:Accept-Encoding,;raw=Yes;get2=Yes/n=3/1=gzip/2=deflate;rm=Yes;has=No');
        Observer.Expect('ifMatch', 'a1=added;a2=added;get=Yes/n=2/1="a"/2="b";keys=1:If-Match,;raw=Yes;get2=Yes/n=3/1="a"/2="b";rm=Yes;has=No');
        Observer.Expect('ifNoneMatch', 'a1=added;a2=added;get=Yes/n=2/1="a"/2="b";keys=1:If-None-Match,;raw=Yes;get2=Yes/n=3/1="a"/2="b";rm=Yes;has=No');
        Observer.Verify();
    end;

    [Test]
    procedure Twice_RequestHeaders_Known_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('range', Twice(1, 'Range', 'bytes=0-9', 'bytes=10-19'));
        Observer.Observe('userAgent', Twice(1, 'User-Agent', 'A/1', 'B/2'));
        Observer.Observe('auth', Twice(1, 'Authorization', 'Bearer a', 'Bearer b'));
        Observer.Observe('host', Twice(1, 'Host', 'a.example', 'b.example'));
        Observer.Observe('connection', Twice(1, 'Connection', 'close', 'keep-alive'));
        Observer.Observe('transferEnc', Twice(1, 'Transfer-Encoding', 'chunked', 'gzip'));
        Observer.Expect('range', 'a1=added;a2=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=Yes/n=1/1=bytes=0-9/2=;keys=1:Range,;raw=Yes;get2=Yes/n=2/1=bytes=0-9/2=bytes=0-9;rm=Yes;has=No');
        Observer.Expect('userAgent', 'a1=added;a2=added;get=Yes/n=2/1=A/1/2=B/2;keys=1:User-Agent,;raw=Yes;get2=Yes/n=3/1=A/1/2=B/2;rm=Yes;has=No');
        Observer.Expect('auth', 'a1=added;a2=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=Yes/n=1/1=Bearer a/2=;keys=1:Authorization,;raw=Yes;get2=Yes/n=2/1=Bearer a/2=Bearer a;rm=Yes;has=No');
        Observer.Expect('host', 'a1=added;a2=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=Yes/n=1/1=a.example/2=;keys=1:Host,;raw=Yes;get2=Yes/n=2/1=a.example/2=a.example;rm=Yes;has=No');
        Observer.Expect('connection', 'a1=added;a2=added;get=Yes/n=2/1=close/2=keep-alive;keys=1:Connection,;raw=Yes;get2=Yes/n=3/1=close/2=keep-alive;rm=Yes;has=No');
        Observer.Expect('transferEnc', 'a1=added;a2=added;get=Yes/n=2/1=chunked/2=gzip;keys=1:Transfer-Encoding,;raw=Yes;get2=Yes/n=3/1=chunked/2=gzip;rm=Yes;has=No');
        Observer.Verify();
    end;

    [Test]
    procedure Twice_RequestHeaders_Known_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('expires', Twice(1, 'Expires', 'Tue, 15 Nov 1994 08:12:31 GMT', 'Tue, 15 Nov 1994 08:12:32 GMT'));
        Observer.Expect('expires', 'a1=E[The requested operation cannot be perfor|InvalidOperation];a2=E[The requested operation cannot be perfor|InvalidOperation];get=No/n=0/1=/2=;keys=0:;raw=No;get2=No/n=0/1=/2=;rm=No;has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Verify();
    end;

    [Test]
    procedure Twice_ContentHeaders_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('type', Twice(3, 'Content-Type', 'text/plain', 'text/html'));
        Observer.Observe('typeSame', Twice(3, 'Content-Type', 'text/plain', 'text/plain'));
        Observer.Observe('encoding', Twice(3, 'Content-Encoding', 'gzip', 'deflate'));
        Observer.Observe('language', Twice(3, 'Content-Language', 'en', 'de'));
        Observer.Observe('disposition', Twice(3, 'Content-Disposition', 'inline', 'attachment'));
        Observer.Observe('length', Twice(3, 'Content-Length', '5', '6'));
        Observer.Expect('type', 'a1=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];a2=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=Yes/n=1/1=text/plain; charset=utf-8/2=;keys=1:Content-Type,;raw=Yes;get2=Yes/n=2/1=text/plain; charset=utf-8/2=text/plain;rm=Yes;has=No');
        Observer.Expect('typeSame', 'a1=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];a2=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=Yes/n=1/1=text/plain; charset=utf-8/2=;keys=1:Content-Type,;raw=Yes;get2=Yes/n=2/1=text/plain; charset=utf-8/2=text/plain;rm=Yes;has=No');
        Observer.Expect('encoding', 'a1=added;a2=added;get=Yes/n=2/1=gzip/2=deflate;keys=2:Content-Type,Content-Encoding,;raw=Yes;get2=Yes/n=3/1=gzip/2=deflate;rm=Yes;has=No');
        Observer.Expect('language', 'a1=added;a2=added;get=Yes/n=2/1=en/2=de;keys=2:Content-Type,Content-Language,;raw=Yes;get2=Yes/n=3/1=en/2=de;rm=Yes;has=No');
        Observer.Expect('disposition', 'a1=added;a2=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=Yes/n=1/1=inline/2=;keys=2:Content-Type,Content-Disposition,;raw=Yes;get2=Yes/n=2/1=inline/2=inline;rm=Yes;has=No');
        Observer.Expect('length', 'a1=added;a2=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=Yes/n=1/1=5/2=;keys=2:Content-Type,Content-Length,;raw=Yes;get2=Yes/n=2/1=5/2=5;rm=Yes;has=No');
        Observer.Verify();
    end;

    [Test]
    procedure Twice_ContentHeaders_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('expires', Twice(3, 'Expires', 'Tue, 15 Nov 1994 08:12:31 GMT', 'Tue, 15 Nov 1994 08:12:32 GMT'));
        Observer.Observe('lastModified', Twice(3, 'Last-Modified', 'Tue, 15 Nov 1994 08:12:31 GMT', 'Tue, 15 Nov 1994 08:12:32 GMT'));
        Observer.Observe('custom', Twice(3, 'X-Custom', 'a', 'b'));
        Observer.Expect('expires', 'a1=added;a2=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=Yes/n=1/1=Tue, 15 Nov 1994 08:12:31 GMT/2=;keys=2:Content-Type,Expires,;raw=Yes;get2=Yes/n=2/1=Tue, 15 Nov 1994 08:12:31 GMT/2=Tue, 15 Nov 1994 08:12:31 GMT;rm=Yes;has=No');
        Observer.Expect('lastModified', 'a1=added;a2=E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format];get=Yes/n=1/1=Tue, 15 Nov 1994 08:12:31 GMT/2=;keys=2:Content-Type,Last-Modified,;raw=Yes;get2=Yes/n=2/1=Tue, 15 Nov 1994 08:12:31 GMT/2=Tue, 15 Nov 1994 08:12:31 GMT;rm=Yes;has=No');
        Observer.Expect('custom', 'a1=added;a2=added;get=Yes/n=2/1=a/2=b;keys=2:Content-Type,X-Custom,;raw=Yes;get2=Yes/n=3/1=a/2=b;rm=Yes;has=No');
        Observer.Verify();
    end;

    [Test]
    procedure Twice_ResponseHeaders()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('custom', Twice(4, 'X-Custom', 'a', 'b'));
        Observer.Observe('customSame', Twice(4, 'X-Custom', 'a', 'a'));
        Observer.Observe('cache', Twice(4, 'Cache-Control', 'no-cache', 'no-store'));
        Observer.Observe('connection', Twice(4, 'Connection', 'close', 'keep-alive'));
        Observer.Observe('type', Twice(4, 'Content-Type', 'text/plain', 'text/html'));
        Observer.Observe('expires', Twice(4, 'Expires', 'Tue, 15 Nov 1994 08:12:31 GMT', 'Tue, 15 Nov 1994 08:12:32 GMT'));
        Observer.Expect('custom', 'a1=added;a2=added;get=Yes/n=2/1=a/2=b;keys=1:X-Custom,;raw=Yes;get2=Yes/n=3/1=a/2=b;rm=Yes;has=No');
        Observer.Expect('customSame', 'a1=added;a2=added;get=Yes/n=2/1=a/2=a;keys=1:X-Custom,;raw=Yes;get2=Yes/n=3/1=a/2=a;rm=Yes;has=No');
        Observer.Expect('cache', 'a1=added;a2=added;get=Yes/n=1/1=no-store, no-cache/2=;keys=1:Cache-Control,;raw=Yes;get2=Yes/n=1/1=no-store, no-cache/2=;rm=Yes;has=No');
        Observer.Expect('connection', 'a1=added;a2=added;get=Yes/n=2/1=close/2=keep-alive;keys=1:Connection,;raw=Yes;get2=Yes/n=3/1=close/2=keep-alive;rm=Yes;has=No');
        Observer.Expect('type', 'a1=E[The requested operation cannot be perfor|InvalidOperation];a2=E[The requested operation cannot be perfor|InvalidOperation];get=No/n=0/1=/2=;keys=0:;raw=No;get2=No/n=0/1=/2=;rm=No;has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Expect('expires', 'a1=E[The requested operation cannot be perfor|InvalidOperation];a2=E[The requested operation cannot be perfor|InvalidOperation];get=No/n=0/1=/2=;keys=0:;raw=No;get2=No/n=0/1=/2=;rm=No;has=E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Verify();
    end;

    [Test]
    procedure NameCaseAndKeys()
    var
        Observer: Codeunit "Probe Observer";
        H: HttpHeaders;
    begin
        Helper.GetH(1, H);
        Observer.Observe('add1', Helper.DoAdd(H, 'X-Custom', 'a'));
        Observer.Observe('add2', Helper.DoAdd(H, 'x-custom', 'b'));
        Observer.Observe('add3', Helper.DoAdd(H, 'X-CUSTOM', 'c'));
        Observer.Observe('keys', Helper.Keys(H));
        Observer.Observe('get', Helper.DoGet(H, 'X-Custom'));
        Observer.Observe('addAccept', Helper.DoAdd(H, 'accept', 'text/html'));
        Observer.Observe('addAccept2', Helper.DoAdd(H, 'ACCEPT', 'text/plain'));
        Observer.Observe('keys2', Helper.Keys(H));
        Observer.Observe('getAccept', Helper.DoGet(H, 'Accept'));
        Observer.Observe('rm', Helper.DoRemove(H, 'x-CUSTOM'));
        Observer.Observe('keys3', Helper.Keys(H));
        Observer.Expect('add1', 'added');
        Observer.Expect('add2', 'added');
        Observer.Expect('add3', 'added');
        Observer.Expect('keys', '1:X-Custom,');
        Observer.Expect('get', 'Yes/n=3/1=a/2=b');
        Observer.Expect('addAccept', 'added');
        Observer.Expect('addAccept2', 'added');
        Observer.Expect('keys2', '2:X-Custom,Accept,');
        Observer.Expect('getAccept', 'Yes/n=2/1=text/html/2=text/plain');
        Observer.Expect('rm', 'Yes');
        Observer.Expect('keys3', '1:Accept,');
        Observer.Verify();
    end;
}
