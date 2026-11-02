// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-triggers-and-events
// Scope: in-scope
// Fixtures used: Probe Observer (69160); cross-app fixtures tests/al-language-xapp-d/Y69XdTriggerSubs.al (61191) and tests/al-language-xapp-b/Y69XbTriggerSubs.al
//   (61357); the install sequence of Y8 (table 61181 "LT Y8 XA Install Log", tests/al-language-xapp-a/Y8XaInstallOrder.al) and table 61354
//   "LT Y64 XA Install Subs" as the note table.
// Probe (writer Y69, al-runner issue 6718 by SShadowS): two apps without a dependency path (B and D) and platform subscribers to
//   "Global Triggers".GetDatabaseTableTriggerSetup while the install code of A, D and B writes rows 1, 10 and 20 of A's table 61180 with Insert(true).
//   D's subscriber leaves every flag alone and notes each setup call and each OnDatabaseInsert for table 61180; B's subscriber (the form of the
//   issue) sets OnDatabaseInsert for that table. Does an unrelated subscriber that sets no flag change anything during an install (does the install code
//   still run to its end, is OnDatabaseInsert raised for rows written while only D is installed), and when does a flag set by an unrelated app take effect?
// The corpus CI publishes A, D, B (ci.yml app_dirs); other hosts install B before D (the SaaS sandbox run order A, B, D). So the facts are
//   asserted as relations to the install sequence the Y8 log records.
// BC versions: 27 - 29
codeunit 93712 "LT Y69 Install Trigger Setup"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure SeqOf(App: Text): Integer
    var
        Log: Record "LT Y8 XA Install Log";
    begin
        Log.SetRange(App, App);
        if Log.FindFirst() then
            exit(Log.Seq);
        exit(-1);
    end;

    local procedure Notes(): Text
    var
        Row: Record "LT Y64 XA Install Subs";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                if Row.Tag.StartsWith('Y69|') then
                    Result += Row.Tag + ' ## ';
            until Row.Next() = 0;
        exit(Result);
    end;

    local procedure RowsB(): Text
    var
        Row: Record "LT Y69 XB Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Format(Row."No.") + ';';
            until Row.Next() = 0;
        exit(Result);
    end;

    [Test]
    procedure Y69_InstallTriggerSetup_Observed()
    var
        Observer: Codeunit "Probe Observer";
        Data: Record "LT Y8 XA Data";
        RowB: Record "LT Y69 XB Row";
        AtStart: Text;
    begin
        Observer.Observe('seq', 'A=' + Format(SeqOf('A')) + ' D=' + Format(SeqOf('D')) + ' B=' + Format(SeqOf('B')));
        Observer.Observe('rows', Format(Data.Count()));
        Observer.Observe('rows_b', Format(RowsB()));
        AtStart := Notes();
        Observer.Observe('notes_after_install', AtStart);
        // The same subscribers in a test session (after the installs): a row inserted with Insert(true) into A's table 61180 and into B's table 61358.
        Data.Init();
        Data."No." := 9969;
        Data.Insert(true);
        Observer.Observe('notes_after_insert_61180', Notes());
        RowB.Init();
        RowB."No." := 9970;
        RowB.Insert(true);
        Observer.Observe('notes_after_insert_61358', Notes());
        Data.Delete();
        RowB.SetFilter("No.", '9969..9970');
        RowB.DeleteAll();
        Observer.Finish();
    end;
}
