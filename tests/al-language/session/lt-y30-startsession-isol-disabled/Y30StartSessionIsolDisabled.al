// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/session/session-startsession-integer-integer-string-table-duration-method
// Scope: in-scope, but NOT runnable by the corpus CI: StartSession in a test needs a test runner with TestIsolation = Disabled
// (Microsoft's 130451), and every CI leg runs under 130450 (session/TestStartSessionRecord.al pins the refusal). Run with the
// windows-remote tool, WR_TEST_RUNNER=130451. Writer Y30 probe branch; not merged to master until a CI leg runs a 130451 job.
// Facts: what a session started with StartSession sees of the record handed to it (temporary record with rows, record with
// filters, record with marks), and what StartSession with a Timeout does to a session that runs longer than the timeout.
table 92310 "LT Y30 Ss Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Info; Text[30]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

table 92311 "LT Y30 Ss Result"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Name; Text[50]) { }
        field(2; Value; Text[250]) { }
    }
    keys { key(PK; Name) { Clustered = true; } }
}

codeunit 92312 "LT Y30 Ss Worker"
{
    TableNo = "LT Y30 Ss Row";

    trigger OnRun()
    var
        Ids: Text;
    begin
        Put('temp', Format(Rec.IsTemporary()));
        Put('current', Format(Rec.Id) + '|' + Rec.Info);
        Put('filters', Rec.GetFilters());
        Put('count', Format(Rec.Count()));
        if Rec.FindSet() then
            repeat
                Ids += Format(Rec.Id) + ',';
            until Rec.Next() = 0;
        Put('ids', Ids);
        Rec.MarkedOnly(true);
        Put('marked_count', Format(Rec.Count()));
        Rec.Reset();
        Put('count_after_reset', Format(Rec.Count()));
        Put('done', 'yes');
        Commit();
    end;

    local procedure Put(Name: Text; Value: Text)
    var
        Res: Record "LT Y30 Ss Result";
    begin
        Res.Name := CopyStr(Name, 1, MaxStrLen(Res.Name));
        Res.Value := CopyStr(Value, 1, MaxStrLen(Res.Value));
        if not Res.Insert() then
            Res.Modify();
    end;
}

codeunit 92313 "LT Y30 Ss Sleeper"
{
    TableNo = "LT Y30 Ss Row";

    trigger OnRun()
    var
        Res: Record "LT Y30 Ss Result";
    begin
        Res.Name := 'start';
        Res.Value := 'yes';
        Res.Insert();
        Commit();
        Sleep(10000);
        Res.Name := 'end';
        Res.Value := 'yes';
        Res.Insert();
        Commit();
    end;
}

codeunit 92314 "LT Y30 Ss Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    local procedure Reset()
    var
        Row: Record "LT Y30 Ss Row";
        Res: Record "LT Y30 Ss Result";
    begin
        Row.DeleteAll();
        Res.DeleteAll();
        Row.Id := 10;
        Row.Info := 'real10';
        Row.Insert();
        Row.Id := 11;
        Row.Info := 'real11';
        Row.Insert();
        Row.Id := 12;
        Row.Info := 'real12';
        Row.Insert();
        Commit();
    end;

    // Waits until the row Name exists (another session commits it) or MaxMs passed.
    local procedure WaitFor(Name: Text; MaxMs: Integer): Boolean
    var
        Res: Record "LT Y30 Ss Result";
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

    local procedure Line(): Text
    var
        Res: Record "LT Y30 Ss Result";
        T: Text;
    begin
        SelectLatestVersion();
        if Res.FindSet() then
            repeat
                if Res.Name <> 'done' then
                    T += Res.Name + '=' + Res.Value + ' ';
            until Res.Next() = 0;
        exit(T);
    end;

    local procedure Cleanup()
    var
        Row: Record "LT Y30 Ss Row";
        Res: Record "LT Y30 Ss Result";
    begin
        Row.DeleteAll();
        Res.DeleteAll();
        Commit();
    end;

    [Test]
    procedure Y30_StartSession_TemporaryRecord()
    var
        TempRow: Record "LT Y30 Ss Row" temporary;
        Observer: Codeunit "Probe Observer";
        Sid: Integer;
        Ok: Boolean;
    begin
        Reset();
        TempRow.Id := 1;
        TempRow.Info := 'temp1';
        TempRow.Insert();
        TempRow.Id := 2;
        TempRow.Info := 'temp2';
        TempRow.Insert();
        TempRow.Id := 3;
        TempRow.Info := 'temp3';
        TempRow.Insert();
        TempRow.Get(2);
        ClearLastError();
        Ok := StartSession(Sid, Codeunit::"LT Y30 Ss Worker", CompanyName(), TempRow);
        Observer.Observe('started', Format(Ok) + '|' + GetLastErrorText());
        Observer.Observe('done', Format(WaitFor('done', 60000)));
        Observer.Observe('worker', Line());
        Observer.Observe('caller_count_after', Format(TempRow.Count()));
        Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure Y30_StartSession_RecordWithFilters()
    var
        Row: Record "LT Y30 Ss Row";
        Observer: Codeunit "Probe Observer";
        Sid: Integer;
        Ok: Boolean;
    begin
        Reset();
        Row.SetRange(Id, 11, 12);
        Row.SetFilter(Info, '<>%1', 'x');
        Row.FindFirst();
        ClearLastError();
        Ok := StartSession(Sid, Codeunit::"LT Y30 Ss Worker", CompanyName(), Row);
        Observer.Observe('started', Format(Ok) + '|' + GetLastErrorText());
        Observer.Observe('done', Format(WaitFor('done', 60000)));
        Observer.Observe('worker', Line());
        Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure Y30_StartSession_RecordWithMarks()
    var
        Row: Record "LT Y30 Ss Row";
        Observer: Codeunit "Probe Observer";
        Sid: Integer;
        Ok: Boolean;
    begin
        Reset();
        Row.Get(10);
        Row.Mark(true);
        Row.Get(12);
        Row.Mark(true);
        Row.MarkedOnly(true);
        Row.FindFirst();
        ClearLastError();
        Ok := StartSession(Sid, Codeunit::"LT Y30 Ss Worker", CompanyName(), Row);
        Observer.Observe('started', Format(Ok) + '|' + GetLastErrorText());
        Observer.Observe('done', Format(WaitFor('done', 60000)));
        Observer.Observe('worker', Line());
        Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure Y30_StartSession_UnsavedRecord()
    var
        Row: Record "LT Y30 Ss Row";
        Observer: Codeunit "Probe Observer";
        Sid: Integer;
        Ok: Boolean;
    begin
        Reset();
        Row.Get(11);
        Row.Info := 'changed-not-saved';
        ClearLastError();
        Ok := StartSession(Sid, Codeunit::"LT Y30 Ss Worker", CompanyName(), Row);
        Observer.Observe('started', Format(Ok) + '|' + GetLastErrorText());
        Observer.Observe('done', Format(WaitFor('done', 60000)));
        Observer.Observe('worker', Line());
        Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure Y30_StartSession_Timeout()
    var
        Row: Record "LT Y30 Ss Row";
        Observer: Codeunit "Probe Observer";
        Sid: Integer;
        Ok: Boolean;
        Waited: Integer;
        StoppedAfter: Integer;
    begin
        Reset();
        Row.Get(10);
        ClearLastError();
        Ok := StartSession(Sid, Codeunit::"LT Y30 Ss Sleeper", CompanyName(), Row, 2000);
        Observer.Observe('started', Format(Ok) + '|' + GetLastErrorText() + '|sid_nonzero=' + Format(Sid <> 0));
        Observer.Observe('start_row', Format(WaitFor('start', 30000)));
        Observer.Observe('active_after_start', Format(Session.IsSessionActive(Sid)));
        StoppedAfter := -1;
        while (Waited < 20000) and (StoppedAfter = -1) do begin
            if not Session.IsSessionActive(Sid) then
                StoppedAfter := Waited;
            Sleep(500);
            Waited += 500;
        end;
        // coarse buckets: the timeout is 2 s, the worker sleeps 10 s
        case true of
            StoppedAfter = -1:
                Observer.Observe('stopped', 'still active after 20 s');
            StoppedAfter < 8000:
                Observer.Observe('stopped', 'before 8 s');
            else
                Observer.Observe('stopped', 'after 8 s');
        end;
        Observer.Observe('end_row', Format(WaitFor('end', 3000)));
        Observer.Observe('rows', Line());
        Cleanup();
        Observer.Finish();
    end;

    [Test]
    procedure Y30_StartSession_NoTimeout_Control()
    var
        Row: Record "LT Y30 Ss Row";
        Observer: Codeunit "Probe Observer";
        Sid: Integer;
        Ok: Boolean;
    begin
        Reset();
        Row.Get(10);
        Ok := StartSession(Sid, Codeunit::"LT Y30 Ss Sleeper", CompanyName(), Row);
        Observer.Observe('started', Format(Ok));
        Observer.Observe('start_row', Format(WaitFor('start', 30000)));
        Observer.Observe('active_after_start', Format(Session.IsSessionActive(Sid)));
        Observer.Observe('end_row', Format(WaitFor('end', 30000)));
        Sleep(1000);
        Observer.Observe('active_after_end', Format(Session.IsSessionActive(Sid)));
        Cleanup();
        Observer.Finish();
    end;
}
