// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpcontent/httpcontent-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), LT P87 Helper (codeunit 74228), table 74221
// Probe: written against BC 29 (runtime 16); every value is observed through Probe Observer and measured later on real BC 29. No request is ever sent.
// Facts: Content-Type set by header and by WriteFrom: which one wins and what ReadAs gives back
// BC versions: 29

codeunit 74227 "LT P87 Content Type"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT P87 Helper";

    local procedure Type(var H: HttpHeaders): Text
    begin
        exit(Helper.DoGet(H, 'Content-Type'));
    end;

    local procedure Read(var C: HttpContent): Text
    var
        T: Text;
        R: Boolean;
    begin
        T := 'preset';
        R := C.ReadAs(T);
        exit(Format(R) + '/' + T);
    end;

    local procedure ReplaceType(var H: HttpHeaders; V: Text): Text
    begin
        Helper.DoRemove(H, 'Content-Type');
        exit(Helper.DoAdd(H, 'Content-Type', V));
    end;

    [Test]
    procedure HeaderBeforeWrite()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        H: HttpHeaders;
        H2: HttpHeaders;
    begin
        C.GetHeaders(H);
        Observer.Observe('freshType', Type(H));
        Observer.Observe('replace', ReplaceType(H, 'application/json'));
        Observer.Observe('typeBefore', Type(H));
        C.WriteFrom('{"a":1}');
        C.GetHeaders(H2);
        Observer.Observe('typeAfterWrite', Type(H2));
        Observer.Observe('oldRefType', Type(H));
        Observer.Observe('read', Read(C));
        Observer.Expect('freshType', 'Yes/n=1/1=text/plain; charset=utf-8/2=');
        Observer.Expect('replace', 'added');
        Observer.Expect('typeBefore', 'Yes/n=1/1=application/json/2=');
        Observer.Expect('typeAfterWrite', 'Yes/n=1/1=text/plain; charset=utf-8/2=');
        Observer.Expect('oldRefType', 'Yes/n=1/1=text/plain; charset=utf-8/2=');
        Observer.Expect('read', 'Yes/{"a":1}');
        Observer.Verify();
    end;

    [Test]
    procedure HeaderAfterWrite()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        H: HttpHeaders;
        H2: HttpHeaders;
    begin
        C.WriteFrom('{"a":1}');
        C.GetHeaders(H);
        Observer.Observe('typeAfterWrite', Type(H));
        Observer.Observe('replace', ReplaceType(H, 'application/json'));
        C.GetHeaders(H2);
        Observer.Observe('typeNew', Type(H2));
        Observer.Observe('typeOld', Type(H));
        Observer.Observe('read', Read(C));
        Observer.Expect('typeAfterWrite', 'Yes/n=1/1=text/plain; charset=utf-8/2=');
        Observer.Expect('replace', 'added');
        Observer.Expect('typeNew', 'Yes/n=1/1=application/json/2=');
        Observer.Expect('typeOld', 'Yes/n=1/1=application/json/2=');
        Observer.Expect('read', 'Yes/{"a":1}');
        Observer.Verify();
    end;

    [Test]
    procedure AddWithoutRemove()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        H: HttpHeaders;
    begin
        C.WriteFrom('abc');
        C.GetHeaders(H);
        Observer.Observe('addJson', Helper.DoAdd(H, 'Content-Type', 'application/json'));
        Observer.Observe('type', Type(H));
        Observer.Observe('keys', Helper.Keys(H));
        Observer.Observe('raw', Helper.DoRaw(H, 'Content-Type', 'text/html'));
        Observer.Observe('typeRaw', Type(H));
        Observer.Observe('read', Read(C));
        Observer.Expect('addJson', 'E[Invalid HTTP header. Please, make sure t|InvalidHeader:Format]');
        Observer.Expect('type', 'Yes/n=1/1=text/plain; charset=utf-8/2=');
        Observer.Expect('keys', '1:Content-Type,');
        Observer.Expect('raw', 'Yes');
        Observer.Expect('typeRaw', 'Yes/n=2/1=text/plain; charset=utf-8/2=text/html');
        Observer.Expect('read', 'Yes/abc');
        Observer.Verify();
    end;

    [Test]
    procedure SecondWriteAfterHeaderChange()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        H: HttpHeaders;
        H2: HttpHeaders;
    begin
        C.WriteFrom('first');
        C.GetHeaders(H);
        Observer.Observe('replace', ReplaceType(H, 'application/xml'));
        C.WriteFrom('<a/>');
        C.GetHeaders(H2);
        Observer.Observe('typeAfterSecondWrite', Type(H2));
        Observer.Observe('read', Read(C));
        C.WriteFrom('third');
        C.GetHeaders(H2);
        Observer.Observe('typeAfterThird', Type(H2));
        Observer.Expect('replace', 'added');
        Observer.Expect('typeAfterSecondWrite', 'Yes/n=1/1=text/plain; charset=utf-8/2=');
        Observer.Expect('read', 'Yes/<a/>');
        Observer.Expect('typeAfterThird', 'Yes/n=1/1=text/plain; charset=utf-8/2=');
        Observer.Verify();
    end;

    [Test]
    procedure WriteAfterRemovedType()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        H: HttpHeaders;
        H2: HttpHeaders;
    begin
        C.WriteFrom('first');
        C.GetHeaders(H);
        Observer.Observe('remove', Helper.DoRemove(H, 'Content-Type'));
        Observer.Observe('keysNow', Helper.Keys(H));
        C.GetHeaders(H2);
        Observer.Observe('keysNew', Helper.Keys(H2));
        Observer.Observe('read', Read(C));
        C.WriteFrom('second');
        C.GetHeaders(H2);
        Observer.Observe('typeAfterWrite', Type(H2));
        Observer.Expect('remove', 'Yes');
        Observer.Expect('keysNow', '0:');
        Observer.Expect('keysNew', '0:');
        Observer.Expect('read', 'Yes/first');
        Observer.Expect('typeAfterWrite', 'Yes/n=1/1=text/plain; charset=utf-8/2=');
        Observer.Verify();
    end;

    [Test]
    procedure ReadAsIgnoresCharsetHeader()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        H: HttpHeaders;
    begin
        C.WriteFrom('äöü€');
        C.GetHeaders(H);
        Observer.Observe('type', Type(H));
        Observer.Observe('readUtf8', Read(C));
        Observer.Observe('replace', ReplaceType(H, 'text/plain; charset=iso-8859-1'));
        Observer.Observe('readLatin1', Read(C));
        Observer.Observe('replace2', ReplaceType(H, 'text/plain; charset=utf-16'));
        Observer.Observe('readUtf16', Read(C));
        Observer.Observe('replace3', ReplaceType(H, 'application/octet-stream'));
        Observer.Observe('readOctet', Read(C));
        Observer.Observe('replace4', ReplaceType(H, 'image/png'));
        Observer.Observe('readPng', Read(C));
        Observer.Expect('type', 'Yes/n=1/1=text/plain; charset=utf-8/2=');
        Observer.Expect('readUtf8', 'Yes/äöü€');
        Observer.Expect('replace', 'added');
        Observer.Expect('readLatin1', 'Yes/Ã¤Ã¶Ã¼â¬');
        Observer.Expect('replace2', 'added');
        Observer.Expect('readUtf16', 'Yes/꓃뛃볃苢�');
        Observer.Expect('replace3', 'added');
        Observer.Expect('readOctet', 'Yes/äöü€');
        Observer.Expect('replace4', 'added');
        Observer.Expect('readPng', 'Yes/äöü€');
        Observer.Verify();
    end;

    [Test]
    procedure ContentTypeVariantsStayVerbatim()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        H: HttpHeaders;
    begin
        C.WriteFrom('x');
        C.GetHeaders(H);
        Observer.Observe('upper', ReplaceType(H, 'TEXT/PLAIN; CHARSET=UTF-8'));
        Observer.Observe('upperType', Type(H));
        Observer.Observe('noSpace', ReplaceType(H, 'text/plain;charset=utf-8'));
        Observer.Observe('noSpaceType', Type(H));
        Observer.Observe('quotedCharset', ReplaceType(H, 'text/plain; charset="utf-8"'));
        Observer.Observe('quotedType', Type(H));
        Observer.Observe('extraParam', ReplaceType(H, 'text/plain; charset=utf-8; format=flowed'));
        Observer.Observe('extraType', Type(H));
        Observer.Observe('bareType', ReplaceType(H, 'application/vnd.api+json'));
        Observer.Observe('bareTypeValue', Type(H));
        Observer.Observe('read', Read(C));
        Observer.Expect('upper', 'added');
        Observer.Expect('upperType', 'Yes/n=1/1=TEXT/PLAIN; CHARSET=UTF-8/2=');
        Observer.Expect('noSpace', 'added');
        Observer.Expect('noSpaceType', 'Yes/n=1/1=text/plain; charset=utf-8/2=');
        Observer.Expect('quotedCharset', 'added');
        Observer.Expect('quotedType', 'Yes/n=1/1=text/plain; charset="utf-8"/2=');
        Observer.Expect('extraParam', 'added');
        Observer.Expect('extraType', 'Yes/n=1/1=text/plain; charset=utf-8; format=flowed/2=');
        Observer.Expect('bareType', 'added');
        Observer.Expect('bareTypeValue', 'Yes/n=1/1=application/vnd.api+json/2=');
        Observer.Expect('read', 'Yes/x');
        Observer.Verify();
    end;

    [Test]
    procedure Request_ContentTypeWins()
    var
        Observer: Codeunit "Probe Observer";
        Req: HttpRequestMessage;
        C: HttpContent;
        H: HttpHeaders;
        H2: HttpHeaders;
        C2: HttpContent;
    begin
        C.WriteFrom('{}');
        C.GetHeaders(H);
        Observer.Observe('replace', ReplaceType(H, 'application/json'));
        Req.Content := C;
        Req.Content.GetHeaders(H2);
        Observer.Observe('reqType', Type(H2));
        Observer.Observe('reqKeys', Helper.Keys(H2));
        C2 := Req.Content;
        Observer.Observe('reqRead', Read(C2));
        Observer.Expect('replace', 'added');
        Observer.Expect('reqType', 'Yes/n=1/1=application/json/2=');
        Observer.Expect('reqKeys', '1:Content-Type,');
        Observer.Expect('reqRead', 'Yes/{}');
        Observer.Verify();
    end;

    [Test]
    procedure Response_ContentTypeHeaderLocation()
    var
        Observer: Codeunit "Probe Observer";
        Resp: HttpResponseMessage;
        H: HttpHeaders;
        H2: HttpHeaders;
    begin
        Resp.Content.WriteFrom('{}');
        Resp.Content.GetHeaders(H);
        Observer.Observe('contentType', Type(H));
        H2 := Resp.Headers;
        Observer.Observe('respTypeHas', Helper.DoContains(H2, 'Content-Type'));
        Observer.Observe('respTypeAdd', Helper.DoAdd(H2, 'Content-Type', 'application/json'));
        Observer.Observe('respKeys', Helper.Keys(H2));
        Observer.Observe('contentKeys', Helper.Keys(H));
        Observer.Expect('contentType', 'Yes/n=1/1=text/plain; charset=utf-8/2=');
        Observer.Expect('respTypeHas', 'E[Invalid HTTP header. Please, make sure t|InvalidHeader:InvalidOperation]');
        Observer.Expect('respTypeAdd', 'E[The requested operation cannot be perfor|InvalidOperation]');
        Observer.Expect('respKeys', '0:');
        Observer.Expect('contentKeys', '1:Content-Type,');
        Observer.Verify();
    end;
}
