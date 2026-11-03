// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: the text and the code of the error that AL raises when it writes to the read-only system table Windows Language (2000000045),
// with and without triggers. License Permission, Language Selection, Table Information and Report Layout List are pinned in
// platform/lt-platform-tables/PtCloudTables.al and onprem platform/PtOnPremTables.al.
// BC versions: 27-29

codeunit 78403 "LT AG Platform Read Only"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure WindowsLanguage_Writes_AreRefused()
    var
        WindowsLanguage: Record "Windows Language";
        Observer: Codeunit "Probe Observer";
    begin
        WindowsLanguage."Language ID" := 99999;
        WindowsLanguage.Name := 'LT AG Language';
        WindowsLanguage."Language Tag" := 'lt-AG';
        WindowsLanguage."Abbreviated Name" := 'LTA';
        asserterror WindowsLanguage.Insert();
        Observer.ObserveError('insert');
        asserterror WindowsLanguage.Insert(true);
        Observer.ObserveError('insert_trigger');
        WindowsLanguage.Get(1033);
        WindowsLanguage.Name := 'changed';
        asserterror WindowsLanguage.Modify();
        Observer.ObserveError('modify');
        asserterror WindowsLanguage.Delete();
        Observer.ObserveError('delete');
        Clear(WindowsLanguage);
        asserterror WindowsLanguage.DeleteAll();
        Observer.ObserveError('delete_all');
        WindowsLanguage.Get(1033);
        Observer.Observe('name_after', WindowsLanguage.Name);
        Observer.Observe('has_99999', Format(WindowsLanguage.Get(99999)));
        Observer.Expect('insert|text', 'The Windows Language table is read-only.');
        Observer.Expect('insert|code', 'DB:Ok');
        Observer.Expect('insert_trigger|text', 'The Windows Language table is read-only.');
        Observer.Expect('insert_trigger|code', 'DB:Ok');
        Observer.Expect('modify|text', 'The Windows Language table is read-only.');
        Observer.Expect('modify|code', 'DB:Ok');
        Observer.Expect('delete|text', 'The Windows Language table is read-only.');
        Observer.Expect('delete|code', 'DB:Ok');
        Observer.Expect('delete_all|text', 'The Windows Language table is read-only.');
        Observer.Expect('delete_all|code', 'DB:Ok');
        Observer.Expect('name_after', 'English (United States)');
        Observer.Expect('has_99999', 'No');
        Observer.Verify();
    end;
}
