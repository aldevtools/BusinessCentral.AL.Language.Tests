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

    local procedure CountOf(Text: Text; Part: Text): Integer
    var
        Rest: Text;
        Count: Integer;
        Pos: Integer;
    begin
        Rest := Text;
        Pos := StrPos(Rest, Part);
        while Pos > 0 do begin
            Count += 1;
            Rest := CopyStr(Rest, Pos + StrLen(Part));
            Pos := StrPos(Rest, Part);
        end;
        exit(Count);
    end;

    // What the install code, the table extension triggers of B and D and the subscribers of B and D left behind. B has no dependency path to D. The
    // notes are 'Y69|...' tags in table 61354 of A. Measured on the SaaS sandbox (BC 29, Windows) with the install order A, B, D and A, D, B.
    [Test]
    procedure Y69_InstallTriggerSetup_NothingConsultedDuringInstall()
    var
        Observer: Codeunit "Probe Observer";
        Data: Record "LT Y8 XA Data";
        BBeforeD: Boolean;
        ExpectedExt: Text;
        ExpectedRowsB: Text;
    begin
        BBeforeD := SeqOf('B') < SeqOf('D');
        // The table extension triggers ran inside the installs: B's on row 20 (its own install) and on row 10 when B was installed before D, D's on
        // row 10 (its own install) and on row 20 when D was installed before B. Every one of them wrote a row with Insert(true) into the table of its app.
        ExpectedExt := '';
        ExpectedRowsB := '20;';
        if BBeforeD then begin
            ExpectedExt := 'Y69|B-ext|row=10 ## ';
            ExpectedRowsB := '10;20;';
        end;
        ExpectedExt += 'Y69|B-ext|row=20 ## Y69|D-ext|row=10 ## ';
        if not BBeforeD then
            ExpectedExt += 'Y69|D-ext|row=20 ## ';
        Observer.Observe('install_rows_of_A_table', Format(Data.Count()));
        Observer.Observe('rows_of_B_table', RowsB());
        // Neither a GetDatabaseTableTriggerSetup subscriber (B's sets OnDatabaseInsert for 61180 and 61192, D's sets no flag for 61180 and 61358) nor an
        // OnDatabaseInsert subscriber ran during any install: the only notes are the extension triggers'.
        Observer.Observe('notes_after_install', Notes());
        Observer.Expect('install_rows_of_A_table', '3');
        Observer.Expect('rows_of_B_table', ExpectedRowsB);
        Observer.Expect('notes_after_install', ExpectedExt);
        Observer.Verify();
    end;

    // The same subscribers in a test session: the setup is asked once per table (61358 was written twice, 61180 once), a subscriber that sets no flag
    // (D for B's table 61358) leaves OnDatabaseInsert unraised, and the flag B sets for 61180 makes OnDatabaseInsert run for the subscribers of B and D.
    [Test]
    procedure Y69_InstallTriggerSetup_SubscribersInATestSession()
    var
        Observer: Codeunit "Probe Observer";
        Data: Record "LT Y8 XA Data";
        RowB: Record "LT Y69 XB Row";
        Text: Text;
    begin
        Data.Init();
        Data."No." := 9969;
        Data.Insert(true);
        RowB.Init();
        RowB."No." := 9970;
        RowB.Insert(true);
        Text := Notes();
        Data.Delete();
        RowB.SetFilter("No.", '9969..9970');
        RowB.DeleteAll();
        Observer.Observe('d_setup_61358', Format(CountOf(Text, '|D-setup|t=61358|in=NoNoNoNo ##')));
        Observer.Observe('d_setup_61180', Format(CountOf(Text, '|D-setup|t=61180|')));
        Observer.Observe('d_insert_61358', Format(CountOf(Text, '|D-insert|t=61358|')));
        Observer.Observe('d_insert_61180', Format(CountOf(Text, '|D-insert|t=61180|row=9969 ##')));
        Observer.Observe('b_setup_61180', Format(CountOf(Text, 'Y69|B-setup|t=61180|in=No ##')));
        Observer.Observe('b_setup_61192', Format(CountOf(Text, 'Y69|B-setup|t=61192|in=No ##')));
        Observer.Observe('b_insert_61180', Format(CountOf(Text, 'Y69|B-insert|t=61180|row=9969 ##')));
        Observer.Observe('b_insert_61192', Format(CountOf(Text, 'Y69|B-insert|t=61192|row=9969 ##')));
        Observer.Expect('d_setup_61358', '1');
        Observer.Expect('d_setup_61180', '1');
        Observer.Expect('d_insert_61358', '0');
        Observer.Expect('d_insert_61180', '1');
        Observer.Expect('b_setup_61180', '1');
        Observer.Expect('b_setup_61192', '1');
        Observer.Expect('b_insert_61180', '1');
        Observer.Expect('b_insert_61192', '1');
        Observer.Verify();
    end;
}
