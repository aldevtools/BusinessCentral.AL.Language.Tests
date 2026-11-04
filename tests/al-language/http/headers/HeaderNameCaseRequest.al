// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpheaders/httpheaders-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), LT Hdr198 Helper (codeunit 72959)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Stored case of known header names added in lower case to request headers; Keys, Contains and GetValues in another case
// BC versions: 29 (27 and 28 by CI)

codeunit 72960 "LT Hdr198 Name Request"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT Hdr198 Helper";

    local procedure Run(var Observer: Codeunit "Probe Observer"; From: Integer; UpTo: Integer)
    var
        Names: List of [Text];
        i: Integer;
    begin
        Helper.KnownNames(Names);
        for i := From to UpTo do
            Observer.Observe(Names.Get(i), Helper.ObservationFor(1, Names.Get(i)));
    end;

    [Test]
    procedure P198_LowerNames_1_To_20()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1, 20);
        Observer.Expect('accept-charset', 'add=ok;keys=1:Accept-Charset,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/utf-8');
        Observer.Expect('accept-encoding', 'add=ok;keys=1:Accept-Encoding,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/gzip');
        Observer.Expect('accept-language', 'add=ok;keys=1:Accept-Language,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/en');
        Observer.Expect('allow', 'add=E[The requested operation cannot be perfor];keys=0:;hasLow=E[Invalid HTTP header. Please, make sure t];hasUp=E[Invalid HTTP header. Please, make sure t];hasMix=E[Invalid HTTP header. Please, make sure t];get=No/');
        Observer.Expect('authorization', 'add=ok;keys=1:Authorization,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/Basic abc');
        Observer.Expect('cache-control', 'add=ok;keys=1:Cache-Control,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/no-cache');
        Observer.Expect('connection', 'add=ok;keys=1:Connection,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/close');
        Observer.Expect('content-disposition', 'add=E[The requested operation cannot be perfor];keys=0:;hasLow=E[Invalid HTTP header. Please, make sure t];hasUp=E[Invalid HTTP header. Please, make sure t];hasMix=E[Invalid HTTP header. Please, make sure t];get=No/');
        Observer.Expect('content-encoding', 'add=E[The requested operation cannot be perfor];keys=0:;hasLow=E[Invalid HTTP header. Please, make sure t];hasUp=E[Invalid HTTP header. Please, make sure t];hasMix=E[Invalid HTTP header. Please, make sure t];get=No/');
        Observer.Expect('content-language', 'add=E[The requested operation cannot be perfor];keys=0:;hasLow=E[Invalid HTTP header. Please, make sure t];hasUp=E[Invalid HTTP header. Please, make sure t];hasMix=E[Invalid HTTP header. Please, make sure t];get=No/');
        Observer.Expect('content-length', 'add=E[The requested operation cannot be perfor];keys=0:;hasLow=E[Invalid HTTP header. Please, make sure t];hasUp=E[Invalid HTTP header. Please, make sure t];hasMix=E[Invalid HTTP header. Please, make sure t];get=No/');
        Observer.Expect('content-location', 'add=E[The requested operation cannot be perfor];keys=0:;hasLow=E[Invalid HTTP header. Please, make sure t];hasUp=E[Invalid HTTP header. Please, make sure t];hasMix=E[Invalid HTTP header. Please, make sure t];get=No/');
        Observer.Expect('content-md5', 'add=E[The requested operation cannot be perfor];keys=0:;hasLow=E[Invalid HTTP header. Please, make sure t];hasUp=E[Invalid HTTP header. Please, make sure t];hasMix=E[Invalid HTTP header. Please, make sure t];get=No/');
        Observer.Expect('content-range', 'add=E[The requested operation cannot be perfor];keys=0:;hasLow=E[Invalid HTTP header. Please, make sure t];hasUp=E[Invalid HTTP header. Please, make sure t];hasMix=E[Invalid HTTP header. Please, make sure t];get=No/');
        Observer.Expect('content-type', 'add=E[The requested operation cannot be perfor];keys=0:;hasLow=E[Invalid HTTP header. Please, make sure t];hasUp=E[Invalid HTTP header. Please, make sure t];hasMix=E[Invalid HTTP header. Please, make sure t];get=No/');
        Observer.Expect('date', 'add=ok;keys=1:Date,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/Mon, 01 Jan 2024 00:00:00 GMT');
        Observer.Expect('expect', 'add=ok;keys=1:Expect,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/100-continue');
        Observer.Expect('expires', 'add=E[The requested operation cannot be perfor];keys=0:;hasLow=E[Invalid HTTP header. Please, make sure t];hasUp=E[Invalid HTTP header. Please, make sure t];hasMix=E[Invalid HTTP header. Please, make sure t];get=No/');
        Observer.Expect('from', 'add=ok;keys=1:From,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/a@b.c');
        Observer.Expect('host', 'add=ok;keys=1:Host,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/localhost');
        Observer.Verify();
    end;





    [Test]
    procedure P198_LowerNames_21_To_39()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Run(Observer, 21, 39);
        Observer.ObserveError('af40');
        Observer.Expect('if-match', 'add=ok;keys=1:If-Match,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/"a"');
        Observer.Expect('if-modified-since', 'add=ok;keys=1:If-Modified-Since,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/Mon, 01 Jan 2024 00:00:00 GMT');
        Observer.Expect('if-none-match', 'add=ok;keys=1:If-None-Match,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/"a"');
        Observer.Expect('if-range', 'add=ok;keys=1:If-Range,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/"a"');
        Observer.Expect('if-unmodified-since', 'add=ok;keys=1:If-Unmodified-Since,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/Mon, 01 Jan 2024 00:00:00 GMT');
        Observer.Expect('last-modified', 'add=E[The requested operation cannot be perfor];keys=0:;hasLow=E[Invalid HTTP header. Please, make sure t];hasUp=E[Invalid HTTP header. Please, make sure t];hasMix=E[Invalid HTTP header. Please, make sure t];get=No/');
        Observer.Expect('max-forwards', 'add=ok;keys=1:Max-Forwards,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/5');
        Observer.Expect('pragma', 'add=ok;keys=1:Pragma,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/no-cache');
        Observer.Expect('proxy-authorization', 'add=ok;keys=1:Proxy-Authorization,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/Basic abc');
        Observer.Expect('range', 'add=ok;keys=1:Range,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/bytes=0-1');
        Observer.Expect('referer', 'add=ok;keys=1:Referer,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/http://localhost/');
        Observer.Expect('te', 'add=ok;keys=1:TE,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/trailers');
        Observer.Expect('trailer', 'add=ok;keys=1:Trailer,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/x-t');
        Observer.Expect('transfer-encoding', 'add=ok;keys=1:Transfer-Encoding,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/chunked');
        Observer.Expect('upgrade', 'add=ok;keys=1:Upgrade,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/HTTP/2.0');
        Observer.Expect('user-agent', 'add=ok;keys=1:User-Agent,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/test');
        Observer.Expect('via', 'add=ok;keys=1:Via,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/1.1 p');
        Observer.Expect('warning', 'add=ok;keys=1:Warning,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/199 a "b"');
        Observer.Expect('af40|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('af40|code', 'ArgumentOutOfRange');
        Observer.Verify();
    end;




}
