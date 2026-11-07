// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setloadfields-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 96940 to 96945, enum 96940, codeunit 96940
// Probe: al-runner issue 6924 (reporter waldo). Companion of the P170_JitLoad_* tests in LoadFieldsFetched.al. A record is read with
// SetLoadFields(primary key), the row is removed through another record variable, then a field that was not loaded is used. Each test
// records the text and code of the error, or that none was raised. Measured on BC 27.5, 28.5 and 29.0 (identical):
// - Reading an unloaded field raises error JustInTimeFieldLoad: "JIT loading of field(s): '<field name>' failed for table: '<table caption>'
//   identification values: '<key field caption>='<value>''". Code keys are written as is, an apostrophe in the value is not doubled, a
//   blank Code key gives 'No.='''. A composite key lists all parts in key order (Part1='P1',Part2='7'), whatever SetLoadFields names.
//   The table and the key fields use their captions, the field that caused the load its name. Key parts: Date 03/07/26 (blank: empty),
//   Decimal 12.5 or -1,234.5678, Guid in braces, Option and Enum by caption.
// - Only fields that are not loaded are named; fields loaded by AddLoadFields or SetLoadFields are read from the old buffer. A record read
//   without SetLoadFields is complete: no error. Reading two unloaded fields in one expression names the first.
// - Validate of an unloaded field raises the same error, also when only OnValidate reads an unloaded field. Modify raises DB:RecordNotFound.
//   Rename raises a JIT error naming all unloaded fields (Name, Note, Amount, ReadName). CalcFields raises nothing.
// - Rec.LoadFields(...) after the row is gone raises nothing and loads nothing; later reads still raise.
// - RecordRef: reading a field after the row is gone raises nothing and returns the old value (Get, FindFirst and AddLoadFields alike).
// - The row removed by Delete, DeleteAll with a filter, DeleteAll(true), DeleteAll without a filter or a Rename of the key: same error.
// - Row deleted and inserted again with the same key: error InconsistentRead ("The field '$systemId' on table ... has changed in the
//   database between initial and JIT load").
// BC versions: 27+

table 96940 "LT PG Code Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[50]) { }
        field(3; Note; Text[50])
        {
            trigger OnValidate()
            begin
                ReadName := Name;
            end;
        }
        field(4; Amount; Decimal) { }
        field(5; "Line Count"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT PG Line" where("Head No." = field("No.")));
            Editable = false;
        }
        field(6; ReadName; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 96941 "LT PG Composite Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Part1; Code[10]) { }
        field(2; Part2; Integer) { }
        field(3; Name; Text[50]) { }
    }

    keys
    {
        key(PK; Part1, Part2) { Clustered = true; }
    }
}

table 96942 "LT PG Caption Row"
{
    Caption = 'Gone Caption Table';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { Caption = 'Row Identifier'; }
        field(2; Info; Text[50]) { Caption = 'Info Caption'; }
        field(3; Plain; Text[50]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

enum 96940 "LT PG Kind"
{
    Extensible = true;
    value(0; First) { }
    value(1; Second) { Caption = 'Second Caption'; }
}

table 96943 "LT PG Typed Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; DateKey; Date) { }
        field(2; DecimalKey; Decimal) { }
        field(3; GuidKey; Guid) { }
        field(4; OptionKey; Option)
        {
            OptionMembers = Alpha,Beta,Gamma;
        }
        field(5; EnumKey; Enum "LT PG Kind") { }
        field(6; Name; Text[50]) { }
    }

    keys
    {
        key(PK; DateKey, DecimalKey, GuidKey, OptionKey, EnumKey) { Clustered = true; }
    }
}

table 96944 "LT PG Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Head No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
    }

    keys
    {
        key(PK; "Head No.", "Line No.") { Clustered = true; }
    }
}

codeunit 96940 "LT PG Jit Load Gone"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        C: Record "LT PG Code Row";
        L: Record "LT PG Line";
    begin
        C.DeleteAll();
        L.DeleteAll();
        AddCode('A1', 'one', 'note one');
        AddCode('A2', 'two', 'note two');
        AddCode('O''NEIL', 'apostrophe', 'note apostrophe');
        AddCode('', 'blank', 'note blank');
        L.Init();
        L."Head No." := 'A1';
        L."Line No." := 1;
        L.Insert();
    end;

    local procedure AddCode(No: Code[20]; Name: Text[50]; Note: Text[50])
    var
        C: Record "LT PG Code Row";
    begin
        C.Init();
        C."No." := No;
        C.Name := Name;
        C.Note := Note;
        C.Amount := 5;
        C.Insert();
    end;

    local procedure PartialCode(var R: Record "LT PG Code Row"; No: Code[20])
    begin
        R.SetLoadFields("No.");
        R.Get(No);
    end;

    local procedure GoneCode(No: Code[20])
    var
        Gone: Record "LT PG Code Row";
    begin
        Gone.Get(No);
        Gone.Delete();
    end;

    [TryFunction]
    local procedure TryReadName(var R: Record "LT PG Code Row")
    var
        S: Text;
    begin
        S := R.Name;
    end;

    [TryFunction]
    local procedure TryReadNote(var R: Record "LT PG Code Row")
    var
        S: Text;
    begin
        S := R.Note;
    end;

    [TryFunction]
    local procedure TryReadBoth(var R: Record "LT PG Code Row")
    var
        S: Text;
    begin
        S := R.Name + R.Note;
    end;

    // ---- 1. Code key (quoting of a Code value) ----

    [Test]
    procedure PG_CodeKey_ReadName()
    var
        R: Record "LT PG Code Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        PartialCode(R, 'A1');
        GoneCode('A1');
        Observer.Observe('raised', Format(not TryReadName(R)));
        Observer.ObserveError('name');
        Observer.Expect('raised', 'Yes');
        Observer.Expect('name|text', 'JIT loading of field(s): ''Name'' failed for table: ''LT PG Code Row'' identification values: ''No.=''A1''''');
        Observer.Expect('name|code', 'JustInTimeFieldLoad');
        Observer.Verify();
    end;

    [Test]
    procedure PG_CodeKey_ReadNote()
    var
        R: Record "LT PG Code Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        PartialCode(R, 'A2');
        GoneCode('A2');
        Observer.Observe('raised', Format(not TryReadNote(R)));
        Observer.ObserveError('note');
        Observer.Expect('raised', 'Yes');
        Observer.Expect('note|text', 'JIT loading of field(s): ''Note'' failed for table: ''LT PG Code Row'' identification values: ''No.=''A2''''');
        Observer.Expect('note|code', 'JustInTimeFieldLoad');
        Observer.Verify();
    end;

    // The record is complete (no SetLoadFields): nothing is loaded later, so a deleted row does not matter.
    [Test]
    procedure PG_CodeKey_FullRecord_NoError()
    var
        R: Record "LT PG Code Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.Get('A1');
        GoneCode('A1');
        Observer.Observe('raised', Format(not TryReadName(R)));
        Observer.ObserveError('name');
        Observer.Observe('name', R.Name);
        Observer.Expect('raised', 'No');
        Observer.Expect('name|text', '');
        Observer.Expect('name|code', '');
        Observer.Expect('name', 'one');
        Observer.Verify();
    end;

    // ---- 2. Composite key (separator, order) ----

    [Test]
    procedure PG_Composite_KeyFieldsLoaded()
    var
        R: Record "LT PG Composite Row";
        Gone: Record "LT PG Composite Row";
        Observer: Codeunit "Probe Observer";
        S: Text;
    begin
        SeedComposite();
        R.SetLoadFields(Part1, Part2);
        R.Get('P1', 7);
        Gone.Get('P1', 7);
        Gone.Delete();
        Observer.Observe('raised', Format(not TryReadCompositeName(R)));
        Observer.ObserveError('name');
        Observer.Expect('raised', 'Yes');
        Observer.Expect('name|text', 'JIT loading of field(s): ''Name'' failed for table: ''LT PG Composite Row'' identification values: ''Part1=''P1'',Part2=''7''''');
        Observer.Expect('name|code', 'JustInTimeFieldLoad');
        Observer.Verify();
    end;

    [Test]
    procedure PG_Composite_OnlyFirstKeyFieldInLoadFields()
    var
        R: Record "LT PG Composite Row";
        Gone: Record "LT PG Composite Row";
        Observer: Codeunit "Probe Observer";
    begin
        SeedComposite();
        R.SetLoadFields(Part1);
        R.Get('P1', 7);
        Gone.Get('P1', 7);
        Gone.Delete();
        Observer.Observe('raised', Format(not TryReadCompositeName(R)));
        Observer.ObserveError('name');
        Observer.Expect('raised', 'Yes');
        Observer.Expect('name|text', 'JIT loading of field(s): ''Name'' failed for table: ''LT PG Composite Row'' identification values: ''Part1=''P1'',Part2=''7''''');
        Observer.Expect('name|code', 'JustInTimeFieldLoad');
        Observer.Verify();
    end;

    [Test]
    procedure PG_Composite_OnlySecondKeyFieldInLoadFields()
    var
        R: Record "LT PG Composite Row";
        Gone: Record "LT PG Composite Row";
        Observer: Codeunit "Probe Observer";
    begin
        SeedComposite();
        R.SetLoadFields(Part2);
        R.Get('P1', 7);
        Gone.Get('P1', 7);
        Gone.Delete();
        Observer.Observe('raised', Format(not TryReadCompositeName(R)));
        Observer.ObserveError('name');
        Observer.Expect('raised', 'Yes');
        Observer.Expect('name|text', 'JIT loading of field(s): ''Name'' failed for table: ''LT PG Composite Row'' identification values: ''Part1=''P1'',Part2=''7''''');
        Observer.Expect('name|code', 'JustInTimeFieldLoad');
        Observer.Verify();
    end;

    local procedure SeedComposite()
    var
        R: Record "LT PG Composite Row";
    begin
        R.DeleteAll();
        R.Init();
        R.Part1 := 'P1';
        R.Part2 := 7;
        R.Name := 'composite';
        R.Insert();
    end;

    [TryFunction]
    local procedure TryReadCompositeName(var R: Record "LT PG Composite Row")
    var
        S: Text;
    begin
        S := R.Name;
    end;

    // ---- 3. Table caption and field caption differ from the names ----

    [Test]
    procedure PG_Caption_FieldWithCaption()
    var
        R: Record "LT PG Caption Row";
        Gone: Record "LT PG Caption Row";
        Observer: Codeunit "Probe Observer";
    begin
        SeedCaption();
        R.SetLoadFields(Id);
        R.Get(1);
        Gone.Get(1);
        Gone.Delete();
        Observer.Observe('raised', Format(not TryReadInfo(R)));
        Observer.ObserveError('info');
        Observer.Expect('raised', 'Yes');
        Observer.Expect('info|text', 'JIT loading of field(s): ''Info'' failed for table: ''Gone Caption Table'' identification values: ''Row Identifier=''1''''');
        Observer.Expect('info|code', 'JustInTimeFieldLoad');
        Observer.Verify();
    end;

    [Test]
    procedure PG_Caption_FieldWithoutCaption()
    var
        R: Record "LT PG Caption Row";
        Gone: Record "LT PG Caption Row";
        Observer: Codeunit "Probe Observer";
    begin
        SeedCaption();
        R.SetLoadFields(Id);
        R.Get(1);
        Gone.Get(1);
        Gone.Delete();
        Observer.Observe('raised', Format(not TryReadPlain(R)));
        Observer.ObserveError('plain');
        Observer.Expect('raised', 'Yes');
        Observer.Expect('plain|text', 'JIT loading of field(s): ''Plain'' failed for table: ''Gone Caption Table'' identification values: ''Row Identifier=''1''''');
        Observer.Expect('plain|code', 'JustInTimeFieldLoad');
        Observer.Verify();
    end;

    local procedure SeedCaption()
    var
        R: Record "LT PG Caption Row";
    begin
        R.DeleteAll();
        R.Init();
        R.Id := 1;
        R.Info := 'info';
        R.Plain := 'plain';
        R.Insert();
    end;

    [TryFunction]
    local procedure TryReadInfo(var R: Record "LT PG Caption Row")
    var
        S: Text;
    begin
        S := R.Info;
    end;

    [TryFunction]
    local procedure TryReadPlain(var R: Record "LT PG Caption Row")
    var
        S: Text;
    begin
        S := R.Plain;
    end;

    // ---- 4. Date, Decimal, Guid, Option and Enum key parts ----

    [Test]
    procedure PG_TypedKey_Values()
    var
        R: Record "LT PG Typed Row";
        Gone: Record "LT PG Typed Row";
        Observer: Codeunit "Probe Observer";
        Id: Guid;
    begin
        Evaluate(Id, '{3F2504E0-4F89-41D3-9A0C-0305E82C3301}');
        R.DeleteAll();
        R.Init();
        R.DateKey := DMY2Date(7, 3, 2026);
        R.DecimalKey := 12.5;
        R.GuidKey := Id;
        R.OptionKey := R.OptionKey::Beta;
        R.EnumKey := R.EnumKey::Second;
        R.Name := 'typed';
        R.Insert();
        Clear(R);
        R.SetLoadFields(DateKey, DecimalKey, GuidKey, OptionKey, EnumKey);
        R.Get(DMY2Date(7, 3, 2026), 12.5, Id, R.OptionKey::Beta, R.EnumKey::Second);
        Gone.Get(DMY2Date(7, 3, 2026), 12.5, Id, R.OptionKey::Beta, R.EnumKey::Second);
        Gone.Delete();
        Observer.Observe('raised', Format(not TryReadTypedName(R)));
        Observer.ObserveError('name');
        Observer.Expect('raised', 'Yes');
        Observer.Expect('name|text', 'JIT loading of field(s): ''Name'' failed for table: ''LT PG Typed Row'' identification values: ''DateKey=''03/07/26'',DecimalKey=''12.5'',GuidKey=''{3F2504E0-4F89-41D3-9A0C-0305E82C3301}'',OptionKey=''Beta'',EnumKey=''Second Caption''''');
        Observer.Expect('name|code', 'JustInTimeFieldLoad');
        Observer.Verify();
    end;

    [Test]
    procedure PG_TypedKey_DefaultValues()
    var
        R: Record "LT PG Typed Row";
        Gone: Record "LT PG Typed Row";
        Observer: Codeunit "Probe Observer";
        Blank: Guid;
    begin
        R.DeleteAll();
        R.Init();
        R.Name := 'typed default';
        R.Insert();
        Clear(R);
        R.SetLoadFields(DateKey, DecimalKey, GuidKey, OptionKey, EnumKey);
        R.Get(0D, 0, Blank, R.OptionKey::Alpha, R.EnumKey::First);
        Gone.Get(0D, 0, Blank, R.OptionKey::Alpha, R.EnumKey::First);
        Gone.Delete();
        Observer.Observe('raised', Format(not TryReadTypedName(R)));
        Observer.ObserveError('name');
        Observer.Expect('raised', 'Yes');
        Observer.Expect('name|text', 'JIT loading of field(s): ''Name'' failed for table: ''LT PG Typed Row'' identification values: ''DateKey='''',DecimalKey=''0'',GuidKey=''{00000000-0000-0000-0000-000000000000}'',OptionKey=''Alpha'',EnumKey=''First''''');
        Observer.Expect('name|code', 'JustInTimeFieldLoad');
        Observer.Verify();
    end;

    [Test]
    procedure PG_TypedKey_NegativeAndFractionDecimal()
    var
        R: Record "LT PG Typed Row";
        Gone: Record "LT PG Typed Row";
        Observer: Codeunit "Probe Observer";
        Blank: Guid;
    begin
        R.DeleteAll();
        R.Init();
        R.DecimalKey := -1234.5678;
        R.OptionKey := R.OptionKey::Gamma;
        R.Name := 'typed negative';
        R.Insert();
        Clear(R);
        R.SetLoadFields(DateKey, DecimalKey, GuidKey, OptionKey, EnumKey);
        R.Get(0D, -1234.5678, Blank, R.OptionKey::Gamma, R.EnumKey::First);
        Gone.Get(0D, -1234.5678, Blank, R.OptionKey::Gamma, R.EnumKey::First);
        Gone.Delete();
        Observer.Observe('raised', Format(not TryReadTypedName(R)));
        Observer.ObserveError('name');
        Observer.Expect('raised', 'Yes');
        Observer.Expect('name|text', 'JIT loading of field(s): ''Name'' failed for table: ''LT PG Typed Row'' identification values: ''DateKey='''',DecimalKey=''-1,234.5678'',GuidKey=''{00000000-0000-0000-0000-000000000000}'',OptionKey=''Gamma'',EnumKey=''First''''');
        Observer.Expect('name|code', 'JustInTimeFieldLoad');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryReadTypedName(var R: Record "LT PG Typed Row")
    var
        S: Text;
    begin
        S := R.Name;
    end;

    // ---- 5. Escaping: apostrophe in a Code key, blank Code key ----

    [Test]
    procedure PG_CodeKey_Apostrophe()
    var
        R: Record "LT PG Code Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        PartialCode(R, 'O''NEIL');
        GoneCode('O''NEIL');
        Observer.Observe('raised', Format(not TryReadName(R)));
        Observer.ObserveError('name');
        Observer.Expect('raised', 'Yes');
        Observer.Expect('name|text', 'JIT loading of field(s): ''Name'' failed for table: ''LT PG Code Row'' identification values: ''No.=''O''NEIL''''');
        Observer.Expect('name|code', 'JustInTimeFieldLoad');
        Observer.Verify();
    end;

    [Test]
    procedure PG_CodeKey_Blank()
    var
        R: Record "LT PG Code Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        PartialCode(R, '');
        GoneCode('');
        Observer.Observe('raised', Format(not TryReadName(R)));
        Observer.ObserveError('name');
        Observer.Expect('raised', 'Yes');
        Observer.Expect('name|text', 'JIT loading of field(s): ''Name'' failed for table: ''LT PG Code Row'' identification values: ''No.=''''''');
        Observer.Expect('name|code', 'JustInTimeFieldLoad');
        Observer.Verify();
    end;

    // ---- 6. Other uses of the partial record after the row is gone ----

    [Test]
    procedure PG_Modify_UnloadedFieldAssigned()
    var
        R: Record "LT PG Code Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        PartialCode(R, 'A1');
        GoneCode('A1');
        R.Name := 'changed';
        asserterror R.Modify();
        Observer.ObserveError('modify');
        Observer.Expect('modify|text', 'The LT PG Code Row does not exist. Identification fields and values: No.=''A1''');
        Observer.Expect('modify|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure PG_Modify_NothingAssigned()
    var
        R: Record "LT PG Code Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        PartialCode(R, 'A1');
        GoneCode('A1');
        asserterror R.Modify();
        Observer.ObserveError('modify');
        Observer.Expect('modify|text', 'The LT PG Code Row does not exist. Identification fields and values: No.=''A1''');
        Observer.Expect('modify|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure PG_Modify_LoadedFieldAssigned()
    var
        R: Record "LT PG Code Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.SetLoadFields("No.", Amount);
        R.Get('A1');
        GoneCode('A1');
        R.Amount := 9;
        asserterror R.Modify();
        Observer.ObserveError('modify');
        Observer.Expect('modify|text', 'The LT PG Code Row does not exist. Identification fields and values: No.=''A1''');
        Observer.Expect('modify|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure PG_CalcFields_AfterGone()
    var
        R: Record "LT PG Code Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        PartialCode(R, 'A1');
        GoneCode('A1');
        Observer.Observe('raised', Format(not TryCalcLineCount(R)));
        Observer.ObserveError('calc');
        Observer.Observe('lineCount', Format(R."Line Count"));
        Observer.Expect('raised', 'No');
        Observer.Expect('calc|text', '');
        Observer.Expect('calc|code', '');
        Observer.Expect('lineCount', '1');
        Observer.Verify();
    end;

    [Test]
    procedure PG_Validate_FieldWithoutTrigger()
    var
        R: Record "LT PG Code Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        PartialCode(R, 'A1');
        GoneCode('A1');
        Observer.Observe('raised', Format(not TryValidateAmount(R)));
        Observer.ObserveError('validate');
        Observer.Expect('raised', 'Yes');
        Observer.Expect('validate|text', 'JIT loading of field(s): ''Amount'' failed for table: ''LT PG Code Row'' identification values: ''No.=''A1''''');
        Observer.Expect('validate|code', 'JustInTimeFieldLoad');
        Observer.Verify();
    end;

    // OnValidate of Note reads Name, which was not loaded.
    [Test]
    procedure PG_Validate_TriggerReadsUnloadedField()
    var
        R: Record "LT PG Code Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        PartialCode(R, 'A1');
        GoneCode('A1');
        Observer.Observe('raised', Format(not TryValidateNote(R)));
        Observer.ObserveError('validate');
        Observer.Expect('raised', 'Yes');
        Observer.Expect('validate|text', 'JIT loading of field(s): ''Name'' failed for table: ''LT PG Code Row'' identification values: ''No.=''A1''''');
        Observer.Expect('validate|code', 'JustInTimeFieldLoad');
        Observer.Verify();
    end;

    [Test]
    procedure PG_Rename_AfterGone()
    var
        R: Record "LT PG Code Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        PartialCode(R, 'A1');
        GoneCode('A1');
        asserterror R.Rename('A9');
        Observer.ObserveError('rename');
        Observer.Expect('rename|text', 'JIT loading of field(s): ''Name, Note, Amount, ReadName'' failed for table: ''LT PG Code Row'' identification values: ''No.=''A1''''');
        Observer.Expect('rename|code', 'JustInTimeFieldLoad');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryCalcLineCount(var R: Record "LT PG Code Row")
    begin
        R.CalcFields("Line Count");
    end;

    [TryFunction]
    local procedure TryValidateAmount(var R: Record "LT PG Code Row")
    begin
        R.Validate(Amount, 7);
    end;

    [TryFunction]
    local procedure TryValidateNote(var R: Record "LT PG Code Row")
    begin
        R.Validate(Note, 'validated');
    end;

    // ---- 7. LoadFields statement and AddLoadFields ----

    [Test]
    procedure PG_LoadFieldsStatement_AfterGone()
    var
        R: Record "LT PG Code Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        PartialCode(R, 'A1');
        GoneCode('A1');
        Observer.Observe('raised', Format(not TryLoadFieldsName(R)));
        Observer.ObserveError('loadfields');
        Observer.Observe('nameLoaded', Format(R.AreFieldsLoaded(Name)));
        Observer.Observe('raisedName', Format(not TryReadName(R)));
        Observer.ObserveError('name');
        Observer.Expect('raised', 'No');
        Observer.Expect('loadfields|text', '');
        Observer.Expect('loadfields|code', '');
        Observer.Expect('nameLoaded', 'No');
        Observer.Expect('raisedName', 'Yes');
        Observer.Expect('name|text', 'JIT loading of field(s): ''Name'' failed for table: ''LT PG Code Row'' identification values: ''No.=''A1''''');
        Observer.Expect('name|code', 'JustInTimeFieldLoad');
        Observer.Verify();
    end;

    [Test]
    procedure PG_LoadFieldsStatement_TwoFields_AfterGone()
    var
        R: Record "LT PG Code Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        PartialCode(R, 'A1');
        GoneCode('A1');
        Observer.Observe('raised', Format(not TryLoadFieldsNameNote(R)));
        Observer.ObserveError('loadfields');
        Observer.Observe('raisedName', Format(not TryReadName(R)));
        Observer.ObserveError('name');
        Observer.Observe('raisedNote', Format(not TryReadNote(R)));
        Observer.ObserveError('note');
        Observer.Expect('raised', 'No');
        Observer.Expect('loadfields|text', '');
        Observer.Expect('loadfields|code', '');
        Observer.Expect('raisedName', 'Yes');
        Observer.Expect('name|text', 'JIT loading of field(s): ''Name'' failed for table: ''LT PG Code Row'' identification values: ''No.=''A1''''');
        Observer.Expect('name|code', 'JustInTimeFieldLoad');
        Observer.Expect('raisedNote', 'Yes');
        Observer.Expect('note|text', 'JIT loading of field(s): ''Note'' failed for table: ''LT PG Code Row'' identification values: ''No.=''A1''''');
        Observer.Expect('note|code', 'JustInTimeFieldLoad');
        Observer.Verify();
    end;

    [Test]
    procedure PG_AddLoadFields_ReadAddedField()
    var
        R: Record "LT PG Code Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.SetLoadFields("No.");
        R.AddLoadFields(Note);
        R.Get('A1');
        GoneCode('A1');
        Observer.Observe('raisedNote', Format(not TryReadNote(R)));
        Observer.ObserveError('note');
        Observer.Observe('note', R.Note);
        Observer.Expect('raisedNote', 'No');
        Observer.Expect('note|text', '');
        Observer.Expect('note|code', '');
        Observer.Expect('note', 'note one');
        Observer.Verify();
    end;

    [Test]
    procedure PG_AddLoadFields_ReadOtherField()
    var
        R: Record "LT PG Code Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.SetLoadFields("No.");
        R.AddLoadFields(Note);
        R.Get('A1');
        GoneCode('A1');
        Observer.Observe('raisedName', Format(not TryReadName(R)));
        Observer.ObserveError('name');
        Observer.Expect('raisedName', 'Yes');
        Observer.Expect('name|text', 'JIT loading of field(s): ''Name'' failed for table: ''LT PG Code Row'' identification values: ''No.=''A1''''');
        Observer.Expect('name|code', 'JustInTimeFieldLoad');
        Observer.Verify();
    end;

    [Test]
    procedure PG_SetLoadFields_NameOnly_ReadNote()
    var
        R: Record "LT PG Code Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.SetLoadFields(Name);
        R.Get('A1');
        GoneCode('A1');
        Observer.Observe('raisedNote', Format(not TryReadNote(R)));
        Observer.ObserveError('note');
        Observer.Observe('raisedName', Format(not TryReadName(R)));
        Observer.ObserveError('name');
        Observer.Observe('name', R.Name);
        Observer.Expect('raisedNote', 'Yes');
        Observer.Expect('note|text', 'JIT loading of field(s): ''Note'' failed for table: ''LT PG Code Row'' identification values: ''No.=''A1''''');
        Observer.Expect('note|code', 'JustInTimeFieldLoad');
        Observer.Expect('raisedName', 'No');
        Observer.Expect('name|text', '');
        Observer.Expect('name|code', '');
        Observer.Expect('name', 'one');
        Observer.Verify();
    end;

    [Test]
    procedure PG_TwoUnloadedFieldsInOneExpression()
    var
        R: Record "LT PG Code Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        PartialCode(R, 'A1');
        GoneCode('A1');
        Observer.Observe('raised', Format(not TryReadBoth(R)));
        Observer.ObserveError('both');
        Observer.Expect('raised', 'Yes');
        Observer.Expect('both|text', 'JIT loading of field(s): ''Name'' failed for table: ''LT PG Code Row'' identification values: ''No.=''A1''''');
        Observer.Expect('both|code', 'JustInTimeFieldLoad');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryLoadFieldsName(var R: Record "LT PG Code Row")
    var
        Ok: Boolean;
    begin
        Ok := R.LoadFields(Name);
    end;

    [TryFunction]
    local procedure TryLoadFieldsNameNote(var R: Record "LT PG Code Row")
    var
        Ok: Boolean;
    begin
        Ok := R.LoadFields(Name, Note);
    end;

    // ---- 8. RecordRef ----

    [Test]
    procedure PG_RecordRef_Get_ReadField()
    var
        Value: Text;
        R: Record "LT PG Code Row";
        RecRef: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.Get('A1');
        RecRef.Open(Database::"LT PG Code Row");
        RecRef.SetLoadFields(R.FieldNo("No."));
        RecRef.Get(R.RecordId);
        GoneCode('A1');
        Observer.Observe('raised', Format(not TryReadRefField(RecRef, R.FieldNo(Name), Value)));
        Observer.ObserveError('name');
        Observer.Observe('namevalue', Value);
        Observer.Expect('raised', 'No');
        Observer.Expect('name|text', '');
        Observer.Expect('name|code', '');
        Observer.Expect('namevalue', 'one');
        Observer.Verify();
    end;

    [Test]
    procedure PG_RecordRef_FindFirst_ReadField()
    var
        Value: Text;
        R: Record "LT PG Code Row";
        RecRef: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        RecRef.Open(Database::"LT PG Code Row");
        RecRef.SetLoadFields(R.FieldNo("No."));
        RecRef.Field(R.FieldNo(Name)).SetRange('one');
        RecRef.FindFirst();
        GoneCode('A1');
        Observer.Observe('raised', Format(not TryReadRefField(RecRef, R.FieldNo(Name), Value)));
        Observer.ObserveError('name');
        Observer.Observe('namevalue', Value);
        Observer.Expect('raised', 'No');
        Observer.Expect('name|text', '');
        Observer.Expect('name|code', '');
        Observer.Expect('namevalue', 'one');
        Observer.Verify();
    end;

    [Test]
    procedure PG_RecordRef_AddLoadFields_ReadAddedField()
    var
        Value: Text;
        R: Record "LT PG Code Row";
        RecRef: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        R.Get('A1');
        RecRef.Open(Database::"LT PG Code Row");
        RecRef.SetLoadFields(R.FieldNo("No."));
        RecRef.AddLoadFields(R.FieldNo(Note));
        RecRef.Get(R.RecordId);
        GoneCode('A1');
        Observer.Observe('raisedNote', Format(not TryReadRefField(RecRef, R.FieldNo(Note), Value)));
        Observer.ObserveError('note');
        Observer.Observe('notevalue', Value);
        Observer.Observe('raisedName', Format(not TryReadRefField(RecRef, R.FieldNo(Name), Value)));
        Observer.ObserveError('name');
        Observer.Observe('namevalue', Value);
        Observer.Expect('raisedNote', 'No');
        Observer.Expect('note|text', '');
        Observer.Expect('note|code', '');
        Observer.Expect('notevalue', 'note one');
        Observer.Expect('raisedName', 'No');
        Observer.Expect('name|text', '');
        Observer.Expect('name|code', '');
        Observer.Expect('namevalue', 'one');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryReadRefField(var RecRef: RecordRef; FieldNumber: Integer; var Value: Text)
    var
        FldRef: FieldRef;
    begin
        FldRef := RecRef.Field(FieldNumber);
        Value := Format(FldRef.Value);
    end;

    // ---- 9. How the row goes away ----

    [Test]
    procedure PG_GoneByDeleteAllWithFilter()
    var
        R: Record "LT PG Code Row";
        Gone: Record "LT PG Code Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        PartialCode(R, 'A1');
        Gone.SetRange(Name, 'one');
        Gone.DeleteAll();
        Observer.Observe('raised', Format(not TryReadName(R)));
        Observer.ObserveError('name');
        Observer.Expect('raised', 'Yes');
        Observer.Expect('name|text', 'JIT loading of field(s): ''Name'' failed for table: ''LT PG Code Row'' identification values: ''No.=''A1''''');
        Observer.Expect('name|code', 'JustInTimeFieldLoad');
        Observer.Verify();
    end;

    [Test]
    procedure PG_GoneByDeleteAllWithTrigger()
    var
        R: Record "LT PG Code Row";
        Gone: Record "LT PG Code Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        PartialCode(R, 'A1');
        Gone.SetFilter("No.", 'A1|A2');
        Gone.DeleteAll(true);
        Observer.Observe('raised', Format(not TryReadName(R)));
        Observer.ObserveError('name');
        Observer.Expect('raised', 'Yes');
        Observer.Expect('name|text', 'JIT loading of field(s): ''Name'' failed for table: ''LT PG Code Row'' identification values: ''No.=''A1''''');
        Observer.Expect('name|code', 'JustInTimeFieldLoad');
        Observer.Verify();
    end;

    [Test]
    procedure PG_GoneByDeleteAllNoFilter()
    var
        R: Record "LT PG Code Row";
        Gone: Record "LT PG Code Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        PartialCode(R, 'A1');
        Gone.DeleteAll();
        Observer.Observe('raised', Format(not TryReadName(R)));
        Observer.ObserveError('name');
        Observer.Expect('raised', 'Yes');
        Observer.Expect('name|text', 'JIT loading of field(s): ''Name'' failed for table: ''LT PG Code Row'' identification values: ''No.=''A1''''');
        Observer.Expect('name|code', 'JustInTimeFieldLoad');
        Observer.Verify();
    end;

    [Test]
    procedure PG_GoneByRenameToAnotherKey()
    var
        R: Record "LT PG Code Row";
        Moved: Record "LT PG Code Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        PartialCode(R, 'A1');
        Moved.Get('A1');
        Moved.Rename('A7');
        Observer.Observe('raised', Format(not TryReadName(R)));
        Observer.ObserveError('name');
        Observer.Expect('raised', 'Yes');
        Observer.Expect('name|text', 'JIT loading of field(s): ''Name'' failed for table: ''LT PG Code Row'' identification values: ''No.=''A1''''');
        Observer.Expect('name|code', 'JustInTimeFieldLoad');
        Observer.Verify();
    end;

    [Test]
    procedure PG_RowDeletedAndInsertedAgainWithSameKey()
    var
        R: Record "LT PG Code Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        PartialCode(R, 'A1');
        GoneCode('A1');
        AddCode('A1', 'again', 'note again');
        Observer.Observe('raised', Format(not TryReadName(R)));
        Observer.ObserveError('name');
        Observer.Expect('raised', 'Yes');
        Observer.Expect('name|text', 'The field ''$systemId'' on table ''LT PG Code Row'' has changed in the database between initial and JIT load. The fields causing the JIT load are: ''Name''.\\The error may be transient if multiple users are editing the same record or permanent if the same user edits the record while keeping an old record.\\Identification values: ''No.=''A1''''\    ');
        Observer.Expect('name|code', 'InconsistentRead');
        Observer.Verify();
    end;

    // Waldo run 2 (al-runner issue 6924): Delete on a partially loaded record while subscribers and the table's OnDelete trigger read a
    // field that was not loaded. Table 97260 below (single Integer key, captions differ from names). Codeunit 97262 records, for every
    // call of OnBeforeDeleteEvent, OnDelete and OnAfterDeleteEvent, the value or the error of reading a loaded and an unloaded field of Rec.
    var
        DelLog: Codeunit "LT WA Del Log";

    local procedure WA_DelSeed()
    var
        Row: Record "LT WA Del Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'N1';
        Row.Info := 'I1';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'N2';
        Row.Info := 'I2';
        Row.Insert();
        DelLog.Wipe();
    end;

    local procedure WA_DelReport(var Observer: Codeunit "Probe Observer")
    var
        Row: Record "LT WA Del Row";
        Entry: Text;
        Index: Integer;
    begin
        for Index := 1 to DelLog.Count() do begin
            Entry := DelLog.Entry(Index);
            Observer.Observe('log ' + Format(Index), Entry);
        end;
        Observer.Observe('log count', Format(DelLog.Count()));
        Observer.Observe('rows left', Format(Row.Count()));
    end;

    [TryFunction]
    local procedure WA_TryReadInfo(var Row: Record "LT WA Del Row"; var Value: Text)
    begin
        Value := Row.Info;
    end;

    local procedure WA_BufferAfter(var Observer: Codeunit "Probe Observer"; var Row: Record "LT WA Del Row")
    var
        InfoValue: Text;
    begin
        ClearLastError();
        if WA_TryReadInfo(Row, InfoValue) then
            Observer.Observe('buffer info after', 'value ' + InfoValue)
        else
            Observer.ObserveError('buffer info after');
        Observer.Observe('buffer id after', Format(Row.Id));
    end;

    [Test]
    procedure WA_Delete_FindSetForUpdate_DeleteTrue()
    var
        Row: Record "LT WA Del Row";
        Observer: Codeunit "Probe Observer";
    begin
        WA_DelSeed();
        Row.SetLoadFields(Name);
        Row.FindSet(true);
        repeat
            Row.Delete(true);
        until Row.Next() = 0;
        WA_DelReport(Observer);
        WA_BufferAfter(Observer, Row);
        Observer.Finish();
    end;

    [Test]
    procedure WA_Delete_FindSetForUpdate_DeleteNoArgument()
    var
        Row: Record "LT WA Del Row";
        Observer: Codeunit "Probe Observer";
    begin
        WA_DelSeed();
        Row.SetLoadFields(Name);
        Row.FindSet(true);
        repeat
            Row.Delete();
        until Row.Next() = 0;
        WA_DelReport(Observer);
        WA_BufferAfter(Observer, Row);
        Observer.Finish();
    end;

    [Test]
    procedure WA_Delete_FindSetReadOnly_DeleteTrue()
    var
        Row: Record "LT WA Del Row";
        Observer: Codeunit "Probe Observer";
    begin
        WA_DelSeed();
        Row.SetLoadFields(Name);
        Row.FindSet();
        repeat
            Row.Delete(true);
        until Row.Next() = 0;
        WA_DelReport(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure WA_Delete_Get_DeleteTrue()
    var
        Row: Record "LT WA Del Row";
        Observer: Codeunit "Probe Observer";
    begin
        WA_DelSeed();
        Row.SetLoadFields(Name);
        Row.Get(1);
        Row.Delete(true);
        WA_DelReport(Observer);
        WA_BufferAfter(Observer, Row);
        Observer.Finish();
    end;

    [Test]
    procedure WA_Delete_FindFirst_DeleteTrue()
    var
        Row: Record "LT WA Del Row";
        Observer: Codeunit "Probe Observer";
    begin
        WA_DelSeed();
        Row.SetLoadFields(Name);
        Row.FindFirst();
        Row.Delete(true);
        WA_DelReport(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure WA_Delete_AllLoaded_DeleteTrue()
    var
        Row: Record "LT WA Del Row";
        Observer: Codeunit "Probe Observer";
    begin
        WA_DelSeed();
        Row.FindSet(true);
        repeat
            Row.Delete(true);
        until Row.Next() = 0;
        WA_DelReport(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure WA_DeleteAll_True_WithSetLoadFields()
    var
        Row: Record "LT WA Del Row";
        Observer: Codeunit "Probe Observer";
    begin
        WA_DelSeed();
        Row.SetLoadFields(Name);
        Row.DeleteAll(true);
        WA_DelReport(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure WA_DeleteAll_NoArgument_WithSetLoadFields()
    var
        Row: Record "LT WA Del Row";
        Observer: Codeunit "Probe Observer";
    begin
        WA_DelSeed();
        Row.SetLoadFields(Name);
        Row.DeleteAll();
        WA_DelReport(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure WA_DeleteAll_True_WithFilterAndSetLoadFields()
    var
        Row: Record "LT WA Del Row";
        Observer: Codeunit "Probe Observer";
    begin
        WA_DelSeed();
        Row.SetRange(Id, 2);
        Row.SetLoadFields(Name);
        Row.DeleteAll(true);
        WA_DelReport(Observer);
        Observer.Finish();
    end;

    // Controls: the same partial read and Delete on a table without trigger and subscribers (Plain) and on a table with only an OnDelete
    // trigger (Trig). Then the unloaded field of the buffer is read after the Delete.
    [TryFunction]
    local procedure WA_TryReadPlainInfo(var Row: Record "LT WA Del Plain"; var Value: Text)
    begin
        Value := Row.Info;
    end;

    [TryFunction]
    local procedure WA_TryReadTrigInfo(var Row: Record "LT WA Del Trig"; var Value: Text)
    begin
        Value := Row.Info;
    end;

    [Test]
    procedure WA_Delete_Control_PlainTable()
    var
        Row: Record "LT WA Del Plain";
        Observer: Codeunit "Probe Observer";
        Value: Text;
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'N1';
        Row.Info := 'I1';
        Row.Insert();
        Row.Id := 2;
        Row.Info := 'I2';
        Row.Insert();
        Row.Reset();
        Row.SetLoadFields(Name);
        Row.FindSet(true);
        repeat
            Row.Delete(true);
        until Row.Next() = 0;
        ClearLastError();
        if WA_TryReadPlainInfo(Row, Value) then
            Observer.Observe('buffer info after', 'value ' + Value)
        else
            Observer.ObserveError('buffer info after');
        Observer.Observe('rows left', Format(Row.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure WA_Delete_Control_PlainTable_NoArgument()
    var
        Row: Record "LT WA Del Plain";
        Observer: Codeunit "Probe Observer";
        Value: Text;
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'N1';
        Row.Info := 'I1';
        Row.Insert();
        Row.SetLoadFields(Name);
        Row.FindFirst();
        Row.Delete();
        ClearLastError();
        if WA_TryReadPlainInfo(Row, Value) then
            Observer.Observe('buffer info after', 'value ' + Value)
        else
            Observer.ObserveError('buffer info after');
        Observer.Finish();
    end;

    [Test]
    procedure WA_Delete_Control_TriggerTable()
    var
        Row: Record "LT WA Del Trig";
        Observer: Codeunit "Probe Observer";
        Value: Text;
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'N1';
        Row.Info := 'I1';
        Row.Insert();
        Row.SetLoadFields(Name);
        Row.FindFirst();
        Row.Delete(true);
        ClearLastError();
        if WA_TryReadTrigInfo(Row, Value) then
            Observer.Observe('buffer info after', 'value ' + Value)
        else
            Observer.ObserveError('buffer info after');
        Observer.Finish();
    end;
}

// local objects of the WA_Delete tests (al-runner issue 6924, waldo run 2).
table 97260 "LT WA Del Row"
{
    Caption = 'Wa Del Caption Table';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { Caption = 'Row Identifier'; }
        field(2; Name; Text[30]) { Caption = 'Name Caption'; }
        field(3; Info; Text[30]) { Caption = 'Info Caption'; }
    }

    keys { key(PK; Id) { Clustered = true; } }

    trigger OnDelete()
    var
        Log: Codeunit "LT WA Del Log";
    begin
        Log.Describe('OnDelete', Rec, 'n/a');
    end;
}

codeunit 97261 "LT WA Del Subscribers"
{
    [EventSubscriber(ObjectType::Table, Database::"LT WA Del Row", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure OnBeforeDelete(var Rec: Record "LT WA Del Row"; RunTrigger: Boolean)
    var
        Log: Codeunit "LT WA Del Log";
    begin
        Log.Describe('OnBeforeDeleteEvent', Rec, Format(RunTrigger));
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT WA Del Row", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDelete(var Rec: Record "LT WA Del Row"; RunTrigger: Boolean)
    var
        Log: Codeunit "LT WA Del Log";
    begin
        Log.Describe('OnAfterDeleteEvent', Rec, Format(RunTrigger));
    end;
}

codeunit 97262 "LT WA Del Log"
{
    SingleInstance = true;

    var
        Entries: List of [Text];

    procedure Wipe()
    begin
        if Entries.Count() > 0 then
            Entries.RemoveRange(1, Entries.Count());
    end;

    procedure Count(): Integer
    begin
        exit(Entries.Count());
    end;

    procedure Entry(Index: Integer): Text
    begin
        exit(Entries.Get(Index));
    end;

    procedure Describe(EventName: Text; var Row: Record "LT WA Del Row"; RunTrigger: Text)
    var
        NameText: Text;
        InfoText: Text;
    begin
        ClearLastError();
        if TryReadName(Row, NameText) then
            NameText := 'value ' + NameText
        else
            NameText := 'error ' + GetLastErrorCode() + ': ' + GetLastErrorText();
        ClearLastError();
        if TryReadInfo(Row, InfoText) then
            InfoText := 'value ' + InfoText
        else
            InfoText := 'error ' + GetLastErrorCode() + ': ' + GetLastErrorText();
        ClearLastError();
        Entries.Add(EventName + ' | trigger ' + RunTrigger + ' | id ' + Format(Row.Id) + ' | name ' + NameText + ' | info ' + InfoText);
    end;

    [TryFunction]
    local procedure TryReadName(var Row: Record "LT WA Del Row"; var Value: Text)
    begin
        Value := Row.Name;
    end;

    [TryFunction]
    local procedure TryReadInfo(var Row: Record "LT WA Del Row"; var Value: Text)
    begin
        Value := Row.Info;
    end;
}

table 97263 "LT WA Del Plain"
{
    Caption = 'Wa Del Plain Caption';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { Caption = 'Row Identifier'; }
        field(2; Name; Text[30]) { Caption = 'Name Caption'; }
        field(3; Info; Text[30]) { Caption = 'Info Caption'; }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 97264 "LT WA Del Trig"
{
    Caption = 'Wa Del Trigger Caption';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { Caption = 'Row Identifier'; }
        field(2; Name; Text[30]) { Caption = 'Name Caption'; }
        field(3; Info; Text[30]) { Caption = 'Info Caption'; }
    }

    keys { key(PK; Id) { Clustered = true; } }

    trigger OnDelete()
    begin
        Name := Name + '!';
    end;
}
