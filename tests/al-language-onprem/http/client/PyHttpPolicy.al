// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/properties/devenv-testhttprequestpolicy-property
// Scope: in-scope (OnPrem app: the [HttpClientHandler] attribute and TestHttpRequestMessage / TestHttpResponseMessage are Scope = OnPrem)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; own codeunits 98700 and 98701
// Probe: observe probe (writer PY, 2026-10-20); every literal asserted below is what the corpus CI service tiers produced.
// Facts: an [HttpClientHandler] under the default policy (no TestHttpRequestPolicy property, codeunit 98700) and under AllowAllOutboundRequests
// (codeunit 98701): a request with no handler, a handler answering false (mocked response) and true (real request to http://localhost:1, which
// refuses the connection), with and without a StrMenuHandler bound (Allow Once = 2, Block Once = 4; Allow Always and Block Always are not used
// because they would store a setting for later tests), and a failed call whose result is not used. AyHttpHandler.al pins AllowOutboundFromHandler,
// PZHttpBlock.al BlockOutboundRequests.
// BC versions: 27, 28, 29 (corpus CI). Tests that reach the handler assert on BC 29 only: Windows 27.5 and 28.5 call the handler with the BC 29
// values (Windows check 2026-10-22), the Linux images of 27 and 28 do not (Linux suspect, bc-linux issue 192).
// No outbound-request approval prompt (StrMenu Allow Always/Allow Once/Block Always/Block Once) appears (bc-linux bcc60c1c; a Windows container
// never shows it, bc-linux 05752c9 #165). So no test binds a StrMenuHandler: a prompt would surface as 'Unhandled UI' in last_error, and
// menu=0 in 'calls' records that none was answered. The *_StrMenuAllowOnce/_StrMenuBlockOnce/_StrMenuCancel tests keep their names and the
// choice they would give; they now pin that the request runs the same as without a menu. Values: corpus CI on bc-linux bcc60c1c (27.5, 28.5,
// 29.0); earlier images showed the prompt and the old values (status 200 OK / Unhandled UI / Block Once = status 400) were Linux-only.

codeunit 98700 "LT PY Http Default Policy"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Calls: Integer;
        Mode: Text;
        MenuChoice: Integer;
        MenuCalls: Integer;
        MenuSeen: Text;

    [HttpClientHandler]
    procedure ModeHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Calls += 1;
        if Mode = 'true' then
            exit(true);
        Response.HttpStatusCode := 201;
        Response.ReasonPhrase := 'Mocked';
        exit(false);
    end;

    [TryFunction]
    local procedure TryGet(Url: Text; var Resp: HttpResponseMessage; var Ret: Boolean)
    var
        Client: HttpClient;
    begin
        Ret := Client.Get(Url, Resp);
    end;

    [TryFunction]
    local procedure TryGetStatement(Url: Text; var Resp: HttpResponseMessage)
    var
        Client: HttpClient;
    begin
        Client.Get(Url, Resp);
    end;

    local procedure Describe(var Resp: HttpResponseMessage): Text
    begin
        exit('status=' + Format(Resp.HttpStatusCode) + ' reason=[' + Resp.ReasonPhrase + '] success=' + Format(Resp.IsSuccessStatusCode) + ' blocked=' + Format(Resp.IsBlockedByEnvironment));
    end;

    local procedure Outcome(var Observer: Codeunit "Probe Observer"; NewMode: Text; Choice: Integer; Url: Text)
    var
        Resp: HttpResponseMessage;
        Ret: Boolean;
    begin
        Mode := NewMode;
        MenuChoice := Choice;
        Calls := 0;
        MenuCalls := 0;
        MenuSeen := '';
        ClearLastError();
        if TryGet(Url, Resp, Ret) then
            Observer.Observe('result', 'ret=' + Format(Ret) + ' ' + Describe(Resp))
        else
            Observer.Observe('result', 'error ' + Describe(Resp));
        Observer.Observe('last_error', GetLastErrorText());
        Observer.Observe('last_code', GetLastErrorCode());
        Observer.Observe('calls', Format(Calls) + ' menu=' + Format(MenuCalls) + ' ' + MenuSeen);
    end;

    [Test]
    procedure NoHandler_ConnectionRefused()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Outcome(Observer, '', 0, 'http://localhost:1/x');
        Observer.Expect('result', 'ret=No status=0 reason=[NavHttpClient Request Failed] success=No blocked=No');
        Observer.Expect('last_error', 'There was an error while executing the HTTP request, the connecting endpoint violates security requirements. Make sure you are connecting to a valid endpoint.');
        Observer.Expect('last_code', 'HttpRequest:Security');
        Observer.Expect('calls', '0 menu=0 ');
        Observer.Verify();
    end;

    [Test]
    procedure NoHandler_StrMenuAllowOnce_ConnectionRefused()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Outcome(Observer, '', 2, 'http://localhost:1/x');
        Observer.Expect('result', 'ret=No status=0 reason=[NavHttpClient Request Failed] success=No blocked=No');
        Observer.Expect('last_error', 'There was an error while executing the HTTP request, the connecting endpoint violates security requirements. Make sure you are connecting to a valid endpoint.');
        Observer.Expect('last_code', 'HttpRequest:Security');
        Observer.Expect('calls', '0 menu=0 ');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ModeHandler')]
    procedure Handler_AnswersFalse_Mocked()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Outcome(Observer, 'false', 0, 'https://example.invalid/mocked');
#if BC29PLUS
        Observer.Expect('result', 'ret=Yes status=201 reason=[Mocked] success=Yes blocked=No');
        Observer.Expect('last_error', '');
        Observer.Expect('last_code', '');
        Observer.Expect('calls', '1 menu=0 ');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too, with the BC 29 values (Windows check 2026-10-22). The Linux images of 27 and 28
        // do not call it (Linux suspect, bc-linux issue 192), so nothing is asserted there.
        Observer.Discard();
#endif
    end;

    [Test]
    [HandlerFunctions('ModeHandler')]
    procedure Handler_AnswersTrue_NoStrMenu()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Outcome(Observer, 'true', 0, 'http://localhost:1/x');
        Observer.Expect('result', 'ret=No status=0 reason=[NavHttpClient Request Failed] success=No blocked=No');
        Observer.Expect('last_error', 'There was an error while executing the HTTP request, the connecting endpoint violates security requirements. Make sure you are connecting to a valid endpoint.');
        Observer.Expect('last_code', 'HttpRequest:Security');
#if BC29PLUS
        Observer.Expect('calls', '1 menu=0 ');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too, with the BC 29 values (Windows check 2026-10-22). The Linux images of 27 and 28
        // do not call it (Linux suspect, bc-linux issue 192), so nothing is asserted there.
        Observer.Discard();
#endif
    end;

    [Test]
    [HandlerFunctions('ModeHandler')]
    procedure Handler_AnswersTrue_StrMenuAllowOnce()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Outcome(Observer, 'true', 2, 'http://localhost:1/x');
        Observer.Expect('result', 'ret=No status=0 reason=[NavHttpClient Request Failed] success=No blocked=No');
        Observer.Expect('last_error', 'There was an error while executing the HTTP request, the connecting endpoint violates security requirements. Make sure you are connecting to a valid endpoint.');
        Observer.Expect('last_code', 'HttpRequest:Security');
#if BC29PLUS
        Observer.Expect('calls', '1 menu=0 ');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too, with the BC 29 values (Windows check 2026-10-22). The Linux images of 27 and 28
        // do not call it (Linux suspect, bc-linux issue 192), so nothing is asserted there.
        Observer.Discard();
#endif
    end;

    [Test]
    [HandlerFunctions('ModeHandler')]
    procedure Handler_AnswersTrue_StrMenuBlockOnce()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Outcome(Observer, 'true', 4, 'http://localhost:1/x');
        Observer.Expect('result', 'ret=No status=0 reason=[NavHttpClient Request Failed] success=No blocked=No');
        Observer.Expect('last_error', 'There was an error while executing the HTTP request, the connecting endpoint violates security requirements. Make sure you are connecting to a valid endpoint.');
        Observer.Expect('last_code', 'HttpRequest:Security');
#if BC29PLUS
        Observer.Expect('calls', '1 menu=0 ');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too, with the BC 29 values (Windows check 2026-10-22). The Linux images of 27 and 28
        // do not call it (Linux suspect, bc-linux issue 192), so nothing is asserted there.
        Observer.Discard();
#endif
    end;

    [Test]
    [HandlerFunctions('ModeHandler')]
    procedure Handler_UnusedResult_BlockOnce()
    var
        Observer: Codeunit "Probe Observer";
        Resp: HttpResponseMessage;
    begin
        Mode := 'true';
        MenuChoice := 4;
        Calls := 0;
        MenuCalls := 0;
        ClearLastError();
        Observer.Observe('statement', Format(TryGetStatement('http://localhost:1/x', Resp)) + ' [' + GetLastErrorText() + '|' + GetLastErrorCode() + '] ' + Describe(Resp) + ' calls=' + Format(Calls) + ' menu=' + Format(MenuCalls));
#if BC29PLUS
        Observer.Expect('statement', 'No [There was an error while executing the HTTP request, the connecting endpoint violates security requirements. Make sure you are connecting to a valid endpoint.|HttpRequest:Security] status=0 reason=[NavHttpClient Request Failed] success=No blocked=No calls=1 menu=0');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too, with the BC 29 values (Windows check 2026-10-22). The Linux images of 27 and 28
        // do not call it (Linux suspect, bc-linux issue 192), so nothing is asserted there.
        Observer.Discard();
#endif
    end;
}

codeunit 98701 "LT PY Http Allow All"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = AllowAllOutboundRequests;

    var
        Calls: Integer;
        Mode: Text;
        MenuChoice: Integer;
        MenuCalls: Integer;
        MenuSeen: Text;

    [HttpClientHandler]
    procedure ModeHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Calls += 1;
        if Mode = 'true' then
            exit(true);
        Response.HttpStatusCode := 201;
        Response.ReasonPhrase := 'Mocked';
        exit(false);
    end;

    [TryFunction]
    local procedure TryGet(Url: Text; var Resp: HttpResponseMessage; var Ret: Boolean)
    var
        Client: HttpClient;
    begin
        Ret := Client.Get(Url, Resp);
    end;

    [TryFunction]
    local procedure TryGetStatement(Url: Text; var Resp: HttpResponseMessage)
    var
        Client: HttpClient;
    begin
        Client.Get(Url, Resp);
    end;

    local procedure Describe(var Resp: HttpResponseMessage): Text
    begin
        exit('status=' + Format(Resp.HttpStatusCode) + ' reason=[' + Resp.ReasonPhrase + '] success=' + Format(Resp.IsSuccessStatusCode) + ' blocked=' + Format(Resp.IsBlockedByEnvironment));
    end;

    local procedure Outcome(var Observer: Codeunit "Probe Observer"; NewMode: Text; Choice: Integer; Url: Text)
    var
        Resp: HttpResponseMessage;
        Ret: Boolean;
    begin
        Mode := NewMode;
        MenuChoice := Choice;
        Calls := 0;
        MenuCalls := 0;
        MenuSeen := '';
        ClearLastError();
        if TryGet(Url, Resp, Ret) then
            Observer.Observe('result', 'ret=' + Format(Ret) + ' ' + Describe(Resp))
        else
            Observer.Observe('result', 'error ' + Describe(Resp));
        Observer.Observe('last_error', GetLastErrorText());
        Observer.Observe('last_code', GetLastErrorCode());
        Observer.Observe('calls', Format(Calls) + ' menu=' + Format(MenuCalls) + ' ' + MenuSeen);
    end;

    [Test]
    procedure NoHandler_ConnectionRefused()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Outcome(Observer, '', 0, 'http://localhost:1/x');
        Observer.Expect('result', 'ret=No status=0 reason=[NavHttpClient Request Failed] success=No blocked=No');
        Observer.Expect('last_error', 'There was an error while executing the HTTP request, the connecting endpoint violates security requirements. Make sure you are connecting to a valid endpoint.');
        Observer.Expect('last_code', 'HttpRequest:Security');
        Observer.Expect('calls', '0 menu=0 ');
        Observer.Verify();
    end;

    [Test]
    procedure NoHandler_StrMenuAllowOnce_ConnectionRefused()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Outcome(Observer, '', 2, 'http://localhost:1/x');
        Observer.Expect('result', 'ret=No status=0 reason=[NavHttpClient Request Failed] success=No blocked=No');
        Observer.Expect('last_error', 'There was an error while executing the HTTP request, the connecting endpoint violates security requirements. Make sure you are connecting to a valid endpoint.');
        Observer.Expect('last_code', 'HttpRequest:Security');
        Observer.Expect('calls', '0 menu=0 ');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ModeHandler')]
    procedure Handler_AnswersFalse_Mocked()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Outcome(Observer, 'false', 0, 'https://example.invalid/mocked');
#if BC29PLUS
        Observer.Expect('result', 'ret=Yes status=201 reason=[Mocked] success=Yes blocked=No');
        Observer.Expect('last_error', '');
        Observer.Expect('last_code', '');
        Observer.Expect('calls', '1 menu=0 ');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too, with the BC 29 values (Windows check 2026-10-22). The Linux images of 27 and 28
        // do not call it (Linux suspect, bc-linux issue 192), so nothing is asserted there.
        Observer.Discard();
#endif
    end;

    [Test]
    [HandlerFunctions('ModeHandler')]
    procedure Handler_AnswersTrue_NoStrMenu()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Outcome(Observer, 'true', 0, 'http://localhost:1/x');
        Observer.Expect('result', 'ret=No status=0 reason=[NavHttpClient Request Failed] success=No blocked=No');
        Observer.Expect('last_error', 'There was an error while executing the HTTP request, the connecting endpoint violates security requirements. Make sure you are connecting to a valid endpoint.');
        Observer.Expect('last_code', 'HttpRequest:Security');
#if BC29PLUS
        Observer.Expect('calls', '1 menu=0 ');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too, with the BC 29 values (Windows check 2026-10-22). The Linux images of 27 and 28
        // do not call it (Linux suspect, bc-linux issue 192), so nothing is asserted there.
        Observer.Discard();
#endif
    end;

    [Test]
    [HandlerFunctions('ModeHandler')]
    procedure Handler_AnswersTrue_StrMenuAllowOnce()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Outcome(Observer, 'true', 2, 'http://localhost:1/x');
        Observer.Expect('result', 'ret=No status=0 reason=[NavHttpClient Request Failed] success=No blocked=No');
        Observer.Expect('last_error', 'There was an error while executing the HTTP request, the connecting endpoint violates security requirements. Make sure you are connecting to a valid endpoint.');
        Observer.Expect('last_code', 'HttpRequest:Security');
#if BC29PLUS
        Observer.Expect('calls', '1 menu=0 ');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too, with the BC 29 values (Windows check 2026-10-22). The Linux images of 27 and 28
        // do not call it (Linux suspect, bc-linux issue 192), so nothing is asserted there.
        Observer.Discard();
#endif
    end;

    [Test]
    [HandlerFunctions('ModeHandler')]
    procedure Handler_AnswersTrue_StrMenuBlockOnce()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Outcome(Observer, 'true', 4, 'http://localhost:1/x');
        Observer.Expect('result', 'ret=No status=0 reason=[NavHttpClient Request Failed] success=No blocked=No');
        Observer.Expect('last_error', 'There was an error while executing the HTTP request, the connecting endpoint violates security requirements. Make sure you are connecting to a valid endpoint.');
        Observer.Expect('last_code', 'HttpRequest:Security');
#if BC29PLUS
        Observer.Expect('calls', '1 menu=0 ');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too, with the BC 29 values (Windows check 2026-10-22). The Linux images of 27 and 28
        // do not call it (Linux suspect, bc-linux issue 192), so nothing is asserted there.
        Observer.Discard();
#endif
    end;

    [Test]
    [HandlerFunctions('ModeHandler')]
    procedure Handler_UnusedResult_BlockOnce()
    var
        Observer: Codeunit "Probe Observer";
        Resp: HttpResponseMessage;
    begin
        Mode := 'true';
        MenuChoice := 4;
        Calls := 0;
        MenuCalls := 0;
        ClearLastError();
        Observer.Observe('statement', Format(TryGetStatement('http://localhost:1/x', Resp)) + ' [' + GetLastErrorText() + '|' + GetLastErrorCode() + '] ' + Describe(Resp) + ' calls=' + Format(Calls) + ' menu=' + Format(MenuCalls));
#if BC29PLUS
        Observer.Expect('statement', 'No [There was an error while executing the HTTP request, the connecting endpoint violates security requirements. Make sure you are connecting to a valid endpoint.|HttpRequest:Security] status=0 reason=[NavHttpClient Request Failed] success=No blocked=No calls=1 menu=0');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too, with the BC 29 values (Windows check 2026-10-22). The Linux images of 27 and 28
        // do not call it (Linux suspect, bc-linux issue 192), so nothing is asserted there.
        Observer.Discard();
#endif
    end;
}
