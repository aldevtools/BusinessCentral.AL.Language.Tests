// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpheaders/httpheaders-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), LT Hdr198 Helper (codeunit 72959)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Helper for the HttpHeaders Cache-Control and header-name-case probes (issue 198)
// BC versions: 29 (27 and 28 by CI)

codeunit 72959 "LT Hdr198 Helper"
{
    procedure GetH(Kind: Integer; var H: HttpHeaders)
    var
        Req: HttpRequestMessage;
        Resp: HttpResponseMessage;
        Content: HttpContent;
    begin
        case Kind of
            1:
                Req.GetHeaders(H);
            2:
                Content.GetHeaders(H);
            3:
                H := Resp.Headers;
        end;
    end;

    [TryFunction]
    local procedure TryAdd(var H: HttpHeaders; N: Text; V: Text)
    begin
        H.Add(N, V);
    end;

    [TryFunction]
    local procedure TryRaw(var H: HttpHeaders; N: Text; V: Text)
    var
        Ok: Boolean;
    begin
        Ok := H.TryAddWithoutValidation(N, V);
    end;

    [TryFunction]
    local procedure TryHas(var H: HttpHeaders; N: Text; var R: Boolean)
    begin
        R := H.Contains(N);
    end;

    [TryFunction]
    local procedure TryGet(var H: HttpHeaders; N: Text; var Res: Text)
    var
        Vals: array[20] of Text;
        i: Integer;
        Found: Boolean;
    begin
        Found := H.GetValues(N, Vals);
        Res := Format(Found) + '/';
        for i := 1 to 20 do
            if Vals[i] <> '' then begin
                if i > 1 then
                    Res += '|';
                Res += Vals[i];
            end;
    end;

    [TryFunction]
    local procedure TryRemove(var H: HttpHeaders; N: Text; var R: Boolean)
    begin
        R := H.Remove(N);
    end;

    local procedure Err(): Text
    begin
        exit('E[' + CopyStr(GetLastErrorText(), 1, 40) + ']');
    end;

    procedure DoAdd(var H: HttpHeaders; N: Text; V: Text): Text
    begin
        ClearLastError();
        if TryAdd(H, N, V) then
            exit('ok');
        exit(Err());
    end;

    procedure DoRaw(var H: HttpHeaders; N: Text; V: Text): Text
    begin
        ClearLastError();
        if TryRaw(H, N, V) then
            exit('ok');
        exit(Err());
    end;

    procedure DoHas(var H: HttpHeaders; N: Text): Text
    var
        R: Boolean;
    begin
        ClearLastError();
        if TryHas(H, N, R) then
            exit(Format(R));
        exit(Err());
    end;

    procedure DoGet(var H: HttpHeaders; N: Text): Text
    var
        Res: Text;
    begin
        ClearLastError();
        if TryGet(H, N, Res) then
            exit(Res);
        exit(Err());
    end;

    procedure DoRemove(var H: HttpHeaders; N: Text): Text
    var
        R: Boolean;
    begin
        ClearLastError();
        if TryRemove(H, N, R) then
            exit(Format(R));
        exit(Err());
    end;

    procedure Keys(var H: HttpHeaders): Text
    var
        L: List of [Text];
        K: Text;
        Res: Text;
    begin
        L := H.Keys();
        Res := Format(L.Count()) + ':';
        foreach K in L do
            Res += K + ',';
        exit(Res);
    end;

    procedure Directives(var L: List of [Text])
    begin
        L.Add('no-store');
        L.Add('no-transform');
        L.Add('only-if-cached');
        L.Add('public');
        L.Add('no-cache');
        L.Add('max-age=60');
        L.Add('max-stale=30');
        L.Add('min-fresh=10');
        L.Add('private');
        L.Add('must-revalidate');
        L.Add('proxy-revalidate');
        L.Add('s-maxage=5');
        L.Add('x-test=1');
    end;

    procedure KnownNames(var L: List of [Text])
    var
        S: Text;
        Parts: List of [Text];
        P: Text;
    begin
        S := 'accept-charset,accept-encoding,accept-language,allow,authorization,cache-control,connection,content-disposition,content-encoding,content-language,content-length,content-location,content-md5,content-range,content-type,date,expect,expires,from,host,if-match,if-modified-since,if-none-match,if-range,if-unmodified-since,last-modified,max-forwards,pragma,proxy-authorization,range,referer,te,trailer,transfer-encoding,upgrade,user-agent,via,warning';
        Parts := S.Split(',');
        foreach P in Parts do
            L.Add(P);
    end;

    procedure ValueFor(N: Text): Text
    begin
        case N of
            'accept-charset':
                exit('utf-8');
            'accept-encoding':
                exit('gzip');
            'accept-language':
                exit('en');
            'allow':
                exit('GET');
            'authorization', 'proxy-authorization':
                exit('Basic abc');
            'cache-control', 'pragma':
                exit('no-cache');
            'connection':
                exit('close');
            'content-disposition':
                exit('attachment');
            'content-encoding':
                exit('gzip');
            'content-language':
                exit('en');
            'content-length', 'max-forwards':
                exit('5');
            'content-location':
                exit('http://localhost/y');
            'content-md5':
                exit('AAAAAAAAAAAAAAAAAAAAAA==');
            'content-range':
                exit('bytes 0-1/2');
            'content-type':
                exit('text/plain');
            'date', 'expires', 'if-modified-since', 'if-unmodified-since', 'last-modified':
                exit('Mon, 01 Jan 2024 00:00:00 GMT');
            'expect':
                exit('100-continue');
            'from':
                exit('a@b.c');
            'host':
                exit('localhost');
            'if-match', 'if-none-match', 'if-range':
                exit('"a"');
            'range':
                exit('bytes=0-1');
            'referer':
                exit('http://localhost/');
            'te':
                exit('trailers');
            'trailer':
                exit('x-t');
            'transfer-encoding':
                exit('chunked');
            'upgrade':
                exit('HTTP/2.0');
            'user-agent':
                exit('test');
            'via':
                exit('1.1 p');
            'warning':
                exit('199 a "b"');
        end;
        exit('x');
    end;

    procedure Swap(S: Text): Text
    begin
        exit(S.ToUpper());
    end;

    procedure Mixed(S: Text): Text
    var
        i: Integer;
        Res: Text;
    begin
        for i := 1 to StrLen(S) do
            if (i mod 2) = 1 then
                Res += UpperCase(CopyStr(S, i, 1))
            else
                Res += LowerCase(CopyStr(S, i, 1));
        exit(Res);
    end;

    procedure ObservationFor(Kind: Integer; N: Text): Text
    var
        H: HttpHeaders;
        Res: Text;
    begin
        GetH(Kind, H);
        Res := 'add=' + DoAdd(H, N, ValueFor(N));
        Res += ';keys=' + Keys(H);
        Res += ';hasLow=' + DoHas(H, N);
        Res += ';hasUp=' + DoHas(H, Swap(N));
        Res += ';hasMix=' + DoHas(H, Mixed(N));
        Res += ';get=' + DoGet(H, Mixed(N));
        exit(Res);
    end;
}
