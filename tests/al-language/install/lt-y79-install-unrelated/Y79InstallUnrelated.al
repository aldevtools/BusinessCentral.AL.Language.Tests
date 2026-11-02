// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extension-install-code
// Scope: in-scope
// Fixtures used: Probe Observer (69160); cross-app fixtures tests/al-language-xapp-a/Y79XaObjects.al (hub 61372, tables 61370 61371 61374 61377-61379),
//   xapp-b/Y79XbSubs.al and xapp-d/Y79XdSubs.al (subscribers and table extensions), the install codeunits 61376 (Y8XaInstallOrder.al), 61384
//   (Y8XbInstallOrder.al) and 61394 (Y8XdInstallOrder.al); the install sequence of Y8 (table 61181 "LT Y8 XA Install Log").
// Probe (writer Y79, al-runner issues 6644 and 6755): what runs during the install of an app (A, B or D) when another app with no dependency path to it
//   has subscribers or table extensions: B and D (B has no dependency on D and D none on B) subscribe to the platform events of "Global Triggers" for the
//   tables of A, to the Upgrade Tag events, and extend the Reason Code and Job Queue Entry tables. The install code of A, B and D (per database and per
//   company) writes rows with Insert(true), asks the Upgrade Tag codeunit for its tags and notes what it sees. Every subscriber notes (Seq order) the
//   install it ran in. B sets the OnDatabaseInsert flag and adds 1 to the trigger mask; D only notes what it is given.
// The corpus CI installs A, D, B; other hosts install B before D. So the facts are asserted as relations to the install sequence the Y8 log records
//   (a subscriber runs during an install exactly when its app was installed first or is the installing app itself).
// BC versions: 27 - 29
codeunit 94170 "LT Y79 Install Unrelated"
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

    // The app is active during the install of Installing: it is Installing itself or was installed before it (A is installed first and has no subscribers).
    local procedure ActiveIn(App: Text; Installing: Text): Boolean
    begin
        exit(SeqOf(App) <= SeqOf(Installing));
    end;

    // The Seq of the first note that starts with Prefix, 0 when there is none.
    local procedure First(Prefix: Text): Integer
    var
        Row: Record "LT Y79 XA Seen";
    begin
        if Row.FindSet() then
            repeat
                if Row.Tag.StartsWith(Prefix) then
                    exit(Row.Seq);
            until Row.Next() = 0;
        exit(0);
    end;

    local procedure Has(Prefix: Text): Boolean
    begin
        exit(First(Prefix) > 0);
    end;

    // The rest of the first note that starts with Prefix after the prefix; '<none>' when there is none.
    local procedure After(Prefix: Text): Text
    var
        Row: Record "LT Y79 XA Seen";
    begin
        if Row.FindSet() then
            repeat
                if Row.Tag.StartsWith(Prefix) then
                    exit(CopyStr(Row.Tag, StrLen(Prefix) + 1));
            until Row.Next() = 0;
        exit('<none>');
    end;

    local procedure Installs(): List of [Text]
    var
        Result: List of [Text];
    begin
        Result.Add('A');
        Result.Add('B');
        Result.Add('D');
        exit(Result);
    end;

    local procedure Tables(): List of [Integer]
    var
        Result: List of [Integer];
    begin
        Result.Add(61370);
        Result.Add(61371);
        exit(Result);
    end;

    [Test]
    procedure Y79_Install_AllInstallCodeRan()
    var
        Observer: Codeunit "Probe Observer";
        App: Text;
    begin
        foreach App in Installs() do begin
            Observer.Observe('install ' + App + ' per company', Format(Has('install|' + App + '|co')));
            Observer.Observe('install ' + App + ' per database', Format(Has('install|' + App + '|db')));
            Observer.Expect('install ' + App + ' per company', 'Yes');
            Observer.Expect('install ' + App + ' per database', 'Yes');
        end;
        Observer.Verify();
    end;

    // During OnInstallAppPerCompany the platform asks the subscribers of the apps installed so far for the trigger setup and the trigger mask of the tables the
    // install code writes with Insert(true) (the per-company table 61370 and the DataPerCompany = false table 61371), and raises OnDatabaseInsert for the rows.
    [Test]
    procedure Y79_PerCompany_TriggerSubscribersOfInstalledApps()
    var
        Observer: Codeunit "Probe Observer";
        App: Text;
        Table: Integer;
        Where: Text;
        BRuns: Boolean;
        DRuns: Boolean;
    begin
        foreach App in Installs() do begin
            BRuns := ActiveIn('B', App);
            DRuns := ActiveIn('D', App);
            foreach Table in Tables() do begin
                Where := '|' + App + '|co|t=' + Format(Table);
                Observer.Observe('B mask ' + App + ' ' + Format(Table), Format(Has('B-mask' + Where)));
                Observer.Observe('D mask ' + App + ' ' + Format(Table), Format(Has('D-mask' + Where)));
                Observer.Observe('B setup ' + App + ' ' + Format(Table), Format(Has('B-setup' + Where)));
                Observer.Observe('D setup ' + App + ' ' + Format(Table), Format(Has('D-setup' + Where)));
                Observer.Observe('B OnDatabaseInsert ' + App + ' ' + Format(Table), Format(Has('B-dbinsert' + Where)));
                Observer.Observe('D OnDatabaseInsert ' + App + ' ' + Format(Table), Format(Has('D-dbinsert' + Where)));
                Observer.Expect('B mask ' + App + ' ' + Format(Table), Format(BRuns));
                Observer.Expect('D mask ' + App + ' ' + Format(Table), Format(DRuns));
                Observer.Expect('B setup ' + App + ' ' + Format(Table), Format(BRuns));
                Observer.Expect('D setup ' + App + ' ' + Format(Table), Format(DRuns));
                // B sets the OnDatabaseInsert flag, D sets none: D's OnDatabaseInsert runs only when B's flag is there to be seen.
                Observer.Expect('B OnDatabaseInsert ' + App + ' ' + Format(Table), Format(BRuns));
                Observer.Expect('D OnDatabaseInsert ' + App + ' ' + Format(Table), Format(BRuns and DRuns));
                // The inputs: B (first subscriber) gets mask 0 and no flag, D gets B's mask bit and B's insert flag when B's subscriber ran before it.
                if BRuns then begin
                    Observer.Observe('B mask input ' + App + ' ' + Format(Table), After('B-mask' + Where + '|in='));
                    Observer.Observe('B setup input ' + App + ' ' + Format(Table), After('B-setup' + Where + '|in='));
                    Observer.Expect('B mask input ' + App + ' ' + Format(Table), '0');
                    Observer.Expect('B setup input ' + App + ' ' + Format(Table), 'NoNoNoNo');
                end;
                if DRuns then begin
                    Observer.Observe('D mask input ' + App + ' ' + Format(Table), After('D-mask' + Where + '|in='));
                    Observer.Observe('D setup input ' + App + ' ' + Format(Table), After('D-setup' + Where + '|in='));
                    if BRuns then begin
                        Observer.Expect('D mask input ' + App + ' ' + Format(Table), '1');
                        Observer.Expect('D setup input ' + App + ' ' + Format(Table), 'YesNoNoNo');
                    end else begin
                        Observer.Expect('D mask input ' + App + ' ' + Format(Table), '0');
                        Observer.Expect('D setup input ' + App + ' ' + Format(Table), 'NoNoNoNo');
                    end;
                end;
            end;
        end;
        Observer.Verify();
    end;

    // During OnInstallAppPerDatabase the install code writes the DataPerCompany = false table 61371 with Insert(true) too, and no subscriber of any installed app
    // is asked for the trigger setup or the trigger mask, and no OnDatabaseInsert is raised (the same as the per-database install of Y69InstallTriggerSetup.al).
    [Test]
    procedure Y79_PerDatabase_NoTriggerSubscriberAsked()
    var
        Observer: Codeunit "Probe Observer";
        App: Text;
        EventName: Text;
        Sub: Text;
    begin
        foreach App in Installs() do
            foreach Sub in Subs() do
                foreach EventName in EventNames() do begin
                    Observer.Observe(Sub + ' ' + EventName + ' in the per-database install of ' + App, Format(Has(Sub + '-' + EventName + '|' + App + '|db|')));
                    Observer.Expect(Sub + ' ' + EventName + ' in the per-database install of ' + App, 'No');
                end;
        Observer.Verify();
    end;

    local procedure Subs(): List of [Text]
    var
        Result: List of [Text];
    begin
        Result.Add('B');
        Result.Add('D');
        exit(Result);
    end;

    local procedure EventNames(): List of [Text]
    var
        Result: List of [Text];
    begin
        Result.Add('mask');
        Result.Add('setup');
        Result.Add('dbinsert');
        Result.Add('globalinsert');
        exit(Result);
    end;

    // Subscribers of the installed apps run in a fixed order whatever the install order was: B before D.
    [Test]
    procedure Y79_PerCompany_SubscriberOrderAndEventOrder()
    var
        Observer: Codeunit "Probe Observer";
        App: Text;
        EventName: Text;
        Where: Text;
    begin
        foreach App in Installs() do begin
            Where := '|' + App + '|co|t=61371';
            if ActiveIn('B', App) and ActiveIn('D', App) then
                foreach EventName in EventNames() do begin
                    if EventName <> 'globalinsert' then begin
                        Observer.Observe('B before D ' + EventName + ' in ' + App, Format(First('B-' + EventName + Where) < First('D-' + EventName + Where)));
                        Observer.Expect('B before D ' + EventName + ' in ' + App, 'Yes');
                    end;
                end;
            if ActiveIn('B', App) then begin
                // The first write is the row in the DataPerCompany = false table 61371 of the install code: mask, then setup, then OnDatabaseInsert, then the second table.
                Observer.Observe('mask before setup before insert ' + App, Format((First('B-mask' + Where) < First('B-setup' + Where)) and (First('B-setup' + Where) < First('B-dbinsert' + Where))));
                Observer.Observe('table 61371 before 61370 ' + App, Format(First('B-dbinsert|' + App + '|co|t=61371') < First('B-mask|' + App + '|co|t=61370')));
                Observer.Expect('mask before setup before insert ' + App, 'Yes');
                Observer.Expect('table 61371 before 61370 ' + App, 'Yes');
            end;
        end;
        Observer.Verify();
    end;

    // The table extensions of B and D on two Base Application tables (Reason Code, Job Queue Entry), and the Upgrade Tag events, in the installs.
    [Test]
    procedure Y79_PerCompany_TableExtensionsAndUpgradeTags()
    var
        Observer: Codeunit "Probe Observer";
        App: Text;
        BRuns: Boolean;
        DRuns: Boolean;
    begin
        foreach App in Installs() do begin
            BRuns := ActiveIn('B', App);
            DRuns := ActiveIn('D', App);
            Observer.Observe('B Reason Code extension in ' + App, Format(Has('B-rc-ext|' + App + '|co|LTY79' + App)));
            Observer.Observe('D Reason Code extension in ' + App, Format(Has('D-rc-ext|' + App + '|co|LTY79' + App)));
            Observer.Observe('B Job Queue Entry extension in ' + App, Format(Has('B-jqe-ext|' + App + '|co')));
            Observer.Observe('D Job Queue Entry extension in ' + App, Format(Has('D-jqe-ext|' + App + '|co')));
            Observer.Expect('B Reason Code extension in ' + App, Format(BRuns));
            Observer.Expect('D Reason Code extension in ' + App, Format(DRuns));
            Observer.Expect('B Job Queue Entry extension in ' + App, Format(BRuns));
            Observer.Expect('D Job Queue Entry extension in ' + App, Format(DRuns));
            Observer.Observe('B per-company tags event in ' + App, Format(Has('B-tags-co|' + App + '|co')));
            Observer.Observe('D per-company tags event in ' + App, Format(Has('D-tags-co|' + App + '|co')));
            Observer.Observe('B per-database tags event in ' + App, Format(Has('B-tags-db|' + App + '|db')));
            Observer.Observe('D per-database tags event in ' + App, Format(Has('D-tags-db|' + App + '|db')));
            Observer.Expect('B per-company tags event in ' + App, Format(BRuns));
            Observer.Expect('D per-company tags event in ' + App, Format(DRuns));
            Observer.Expect('B per-database tags event in ' + App, Format(BRuns));
            Observer.Expect('D per-database tags event in ' + App, Format(DRuns));
            // The tags the install code of A got back: its own and the ones of the apps whose subscribers ran, in subscriber order.
            Observer.Observe('tags per company in ' + App, After('tags|' + App + '|co|'));
            Observer.Observe('tags per database in ' + App, After('tags|' + App + '|db|'));
            Observer.Expect('tags per company in ' + App, 'A=Yes|B=' + Format(BRuns) + '|D=' + Format(DRuns));
            Observer.Expect('tags per database in ' + App, 'A=Yes|B=' + Format(BRuns) + '|D=' + Format(DRuns));
        end;
        Observer.Verify();
    end;

    // Writes into the install order of the table extensions: B before D.
    [Test]
    procedure Y79_PerCompany_TableExtensionOrder()
    var
        Observer: Codeunit "Probe Observer";
        App: Text;
    begin
        foreach App in Installs() do
            if ActiveIn('B', App) and ActiveIn('D', App) then begin
                Observer.Observe('B before D Reason Code extension in ' + App, Format(First('B-rc-ext|' + App + '|co') < First('D-rc-ext|' + App + '|co')));
                Observer.Observe('B before D Job Queue Entry extension in ' + App, Format(First('B-jqe-ext|' + App + '|co') < First('D-jqe-ext|' + App + '|co')));
                Observer.Observe('B before D tags in ' + App, Format(First('B-tags-co|' + App + '|co') < First('D-tags-co|' + App + '|co')));
                Observer.Expect('B before D Reason Code extension in ' + App, 'Yes');
                Observer.Expect('B before D Job Queue Entry extension in ' + App, 'Yes');
                Observer.Expect('B before D tags in ' + App, 'Yes');
            end;
        Observer.Verify();
    end;

    // What the install code (also A's) saw of the AllObjWithCaption and AllObj rows of type TableData of its own table and of a Base Application table: the
    // same text during OnInstallAppPerCompany and OnInstallAppPerDatabase of every app, and the same as in a test session.
    [Test]
    procedure Y79_Install_AllObjTableDataColumns()
    var
        Observer: Codeunit "Probe Observer";
        Render: Codeunit "LT Y79 XA Render";
        Info: ModuleInfo;
        App: Text;
        Phase: Text;
        OwnText: Text;
        MsText: Text;
    begin
        NavApp.GetModuleInfo('cd6a4292-f27b-4af9-89bc-15a5956f5c71', Info);
        OwnText := Render.Describe(Database::"LT Y79 XA Data", Info);
        MsText := Render.Describe(Database::Contact, Info);
        Observer.Observe('test session own table', OwnText);
        Observer.Observe('test session Base Application table', MsText);
        Observer.Expect('test session own table', 'cap name=LT Y79 XA Data caption=LT Y79 XA Data subtype=[Normal] ns=[] pkg=own rt=own rt=pkg:Yes app=own |same as Table row: pkg=Yes rt=Yes app=Yes ns=Yes |AllObj same: pkg=Yes rt=Yes ns=Yes');
        Observer.Expect('test session Base Application table', 'cap name=Contact caption=Contact subtype=[Normal] ns=[Microsoft.CRM.Contact] pkg=base rt=other rt=pkg:No app=base |same as Table row: pkg=Yes rt=Yes app=Yes ns=Yes |AllObj same: pkg=Yes rt=Yes ns=Yes');
        foreach App in Installs() do
            foreach Phase in PhasesList() do begin
                Observer.Observe('install ' + App + ' ' + Phase + ' own table', After('objects|' + App + '|' + Phase + '|own|'));
                Observer.Observe('install ' + App + ' ' + Phase + ' Base Application table', After('objects|' + App + '|' + Phase + '|ms|'));
                Observer.Expect('install ' + App + ' ' + Phase + ' own table', OwnText);
                Observer.Expect('install ' + App + ' ' + Phase + ' Base Application table', MsText);
            end;
        Observer.Verify();
    end;

    local procedure PhasesList(): List of [Text]
    var
        Result: List of [Text];
    begin
        Result.Add('co');
        Result.Add('db');
        exit(Result);
    end;

    local procedure Clean(): Text
    var
        Row: Record "LT Y79 XA Seen";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                if Row.Tag.Contains('|-|') then begin
                    Result += Row.Tag + ' ## ';
                    Row.Delete();
                end;
            until Row.Next() = 0;
        exit(Result);
    end;

    [Test]
    procedure Y79_TestSession_Obs61377()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y79 XA Mask 2";
    begin
        Clean();
        Row.Init();
        Row."No." := 1;
        Row.Insert(true);
        Observer.Observe('after insert', Clean());
        Row.Note := 'x';
        Row.Modify(true);
        Observer.Observe('after modify', Clean());
        Row.Rename(2);
        Observer.Observe('after rename', Clean());
        Row.Delete(true);
        Observer.Observe('after delete', Clean());
        Observer.Finish();
    end;

    [Test]
    procedure Y79_TestSession_Obs61378()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y79 XA Mask 4";
    begin
        Clean();
        Row.Init();
        Row."No." := 1;
        Row.Insert(true);
        Observer.Observe('after insert', Clean());
        Row.Note := 'x';
        Row.Modify(true);
        Observer.Observe('after modify', Clean());
        Row.Rename(2);
        Observer.Observe('after rename', Clean());
        Row.Delete(true);
        Observer.Observe('after delete', Clean());
        Observer.Finish();
    end;

    [Test]
    procedure Y79_TestSession_Obs61379()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y79 XA Mask 8";
    begin
        Clean();
        Row.Init();
        Row."No." := 1;
        Row.Insert(true);
        Observer.Observe('after insert', Clean());
        Row.Note := 'x';
        Row.Modify(true);
        Observer.Observe('after modify', Clean());
        Row.Rename(2);
        Observer.Observe('after rename', Clean());
        Row.Delete(true);
        Observer.Observe('after delete', Clean());
        Observer.Finish();
    end;

    [Test]
    procedure Y79_TestSession_Obs61371()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y79 XA Db Data";
    begin
        Clean();
        Row.Init();
        Row."No." := 9971;
        Row.Insert(true);
        Observer.Observe('after insert', Clean());
        Row.Note := 'x';
        Row.Modify(true);
        Observer.Observe('after modify', Clean());
        Row.Delete(true);
        Observer.Observe('after delete', Clean());
        Observer.Finish();
    end;

    [Test]
    procedure Y79_TestSession_Obs61370()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y79 XA Data";
    begin
        Clean();
        Row.Init();
        Row."No." := 9972;
        Row.Insert(true);
        Observer.Observe('after insert', Clean());
        Row.Note := 'x';
        Row.Modify(true);
        Observer.Observe('after modify', Clean());
        Row.Delete(true);
        Observer.Observe('after delete', Clean());
        Observer.Finish();
    end;
}
