// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permission-set-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Y69PermSets.al (sets 93700-93708, extension 93707, writer 93709, helper 93735); Permissions Mock (131006).
// Probe (writer Y69, al-runner issue 6716 by SShadowS): permission sets that name a table BC 29 ships twice under one id (the Base Application's
//   ObsoleteState = Moved copy and the Business Foundation target): Reason Code 231, Return Reason 6635, Source Code 230, Source Code Setup 242,
//   No. Series 308, No. Series Line 309, No. Series Relationship 310, No. Series Tenant 1263. Which table the name binds to (Expanded Permission
//   rows of the set), whether the set grants it (read, insert, modify, delete of a seeded row under Permissions Mock.Set), the same through an
//   included set, an excluded set, a permission set extension, the Permissions property of a codeunit, and the reporter's shape (the set names
//   Reason Code and Customer; the read of Customer must work).
// Shape: observe/expect; every row is seeded before the mock and removed at the end; each operation ends in Error('LT Y69 ok').
// BC versions: 27, 28, 29
codeunit 93710 "LT Y69 Moved Tables"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT Y69 Helper";
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Mock.Set('LT Y69 MV Plain');
        ClearLastError();
        asserterror Writer.InsertReason();
        Observer.ObserveError('plain_writer_insert_reason');
        asserterror Writer.DeleteSeries();
        Observer.ObserveError('plain_writer_delete_series');
        Y19Helper.RestoreMock(Mock, WasStarted);
        Helper.CleanMoved();
        Observer.Finish();
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
        Observer.Observe(SetName + '|reason_code_four_ops', Helper.FourOps(Database::"Reason Code"));
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
            Observer.Observe(SetName + '|' + Format(Helper.MovedTableId(i)), Helper.FourOps(Helper.MovedTableId(i)));
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
