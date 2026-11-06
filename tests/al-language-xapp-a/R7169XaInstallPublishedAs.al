// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extension-install-code
// Scope: in-scope
// Fixtures used: none.
// Probe: al-runner issue 7169 (MortenRa). XApp A is a dependency app of the main test app, published by "AL Language" (not Microsoft), through the
//   dev endpoint like every corpus app (ci.yml app_dirs). Its install code reads column "Published As" of "NAV App Installed App" for itself,
//   for Base Application and through the filter the issue uses (Publisher + "Published As"), and logs the texts. The test
//   LT R7169 Dep Install Published As (tests/al-language/record/lt-r7142-installed-app/) reads the log back.
// Install code must never fail (check-install-triggers.py): every read is in a TryFunction (an error becomes a log text), every write is
//   `if Insert() then;` into a DataPerCompany = false table.

table 96080 "LT R7169 XA Install Log"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; Entry; Text[100]) { }
        field(2; Detail; Text[250]) { }
    }

    keys { key(PK; Entry) { Clustered = true; } }
}

codeunit 96081 "LT R7169 XA Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        ThisModule: ModuleInfo;
        Value: Text;
    begin
        NavApp.GetCurrentModuleInfo(ThisModule);
        if TryPublishedAs(ThisModule.Id(), Value) then
            Log('own', Value)
        else
            Log('own', 'error: ' + GetLastErrorText());
        if TryPublishedAs('{437dbf0e-84ff-417a-965d-ed2bb9650972}', Value) then
            Log('base_application', Value)
        else
            Log('base_application', 'error: ' + GetLastErrorText());
        if TryFilterCount('AL Language', true, Value) then
            Log('filter_publisher_al_language_global_count', Value)
        else
            Log('filter_publisher_al_language_global_count', 'error: ' + GetLastErrorText());
        if TryFilterCount('AL Language', false, Value) then
            Log('filter_publisher_al_language_dev_count', Value)
        else
            Log('filter_publisher_al_language_dev_count', 'error: ' + GetLastErrorText());
    end;

    [TryFunction]
    local procedure TryPublishedAs(AppId: Guid; var Result: Text)
    var
        Row: Record "NAV App Installed App";
    begin
        if not Row.Get(AppId) then begin
            Result := 'no row';
            exit;
        end;
        Result := Format(Row."Published As") + '|' + Format(Row."Published As", 0, 2);
    end;

    [TryFunction]
    local procedure TryFilterCount(PublisherName: Text; GlobalApps: Boolean; var Result: Text)
    var
        Row: Record "NAV App Installed App";
    begin
        Row.SetRange(Publisher, PublisherName);
        if GlobalApps then
            Row.SetRange("Published As", Row."Published As"::Global)
        else
            Row.SetRange("Published As", Row."Published As"::Dev);
        Result := Format(Row.Count());
    end;

    local procedure Log(Name: Text; Value: Text)
    var
        Entry: Record "LT R7169 XA Install Log";
    begin
        Entry.Entry := CopyStr(Name, 1, MaxStrLen(Entry.Entry));
        Entry.Detail := CopyStr(Value, 1, MaxStrLen(Entry.Detail));
        if Entry.Insert() then;
    end;
}
