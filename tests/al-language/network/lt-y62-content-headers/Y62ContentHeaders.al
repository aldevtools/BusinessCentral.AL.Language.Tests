// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpcontent/httpcontent-getheaders-method
// Scope: in-scope. HttpContent.GetHeaders on the content of an HttpRequestMessage that never got content, with the Boolean result used (exit,
//   if, assignment) and as a statement; the request's content state after such a call; the same after content was assigned, after
//   Content.Clear(), and on an HttpResponseMessage that was never filled. No network call is made.
// Fixtures used: Probe Observer (69160); self-contained codeunit 93264
// Probe: gap cycle 6, spec G6-23 (writer Y62). Every literal asserted below is what BC produced (corpus CI 27.5, 28.5, 29.0; SaaS sandbox BC 29).
// Facts: every call starts with a header X-Seed in H, so the values show whether the call cleared or filled H: result|keys=<count>|seed=<Yes/No>
//   or error:<text>|<code>.
// Results (same on 27.5, 28.5, 29.0 and the SaaS sandbox): with the result used, GetHeaders on a request without content answers false, does
//   not raise and leaves H as it was; the content stays uninitialized (a later statement call raises NotInitialized); after content was assigned
//   or Req.Content.Clear() it answers true with the content headers; on a never filled response it answers true with no headers.
// BC versions: 27, 28, 29

codeunit 93264 "LT Y62 Content Headers"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure NewRequest(var Req: HttpRequestMessage)
    begin
        Req.SetRequestUri('https://example.invalid/x');
        Req.Method('GET');
    end;

    local procedure HeadersAsExit(var Req: HttpRequestMessage; var H: HttpHeaders): Boolean
    begin
        exit(Req.Content.GetHeaders(H));
    end;

    local procedure HeadersAsIf(var Req: HttpRequestMessage; var H: HttpHeaders): Text
    begin
        if Req.Content.GetHeaders(H) then
            exit('true');
        exit('false');
    end;

    local procedure HeadersAsAssign(var Req: HttpRequestMessage; var H: HttpHeaders): Boolean
    var
        Result: Boolean;
    begin
        Result := Req.Content.GetHeaders(H);
        exit(Result);
    end;

    [TryFunction]
    local procedure HeadersAsStatement(var Req: HttpRequestMessage; var H: HttpHeaders)
    begin
        Req.Content.GetHeaders(H);
    end;

    [TryFunction]
    local procedure TryForm(Form: Integer; var Req: HttpRequestMessage; var H: HttpHeaders; var Txt: Text)
    begin
        case Form of
            1:
                Txt := Format(HeadersAsExit(Req, H));
            2:
                Txt := HeadersAsIf(Req, H);
            3:
                Txt := Format(HeadersAsAssign(Req, H));
        end;
    end;

    local procedure Seeded(var H: HttpHeaders)
    begin
        Clear(H);
        H.Add('X-Seed', '1');
    end;

    local procedure State(var H: HttpHeaders): Text
    begin
        exit('|keys=' + Format(H.Keys().Count()) + '|seed=' + Format(H.Contains('X-Seed')));
    end;

    local procedure RunForm(Form: Integer; var Req: HttpRequestMessage; var H: HttpHeaders): Text
    var
        Txt: Text;
    begin
        Seeded(H);
        ClearLastError();
        if TryForm(Form, Req, H, Txt) then
            exit(Txt + State(H));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode() + State(H));
    end;

    local procedure RunStatement(var Req: HttpRequestMessage; var H: HttpHeaders): Text
    begin
        Seeded(H);
        ClearLastError();
        if HeadersAsStatement(Req, H) then
            exit('ok' + State(H));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode() + State(H));
    end;

    [Test]
    procedure GetHeaders_ResultUsed_FreshRequest()
    var
        Observer: Codeunit "Probe Observer";
        Req1: HttpRequestMessage;
        Req2: HttpRequestMessage;
        Req3: HttpRequestMessage;
        H: HttpHeaders;
    begin
        NewRequest(Req1);
        NewRequest(Req2);
        NewRequest(Req3);
        Observer.Observe('exit', RunForm(1, Req1, H));
        Observer.Observe('if', RunForm(2, Req2, H));
        Observer.Observe('assign', RunForm(3, Req3, H));
        Observer.Expect('exit', 'No|keys=1|seed=Yes');
        Observer.Expect('if', 'false|keys=1|seed=Yes');
        Observer.Expect('assign', 'No|keys=1|seed=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure GetHeaders_ResultUsed_ThenStatementAndReadAs()
    var
        Observer: Codeunit "Probe Observer";
        Req: HttpRequestMessage;
        Fresh: HttpRequestMessage;
        H: HttpHeaders;
        Txt: Text;
    begin
        NewRequest(Req);
        Observer.Observe('exit', RunForm(1, Req, H));
        Observer.Observe('exit again', RunForm(1, Req, H));
        Observer.Observe('statement after', RunStatement(Req, H));
        Txt := 'preset';
        Observer.Observe('readas after', Format(Req.Content.ReadAs(Txt)) + '|' + Txt);
        NewRequest(Fresh);
        Observer.Observe('statement on fresh', RunStatement(Fresh, H));
        Observer.Expect('exit', 'No|keys=1|seed=Yes');
        Observer.Expect('exit again', 'No|keys=1|seed=Yes');
        Observer.Expect('statement after', 'error:Microsoft.Dynamics.Nav.Runtime.NavHttpContent variable not initialized.|NotInitialized|keys=1|seed=Yes');
        Observer.Expect('readas after', 'No|preset');
        Observer.Expect('statement on fresh', 'error:Microsoft.Dynamics.Nav.Runtime.NavHttpContent variable not initialized.|NotInitialized|keys=1|seed=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure GetHeaders_ResultUsed_AfterContentAssigned()
    var
        Observer: Codeunit "Probe Observer";
        Req: HttpRequestMessage;
        Content: HttpContent;
        CH: HttpHeaders;
        H: HttpHeaders;
        Values: List of [Text];
    begin
        NewRequest(Req);
        Content.GetHeaders(CH);
        CH.Add('Content-Length', '0');
        Req.Content := Content;
        Observer.Observe('exit', RunForm(1, Req, H));
        Observer.Observe('content-length', Format(H.Contains('Content-Length')));
        if H.GetValues('Content-Length', Values) then
            Observer.Observe('content-length values', Format(Values.Count()))
        else
            Observer.Observe('content-length values', 'none');
        Observer.Observe('statement', RunStatement(Req, H));
        Observer.Expect('exit', 'Yes|keys=2|seed=No');
        Observer.Expect('content-length', 'Yes');
        Observer.Expect('content-length values', '1');
        Observer.Expect('statement', 'ok|keys=2|seed=No');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryClear(var Req: HttpRequestMessage)
    begin
        Req.Content.Clear();
    end;

    [Test]
    procedure GetHeaders_AfterContentClear_FreshRequest()
    var
        Observer: Codeunit "Probe Observer";
        Req: HttpRequestMessage;
        H: HttpHeaders;
        Txt: Text;
    begin
        NewRequest(Req);
        ClearLastError();
        if TryClear(Req) then
            Observer.Observe('clear', 'ok')
        else
            Observer.ObserveError('clear');
        Observer.Observe('exit', RunForm(1, Req, H));
        Observer.Observe('statement', RunStatement(Req, H));
        Txt := 'preset';
        Observer.Observe('readas', Format(Req.Content.ReadAs(Txt)) + '|' + Txt);
        Observer.Expect('clear', 'ok');
        Observer.Expect('exit', 'Yes|keys=1|seed=No');
        Observer.Expect('statement', 'ok|keys=1|seed=No');
        Observer.Expect('readas', 'Yes|');
        Observer.Verify();
    end;

    local procedure RespHeadersAsExit(var Resp: HttpResponseMessage; var H: HttpHeaders): Boolean
    begin
        exit(Resp.Content.GetHeaders(H));
    end;

    [TryFunction]
    local procedure RespHeadersAsStatement(var Resp: HttpResponseMessage; var H: HttpHeaders)
    begin
        Resp.Content.GetHeaders(H);
    end;

    [TryFunction]
    local procedure TryRespForm(Form: Integer; var Resp: HttpResponseMessage; var H: HttpHeaders; var Txt: Text)
    var
        Result: Boolean;
    begin
        case Form of
            1:
                Txt := Format(RespHeadersAsExit(Resp, H));
            2:
                if Resp.Content.GetHeaders(H) then
                    Txt := 'true'
                else
                    Txt := 'false';
            3:
                begin
                    Result := Resp.Content.GetHeaders(H);
                    Txt := Format(Result);
                end;
            4:
                begin
                    RespHeadersAsStatement(Resp, H);
                    Txt := 'ok';
                end;
        end;
    end;

    [Test]
    procedure GetHeaders_ResultUsed_ResponseWithoutContent()
    var
        Observer: Codeunit "Probe Observer";
        Resp: HttpResponseMessage;
        H: HttpHeaders;
        Txt: Text;
        Form: Integer;
    begin
        for Form := 1 to 4 do begin
            Clear(Resp);
            Seeded(H);
            ClearLastError();
            Txt := '';
            if TryRespForm(Form, Resp, H, Txt) then
                Observer.Observe('form' + Format(Form), Txt + State(H))
            else
                Observer.Observe('form' + Format(Form), 'error:' + GetLastErrorText() + '|' + GetLastErrorCode() + State(H));
        end;
        Observer.Expect('form1', 'Yes|keys=0|seed=No');
        Observer.Expect('form2', 'true|keys=0|seed=No');
        Observer.Expect('form3', 'Yes|keys=0|seed=No');
        Observer.Expect('form4', 'ok|keys=0|seed=No');
        Observer.Verify();
    end;
}
