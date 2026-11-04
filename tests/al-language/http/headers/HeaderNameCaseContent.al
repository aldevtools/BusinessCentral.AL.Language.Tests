// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpheaders/httpheaders-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), LT Hdr198 Helper (codeunit 72959)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Stored case of known header names added in lower case to content headers (many are invalid there: the error is observed)
// BC versions: 29 (27 and 28 by CI)

codeunit 72961 "LT Hdr198 Name Content"
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
            Observer.Observe(Names.Get(i), Helper.ObservationFor(2, Names.Get(i)));
    end;

    [Test]
    procedure P198_LowerNames_1_To_20()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1, 20);
        Observer.Expect('accept-charset', 'add=E[The requested operation cannot be perfor];keys=1:Content-Type,;hasLow=E[Invalid HTTP header. Please, make sure t];hasUp=E[Invalid HTTP header. Please, make sure t];hasMix=E[Invalid HTTP header. Please, make sure t];get=No/');
        Observer.Expect('accept-encoding', 'add=E[The requested operation cannot be perfor];keys=1:Content-Type,;hasLow=E[Invalid HTTP header. Please, make sure t];hasUp=E[Invalid HTTP header. Please, make sure t];hasMix=E[Invalid HTTP header. Please, make sure t];get=No/');
        Observer.Expect('accept-language', 'add=E[The requested operation cannot be perfor];keys=1:Content-Type,;hasLow=E[Invalid HTTP header. Please, make sure t];hasUp=E[Invalid HTTP header. Please, make sure t];hasMix=E[Invalid HTTP header. Please, make sure t];get=No/');
        Observer.Expect('allow', 'add=ok;keys=2:Content-Type,Allow,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/GET');
        Observer.Expect('authorization', 'add=E[The requested operation cannot be perfor];keys=1:Content-Type,;hasLow=E[Invalid HTTP header. Please, make sure t];hasUp=E[Invalid HTTP header. Please, make sure t];hasMix=E[Invalid HTTP header. Please, make sure t];get=No/');
        Observer.Expect('cache-control', 'add=E[The requested operation cannot be perfor];keys=1:Content-Type,;hasLow=E[Invalid HTTP header. Please, make sure t];hasUp=E[Invalid HTTP header. Please, make sure t];hasMix=E[Invalid HTTP header. Please, make sure t];get=No/');
        Observer.Expect('connection', 'add=E[The requested operation cannot be perfor];keys=1:Content-Type,;hasLow=E[Invalid HTTP header. Please, make sure t];hasUp=E[Invalid HTTP header. Please, make sure t];hasMix=E[Invalid HTTP header. Please, make sure t];get=No/');
        Observer.Expect('content-disposition', 'add=ok;keys=2:Content-Type,Content-Disposition,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/attachment');
        Observer.Expect('content-encoding', 'add=ok;keys=2:Content-Type,Content-Encoding,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/gzip');
        Observer.Expect('content-language', 'add=ok;keys=2:Content-Type,Content-Language,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/en');
        Observer.Expect('content-length', 'add=ok;keys=2:Content-Type,Content-Length,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/5');
        Observer.Expect('content-location', 'add=ok;keys=2:Content-Type,Content-Location,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/http://localhost/y');
        Observer.Expect('content-md5', 'add=ok;keys=2:Content-Type,Content-MD5,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/AAAAAAAAAAAAAAAAAAAAAA==');
        Observer.Expect('content-range', 'add=ok;keys=2:Content-Type,Content-Range,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/bytes 0-1/2');
        Observer.Expect('content-type', 'add=E[Invalid HTTP header. Please, make sure t];keys=1:Content-Type,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/text/plain; charset=utf-8');
        Observer.Expect('date', 'add=E[The requested operation cannot be perfor];keys=1:Content-Type,;hasLow=E[Invalid HTTP header. Please, make sure t];hasUp=E[Invalid HTTP header. Please, make sure t];hasMix=E[Invalid HTTP header. Please, make sure t];get=No/');
        Observer.Expect('expect', 'add=E[The requested operation cannot be perfor];keys=1:Content-Type,;hasLow=E[Invalid HTTP header. Please, make sure t];hasUp=E[Invalid HTTP header. Please, make sure t];hasMix=E[Invalid HTTP header. Please, make sure t];get=No/');
        Observer.Expect('expires', 'add=ok;keys=2:Content-Type,Expires,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/Mon, 01 Jan 2024 00:00:00 GMT');
        Observer.Expect('from', 'add=E[The requested operation cannot be perfor];keys=1:Content-Type,;hasLow=E[Invalid HTTP header. Please, make sure t];hasUp=E[Invalid HTTP header. Please, make sure t];hasMix=E[Invalid HTTP header. Please, make sure t];get=No/');
        Observer.Expect('host', 'add=E[The requested operation cannot be perfor];keys=1:Content-Type,;hasLow=E[Invalid HTTP header. Please, make sure t];hasUp=E[Invalid HTTP header. Please, make sure t];hasMix=E[Invalid HTTP header. Please, make sure t];get=No/');
        Observer.Verify();
    end;





    [Test]
    procedure P198_LowerNames_21_To_39()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Run(Observer, 21, 39);
        Observer.ObserveError('af40');
        Observer.Expect('if-match', 'add=E[The requested operation cannot be perfor];keys=1:Content-Type,;hasLow=E[Invalid HTTP header. Please, make sure t];hasUp=E[Invalid HTTP header. Please, make sure t];hasMix=E[Invalid HTTP header. Please, make sure t];get=No/');
        Observer.Expect('if-modified-since', 'add=E[The requested operation cannot be perfor];keys=1:Content-Type,;hasLow=E[Invalid HTTP header. Please, make sure t];hasUp=E[Invalid HTTP header. Please, make sure t];hasMix=E[Invalid HTTP header. Please, make sure t];get=No/');
        Observer.Expect('if-none-match', 'add=E[The requested operation cannot be perfor];keys=1:Content-Type,;hasLow=E[Invalid HTTP header. Please, make sure t];hasUp=E[Invalid HTTP header. Please, make sure t];hasMix=E[Invalid HTTP header. Please, make sure t];get=No/');
        Observer.Expect('if-range', 'add=E[The requested operation cannot be perfor];keys=1:Content-Type,;hasLow=E[Invalid HTTP header. Please, make sure t];hasUp=E[Invalid HTTP header. Please, make sure t];hasMix=E[Invalid HTTP header. Please, make sure t];get=No/');
        Observer.Expect('if-unmodified-since', 'add=E[The requested operation cannot be perfor];keys=1:Content-Type,;hasLow=E[Invalid HTTP header. Please, make sure t];hasUp=E[Invalid HTTP header. Please, make sure t];hasMix=E[Invalid HTTP header. Please, make sure t];get=No/');
        Observer.Expect('last-modified', 'add=ok;keys=2:Content-Type,Last-Modified,;hasLow=Yes;hasUp=Yes;hasMix=Yes;get=Yes/Mon, 01 Jan 2024 00:00:00 GMT');
        Observer.Expect('max-forwards', 'add=E[The requested operation cannot be perfor];keys=1:Content-Type,;hasLow=E[Invalid HTTP header. Please, make sure t];hasUp=E[Invalid HTTP header. Please, make sure t];hasMix=E[Invalid HTTP header. Please, make sure t];get=No/');
        Observer.Expect('pragma', 'add=E[The requested operation cannot be perfor];keys=1:Content-Type,;hasLow=E[Invalid HTTP header. Please, make sure t];hasUp=E[Invalid HTTP header. Please, make sure t];hasMix=E[Invalid HTTP header. Please, make sure t];get=No/');
        Observer.Expect('proxy-authorization', 'add=E[The requested operation cannot be perfor];keys=1:Content-Type,;hasLow=E[Invalid HTTP header. Please, make sure t];hasUp=E[Invalid HTTP header. Please, make sure t];hasMix=E[Invalid HTTP header. Please, make sure t];get=No/');
        Observer.Expect('range', 'add=E[The requested operation cannot be perfor];keys=1:Content-Type,;hasLow=E[Invalid HTTP header. Please, make sure t];hasUp=E[Invalid HTTP header. Please, make sure t];hasMix=E[Invalid HTTP header. Please, make sure t];get=No/');
        Observer.Expect('referer', 'add=E[The requested operation cannot be perfor];keys=1:Content-Type,;hasLow=E[Invalid HTTP header. Please, make sure t];hasUp=E[Invalid HTTP header. Please, make sure t];hasMix=E[Invalid HTTP header. Please, make sure t];get=No/');
        Observer.Expect('te', 'add=E[The requested operation cannot be perfor];keys=1:Content-Type,;hasLow=E[Invalid HTTP header. Please, make sure t];hasUp=E[Invalid HTTP header. Please, make sure t];hasMix=E[Invalid HTTP header. Please, make sure t];get=No/');
        Observer.Expect('trailer', 'add=E[The requested operation cannot be perfor];keys=1:Content-Type,;hasLow=E[Invalid HTTP header. Please, make sure t];hasUp=E[Invalid HTTP header. Please, make sure t];hasMix=E[Invalid HTTP header. Please, make sure t];get=No/');
        Observer.Expect('transfer-encoding', 'add=E[The requested operation cannot be perfor];keys=1:Content-Type,;hasLow=E[Invalid HTTP header. Please, make sure t];hasUp=E[Invalid HTTP header. Please, make sure t];hasMix=E[Invalid HTTP header. Please, make sure t];get=No/');
        Observer.Expect('upgrade', 'add=E[The requested operation cannot be perfor];keys=1:Content-Type,;hasLow=E[Invalid HTTP header. Please, make sure t];hasUp=E[Invalid HTTP header. Please, make sure t];hasMix=E[Invalid HTTP header. Please, make sure t];get=No/');
        Observer.Expect('user-agent', 'add=E[The requested operation cannot be perfor];keys=1:Content-Type,;hasLow=E[Invalid HTTP header. Please, make sure t];hasUp=E[Invalid HTTP header. Please, make sure t];hasMix=E[Invalid HTTP header. Please, make sure t];get=No/');
        Observer.Expect('via', 'add=E[The requested operation cannot be perfor];keys=1:Content-Type,;hasLow=E[Invalid HTTP header. Please, make sure t];hasUp=E[Invalid HTTP header. Please, make sure t];hasMix=E[Invalid HTTP header. Please, make sure t];get=No/');
        Observer.Expect('warning', 'add=E[The requested operation cannot be perfor];keys=1:Content-Type,;hasLow=E[Invalid HTTP header. Please, make sure t];hasUp=E[Invalid HTTP header. Please, make sure t];hasMix=E[Invalid HTTP header. Please, make sure t];get=No/');
        Observer.Expect('af40|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('af40|code', 'ArgumentOutOfRange');
        Observer.Verify();
    end;




}
