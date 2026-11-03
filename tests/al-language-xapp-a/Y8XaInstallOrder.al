// Install-order probe of cross-app fixture A (writer Y8, al-runtime-rs docs/probes-needed.md install-order leftovers).
// Each of the fixtures A, D and B logs, from its OnInstallAppPerDatabase trigger, which rows of table 61180 it sees, and then writes its own row
// with Insert(true). Fixture B's table extension of 61180 (Y8XbInstallOrder.al) appends '+BX' to Note in OnBeforeInsert, so a row's Note shows
// whether B's extension trigger ran when that row was written. D does not depend on B and B does not depend on D (no dependency path).
// The test "LT Y8 Install Order Tests" (91420, tests/al-language/install/lt-y8-install-order/) reads the rows back.
// Install code must never fail (check-install-triggers.py): every write is `if Insert(..) then;` into a DataPerCompany = false table, and the only
// trigger that runs on these inserts (B's OnBeforeInsert) only appends text.

table 61180 "LT Y8 XA Data"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; "No."; Integer) { }
        field(2; Note; Text[50]) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

table 61181 "LT Y8 XA Install Log"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; Seq; Integer) { AutoIncrement = true; }
        field(2; App; Text[10]) { }
        field(3; Seen; Text[250]) { }
    }

    keys { key(PK; Seq) { Clustered = true; } }
}

codeunit 61182 "LT Y8 XA Install Helper"
{
    procedure SeenRows(): Text
    var
        Data: Record "LT Y8 XA Data";
        Result: Text;
    begin
        if Data.FindSet() then
            repeat
                Result += Format(Data."No.") + '=' + Data.Note + ';';
            until Data.Next() = 0;
        exit(Result);
    end;

    procedure LogAndWrite(App: Text; RowNo: Integer)
    var
        Log: Record "LT Y8 XA Install Log";
        Data: Record "LT Y8 XA Data";
    begin
        Log.Init();
        Log.App := CopyStr(App, 1, MaxStrLen(Log.App));
        Log.Seen := CopyStr(SeenRows(), 1, MaxStrLen(Log.Seen));
        if Log.Insert() then;
        Data.Init();
        Data."No." := RowNo;
        Data.Note := CopyStr(App, 1, 10);
        if Data.Insert(true) then;
    end;
}

codeunit 61183 "LT Y8 XA Install"
{
    Subtype = Install;

    trigger OnInstallAppPerDatabase()
    var
        Helper: Codeunit "LT Y8 XA Install Helper";
    begin
        Helper.LogAndWrite('A', 1);
    end;
}

// Writer Y79 (al-runner issues 6644 and 6755): the install code of A runs the probe of A's hub 61372, per database and per company (see
// tests/al-language-xapp-a/Y79XaObjects.al). Install code must never fail: every write is `if Insert(true) then;`, the Upgrade Tag calls only read.
codeunit 61376 "LT Y79 XA Install"
{
    Subtype = Install;

    trigger OnInstallAppPerDatabase()
    var
        Hub: Codeunit "LT Y79 XA Hub";
    begin
        Hub.Probe('A', 'db');
    end;

    trigger OnInstallAppPerCompany()
    var
        Hub: Codeunit "LT Y79 XA Hub";
    begin
        Hub.Probe('A', 'co');
    end;
}

// Writer Y85: loads the package data files of Y85XaPackageData.al (NavApp.LoadPackageData), each table only while it is empty.
codeunit 94449 "LT Y85 Pkg Install"

{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        Company: Record "LT Y85 Pkg Company";
        Types: Record "LT Y85 Pkg Types";
        Order: Record "LT Y85 Pkg Order";
        Auto: Record "LT Y85 Pkg Auto";
    begin
        if Company.IsEmpty() then
            NavApp.LoadPackageData(Database::"LT Y85 Pkg Company");
        if Types.IsEmpty() then
            NavApp.LoadPackageData(Database::"LT Y85 Pkg Types");
        if Order.IsEmpty() then
            NavApp.LoadPackageData(Database::"LT Y85 Pkg Order");
        if Auto.IsEmpty() then
            NavApp.LoadPackageData(Database::"LT Y85 Pkg Auto");
    end;

    trigger OnInstallAppPerDatabase()
    var
        Db: Record "LT Y85 Pkg Database";
    begin
        if Db.IsEmpty() then
            NavApp.LoadPackageData(Database::"LT Y85 Pkg Database");
    end;
}

// Writer Y88: loads the package data files of Y88XaPackageData.al. Every load runs in a TryFunction (a value the platform rejects must not fail the
// install); the error of a failed load goes to the log table, `if Insert() then;` is the only write. A table is loaded only while it is empty.
codeunit 94682 "LT Y88 Pkg Install"
{
    Subtype = Install;

    local procedure LoadOne(TableId: Integer; Name: Text)
    var
        Log: Record "LT Y88 Pkg Log";
        Ok: Boolean;
    begin
        Ok := TryLoad(TableId);
        Log.Kind := 'load';
        Log.Subject := CopyStr(Name, 1, 50);
        if Ok then
            Log.Detail := 'ok'
        else
            Log.Detail := CopyStr('error ' + GetLastErrorCode() + ': ' + GetLastErrorText(), 1, 250);
        if Log.Insert() then;
    end;

    [TryFunction]
    local procedure TryLoad(TableId: Integer)
    begin
        NavApp.LoadPackageData(TableId);
    end;

    trigger OnInstallAppPerCompany()
    var
        Events: Record "LT Y88 Pkg Events";
        Opt: Record "LT Y88 Pkg Option";
        Enm: Record "LT Y88 Pkg Enum Table";
        DateHigh: Record "LT Y88 Pkg Date High";
        DecHuge: Record "LT Y88 Pkg Dec Huge";
        DecTiny: Record "LT Y88 Pkg Dec Tiny";
    begin
        if Events.IsEmpty() then
            LoadOne(Database::"LT Y88 Pkg Events", 'events');
        if Opt.IsEmpty() then
            LoadOne(Database::"LT Y88 Pkg Option", 'option');
        if Enm.IsEmpty() then
            LoadOne(Database::"LT Y88 Pkg Enum Table", 'enum');
        if DateHigh.IsEmpty() then
            LoadOne(Database::"LT Y88 Pkg Date High", 'date high');
        if DecHuge.IsEmpty() then
            LoadOne(Database::"LT Y88 Pkg Dec Huge", 'decimal huge');
        if DecTiny.IsEmpty() then
            LoadOne(Database::"LT Y88 Pkg Dec Tiny", 'decimal tiny');
    end;
}
