// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-insert-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-testfield-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-getview-method
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALT Composite (60001), ALT Keyed (60006),
//                ALT Relation Child (60029), ALT Relation Parent (60028), ALTFixtureCleanup (60019),
//                shared Assert (60021); self-contained tables 68138..68140
// Probe: written against a real BC 27.5 service tier (en-US); every literal below is what that
// tier produced. Other BC versions were not measured.
//
// Pins the full text and code of the record errors (already exists, does not exist, stale
// Modify, TestField, FieldError, TableRelation), that Insert on a table without a BLOB field
// is deferred so a duplicate key surfaces at the next database access, the Format of a RecordId,
// GetPosition, GetView and GetFilters, FilterGroup, and that a temporary record is not rolled back
// by asserterror.
//
// asserterror rolls the open write transaction back, so every test commits its set-up before the
// asserterror statements.
// BC versions: 27.5

table 68138 "Probe Dup No Blob"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 68139 "Probe Dup With Blob"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Payload; Blob) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 68140 "Probe Dup With Trigger"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    trigger OnInsert()
    begin
    end;
}

codeunit 68137 "Probe Record Texts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
        Commit();
    end;

    [Test]
    procedure Record_Insert_DuplicateKey_Text()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        Initialize();
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 1;
        ALTUniversal.Insert();
        Commit();

        ALTUniversal.Init();
        ALTUniversal."Entry No." := 1;
        asserterror ALTUniversal.Insert();

        Assert.AreEqual('The record in table ALT Universal already exists. Identification fields and values: Entry No.=''1''', GetLastErrorText(), 'text');
        Assert.AreEqual('DB:RecordExists', GetLastErrorCode(), 'code');
    end;

    [Test]
    procedure Record_Get_Missing_Text()
    var
        ALTUniversal: Record "ALT Universal";
        ALTComposite: Record "ALT Composite";
    begin
        Initialize();

        asserterror ALTUniversal.Get(99);
        Assert.AreEqual('The ALT Universal does not exist. Identification fields and values: Entry No.=''99''', GetLastErrorText(), 'text');
        Assert.AreEqual('DB:RecordNotFound', GetLastErrorCode(), 'code');

        asserterror ALTComposite.Get(9, 'zz', 8);
        Assert.AreEqual('The ALT Composite does not exist. Identification fields and values: Key1=''9'',Key2=''ZZ'',Key3=''8''', GetLastErrorText(), 'a composite key is joined with commas and the Code value is upper case');
    end;

    [Test]
    procedure Record_ModifyDeleteMissing_And_RenameToExisting_Text()
    var
        ALTUniversal: Record "ALT Universal";
        Other: Record "ALT Universal";
    begin
        Initialize();
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 1;
        ALTUniversal.Insert();
        Other.Init();
        Other."Entry No." := 2;
        Other.Insert();
        Commit();

        Other.Init();
        Other."Entry No." := 55;
        asserterror Other.Modify();
        Assert.AreEqual('The ALT Universal does not exist. Identification fields and values: Entry No.=''55''', GetLastErrorText(), 'Modify');
        Assert.AreEqual('DB:RecordNotFound', GetLastErrorCode(), 'Modify code');

        asserterror Other.Delete();
        Assert.AreEqual('The ALT Universal does not exist. Identification fields and values: Entry No.=''55''', GetLastErrorText(), 'Delete');

        asserterror ALTUniversal.Rename(2);
        Assert.AreEqual('The record in table ALT Universal already exists. Identification fields and values: Entry No.=''2''', GetLastErrorText(), 'Rename');
        Assert.AreEqual('DB:RecordExists', GetLastErrorCode(), 'Rename code');
    end;

    [Test]
    procedure Record_Modify_StaleBuffer_Text()
    // CLAIM: the text has a carriage return and a backslash after the first sentence and after each following line: ...try again.CR\CR\Identification fields and values:CR\CR\Entry No.='1'.
    var
        ALTUniversal: Record "ALT Universal";
        Newer: Record "ALT Universal";
        Expected: Text;
    begin
        Initialize();
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 1;
        ALTUniversal.Insert();
        Commit();
        ALTUniversal.Get(1);
        Newer.Get(1);
        Newer."Text Field" := 'other';
        Newer.Modify();
        Commit();

        ALTUniversal."Text Field" := 'stale';
        asserterror ALTUniversal.Modify();

        Expected := 'The changes to the ALT Universal record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.' +
            '\' + '\' + 'Identification fields and values:' + '\' + '\' + 'Entry No.=''1''';
        Assert.AreEqual(Expected, GetLastErrorText(), 'text');
        Assert.AreEqual('DB:RecordChanged', GetLastErrorCode(), 'code');
    end;

    [Test]
    procedure Record_Insert_DuplicateKey_WithoutBlobField_IsDeferred_AndSurfacesAtTheNextAccess()
    // CLAIM: Insert() of an existing key on a table without a BLOB field returns without an error (with or without a trigger on the table and with Insert(true)); the error is raised by the next access to the table or by Commit. A guarded Insert returns false at once.
    var
        NoBlob: Record "Probe Dup No Blob";
        WithTrigger: Record "Probe Dup With Trigger";
        Duplicate: Record "Probe Dup No Blob";
        Inserted: Boolean;
        Rows: Integer;
    begin
        Initialize();
        NoBlob.DeleteAll();
        WithTrigger.DeleteAll();
        NoBlob.Id := 1;
        NoBlob.Insert();
        WithTrigger.Id := 1;
        WithTrigger.Insert();
        Commit();

        Duplicate.Id := 1;
        Inserted := Duplicate.Insert();
        Assert.IsFalse(Inserted, 'the guarded form returns false immediately');

        Duplicate.Id := 1;
        Duplicate.Insert();
        asserterror Rows := NoBlob.Count();
        Assert.AreEqual('The record in table Probe Dup No Blob already exists. Identification fields and values: Id=''1''', GetLastErrorText(), 'raised by the next read');
        Assert.AreEqual('DB:RecordExists', GetLastErrorCode(), 'code');

        WithTrigger.Id := 1;
        WithTrigger.Insert(true);
        asserterror Commit();
        Assert.AreEqual('The record in table Probe Dup With Trigger already exists. Identification fields and values: Id=''1''', GetLastErrorText(), 'raised by Commit, also with a trigger on the table');
    end;

    [Test]
    procedure Record_Insert_DuplicateKey_WithBlobField_IsRaisedAtOnce()
    var
        WithBlob: Record "Probe Dup With Blob";
    begin
        Initialize();
        WithBlob.DeleteAll();
        WithBlob.Id := 1;
        WithBlob.Insert();
        Commit();

        WithBlob.Id := 1;
        asserterror WithBlob.Insert();

        Assert.AreEqual('The record in table Probe Dup With Blob already exists. Identification fields and values: Id=''1''', GetLastErrorText(), 'text');
    end;

    [Test]
    procedure Record_TestField_MismatchTexts()
    var
        ALTUniversal: Record "ALT Universal";
        ALTComposite: Record "ALT Composite";
    begin
        Initialize();
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 7;
        ALTUniversal."Text Field" := 'cur';
        ALTUniversal."Integer Field" := 5;
        ALTUniversal.Insert();

        asserterror ALTUniversal.TestField("Text Field", 'wanted');
        Assert.AreEqual('Text Field must be equal to ''wanted''  in ALT Universal: Entry No.=7. Current value is ''cur''.', GetLastErrorText(), 'text value (two spaces before "in")');
        Assert.AreEqual('TestField', GetLastErrorCode(), 'code');

        asserterror ALTUniversal.TestField("Integer Field", 6);
        Assert.AreEqual('Integer Field must be equal to ''6''  in ALT Universal: Entry No.=7. Current value is ''5''.', GetLastErrorText(), 'integer');

        asserterror ALTUniversal.TestField("Boolean Field", true);
        Assert.AreEqual('Boolean Field must be equal to ''Yes''  in ALT Universal: Entry No.=7. Current value is ''No''.', GetLastErrorText(), 'boolean');

        asserterror ALTUniversal.TestField("Date Field", 20240101D);
        Assert.AreEqual('Date Field must be equal to ''01/01/24''  in ALT Universal: Entry No.=7. Current value is ''''.', GetLastErrorText(), 'date');

        asserterror ALTUniversal.TestField("Code Field");
        Assert.AreEqual('Code Field must have a value in ALT Universal: Entry No.=7. It cannot be zero or empty.', GetLastErrorText(), 'empty value');

        ALTComposite.Init();
        ALTComposite.Key1 := 1;
        ALTComposite.Key2 := 'abc';
        ALTComposite.Key3 := 3;
        ALTComposite.Value1 := 'v';
        ALTComposite.Insert();
        asserterror ALTComposite.TestField(Value1, 'other');
        Assert.AreEqual('Value1 must be equal to ''other''  in ALT Composite: Key1=1, Key2=ABC, Key3=3. Current value is ''v''.', GetLastErrorText(), 'composite key is joined with ", "');
    end;

    [Test]
    procedure Record_FieldError_Texts()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        Initialize();
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 7;
        ALTUniversal."Text Field" := 'cur';
        ALTUniversal.Insert();

        asserterror ALTUniversal.FieldError("Text Field", 'is not allowed');
        Assert.AreEqual('Text Field is not allowed in ALT Universal Entry No.=''7''.', GetLastErrorText(), 'with text: no colon after the table, the key in quotes');
        Assert.AreEqual('NCLCSRTS:TableErrorStr', GetLastErrorCode(), 'code');

        asserterror ALTUniversal.FieldError("Text Field");
        Assert.AreEqual('Text Field must not be cur in ALT Universal Entry No.=''7''.', GetLastErrorText(), 'without text');
    end;

    [Test]
    procedure Record_Validate_TableRelation_Text_BlankIsAccepted()
    var
        Child: Record "ALT Relation Child";
        Parent: Record "ALT Relation Parent";
    begin
        Initialize();
        Child.Init();
        Child."Entry No." := 1;

        asserterror Child.Validate("Validated Ref", 'NOPE');
        Assert.AreEqual('The field Validated Ref of table ALT Relation Child contains a value (NOPE) that cannot be found in the related table (ALT Relation Parent).', GetLastErrorText(), 'text');
        Assert.AreEqual('DB:PrimRecordNotFound', GetLastErrorCode(), 'code');

        Child.Validate("Validated Ref", '');
        Parent.Init();
        Parent.Code := 'OK';
        Parent.Insert();
        Child.Validate("Validated Ref", 'OK');
        Assert.AreEqual('OK', Child."Validated Ref", 'a value that exists');
    end;

    [Test]
    procedure RecordId_Format_And_GetPosition()
    var
        ALTUniversal: Record "ALT Universal";
        ALTComposite: Record "ALT Composite";
        ALTKeyed: Record "ALT Keyed";
    begin
        Initialize();
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 5;
        ALTComposite.Init();
        ALTComposite.Key1 := 9;
        ALTComposite.Key2 := 'zz';
        ALTComposite.Key3 := 8;

        Assert.AreEqual('ALT Universal: 5', Format(ALTUniversal.RecordId), 'RecordId');
        Assert.AreEqual('ALT Composite: 9,ZZ,8', Format(ALTComposite.RecordId), 'composite RecordId');
        Assert.AreEqual('Entry No.=CONST(5)', ALTUniversal.GetPosition(), 'GetPosition');
        Assert.AreEqual('Field1=0(5)', ALTUniversal.GetPosition(false), 'GetPosition without names');
        Assert.AreEqual('Key1=CONST(9),Key2=CONST(ZZ),Key3=CONST(8)', ALTComposite.GetPosition(), 'composite GetPosition');
        Assert.AreEqual('Field1=0(9),Field2=0(ZZ),Field3=0(8)', ALTComposite.GetPosition(false), 'composite GetPosition without names');
        Assert.AreEqual('Entry No.', ALTUniversal.CurrentKey(), 'CurrentKey');
        Assert.AreEqual('Key1,Key2,Key3', ALTComposite.CurrentKey(), 'composite CurrentKey');

        ALTKeyed.SetCurrentKey(Name, Code);
        ALTKeyed.Init();
        ALTKeyed."Entry No." := 3;
        ALTKeyed.Name := 'nm';
        ALTKeyed.Code := 'cd';
        Assert.AreEqual('Name,Code', ALTKeyed.CurrentKey(), 'a secondary key');
        Assert.AreEqual('Entry No.=CONST(3)', ALTKeyed.GetPosition(), 'GetPosition is the primary key even with a secondary key set');
    end;

    [Test]
    procedure Record_GetView_And_GetFilters_Texts()
    var
        ALTKeyed: Record "ALT Keyed";
    begin
        Initialize();

        Assert.AreEqual('VERSION(1) SORTING(Entry No.)', ALTKeyed.GetView(), 'plain');
        Assert.AreEqual('VERSION(1) SORTING(Field1)', ALTKeyed.GetView(false), 'plain without names');

        ALTKeyed.SetRange("Entry No.", 1, 3);
        ALTKeyed.SetFilter(Name, 'a*|b');
        ALTKeyed.SetCurrentKey(Amount);
        ALTKeyed.Ascending(false);
        Assert.AreEqual('VERSION(1) SORTING(Amount) ORDER(Descending) WHERE(Entry No.=FILTER(1..3),Name=FILTER(a*|b))', ALTKeyed.GetView(), 'with filters, a key and a descending order');
        Assert.AreEqual('VERSION(1) SORTING(Field4) ORDER(1) WHERE(Field1=1(1..3),Field2=1(a*|b))', ALTKeyed.GetView(false), 'without names');
        Assert.AreEqual('Entry No.: 1..3, Name: a*|b', ALTKeyed.GetFilters(), 'GetFilters');

        ALTKeyed.SetRange(Amount, 5);
        ALTKeyed.SetRange("Date Field", 20240101D, 20240131D);
        ALTKeyed.SetFilter(Status, '<>%1', ALTKeyed.Status::" ");
        Assert.AreEqual('Entry No.: 1..3, Name: a*|b, Amount: 5, Date Field: 01/01/24..01/31/24, Status: <>'' ''', ALTKeyed.GetFilters(), 'GetFilters in field order');

        ALTKeyed.Reset();
        Assert.AreEqual('VERSION(1) SORTING(Entry No.)', ALTKeyed.GetView(), 'after Reset');
    end;

    [Test]
    procedure Record_FilterGroup_ReturnsTheGroupJustSet_AndReadsOnlyTheCurrentGroup()
    var
        ALTKeyed: Record "ALT Keyed";
    begin
        Initialize();

        ALTKeyed.FilterGroup(2);
        ALTKeyed.SetRange(Code, 'X');
        ALTKeyed.FilterGroup(0);
        Assert.AreEqual('', ALTKeyed.GetFilters(), 'group 0 does not show the group 2 filter');
        Assert.AreEqual(2, ALTKeyed.FilterGroup(2), 'FilterGroup(2) returns 2');
        Assert.AreEqual('Code: X', ALTKeyed.GetFilters(), 'group 2');
        Assert.AreEqual(0, ALTKeyed.FilterGroup(0), 'FilterGroup(0) returns 0, the group it sets, not the one it leaves');

        ALTKeyed.Reset();
        ALTKeyed.FilterGroup(2);
        Assert.AreEqual('', ALTKeyed.GetFilters(), 'Reset clears the group 2 filter too');
    end;

    [Test]
    procedure TemporaryRecord_IsNotRolledBackByAsserterror_ARealRecordIs()
    var
        Temp: Record "ALT Universal" temporary;
        Real: Record "ALT Universal";
    begin
        Initialize();
        Temp.Init();
        Temp."Entry No." := 1;
        Temp.Insert();

        asserterror begin
            Temp.Init();
            Temp."Entry No." := 2;
            Temp.Insert();
            Real.Init();
            Real."Entry No." := 100;
            Real.Insert();
            Error('x');
        end;

        Assert.AreEqual(2, Temp.Count(), 'both temporary rows are still there');
        Assert.AreEqual(0, Real.Count(), 'the real row was rolled back');
    end;


    // ---- AL Runner issue 5788 (writer RU): where a duplicate-key error that is still deferred when a codeunit's OnRun or a TryFunction ends
    // surfaces. A test that ends with the error deferred cannot be a corpus test (it fails), so these are its neighbours: the end of a
    // guarded and of a statement-form Codeunit.Run (the test runner runs a test codeunit through Codeunit.Run).
    // A TryFunction cannot be asked: an Insert inside one is refused at once (pinned in misc/lt-cu-odd-leads/CuTryTests.al).
    // Codeunit 88665 (lt-ru-deferred-dup/RuDeferredDupTargets.al) inserts Id 2, then a duplicate of Id 1 as its last statement.

    local procedure RuPrepare()
    var
        NoBlob: Record "Probe Dup No Blob";
    begin
        Initialize();
        NoBlob.DeleteAll();
        NoBlob.Id := 1;
        NoBlob.Txt := 'first';
        NoBlob.Insert();
        Commit();
    end;

    local procedure RuObserveRows(var Observer: Codeunit "Probe Observer")
    var
        NoBlob: Record "Probe Dup No Blob";
        Rows: Integer;
    begin
        if RuTryCount(Rows) then
            Observer.Observe('read', Format(Rows))
        else
            Observer.ObserveError('read');
        if RuTryCount(Rows) then
            Observer.Observe('second read', Format(Rows))
        else
            Observer.ObserveError('second read');
        Observer.Observe('row 2 exists', Format(NoBlob.Get(2)));
        NoBlob.Get(1);
        Observer.Observe('row 1 text', NoBlob.Txt);
        NoBlob.DeleteAll();
        Commit();
    end;

    [TryFunction]
    local procedure RuTryCount(var Rows: Integer)
    var
        NoBlob: Record "Probe Dup No Blob";
    begin
        Rows := NoBlob.Count();
    end;

    [Test]
    procedure RU_DeferredDuplicate_EndOfGuardedCodeunitRun()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        RuPrepare();
        Ok := Codeunit.Run(Codeunit::"LT RU Dup At End");
        Observer.Observe('run', Format(Ok));
        if not Ok then
            Observer.ObserveError('run');
        RuObserveRows(Observer);
        // Guarded: the deferred error ends the run (false, the duplicate's text and code) and rolls back the run's other insert.
        Observer.Expect('run', 'No');
        Observer.Expect('run|text', 'The record in table Probe Dup No Blob already exists. Identification fields and values: Id=''1''');
        Observer.Expect('run|code', 'DB:RecordExists');
        Observer.Expect('read', '1');
        Observer.Expect('second read', '1');
        Observer.Expect('row 2 exists', 'No');
        Observer.Expect('row 1 text', 'first');
        Observer.Verify();
    end;

    [Test]
    procedure RU_DeferredDuplicate_EndOfStatementCodeunitRun()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RuPrepare();
        Codeunit.Run(Codeunit::"LT RU Dup At End");
        Observer.Observe('run', 'returned');
        RuObserveRows(Observer);
        // Statement form: the run returns with the error still deferred, the caller's next read raises it, and the run's other insert stays.
        Observer.Expect('run', 'returned');
        Observer.Expect('read|text', 'The record in table Probe Dup No Blob already exists. Identification fields and values: Id=''1''');
        Observer.Expect('read|code', 'DB:RecordExists');
        Observer.Expect('second read', '2');
        Observer.Expect('row 2 exists', 'Yes');
        Observer.Expect('row 1 text', 'first');
        Observer.Verify();
    end;
}
