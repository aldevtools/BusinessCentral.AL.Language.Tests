// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (69160), Y21RowDump.al (LT Y21 Row Dump 92151)
// Probe: the columns of Cloud-scope platform tables whose values come from the service tier, the SQL server or the license, measured in
// the corpus CI containers (bc-linux, CI runs 41191247902 attempts 1 and 2, and 41193475549). Exact values are asserted only where the
// runs gave the same value; a column that changed between runs is asserted by a rule (blank, in the past, equal to another column of
// the session).
// Facts (CI containers):
//  - Printer has no rows, Database Missing Indexes had none (asserted by rules only). RecordRef.Open of Printer, Database Locks and Database Missing Indexes is
//    refused in a Cloud app ("You cannot open record ... from a RecordRef data type when you are using target ..."), the record works.
//  - License Information: every read fails, Count() included: the platform's single row holds the whole license text (1516
//    characters) in the Text[250] column (code StringLengthExceeded).
//  - Windows Language: Enabled, Form Enabled, Report Enabled and XMLport Enabled are Yes on every row, Dataport Enabled and Help File
//    Exist on none, ETX File Exist on 48 rows (49 on BC 29).
//  - Session Event: one row for the running session; its columns equal the session's Active Session row and UserId()/UserSecurityId().
//  - Database Wait Statistics: the set of categories changed between runs (16 or 17 rows: "Tracing", fewer in a later BC 28.5 run),
//    only the rules of a row are asserted.
//  - Database Locks gave no stable value (2 rows before an insert, 0 after it, 0 and 0 on BC 27.5); not asserted.
// BC versions: 27.5, 28.5, 29.0

codeunit 92150 "LT Y21 Env Columns"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Dump: Codeunit "LT Y21 Row Dump";

    [Test]
    procedure Y21_Printer_NoRows()
    var
        Observer: Codeunit "Probe Observer";
        Printer: Record Printer;
    begin
        Observer.Observe('count', Format(Printer.Count()));
        Observer.Observe('find first', Format(Printer.FindFirst()));
        Observer.Expect('count', '0');
        Observer.Expect('find first', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Y21_Printer_RecordRefRefused()
    var
        RecRef: RecordRef;
    begin
        asserterror RecRef.Open(Database::Printer);
        if StrPos(GetLastErrorText(), 'You cannot open record 2000000039 from a RecordRef data type when you are using target') <> 1 then
            Error('unexpected error: %1', GetLastErrorText());
    end;

    [Test]
    procedure Y21_LicenseInformation_ReadFails()
    var
        Observer: Codeunit "Probe Observer";
        License: Record "License Information";
    begin
        Observer.Observe('count', Format(TryCount(License)));
        Observer.Observe('count error code', GetLastErrorCode());
        Observer.Observe('count error text start', CopyStr(GetLastErrorText(), 1, 78));
        ClearLastError();
        Observer.Observe('find first', Format(TryFindFirst(License)));
        Observer.Observe('find first error code', GetLastErrorCode());
        ClearLastError();
        Observer.Expect('count', 'No');
        Observer.Expect('count error code', 'StringLengthExceeded');
        Observer.Expect('count error text start', 'The length of the string is 1516, but it must be less than or equal to 250 cha');
        Observer.Expect('find first', 'No');
        Observer.Expect('find first error code', 'StringLengthExceeded');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryCount(var License: Record "License Information")
    var
        N: Integer;
    begin
        N := License.Count();
    end;

    [TryFunction]
    local procedure TryFindFirst(var License: Record "License Information")
    begin
        License.FindFirst();
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
        // Flags: 1 Enabled, 2 Form Enabled, 3 Report Enabled, 4 Dataport Enabled, 5 XMLport Enabled, 6 ETX File Exist, 7 Help File Exist.
        // The digest of 1, 2, 3 and 5 is the digest of every Language ID (the same rows as AgWindowsLanguage.al counts).
#if BC29PLUS
        Observer.Expect('flag 1', 'count=212 digest=837524682');
        Observer.Expect('flag 2', 'count=212 digest=837524682');
        Observer.Expect('flag 3', 'count=212 digest=837524682');
        Observer.Expect('flag 4', 'count=0 digest=0');
        Observer.Expect('flag 5', 'count=212 digest=837524682');
        Observer.Expect('flag 6', 'count=49 digest=499707143');
        Observer.Expect('flag 7', 'count=0 digest=0');
#else
        Observer.Expect('flag 1', 'count=208 digest=862752769');
        Observer.Expect('flag 2', 'count=208 digest=862752769');
        Observer.Expect('flag 3', 'count=208 digest=862752769');
        Observer.Expect('flag 4', 'count=0 digest=0');
        Observer.Expect('flag 5', 'count=208 digest=862752769');
        Observer.Expect('flag 6', 'count=48 digest=668088811');
        Observer.Expect('flag 7', 'count=0 digest=0');
#endif
        Observer.Expect('1033', 'Yes,Yes,Yes,No,Yes,Yes,No');
        Observer.Expect('1031', 'Yes,Yes,Yes,No,Yes,Yes,No');
        Observer.Expect('1030', 'Yes,Yes,Yes,No,Yes,Yes,No');
        Observer.Expect('1025', 'Yes,Yes,Yes,No,Yes,No,No');
        Observer.Verify();
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
    begin
        Observer.Observe('total>0', Format(not SessionEvent.IsEmpty()));
        Observer.Observe('active session', Format(ActiveSession.Get(ServiceInstanceId(), SessionId())));
        SessionEvent.SetRange("Session ID", SessionId());
        SessionEvent.SetRange("Server Instance ID", ServiceInstanceId());
        Observer.Observe('own rows', Format(SessionEvent.Count()));
        if SessionEvent.FindFirst() then begin
            Observer.Observe('event type', Format(SessionEvent."Event Type", 0, 9));
            Observer.Observe('comment', SessionEvent.Comment);
            Observer.Observe('database name', SessionEvent."Database Name");
            Observer.Observe('relations',
                'user_sid=' + Format(SessionEvent."User SID" = UserSecurityId()) +
                ' user_id=' + Format(SessionEvent."User ID" = UserId()) +
                ' db=' + Format(SessionEvent."Database Name" = ActiveSession."Database Name") +
                ' ccn=' + Format(SessionEvent."Client Computer Name" = ActiveSession."Client Computer Name") +
                ' unique=' + Format(SessionEvent."Session Unique ID" = ActiveSession."Session Unique ID") +
                ' client_type=' + Format(SessionEvent."Client Type" = ActiveSession."Client Type") +
                ' dt_eq_login=' + Format(SessionEvent."Event Datetime" = ActiveSession."Login Datetime"));
            Observer.Observe('event datetime', Dump.DtRule(SessionEvent."Event Datetime"));
        end;
        Observer.Expect('total>0', 'Yes');
        Observer.Expect('active session', 'Yes');
        Observer.Expect('own rows', '1');
        Observer.Expect('event type', '0');
        Observer.Expect('comment', '');
        Observer.Expect('database name', 'CRONUS');
        Observer.Expect('relations', 'user_sid=Yes user_id=Yes db=Yes ccn=Yes unique=Yes client_type=Yes dt_eq_login=Yes');
        Observer.Expect('event datetime', 'past');
        Observer.Verify();
    end;

    [Test]
    procedure Y21_DatabaseWaitStatistics_Rules()
    var
        Observer: Codeunit "Probe Observer";
        WaitStats: Record "Database Wait Statistics";
        Rules: Text;
        StartTime: DateTime;
        SameStart: Boolean;
    begin
        SameStart := true;
        if WaitStats.FindSet() then begin
            StartTime := WaitStats."Database start time";
            repeat
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
        Observer.Observe('rules broken', Rules);
        // 'same start time' is held: on BC 29 the rows came back with different start times once (master run
        // 41243666409, 2026-10-31) and the same times in every other run. Flaky_Y21_DatabaseWaitStatistics_SameStart keeps it.
        Observer.Observe('start time', Dump.DtRule(StartTime));
        Observer.Expect('rules broken', '');
        Observer.Expect('start time', 'past');
        Observer.Verify();
    end;

    procedure Flaky_Y21_DatabaseWaitStatistics_SameStart()
    var
        Observer: Codeunit "Probe Observer";
        WaitStats: Record "Database Wait Statistics";
        StartTime: DateTime;
        SameStart: Boolean;
    begin
        SameStart := true;
        if WaitStats.FindSet() then begin
            StartTime := WaitStats."Database start time";
            repeat
                if WaitStats."Database start time" <> StartTime then
                    SameStart := false;
            until WaitStats.Next() = 0;
        end;
        Observer.Observe('same start time', Format(SameStart));
        Observer.Expect('same start time', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Y21_DatabaseMissingIndexes_Rules()
    var
        Observer: Codeunit "Probe Observer";
        MissingIndex: Record "Database Missing Indexes";
        Rules: Text;
    begin
        // The CI containers gave no row (a subset run); a full run may give some, so only the rules of a row are asserted.
        if MissingIndex.FindSet() then
            repeat
                if MissingIndex."Table Name" = '' then
                    Rules += 'no table;';
                if (MissingIndex."Index Equality Columns" = '') and (MissingIndex."Index Inequality Columns" = '') then
                    Rules += 'no columns;';
                if MissingIndex."User Seeks" + MissingIndex."User Scans" < 1 then
                    Rules += 'never used;';
            until MissingIndex.Next() = 0;
        Observer.Observe('rules broken', Rules);
        Observer.Expect('rules broken', '');
        Observer.Verify();
    end;
}
