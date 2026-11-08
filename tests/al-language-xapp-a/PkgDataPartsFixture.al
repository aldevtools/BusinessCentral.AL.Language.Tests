// Cross-app fixture A: NavApp.LoadPackageData of a table in the install part that does not match its DataPerCompany (al-runner issue 6649).
// The files TAB97990.navxdata and TAB97991.navxdata in this folder (same layout as Y85XaPackageData.al: key "No." then Description, two rows
// each) are loaded by the install codeunit 97999 below: the per-company table 97990 from OnInstallAppPerDatabase, and the shared table 97991
// (DataPerCompany = false) from OnInstallAppPerCompany. Each load runs in a TryFunction; its result goes to the shared log 97992 with
// `if Insert() then;` only. The tests are in tests/al-language/install-upgrade/install-triggers/PkgDataParts.al.

table 97992 "LT PkgParts Log"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; Id; Integer) { AutoIncrement = true; }
        field(2; Part; Text[20]) { }
        field(3; Subject; Text[50]) { }
        field(4; Detail; Text[250]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 97990 "LT PkgParts Company"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Description; Text[30]) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 97991 "LT PkgParts Shared"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Description; Text[30]) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 97999 "LT PkgParts Install"
{
    Subtype = Install;

    local procedure LoadOne(TableId: Integer; PartName: Text; Name: Text)
    var
        Log: Record "LT PkgParts Log";
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := TryLoad(TableId);
        Log.Part := CopyStr(PartName, 1, 20);
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

    trigger OnInstallAppPerDatabase()
    begin
        LoadOne(Database::"LT PkgParts Company", 'database', 'company table');
    end;

    trigger OnInstallAppPerCompany()
    var
        Shared: Record "LT PkgParts Shared";
        Log: Record "LT PkgParts Log";
    begin
        if Shared.IsEmpty() then
            LoadOne(Database::"LT PkgParts Shared", 'company', 'shared table')
        else begin
            Log.Part := 'company';
            Log.Subject := 'shared table';
            Log.Detail := 'skipped, it had rows';
            if Log.Insert() then;
        end;
    end;
}
