// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: OnPrem (the tables have Scope = OnPrem in the system symbols; a Cloud app gets AL0296)
// Fixtures used: Probe Observer (69160), Y21OnPremRowDump.al (LT Y21 OnPrem Row Dump 98661, tables 98662 and 98663)
// Probe: the columns of OnPrem-scope platform tables whose values come from the service tier, the host, the SQL server or the license,
// measured in the corpus CI containers (bc-linux). Exact values are asserted only where two CI runs gave the same value; a column that
// changes between runs or between calls is asserted by a rule (blank, in the past, equal to another column of the session).
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

    [Test]
    procedure Y21_Drive_Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('rows', Rows(Database::Drive, 5));
        Observer.Finish();
    end;

    [Test]
    procedure Y21_File_OwnFile()
    var
        Observer: Codeunit "Probe Observer";
        FileRec: Record File;
        F: File;
        Dir: Text;
        Name: Text;
        Len: Integer;
        InS: InStream;
        Content: Text;
        RecRef: RecordRef;
    begin
        Dir := TemporaryPath();
        Name := 'LTY21' + DelChr(Format(CreateGuid()), '=', '{}-') + '.txt';
        F.TextMode(true);
        F.Create(Dir + Name);
        F.Write('LT Y21 file');
        Len := F.Len();
        F.Close();
        Observer.Observe('raw dir', Dir);
        Observer.Observe('len', Format(Len));
        FileRec.SetRange(Path, Dir);
        Observer.Observe('count in dir', Format(FileRec.Count()));
        FileRec.SetRange(Name, Name);
        Observer.Observe('own count', Format(FileRec.Count()));
        if FileRec.FindFirst() then begin
            Observer.Observe('path eq dir', Format(FileRec.Path = Dir));
            Observer.Observe('name eq', Format(FileRec.Name = Name));
            Observer.Observe('is a file', Format(FileRec."Is a file"));
            Observer.Observe('size', Format(FileRec.Size));
            Observer.Observe('date', Format(FileRec.Date = Today()));
            Observer.Observe('time set', Format(FileRec.Time <> 0T));
            Observer.Observe('time le now', Format(FileRec.Time <= Time()));
            FileRec.CalcFields(Data);
            Observer.Observe('data has value', Format(FileRec.Data.HasValue()));
            FileRec.Data.CreateInStream(InS);
            InS.ReadText(Content);
            Observer.Observe('data', Content);
            RecRef.GetTable(FileRec);
            Observer.Observe('row', Dump.Row(RecRef));
        end;
        FileRec.SetRange(Name);
        FileRec.SetRange(Path, Dir + 'lt-y21-no-such-folder');
        Observer.Observe('missing dir count', Format(FileRec.Count()));
        File.Erase(Dir + Name);
        Observer.Finish();
    end;

    [Test]
    procedure Y21_TableInformation_Sizes()
    var
        Observer: Codeunit "Probe Observer";
        Sized: Record "LT Y21 Sized Table";
        TableInfo: Record "Table Information";
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
        Observer.Observe('company', TableInfoRow(Database::Company));
        Observer.Observe('no series', TableInfoRow(308));
        TableInfo.SetRange("Company Name", CompanyName());
        Observer.Observe('company rows', Format(TableInfo.Count()));
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure Y21_Database_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Db: Record Database;
        ActiveSession: Record "Active Session";
    begin
        Observer.Observe('rows', Rows(Database::Database, 3));
        ActiveSession.Get(ServiceInstanceId(), SessionId());
        if Db.FindFirst() then begin
            Observer.Observe('raw created', Format(Db.Created, 0, 9));
            Observer.Observe('name eq session db', Format(Db."Database Name" = ActiveSession."Database Name"));
        end;
        Db.SetRange("My Database", true);
        Observer.Observe('my database count', Format(Db.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure Y21_SidAccountId_Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('rows', Rows(Database::"SID - Account ID", 3));
        Observer.Finish();
    end;

    [Test]
    procedure Y21_ServerInstance_OwnRow()
    var
        Observer: Codeunit "Probe Observer";
        ServerInstance: Record "Server Instance";
        ActiveSession: Record "Active Session";
        RecRef: RecordRef;
    begin
        Observer.Observe('count', Format(ServerInstance.Count()));
        ActiveSession.Get(ServiceInstanceId(), SessionId());
        Observer.Observe('get own', Format(ServerInstance.Get(ServiceInstanceId())));
        RecRef.GetTable(ServerInstance);
        Observer.Observe('own row', Dump.Row(RecRef));
        Observer.Observe('instance name eq session', Format(ServerInstance."Server Instance Name" = ActiveSession."Server Instance Name"));
        Observer.Observe('computer name eq session', Format(ServerInstance."Server Computer Name" = ActiveSession."Server Computer Name"));
        Observer.Observe('raw computer name', ServerInstance."Server Computer Name");
        Observer.Observe('raw last tenant config version', Format(ServerInstance."Last Tenant Config Version"));
        Observer.Observe('last active ge login', Format(ServerInstance."Last Active" >= ActiveSession."Login Datetime"));
        Observer.Observe('rows', Rows(Database::"Server Instance", 3));
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure Y21_ExtensionExecutionInfo_Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('rows', Rows(Database::"Extension Execution Info", 3));
        Observer.Finish();
    end;

    [Test]
    procedure Y21_ReportPrinter_Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('rows', Rows(Database::"Report Printer", 3));
        Observer.Finish();
    end;

    [Test]
    procedure Y21_PerformanceProfiles_Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('rows', Rows(Database::"Performance Profiles", 2));
        Observer.Finish();
    end;

    [Test]
    procedure Y21_ExternalEventSubscription_LastModified()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Record "External Event Subscription";
        Before: DateTime;
        Id: Guid;
    begin
        Before := CurrentDateTime();
        Id := CreateGuid();
        Sub.Init();
        Sub.ID := Id;
        Sub."Event Name" := 'lty21event';
        Sub."Company Name" := CompanyName();
        Sub.Insert();
        Sub.Get(Id);
        Observer.Observe('insert', Dump.DtRule(Sub."Last Modified Date Time") + ' ge_before=' + Format(Sub."Last Modified Date Time" >= Before));
        Sub."Client State" := 'x';
        Sub.Modify();
        Sub.Get(Id);
        Observer.Observe('modify', Dump.DtRule(Sub."Last Modified Date Time") + ' ge_before=' + Format(Sub."Last Modified Date Time" >= Before));
        Sub."Last Modified Date Time" := CreateDateTime(DMY2Date(1, 1, 2020), 0T);
        Sub.Modify();
        Sub.Get(Id);
        Observer.Observe('modify set', Format(Sub."Last Modified Date Time" = CreateDateTime(DMY2Date(1, 1, 2020), 0T)) + ' ' + Dump.DtRule(Sub."Last Modified Date Time"));
        Observer.Finish();
    end;

    [Test]
    procedure Y21_ExternalEventLogEntry_EventDateTime()
    var
        Observer: Codeunit "Probe Observer";
        LogEntry: Record "External Event Log Entry";
        RecRef: RecordRef;
        Before: DateTime;
    begin
        Before := CurrentDateTime();
        LogEntry.Init();
        LogEntry."Event Name" := 'lty21event';
        LogEntry."Company Name" := CompanyName();
        LogEntry.Insert();
        Observer.Observe('id', Format(LogEntry.ID));
        LogEntry.SetRange("Event Name", 'lty21event');
        LogEntry.FindFirst();
        Observer.Observe('insert', Dump.DtRule(LogEntry."Event Date Time") + ' ge_before=' + Format(LogEntry."Event Date Time" >= Before));
        RecRef.GetTable(LogEntry);
        Observer.Observe('row', Dump.Row(RecRef));
        Observer.Finish();
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
        Observer.Finish();
    end;

#if BC28PLUS
    [Test]
    procedure Y21_DatabaseIndex_OwnTable()
    var
        Observer: Codeunit "Probe Observer";
        Sized: Record "LT Y21 Sized Table";
        DbIndex: Record "Database Index";
        RecRef: RecordRef;
        I: Integer;
    begin
        DbIndex.SetRange(TableId, Database::"LT Y21 Sized Table");
        RecRef.GetTable(DbIndex);
        Observer.Observe('empty', Dump.Dump(RecRef, 3));
        for I := 1 to 20 do begin
            Sized."No." := I;
            Sized.Name := 'n' + Format(I);
            Sized.Insert();
        end;
        if Sized.FindFirst() then;
        RecRef.GetTable(DbIndex);
        Observer.Observe('after 20', Dump.Dump(RecRef, 3));
        Observer.Finish();
    end;
#endif
}
