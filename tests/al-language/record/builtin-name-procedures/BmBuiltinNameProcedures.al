// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-methods
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Corpus #664 item 18: a table procedure with the name of a built-in record method. With the same parameter types (Count(), Insert(),
// IsEmpty(), FindFirst(), Modify(Boolean)) the compiler gives warning AL0524 ("The base type already defines a method ... will become an
// error"); Modify() with no parameter and Get() with no parameter give no diagnostic (AL 30 beta, runtime 16.1 to 18.0). This records
// which one runs for Rec.Count(), Rec.Insert() and so on: the table procedure (it returns a marker, and writes nothing) or the built-in.
// BC versions: 29 (27 and 28 by CI)
table 81954 "LT BM Builtin Names"
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

    procedure Count(): Integer
    begin
        exit(-42);
    end;

    procedure IsEmpty(): Boolean
    begin
        exit(false);
    end;

    procedure FindFirst(): Boolean
    begin
        Note := 'own FindFirst';
        exit(false);
    end;

    procedure Insert()
    begin
        Note := 'own Insert';
    end;

    procedure Modify()
    begin
        Note := 'own Modify';
    end;

    procedure Modify(RunTrigger: Boolean): Boolean
    begin
        Note := 'own Modify(Boolean)';
        exit(false);
    end;

    procedure Get(): Boolean
    begin
        Note := 'own Get';
        exit(false);
    end;
}

codeunit 81955 "LT BM Builtin Names"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure BM_TableProcedure_NamedLikeBuiltin()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BM Builtin Names";
        Check: RecordRef;
    begin
        Row.DeleteAll();
        Observer.Observe('isempty_on_empty_table', Format(Row.IsEmpty()));
        Observer.Observe('count_on_empty_table', Format(Row.Count()));
        Row.Init();
        Row.Id := 1;
        Row.Note := 'caller';
        Row.Insert();
        Observer.Observe('note_after_insert', Row.Note);
        Check.Open(Database::"LT BM Builtin Names");
        Observer.Observe('stored_rows_after_insert', Format(Check.Count()));
        Row.Id := 2;
        Row.Note := 'caller';
        Observer.Observe('insert_true_result', Format(Row.Insert(true)));
        Observer.Observe('stored_rows_after_insert_true', Format(Check.Count()));
        Observer.Observe('count_after_inserts', Format(Row.Count()));
        Observer.Observe('isempty_after_inserts', Format(Row.IsEmpty()));
        Row.Note := '';
        Observer.Observe('findfirst_result', Format(Row.FindFirst()));
        Observer.Observe('note_after_findfirst', '[' + Row.Note + '] id ' + Format(Row.Id));
        Row.Note := '';
        Observer.Observe('get_noarg_result', Format(Row.Get()));
        Observer.Observe('note_after_get_noarg', '[' + Row.Note + ']');
        Observer.Observe('get_key_result', Format(Row.Get(2)));
        Observer.Observe('note_after_get_key', '[' + Row.Note + ']');
        Row.Note := 'changed';
        Row.Modify();
        Observer.Observe('note_after_modify', Row.Note);
        Observer.Observe('stored_note_after_modify', StoredNote(2));
        Row.Note := 'changed2';
        Observer.Observe('modify_false_result', Format(Row.Modify(false)));
        Observer.Observe('note_after_modify_false', Row.Note);
        Observer.Observe('stored_note_after_modify_false', StoredNote(2));
        Check.Close();
        Observer.Expect('isempty_on_empty_table', 'No');
        Observer.Expect('count_on_empty_table', '-42');
        Observer.Expect('note_after_insert', 'own Insert');
        Observer.Expect('stored_rows_after_insert', '0');
        Observer.Expect('insert_true_result', 'Yes');
        Observer.Expect('stored_rows_after_insert_true', '1');
        Observer.Expect('count_after_inserts', '-42');
        Observer.Expect('isempty_after_inserts', 'No');
        Observer.Expect('findfirst_result', 'No');
        Observer.Expect('note_after_findfirst', '[own FindFirst] id 2');
        Observer.Expect('get_noarg_result', 'No');
        Observer.Expect('note_after_get_noarg', '[own Get]');
        Observer.Expect('get_key_result', 'Yes');
        Observer.Expect('note_after_get_key', '[caller]');
        Observer.Expect('note_after_modify', 'own Modify');
        Observer.Expect('stored_note_after_modify', 'caller');
        Observer.Expect('modify_false_result', 'No');
        Observer.Expect('note_after_modify_false', 'own Modify(Boolean)');
        Observer.Expect('stored_note_after_modify_false', 'caller');
        Observer.Verify();
    end;

    local procedure StoredNote(Id: Integer): Text
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        RecRef.Open(Database::"LT BM Builtin Names");
        FldRef := RecRef.Field(1);
        FldRef.SetRange(Id);
        if not RecRef.FindFirst() then
            exit('<no row>');
        exit(Format(RecRef.Field(2).Value()));
    end;
}
