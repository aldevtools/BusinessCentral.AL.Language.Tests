// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-methods
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Writer Y36 (gap cycle 3, C3-06b): a table procedure named like a built-in record method, called with the SAME number of arguments
// as the built-in but with other types. Neighbour of BmBuiltinNameProcedures.al (same arity and types).
// Compile (alc 18.1 runtime 16.0, alc 30 runtime 17.0 and 18.0, same result; no warning AL0524 for any of these, the types differ):
//   Row.Get(1, 2) next to own Get(Record; Record), Row.Delete(true) next to own Delete(Text), Row.Validate(Note, 'x') next to own
//   Validate(Text; Text), Row3.Get('A') next to own Get(Code[20]) all compile. Row.Insert(true, true, true) next to own
//   Insert(Integer; Text; Boolean) does not compile (AL0133, must-not-compile case 2500).
// The tests record which one runs: the table procedure (it writes a marker into Note and changes no row) or the built-in.
// BC (SaaS BC 29): the built-in runs whenever the call does not fit the own procedure's types: Get(1, 2) raises AL:ToManyKeyFields
//   (built-in Get, one-field key), Delete(true) deletes the row, Validate(Note, 'x') validates the field. With matching types the own
//   procedure runs: Delete('why') and Validate('Note', 'y') (Text, Text) run the table procedure, Get('A') on the Code key table runs
//   own Get(Code[20]) (returns No, nothing loaded). Bare Insert() and Get(1) inside the table code reach the built-ins.
// BC versions: 29 (27 and 28 by CI)
table 92370 "LT Y36 SameArity"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Note; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    procedure Get(A: Record "LT Y36 SameArity Ref"; B: Record "LT Y36 SameArity Ref"): Boolean
    begin
        Note := 'own Get(rec,rec)';
        exit(false);
    end;

    procedure Insert(A: Integer; B: Text; C: Boolean)
    begin
        Note := 'own Insert(3)';
    end;

    procedure Delete(Reason: Text): Boolean
    begin
        Note := 'own Delete(Text)';
        exit(false);
    end;

    procedure Validate(FieldName: Text; Value: Text)
    begin
        Note := 'own Validate';
    end;

    procedure BareInsertAndGet(NewId: Integer; GetId: Integer): Text
    var
        Found: Boolean;
    begin
        Id := NewId;
        Note := 'inside';
        Insert();
        Note := 'before get';
        Found := Get(GetId);
        exit(Format(Found) + ' ' + Note);
    end;
}

table 92371 "LT Y36 SameArity Ref"
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
}

table 92372 "LT Y36 CodeKey"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; No; Code[20]) { }
        field(2; Note; Text[30]) { }
    }

    keys
    {
        key(PK; No) { Clustered = true; }
    }

    procedure Get(No: Code[20]): Boolean
    begin
        Note := 'own Get(Code)';
        exit(false);
    end;
}

codeunit 92373 "LT Y36 SameArity"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT Y36 SameArity";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Note := 'stored 1';
        Row.Insert();
        Row.Id := 2;
        Row.Note := 'stored 2';
        Row.Insert();
    end;

    local procedure Stored(): Text
    var
        Row: Record "LT Y36 SameArity";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Format(Row.Id) + '=' + Row.Note + ';';
            until Row.Next() = 0;
        exit(Format(Row.Count()) + ':' + Result);
    end;

    [TryFunction]
    local procedure TryGet12(var Row: Record "LT Y36 SameArity"; var Found: Boolean)
    begin
        Found := Row.Get(1, 2);
    end;

    [TryFunction]
    local procedure TryGet12Unused(var Row: Record "LT Y36 SameArity")
    begin
        Row.Get(1, 2);
    end;

    [Test]
    procedure Y36_SameArity_Get_IntegerArgs()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y36 SameArity";
        Found: Boolean;
    begin
        Seed();
        Row.Note := 'caller';
        if TryGet12(Row, Found) then
            Observer.Observe('get_1_2', 'ok ' + Format(Found))
        else
            Observer.Observe('get_1_2', 'error ' + GetLastErrorCode() + ': ' + GetLastErrorText());
        Observer.Observe('note_after_get_1_2', '[' + Row.Note + '] id ' + Format(Row.Id));
        ClearLastError();
        Row.Note := 'caller';
        if TryGet12Unused(Row) then
            Observer.Observe('get_1_2_unused', 'ok')
        else
            Observer.Observe('get_1_2_unused', 'error ' + GetLastErrorCode() + ': ' + GetLastErrorText());
        Observer.Observe('note_after_get_1_2_unused', '[' + Row.Note + '] id ' + Format(Row.Id));
        Observer.Expect('get_1_2', 'error AL:ToManyKeyFields: Too many key fields were specified, so "LT Y36 SameArity" could not be retrieved. The number of fields in the primary key is 1.');
        Observer.Expect('note_after_get_1_2', '[caller] id 0');
        Observer.Expect('get_1_2_unused', 'error AL:ToManyKeyFields: Too many key fields were specified, so "LT Y36 SameArity" could not be retrieved. The number of fields in the primary key is 1.');
        Observer.Expect('note_after_get_1_2_unused', '[caller] id 0');
        Observer.Verify();
    end;

    [Test]
    procedure Y36_SameArity_Get_OneArg()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y36 SameArity";
    begin
        Seed();
        Row.Note := 'caller';
        Observer.Observe('get_2_result', Format(Row.Get(2)));
        Observer.Observe('note_after_get_2', '[' + Row.Note + '] id ' + Format(Row.Id));
        Observer.Expect('get_2_result', 'Yes');
        Observer.Expect('note_after_get_2', '[stored 2] id 2');
        Observer.Verify();
    end;

    [Test]
    procedure Y36_SameArity_Delete_Boolean()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y36 SameArity";
    begin
        Seed();
        Row.Get(1);
        Observer.Observe('delete_true_result', Format(Row.Delete(true)));
        Observer.Observe('note_after_delete_true', '[' + Row.Note + ']');
        Observer.Observe('stored_after_delete_true', Stored());
        Row.Get(2);
        Row.Delete(true);
        Observer.Observe('note_after_delete_true_unused', '[' + Row.Note + ']');
        Observer.Observe('stored_after_delete_true_unused', Stored());
        Seed();
        Row.Get(1);
        Observer.Observe('delete_text_result', Format(Row.Delete('why')));
        Observer.Observe('note_after_delete_text', '[' + Row.Note + ']');
        Observer.Observe('stored_after_delete_text', Stored());
        Row.Get(1);
        Observer.Observe('delete_noarg_result', Format(Row.Delete()));
        Observer.Observe('note_after_delete_noarg', '[' + Row.Note + ']');
        Observer.Observe('stored_after_delete_noarg', Stored());
        Observer.Expect('delete_true_result', 'Yes');
        Observer.Expect('note_after_delete_true', '[stored 1]');
        Observer.Expect('stored_after_delete_true', '1:2=stored 2;');
        Observer.Expect('note_after_delete_true_unused', '[stored 2]');
        Observer.Expect('stored_after_delete_true_unused', '0:');
        Observer.Expect('delete_text_result', 'No');
        Observer.Expect('note_after_delete_text', '[own Delete(Text)]');
        Observer.Expect('stored_after_delete_text', '2:1=stored 1;2=stored 2;');
        Observer.Expect('delete_noarg_result', 'Yes');
        Observer.Expect('note_after_delete_noarg', '[stored 1]');
        Observer.Expect('stored_after_delete_noarg', '1:2=stored 2;');
        Observer.Verify();
    end;

    [Test]
    procedure Y36_SameArity_Validate_FieldAndValue()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y36 SameArity";
    begin
        Seed();
        Row.Get(1);
        Row.Validate(Note, 'x');
        Observer.Observe('note_after_validate_field_text', '[' + Row.Note + ']');
        Row.Get(1);
        Row.Validate(Id, 7);
        Observer.Observe('after_validate_id_7', '[' + Row.Note + '] id ' + Format(Row.Id));
        Row.Get(1);
        Row.Validate('Note', 'y');
        Observer.Observe('note_after_validate_text_text', '[' + Row.Note + ']');
        Observer.Observe('stored_after_validates', Stored());
        Observer.Expect('note_after_validate_field_text', '[x]');
        Observer.Expect('after_validate_id_7', '[stored 1] id 7');
        Observer.Expect('note_after_validate_text_text', '[own Validate]');
        Observer.Expect('stored_after_validates', '2:1=stored 1;2=stored 2;');
        Observer.Verify();
    end;

    [Test]
    procedure Y36_SameArity_Insert_InsideTable()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y36 SameArity";
    begin
        Seed();
        Row.Init();
        Observer.Observe('bare_insert_then_get_1', Row.BareInsertAndGet(5, 1));
        Observer.Observe('row_after_bare_calls', '[' + Row.Note + '] id ' + Format(Row.Id));
        Observer.Observe('stored_after_bare_calls', Stored());
        Row.Init();
        Row.Id := 6;
        Row.Note := 'caller insert';
        Row.Insert();
        Observer.Observe('stored_after_rec_insert', Stored());
        Observer.Expect('bare_insert_then_get_1', 'Yes stored 1');
        Observer.Expect('row_after_bare_calls', '[stored 1] id 1');
        Observer.Expect('stored_after_bare_calls', '3:1=stored 1;2=stored 2;5=inside;');
        Observer.Expect('stored_after_rec_insert', '4:1=stored 1;2=stored 2;5=inside;6=caller insert;');
        Observer.Verify();
    end;

    [Test]
    procedure Y36_CodeKey_Get_OwnSameArity()
    var
        Observer: Codeunit "Probe Observer";
        Row3: Record "LT Y36 CodeKey";
        Check: Record "LT Y36 CodeKey";
    begin
        Check.DeleteAll();
        Check.Init();
        Check.No := 'A';
        Check.Note := 'stored A';
        Check.Insert();
        Row3.Note := 'caller';
        Observer.Observe('get_A_result', Format(Row3.Get('A')));
        Observer.Observe('row3_after_get_A', '[' + Row3.Note + '] no [' + Row3.No + ']');
        Row3.Note := 'caller';
        Observer.Observe('get_Z_result', Format(Row3.Get('Z')));
        Observer.Observe('row3_after_get_Z', '[' + Row3.Note + '] no [' + Row3.No + ']');
        Observer.Expect('get_A_result', 'No');
        Observer.Expect('row3_after_get_A', '[own Get(Code)] no []');
        Observer.Expect('get_Z_result', 'No');
        Observer.Expect('row3_after_get_Z', '[own Get(Code)] no []');
        Observer.Verify();
    end;
}
