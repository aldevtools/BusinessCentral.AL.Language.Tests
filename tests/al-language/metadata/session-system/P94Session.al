// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/session/session-data-type
// Scope: in-scope
// Fixtures used: P94Fixtures.al (table 73058, no-op codeunit 73072 that sleeps one second, helper 73071), Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Session.StartSession (three overloads) and StopSession: return values, session id, errors. Every started session is stopped right away. The own session is never stopped.
// BC versions: 29 (27 and 28 by CI)

codeunit 73081 "LT P94 Session Start"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P94 Helper";

    [TryFunction]
    local procedure TryStart(var SessionId: Integer; CodeunitId: Integer; var Ok: Boolean)
    begin
        Ok := Session.StartSession(SessionId, CodeunitId);
    end;

    [TryFunction]
    local procedure TryStartCompany(var SessionId: Integer; CodeunitId: Integer; Company: Text; var Ok: Boolean)
    begin
        Ok := Session.StartSession(SessionId, CodeunitId, Company);
    end;

    [TryFunction]
    local procedure TryStartTimeout(var SessionId: Integer; CodeunitId: Integer; Timeout: Duration; var Ok: Boolean)
    begin
        Ok := Session.StartSession(SessionId, CodeunitId, Timeout);
    end;

    [TryFunction]
    local procedure TryStop(SessionId: Integer; var Ok: Boolean)
    begin
        Ok := Session.StopSession(SessionId);
    end;

    [TryFunction]
    local procedure TryStopComment(SessionId: Integer; Comment: Text; var Ok: Boolean)
    begin
        Ok := Session.StopSession(SessionId, Comment);
    end;

    local procedure StopText(SessionId: Integer): Text
    var
        Ok: Boolean;
    begin
        if TryStop(SessionId, Ok) then
            exit(Format(Ok));
        exit(Helper.ErrText());
    end;

    [Test]
    procedure Start_TwoSessionsDifferentIds()
    var
        A: Integer;
        B: Integer;
    begin
        asserterror Observer.Observe('okA', Format(Session.StartSession(A, Codeunit::"LT P94 NoOp")));
        Observer.ObserveError('af79');
        asserterror Observer.Observe('okB', Format(Session.StartSession(B, Codeunit::"LT P94 NoOp")));
        Observer.ObserveError('af81');
        Observer.Observe('differ', Format(A <> B));
        Observer.Observe('stopA', Format(Session.StopSession(A)));
        Observer.Observe('stopB', Format(Session.StopSession(B)));
        Observer.Expect('af79|text', 'Sessions can only be started in tests that are run by a TestRunner that has TestIsolation set to Disabled.');
        Observer.Expect('af79|code', 'TestStartSessionNotAllowed');
        Observer.Expect('af81|text', 'Sessions can only be started in tests that are run by a TestRunner that has TestIsolation set to Disabled.');
        Observer.Expect('af81|code', 'TestStartSessionNotAllowed');
        Observer.Expect('differ', 'No');
        Observer.Expect('stopA', 'No');
        Observer.Expect('stopB', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Start_WithOwnCompany()
    var
        SessionId: Integer;
    begin
        asserterror Observer.Observe('ok', Format(Session.StartSession(SessionId, Codeunit::"LT P94 NoOp", CompanyName())));
        Observer.ObserveError('af93');
        Observer.Observe('idPositive', Format(SessionId > 0));
        Observer.Observe('stop', Format(Session.StopSession(SessionId)));
        Observer.Expect('af93|text', 'Sessions can only be started in tests that are run by a TestRunner that has TestIsolation set to Disabled.');
        Observer.Expect('af93|code', 'TestStartSessionNotAllowed');
        Observer.Expect('idPositive', 'No');
        Observer.Expect('stop', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Start_WithEmptyCompany()
    var
        SessionId: Integer;
        Ok: Boolean;
    begin
        if TryStartCompany(SessionId, Codeunit::"LT P94 NoOp", '', Ok) then begin
            Observer.Observe('ok', Format(Ok));
            Observer.Observe('idPositive', Format(SessionId > 0));
            Observer.Observe('stop', StopText(SessionId));
        end else
            Observer.Observe('ok', Helper.ErrText());
        Observer.Expect('ok', 'error:Sessions can only be started in tests that are run by a TestRunner that has TestIsolation set to Disabled.|TestStartSessionNotAllowed');
        Observer.Verify();
    end;

    [Test]
    procedure Start_WithUnknownCompany()
    var
        SessionId: Integer;
        Ok: Boolean;
    begin
        SessionId := 777;
        if TryStartCompany(SessionId, Codeunit::"LT P94 NoOp", 'LT P94 No Such Company', Ok) then begin
            Observer.Observe('ok', Format(Ok));
            Observer.Observe('idUnchanged', Format(SessionId = 777));
            if SessionId <> 777 then
                Observer.Observe('stop', StopText(SessionId));
        end else begin
            Observer.Observe('ok', Helper.ErrText());
            Observer.Observe('idUnchanged', Format(SessionId = 777));
        end;
        Observer.Expect('ok', 'error:Sessions can only be started in tests that are run by a TestRunner that has TestIsolation set to Disabled.|TestStartSessionNotAllowed');
        Observer.Expect('idUnchanged', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Start_WithCompanyAndRecord()
    var
        Line: Record "LT P94 Line";
        SessionId: Integer;
    begin
        Line.Id := 5;
        Line.Note := 'param';
        asserterror Observer.Observe('ok', Format(Session.StartSession(SessionId, Codeunit::"LT P94 NoOp", CompanyName(), Line)));
        Observer.ObserveError('af142');
        Observer.Observe('idPositive', Format(SessionId > 0));
        Observer.Observe('stop', Format(Session.StopSession(SessionId)));
        Observer.Expect('af142|text', 'Sessions can only be started in tests that are run by a TestRunner that has TestIsolation set to Disabled.');
        Observer.Expect('af142|code', 'TestStartSessionNotAllowed');
        Observer.Expect('idPositive', 'No');
        Observer.Expect('stop', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Start_WithCompanyRecordAndTimeout()
    var
        Line: Record "LT P94 Line";
        SessionId: Integer;
        Timeout: Duration;
    begin
        Timeout := 60000;
        asserterror Observer.Observe('ok', Format(Session.StartSession(SessionId, Codeunit::"LT P94 NoOp", CompanyName(), Line, Timeout)));
        Observer.ObserveError('af157');
        Observer.Observe('idPositive', Format(SessionId > 0));
        Observer.Observe('stop', Format(Session.StopSession(SessionId)));
        Observer.Expect('af157|text', 'Sessions can only be started in tests that are run by a TestRunner that has TestIsolation set to Disabled.');
        Observer.Expect('af157|code', 'TestStartSessionNotAllowed');
        Observer.Expect('idPositive', 'No');
        Observer.Expect('stop', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Start_WithTimeoutFirst()
    var
        SessionId: Integer;
        Timeout: Duration;
    begin
        Timeout := 60000;
        asserterror Observer.Observe('ok', Format(Session.StartSession(SessionId, Codeunit::"LT P94 NoOp", Timeout)));
        Observer.ObserveError('af171');
        Observer.Observe('idPositive', Format(SessionId > 0));
        Observer.Observe('stop', Format(Session.StopSession(SessionId)));
        Observer.Expect('af171|text', 'Sessions can only be started in tests that are run by a TestRunner that has TestIsolation set to Disabled.');
        Observer.Expect('af171|code', 'TestStartSessionNotAllowed');
        Observer.Expect('idPositive', 'No');
        Observer.Expect('stop', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Start_WithTimeoutAndCompany()
    var
        SessionId: Integer;
        Timeout: Duration;
    begin
        Timeout := 60000;
        asserterror Observer.Observe('ok', Format(Session.StartSession(SessionId, Codeunit::"LT P94 NoOp", Timeout, CompanyName())));
        Observer.ObserveError('af185');
        Observer.Observe('idPositive', Format(SessionId > 0));
        Observer.Observe('stop', Format(Session.StopSession(SessionId)));
        Observer.Expect('af185|text', 'Sessions can only be started in tests that are run by a TestRunner that has TestIsolation set to Disabled.');
        Observer.Expect('af185|code', 'TestStartSessionNotAllowed');
        Observer.Expect('idPositive', 'No');
        Observer.Expect('stop', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Start_TimeoutZeroAndNegative()
    var
        SessionId: Integer;
        Timeout: Duration;
        Ok: Boolean;
    begin
        Timeout := 0;
        if TryStartTimeout(SessionId, Codeunit::"LT P94 NoOp", Timeout, Ok) then begin
            Observer.Observe('zero', Format(Ok));
            Observer.Observe('zeroStop', StopText(SessionId));
        end else
            Observer.Observe('zero', Helper.ErrText());
        SessionId := 0;
        Timeout := -1;
        if TryStartTimeout(SessionId, Codeunit::"LT P94 NoOp", Timeout, Ok) then begin
            Observer.Observe('negative', Format(Ok));
            Observer.Observe('negativeStop', StopText(SessionId));
        end else
            Observer.Observe('negative', Helper.ErrText());
        Observer.Expect('zero', 'error:Sessions can only be started in tests that are run by a TestRunner that has TestIsolation set to Disabled.|TestStartSessionNotAllowed');
        Observer.Expect('negative', 'error:Sessions can only be started in tests that are run by a TestRunner that has TestIsolation set to Disabled.|TestStartSessionNotAllowed');
        Observer.Verify();
    end;

    [Test]
    procedure Start_UnknownCodeunit()
    var
        SessionId: Integer;
        Ok: Boolean;
    begin
        SessionId := 777;
        if TryStart(SessionId, 73999, Ok) then begin
            Observer.Observe('ok', Format(Ok));
            Observer.Observe('idUnchanged', Format(SessionId = 777));
            if SessionId <> 777 then
                Observer.Observe('stop', StopText(SessionId));
        end else begin
            Observer.Observe('ok', Helper.ErrText());
            Observer.Observe('idUnchanged', Format(SessionId = 777));
        end;
        Observer.Expect('ok', 'error:Sessions can only be started in tests that are run by a TestRunner that has TestIsolation set to Disabled.|TestStartSessionNotAllowed');
        Observer.Expect('idUnchanged', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Start_ZeroAndNegativeCodeunit()
    var
        SessionId: Integer;
        Ok: Boolean;
    begin
        SessionId := 777;
        if TryStart(SessionId, 0, Ok) then begin
            Observer.Observe('zero', Format(Ok));
            if SessionId <> 777 then
                Observer.Observe('zeroStop', StopText(SessionId));
        end else
            Observer.Observe('zero', Helper.ErrText());
        SessionId := 777;
        if TryStart(SessionId, -1, Ok) then begin
            Observer.Observe('negative', Format(Ok));
            if SessionId <> 777 then
                Observer.Observe('negativeStop', StopText(SessionId));
        end else
            Observer.Observe('negative', Helper.ErrText());
        Observer.Expect('zero', 'error:Sessions can only be started in tests that are run by a TestRunner that has TestIsolation set to Disabled.|TestStartSessionNotAllowed');
        Observer.Expect('negative', 'error:Sessions can only be started in tests that are run by a TestRunner that has TestIsolation set to Disabled.|TestStartSessionNotAllowed');
        Observer.Verify();
    end;

    [Test]
    procedure Start_NotACodeunitObject()
    var
        SessionId: Integer;
        Ok: Boolean;
    begin
        // 73069 is a page, not a codeunit
        SessionId := 777;
        if TryStart(SessionId, 73069, Ok) then begin
            Observer.Observe('ok', Format(Ok));
            if SessionId <> 777 then
                Observer.Observe('stop', StopText(SessionId));
        end else
            Observer.Observe('ok', Helper.ErrText());
        Observer.Expect('ok', 'error:Sessions can only be started in tests that are run by a TestRunner that has TestIsolation set to Disabled.|TestStartSessionNotAllowed');
        Observer.Verify();
    end;

    [Test]
    procedure Stop_InvalidIds()
    begin
        Observer.Observe('zero', StopText(0));
        Observer.Observe('negative', StopText(-1));
        Observer.Observe('max', StopText(2147483647));
        Observer.Expect('zero', 'No');
        Observer.Expect('negative', 'No');
        Observer.Expect('max', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Stop_Twice()
    var
        SessionId: Integer;
    begin
        asserterror Session.StartSession(SessionId, Codeunit::"LT P94 NoOp");
        Observer.ObserveError('af288');
        Observer.Observe('first', StopText(SessionId));
        Observer.Observe('second', StopText(SessionId));
        Observer.Expect('af288|text', 'Sessions can only be started in tests that are run by a TestRunner that has TestIsolation set to Disabled.');
        Observer.Expect('af288|code', 'TestStartSessionNotAllowed');
        Observer.Expect('first', 'No');
        Observer.Expect('second', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Stop_WithComment()
    var
        SessionId: Integer;
        Ok: Boolean;
    begin
        asserterror Session.StartSession(SessionId, Codeunit::"LT P94 NoOp");
        Observer.ObserveError('af301');
        if TryStopComment(SessionId, 'stopped by probe', Ok) then
            Observer.Observe('stop', Format(Ok))
        else
            Observer.Observe('stop', Helper.ErrText());
        Observer.Expect('af301|text', 'Sessions can only be started in tests that are run by a TestRunner that has TestIsolation set to Disabled.');
        Observer.Expect('af301|code', 'TestStartSessionNotAllowed');
        Observer.Expect('stop', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Stop_WithEmptyComment()
    var
        SessionId: Integer;
        Ok: Boolean;
    begin
        asserterror Session.StartSession(SessionId, Codeunit::"LT P94 NoOp");
        Observer.ObserveError('af316');
        if TryStopComment(SessionId, '', Ok) then
            Observer.Observe('stop', Format(Ok))
        else
            Observer.Observe('stop', Helper.ErrText());
        Observer.Expect('af316|text', 'Sessions can only be started in tests that are run by a TestRunner that has TestIsolation set to Disabled.');
        Observer.Expect('af316|code', 'TestStartSessionNotAllowed');
        Observer.Expect('stop', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Stop_WithVeryLongComment()
    var
        SessionId: Integer;
        Ok: Boolean;
    begin
        asserterror Session.StartSession(SessionId, Codeunit::"LT P94 NoOp");
        Observer.ObserveError('af331');
        if TryStopComment(SessionId, PadStr('', 5000, 'c'), Ok) then
            Observer.Observe('stop', Format(Ok))
        else
            Observer.Observe('stop', Helper.ErrText());
        Observer.Expect('af331|text', 'Sessions can only be started in tests that are run by a TestRunner that has TestIsolation set to Disabled.');
        Observer.Expect('af331|code', 'TestStartSessionNotAllowed');
        Observer.Expect('stop', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Stop_UnknownIdWithComment()
    var
        Ok: Boolean;
    begin
        if TryStopComment(2147483646, 'nobody', Ok) then
            Observer.Observe('stop', Format(Ok))
        else
            Observer.Observe('stop', Helper.ErrText());
        Observer.Expect('stop', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure IsSessionActive_AfterStop()
    var
        SessionId: Integer;
    begin
        asserterror Session.StartSession(SessionId, Codeunit::"LT P94 NoOp");
        Observer.ObserveError('af357');
        Session.StopSession(SessionId);
        Sleep(500);
        Observer.Observe('activeAfterStop', Format(Session.IsSessionActive(SessionId)));
        Observer.Expect('af357|text', 'Sessions can only be started in tests that are run by a TestRunner that has TestIsolation set to Disabled.');
        Observer.Expect('af357|code', 'TestStartSessionNotAllowed');
        Observer.Expect('activeAfterStop', 'No');
        Observer.Verify();
    end;
}
