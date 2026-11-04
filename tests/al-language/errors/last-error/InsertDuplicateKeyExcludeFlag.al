// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-insert-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained tables 74860 and 74861, codeunit 74862
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: GetLastErrorText(true) (ExcludeCustomerContent) against GetLastErrorText(false) and GetLastErrorCode when Insert hits an existing primary key (single field, composite key, Insert(true)) or a unique secondary key. The tables carry a Blob field so the insert is sent at the statement (a duplicate insert into a table without a Blob is only raised at the end of the test, corpus-writer rule 9). One case per test because asserterror rolls back the earlier uncommitted writes.
// BC versions: 29 (27 and 28 by CI)

table 74860 "LT DUP Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Name; Text[30]) { }
        field(3; Data; Blob) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
        key(Sec; Name) { Unique = true; }
    }
}

table 74861 "LT DUP Composite"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Sub; Integer) { }
        field(3; Data; Blob) { }
    }

    keys { key(PK; Code, Sub) { Clustered = true; } }
}

codeunit 74862 "LT DUP Insert Flag"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Forms(Name: Text; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe(Name + '_true', GetLastErrorText(true));
        Observer.Observe(Name + '_false', GetLastErrorText(false));
        Observer.Observe(Name + '_code', GetLastErrorCode());
    end;

    [Test]
    procedure InsertDuplicate_SingleKey_ExcludeFlag()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT DUP Row";
    begin
        Row.DeleteAll();
        Row.Code := 'DUP1';
        Row.Name := 'first';
        Row.Insert();
        Row.Name := 'second';
        asserterror Row.Insert();
        Forms('single', Observer);
        Observer.Expect('single_true', 'The record in table LT DUP Row already exists. Identification fields and values: <redacted>');
        Observer.Expect('single_false', 'The record in table LT DUP Row already exists. Identification fields and values: Code=''DUP1''');
        Observer.Expect('single_code', 'DB:RecordExists');
        Observer.Verify();
    end;

    [Test]
    procedure InsertDuplicate_SingleKeyRunTrigger_ExcludeFlag()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT DUP Row";
    begin
        Row.DeleteAll();
        Row.Code := 'DUP2';
        Row.Name := 'first';
        Row.Insert(true);
        Row.Name := 'second';
        asserterror Row.Insert(true);
        Forms('trigger', Observer);
        Observer.Expect('trigger_true', 'The record in table LT DUP Row already exists. Identification fields and values: <redacted>');
        Observer.Expect('trigger_false', 'The record in table LT DUP Row already exists. Identification fields and values: Code=''DUP2''');
        Observer.Expect('trigger_code', 'DB:RecordExists');
        Observer.Verify();
    end;

    [Test]
    procedure InsertDuplicate_CompositeKey_ExcludeFlag()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT DUP Composite";
    begin
        Row.DeleteAll();
        Row.Code := 'DUP3';
        Row.Sub := 7;
        Row.Insert();
        asserterror Row.Insert();
        Forms('composite', Observer);
        Observer.Expect('composite_true', 'The record in table LT DUP Composite already exists. Identification fields and values: <redacted>');
        Observer.Expect('composite_false', 'The record in table LT DUP Composite already exists. Identification fields and values: Code=''DUP3'',Sub=''7''');
        Observer.Expect('composite_code', 'DB:RecordExists');
        Observer.Verify();
    end;

    [Test]
    procedure InsertDuplicate_UniqueSecondaryKey_ExcludeFlag()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT DUP Row";
    begin
        Row.DeleteAll();
        Row.Code := 'DUP4';
        Row.Name := 'same name';
        Row.Insert();
        Row.Code := 'DUP5';
        asserterror Row.Insert();
        Forms('secondary', Observer);
        Observer.Expect('secondary_true', 'There is already a record in table LT DUP Row that has the same values in a unique index for the following fields: <redacted>');
        Observer.Expect('secondary_false', 'There is already a record in table LT DUP Row that has the same values in a unique index for the following fields: Name=''same name''');
        Observer.Expect('secondary_code', 'DB:RecordExists');
        Observer.Verify();
    end;
}
