// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-loadfields-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 70904, codeunit 70905
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Ok := Rec.LoadFields(...) after Get, after Get under SetLoadFields, after Find and FindFirst, after a field assigned following the Get
// BC versions: 29 (27 and 28 by CI)

table 70904 "LT P170 Load Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[50]) { }
        field(3; Amount; Decimal) { }
        field(4; Note; Text[50]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 70905 "LT P170 LoadFields"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT P170 Load Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Amount := 10;
        Row.Note := 'n1';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'two';
        Row.Amount := 20;
        Row.Note := 'n2';
        Row.Insert();
    end;

    [Test]
    procedure P170_LoadFields_Function_AfterFullGet()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P170 Load Row";
        Ok: Boolean;
    begin
        Seed();
        Ok := Row.Get(1);
        Observer.Observe('get', Format(Ok));
        Ok := Row.LoadFields(Name);
        Observer.Observe('load_name', Format(Ok));
        Observer.Observe('name', Row.Name);
        Observer.Observe('amount', Format(Row.Amount));
        Observer.Observe('id', Format(Row.Id));
        Ok := Row.LoadFields(Name, Amount, Note);
        Observer.Observe('load_all', Format(Ok));
        Observer.Observe('note', Row.Note);
        Observer.Observe('loaded_note', Format(Row.AreFieldsLoaded(Note)));
        Observer.Expect('get', 'Yes');
        Observer.Expect('load_name', 'Yes');
        Observer.Expect('name', 'one');
        Observer.Expect('amount', '10');
        Observer.Expect('id', '1');
        Observer.Expect('load_all', 'Yes');
        Observer.Expect('note', 'n1');
        Observer.Expect('loaded_note', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P170_LoadFields_Function_AfterAssignFollowingGet()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P170 Load Row";
        Ok: Boolean;
    begin
        Seed();
        Row.Get(1);
        Row.Name := 'changed';
        Row.Amount := 99;
        Ok := Row.LoadFields(Name);
        Observer.Observe('load_name', Format(Ok));
        Observer.Observe('name', Row.Name);
        Observer.Observe('amount', Format(Row.Amount));
        Ok := Row.LoadFields(Amount);
        Observer.Observe('load_amount', Format(Ok));
        Observer.Observe('amount_after', Format(Row.Amount));
        Observer.Expect('load_name', 'Yes');
        Observer.Expect('name', 'changed');
        Observer.Expect('amount', '99');
        Observer.Expect('load_amount', 'Yes');
        Observer.Expect('amount_after', '99');
        Observer.Verify();
    end;

    [Test]
    procedure P170_LoadFields_Function_AfterGetUnderSetLoadFields()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P170 Load Row";
        Ok: Boolean;
    begin
        Seed();
        Row.SetLoadFields(Name);
        Row.Get(1);
        Observer.Observe('loaded_name', Format(Row.AreFieldsLoaded(Name)));
        Observer.Observe('loaded_amount', Format(Row.AreFieldsLoaded(Amount)));
        Ok := Row.LoadFields(Amount);
        Observer.Observe('load_amount', Format(Ok));
        Observer.Observe('loaded_amount_after', Format(Row.AreFieldsLoaded(Amount)));
        Observer.Observe('amount', Format(Row.Amount));
        Ok := Row.LoadFields(Name, Amount, Note);
        Observer.Observe('load_all', Format(Ok));
        Observer.Observe('loaded_note_after', Format(Row.AreFieldsLoaded(Note)));
        Observer.Observe('note', Row.Note);
        Observer.Expect('loaded_name', 'Yes');
        Observer.Expect('loaded_amount', 'No');
        Observer.Expect('load_amount', 'Yes');
        Observer.Expect('loaded_amount_after', 'Yes');
        Observer.Expect('amount', '10');
        Observer.Expect('load_all', 'Yes');
        Observer.Expect('loaded_note_after', 'Yes');
        Observer.Expect('note', 'n1');
        Observer.Verify();
    end;

    [Test]
    procedure P170_LoadFields_Function_AfterFindVariants()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P170 Load Row";
        Ok: Boolean;
    begin
        Seed();
        Row.SetRange(Id, 2);
        Ok := Row.FindFirst();
        Observer.Observe('findfirst', Format(Ok));
        Ok := Row.LoadFields(Name);
        Observer.Observe('after_findfirst', Format(Ok));
        Observer.Observe('name', Row.Name);
        Clear(Row);
        Row.SetRange(Id, 1);
        Ok := Row.Find('-');
        Observer.Observe('find', Format(Ok));
        Ok := Row.LoadFields(Amount);
        Observer.Observe('after_find', Format(Ok));
        Observer.Observe('amount', Format(Row.Amount));
        Observer.Expect('findfirst', 'Yes');
        Observer.Expect('after_findfirst', 'Yes');
        Observer.Expect('name', 'two');
        Observer.Expect('find', 'Yes');
        Observer.Expect('after_find', 'Yes');
        Observer.Expect('amount', '10');
        Observer.Verify();
    end;

    [Test]
    procedure P170_LoadFields_Function_AfterFailedGetAndOnDeletedRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P170 Load Row";
        Gone: Record "LT P170 Load Row";
        Ok: Boolean;
    begin
        Seed();
        Ok := Row.Get(77);
        Observer.Observe('get_missing', Format(Ok));
        Ok := Row.LoadFields(Name);
        Observer.Observe('load_after_missing', Format(Ok));
        Row.Get(2);
        Gone.Get(2);
        Gone.Delete();
        Ok := Row.LoadFields(Name);
        Observer.Observe('load_row_deleted_meanwhile', Format(Ok));
        Observer.Observe('name', Row.Name);
        Observer.Expect('get_missing', 'No');
        Observer.Expect('load_after_missing', 'No');
        Observer.Expect('load_row_deleted_meanwhile', 'Yes');
        Observer.Expect('name', 'two');
        Observer.Verify();
    end;

    [Test]
    procedure P170_LoadFields_Statement_ThenReadAfterGet()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P170 Load Row";
    begin
        Seed();
        Row.Get(1);
        Row.LoadFields(Note);
        Observer.Observe('note', Row.Note);
        Observer.Observe('name', Row.Name);
        Observer.Observe('loaded_note', Format(Row.AreFieldsLoaded(Note)));
        Observer.Observe('loaded_name', Format(Row.AreFieldsLoaded(Name)));
        Observer.Expect('note', 'n1');
        Observer.Expect('name', 'one');
        Observer.Expect('loaded_note', 'Yes');
        Observer.Expect('loaded_name', 'Yes');
        Observer.Verify();
    end;


    // Corpus issue 668 item 37 (writer BQ): just-in-time load of a field that SetLoadFields left out, after the row was deleted (microsoft/AL
    // issue 6852). LT BQ Ret Row (record/lt-bq-odd-leads/BqObjects.al) has Name and the table-extension field ExtNote. Each case is a test of
    // its own: its error, if any, is the result.
    local procedure BqSeedJit()
    var
        R: Record "LT BQ Ret Row";
    begin
        R.DeleteAll();
        R.Init();
        R.Id := 1;
        R.Name := 'one';
        R.ExtNote := 'note one';
        R.Insert();
        R.Init();
        R.Id := 2;
        R.Name := 'two';
        R.ExtNote := 'note two';
        R.Insert();
    end;

    [Test]
    procedure P170_JitLoad_NormalField_RowDeletedByAnotherVariable_BQ()
    var
        R: Record "LT BQ Ret Row";
        Gone: Record "LT BQ Ret Row";
        Observer: Codeunit "Probe Observer";
    begin
        BqSeedJit();
        R.SetLoadFields(Id);
        R.Get(1);
        Gone.Get(1);
        Gone.Delete();
        asserterror Observer.Observe('name', R.Name);
        Observer.ObserveError('name');
        Observer.Expect('name|text', 'JIT loading of field(s): ''Name'' failed for table: ''LT BQ Ret Row'' identification values: ''Id=''1''''');
        Observer.Expect('name|code', 'JustInTimeFieldLoad');
        Observer.Verify();
    end;

    [Test]
    procedure P170_JitLoad_ExtensionField_RowDeletedByAnotherVariable_BQ()
    var
        R: Record "LT BQ Ret Row";
        Gone: Record "LT BQ Ret Row";
        Observer: Codeunit "Probe Observer";
    begin
        BqSeedJit();
        R.SetLoadFields(Id);
        R.Get(1);
        Gone.Get(1);
        Gone.Delete();
        asserterror Observer.Observe('extNote', R.ExtNote);
        Observer.ObserveError('extNote');
        Observer.Expect('extNote|text', 'JIT loading of field(s): ''ExtNote'' failed for table: ''LT BQ Ret Row'' identification values: ''Id=''1''''');
        Observer.Expect('extNote|code', 'JustInTimeFieldLoad');
        Observer.Verify();
    end;

    [Test]
    procedure P170_JitLoad_After_Delete_Of_The_Same_Partial_Record_BQ()
    var
        R: Record "LT BQ Ret Row";
        Observer: Codeunit "Probe Observer";
    begin
        BqSeedJit();
        R.SetLoadFields(Id);
        R.Get(2);
        Observer.Observe('nameLoadedBefore', Format(R.AreFieldsLoaded(Name)));
        R.Delete();
        Observer.Observe('nameLoadedAfterDelete', Format(R.AreFieldsLoaded(Name)));
        Observer.Observe('extLoadedAfterDelete', Format(R.AreFieldsLoaded(ExtNote)));
        Observer.Observe('name', R.Name);
        Observer.Expect('nameLoadedBefore', 'No');
        Observer.Expect('nameLoadedAfterDelete', 'Yes');
        Observer.Expect('extLoadedAfterDelete', 'Yes');
        Observer.Expect('name', 'two');
        Observer.Verify();
    end;
}
