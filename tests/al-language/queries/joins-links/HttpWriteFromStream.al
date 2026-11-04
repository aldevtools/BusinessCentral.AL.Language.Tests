// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpcontent/httpcontent-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), own temporary table 70790, test codeunit 70791
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: HttpContent.WriteFrom(InStream) of a Blob field, then GetHeaders: which headers exist (Content-Type and others), their values, with preset headers, binary and Unicode streams, a second WriteFrom, and the content inside an HttpRequestMessage
// BC versions: 29 (27 and 28 by CI)

table 70790 "LT P100 Blob"
{
    TableType = Temporary;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Data; Blob) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 70791 "LT P100 Content Headers"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure UnicodeText(): Text
    var
        T: Text[10];
    begin
        T[1] := 99;
        T[2] := 97;
        T[3] := 102;
        T[4] := 233;
        T[5] := 32;
        T[6] := 8364;
        exit(T);
    end;

    local procedure FillText(var Rec: Record "LT P100 Blob" temporary; Id: Integer; Txt: Text)
    var
        OutS: OutStream;
    begin
        Rec.Init();
        Rec.Id := Id;
        Rec.Data.CreateOutStream(OutS);
        OutS.WriteText(Txt);
        Rec.Insert();
    end;

    local procedure FillBytes(var Rec: Record "LT P100 Blob" temporary; Id: Integer)
    var
        OutS: OutStream;
        B: Byte;
    begin
        Rec.Init();
        Rec.Id := Id;
        Rec.Data.CreateOutStream(OutS);
        B := 0;
        OutS.Write(B);
        B := 1;
        OutS.Write(B);
        B := 2;
        OutS.Write(B);
        B := 255;
        OutS.Write(B);
        B := 254;
        OutS.Write(B);
        Rec.Insert();
    end;

    local procedure Stream(var Rec: Record "LT P100 Blob" temporary; Id: Integer; var InS: InStream)
    begin
        Rec.Get(Id);
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(InS);
    end;

    local procedure Hdr(var H: HttpHeaders; Name: Text): Text
    var
        Vals: array[10] of Text;
        Res: Text;
        I: Integer;
    begin
        if not H.Contains(Name) then
            exit('absent');
        if not H.GetValues(Name, Vals) then
            exit('contains but no values');
        for I := 1 to ArrayLen(Vals) do
            if Vals[I] <> '' then
                Res += Format(I) + '=' + Vals[I] + ';';
        exit(Res);
    end;

    local procedure Known(var H: HttpHeaders): Text
    begin
        exit('type=' + Hdr(H, 'Content-Type') + ' len=' + Hdr(H, 'Content-Length') + ' disp=' + Hdr(H, 'Content-Disposition') + ' enc=' + Hdr(H, 'Content-Encoding') + ' lang=' + Hdr(H, 'Content-Language') + ' md5=' + Hdr(H, 'Content-MD5'));
    end;

    local procedure ReadBack(var C: HttpContent): Text
    var
        T: Text;
        R: Boolean;
    begin
        T := 'preset';
        R := C.ReadAs(T);
        exit(Format(R) + '/' + T);
    end;

    [Test]
    procedure P100_Text_KnownHeaders()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P100 Blob" temporary;
        C: HttpContent;
        H: HttpHeaders;
        InS: InStream;
    begin
        FillText(Rec, 1, 'hello');
        Stream(Rec, 1, InS);
        C.WriteFrom(InS);
        Observer.Observe('getheaders', Format(C.GetHeaders(H)));
        Observer.Observe('known', Known(H));
        Observer.Observe('keys', Format(H.Keys().Count()));
        Observer.Observe('read', ReadBack(C));
        Observer.Expect('getheaders', 'Yes');
        Observer.Expect('known', 'type=1=text/plain; charset=utf-8; len=absent disp=absent enc=absent lang=absent md5=absent');
        Observer.Expect('keys', '1');
        Observer.Expect('read', 'Yes/hello');
        Observer.Verify();
    end;

    [Test]
    procedure P100_Binary_KnownHeaders()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P100 Blob" temporary;
        C: HttpContent;
        H: HttpHeaders;
        InS: InStream;
    begin
        FillBytes(Rec, 1);
        Stream(Rec, 1, InS);
        C.WriteFrom(InS);
        C.GetHeaders(H);
        Observer.Observe('known', Known(H));
        Observer.Observe('keys', Format(H.Keys().Count()));
        Observer.Expect('known', 'type=1=text/plain; charset=utf-8; len=absent disp=absent enc=absent lang=absent md5=absent');
        Observer.Expect('keys', '1');
        Observer.Verify();
    end;

    [Test]
    procedure P100_Unicode_KnownHeaders()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P100 Blob" temporary;
        C: HttpContent;
        H: HttpHeaders;
        InS: InStream;
    begin
        FillText(Rec, 1, UnicodeText());
        Stream(Rec, 1, InS);
        C.WriteFrom(InS);
        C.GetHeaders(H);
        Observer.Observe('known', Known(H));
        Observer.Observe('read', ReadBack(C));
        Observer.Expect('known', 'type=1=text/plain; charset=utf-8; len=absent disp=absent enc=absent lang=absent md5=absent');
        Observer.Expect('read', 'Yes/caf� �');
        Observer.Verify();
    end;

    [Test]
    procedure P100_PresetContentType_ThenWrite()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P100 Blob" temporary;
        C: HttpContent;
        H: HttpHeaders;
        H2: HttpHeaders;
        InS: InStream;
    begin
        FillText(Rec, 1, '{"a":1}');
        C.GetHeaders(H);
        Observer.Observe('add_type', Format(H.Add('Content-Type', 'application/json')));
        Stream(Rec, 1, InS);
        C.WriteFrom(InS);
        C.GetHeaders(H2);
        Observer.Observe('known', Known(H2));
        Observer.Observe('keys', Format(H2.Keys().Count()));
        Observer.Expect('add_type', 'No');
        Observer.Expect('known', 'type=1=text/plain; charset=utf-8; len=absent disp=absent enc=absent lang=absent md5=absent');
        Observer.Expect('keys', '1');
        Observer.Verify();
    end;

    [Test]
    procedure P100_PresetOtherHeaders_ThenWrite()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P100 Blob" temporary;
        C: HttpContent;
        H: HttpHeaders;
        H2: HttpHeaders;
        InS: InStream;
    begin
        FillText(Rec, 1, 'abc');
        C.GetHeaders(H);
        H.Add('Content-Disposition', 'attachment; filename="a.txt"');
        H.Add('Content-Language', 'de');
        H.Add('X-Custom', 'v1');
        Stream(Rec, 1, InS);
        C.WriteFrom(InS);
        C.GetHeaders(H2);
        Observer.Observe('known', Known(H2));
        Observer.Observe('custom', Hdr(H2, 'X-Custom'));
        Observer.Observe('keys', Format(H2.Keys().Count()));
        Observer.Expect('known', 'type=1=text/plain; charset=utf-8; len=absent disp=1=attachment; filename="a.txt"; enc=absent lang=1=de; md5=absent');
        Observer.Expect('custom', '1=v1;');
        Observer.Expect('keys', '4');
        Observer.Verify();
    end;

    [Test]
    procedure P100_SecondWrite_ReplacesBody()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P100 Blob" temporary;
        C: HttpContent;
        H: HttpHeaders;
        InS: InStream;
        InS2: InStream;
    begin
        FillText(Rec, 1, 'first');
        FillBytes(Rec, 2);
        Stream(Rec, 1, InS);
        C.WriteFrom(InS);
        C.GetHeaders(H);
        Observer.Observe('after_first', Known(H));
        Observer.Observe('read_first', ReadBack(C));
        Stream(Rec, 2, InS2);
        C.WriteFrom(InS2);
        C.GetHeaders(H);
        Observer.Observe('after_second_same_var', Known(H));
        Observer.Observe('keys', Format(H.Keys().Count()));
        Observer.Expect('after_first', 'type=1=text/plain; charset=utf-8; len=absent disp=absent enc=absent lang=absent md5=absent');
        Observer.Expect('read_first', 'Yes/first');
        Observer.Expect('after_second_same_var', 'type=1=text/plain; charset=utf-8; len=1=5; disp=absent enc=absent lang=absent md5=absent');
        Observer.Expect('keys', '2');
        Observer.Verify();
    end;

    [Test]
    procedure P100_EmptyBlob()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P100 Blob" temporary;
        C: HttpContent;
        H: HttpHeaders;
        InS: InStream;
    begin
        Rec.Init();
        Rec.Id := 1;
        Rec.Insert();
        Stream(Rec, 1, InS);
        C.WriteFrom(InS);
        C.GetHeaders(H);
        Observer.Observe('known', Known(H));
        Observer.Observe('keys', Format(H.Keys().Count()));
        Observer.Observe('read', ReadBack(C));
        Observer.Expect('known', 'type=1=text/plain; charset=utf-8; len=absent disp=absent enc=absent lang=absent md5=absent');
        Observer.Expect('keys', '1');
        Observer.Expect('read', 'Yes/');
        Observer.Verify();
    end;

    [Test]
    procedure P100_InsideRequestMessage()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P100 Blob" temporary;
        Req: HttpRequestMessage;
        C: HttpContent;
        H: HttpHeaders;
        RH: HttpHeaders;
        InS: InStream;
    begin
        FillText(Rec, 1, 'body');
        Stream(Rec, 1, InS);
        C.WriteFrom(InS);
        Req.Content := C;
        Req.Content.GetHeaders(H);
        Observer.Observe('content_known', Known(H));
        Req.GetHeaders(RH);
        Observer.Observe('request_keys', Format(RH.Keys().Count()));
        asserterror Observer.Observe('request_type', Hdr(RH, 'Content-Type'));
        Observer.ObserveError('af277');
        Observer.Expect('content_known', 'type=1=text/plain; charset=utf-8; len=absent disp=absent enc=absent lang=absent md5=absent');
        Observer.Expect('request_keys', '0');
        Observer.Expect('af277|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('af277|code', 'InvalidHeader:InvalidOperation');
        Observer.Verify();
    end;
}
