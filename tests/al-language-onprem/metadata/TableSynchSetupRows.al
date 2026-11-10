// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: OnPrem app only: the Table Synch. Setup table (2000000135) has Scope = OnPrem, so a Target = Cloud app cannot name it
//   (must-not-compile case 0021) and a RecordRef from a Cloud app cannot open it.
// Fixtures used: Probe Observer (69160), ALT Universal (60000), both from the AL Language Coverage Tests app; own objects 98202-98208
//   (MD TableSync Log, MD TableSync Source, MD TableSync Target, MD TableSync Company Row, MD TableSync Reader, MD TableSync Install,
//   MD TableSync Tests)
// Probe: from al-runner issue 7582: an install codeunit calls Base Application's "Data Upgrade Mgt.".SetTableSyncSetup(Source table,
//   Target table, Force) in OnInstallAppPerDatabase. That procedure runs: if TableSynchSetup.Get(TableId) then set "Upgrade Table ID"
//   and Mode and Modify.
// Area: the rows of Table Synch. Setup for tables of an extension, and SetTableSyncSetup on them.
//   - At install (OnInstallAppPerDatabase and OnInstallAppPerCompany of this app): is there a row for a table of the app being
//     installed (DataPerCompany = false, and per company), what SetTableSyncSetup does, the row afterwards, and setting it back.
//     The install code logs into a DataPerCompany = false table; the test reads the log.
//     At install every read and every SetTableSyncSetup call runs in a TryFunction, because an install trigger that raises breaks the
//     publish of the app on every BC version. So the log says 'error:<code>|<text>' where the call raised, and a Modify that the
//     server refuses inside a TryFunction shows as that error. The call as a plain statement is measured at test time.
//   - At test time: the row for tables of this app, of the Cloud corpus app, of Base Application, for Table Synch. Setup itself, for
//     table id 0 and for an id with no table; IsEmpty; SetTableSyncSetup as a statement and in a TryFunction (a table with a row, an
//     id with no table), the row afterwards, setting it back; Modify of the row from this app.
//   Not measured: Insert and Delete on Table Synch. Setup (a Microsoft table; only the app's own row is changed and set back), and
//   the effect of a row on a later schema synchronisation.
// local object: the install codeunit must run at install, and the tests assert rows keyed by the ids of these tables.
// Observation form: every test ends in Finish(); the values are what BC produced.
// BC versions: 27.5, 28.5, 29.0 (measured by the corpus CI)

table 98202 "MD TableSync Log"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; Entry; Code[50]) { }
        field(2; Value; Text[1024]) { }
    }

    keys
    {
        key(PK; Entry) { Clustered = true; }
    }
}

table 98203 "MD TableSync Source"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; EntryNo; Integer) { }
    }

    keys
    {
        key(PK; EntryNo) { Clustered = true; }
    }
}

table 98204 "MD TableSync Target"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; EntryNo; Integer) { }
    }

    keys
    {
        key(PK; EntryNo) { Clustered = true; }
    }
}

table 98205 "MD TableSync Company Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; EntryNo; Integer) { }
    }

    keys
    {
        key(PK; EntryNo) { Clustered = true; }
    }
}

codeunit 98206 "MD TableSync Reader"
{
    [TryFunction]
    local procedure TryRead(TableId: Integer; var Result: Text)
    var
        Setup: Record "Table Synch. Setup";
    begin
        if Setup.Get(TableId) then
            Result := 'row: upgrade table ' + UpgradeTableName(Setup."Upgrade Table ID") + ', mode ' + Format(Setup.Mode)
        else
            Result := 'no row';
    end;

    local procedure UpgradeTableName(UpgradeTableId: Integer): Text
    begin
        case UpgradeTableId of
            0:
                exit('0');
            Database::"MD TableSync Source":
                exit('Source');
            Database::"MD TableSync Target":
                exit('Target');
        end;
        exit('other');
    end;

    [TryFunction]
    local procedure TrySet(TableId: Integer; UpgradeTableId: Integer; Mode: Option Check,Copy,Move,Force)
    var
        DataUpgradeMgt: Codeunit "Data Upgrade Mgt.";
    begin
        DataUpgradeMgt.SetTableSyncSetup(TableId, UpgradeTableId, Mode);
    end;

    [TryFunction]
    local procedure TryIsEmpty(var Result: Boolean)
    var
        Setup: Record "Table Synch. Setup";
    begin
        Result := Setup.IsEmpty();
    end;

    [TryFunction]
    local procedure TryCountFor(TableId: Integer; var Result: Integer)
    var
        Setup: Record "Table Synch. Setup";
    begin
        Setup.SetRange("Table ID", TableId);
        Result := Setup.Count();
    end;

    procedure Read(TableId: Integer): Text
    var
        Result: Text;
    begin
        ClearLastError();
        if TryRead(TableId, Result) then
            exit(Result);
        exit('error:' + GetLastErrorCode() + '|' + GetLastErrorText());
    end;

    procedure SetInTryFunction(TableId: Integer; UpgradeTableId: Integer; Mode: Option Check,Copy,Move,Force): Text
    begin
        ClearLastError();
        if TrySet(TableId, UpgradeTableId, Mode) then
            exit('ok');
        exit('error:' + GetLastErrorCode() + '|' + GetLastErrorText());
    end;

    procedure IsEmptyText(): Text
    var
        Result: Boolean;
    begin
        ClearLastError();
        if TryIsEmpty(Result) then
            exit(Format(Result));
        exit('error:' + GetLastErrorCode() + '|' + GetLastErrorText());
    end;

    procedure CountForText(TableId: Integer): Text
    var
        Result: Integer;
    begin
        ClearLastError();
        if TryCountFor(TableId, Result) then
            exit(Format(Result));
        exit('error:' + GetLastErrorCode() + '|' + GetLastErrorText());
    end;
}

codeunit 98207 "MD TableSync Install"
{
    Subtype = Install;

    trigger OnInstallAppPerDatabase()
    begin
        Steps('DB');
    end;

    trigger OnInstallAppPerCompany()
    begin
        Steps('CO');
    end;

    local procedure Steps(Prefix: Code[10])
    var
        Reader: Codeunit "MD TableSync Reader";
        Mode: Option Check,Copy,Move,Force;
    begin
        Log(Prefix + ' 1 SOURCE', Reader.Read(Database::"MD TableSync Source"));
        Log(Prefix + ' 2 TARGET', Reader.Read(Database::"MD TableSync Target"));
        Log(Prefix + ' 3 COMPANY ROW', Reader.Read(Database::"MD TableSync Company Row"));
        Log(Prefix + ' 4 SET', Reader.SetInTryFunction(Database::"MD TableSync Source", Database::"MD TableSync Target", Mode::Force));
        Log(Prefix + ' 5 SOURCE AFTER SET', Reader.Read(Database::"MD TableSync Source"));
        Log(Prefix + ' 6 SET BACK', Reader.SetInTryFunction(Database::"MD TableSync Source", 0, Mode::Check));
        Log(Prefix + ' 7 SOURCE AFTER SET BACK', Reader.Read(Database::"MD TableSync Source"));
    end;

    local procedure Log(Entry: Code[50]; Value: Text)
    var
        Row: Record "MD TableSync Log";
    begin
        Row.Entry := Entry;
        Row.Value := CopyStr(Value, 1, MaxStrLen(Row.Value));
        if Row.Insert() then;
    end;
}

codeunit 98208 "MD TableSync Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Logged(Entry: Code[50]): Text
    var
        Row: Record "MD TableSync Log";
    begin
        if Row.Get(Entry) then
            exit(Row.Value);
        exit('<no log row>');
    end;

    local procedure InstallSteps(var Observer: Codeunit "Probe Observer"; Prefix: Code[10])
    begin
        Observer.Observe('source', Logged(Prefix + ' 1 SOURCE'));
        Observer.Observe('target', Logged(Prefix + ' 2 TARGET'));
        Observer.Observe('company row', Logged(Prefix + ' 3 COMPANY ROW'));
        Observer.Observe('set', Logged(Prefix + ' 4 SET'));
        Observer.Observe('source after set', Logged(Prefix + ' 5 SOURCE AFTER SET'));
        Observer.Observe('set back', Logged(Prefix + ' 6 SET BACK'));
        Observer.Observe('source after set back', Logged(Prefix + ' 7 SOURCE AFTER SET BACK'));
    end;

    [Test]
    procedure TableSynchSetup_AtInstallPerDatabase()
    var
        Observer: Codeunit "Probe Observer";
    begin
        InstallSteps(Observer, 'DB');
        Observer.Expect('source', 'no row');
        Observer.Expect('target', 'no row');
        Observer.Expect('company row', 'no row');
        Observer.Expect('set', 'ok');
        Observer.Expect('source after set', 'no row');
        Observer.Expect('set back', 'ok');
        Observer.Expect('source after set back', 'no row');
        Observer.Verify();
    end;

    [Test]
    procedure TableSynchSetup_AtInstallPerCompany()
    var
        Observer: Codeunit "Probe Observer";
    begin
        InstallSteps(Observer, 'CO');
        Observer.Expect('source', 'no row');
        Observer.Expect('target', 'no row');
        Observer.Expect('company row', 'no row');
        Observer.Expect('set', 'ok');
        Observer.Expect('source after set', 'no row');
        Observer.Expect('set back', 'ok');
        Observer.Expect('source after set back', 'no row');
        Observer.Verify();
    end;

    [Test]
    procedure TableSynchSetup_RowsAtTestTime()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "MD TableSync Reader";
    begin
        Observer.Observe('isempty', Reader.IsEmptyText());
        Observer.Observe('source', Reader.Read(Database::"MD TableSync Source"));
        Observer.Observe('source count', Reader.CountForText(Database::"MD TableSync Source"));
        Observer.Observe('target', Reader.Read(Database::"MD TableSync Target"));
        Observer.Observe('company row', Reader.Read(Database::"MD TableSync Company Row"));
        Observer.Observe('log table', Reader.Read(Database::"MD TableSync Log"));
        Observer.Observe('cloud app table', Reader.Read(Database::"ALT Universal"));
        Observer.Observe('customer', Reader.Read(Database::Customer));
        Observer.Observe('table synch setup itself', Reader.Read(Database::"Table Synch. Setup"));
        Observer.Observe('id 0', Reader.Read(0));
        Observer.Observe('id with no table', Reader.Read(1999999999));
        Observer.Expect('isempty', 'Yes');
        Observer.Expect('source', 'no row');
        Observer.Expect('source count', '0');
        Observer.Expect('target', 'no row');
        Observer.Expect('company row', 'no row');
        Observer.Expect('log table', 'no row');
        Observer.Expect('cloud app table', 'no row');
        Observer.Expect('customer', 'no row');
        Observer.Expect('table synch setup itself', 'no row');
        Observer.Expect('id 0', 'no row');
        Observer.Expect('id with no table', 'no row');
        Observer.Verify();
    end;

    [Test]
    procedure SetTableSyncSetup_Statement_TableOfThisApp()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "MD TableSync Reader";
        DataUpgradeMgt: Codeunit "Data Upgrade Mgt.";
        Mode: Option Check,Copy,Move,Force;
    begin
        // The reported call, as a plain statement.
        Observer.Observe('before', Reader.Read(Database::"MD TableSync Source"));
        DataUpgradeMgt.SetTableSyncSetup(Database::"MD TableSync Source", Database::"MD TableSync Target", Mode::Force);
        Observer.Observe('after set', Reader.Read(Database::"MD TableSync Source"));
        Observer.Observe('target after set', Reader.Read(Database::"MD TableSync Target"));
        DataUpgradeMgt.SetTableSyncSetup(Database::"MD TableSync Source", 0, Mode::Check);
        Observer.Observe('after set back', Reader.Read(Database::"MD TableSync Source"));
        Observer.Expect('before', 'no row');
        Observer.Expect('after set', 'no row');
        Observer.Expect('target after set', 'no row');
        Observer.Expect('after set back', 'no row');
        Observer.Verify();
    end;

    [Test]
    procedure SetTableSyncSetup_Statement_EveryMode()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "MD TableSync Reader";
        DataUpgradeMgt: Codeunit "Data Upgrade Mgt.";
        Mode: Option Check,Copy,Move,Force;
    begin
        DataUpgradeMgt.SetTableSyncSetup(Database::"MD TableSync Source", Database::"MD TableSync Target", Mode::Copy);
        Observer.Observe('copy', Reader.Read(Database::"MD TableSync Source"));
        DataUpgradeMgt.SetTableSyncSetup(Database::"MD TableSync Source", Database::"MD TableSync Target", Mode::Move);
        Observer.Observe('move', Reader.Read(Database::"MD TableSync Source"));
        DataUpgradeMgt.SetTableSyncSetup(Database::"MD TableSync Source", Database::"MD TableSync Source", Mode::Check);
        Observer.Observe('check, itself as upgrade table', Reader.Read(Database::"MD TableSync Source"));
        DataUpgradeMgt.SetTableSyncSetup(Database::"MD TableSync Source", 1999999999, Mode::Check);
        Observer.Observe('check, upgrade table id with no table', Reader.Read(Database::"MD TableSync Source"));
        DataUpgradeMgt.SetTableSyncSetup(Database::"MD TableSync Source", 0, Mode::Check);
        Observer.Observe('after set back', Reader.Read(Database::"MD TableSync Source"));
        Observer.Expect('copy', 'no row');
        Observer.Expect('move', 'no row');
        Observer.Expect('check, itself as upgrade table', 'no row');
        Observer.Expect('check, upgrade table id with no table', 'no row');
        Observer.Expect('after set back', 'no row');
        Observer.Verify();
    end;

    [Test]
    procedure SetTableSyncSetup_Statement_IdWithNoTable()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "MD TableSync Reader";
        DataUpgradeMgt: Codeunit "Data Upgrade Mgt.";
        Mode: Option Check,Copy,Move,Force;
    begin
        DataUpgradeMgt.SetTableSyncSetup(1999999999, Database::"MD TableSync Target", Mode::Force);
        Observer.Observe('after set', Reader.Read(1999999999));
        Observer.Expect('after set', 'no row');
        Observer.Verify();
    end;

    [Test]
    procedure SetTableSyncSetup_TryFunction()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "MD TableSync Reader";
        Mode: Option Check,Copy,Move,Force;
    begin
        Observer.Observe('table of this app', Reader.SetInTryFunction(Database::"MD TableSync Source", Database::"MD TableSync Target", Mode::Force));
        Observer.Observe('after', Reader.Read(Database::"MD TableSync Source"));
        Observer.Observe('set back', Reader.SetInTryFunction(Database::"MD TableSync Source", 0, Mode::Check));
        Observer.Observe('after set back', Reader.Read(Database::"MD TableSync Source"));
        Observer.Observe('id with no table', Reader.SetInTryFunction(1999999999, Database::"MD TableSync Target", Mode::Force));
        Observer.Expect('table of this app', 'ok');
        Observer.Expect('after', 'no row');
        Observer.Expect('set back', 'ok');
        Observer.Expect('after set back', 'no row');
        Observer.Expect('id with no table', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure TableSynchSetup_ModifyFromThisApp()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "MD TableSync Reader";
        Setup: Record "Table Synch. Setup";
    begin
        if Setup.Get(Database::"MD TableSync Source") then begin
            Observer.Observe('get', 'row');
            Setup."Upgrade Table ID" := Database::"MD TableSync Target";
            Setup.Mode := Setup.Mode::Copy;
            Observer.Observe('modify', Format(Setup.Modify()));
            Observer.Observe('after modify', Reader.Read(Database::"MD TableSync Source"));
            Setup."Upgrade Table ID" := 0;
            Setup.Mode := Setup.Mode::Check;
            Observer.Observe('modify back', Format(Setup.Modify()));
            Observer.Observe('after modify back', Reader.Read(Database::"MD TableSync Source"));
        end else
            Observer.Observe('get', 'no row');
        Observer.Expect('get', 'no row');
        Observer.Verify();
    end;
}
