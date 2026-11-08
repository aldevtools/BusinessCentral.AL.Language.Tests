// Cross-app fixture A: NavApp.LoadPackageData of a table in the install part that does not match its DataPerCompany (al-runner issue 6649).
// The files TAB97990.navxdata and TAB97991.navxdata in this folder (same layout as Y85XaPackageData.al: key "No." then Description, two rows
// each) are loaded by the install // Case 1 (database part, per-company table): OnInstallAppPerDatabase runs once per install, so the load cannot repeat.
codeunit 97999 "LT PkgParts Install"
{
    Subtype = Install;

    trigger OnInstallAppPerDatabase()
    var
        Log: Record "LT PkgParts Log";
    begin
        Log.Part := 'database';
        Log.Subject := 'company table';
        Log.Detail := 'load called';
        if Log.Insert() then;
        NavApp.LoadPackageData(Database::"LT PkgParts Company");
    end;
}

// Case 2 (company part, shared table): OnInstallAppPerCompany runs once per company. The first version of this probe guarded the load with
// IsEmpty() of the shared table, and the install of 'My Company' failed with a duplicate key (S1) in the shared table: the guard did not stop a
// second load. Now the load runs only in the first company that reaches the trigger: the marker row in the log is inserted before the load and
// read back in every later company, so the load cannot run twice.
codeunit 97998 "LT PkgParts Install Co"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        Log: Record "LT PkgParts Log";
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
        Log.Init();
        Log.Part := 'company';
        Log.Subject := 'shared table';
        Log.Detail := 'load called';
        if Log.Insert() then;
        NavApp.LoadPackageData(Database::"LT PkgParts Shared");
    end;
}
