// Cross-app fixture A: NavApp.LoadPackageData of a table in the install part that does not match its DataPerCompany (al-runner issue 6649).
// The file TAB97991.navxdata in this folder (same layout as Y85XaPackageData.al: key "No." then Description, two rows) is loaded by the install
// codeunit below. The other half of the question (a per-company table loaded from OnInstallAppPerDatabase) cannot be a fixture: on BC 29.0 the load
// fails the publish of the whole app with "Cannot access destination table", and no TryFunction catches it (see the pull request).

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

// Case 2 (company part, shared table): OnInstallAppPerCompany runs once per company. The load runs only in the first company that reaches the
// trigger: a marker row in the log is read back in every later company, so the load cannot run twice. Inside a TryFunction, outcome logged after.
codeunit 97998 "LT PkgParts Install Co"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        Log: Record "LT PkgParts Log";
        Ok: Boolean;
    begin
        Log.SetRange(Part, 'company');
        Log.SetRange(Subject, 'shared table');
        if not Log.IsEmpty() then begin
            Log.Init();
            Log.Part := 'company-later';
            Log.Subject := 'shared table';
            Log.Detail := 'no load';
            if Log.Insert() then;
            exit;
        end;
        Ok := TryLoad();
        Log.Init();
        Log.Part := 'company';
        Log.Subject := 'shared table';
        if Ok then
            Log.Detail := 'load returned'
        else
            Log.Detail := CopyStr('load failed: ' + GetLastErrorText(), 1, MaxStrLen(Log.Detail));
        if Log.Insert() then;
    end;

    [TryFunction]
    local procedure TryLoad()
    begin
        NavApp.LoadPackageData(Database::"LT PkgParts Shared");
    end;
}
