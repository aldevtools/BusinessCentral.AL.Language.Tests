// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects below
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: A Record variable assigned a Variant holding a RecordRef (same table, other table, closed RecordRef) (assumption recordref-variant-to-record); types/lt-variant/VaTConvert.al covers scalar Variant conversions only.
// BC versions: 29 (27 and 28 by CI)

table 70653 "LT RRVar Row"
{
    fields
    {
        field(1; "No."; Integer) { }
        field(2; Name; Text[30]) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 70654 "LT RRVar Other"
{
    fields
    {
        field(1; "No."; Integer) { }
        field(2; Name; Text[30]) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

// Writer QP (al-runtime-rs "Codeunit.Run with a RecordRef in a Variant", Microsoft's Batch Processing Mgt. InvokeProcessing shape):
//   a Variant holding a RecordRef positioned on a row is passed to Codeunit.Run of a codeunit with TableNo = "LT RRVar Row" (87142).
//   OnRun logs Rec's key, Name and filters, changes Name and calls Modify. After the call: the RecordRef's Name field and the stored row,
//   for the plain call and the guarded `if Codeunit.Run(...)` form (after Commit), a filtered RecordRef, and a RecordRef of another table
//   (error 'Record(70654) is not compatible with Codeunit.Run(Record(70653)).', raised even by the guarded form, which does not catch it).
//   QP_ tests in codeunit 70655; SingleInstance log 87143 is used only by it.
codeunit 87143 "LT QP RRVar Run Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

codeunit 87142 "LT QP RRVar Run Target"
{
    TableNo = "LT RRVar Row";

    trigger OnRun()
    var
        Log: Codeunit "LT QP RRVar Run Log";
    begin
        Log.Add('onrun no=' + Format(Rec."No.") + ' name=' + Rec.Name + ' filters=[' + Rec.GetFilters() + ']');
        Rec.Name := 'changed';
        Rec.Modify();
        Log.Add('modified');
    end;
}

codeunit 70655 "LT RRVar To Record"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT RRVar Row";
        Other: Record "LT RRVar Other";
    begin
        Row.DeleteAll();
        Other.DeleteAll();
        Row."No." := 1;
        Row.Name := 'first';
        Row.Insert();
        Row."No." := 2;
        Row.Name := 'second';
        Row.Insert();
        Other."No." := 7;
        Other.Name := 'other';
        Other.Insert();
    end;

    [TryFunction]
    local procedure TryAssign(V: Variant; var Row: Record "LT RRVar Row")
    begin
        Row := V;
    end;

    local procedure Outcome(V: Variant; var Row: Record "LT RRVar Row"): Text
    begin
        ClearLastError();
        if TryAssign(V, Row) then
            exit('ok');
        exit('error:' + GetLastErrorText());
    end;

    [Test]
    procedure RecordFromVariant_SameTable_Result()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        V: Variant;
        Row: Record "LT RRVar Row";
    begin
        Seed();
        RR.Open(Database::"LT RRVar Row");
        RR.FindFirst();
        V := RR;
        Observer.Observe('is_recordref', Format(V.IsRecordRef()));
        Observer.Observe('is_record', Format(V.IsRecord()));
        Observer.Observe('assign_first', Outcome(V, Row));
        Observer.Observe('first_no', Format(Row."No."));
        Observer.Observe('first_name', Row.Name);
        RR.Next();
        V := RR;
        Observer.Observe('assign_second', Outcome(V, Row));
        Observer.Observe('second_no', Format(Row."No."));
        Observer.Observe('second_name', Row.Name);
        Observer.Expect('is_recordref', 'Yes');
        Observer.Expect('is_record', 'No');
        Observer.Expect('assign_first', 'ok');
        Observer.Expect('first_no', '1');
        Observer.Expect('first_name', 'first');
        Observer.Expect('assign_second', 'ok');
        Observer.Expect('second_no', '2');
        Observer.Expect('second_name', 'second');
        Observer.Verify();
    end;

    [Test]
    procedure RecordFromVariant_IsCopy_Result()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        V: Variant;
        Row: Record "LT RRVar Row";
        Check: Record "LT RRVar Row";
    begin
        Seed();
        RR.Open(Database::"LT RRVar Row");
        RR.FindFirst();
        V := RR;
        Observer.Observe('assign', Outcome(V, Row));
        Row.Name := 'changed in copy';
        Row.Modify();
        Check.Get(1);
        Observer.Observe('stored_after_modify', Check.Name);
        RR.Get(RR.RecordId());
        Observer.Observe('rr_name_after_modify', Format(RR.Field(2).Value()));
        Row.SetRange("No.", 2);
        Observer.Observe('copy_has_filter_no', Format(Row.HasFilter()));
        Observer.Expect('assign', 'ok');
        Observer.Expect('stored_after_modify', 'changed in copy');
        Observer.Expect('rr_name_after_modify', 'changed in copy');
        Observer.Expect('copy_has_filter_no', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure RecordFromVariant_OtherTable_Result()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        V: Variant;
        Row: Record "LT RRVar Row";
    begin
        Seed();
        RR.Open(Database::"LT RRVar Other");
        RR.FindFirst();
        V := RR;
        Observer.Observe('other_table', Outcome(V, Row));
        Observer.Observe('row_untouched_no', Format(Row."No."));
        Observer.Expect('other_table', 'error:The requested operation is not supported.');
        Observer.Expect('row_untouched_no', '0');
        Observer.Verify();
    end;

    [Test]
    procedure RecordFromVariant_ClosedRecordRef_Result()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        V: Variant;
        Row: Record "LT RRVar Row";
    begin
        Seed();
        V := RR;
        Observer.Observe('is_recordref', Format(V.IsRecordRef()));
        Observer.Observe('closed_recordref', Outcome(V, Row));
        Observer.Expect('is_recordref', 'Yes');
        Observer.Expect('closed_recordref', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavRecordRef to Microsoft.Dynamics.Nav.Runtime.INavRecordHandle.');
        Observer.Verify();
    end;

    [Test]
    procedure RecordFromVariant_OpenedNoCurrentRow_Result()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        V: Variant;
        Row: Record "LT RRVar Row";
    begin
        Seed();
        RR.Open(Database::"LT RRVar Row");
        V := RR;
        Row."No." := 55;
        Observer.Observe('opened_not_positioned', Outcome(V, Row));
        Observer.Observe('row_no_after', Format(Row."No."));
        Observer.Expect('opened_not_positioned', 'ok');
        Observer.Expect('row_no_after', '0');
        Observer.Verify();
    end;

    local procedure QP_RowName(No: Integer): Text
    var
        Row: Record "LT RRVar Row";
    begin
        if not Row.Get(No) then
            exit('<no row>');
        exit(Row.Name);
    end;

    [Test]
    procedure QP_CodeunitRun_VariantRecordRef_Plain()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QP RRVar Run Log";
        RR: RecordRef;
        V: Variant;
    begin
        Seed();
        Log.Take();
        RR.Open(Database::"LT RRVar Row");
        RR.Field(1).SetRange(2);
        RR.FindFirst();
        RR.Field(1).SetRange();
        V := RR;
        Codeunit.Run(Codeunit::"LT QP RRVar Run Target", V);
        Observer.Observe('log', Log.Take());
        Observer.Observe('recref_name', Format(RR.Field(2).Value));
        Observer.Observe('recref_no', Format(RR.Field(1).Value));
        Observer.Observe('stored_2', QP_RowName(2));
        Observer.Observe('stored_1', QP_RowName(1));
        Observer.Expect('log', 'onrun no=2 name=second filters=[];modified;');
        Observer.Expect('recref_name', 'changed');
        Observer.Expect('recref_no', '2');
        Observer.Expect('stored_2', 'changed');
        Observer.Expect('stored_1', 'first');
        Observer.Verify();
    end;

    [Test]
    procedure QP_CodeunitRun_VariantRecordRef_Guarded()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QP RRVar Run Log";
        RR: RecordRef;
        V: Variant;
        Ok: Boolean;
    begin
        Seed();
        Commit();
        Log.Take();
        RR.Open(Database::"LT RRVar Row");
        RR.Field(1).SetRange(2);
        RR.FindFirst();
        RR.Field(1).SetRange();
        V := RR;
        ClearLastError();
        Ok := Codeunit.Run(Codeunit::"LT QP RRVar Run Target", V);
        Observer.Observe('result', Format(Ok));
        Observer.Observe('last_error', GetLastErrorText());
        Observer.Observe('log', Log.Take());
        Observer.Observe('recref_name', Format(RR.Field(2).Value));
        Observer.Observe('stored_2', QP_RowName(2));
        Observer.Observe('stored_1', QP_RowName(1));
        Observer.Expect('result', 'Yes');
        Observer.Expect('last_error', '');
        Observer.Expect('log', 'onrun no=2 name=second filters=[];modified;');
        Observer.Expect('recref_name', 'changed');
        Observer.Expect('stored_2', 'changed');
        Observer.Expect('stored_1', 'first');
        Observer.Verify();
    end;

    [Test]
    procedure QP_CodeunitRun_VariantRecordRef_Filtered()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QP RRVar Run Log";
        RR: RecordRef;
        V: Variant;
    begin
        Seed();
        Log.Take();
        RR.Open(Database::"LT RRVar Row");
        RR.Field(2).SetFilter('first|second');
        RR.FindLast();
        V := RR;
        Codeunit.Run(Codeunit::"LT QP RRVar Run Target", V);
        Observer.Observe('log', Log.Take());
        Observer.Observe('recref_name', Format(RR.Field(2).Value));
        Observer.Observe('recref_filters', RR.GetFilters());
        Observer.Observe('stored_2', QP_RowName(2));
        Observer.Expect('log', 'onrun no=2 name=second filters=[Name: first|second];modified;');
        Observer.Expect('recref_name', 'changed');
        Observer.Expect('recref_filters', 'Name: first|second');
        Observer.Expect('stored_2', 'changed');
        Observer.Verify();
    end;

    [Test]
    procedure QP_CodeunitRun_VariantRecordRef_OtherTable()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QP RRVar Run Log";
        RR: RecordRef;
        V: Variant;
    begin
        Seed();
        Commit();
        Log.Take();
        RR.Open(Database::"LT RRVar Other");
        RR.FindFirst();
        V := RR;
        // Observed on 27.5, 28.5 and 29.0: the guarded form does NOT catch this error; it ends the test (run af0fb0d1).
        asserterror if Codeunit.Run(Codeunit::"LT QP RRVar Run Target", V) then;
        Observer.Observe('other_table_error', GetLastErrorText());
        Observer.Observe('log', Log.Take());
        Observer.Expect('other_table_error', 'Record(70654) is not compatible with Codeunit.Run(Record(70653)).');
        Observer.Expect('log', '');
        Observer.Verify();
    end;
}
