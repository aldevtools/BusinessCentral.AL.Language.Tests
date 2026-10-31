// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/session/session-startsession-integer-integer-string-table-duration-method
// Scope: in-scope. Runs under Microsoft's runner 130451 (TestIsolation = Disabled), as session/Y30StartSessionIsolDisabled.al.
// Writer Y40 (2026-10-31): a session started with StartSession that runs longer than the call: IsSessionActive over time, what the
// session wrote and when, StopSession on a running session and on one that ended, a Timeout that is longer than the run, a Timeout
// that cuts a session which commits a tick every 500 ms, a session that ends in an error, and IsSessionActive / StopSession of
// session ids that do not exist. Times are coarse buckets (the session times of a test server vary).
// Measured on a BC 29 SaaS sandbox under runner 130451 (2026-10-31): StartSession returns at once and the session stays active while
// it sleeps; it turns inactive when OnRun ends, when StopSession stops it (the rest of OnRun does not run), when its Timeout runs out
// (no further commits) and when it fails (the caller sees no error). StopSession raises no error for a session that ended or was
// stopped, nor for an id that does not exist; IsSessionActive of 0, -1 and an unknown id is No.
// BC versions: 27 - 29
table 92320 "LT Y40 Ss Result"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Name; Text[50]) { }
        field(2; Value; Text[250]) { }
    }

    keys
    {
        key(PK; Name) { Clustered = true; }
    }
}

// TableNo only because StartSession with a Timeout takes a record. Writes 'start', sleeps 5 s, writes 'end' (each committed).
codeunit 92321 "LT Y40 Ss Slow"
{
    TableNo = "LT Y40 Ss Result";

    trigger OnRun()
    var
        Res: Record "LT Y40 Ss Result";
    begin
        Res.Name := 'start';
        Res.Insert();
        Commit();
        Sleep(5000);
        Res.Name := 'end';
        Res.Insert();
        Commit();
    end;
}

// Writes 'tick 1' .. 'tick 20', one every 500 ms (each committed), then 'end'.
codeunit 92323 "LT Y40 Ss Ticker"
{
    TableNo = "LT Y40 Ss Result";

    trigger OnRun()
    var
        Res: Record "LT Y40 Ss Result";
        I: Integer;
    begin
        for I := 1 to 20 do begin
            Res.Name := 'tick ' + Format(I);
            Res.Insert();
            Commit();
            Sleep(500);
        end;
        Res.Name := 'end';
        Res.Insert();
        Commit();
    end;
}

// Writes 'start' (committed), then fails.
codeunit 92324 "LT Y40 Ss Failer"
{
    trigger OnRun()
    var
        Res: Record "LT Y40 Ss Result";
    begin
        Res.Name := 'start';
        Res.Insert();
        Commit();
        Error('LT Y40 worker failed');
    end;
}

codeunit 92322 "LT Y40 Ss Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    local procedure Reset()
    var
        Res: Record "LT Y40 Ss Result";
    begin
        Res.DeleteAll();
        Commit();
    end;

    // Waits until the row Name exists (another session commits it) or MaxMs passed.
    local procedure WaitFor(Name: Text; MaxMs: Integer): Boolean
    var
        Res: Record "LT Y40 Ss Result";
        Waited: Integer;
    begin
        while Waited < MaxMs do begin
            SelectLatestVersion();
            if Res.Get(Name) then
                exit(true);
            Sleep(250);
            Waited += 250;
        end;
        exit(false);
    end;

    // Waits until the session is no longer active or MaxMs passed; returns the bucket of the time it took.
    local procedure WaitInactive(Sid: Integer; MaxMs: Integer): Text
    var
        Waited: Integer;
    begin
        while Waited < MaxMs do begin
            if not Session.IsSessionActive(Sid) then
                exit('inactive');
            Sleep(250);
            Waited += 250;
        end;
        exit('still active');
    end;

    local procedure Has(Name: Text): Boolean
    var
        Res: Record "LT Y40 Ss Result";
    begin
        SelectLatestVersion();
        exit(Res.Get(Name));
    end;

    local procedure Ticks(): Integer
    var
        Res: Record "LT Y40 Ss Result";
    begin
        SelectLatestVersion();
        Res.SetFilter(Name, 'tick*');
        exit(Res.Count());
    end;

    local procedure Bucket(Ms: Integer): Text
    begin
        case true of
            Ms < 2000:
                exit('under 2 s');
            Ms < 4000:
                exit('2 to 4 s');
            else
                exit('4 s or more');
        end;
    end;

    [TryFunction]
    local procedure TryStop(Sid: Integer)
    begin
        StopSession(Sid);
    end;

    local procedure Stop(Sid: Integer): Text
    begin
        ClearLastError();
        if TryStop(Sid) then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Y40_Slow_NoTimeout_ActiveOverTime()
    var
        Observer: Codeunit "Probe Observer";
        Sid: Integer;
        Before: DateTime;
    begin
        Reset();
        Before := CurrentDateTime();
        Observer.Observe('started', Format(StartSession(Sid, Codeunit::"LT Y40 Ss Slow", CompanyName())));
        Observer.Observe('call_returned', Bucket(CurrentDateTime() - Before));
        Observer.Observe('active_right_after', Format(Session.IsSessionActive(Sid)));
        Observer.Observe('start_row', Format(WaitFor('start', 30000)));
        Sleep(2000);
        Observer.Observe('active_2s_after_start', Format(Session.IsSessionActive(Sid)));
        Observer.Observe('end_row_2s_after_start', Format(Has('end')));
        Observer.Observe('end_row', Format(WaitFor('end', 30000)));
        Observer.Observe('inactive_after_end', WaitInactive(Sid, 10000));
        Reset();
        Observer.Expect('started', 'Yes');
        Observer.Expect('call_returned', 'under 2 s');
        Observer.Expect('active_right_after', 'Yes');
        Observer.Expect('start_row', 'Yes');
        Observer.Expect('active_2s_after_start', 'Yes');
        Observer.Expect('end_row_2s_after_start', 'No');
        Observer.Expect('end_row', 'Yes');
        Observer.Expect('inactive_after_end', 'inactive');
        Observer.Verify();
    end;

    [Test]
    procedure Y40_StopSession_WhileSleeping()
    var
        Observer: Codeunit "Probe Observer";
        Sid: Integer;
    begin
        Reset();
        StartSession(Sid, Codeunit::"LT Y40 Ss Slow", CompanyName());
        Observer.Observe('start_row', Format(WaitFor('start', 30000)));
        Observer.Observe('stop', Stop(Sid));
        Observer.Observe('inactive_after_stop', WaitInactive(Sid, 10000));
        Observer.Observe('end_row', Format(WaitFor('end', 8000)));
        Observer.Observe('stop_again', Stop(Sid));
        Reset();
        Observer.Expect('start_row', 'Yes');
        Observer.Expect('stop', 'ok');
        Observer.Expect('inactive_after_stop', 'inactive');
        Observer.Expect('end_row', 'No');
        Observer.Expect('stop_again', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure Y40_StopSession_AfterEnd()
    var
        Observer: Codeunit "Probe Observer";
        Sid: Integer;
    begin
        Reset();
        StartSession(Sid, Codeunit::"LT Y40 Ss Slow", CompanyName());
        Observer.Observe('end_row', Format(WaitFor('end', 30000)));
        Observer.Observe('inactive', WaitInactive(Sid, 10000));
        Observer.Observe('stop_ended', Stop(Sid));
        Reset();
        Observer.Expect('end_row', 'Yes');
        Observer.Expect('inactive', 'inactive');
        Observer.Expect('stop_ended', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure Y40_Timeout_LongerThanRun()
    var
        Arg: Record "LT Y40 Ss Result";
        Observer: Codeunit "Probe Observer";
        Sid: Integer;
    begin
        Reset();
        Observer.Observe('started', Format(StartSession(Sid, Codeunit::"LT Y40 Ss Slow", CompanyName(), Arg, 30000)));
        Observer.Observe('start_row', Format(WaitFor('start', 30000)));
        Observer.Observe('end_row', Format(WaitFor('end', 30000)));
        Observer.Observe('inactive_after_end', WaitInactive(Sid, 10000));
        Reset();
        Observer.Expect('started', 'Yes');
        Observer.Expect('start_row', 'Yes');
        Observer.Expect('end_row', 'Yes');
        Observer.Expect('inactive_after_end', 'inactive');
        Observer.Verify();
    end;

    [Test]
    procedure Y40_Timeout_CutsTicker()
    var
        Arg: Record "LT Y40 Ss Result";
        Observer: Codeunit "Probe Observer";
        Sid: Integer;
        TicksAtStop: Integer;
    begin
        Reset();
        Observer.Observe('started', Format(StartSession(Sid, Codeunit::"LT Y40 Ss Ticker", CompanyName(), Arg, 3000)));
        Observer.Observe('first_tick', Format(WaitFor('tick 1', 30000)));
        Observer.Observe('active_after_first_tick', Format(Session.IsSessionActive(Sid)));
        Observer.Observe('inactive', WaitInactive(Sid, 15000));
        TicksAtStop := Ticks();
        Sleep(3000);
        // 20 ticks take 10 s; a 3 s timeout leaves about 6
        case true of
            TicksAtStop = 20:
                Observer.Observe('ticks_at_stop', 'all 20');
            TicksAtStop > 12:
                Observer.Observe('ticks_at_stop', 'more than 12');
            TicksAtStop >= 2:
                Observer.Observe('ticks_at_stop', '2 to 12');
            else
                Observer.Observe('ticks_at_stop', 'under 2');
        end;
        Observer.Observe('ticks_grow_after_stop', Format(Ticks() > TicksAtStop));
        Observer.Observe('end_row', Format(Has('end')));
        Reset();
        Observer.Expect('started', 'Yes');
        Observer.Expect('first_tick', 'Yes');
        Observer.Expect('active_after_first_tick', 'Yes');
        Observer.Expect('inactive', 'inactive');
        Observer.Expect('ticks_at_stop', '2 to 12');
        Observer.Expect('ticks_grow_after_stop', 'No');
        Observer.Expect('end_row', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Y40_SessionThatFails()
    var
        Observer: Codeunit "Probe Observer";
        Sid: Integer;
    begin
        Reset();
        ClearLastError();
        Observer.Observe('started', Format(StartSession(Sid, Codeunit::"LT Y40 Ss Failer", CompanyName())));
        Observer.Observe('start_row', Format(WaitFor('start', 30000)));
        Observer.Observe('inactive', WaitInactive(Sid, 15000));
        Observer.Observe('caller_last_error', GetLastErrorText());
        Reset();
        Observer.Expect('started', 'Yes');
        Observer.Expect('start_row', 'Yes');
        Observer.Expect('inactive', 'inactive');
        Observer.Expect('caller_last_error', '');
        Observer.Verify();
    end;

    [Test]
    procedure Y40_UnknownSessionIds()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('active_0', Format(Session.IsSessionActive(0)));
        Observer.Observe('active_minus_1', Format(Session.IsSessionActive(-1)));
        Observer.Observe('active_max', Format(Session.IsSessionActive(2147483647)));
        Observer.Observe('stop_max', Stop(2147483647));
        Observer.Expect('active_0', 'No');
        Observer.Expect('active_minus_1', 'No');
        Observer.Expect('active_max', 'No');
        Observer.Expect('stop_max', 'ok');
        Observer.Verify();
    end;
}
