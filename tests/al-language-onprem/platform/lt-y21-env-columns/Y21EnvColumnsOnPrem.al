// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: OnPrem (the tables have Scope = OnPrem in the system symbols; a Cloud app gets AL0296)
// Fixtures used: Probe Observer (69160), Y21OnPremRowDump.al (LT Y21 OnPrem Row Dump 98661, tables 98662 and 98663)
// Probe: the columns of OnPrem-scope platform tables whose values come from the service tier, the host, the SQL server or the license,
// measured in the corpus CI containers (bc-linux, CI runs 41191247902 attempts 1 and 2, and 41193475549). Exact values are asserted only
// where the runs gave the same value; a column that changed between runs (the container host name, SQL usage counters) is asserted by
// a rule or a relation, or left out.
// Facts (CI containers):
//  - Drive: BC 27.5 and 28.5 refuse the read ("Server file access by AL functions is disabled. ..."); BC 29.0 gives no row.
//  - File: Path is Code[98], so the filter is upper-cased and TemporaryPath() (165 characters here) does not fit. On the Linux
//    container a filter on /tmp/ finds no file (Suspect_File_ListsOwnFile, not a test: the file system is case-sensitive).
//  - Table Information: per company rows (both companies) for a per-company table; Record Size = Data Size (KB) * 1024 / No. of
//    Records, Size (KB) = Data Size (KB) + Index Size (KB), Compression = 2; an empty table has 0 in every size column.
//  - Permission Range: 230 rows of the container's license, all objects 1..99999999 with full RIMDX.
//  - Database: one row CRONUS, creator sa, created on the day the container's database was made.
//  - SID - Account ID, Extension Execution Info and Performance Profiles: no rows.
//  - Server Instance: one row, the session's: service MicrosoftDynamicsNavServer, instance BC, ports 7085 and 7086, Status 0;
//    the computer name is the container's host name (changes per run, equal to Active Session's).
//  - Report Printer: no row on 27.5; the browser printer on 28.5 and 29.0.
//  - Webhook Subscription "Created By", External Event Subscription "Last Modified Date Time", External Event Log Entry "Event Date
//    Time", External Event Notification "Last Retry Date Time": stored as AL writes them; the platform fills none of them.
//  - Database Index (BC 28 and later): one row per index and company; usage counters left out (they count earlier tests).
// BC versions: 27.5, 28.5, 29.0 (Database Index: 28.5 and later)

codeunit 98660 "LT Y21 Env Columns OnPrem"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Dump: Codeunit "LT Y21 OnPrem Row Dump";

    local procedure Rows(TableNo: Integer; MaxRows: Integer): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(TableNo);
        exit(Dump.Dump(RecRef, MaxRows));
    end;

    [TryFunction]
    local procedure TryRows(TableNo: Integer; MaxRows: Integer; var Result: Text)
    begin
        Result := Rows(TableNo, MaxRows);
    end;

    [Test]
    procedure Y21_Drive_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
    begin
        Observer.Observe('read', Format(TryRows(Database::Drive, 5, Result)));
        Observer.Observe('rows', Result);
        Observer.Observe('error', GetLastErrorText());
        ClearLastError();
#if BC29PLUS
        Observer.Expect('read', 'Yes');
        Observer.Expect('rows', 'n=0;');
        Observer.Expect('error', '');
#else
        Observer.Expect('read', 'No');
        Observer.Expect('rows', '');
        Observer.Expect('error', 'Server file access by AL functions is disabled. Contact your system administrator.');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Y21_File_TemporaryPathFilter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('length', Format(StrLen(TemporaryPath())));
        Observer.Observe('filter', Format(TrySetPath(TemporaryPath())));
        Observer.Observe('error code', GetLastErrorCode());
        ClearLastError();
        Observer.Expect('length', '165');
        Observer.Expect('filter', 'No');
        Observer.Expect('error code', 'StringLengthExceeded');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TrySetPath(Dir: Text)
    var
        FileRec: Record File;
    begin
        FileRec.SetRange(Path, Dir);
    end;

    [Test]
    procedure Y21_File_PathFilterUpperCase()
    var
        Observer: Codeunit "Probe Observer";
        FileRec: Record File;
    begin
        FileRec.SetRange(Path, '/tmp/');
        Observer.Observe('slash', FileRec.GetFilter(Path));
        FileRec.SetRange(Path, '/tmp');
        Observer.Observe('no slash', FileRec.GetFilter(Path));
        Observer.Expect('slash', '/TMP/');
        Observer.Expect('no slash', '/TMP');
        Observer.Verify();
    end;

    // Not a test (Linux suspect): on the Linux CI container the File table gives no row for a file just written to /tmp/
    // (create Yes, len 13, own count 0, count in dir>0 No, with and without the trailing slash). Needs the Windows nightly.
    procedure Suspect_File_ListsOwnFile(Dir: Text)
    var
        Observer: Codeunit "Probe Observer";
        FileRec: Record File;
        F: File;
        Name: Text;
        Len: Integer;
    begin
        Name := 'LTY21' + DelChr(Format(CreateGuid()), '=', '{}-') + '.txt';
        F.TextMode(true);
        Observer.Observe('create', Format(F.Create(Dir + Name)));
        F.Write('LT Y21 file');
        Len := F.Len();
        F.Close();
        Observer.Observe('len', Format(Len));
        FileRec.SetRange(Path, Dir);
        Observer.Observe('count in dir>0', Format(not FileRec.IsEmpty()));
        FileRec.SetRange(Name, Name);
        Observer.Observe('own count', Format(FileRec.Count()));
        if FileRec.FindFirst() then begin
            Observer.Observe('is a file', Format(FileRec."Is a file"));
            Observer.Observe('size', Format(FileRec.Size));
            Observer.Observe('date today', Format(FileRec.Date = Today()));
            Observer.Observe('time set', Format(FileRec.Time <> 0T));
        end;
        File.Erase(Dir + Name);
        Observer.Finish();
    end;

    [Test]
    procedure Y21_TableInformation_Sizes()
    var
        Observer: Codeunit "Probe Observer";
        Sized: Record "LT Y21 Sized Table";
        I: Integer;
    begin
        Observer.Observe('empty table', TableInfoRow(Database::"LT Y21 Empty Table"));
        Observer.Observe('sized before', TableInfoRow(Database::"LT Y21 Sized Table"));
        for I := 1 to 50 do begin
            Sized."No." := I;
            Sized.Name := PadStr('', 100, 'x');
            Sized.Amount := I;
            Sized.Insert();
        end;
        Observer.Observe('sized after 50', TableInfoRow(Database::"LT Y21 Sized Table"));
        Observer.Observe('company rules', SizeRules(Database::Company));
        Observer.Observe('no series rules', SizeRules(308));
        // A passing test commits: remove the rows so that Y21_DatabaseIndex_OwnTable starts from an empty table.
        Sized.DeleteAll();
        Observer.Expect('empty table', 'n=2;[1=<Company>;2=98663;3=LT Y21 Empty Table;4=0;5=0;6=0;7=2;8=0;9=0;][1=My Company;2=98663;3=LT Y21 Empty Table;4=0;5=0;6=0;7=2;8=0;9=0;]');
        Observer.Expect('sized before', 'n=2;[1=<Company>;2=98662;3=LT Y21 Sized Table;4=0;5=0;6=0;7=2;8=0;9=0;][1=My Company;2=98662;3=LT Y21 Sized Table;4=0;5=0;6=0;7=2;8=0;9=0;]');
        Observer.Expect('sized after 50', 'n=2;[1=<Company>;2=98662;3=LT Y21 Sized Table;4=50;5=327.68;6=48;7=2;8=16;9=32;][1=My Company;2=98662;3=LT Y21 Sized Table;4=0;5=0;6=0;7=2;8=0;9=0;]');
        Observer.Expect('company rules', 'rows=1 ok');
        Observer.Expect('no series rules', 'rows=2 ok');
        Observer.Verify();
    end;

    local procedure TableInfoRow(TableNo: Integer): Text
    var
        TableInfo: Record "Table Information";
        RecRef: RecordRef;
    begin
        TableInfo.SetRange("Table No.", TableNo);
        RecRef.GetTable(TableInfo);
        exit(Dump.Dump(RecRef, 2));
    end;

    // Record Size = Data Size (KB) * 1024 / No. of Records (0 without records), Size (KB) = Data Size (KB) + Index Size (KB), Compression 2.
    local procedure SizeRules(TableNo: Integer): Text
    var
        TableInfo: Record "Table Information";
        Broken: Text;
    begin
        TableInfo.SetRange("Table No.", TableNo);
        if TableInfo.FindSet() then
            repeat
                if TableInfo."No. of Records" = 0 then begin
                    if TableInfo."Record Size" <> 0 then
                        Broken += ' record size without records';
                end else
                    if Round(TableInfo."Record Size", 0.01) <> Round(TableInfo."Data Size (KB)" * 1024 / TableInfo."No. of Records", 0.01) then
                        Broken += ' record size';
                if TableInfo."Size (KB)" <> TableInfo."Data Size (KB)" + TableInfo."Index Size (KB)" then
                    Broken += ' size';
                if TableInfo.Compression <> 2 then
                    Broken += ' compression';
            until TableInfo.Next() = 0;
        if Broken = '' then
            Broken := ' ok';
        exit('rows=' + Format(TableInfo.Count()) + Broken);
    end;

    [Test]
    procedure Y21_PermissionRange_Rows()
    var
        Observer: Codeunit "Probe Observer";
        PermissionRange: Record "Permission Range";
        RecRef: RecordRef;
        State: BigInteger;
    begin
        Observer.Observe('count', Format(PermissionRange.Count()));
        RecRef.Open(Database::"Permission Range");
        if RecRef.FindSet() then
            repeat
                Dump.Hash(Dump.Row(RecRef) + '#', State);
            until RecRef.Next() = 0;
        Observer.Observe('digest', Format(State));
        Observer.Observe('first rows', Rows(Database::"Permission Range", 4));
        PermissionRange.SetRange("Object Type", PermissionRange."Object Type"::Codeunit);
        PermissionRange.SetFilter(From, '<=%1', 50000);
        PermissionRange.SetFilter("To", '>=%1', 50000);
        RecRef.GetTable(PermissionRange);
        Observer.Observe('codeunit 50000', Dump.Dump(RecRef, 2));
        Observer.Expect('count', '230');
#if BC28PLUS
        Observer.Expect('digest', '1738678992');
#else
        Observer.Expect('digest', '1778057812');
#endif
        Observer.Expect('first rows', 'n=230;[1=0;2=0;3=1;4=99999999;10=1;11=1;12=1;13=1;14=1;15=0;][1=0;2=1;3=123456700;4=123456799;10=1;11=1;12=1;13=1;14=1;15=0;][1=0;2=2;3=2000000000;4=2000000300;10=1;11=1;12=1;13=1;14=1;15=0;][1=1;2=0;3=1;4=99999999;10=1;11=1;12=1;13=1;14=1;15=0;]');
        Observer.Expect('codeunit 50000', 'n=1;[1=5;2=0;3=1;4=99999999;10=1;11=1;12=1;13=1;14=1;15=0;]');
        Observer.Verify();
    end;

    [Test]
    procedure Y21_Database_Row()
    var
        Observer: Codeunit "Probe Observer";
        Db: Record Database;
        ActiveSession: Record "Active Session";
    begin
        ActiveSession.Get(ServiceInstanceId(), SessionId());
        Observer.Observe('count', Format(Db.Count()));
        if Db.FindFirst() then begin
            Observer.Observe('name', Db."Database Name");
            Observer.Observe('creator', Db.Creator);
            Observer.Observe('created not after today', Format((Db.Created <> 0D) and (Db.Created <= Today())));
            Observer.Observe('replication type', Format(Db."Replication Type", 0, 9));
            Observer.Observe('my database', Format(Db."My Database"));
            Observer.Observe('name eq session db', Format(Db."Database Name" = ActiveSession."Database Name"));
        end;
        Observer.Expect('count', '1');
        Observer.Expect('name', 'CRONUS');
        Observer.Expect('creator', 'sa');
        Observer.Expect('created not after today', 'Yes');
        Observer.Expect('replication type', '0');
        Observer.Expect('my database', 'Yes');
        Observer.Expect('name eq session db', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Y21_EmptyTables()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('sid account id', Rows(Database::"SID - Account ID", 1));
        Observer.Observe('extension execution info', Rows(Database::"Extension Execution Info", 1));
        Observer.Observe('performance profiles', Rows(Database::"Performance Profiles", 1));
        Observer.Expect('sid account id', 'n=0;');
        Observer.Expect('extension execution info', 'n=0;');
        Observer.Expect('performance profiles', 'n=0;');
        Observer.Verify();
    end;

    [Test]
    procedure Y21_ServerInstance_OwnRow()
    var
        Observer: Codeunit "Probe Observer";
        ServerInstance: Record "Server Instance";
        ActiveSession: Record "Active Session";
    begin
        Observer.Observe('count', Format(ServerInstance.Count()));
        ActiveSession.Get(ServiceInstanceId(), SessionId());
        Observer.Observe('get own', Format(ServerInstance.Get(ServiceInstanceId())));
        Observer.Observe('row', Format(ServerInstance."Server Instance ID") + '|' + ServerInstance."Service Name" + '|' + ServerInstance."Server Instance Name" + '|' +
            Format(ServerInstance."Server Port") + '|' + Format(ServerInstance."Management Port") + '|' + Format(ServerInstance.Status, 0, 9) + '|' +
            Format(ServerInstance."Last Tenant Config Version"));
        Observer.Observe('instance name eq session', Format(ServerInstance."Server Instance Name" = ActiveSession."Server Instance Name"));
        Observer.Observe('computer name eq session', Format(ServerInstance."Server Computer Name" = ActiveSession."Server Computer Name"));
        Observer.Observe('computer name set', Format(ServerInstance."Server Computer Name" <> ''));
        Observer.Observe('last active', Dump.DtRule(ServerInstance."Last Active"));
        Observer.Expect('count', '1');
        Observer.Expect('get own', 'Yes');
        Observer.Expect('row', Format(ServiceInstanceId()) + '|MicrosoftDynamicsNavServer|BC|7085|7086|0|0');
        Observer.Expect('instance name eq session', 'Yes');
        Observer.Expect('computer name eq session', 'Yes');
        Observer.Expect('computer name set', 'Yes');
        Observer.Expect('last active', 'past');
        Observer.Verify();
    end;

    [Test]
    procedure Y21_ReportPrinter_Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('rows', Rows(Database::"Report Printer", 3));
#if BC28PLUS
        Observer.Expect('rows', 'n=1;[1=(Handled by the browser);2=(Handled by the browser);3=;4=Browser Printer;5=;6=Sends print jobs to the browser''s printer;]');
#else
        Observer.Expect('rows', 'n=0;');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Y21_WebhookSubscription_CreatedBy()
    var
        Observer: Codeunit "Probe Observer";
        Webhook: Record "Webhook Subscription";
    begin
        Webhook.Init();
        Webhook."Subscription ID" := 'LTY21A';
        Webhook.Endpoint := 'https://example.invalid/y21';
        Webhook.Insert();
        Webhook.Get('LTY21A', 'https://example.invalid/y21');
        Observer.Observe('blank created by', '[' + Webhook."Created By" + '] eq userid=' + Format(Webhook."Created By" = UserId()));
        Webhook.Init();
        Webhook."Subscription ID" := 'LTY21B';
        Webhook.Endpoint := 'https://example.invalid/y21';
        Webhook."Created By" := 'LTY21USER';
        Webhook.Insert(true);
        Webhook.Get('LTY21B', 'https://example.invalid/y21');
        Observer.Observe('set created by', '[' + Webhook."Created By" + ']');
        Webhook."Created By" := 'LTY21OTHER';
        Webhook.Modify();
        Webhook.Get('LTY21B', 'https://example.invalid/y21');
        Observer.Observe('modified created by', '[' + Webhook."Created By" + ']');
        Observer.Expect('blank created by', '[] eq userid=No');
        Observer.Expect('set created by', '[LTY21USER]');
        Observer.Expect('modified created by', '[LTY21OTHER]');
        Observer.Verify();
    end;

    [Test]
    procedure Y21_ExternalEventSubscription_LastModified()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Record "External Event Subscription";
        Id: Guid;
    begin
        Id := CreateGuid();
        Sub.Init();
        Sub.ID := Id;
        Sub."Event Name" := 'lty21event';
        Sub."Company Name" := CompanyName();
        Sub.Insert();
        Sub.Get(Id);
        Observer.Observe('insert', Dump.DtRule(Sub."Last Modified Date Time"));
        Sub."Client State" := 'x';
        Sub.Modify();
        Sub.Get(Id);
        Observer.Observe('modify', Dump.DtRule(Sub."Last Modified Date Time"));
        Sub."Last Modified Date Time" := CreateDateTime(DMY2Date(1, 1, 2020), 0T);
        Sub.Modify();
        Sub.Get(Id);
        Observer.Observe('modify set', Format(Sub."Last Modified Date Time" = CreateDateTime(DMY2Date(1, 1, 2020), 0T)));
        Observer.Expect('insert', 'blank');
        Observer.Expect('modify', 'blank');
        Observer.Expect('modify set', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Y21_ExternalEventLogEntry_EventDateTime()
    var
        Observer: Codeunit "Probe Observer";
        LogEntry: Record "External Event Log Entry";
        RecRef: RecordRef;
    begin
        LogEntry.Init();
        LogEntry."Event Name" := 'lty21event';
        LogEntry."Company Name" := CompanyName();
        LogEntry.Insert();
        Observer.Observe('id', Format(LogEntry.ID));
        LogEntry.SetRange("Event Name", 'lty21event');
        LogEntry.FindFirst();
        RecRef.GetTable(LogEntry);
        Observer.Observe('row', Dump.Row(RecRef));
        Observer.Expect('id', '1');
        Observer.Expect('row', '1=1;2=null;3=;4=lty21event;5=<Company>;6=null;7=blank;8=blob:0;9=false;10=null;11=;');
        Observer.Verify();
    end;

    [Test]
    procedure Y21_ExternalEventNotification_LastRetry()
    var
        Observer: Codeunit "Probe Observer";
        Notification: Record "External Event Notification";
        RecRef: RecordRef;
    begin
        Notification.Init();
        Notification."Log Entry Id" := 1;
        Notification."Subscription Id" := CreateGuid();
        Notification.Insert();
        RecRef.GetTable(Notification);
        RecRef.Find();
        Observer.Observe('insert row', Dump.Row(RecRef));
        Notification."Retry Count" := 1;
        Notification.Modify();
        RecRef.GetTable(Notification);
        RecRef.Find();
        Observer.Observe('modify row', Dump.Row(RecRef));
        Observer.Expect('insert row', '1=1;2=guid;3=0;4=blank;5=0;6=blank;');
        Observer.Expect('modify row', '1=1;2=guid;3=0;4=blank;5=1;6=blank;');
        Observer.Verify();
    end;

#if BC28PLUS
    [Test]
    procedure Y21_DatabaseIndex_OwnTable()
    var
        Observer: Codeunit "Probe Observer";
        Sized: Record "LT Y21 Sized Table";
        I: Integer;
    begin
        Observer.Observe('empty', IndexRows());
        for I := 1 to 20 do begin
            Sized."No." := I;
            Sized.Name := 'n' + Format(I);
            Sized.Insert();
        end;
        Observer.Observe('after 20', IndexRows());
        Observer.Finish();
    end;

    // Per index row: Index Name|Company Name|Column Names|Included Fields|Enabled|Metadata Defined|Unique|Index Size (KB)|Fragmentation %|
    // Database Start time|Statistics rebuild at|Row count. The usage counters and Last Seek/Scan/Lookup/Update are left out.
    local procedure IndexRows(): Text
    var
        DbIndex: Record "Database Index";
        Result: Text;
    begin
        DbIndex.SetRange(TableId, Database::"LT Y21 Sized Table");
        Result := 'n=' + Format(DbIndex.Count()) + ';';
        if DbIndex.FindSet() then
            repeat
                Result += DbIndex."Index Name" + '|' + DbIndex."Company Name" + '|' + DbIndex."Column Names" + '|' + DbIndex."Included Fields" + '|' +
                    Format(DbIndex.Enabled) + '|' + Format(DbIndex."Metadata Defined") + '|' + Format(DbIndex.Unique) + '|' + Format(DbIndex."Index Size (KB)") + '|' +
                    Format(DbIndex."Fragmentation %", 0, 9) + '|' + Dump.DtRule(DbIndex."Database Start time") + '|' + Dump.DtRule(DbIndex."Statistics rebuild at") + '|' +
                    Format(DbIndex."Row count") + ';';
            until DbIndex.Next() = 0;
        exit(Result);
    end;
#endif
}
