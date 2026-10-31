// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (69160), Y21RowDump.al (LT Y21 Row Dump 92151, LT Y21 Lock Row 92152)
// Probe: the columns of Cloud-scope platform tables whose values come from the service tier, the SQL server or the license, measured in
// the corpus CI containers (bc-linux). Exact values are asserted only where two CI runs gave the same value; a column that changes
// between runs or between calls is asserted by a rule (blank, in the past, equal to another column of the session).
// BC versions: 27.5, 28.5, 29.0

codeunit 92150 "LT Y21 Env Columns"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Dump: Codeunit "LT Y21 Row Dump";

    [Test]
    procedure Y21_Printer_Rows()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::Printer);
        Observer.Observe('rows', Dump.Dump(RecRef, 3));
        Observer.Finish();
    end;

    [Test]
    procedure Y21_LicenseInformation_Rows()
    var
        Observer: Codeunit "Probe Observer";
        License: Record "License Information";
        State: BigInteger;
        N: Integer;
    begin
        Observer.Observe('count', Format(License.Count()));
        if License.FindSet() then
            repeat
                N += 1;
                Dump.Hash(Format(License."Line No.") + '|' + License.Text + '#', State);
                if N <= 6 then
                    Observer.Observe('line ' + Format(N), Format(License."Line No.") + '|' + CopyStr(License.Text, 1, 100));
            until License.Next() = 0;
        Observer.Observe('digest', Format(State));
        Observer.Finish();
    end;

    [Test]
    procedure Y21_WindowsLanguage_Flags()
    var
        Observer: Codeunit "Probe Observer";
        WindowsLanguage: Record "Windows Language";
        Counts: array[7] of Integer;
        States: array[7] of BigInteger;
        Flags: array[7] of Boolean;
        I: Integer;
    begin
        if WindowsLanguage.FindSet() then
            repeat
                Flags[1] := WindowsLanguage.Enabled;
                Flags[2] := WindowsLanguage."Form Enabled";
                Flags[3] := WindowsLanguage."Report Enabled";
                Flags[4] := WindowsLanguage."Dataport Enabled";
                Flags[5] := WindowsLanguage."XMLport Enabled";
                Flags[6] := WindowsLanguage."ETX File Exist";
                Flags[7] := WindowsLanguage."Help File Exist";
                for I := 1 to 7 do
                    if Flags[I] then begin
                        Counts[I] += 1;
                        Dump.Hash(Format(WindowsLanguage."Language ID") + ';', States[I]);
                    end;
            until WindowsLanguage.Next() = 0;
        for I := 1 to 7 do
            Observer.Observe('flag ' + Format(I), 'count=' + Format(Counts[I]) + ' digest=' + Format(States[I]));
        Observer.Observe('1033', LanguageFlags(1033));
        Observer.Observe('1031', LanguageFlags(1031));
        Observer.Observe('1030', LanguageFlags(1030));
        Observer.Observe('1025', LanguageFlags(1025));
        Observer.Finish();
    end;

    local procedure LanguageFlags(Id: Integer): Text
    var
        WindowsLanguage: Record "Windows Language";
    begin
        if not WindowsLanguage.Get(Id) then
            exit('missing');
        exit(Format(WindowsLanguage.Enabled) + ',' + Format(WindowsLanguage."Form Enabled") + ',' + Format(WindowsLanguage."Report Enabled") + ',' +
            Format(WindowsLanguage."Dataport Enabled") + ',' + Format(WindowsLanguage."XMLport Enabled") + ',' + Format(WindowsLanguage."ETX File Exist") + ',' +
            Format(WindowsLanguage."Help File Exist"));
    end;

    [Test]
    procedure Y21_SessionEvent_OwnSession()
    var
        Observer: Codeunit "Probe Observer";
        SessionEvent: Record "Session Event";
        ActiveSession: Record "Active Session";
        RecRef: RecordRef;
        N: Integer;
    begin
        Observer.Observe('total>0', Format(not SessionEvent.IsEmpty()));
        Observer.Observe('active session', Format(ActiveSession.Get(ServiceInstanceId(), SessionId())));
        SessionEvent.SetRange("Session ID", SessionId());
        SessionEvent.SetRange("Server Instance ID", ServiceInstanceId());
        RecRef.GetTable(SessionEvent);
        Observer.Observe('own rows', Dump.Dump(RecRef, 3));
        if SessionEvent.FindSet() then
            repeat
                N += 1;
                if N <= 3 then
                    Observer.Observe('row ' + Format(N) + ' relations',
                        'user_sid=' + Format(SessionEvent."User SID" = UserSecurityId()) +
                        ' user_id=' + Format(SessionEvent."User ID" = UserId()) +
                        ' db=' + Format(SessionEvent."Database Name" = ActiveSession."Database Name") +
                        ' ccn=' + Format(SessionEvent."Client Computer Name" = ActiveSession."Client Computer Name") +
                        ' unique=' + Format(SessionEvent."Session Unique ID" = ActiveSession."Session Unique ID") +
                        ' client_type=' + Format(SessionEvent."Client Type" = ActiveSession."Client Type") +
                        ' dt_eq_login=' + Format(SessionEvent."Event Datetime" = ActiveSession."Login Datetime") +
                        ' dt_ge_login=' + Format(SessionEvent."Event Datetime" >= ActiveSession."Login Datetime"));
            until SessionEvent.Next() = 0;
        Observer.Observe('raw db', ActiveSession."Database Name");
        Observer.Observe('raw ccn', ActiveSession."Client Computer Name");
        Observer.Finish();
    end;

    [Test]
    procedure Y21_DatabaseLocks_AfterInsert()
    var
        Observer: Codeunit "Probe Observer";
        DbLocks: Record "Database Locks";
        LockRow: Record "LT Y21 Lock Row";
        RecRef: RecordRef;
        N: Integer;
    begin
        DbLocks.SetRange("Session ID", SessionId());
        Observer.Observe('before', Format(DbLocks.Count()));
        LockRow."No." := 1;
        LockRow.Name := 'Y21';
        LockRow.Insert();
        RecRef.GetTable(DbLocks);
        Observer.Observe('after insert', Dump.Dump(RecRef, 4));
        if DbLocks.FindSet() then
            repeat
                N += 1;
                if N <= 4 then
                    Observer.Observe('row ' + Format(N) + ' relations',
                        'user=' + Format(DbLocks."User Name" = UserId()) +
                        ' sql_session_eq_session=' + Format(DbLocks."SQL Session ID" = SessionId()) +
                        ' tx>0=' + Format(DbLocks."Transaction ID" > 0));
            until DbLocks.Next() = 0;
        Observer.Finish();
    end;

    [Test]
    procedure Y21_DatabaseWaitStatistics_Rows()
    var
        Observer: Codeunit "Probe Observer";
        WaitStats: Record "Database Wait Statistics";
        Categories: Text;
        Rules: Text;
        StartTime: DateTime;
        SameStart: Boolean;
    begin
        Observer.Observe('count', Format(WaitStats.Count()));
        SameStart := true;
        if WaitStats.FindSet() then begin
            StartTime := WaitStats."Database start time";
            repeat
                Categories += WaitStats."Wait Category" + ';';
                if WaitStats."Database start time" <> StartTime then
                    SameStart := false;
                if WaitStats."Waiting Tasks Count" < 0 then
                    Rules += 'negative count ' + WaitStats."Wait Category" + ';';
                if WaitStats."Max Wait Time in ms" > WaitStats."Wait Time in ms" then
                    Rules += 'max>total ' + WaitStats."Wait Category" + ';';
                if WaitStats."Signal Wait Time in ms" > WaitStats."Wait Time in ms" then
                    Rules += 'signal>total ' + WaitStats."Wait Category" + ';';
                if (WaitStats."Waiting Tasks Count" = 0) and (WaitStats."Wait Time in ms" <> 0) then
                    Rules += 'time without tasks ' + WaitStats."Wait Category" + ';';
            until WaitStats.Next() = 0;
        end;
        Observer.Observe('categories', Categories);
        Observer.Observe('rules broken', Rules);
        Observer.Observe('same start time', Format(SameStart));
        Observer.Observe('start time', Dump.DtRule(StartTime));
        Observer.Finish();
    end;

    [Test]
    procedure Y21_DatabaseMissingIndexes_Rows()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Database Missing Indexes");
        Observer.Observe('rows', Dump.Dump(RecRef, 2));
        Observer.Finish();
    end;
}
