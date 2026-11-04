// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpheaders/httpheaders-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table 74221 and helper codeunit 74228 of this file
// Probe: written against BC 29 (runtime 16); every value is observed through Probe Observer and measured later on real BC 29. No request is ever sent.
// Facts: helper objects for the P87 HttpHeaders / HttpContent probes
// BC versions: 29

table 74221 "LT P87 Blob"
{
    TableType = Temporary;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Data; Blob) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

codeunit 74228 "LT P87 Helper"
{
    // Kind: 1 request headers, 2 request content headers, 3 stand-alone content headers, 4 response headers, 5 response content headers
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
                begin
                    Req.Content := Content;
                    Req.Content.GetHeaders(H);
                end;
            3:
                Content.GetHeaders(H);
            4:
                H := Resp.Headers;
            5:
                Resp.Content.GetHeaders(H);
        end;
    end;

    procedure Err(): Text
    begin
        exit('E[' + CopyStr(GetLastErrorText(), 1, 40) + '|' + GetLastErrorCode() + ']');
    end;

    [TryFunction]
    local procedure TryAdd(var H: HttpHeaders; N: Text; V: Text)
    begin
        H.Add(N, V);
    end;

    [TryFunction]
    local procedure TryContains(var H: HttpHeaders; N: Text; var R: Boolean)
    begin
        R := H.Contains(N);
    end;

    [TryFunction]
    local procedure TryGet(var H: HttpHeaders; N: Text; var R: Boolean; var Cnt: Integer; var First: Text; var Second: Text)
    var
        Vals: array[10] of Text;
        i: Integer;
    begin
        R := H.GetValues(N, Vals);
        Cnt := 0;
        for i := 1 to 10 do begin
            if Vals[i] <> '' then
                Cnt += 1;
        end;
        First := Vals[1];
        Second := Vals[2];
    end;

    [TryFunction]
    local procedure TryRaw(var H: HttpHeaders; N: Text; V: Text; var R: Boolean)
    begin
        R := H.TryAddWithoutValidation(N, V);
    end;

    [TryFunction]
    local procedure TryRemove(var H: HttpHeaders; N: Text; var R: Boolean)
    begin
        R := H.Remove(N);
    end;

    procedure DoAdd(var H: HttpHeaders; N: Text; V: Text): Text
    begin
        if TryAdd(H, N, V) then
            exit('added');
        exit(Err());
    end;

    procedure DoContains(var H: HttpHeaders; N: Text): Text
    var
        R: Boolean;
    begin
        if TryContains(H, N, R) then
            exit(Format(R));
        exit(Err());
    end;

    procedure DoGet(var H: HttpHeaders; N: Text): Text
    var
        R: Boolean;
        Cnt: Integer;
        First: Text;
        Second: Text;
    begin
        if TryGet(H, N, R, Cnt, First, Second) then
            exit(Format(R) + '/n=' + Format(Cnt) + '/1=' + CopyStr(First, 1, 60) + '/2=' + CopyStr(Second, 1, 60));
        exit(Err());
    end;

    procedure DoRaw(var H: HttpHeaders; N: Text; V: Text): Text
    var
        R: Boolean;
    begin
        if TryRaw(H, N, V, R) then
            exit(Format(R));
        exit(Err());
    end;

    procedure DoRemove(var H: HttpHeaders; N: Text): Text
    var
        R: Boolean;
    begin
        if TryRemove(H, N, R) then
            exit(Format(R));
        exit(Err());
    end;

    procedure Keys(var H: HttpHeaders): Text
    var
        K: Text;
        Res: Text;
    begin
        foreach K in H.Keys() do
            Res += K + ',';
        exit(Format(H.Keys().Count()) + ':' + CopyStr(Res, 1, 200));
    end;

    procedure ValueFor(N: Text): Text
    begin
        case N of
            'Cache-Control':
                exit('no-cache');
            'Range':
                exit('bytes=0-9');
            'If-Match', 'If-None-Match':
                exit('"abc"');
            'Content-Disposition':
                exit('attachment; filename="a.txt"');
            'Content-Encoding', 'Accept-Encoding':
                exit('gzip');
            'Content-Language':
                exit('en');
            'Content-Length':
                exit('5');
            'Expires', 'Last-Modified':
                exit('Tue, 15 Nov 1994 08:12:31 GMT');
            'Authorization':
                exit('Bearer abc');
            'User-Agent':
                exit('LT/1.0');
            'Accept':
                exit('application/json');
            'Content-Type':
                exit('text/plain');
            'Host':
                exit('a.example');
            'Connection':
                exit('close');
            'Transfer-Encoding':
                exit('chunked');
        end;
        exit('v');
    end;

    procedure Names(var L: List of [Text])
    begin
        L.Add('Cache-Control');
        L.Add('Range');
        L.Add('If-Match');
        L.Add('If-None-Match');
        L.Add('Content-Disposition');
        L.Add('Content-Encoding');
        L.Add('Content-Language');
        L.Add('Content-Length');
        L.Add('Expires');
        L.Add('Last-Modified');
        L.Add('Authorization');
        L.Add('User-Agent');
        L.Add('Accept');
        L.Add('Accept-Encoding');
        L.Add('Content-Type');
        L.Add('Host');
        L.Add('Connection');
        L.Add('Transfer-Encoding');
        L.Add('X-Custom');
    end;

    // One line per name: Add, Contains, GetValues, Remove, TryAddWithoutValidation, Contains
    procedure Matrix(Kind: Integer; N: Text): Text
    var
        H: HttpHeaders;
        V: Text;
        Res: Text;
    begin
        GetH(Kind, H);
        V := ValueFor(N);
        Res := 'add=' + DoAdd(H, N, V);
        Res += ';has=' + DoContains(H, N);
        Res += ';get=' + CopyStr(DoGet(H, N), 1, 120);
        Res += ';rm=' + DoRemove(H, N);
        Res += ';raw=' + DoRaw(H, N, V);
        Res += ';has3=' + DoContains(H, N);
        exit(Res);
    end;
}
