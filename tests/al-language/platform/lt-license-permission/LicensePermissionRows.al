// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: rows of the platform table License Permission (2000000043) for questions the earlier License Permission files do not answer:
// ledger tables that a license may grant only indirectly, Table rows next to TableData rows, negative object numbers, rows whose
// permission columns are only partly set, and object numbers of the system range (2000000000 and up) for every object type.
// A row is written as Read/Insert/Modify/Delete/Execute/Limited Usage, each Format(<column>, 0, 9): 0 = blank, 1 = Yes, 2 = Indirect.
// Object types are passed as the option ordinal of "Object Type" (0 TableData, 1 Table, 3 Report, 5 Codeunit, 6 XMLport,
// 7 MenuSuite, 8 Page, 9 Query, 10 System, 11 FieldNumber).
// Facts: see the Expect lines of each test.
// BC versions: 27-29

codeunit 90950 "LT Y4 LicPerm Rows"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Describe(ObjectType: Integer; ObjectNumber: Integer): Text
    var
        LicensePermission: Record "License Permission";
    begin
        if not LicensePermission.Get(ObjectType, ObjectNumber) then
            exit('no row');
        exit(RowText(LicensePermission));
    end;

    local procedure RowText(var LicensePermission: Record "License Permission"): Text
    begin
        exit(Format(LicensePermission."Read Permission", 0, 9) + '/' + Format(LicensePermission."Insert Permission", 0, 9) + '/' +
            Format(LicensePermission."Modify Permission", 0, 9) + '/' + Format(LicensePermission."Delete Permission", 0, 9) + '/' +
            Format(LicensePermission."Execute Permission", 0, 9) + '/' + Format(LicensePermission."Limited Usage Permission", 0, 9));
    end;

    local procedure Ids(var LicensePermission: Record "License Permission"; MaxRows: Integer): Text
    var
        Result: Text;
        Taken: Integer;
    begin
        if LicensePermission.FindSet() then
            repeat
                Result += Format(LicensePermission."Object Number") + ',';
                Taken += 1;
            until (LicensePermission.Next() = 0) or (Taken >= MaxRows);
        exit(Result);
    end;

    // Ledger and register tables: a license can grant these indirectly (for example Insert on G/L Entry 17).
    [Test]
    procedure LicensePermission_LedgerTables_TableData()
    var
        Observer: Codeunit "Probe Observer";
        Numbers: List of [Integer];
        N: Integer;
    begin
        Numbers.AddRange(17, 21, 25, 32, 45, 169, 203, 254, 271, 379, 380, 5802, 5625, 7312);
        foreach N in Numbers do
            Observer.Observe('tabledata_' + Format(N), Describe(0, N));
        Observer.Observe('table_17', Describe(1, 17));
        Observer.Observe('table_32', Describe(1, 32));
        Observer.Finish();
    end;

    // The caption Format gives for each column of one row (Format without a format number).
    [Test]
    procedure LicensePermission_GLEntry_Captions()
    var
        Observer: Codeunit "Probe Observer";
        LicensePermission: Record "License Permission";
    begin
        LicensePermission.Get(LicensePermission."Object Type"::TableData, 17);
        Observer.Observe('type', Format(LicensePermission."Object Type"));
        Observer.Observe('read', Format(LicensePermission."Read Permission"));
        Observer.Observe('insert', Format(LicensePermission."Insert Permission"));
        Observer.Observe('modify', Format(LicensePermission."Modify Permission"));
        Observer.Observe('delete', Format(LicensePermission."Delete Permission"));
        Observer.Observe('execute', Format(LicensePermission."Execute Permission"));
        Observer.Observe('limited', Format(LicensePermission."Limited Usage Permission"));
        Observer.Finish();
    end;

    // Which TableData rows in 1..2000 have an Indirect value in a column (filter on the column).
    [Test]
    procedure LicensePermission_IndirectRows_Filter()
    var
        Observer: Codeunit "Probe Observer";
        LicensePermission: Record "License Permission";
    begin
        LicensePermission.SetRange("Object Type", LicensePermission."Object Type"::TableData);
        LicensePermission.SetRange("Object Number", 1, 2000);
        LicensePermission.SetRange("Insert Permission", LicensePermission."Insert Permission"::Indirect);
        Observer.Observe('insert_indirect_ids', Ids(LicensePermission, 30));
        LicensePermission.SetRange("Insert Permission");
        LicensePermission.SetRange("Read Permission", LicensePermission."Read Permission"::Indirect);
        Observer.Observe('read_indirect_ids', Ids(LicensePermission, 30));
        LicensePermission.SetRange("Read Permission");
        LicensePermission.SetRange("Modify Permission", LicensePermission."Modify Permission"::Indirect);
        Observer.Observe('modify_indirect_ids', Ids(LicensePermission, 30));
        LicensePermission.SetRange("Modify Permission");
        LicensePermission.SetRange("Delete Permission", LicensePermission."Delete Permission"::Indirect);
        Observer.Observe('delete_indirect_ids', Ids(LicensePermission, 30));
        Observer.Finish();
    end;

    // Table and TableData rows for the same number side by side.
    [Test]
    procedure LicensePermission_TableVsTableData()
    var
        Observer: Codeunit "Probe Observer";
        Numbers: List of [Integer];
        N: Integer;
    begin
        Numbers.AddRange(1, 17, 18, 27, 9999, 50000, 99999, 100000, 1000000, 70000000, 99999999, 100000000, 2000000001, 2000000004, 2000000043);
        foreach N in Numbers do
            Observer.Observe(Format(N), 'table=' + Describe(1, N) + ' tabledata=' + Describe(0, N));
        Observer.Finish();
    end;

    // Negative object numbers: Get and a range around zero.
    [Test]
    procedure LicensePermission_NegativeNumbers()
    var
        Observer: Codeunit "Probe Observer";
        LicensePermission: Record "License Permission";
    begin
        Observer.Observe('codeunit_-1', Describe(5, -1));
        Observer.Observe('tabledata_-1', Describe(0, -1));
        Observer.Observe('table_-5', Describe(1, -5));
        Observer.Observe('system_-1', Describe(10, -1));
        Observer.Observe('page_-2147483647', Describe(8, -2147483647));
        LicensePermission.SetRange("Object Type", LicensePermission."Object Type"::Codeunit);
        LicensePermission.SetRange("Object Number", -3, 3);
        Observer.Observe('codeunit_-3_3_ids', Ids(LicensePermission, 20));
        LicensePermission.SetRange("Object Number", -10, -1);
        Observer.Observe('codeunit_-10_-1_count', Format(LicensePermission.Count()));
        LicensePermission.SetRange("Object Type", LicensePermission."Object Type"::TableData);
        LicensePermission.SetRange("Object Number", -2, 2);
        Observer.Observe('tabledata_-2_2_ids', Ids(LicensePermission, 20));
        Observer.Finish();
    end;

    // Rows whose columns are only partly set: System objects with Execute but no Read, in 1..99999.
    [Test]
    procedure LicensePermission_PartialRows_System()
    var
        Observer: Codeunit "Probe Observer";
        LicensePermission: Record "License Permission";
    begin
        LicensePermission.SetRange("Object Type", LicensePermission."Object Type"::System);
        LicensePermission.SetRange("Object Number", 1, 99999);
        LicensePermission.SetRange("Execute Permission", LicensePermission."Execute Permission"::Yes);
        LicensePermission.SetRange("Read Permission", LicensePermission."Read Permission"::" ");
        Observer.Observe('exec_noread_count', Format(LicensePermission.Count()));
        if LicensePermission.FindFirst() then
            Observer.Observe('exec_noread_first', Format(LicensePermission."Object Number") + '=' + RowText(LicensePermission));
        if LicensePermission.FindLast() then
            Observer.Observe('exec_noread_last', Format(LicensePermission."Object Number") + '=' + RowText(LicensePermission));
        LicensePermission.SetRange("Execute Permission");
        LicensePermission.SetRange("Read Permission", LicensePermission."Read Permission"::Yes);
        Observer.Observe('read_count', Format(LicensePermission.Count()));
        LicensePermission.SetRange("Read Permission", LicensePermission."Read Permission"::" ");
        LicensePermission.SetRange("Execute Permission", LicensePermission."Execute Permission"::" ");
        Observer.Observe('blank_count', Format(LicensePermission.Count()));
        if LicensePermission.FindFirst() then
            Observer.Observe('blank_first', Format(LicensePermission."Object Number"));
        Observer.Finish();
    end;

    // Rows whose columns are only partly set, any type in 1..99999: Read Yes with Delete blank, Execute Yes with Insert blank.
    [Test]
    procedure LicensePermission_PartialRows_ByType()
    var
        Observer: Codeunit "Probe Observer";
        LicensePermission: Record "License Permission";
        Types: List of [Integer];
        T: Integer;
    begin
        Types.AddRange(0, 1, 3, 5, 6, 8, 9);
        foreach T in Types do begin
            LicensePermission.Reset();
            LicensePermission.SetRange("Object Type", T);
            LicensePermission.SetRange("Object Number", 1, 99999);
            LicensePermission.SetRange("Read Permission", LicensePermission."Read Permission"::Yes);
            LicensePermission.SetRange("Delete Permission", LicensePermission."Delete Permission"::" ");
            Observer.Observe('type' + Format(T) + '_read_nodelete', Format(LicensePermission.Count()));
            LicensePermission.SetRange("Read Permission");
            LicensePermission.SetRange("Delete Permission");
            LicensePermission.SetRange("Execute Permission", LicensePermission."Execute Permission"::" ");
            Observer.Observe('type' + Format(T) + '_noexecute', Format(LicensePermission.Count()));
        end;
        Observer.Finish();
    end;
}

// The system range (2000000000 and up), one test per object type, at the same numbers.
codeunit 90951 "LT Y4 LicPerm System"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Describe(ObjectType: Integer; ObjectNumber: Integer): Text
    var
        LicensePermission: Record "License Permission";
    begin
        if not LicensePermission.Get(ObjectType, ObjectNumber) then
            exit('no row');
        exit(Format(LicensePermission."Read Permission", 0, 9) + '/' + Format(LicensePermission."Insert Permission", 0, 9) + '/' +
            Format(LicensePermission."Modify Permission", 0, 9) + '/' + Format(LicensePermission."Delete Permission", 0, 9) + '/' +
            Format(LicensePermission."Execute Permission", 0, 9) + '/' + Format(LicensePermission."Limited Usage Permission", 0, 9));
    end;

    local procedure ObserveSystemNumbers(var Observer: Codeunit "Probe Observer"; ObjectType: Integer)
    var
        Numbers: List of [Integer];
        N: Integer;
    begin
        Numbers.AddRange(2000000002, 2000000004, 2000000006, 2000000020, 2000000038, 2000000043, 2000000058, 2000000100);
        Numbers.AddRange(2000000150, 2000000200, 2000000500, 2000001000, 2000100000, 2099999999, 2100000000);
        foreach N in Numbers do
            Observer.Observe(Format(N), Describe(ObjectType, N));
    end;

    [Test]
    procedure SystemRange_TableData()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveSystemNumbers(Observer, 0);
        Observer.Finish();
    end;

    [Test]
    procedure SystemRange_Table()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveSystemNumbers(Observer, 1);
        Observer.Finish();
    end;

    [Test]
    procedure SystemRange_Report()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveSystemNumbers(Observer, 3);
        Observer.Finish();
    end;

    [Test]
    procedure SystemRange_Codeunit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveSystemNumbers(Observer, 5);
        Observer.Finish();
    end;

    [Test]
    procedure SystemRange_XMLport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveSystemNumbers(Observer, 6);
        Observer.Finish();
    end;

    [Test]
    procedure SystemRange_MenuSuite()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveSystemNumbers(Observer, 7);
        Observer.Observe('menusuite_1', Describe(7, 1));
        Observer.Finish();
    end;

    [Test]
    procedure SystemRange_Page()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveSystemNumbers(Observer, 8);
        Observer.Finish();
    end;

    [Test]
    procedure SystemRange_Query()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveSystemNumbers(Observer, 9);
        Observer.Finish();
    end;

    [Test]
    procedure SystemRange_System()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveSystemNumbers(Observer, 10);
        Observer.Observe('2000000000', Describe(10, 2000000000));
        Observer.Observe('2000000001', Describe(10, 2000000001));
        Observer.Finish();
    end;

    [Test]
    procedure SystemRange_FieldNumber()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveSystemNumbers(Observer, 11);
        Observer.Observe('fieldnumber_1', Describe(11, 1));
        Observer.Finish();
    end;

    // The first number without Execute and the last number with Execute in 2000000000..2000001000, per type (filter on the column).
    // A FindLast over the whole system range (up to 2147483647) did not finish in 5 minutes on the SaaS sandbox.
    [Test]
    procedure SystemRange_Bounds()
    var
        Observer: Codeunit "Probe Observer";
        LicensePermission: Record "License Permission";
        Types: List of [Integer];
        T: Integer;
    begin
        Types.AddRange(0, 1, 3, 5, 6, 8, 9, 10);
        foreach T in Types do begin
            LicensePermission.Reset();
            LicensePermission.SetRange("Object Type", T);
            LicensePermission.SetRange("Object Number", 2000000000, 2000001000);
            LicensePermission.SetRange("Execute Permission", LicensePermission."Execute Permission"::Yes);
            if LicensePermission.FindLast() then
                Observer.Observe('type' + Format(T) + '_last_exec', Format(LicensePermission."Object Number"))
            else
                Observer.Observe('type' + Format(T) + '_last_exec', 'none');
            LicensePermission.SetRange("Execute Permission", LicensePermission."Execute Permission"::" ");
            if LicensePermission.FindFirst() then
                Observer.Observe('type' + Format(T) + '_first_noexec', Format(LicensePermission."Object Number"))
            else
                Observer.Observe('type' + Format(T) + '_first_noexec', 'none');
        end;
        Observer.Finish();
    end;
}
