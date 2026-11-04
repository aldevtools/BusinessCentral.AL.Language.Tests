// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-permissions
// Scope: in-scope
// Fixtures used: Probe Observer (69160); "LT Y24 Row" (91936), "LT Y24 Perm Helper" (91978) and "LT Y24 Lower Calls" (91979) in
//   tests/al-language/permissions/lt-y19-perm-probes/Y24PermObjects.al; Microsoft's Tests-TestLibraries app installed (CI job "BC TestLibraries"), its table 135000 "Data Type Buffer"
//   used by id only (this app has no compile dependency on Tests-TestLibraries).
// Probe: al-runtime-rs ADR-062 (permission enforcement in stages), stage 4 probes, writer Y24, under the permission sets Microsoft's test
//   runner assigns before each test method whose TestPermissions is not Disabled (lt-bi-testpermissions/BiTpHelper.al):
//   P23 "Test Tables": read and insert a table of a Microsoft test library (Data Type Buffer, granted by Test Tables) and a table of the
//       corpus main app that no runner set names (the own table of this app is pinned by BiTpDefault.al);
//   P24 D365 Full Access in practice: a direct insert into G/L Entry, a posting through "Gen. Jnl.-Post Line" (its Permissions property
//       grants the ledger writes), a read of Company Information;
//   P25 lowering on top of the runner, in a Restrictive and a default codeunit: "Library - Lower Permissions".SetO365Basic and then
//       AddO365Setup. This app cannot call the library (no dependency on Tests-TestLibraries or Permissions Mock, and writers do not
//       change app.json), so "LT Y24 Lower Calls" in the main corpus app makes the same Permissions Mock calls the library makes.
//       Observed: insert into Standard Text (D365 Basic - Edit grants IMD) and Payment Terms
//       (D365 Setup grants RIMD), and into "LT Y24 Row" (no set names it).
// Every write runs inside asserterror and ends with an own error, so nothing stays in Microsoft tables. Every test method declares
//   [HandlerFunctions] and raises one Message, so the CI runner routes the codeunit to Microsoft's test runner (BiTpHelper.al).
// Facts (BC 27.5, 28.5, 29.0, Restrictive and default the same): under the runner sets a Test Tables table takes an insert and a read;
//   a table no set names fails Read and Insert with the app name of the code that accesses it (this app, not the table's app); a direct
//   G/L Entry insert fails (Insert, DB:ClientInsertDenied); "Gen. Jnl.-Post Line" posts; Company Information reads. After the
//   SetO365Basic calls Standard Text takes an insert and Payment Terms does not (Insert); after AddO365Setup both do.
// BC versions: 27, 28, 29

codeunit 81640 "LT Y24 Lower Probe"
{
    procedure ObserveRunnerTables(var Observer: Codeunit "Probe Observer")
    begin
        asserterror InsertReadDataTypeBuffer();
        Observer.ObserveError('test_library_table_insert_read');
        asserterror ReadMainAppRow();
        Observer.ObserveError('main_app_table_read');
        asserterror InsertMainAppRow(7);
        Observer.ObserveError('main_app_table_insert');
    end;

    procedure ObserveFullAccess(var Observer: Codeunit "Probe Observer")
    begin
        asserterror InsertGLEntry();
        Observer.ObserveError('gl_entry_insert');
        asserterror PostGenJnlLine();
        Observer.ObserveError('gen_jnl_post_line');
        asserterror ReadCompanyInformation();
        Observer.ObserveError('company_information_read');
    end;

    // "Library - Lower Permissions".SetO365Basic, then AddO365Setup when AddSetup is true (the calls: "LT Y24 Lower Calls", 91979).
    procedure Lower(var Observer: Codeunit "Probe Observer"; AddSetup: Boolean)
    var
        LowerCalls: Codeunit "LT Y24 Lower Calls";
    begin
        Observer.Observe('mock_started_' + Format(AddSetup), Format(LowerCalls.IsStarted()));
        LowerCalls.SetO365Basic();
        if AddSetup then
            LowerCalls.AddO365Setup();
    end;

    procedure ObserveLowered(var Observer: Codeunit "Probe Observer"; Prefix: Text)
    begin
        asserterror InsertStandardText();
        Observer.ObserveError(Prefix + 'standard_text_insert');
        asserterror InsertPaymentTerms();
        Observer.ObserveError(Prefix + 'payment_terms_insert');
        asserterror InsertMainAppRow(8);
        Observer.ObserveError(Prefix + 'main_app_table_insert');
    end;

    // Data Type Buffer may hold no rows (a read of an empty table raises no permission error), so the read follows an insert.
    local procedure InsertReadDataTypeBuffer()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(135000);
        RecRef.Field(1).Value := 81642;
        RecRef.Insert();
        RecRef.Reset();
        Error('LT Y24 ok inserted, findfirst %1', RecRef.FindFirst());
    end;

    local procedure ReadMainAppRow()
    var
        Row: Record "LT Y24 Row";
        Helper: Codeunit "LT Y24 Perm Helper";
    begin
        Helper.SeedRunnerRow();
        Error('LT Y24 ok findfirst %1', Row.FindFirst());
    end;

    local procedure InsertMainAppRow(NewId: Integer)
    var
        Row: Record "LT Y24 Row";
    begin
        Row.Id := 81640 + NewId;
        Row.Insert();
        Error('LT Y24 ok inserted');
    end;

    local procedure InsertGLEntry()
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry."Entry No." := 2000000000;
        GLEntry.Insert();
        Error('LT Y24 ok inserted');
    end;

    // Two G/L accounts that take a direct posting with no posting groups and no default dimensions, balanced against each other.
    local procedure PostGenJnlLine()
    var
        GenJnlLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        AccountNo: Code[20];
        BalAccountNo: Code[20];
    begin
        AccountNo := FindPlainAccount('');
        BalAccountNo := FindPlainAccount(AccountNo);
        if (AccountNo = '') or (BalAccountNo = '') then
            Error('LT Y24 no plain G/L accounts');
        GenJnlLine."Line No." := 10000;
        GenJnlLine."Posting Date" := PostingDate();
        GenJnlLine."Document No." := 'LTY24';
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
        GenJnlLine."Account No." := AccountNo;
        GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"G/L Account";
        GenJnlLine."Bal. Account No." := BalAccountNo;
        GenJnlLine.Description := 'LT Y24';
        GenJnlLine.Amount := 1;
        GenJnlLine."Amount (LCY)" := 1;
        GenJnlLine."Source Currency Amount" := 1;
        GenJnlPostLine.RunWithCheck(GenJnlLine);
        GLEntry.SetRange("Document No.", 'LTY24');
        Error('LT Y24 ok posted %1', GLEntry.Count());
    end;

    local procedure FindPlainAccount(Skip: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
        DefaultDimension: Record "Default Dimension";
    begin
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.SetRange("Direct Posting", true);
        GLAccount.SetRange(Blocked, false);
        GLAccount.SetRange("Gen. Posting Type", GLAccount."Gen. Posting Type"::" ");
        GLAccount.SetRange("Gen. Bus. Posting Group", '');
        GLAccount.SetRange("Gen. Prod. Posting Group", '');
        GLAccount.SetRange("VAT Bus. Posting Group", '');
        GLAccount.SetRange("VAT Prod. Posting Group", '');
        GLAccount.SetFilter("No.", '<>%1', Skip);
        if GLAccount.FindSet() then
            repeat
                DefaultDimension.SetRange("Table ID", Database::"G/L Account");
                DefaultDimension.SetRange("No.", GLAccount."No.");
                if DefaultDimension.IsEmpty() then
                    exit(GLAccount."No.");
            until GLAccount.Next() = 0;
        exit('');
    end;

    // The first allowed posting date of the database: General Ledger Setup's Allow Posting From, else the start of the first open
    // accounting period, else the work date.
    local procedure PostingDate(): Date
    var
        GLSetup: Record "General Ledger Setup";
        AccountingPeriod: Record "Accounting Period";
    begin
        GLSetup.Get();
        if GLSetup."Allow Posting From" <> 0D then
            exit(GLSetup."Allow Posting From");
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst() then
            exit(AccountingPeriod."Starting Date");
        exit(WorkDate());
    end;

    local procedure ReadCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
    begin
        Error('LT Y24 ok get %1', CompanyInformation.Get());
    end;

    local procedure InsertStandardText()
    var
        StandardText: Record "Standard Text";
    begin
        StandardText.Code := 'LTY24';
        StandardText.Insert();
        Error('LT Y24 ok inserted');
    end;

    local procedure InsertPaymentTerms()
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.Code := 'LTY24';
        PaymentTerms.Insert();
        Error('LT Y24 ok inserted');
    end;
}

codeunit 81641 "LT Y24 Runner Sets"
{
    Subtype = Test;

    var
        // One Observer per codeunit: the _More tests raise the rest of a long observation.
        Observer: Codeunit "Probe Observer";

    [Test]
    [HandlerFunctions('Y24Msg')]
    procedure Y24_P23_TestTables()
    var
        Probe: Codeunit "LT Y24 Lower Probe";
    begin
        Message('LT Y24');
        Probe.ObserveRunnerTables(Observer);
        Observer.Expect('test_library_table_insert_read|text', 'LT Y24 ok inserted, findfirst Yes');
        Observer.Expect('test_library_table_insert_read|code', 'Dialog');
        Observer.Expect('main_app_table_read|text', 'Sorry, the current permissions prevented the action. (TableData 91936 LT Y24 Row Read: AL Language Coverage Tests (Test Libraries))');
        Observer.Expect('main_app_table_read|code', 'DB:ClientReadDenied');
        Observer.Expect('main_app_table_insert|text', 'Sorry, the current permissions prevented the action. (TableData 91936 LT Y24 Row Insert: AL Language Coverage Tests (Test Libraries))');
        Observer.Expect('main_app_table_insert|code', 'DB:ClientInsertDenied');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('Y24Msg')]
    procedure Y24_P24_FullAccess()
    var
        Probe: Codeunit "LT Y24 Lower Probe";
    begin
        Message('LT Y24');
        Probe.ObserveFullAccess(Observer);
        Observer.Expect('gl_entry_insert|text', 'Sorry, the current permissions prevented the action. (TableData 17 G/L Entry Insert: AL Language Coverage Tests (Test Libraries))');
        Observer.Expect('gl_entry_insert|code', 'DB:ClientInsertDenied');
        Observer.Expect('gen_jnl_post_line|text', 'LT Y24 ok posted 2');
        Observer.Expect('gen_jnl_post_line|code', 'Dialog');
        Observer.Expect('company_information_read|text', 'LT Y24 ok get Yes');
        Observer.Expect('company_information_read|code', 'Dialog');
        Observer.Verify();
    end;

    [MessageHandler]
    procedure Y24Msg(Msg: Text[1024])
    begin
    end;
}

codeunit 81642 "LT Y24 Lower Restrictive"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        // One Observer per codeunit: the _More tests raise the rest of a long observation.
        Observer: Codeunit "Probe Observer";

    [Test]
    [HandlerFunctions('Y24Msg')]
    procedure Y24_P25_Restrictive()
    var
        Probe: Codeunit "LT Y24 Lower Probe";
    begin
        Message('LT Y24');
        Probe.ObserveLowered(Observer, 'runner_');
        Probe.Lower(Observer, false);
        Probe.ObserveLowered(Observer, 'basic_');
        Probe.Lower(Observer, true);
        Probe.ObserveLowered(Observer, 'basic_setup_');
        Observer.Expect('runner_standard_text_insert|text', 'LT Y24 ok inserted');
        Observer.Expect('runner_standard_text_insert|code', 'Dialog');
        Observer.Expect('runner_payment_terms_insert|text', 'LT Y24 ok inserted');
        Observer.Expect('runner_payment_terms_insert|code', 'Dialog');
        Observer.Expect('runner_main_app_table_insert|text', 'Sorry, the current permissions prevented the action. (TableData 91936 LT Y24 Row Insert: AL Language Coverage Tests (Test Libraries))');
        Observer.Expect('runner_main_app_table_insert|code', 'DB:ClientInsertDenied');
        Observer.Expect('mock_started_No', 'Yes');
        Observer.Expect('basic_standard_text_insert|text', 'LT Y24 ok inserted');
        Observer.Expect('basic_standard_text_insert|code', 'Dialog');
        Observer.Expect('basic_payment_terms_insert|text', 'Sorry, the current permissions prevented the action. (TableData 3 Payment Terms Insert: AL Language Coverage Tests (Test Libraries))');
        Observer.Expect('basic_payment_terms_insert|code', 'DB:ClientInsertDenied');
        Observer.Expect('basic_main_app_table_insert|text', 'Sorry, the current permissions prevented the action. (TableData 91936 LT Y24 Row Insert: AL Language Coverage Tests (Test Libraries))');
        Observer.Expect('basic_main_app_table_insert|code', 'DB:ClientInsertDenied');
        Observer.Expect('mock_started_Yes', 'Yes');
        Observer.Expect('basic_setup_standard_text_insert|text', 'LT Y24 ok inserted');
        Observer.Expect('basic_setup_standard_text_insert|code', 'Dialog');
        Observer.Expect('basic_setup_payment_terms_insert|text', 'LT Y24 ok inserted');
        Observer.Expect('basic_setup_payment_terms_insert|code', 'Dialog');
        Observer.Expect('basic_setup_main_app_table_insert|text', 'Sorry, the current permissions prevented the action. (TableData 91936 LT Y24 Row Insert: AL Language Coverage Tests (Test Libraries))');
        Observer.Expect('basic_setup_main_app_table_insert|code', 'DB:ClientInsertDenied');
        Observer.Verify();
    end;

    [MessageHandler]
    procedure Y24Msg(Msg: Text[1024])
    begin
    end;
}

codeunit 81643 "LT Y24 Lower Default"
{
    Subtype = Test;

    var
        // One Observer per codeunit: the _More tests raise the rest of a long observation.
        Observer: Codeunit "Probe Observer";

    [Test]
    [HandlerFunctions('Y24Msg')]
    procedure Y24_P25_Default()
    var
        Probe: Codeunit "LT Y24 Lower Probe";
    begin
        Message('LT Y24');
        Probe.ObserveLowered(Observer, 'runner_');
        Probe.Lower(Observer, false);
        Probe.ObserveLowered(Observer, 'basic_');
        Probe.Lower(Observer, true);
        Probe.ObserveLowered(Observer, 'basic_setup_');
        Observer.Expect('runner_standard_text_insert|text', 'LT Y24 ok inserted');
        Observer.Expect('runner_standard_text_insert|code', 'Dialog');
        Observer.Expect('runner_payment_terms_insert|text', 'LT Y24 ok inserted');
        Observer.Expect('runner_payment_terms_insert|code', 'Dialog');
        Observer.Expect('runner_main_app_table_insert|text', 'Sorry, the current permissions prevented the action. (TableData 91936 LT Y24 Row Insert: AL Language Coverage Tests (Test Libraries))');
        Observer.Expect('runner_main_app_table_insert|code', 'DB:ClientInsertDenied');
        Observer.Expect('mock_started_No', 'Yes');
        Observer.Expect('basic_standard_text_insert|text', 'LT Y24 ok inserted');
        Observer.Expect('basic_standard_text_insert|code', 'Dialog');
        Observer.Expect('basic_payment_terms_insert|text', 'Sorry, the current permissions prevented the action. (TableData 3 Payment Terms Insert: AL Language Coverage Tests (Test Libraries))');
        Observer.Expect('basic_payment_terms_insert|code', 'DB:ClientInsertDenied');
        Observer.Expect('basic_main_app_table_insert|text', 'Sorry, the current permissions prevented the action. (TableData 91936 LT Y24 Row Insert: AL Language Coverage Tests (Test Libraries))');
        Observer.Expect('basic_main_app_table_insert|code', 'DB:ClientInsertDenied');
        Observer.Expect('mock_started_Yes', 'Yes');
        Observer.Expect('basic_setup_standard_text_insert|text', 'LT Y24 ok inserted');
        Observer.Expect('basic_setup_standard_text_insert|code', 'Dialog');
        Observer.Expect('basic_setup_payment_terms_insert|text', 'LT Y24 ok inserted');
        Observer.Expect('basic_setup_payment_terms_insert|code', 'Dialog');
        Observer.Expect('basic_setup_main_app_table_insert|text', 'Sorry, the current permissions prevented the action. (TableData 91936 LT Y24 Row Insert: AL Language Coverage Tests (Test Libraries))');
        Observer.Expect('basic_setup_main_app_table_insert|code', 'DB:ClientInsertDenied');
        Observer.Verify();
    end;

    [MessageHandler]
    procedure Y24Msg(Msg: Text[1024])
    begin
    end;
}
