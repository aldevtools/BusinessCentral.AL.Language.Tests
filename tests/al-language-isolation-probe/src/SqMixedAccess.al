namespace ALLanguage.IsolationProbe;

// HEADER PLACEHOLDER

// MA: new sequence: helper and every mixed kind, Commit, Record write, then the test fails.
// MAa: Initialize only.
// MAb: the helper takes a number and inserts an entry, Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// MAc: reads the sequences and the tables and asserts them.
codeunit 79530 "LT SQM MA"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure MAa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure MAb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('MAb fails on purpose');
    end;

    [Test]
    procedure MAc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'MA';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// MW: new sequence: helper and a Record write only, Commit, Record write, then the test fails (control of MA).
// MWa: Initialize only.
// MWb: the helper takes a number and inserts an entry, Record insert B1, Commit(), Record insert B2, then fails.
// MWc: reads the sequences and the tables and asserts them.
codeunit 79531 "LT SQM MW"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure MWa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure MWb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('B1');
        Commit();
        Access.InsertRow('B2');
        Error('MWb fails on purpose');
    end;

    [Test]
    procedure MWc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'MW';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// MT: new sequence: helper, Record write, a temporary Record, Commit, Record write, then the test fails.
// MTa: Initialize only.
// MTb: the helper takes a number and inserts an entry, Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), Commit(), Record insert B2, then fails.
// MTc: reads the sequences and the tables and asserts them.
codeunit 79532 "LT SQM MT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure MTa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure MTb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('B1');
        Access.TempRecord();
        Commit();
        Access.InsertRow('B2');
        Error('MTb fails on purpose');
    end;

    [Test]
    procedure MTc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'MT';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// MB: new sequence: helper, Record write, session builtins, Commit, Record write, then the test fails.
// MBa: Initialize only.
// MBb: the helper takes a number and inserts an entry, Record insert B1, session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), Commit(), Record insert B2, then fails.
// MBc: reads the sequences and the tables and asserts them.
codeunit 79533 "LT SQM MB"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure MBa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure MBb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('B1');
        Access.Builtins();
        Commit();
        Access.InsertRow('B2');
        Error('MBb fails on purpose');
    end;

    [Test]
    procedure MBc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'MB';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// MQ: new sequence: helper, Record write, a Query read, Commit, Record write, then the test fails.
// MQa: Initialize only.
// MQb: the helper takes a number and inserts an entry, Record insert B1, a Query Open, Read, Close, Commit(), Record insert B2, then fails.
// MQc: reads the sequences and the tables and asserts them.
codeunit 79534 "LT SQM MQ"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure MQa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure MQb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('B1');
        Access.QueryRead();
        Commit();
        Access.InsertRow('B2');
        Error('MQb fails on purpose');
    end;

    [Test]
    procedure MQc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'MQ';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// MK: new sequence: helper, Record write, RecordRef calls the helper does not make, Commit, Record write, then the test fails.
// MKa: Initialize only.
// MKb: the helper takes a number and inserts an entry, Record insert B1, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// MKc: reads the sequences and the tables and asserts them.
codeunit 79535 "LT SQM MK"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure MKa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure MKb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('B1');
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('MKb fails on purpose');
    end;

    [Test]
    procedure MKc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'MK';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// MP: new sequence: helper, Record write, Page.Run with a PageHandler, Commit, Record write, then the test fails.
// MPa: Initialize only.
// MPb: the helper takes a number and inserts an entry, Record insert B1, Page.Run of a card (PageHandler closes it), Commit(), Record insert B2, then fails.
// MPc: reads the sequences and the tables and asserts them.
codeunit 79536 "LT SQM MP"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure MPa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    [HandlerFunctions('RowCardHandler')]
    procedure MPb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('B1');
        Access.RunPage();
        Commit();
        Access.InsertRow('B2');
        Error('MPb fails on purpose');
    end;

    [Test]
    procedure MPc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    [PageHandler]
    procedure RowCardHandler(var RowCard: TestPage "LT SQM Row Card")
    begin
        RowCard.Close();
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'MP';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// MR: new sequence: helper, Record write, Report.SaveAs Xml, Commit, Record write, then the test fails.
// MRa: Initialize only.
// MRb: the helper takes a number and inserts an entry, Record insert B1, Report.SaveAs in Xml format, Commit(), Record insert B2, then fails.
// MRc: reads the sequences and the tables and asserts them.
codeunit 79537 "LT SQM MR"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure MRa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure MRb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('B1');
        Access.ReportXml();
        Commit();
        Access.InsertRow('B2');
        Error('MRb fails on purpose');
    end;

    [Test]
    procedure MRc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'MR';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// M2: new sequences: the helper on two entry tables (two RecordRef loads of different tables), mixed kinds, Commit, Record write, then the test fails.
// M2a: Initialize only.
// M2b: the helper takes a number and inserts an entry, the helper takes a number of the second entry table and inserts an entry there, Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// M2c: reads the sequences and the tables and asserts them.
codeunit 79538 "LT SQM M2"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure M2a_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure M2b_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Seq.InsertEntry2(Name2(), Cell);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('M2b fails on purpose');
    end;

    [Test]
    procedure M2c_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | name2=' + Seq.State(Name2()) + ' | preview2=' + Seq.State(Seq.PreviewName(Name2())) + ' | entries2=' + Seq.Entries2();
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    local procedure Name2(): Text
    begin
        exit('LTSQM2' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'M2';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// MN: new sequence: MA with no Commit in the failed test.
// MNa: Initialize only.
// MNb: the helper takes a number and inserts an entry, Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Record insert B2, then fails.
// MNc: reads the sequences and the tables and asserts them.
codeunit 79539 "LT SQM MN"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure MNa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure MNb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Access.InsertRow('B2');
        Error('MNb fails on purpose');
    end;

    [Test]
    procedure MNc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'MN';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// NT: raw insert and a temporary Record only, Commit, Record write, then the test fails.
// NTa: Initialize only.
// NTb: NumberSequence.Insert(Name, 0, 1, true) and Next, a temporary Record (Insert, FindSet, Modify, DeleteAll), Commit(), Record insert B2, then fails.
// NTc: reads the sequences and the tables and asserts them.
codeunit 79540 "LT SQM NT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure NTa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure NTb_FailsOnPurpose()
    begin
        Initialize();
        NumberSequence.Insert(Name(), 0, 1, true);
        if NumberSequence.Next(Name()) = 0 then;
        Access.TempRecord();
        Commit();
        Access.InsertRow('B2');
        Error('NTb fails on purpose');
    end;

    [Test]
    procedure NTc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'NT';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// NB: raw insert and session builtins only, Commit, Record write, then the test fails.
// NBa: Initialize only.
// NBb: NumberSequence.Insert(Name, 0, 1, true) and Next, session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), Commit(), Record insert B2, then fails.
// NBc: reads the sequences and the tables and asserts them.
codeunit 79541 "LT SQM NB"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure NBa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure NBb_FailsOnPurpose()
    begin
        Initialize();
        NumberSequence.Insert(Name(), 0, 1, true);
        if NumberSequence.Next(Name()) = 0 then;
        Access.Builtins();
        Commit();
        Access.InsertRow('B2');
        Error('NBb fails on purpose');
    end;

    [Test]
    procedure NBc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'NB';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// NQ: raw insert and a Query read only, Commit, Record write, then the test fails.
// NQa: Initialize only.
// NQb: NumberSequence.Insert(Name, 0, 1, true) and Next, a Query Open, Read, Close, Commit(), Record insert B2, then fails.
// NQc: reads the sequences and the tables and asserts them.
codeunit 79542 "LT SQM NQ"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure NQa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure NQb_FailsOnPurpose()
    begin
        Initialize();
        NumberSequence.Insert(Name(), 0, 1, true);
        if NumberSequence.Next(Name()) = 0 then;
        Access.QueryRead();
        Commit();
        Access.InsertRow('B2');
        Error('NQb fails on purpose');
    end;

    [Test]
    procedure NQc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'NQ';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// NK: raw insert and RecordRef calls with no read only, Commit, Record write, then the test fails.
// NKa: Initialize only.
// NKb: NumberSequence.Insert(Name, 0, 1, true) and Next, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// NKc: reads the sequences and the tables and asserts them.
codeunit 79543 "LT SQM NK"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure NKa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure NKb_FailsOnPurpose()
    begin
        Initialize();
        NumberSequence.Insert(Name(), 0, 1, true);
        if NumberSequence.Next(Name()) = 0 then;
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('NKb fails on purpose');
    end;

    [Test]
    procedure NKc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'NK';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// NP: raw insert and Page.Run with a PageHandler only, Commit, Record write, then the test fails.
// NPa: Initialize only.
// NPb: NumberSequence.Insert(Name, 0, 1, true) and Next, Page.Run of a card (PageHandler closes it), Commit(), Record insert B2, then fails.
// NPc: reads the sequences and the tables and asserts them.
codeunit 79544 "LT SQM NP"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure NPa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    [HandlerFunctions('RowCardHandler')]
    procedure NPb_FailsOnPurpose()
    begin
        Initialize();
        NumberSequence.Insert(Name(), 0, 1, true);
        if NumberSequence.Next(Name()) = 0 then;
        Access.RunPage();
        Commit();
        Access.InsertRow('B2');
        Error('NPb fails on purpose');
    end;

    [Test]
    procedure NPc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    [PageHandler]
    procedure RowCardHandler(var RowCard: TestPage "LT SQM Row Card")
    begin
        RowCard.Close();
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'NP';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// NR: raw insert and Report.SaveAs Xml only, Commit, Record write, then the test fails.
// NRa: Initialize only.
// NRb: NumberSequence.Insert(Name, 0, 1, true) and Next, Report.SaveAs in Xml format, Commit(), Record insert B2, then fails.
// NRc: reads the sequences and the tables and asserts them.
codeunit 79545 "LT SQM NR"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure NRa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure NRb_FailsOnPurpose()
    begin
        Initialize();
        NumberSequence.Insert(Name(), 0, 1, true);
        if NumberSequence.Next(Name()) = 0 then;
        Access.ReportXml();
        Commit();
        Access.InsertRow('B2');
        Error('NRb fails on purpose');
    end;

    [Test]
    procedure NRc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'NR';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// NA: raw insert with the temporary Record, builtins and RecordRef calls (no table read or write), Commit, Record write, then the test fails.
// NAa: Initialize only.
// NAb: NumberSequence.Insert(Name, 0, 1, true) and Next, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// NAc: reads the sequences and the tables and asserts them.
codeunit 79546 "LT SQM NA"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure NAa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure NAb_FailsOnPurpose()
    begin
        Initialize();
        NumberSequence.Insert(Name(), 0, 1, true);
        if NumberSequence.Next(Name()) = 0 then;
        Access.TempRecord();
        Access.Builtins();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('NAb fails on purpose');
    end;

    [Test]
    procedure NAc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'NA';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// PA: new sequence: helper, guarded Codeunit.Run of a preview engine (Error('')), mixed kinds, Commit, Record write, then the test fails.
// PAa: Initialize only.
// PAb: the helper takes a number and inserts an entry, Codeunit.Run (return value used) of a preview engine that writes a row, takes a number through the helper and ends with Error(''), Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// PAc: reads the sequences and the tables and asserts them.
codeunit 79547 "LT SQM PA"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        PreviewResult: Text;
        Cell: Code[10];

    [Test]
    procedure PAa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure PAb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        PreviewResult += 'run:';
        PreviewResult += Access.RunPreview(Name(), 0);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('PAb fails on purpose');
    end;

    [Test]
    procedure PAc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | pv=' + PreviewResult;
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'PA';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// PB: new sequence: helper, asserterror of a preview call (Error('')), mixed kinds, Commit, Record write, then the test fails.
// PBa: Initialize only.
// PBb: the helper takes a number and inserts an entry, asserterror of a call that writes a row, takes a number through the helper and ends with Error(''), Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// PBc: reads the sequences and the tables and asserts them.
codeunit 79548 "LT SQM PB"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        PreviewResult: Text;
        Cell: Code[10];

    [Test]
    procedure PBa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure PBb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        asserterror Access.PreviewInline(Name());
        PreviewResult += 'asserterror:''' + GetLastErrorText() + '''';
        ClearLastError();
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('PBb fails on purpose');
    end;

    [Test]
    procedure PBc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | pv=' + PreviewResult;
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'PB';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// PC: new sequence: PA with no Commit in the failed test.
// PCa: Initialize only.
// PCb: the helper takes a number and inserts an entry, Codeunit.Run (return value used) of a preview engine that writes a row, takes a number through the helper and ends with Error(''), Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Record insert B2, then fails.
// PCc: reads the sequences and the tables and asserts them.
codeunit 79549 "LT SQM PC"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        PreviewResult: Text;
        Cell: Code[10];

    [Test]
    procedure PCa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure PCb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        PreviewResult += 'run:';
        PreviewResult += Access.RunPreview(Name(), 0);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Access.InsertRow('B2');
        Error('PCb fails on purpose');
    end;

    [Test]
    procedure PCc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | pv=' + PreviewResult;
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'PC';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// PD: new sequence: helper, guarded Codeunit.Run of a preview engine that writes a row only, mixed kinds, Commit, Record write, then the test fails.
// PDa: Initialize only.
// PDb: the helper takes a number and inserts an entry, Codeunit.Run (return value used) of a preview engine that writes a row and ends with Error(''), Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// PDc: reads the sequences and the tables and asserts them.
codeunit 79550 "LT SQM PD"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        PreviewResult: Text;
        Cell: Code[10];

    [Test]
    procedure PDa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure PDb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        PreviewResult += 'run:';
        PreviewResult += Access.RunPreview('', 0);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('PDb fails on purpose');
    end;

    [Test]
    procedure PDc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | pv=' + PreviewResult;
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'PD';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// PE: raw insert, guarded Codeunit.Run of a preview engine that writes a row only, Commit, Record write, then the test fails.
// PEa: Initialize only.
// PEb: NumberSequence.Insert(Name, 0, 1, true) and Next, Codeunit.Run (return value used) of a preview engine that writes a row and ends with Error(''), Commit(), Record insert B2, then fails.
// PEc: reads the sequences and the tables and asserts them.
codeunit 79551 "LT SQM PE"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        PreviewResult: Text;
        Cell: Code[10];

    [Test]
    procedure PEa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure PEb_FailsOnPurpose()
    begin
        Initialize();
        NumberSequence.Insert(Name(), 0, 1, true);
        if NumberSequence.Next(Name()) = 0 then;
        PreviewResult += 'run:';
        PreviewResult += Access.RunPreview('', 0);
        Commit();
        Access.InsertRow('B2');
        Error('PEb fails on purpose');
    end;

    [Test]
    procedure PEc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | pv=' + PreviewResult;
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'PE';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// PN: new sequence: PA and the test passes (control).
// PNa: Initialize only.
// PNb: the helper takes a number and inserts an entry, Codeunit.Run (return value used) of a preview engine that writes a row, takes a number through the helper and ends with Error(''), Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2 (passes).
// PNc: reads the sequences and the tables and asserts them.
codeunit 79552 "LT SQM PN"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        PreviewResult: Text;
        Cell: Code[10];

    [Test]
    procedure PNa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure PNb_Passes()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        PreviewResult += 'run:';
        PreviewResult += Access.RunPreview(Name(), 0);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
    end;

    [Test]
    procedure PNc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | pv=' + PreviewResult;
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'PN';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// XA: existing sequence: direct entry, helper restarts, mixed kinds, Commit, Record write, then the test fails.
// XAa: Initialize only (records the start state).
// XAb: an entry S + 5 inserted without the sequence, the helper takes a number (Restart of both sequences) and inserts the entry, Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// XAc: reads the sequences and the tables and asserts them.
codeunit 79553 "LT SQM XA"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name()) + ',' + Seq.Prepare(Seq.PreviewName(Name()));
    end;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure XAa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure XAb_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertDirectEntry(Base + 5, Cell);
        TakenNext := Seq.Offset(Seq.InsertEntry(Name(), Cell), Base);
        ChangedState := Seq.LastCreate() + ' ' + Seq.Rel(Name(), Base);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('XAb fails on purpose');
    end;

    [Test]
    procedure XAc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), Base) + ' | preview=' + Seq.Rel(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.EntriesRel(Base);
        Actual += ' | next=' + Seq.NextRel(Name(), Base) + ' | preview next=' + Seq.NextRel(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | name after=' + Seq.Rel(Name(), Base);
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQMXA');
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'XA';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name());
        PreviewBase := Seq.CurrentOrZero(Seq.PreviewName(Name()));
        StartState := Seq.Rel(Name(), Base) + ',' + Seq.Rel(Seq.PreviewName(Name()), PreviewBase);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// XB: existing sequence: XA with no Commit in the failed test.
// XBa: Initialize only (records the start state).
// XBb: an entry S + 5 inserted without the sequence, the helper takes a number (Restart of both sequences) and inserts the entry, Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Record insert B2, then fails.
// XBc: reads the sequences and the tables and asserts them.
codeunit 79554 "LT SQM XB"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name()) + ',' + Seq.Prepare(Seq.PreviewName(Name()));
    end;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure XBa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure XBb_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertDirectEntry(Base + 5, Cell);
        TakenNext := Seq.Offset(Seq.InsertEntry(Name(), Cell), Base);
        ChangedState := Seq.LastCreate() + ' ' + Seq.Rel(Name(), Base);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Access.InsertRow('B2');
        Error('XBb fails on purpose');
    end;

    [Test]
    procedure XBc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), Base) + ' | preview=' + Seq.Rel(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.EntriesRel(Base);
        Actual += ' | next=' + Seq.NextRel(Name(), Base) + ' | preview next=' + Seq.NextRel(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | name after=' + Seq.Rel(Name(), Base);
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQMXB');
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'XB';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name());
        PreviewBase := Seq.CurrentOrZero(Seq.PreviewName(Name()));
        StartState := Seq.Rel(Name(), Base) + ',' + Seq.Rel(Seq.PreviewName(Name()), PreviewBase);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// XC: existing sequence: XA plus Page.Run and Report.SaveAs Xml.
// XCa: Initialize only (records the start state).
// XCb: an entry S + 5 inserted without the sequence, the helper takes a number (Restart of both sequences) and inserts the entry, Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Page.Run of a card (PageHandler closes it), Report.SaveAs in Xml format, Commit(), Record insert B2, then fails.
// XCc: reads the sequences and the tables and asserts them.
codeunit 79555 "LT SQM XC"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name()) + ',' + Seq.Prepare(Seq.PreviewName(Name()));
    end;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure XCa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    [HandlerFunctions('RowCardHandler')]
    procedure XCb_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertDirectEntry(Base + 5, Cell);
        TakenNext := Seq.Offset(Seq.InsertEntry(Name(), Cell), Base);
        ChangedState := Seq.LastCreate() + ' ' + Seq.Rel(Name(), Base);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Access.RunPage();
        Access.ReportXml();
        Commit();
        Access.InsertRow('B2');
        Error('XCb fails on purpose');
    end;

    [Test]
    procedure XCc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), Base) + ' | preview=' + Seq.Rel(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.EntriesRel(Base);
        Actual += ' | next=' + Seq.NextRel(Name(), Base) + ' | preview next=' + Seq.NextRel(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | name after=' + Seq.Rel(Name(), Base);
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    [PageHandler]
    procedure RowCardHandler(var RowCard: TestPage "LT SQM Row Card")
    begin
        RowCard.Close();
    end;

    local procedure Name(): Text
    begin
        exit('LTSQMXC');
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'XC';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name());
        PreviewBase := Seq.CurrentOrZero(Seq.PreviewName(Name()));
        StartState := Seq.Rel(Name(), Base) + ',' + Seq.Rel(Seq.PreviewName(Name()), PreviewBase);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// XD: existing sequence: XA with a guarded Codeunit.Run of a preview engine after the restart.
// XDa: Initialize only (records the start state).
// XDb: an entry S + 5 inserted without the sequence, the helper takes a number (Restart of both sequences) and inserts the entry, Codeunit.Run (return value used) of a preview engine that writes a row, takes a number through the helper and ends with Error(''), Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// XDc: reads the sequences and the tables and asserts them.
codeunit 79556 "LT SQM XD"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name()) + ',' + Seq.Prepare(Seq.PreviewName(Name()));
    end;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        PreviewResult: Text;
        Cell: Code[10];

    [Test]
    procedure XDa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure XDb_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertDirectEntry(Base + 5, Cell);
        TakenNext := Seq.Offset(Seq.InsertEntry(Name(), Cell), Base);
        ChangedState := Seq.LastCreate() + ' ' + Seq.Rel(Name(), Base);
        PreviewResult += 'run:';
        PreviewResult += Access.RunPreview(Name(), 0);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('XDb fails on purpose');
    end;

    [Test]
    procedure XDc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | pv=' + PreviewResult;
        Actual += ' | name=' + Seq.Rel(Name(), Base) + ' | preview=' + Seq.Rel(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.EntriesRel(Base);
        Actual += ' | next=' + Seq.NextRel(Name(), Base) + ' | preview next=' + Seq.NextRel(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | name after=' + Seq.Rel(Name(), Base);
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQMXD');
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'XD';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name());
        PreviewBase := Seq.CurrentOrZero(Seq.PreviewName(Name()));
        StartState := Seq.Rel(Name(), Base) + ',' + Seq.Rel(Seq.PreviewName(Name()), PreviewBase);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// XE: existing sequence: XC with no Commit in the failed test.
// XEa: Initialize only (records the start state).
// XEb: an entry S + 5 inserted without the sequence, the helper takes a number (Restart of both sequences) and inserts the entry, Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Page.Run of a card (PageHandler closes it), Report.SaveAs in Xml format, Record insert B2, then fails.
// XEc: reads the sequences and the tables and asserts them.
codeunit 79557 "LT SQM XE"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name()) + ',' + Seq.Prepare(Seq.PreviewName(Name()));
    end;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure XEa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    [HandlerFunctions('RowCardHandler')]
    procedure XEb_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertDirectEntry(Base + 5, Cell);
        TakenNext := Seq.Offset(Seq.InsertEntry(Name(), Cell), Base);
        ChangedState := Seq.LastCreate() + ' ' + Seq.Rel(Name(), Base);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Access.RunPage();
        Access.ReportXml();
        Access.InsertRow('B2');
        Error('XEb fails on purpose');
    end;

    [Test]
    procedure XEc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), Base) + ' | preview=' + Seq.Rel(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.EntriesRel(Base);
        Actual += ' | next=' + Seq.NextRel(Name(), Base) + ' | preview next=' + Seq.NextRel(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | name after=' + Seq.Rel(Name(), Base);
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    [PageHandler]
    procedure RowCardHandler(var RowCard: TestPage "LT SQM Row Card")
    begin
        RowCard.Close();
    end;

    local procedure Name(): Text
    begin
        exit('LTSQMXE');
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'XE';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name());
        PreviewBase := Seq.CurrentOrZero(Seq.PreviewName(Name()));
        StartState := Seq.Rel(Name(), Base) + ',' + Seq.Rel(Seq.PreviewName(Name()), PreviewBase);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// XN: existing sequence: raw Restart with a temporary Record, builtins and RecordRef calls (no table read or write), then the test fails.
// XNa: Initialize only (records the start state).
// XNb: NumberSequence.Restart(Name, S + 1000), a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), then fails.
// XNc: reads the sequences and the tables and asserts them.
codeunit 79558 "LT SQM XN"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name()) + ',' + Seq.Prepare(Seq.PreviewName(Name()));
    end;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure XNa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure XNb_FailsOnPurpose()
    begin
        Initialize();
        NumberSequence.Restart(Name(), Base + 1000);
        ChangedState := Seq.Rel(Name(), Base);
        Access.TempRecord();
        Access.Builtins();
        Access.RecordRefExtra();
        Error('XNb fails on purpose');
    end;

    [Test]
    procedure XNc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), Base) + ' | preview=' + Seq.Rel(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.EntriesRel(Base);
        Actual += ' | next=' + Seq.NextRel(Name(), Base) + ' | preview next=' + Seq.NextRel(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | name after=' + Seq.Rel(Name(), Base);
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQMXN');
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'XN';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name());
        PreviewBase := Seq.CurrentOrZero(Seq.PreviewName(Name()));
        StartState := Seq.Rel(Name(), Base) + ',' + Seq.Rel(Seq.PreviewName(Name()), PreviewBase);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// XQ: existing sequence: raw Restart and a Query read, then the test fails.
// XQa: Initialize only (records the start state).
// XQb: NumberSequence.Restart(Name, S + 1000), a Query Open, Read, Close, then fails.
// XQc: reads the sequences and the tables and asserts them.
codeunit 79559 "LT SQM XQ"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name()) + ',' + Seq.Prepare(Seq.PreviewName(Name()));
    end;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure XQa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure XQb_FailsOnPurpose()
    begin
        Initialize();
        NumberSequence.Restart(Name(), Base + 1000);
        ChangedState := Seq.Rel(Name(), Base);
        Access.QueryRead();
        Error('XQb fails on purpose');
    end;

    [Test]
    procedure XQc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), Base) + ' | preview=' + Seq.Rel(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.EntriesRel(Base);
        Actual += ' | next=' + Seq.NextRel(Name(), Base) + ' | preview next=' + Seq.NextRel(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | name after=' + Seq.Rel(Name(), Base);
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQMXQ');
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'XQ';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name());
        PreviewBase := Seq.CurrentOrZero(Seq.PreviewName(Name()));
        StartState := Seq.Rel(Name(), Base) + ',' + Seq.Rel(Seq.PreviewName(Name()), PreviewBase);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// XP: existing sequence: XA and the test passes (control).
// XPa: Initialize only (records the start state).
// XPb: an entry S + 5 inserted without the sequence, the helper takes a number (Restart of both sequences) and inserts the entry, Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2 (passes).
// XPc: reads the sequences and the tables and asserts them.
codeunit 79560 "LT SQM XP"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name()) + ',' + Seq.Prepare(Seq.PreviewName(Name()));
    end;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure XPa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure XPb_Passes()
    begin
        Initialize();
        Access.InsertDirectEntry(Base + 5, Cell);
        TakenNext := Seq.Offset(Seq.InsertEntry(Name(), Cell), Base);
        ChangedState := Seq.LastCreate() + ' ' + Seq.Rel(Name(), Base);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
    end;

    [Test]
    procedure XPc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), Base) + ' | preview=' + Seq.Rel(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.EntriesRel(Base);
        Actual += ' | next=' + Seq.NextRel(Name(), Base) + ' | preview next=' + Seq.NextRel(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | name after=' + Seq.Rel(Name(), Base);
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQMXP');
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'XP';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name());
        PreviewBase := Seq.CurrentOrZero(Seq.PreviewName(Name()));
        StartState := Seq.Rel(Name(), Base) + ',' + Seq.Rel(Seq.PreviewName(Name()), PreviewBase);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// FA: two failed tests: both commit after mixed access.
// FAa: Initialize only.
// FAb: the helper takes a number and inserts an entry, Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// FAb2: the helper takes a number and inserts an entry, Record insert C1, a temporary Record (Insert, FindSet, Modify, DeleteAll), a Query Open, Read, Close, Commit(), Record insert C2, then fails.
// FAc: reads the sequences and the tables and asserts them.
codeunit 79561 "LT SQM FA"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure FAa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure FAb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('FAb fails on purpose');
    end;

    [Test]
    procedure FAb2_FailsAgain()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('C1');
        Access.TempRecord();
        Access.QueryRead();
        Commit();
        Access.InsertRow('C2');
        Error('FAb2 fails on purpose');
    end;

    [Test]
    procedure FAc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'FA';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// FB: two failed tests: the first commits after mixed access, the second does not commit.
// FBa: Initialize only.
// FBb: the helper takes a number and inserts an entry, Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// FBb2: the helper takes a number and inserts an entry, Record insert C1, a temporary Record (Insert, FindSet, Modify, DeleteAll), a Query Open, Read, Close, Record insert C2, then fails.
// FBc: reads the sequences and the tables and asserts them.
codeunit 79562 "LT SQM FB"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure FBa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure FBb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('FBb fails on purpose');
    end;

    [Test]
    procedure FBb2_FailsAgain()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('C1');
        Access.TempRecord();
        Access.QueryRead();
        Access.InsertRow('C2');
        Error('FBb2 fails on purpose');
    end;

    [Test]
    procedure FBc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'FB';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// FC: two failed tests: the first does not commit, the second commits after mixed access.
// FCa: Initialize only.
// FCb: the helper takes a number and inserts an entry, Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Record insert B2, then fails.
// FCb2: the helper takes a number and inserts an entry, Record insert C1, a temporary Record (Insert, FindSet, Modify, DeleteAll), a Query Open, Read, Close, Commit(), Record insert C2, then fails.
// FCc: reads the sequences and the tables and asserts them.
codeunit 79563 "LT SQM FC"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure FCa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure FCb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Access.InsertRow('B2');
        Error('FCb fails on purpose');
    end;

    [Test]
    procedure FCb2_FailsAgain()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('C1');
        Access.TempRecord();
        Access.QueryRead();
        Commit();
        Access.InsertRow('C2');
        Error('FCb2 fails on purpose');
    end;

    [Test]
    procedure FCc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'FC';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// FD: two failed tests: the first commits after mixed access, the second only takes a number.
// FDa: Initialize only.
// FDb: the helper takes a number and inserts an entry, Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// FDb2: NumberSequence.Next, then fails.
// FDc: reads the sequences and the tables and asserts them.
codeunit 79564 "LT SQM FD"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        Cell: Code[10];

    [Test]
    procedure FDa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure FDb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('FDb fails on purpose');
    end;

    [Test]
    procedure FDb2_FailsAgain()
    begin
        Initialize();
        if NumberSequence.Next(Name()) = 0 then;
        Error('FDb2 fails on purpose');
    end;

    [Test]
    procedure FDc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'FD';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// FE: two failed tests, existing sequence: the first restarts and commits, the second restarts again with no commit.
// FEa: Initialize only (records the start state).
// FEb: an entry S + 5 inserted without the sequence, the helper takes a number (Restart of both sequences) and inserts the entry, Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// FEb2: an entry S + 20 inserted without the sequence, the helper takes a number (a second restart) and inserts the entry, Record insert C1, a temporary Record (Insert, FindSet, Modify, DeleteAll), a Query Open, Read, Close, Record insert C2, then fails.
// FEc: reads the sequences and the tables and asserts them.
codeunit 79565 "LT SQM FE"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name()) + ',' + Seq.Prepare(Seq.PreviewName(Name()));
    end;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        Cell: Code[10];

    [Test]
    procedure FEa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure FEb_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertDirectEntry(Base + 5, Cell);
        TakenNext := Seq.Offset(Seq.InsertEntry(Name(), Cell), Base);
        ChangedState := Seq.LastCreate() + ' ' + Seq.Rel(Name(), Base);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('FEb fails on purpose');
    end;

    [Test]
    procedure FEb2_FailsAgain()
    begin
        Initialize();
        Access.InsertDirectEntry(Base + 20, Cell);
        TakenNext += ',' + Seq.Offset(Seq.InsertEntry(Name(), Cell), Base);
        ChangedState += ',' + Seq.LastCreate() + ' ' + Seq.Rel(Name(), Base);
        Access.InsertRow('C1');
        Access.TempRecord();
        Access.QueryRead();
        Access.InsertRow('C2');
        Error('FEb2 fails on purpose');
    end;

    [Test]
    procedure FEc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | name=' + Seq.Rel(Name(), Base) + ' | preview=' + Seq.Rel(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.EntriesRel(Base);
        Actual += ' | next=' + Seq.NextRel(Name(), Base) + ' | preview next=' + Seq.NextRel(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | name after=' + Seq.Rel(Name(), Base);
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQMFE');
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'FE';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name());
        PreviewBase := Seq.CurrentOrZero(Seq.PreviewName(Name()));
        StartState := Seq.Rel(Name(), Base) + ',' + Seq.Rel(Seq.PreviewName(Name()), PreviewBase);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// PF: new sequence: helper, guarded Codeunit.Run of an engine that ends normally, mixed kinds, Commit, Record write, then the test fails.
// PFa: Initialize only.
// PFb: the helper takes a number and inserts an entry, Codeunit.Run (return value used) of an engine that writes a row, takes a number through the helper and ends normally, Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// PFc: reads the sequences and the tables and asserts them.
codeunit 79566 "LT SQM PF"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        PreviewResult: Text;
        Cell: Code[10];

    [Test]
    procedure PFa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure PFb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        PreviewResult += 'run:';
        PreviewResult += Access.RunPreview(Name(), 1);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('PFb fails on purpose');
    end;

    [Test]
    procedure PFc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | pv=' + PreviewResult;
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'PF';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// PG: new sequence: helper, guarded Codeunit.Run of an engine that ends with an error text, mixed kinds, Commit, Record write, then the test fails.
// PGa: Initialize only.
// PGb: the helper takes a number and inserts an entry, Codeunit.Run (return value used) of an engine that writes a row, takes a number through the helper and ends with Error('preview engine error'), Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// PGc: reads the sequences and the tables and asserts them.
codeunit 79567 "LT SQM PG"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        PreviewResult: Text;
        Cell: Code[10];

    [Test]
    procedure PGa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure PGb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        PreviewResult += 'run:';
        PreviewResult += Access.RunPreview(Name(), 2);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('PGb fails on purpose');
    end;

    [Test]
    procedure PGc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | pv=' + PreviewResult;
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'PG';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// PH: new sequence: helper, Commit, guarded Codeunit.Run of a preview engine (Error('')), mixed kinds, Commit, Record write, then the test fails.
// PHa: Initialize only.
// PHb: the helper takes a number and inserts an entry, Commit(), Codeunit.Run (return value used) of a preview engine that writes a row, takes a number through the helper and ends with Error(''), Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// PHc: reads the sequences and the tables and asserts them.
codeunit 79568 "LT SQM PH"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        PreviewResult: Text;
        Cell: Code[10];

    [Test]
    procedure PHa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure PHb_FailsOnPurpose()
    begin
        Initialize();
        Seq.InsertEntry(Name(), Cell);
        Commit();
        PreviewResult += 'run:';
        PreviewResult += Access.RunPreview(Name(), 0);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('PHb fails on purpose');
    end;

    [Test]
    procedure PHc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | pv=' + PreviewResult;
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'PH';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// PI: raw insert, guarded Codeunit.Run of a preview engine that takes a number (Error('')), mixed kinds, Commit, Record write, then the test fails.
// PIa: Initialize only.
// PIb: NumberSequence.Insert(Name, 0, 1, true) and Next, Codeunit.Run (return value used) of a preview engine that writes a row, takes a number through the helper and ends with Error(''), Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// PIc: reads the sequences and the tables and asserts them.
codeunit 79569 "LT SQM PI"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        PreviewResult: Text;
        Cell: Code[10];

    [Test]
    procedure PIa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure PIb_FailsOnPurpose()
    begin
        Initialize();
        NumberSequence.Insert(Name(), 0, 1, true);
        if NumberSequence.Next(Name()) = 0 then;
        PreviewResult += 'run:';
        PreviewResult += Access.RunPreview(Name(), 0);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('PIb fails on purpose');
    end;

    [Test]
    procedure PIc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | pv=' + PreviewResult;
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'PI';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// PJ: raw insert, guarded Codeunit.Run of a preview engine that takes a number (Error('')), Commit, Record write, then the test fails.
// PJa: Initialize only.
// PJb: NumberSequence.Insert(Name, 0, 1, true) and Next, Codeunit.Run (return value used) of a preview engine that writes a row, takes a number through the helper and ends with Error(''), Commit(), Record insert B2, then fails.
// PJc: reads the sequences and the tables and asserts them.
codeunit 79570 "LT SQM PJ"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Token: Text;
        PreviewResult: Text;
        Cell: Code[10];

    [Test]
    procedure PJa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure PJb_FailsOnPurpose()
    begin
        Initialize();
        NumberSequence.Insert(Name(), 0, 1, true);
        if NumberSequence.Next(Name()) = 0 then;
        PreviewResult += 'run:';
        PreviewResult += Access.RunPreview(Name(), 0);
        Commit();
        Access.InsertRow('B2');
        Error('PJb fails on purpose');
    end;

    [Test]
    procedure PJc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | pv=' + PreviewResult;
        Actual += ' | name=' + Seq.State(Name()) + ' | preview=' + Seq.State(Seq.PreviewName(Name()));
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.Entries();
        Actual += ' | next=' + Seq.NextAbs(Name()) + ' | preview next=' + Seq.NextAbs(Seq.PreviewName(Name()));
        Actual += ' | name after=' + Seq.State(Name());
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQM' + Cell + Token);
    end;

    // The first call deletes the rows of earlier cells, writes the INIT row and commits; later calls do nothing.
    // Token: a number sequence outlives the app and the run, so the name carries a token made once per codeunit run.
    local procedure Initialize()
    begin
        Cell := 'PJ';
        if IsInitialized then
            exit;
        Token := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}

// XF: existing sequence: helper restarts, Commit, guarded Codeunit.Run of a preview engine that takes a number, mixed kinds, Commit, Record write, then the test fails.
// XFa: Initialize only (records the start state).
// XFb: an entry S + 5 inserted without the sequence, the helper takes a number (Restart of both sequences) and inserts the entry, Commit(), Codeunit.Run (return value used) of a preview engine that writes a row, takes a number through the helper and ends with Error(''), Record insert B1, a temporary Record (Insert, FindSet, Modify, DeleteAll), session builtins (CompanyName, UserId, GuiAllowed, WorkDate, ...), a Query Open, Read, Close, RecordRef calls the helper does not make (FieldCount, Field, SetRecFilter, GetFilters), Commit(), Record insert B2, then fails.
// XFc: reads the sequences and the tables and asserts them.
codeunit 79571 "LT SQM XF"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The sequence exists before the tests begin: OnRun makes it when it is missing (a later run finds it).
    trigger OnRun()
    begin
        OnRunState := Seq.Prepare(Name()) + ',' + Seq.Prepare(Seq.PreviewName(Name()));
    end;

    var
        Seq: Codeunit "LT SQM Seq";
        Access: Codeunit "LT SQM Access";
        IsInitialized: Boolean;
        Base: BigInteger;
        PreviewBase: BigInteger;
        OnRunState: Text;
        StartState: Text;
        ChangedState: Text;
        TakenNext: Text;
        PreviewResult: Text;
        Cell: Code[10];

    [Test]
    procedure XFa_Earlier()
    begin
        Initialize();
    end;

    [Test]
    procedure XFb_FailsOnPurpose()
    begin
        Initialize();
        Access.InsertDirectEntry(Base + 5, Cell);
        TakenNext := Seq.Offset(Seq.InsertEntry(Name(), Cell), Base);
        ChangedState := Seq.LastCreate() + ' ' + Seq.Rel(Name(), Base);
        Commit();
        PreviewResult += 'run:';
        PreviewResult += Access.RunPreview(Name(), 0);
        Access.InsertRow('B1');
        Access.TempRecord();
        Access.Builtins();
        Access.QueryRead();
        Access.RecordRefExtra();
        Commit();
        Access.InsertRow('B2');
        Error('XFb fails on purpose');
    end;

    [Test]
    procedure XFc_ReadsAndAsserts()
    var
        Actual: Text;
    begin
        Actual := 'onrun=' + OnRunState + ' | initialized=' + Format(IsInitialized);
        Initialize();
        Actual += ' | start=' + StartState + ' | changed=' + ChangedState + ' | taken=' + TakenNext;
        Actual += ' | pv=' + PreviewResult;
        Actual += ' | name=' + Seq.Rel(Name(), Base) + ' | preview=' + Seq.Rel(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | rows=' + Access.Rows() + ' | entries=' + Seq.EntriesRel(Base);
        Actual += ' | next=' + Seq.NextRel(Name(), Base) + ' | preview next=' + Seq.NextRel(Seq.PreviewName(Name()), PreviewBase);
        Actual += ' | name after=' + Seq.Rel(Name(), Base);
        if Actual <> 'TBD' then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;

    local procedure Name(): Text
    begin
        exit('LTSQMXF');
    end;

    // The first call notes the start state, deletes the rows of earlier cells, writes the INIT row and commits; later
    // calls do nothing.
    local procedure Initialize()
    begin
        Cell := 'XF';
        if IsInitialized then
            exit;
        Base := Seq.CurrentOrZero(Name());
        PreviewBase := Seq.CurrentOrZero(Seq.PreviewName(Name()));
        StartState := Seq.Rel(Name(), Base) + ',' + Seq.Rel(Seq.PreviewName(Name()), PreviewBase);
        Access.DeleteAllRows();
        Access.InsertRow('INIT');
        IsInitialized := true;
        Commit();
    end;
}
