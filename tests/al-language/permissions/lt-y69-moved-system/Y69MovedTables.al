// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permission-set-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Y69PermSets.al (sets 93700-93708, extension 93707, writer 93709, helper 93735); Permissions Mock (131006).
// Probe (writer Y69, al-runner issue 6716 by SShadowS): permission sets that name a table BC 29 ships twice under one id (the Base Application's
//   ObsoleteState = Moved copy and the Business Foundation target): Reason Code 231, Return Reason 6635, Source Code 230, Source Code Setup 242,
//   No. Series 308, No. Series Line 309, No. Series Relationship 310, No. Series Tenant 1263. Which table the name binds to (Expanded Permission
//   rows of the set), whether the set grants it (read, insert, modify, delete of a seeded row under Permissions Mock.Set), the same through an
//   included set, an excluded set, a permission set extension, the Permissions property of a codeunit, and the reporter's shape (the set names
//   Reason Code and Customer; the read of Customer must work).
// Facts (Linux CI 27.5, 28.5, 29.0, identical; the Expanded Permission rows of the same sets also on the BC 29 SaaS sandbox, Y69ExpandedRows.al): the name of a moved
//   table binds to its one table id; a tabledata grant of it works (all four operations under RIMD, read under R, only the grant's own letters), table
//   grants give Execute on the table object, an included set grants through the outer set, an excluded set removes only the letters it names (excluding R
//   leaves insert, modify and delete), a lower case r gives no direct read, a permission set extension adds its tables, the Permissions property of a
//   codeunit gives indirect permission for the moved table. The reporter's set (Reason Code and Customer) grants the Customer read.
// Shape: observe/expect; every row is seeded before the mock and removed at the end; each operation ends in Error('LT Y69 ok').
// BC versions: 27, 28, 29
codeunit 93710 "LT Y69 Moved Tables"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT Y69 Helper";
        MockHelper: Codeunit "LT Y69 Mock Helper";
        Y19Helper: Codeunit "LT Y19 Perm Helper";
        Mock: Codeunit "Permissions Mock";

    [Test]
    procedure Y69_MV_ReporterShape()
    var
        Observer: Codeunit "Probe Observer";
        WasStarted: Boolean;
    begin
        Helper.SeedMoved();
        WasStarted := Y19Helper.StartMock(Mock);
        ObserveSet(Observer, 'LT Y69 MV Name');
        ObserveSet(Observer, 'LT Y69 MV Plain');
        Y19Helper.RestoreMock(Mock, WasStarted);
        Helper.CleanMoved();
        Observer.Expect('LT Y69 MV NAME|set', 'ok');
        Observer.Expect('LT Y69 MV NAME|customer_read|text', 'LT Y69 ok');
        Observer.Expect('LT Y69 MV NAME|customer_read|code', 'Dialog');
        Observer.Expect('LT Y69 MV NAME|reason_code_read_permission', 'Yes');
        Observer.Expect('LT Y69 MV NAME|reason_code_four_ops', 'oDDD');
        Observer.Expect('LT Y69 MV PLAIN|set', 'ok');
        Observer.Expect('LT Y69 MV PLAIN|customer_read|text', 'LT Y69 ok');
        Observer.Expect('LT Y69 MV PLAIN|customer_read|code', 'Dialog');
        Observer.Expect('LT Y69 MV PLAIN|reason_code_read_permission', 'No');
        Observer.Expect('LT Y69 MV PLAIN|reason_code_four_ops', 'DDDD');
        Observer.Verify();
    end;

    [Test]
    procedure Y69_MV_NameSetEveryTable()
    var
        Observer: Codeunit "Probe Observer";
        WasStarted: Boolean;
    begin
        Helper.SeedMoved();
        WasStarted := Y19Helper.StartMock(Mock);
        ObserveTables(Observer, 'LT Y69 MV Name');
        Y19Helper.RestoreMock(Mock, WasStarted);
        Helper.CleanMoved();
        Observer.Expect('LT Y69 MV NAME|customer', 'LT Y69 ok');
        Observer.Expect('LT Y69 MV NAME|231', 'oDDD');
        Observer.Expect('LT Y69 MV NAME|6635', 'DDDD');
        Observer.Expect('LT Y69 MV NAME|230', 'DDDD');
        Observer.Expect('LT Y69 MV NAME|242', 'DDDD');
        Observer.Expect('LT Y69 MV NAME|308', 'DDDD');
        Observer.Expect('LT Y69 MV NAME|309', 'DDDD');
        Observer.Expect('LT Y69 MV NAME|310', 'DDDD');
        Observer.Expect('LT Y69 MV NAME|1263', 'DDDD');
        Observer.Verify();
    end;

    [Test]
    procedure Y69_MV_AllSetEveryTable()
    var
        Observer: Codeunit "Probe Observer";
        WasStarted: Boolean;
    begin
        Helper.SeedMoved();
        WasStarted := Y19Helper.StartMock(Mock);
        ObserveTables(Observer, 'LT Y69 MV All');
        Y19Helper.RestoreMock(Mock, WasStarted);
        Helper.CleanMoved();
        Observer.Expect('LT Y69 MV ALL|customer', 'LT Y69 ok');
        Observer.Expect('LT Y69 MV ALL|231', 'oooo');
        Observer.Expect('LT Y69 MV ALL|6635', 'oooo');
        Observer.Expect('LT Y69 MV ALL|230', 'oooo');
        Observer.Expect('LT Y69 MV ALL|242', 'oooo');
        Observer.Expect('LT Y69 MV ALL|308', 'oooo');
        Observer.Expect('LT Y69 MV ALL|309', 'oooo');
        Observer.Expect('LT Y69 MV ALL|310', 'oooo');
        Observer.Expect('LT Y69 MV ALL|1263', 'oooo');
        Observer.Verify();
    end;

    [Test]
    procedure Y69_MV_IncludedAndExcludedSets()
    var
        Observer: Codeunit "Probe Observer";
        WasStarted: Boolean;
    begin
        Helper.SeedMoved();
        WasStarted := Y19Helper.StartMock(Mock);
        ObserveTables(Observer, 'LT Y69 MV Outer');
        ObserveTables(Observer, 'LT Y69 MV Excl');
        Y19Helper.RestoreMock(Mock, WasStarted);
        Helper.CleanMoved();
        Observer.Expect('LT Y69 MV OUTER|customer', 'LT Y69 ok');
        Observer.Expect('LT Y69 MV OUTER|231', 'DDDD');
        Observer.Expect('LT Y69 MV OUTER|6635', 'oDDD');
        Observer.Expect('LT Y69 MV OUTER|230', 'DDDD');
        Observer.Expect('LT Y69 MV OUTER|242', 'DDDD');
        Observer.Expect('LT Y69 MV OUTER|308', 'DDDD');
        Observer.Expect('LT Y69 MV OUTER|309', 'DDDD');
        Observer.Expect('LT Y69 MV OUTER|310', 'DDDD');
        Observer.Expect('LT Y69 MV OUTER|1263', 'DDDD');
        Observer.Expect('LT Y69 MV EXCL|customer', 'Sorry, the current permissions prevented the action. (TableData 18 Customer Read: AL Language Coverage Tests)');
        Observer.Expect('LT Y69 MV EXCL|231', 'DoDD');
        Observer.Expect('LT Y69 MV EXCL|6635', 'oooo');
        Observer.Expect('LT Y69 MV EXCL|230', 'oooo');
        Observer.Expect('LT Y69 MV EXCL|242', 'oooo');
        Observer.Expect('LT Y69 MV EXCL|308', 'oooo');
        Observer.Expect('LT Y69 MV EXCL|309', 'oooo');
        Observer.Expect('LT Y69 MV EXCL|310', 'oooo');
        Observer.Expect('LT Y69 MV EXCL|1263', 'oooo');
        Observer.Verify();
    end;

    [Test]
    procedure Y69_MV_ExtensionAndIndirect()
    var
        Observer: Codeunit "Probe Observer";
        WasStarted: Boolean;
    begin
        Helper.SeedMoved();
        WasStarted := Y19Helper.StartMock(Mock);
        ObserveTables(Observer, 'LT Y69 MV Ext Base');
        ObserveTables(Observer, 'LT Y69 MV Indirect');
        Y19Helper.RestoreMock(Mock, WasStarted);
        Helper.CleanMoved();
        Observer.Expect('LT Y69 MV EXT BASE|customer', 'LT Y69 ok');
        Observer.Expect('LT Y69 MV EXT BASE|231', 'DDDD');
        Observer.Expect('LT Y69 MV EXT BASE|6635', 'DDDD');
        Observer.Expect('LT Y69 MV EXT BASE|230', 'oDDD');
        Observer.Expect('LT Y69 MV EXT BASE|242', 'DDDD');
        Observer.Expect('LT Y69 MV EXT BASE|308', 'DDDD');
        Observer.Expect('LT Y69 MV EXT BASE|309', 'DDDD');
        Observer.Expect('LT Y69 MV EXT BASE|310', 'DDDD');
        Observer.Expect('LT Y69 MV EXT BASE|1263', 'oooo');
        Observer.Expect('LT Y69 MV INDIRECT|customer', 'LT Y69 ok');
        Observer.Expect('LT Y69 MV INDIRECT|231', 'DDDD');
        Observer.Expect('LT Y69 MV INDIRECT|6635', 'DDDD');
        Observer.Expect('LT Y69 MV INDIRECT|230', 'DDDD');
        Observer.Expect('LT Y69 MV INDIRECT|242', 'DDDD');
        Observer.Expect('LT Y69 MV INDIRECT|308', 'DDDD');
        Observer.Expect('LT Y69 MV INDIRECT|309', 'DDDD');
        Observer.Expect('LT Y69 MV INDIRECT|310', 'DDDD');
        Observer.Expect('LT Y69 MV INDIRECT|1263', 'DDDD');
        Observer.Verify();
    end;

    [Test]
    procedure Y69_MV_EffectivePermissionAndPermissionsProperty()
    var
        Observer: Codeunit "Probe Observer";
        Writer: Codeunit "LT Y69 MV Writer";
        WasStarted: Boolean;
        i: Integer;
    begin
        Helper.SeedMoved();
        WasStarted := Y19Helper.StartMock(Mock);
        Mock.Set('LT Y69 MV All');
        for i := 1 to Helper.MovedTableCount() do begin
            Observer.Observe('all_tabledata_' + Format(Helper.MovedTableId(i)), Y19Helper.Rights(0, Helper.MovedTableId(i)));
            Observer.Observe('all_table_' + Format(Helper.MovedTableId(i)), Y19Helper.Rights(1, Helper.MovedTableId(i)));
        end;
        Mock.ClearAssignments();
        Helper.SeedMoved();
        Mock.Set('LT Y69 MV Plain');
        ClearLastError();
        asserterror Writer.InsertReason();
        Observer.ObserveError('plain_writer_insert_reason');
        Mock.ClearAssignments();
        Helper.SeedMoved();
        Mock.Set('LT Y69 MV Plain');
        asserterror Writer.DeleteSeries();
        Observer.ObserveError('plain_writer_delete_series');
        Y19Helper.RestoreMock(Mock, WasStarted);
        Helper.CleanMoved();
        Observer.Expect('all_tabledata_231', 'Yes,Yes,Yes,Yes, ');
        Observer.Expect('all_table_231', ' , , , ,Yes');
        Observer.Expect('all_tabledata_6635', 'Yes,Yes,Yes,Yes, ');
        Observer.Expect('all_table_6635', ' , , , ,Yes');
        Observer.Expect('all_tabledata_230', 'Yes,Yes,Yes,Yes, ');
        Observer.Expect('all_table_230', ' , , , ,Yes');
        Observer.Expect('all_tabledata_242', 'Yes,Yes,Yes,Yes, ');
        Observer.Expect('all_table_242', ' , , , ,Yes');
        Observer.Expect('all_tabledata_308', 'Yes,Yes,Yes,Yes, ');
        Observer.Expect('all_table_308', ' , , , ,Yes');
        Observer.Expect('all_tabledata_309', 'Yes,Yes,Yes,Yes, ');
        Observer.Expect('all_table_309', ' , , , ,Yes');
        Observer.Expect('all_tabledata_310', 'Yes,Yes,Yes,Yes, ');
        Observer.Expect('all_table_310', ' , , , ,Yes');
        Observer.Expect('all_tabledata_1263', 'Yes,Yes,Yes,Yes, ');
        Observer.Expect('all_table_1263', ' , , , ,Yes');
        Observer.Expect('plain_writer_insert_reason|text', 'Sorry, the current permissions prevented the action. (TableData 231 Reason Code IndirectInsert: AL Language Coverage Tests)');
        Observer.Expect('plain_writer_insert_reason|code', 'DB:ClientInsertDenied');
        Observer.Expect('plain_writer_delete_series|text', 'Sorry, the current permissions prevented the action. (TableData 308 No. Series IndirectDelete: AL Language Coverage Tests)');
        Observer.Expect('plain_writer_delete_series|code', 'DB:ClientDeleteDenied');
        Observer.Verify();
    end;

    local procedure ObserveSet(var Observer: Codeunit "Probe Observer"; SetName: Code[20])
    var
        Customer: Record Customer;
    begin
        Mock.ClearAssignments();
        ClearLastError();
        if not TrySet(SetName) then begin
            Observer.Observe(SetName + '|set', 'failed: ' + GetLastErrorText());
            Observer.Observe(SetName + '|set_code', GetLastErrorCode());
            ClearLastError();
            exit;
        end;
        Observer.Observe(SetName + '|set', 'ok');
        asserterror begin
            if Customer.FindFirst() then;
            Error('LT Y69 ok');
        end;
        Observer.ObserveError(SetName + '|customer_read');
        Observer.Observe(SetName + '|reason_code_read_permission', Format(ReadPermissionOf(Database::"Reason Code")));
        Observer.Observe(SetName + '|reason_code_four_ops', MockHelper.FourOps(SetName, Database::"Reason Code"));
        Mock.ClearAssignments();
    end;

    // The four operations on each moved table under one set.
    local procedure ObserveTables(var Observer: Codeunit "Probe Observer"; SetName: Code[20])
    var
        i: Integer;
        Customer: Record Customer;
    begin
        Mock.ClearAssignments();
        ClearLastError();
        if not TrySet(SetName) then begin
            Observer.Observe(SetName + '|set', 'failed: ' + GetLastErrorText());
            ClearLastError();
            exit;
        end;
        asserterror begin
            if Customer.FindFirst() then;
            Error('LT Y69 ok');
        end;
        Observer.Observe(SetName + '|customer', GetLastErrorText());
        ClearLastError();
        for i := 1 to Helper.MovedTableCount() do
            Observer.Observe(SetName + '|' + Format(Helper.MovedTableId(i)), MockHelper.FourOps(SetName, Helper.MovedTableId(i)));
        Mock.ClearAssignments();
    end;

    [TryFunction]
    local procedure TrySet(SetName: Code[20])
    begin
        Mock.Set(SetName);
    end;

    local procedure ReadPermissionOf(TableId: Integer): Boolean
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(TableId);
        exit(RecRef.ReadPermission());
    end;
}
