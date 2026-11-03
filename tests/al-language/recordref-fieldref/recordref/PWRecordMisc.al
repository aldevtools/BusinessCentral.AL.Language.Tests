// Probe writer-c: remaining open points from "All buckets with test data", "Table globals" (RecordRef keys, temporary
// record and Variant, Companies round 2) of docs/probes-needed.md. Observe-only.
// Fixtures: table 69750 (has a Removed field), table 69751, codeunit 69752 (tests).
// Uses fixture table "ALT CRM Entity" (60291) of the corpus app.

table 69750 "PW RM Removed"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[20]) { }
        field(3; Gone; Integer)
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'probe';
            ObsoleteTag = '1.0';
        }
        field(4; Last; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 69751 "PW RM Plain"
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
        key(K2; Txt) { }
    }
}

codeunit 69752 "PW Record Misc Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    // ---- temporary CRM record with no connection registered ----

    [Test]
    procedure CrmTemp_InitInsertCount()
    var
        Crm: Record "ALT CRM Entity" temporary;
    begin
        Crm.Init();
        Crm.Name := 'n1';
        Crm.Insert();
        Observer.Observe('insert', 'no error');
        Observer.Observe('count', Format(Crm.Count()));
        Observer.Expect('insert', 'no error');
        Observer.Expect('count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure CrmTemp_ResetDeleteAll()
    var
        Crm: Record "ALT CRM Entity" temporary;
    begin
        Crm.Reset();
        Crm.DeleteAll();
        Observer.Observe('reset_and_deleteall_done', 'yes');
        Observer.Observe('isempty', Format(Crm.IsEmpty()));
        Observer.Expect('reset_and_deleteall_done', 'yes');
        Observer.Expect('isempty', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure CrmTemp_InsertWithGuid_ThenRead()
    var
        Crm: Record "ALT CRM Entity" temporary;
    begin
        Crm.EntityId := CreateGuid();
        Crm.Name := 'n2';
        Crm.Insert();
        Observer.Observe('count', Format(Crm.Count()));
        Crm.Reset();
        Observer.Observe('findfirst', Format(Crm.FindFirst()));
        Observer.Observe('name', Crm.Name);
        Crm.DeleteAll();
        Observer.Observe('count_after_deleteall', Format(Crm.Count()));
        Observer.Expect('count', '1');
        Observer.Expect('findfirst', 'Yes');
        Observer.Expect('name', 'n2');
        Observer.Expect('count_after_deleteall', '0');
        Observer.Verify();
    end;

    // ---- a field with ObsoleteState = Removed through RecordRef ----

    [Test]
    procedure RemovedField_FieldCountExistAndIndex()
    var
        RecRef: RecordRef;
        Names: Text;
        i: Integer;
    begin
        RecRef.Open(Database::"PW RM Removed");
        Observer.Observe('fieldcount', Format(RecRef.FieldCount()));
        Observer.Observe('fieldexist_3', Format(RecRef.FieldExist(3)));
        for i := 1 to RecRef.FieldCount() do
            Names += RecRef.FieldIndex(i).Name + '(' + Format(RecRef.FieldIndex(i).Number) + ') ';
        Observer.Observe('fieldindex_loop', Names);
        Observer.Expect('fieldcount', '3');
        Observer.Expect('fieldexist_3', 'No');
        Observer.Expect('fieldindex_loop', 'Id(1) Txt(2) Last(4) ');
        Observer.Verify();
    end;

    [Test]
    procedure RemovedField_FieldNError()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        RecRef.Open(Database::"PW RM Removed");
        asserterror FldRef := RecRef.Field(3);
        Observer.ObserveError('field_3');
        Observer.Expect('field_3|text', 'Field Gone (3) of table PW RM Removed (69750) is obsoleted, reason: probe');
        Observer.Expect('field_3|code', 'MetadataObsolete');
        Observer.Verify();
    end;

    [Test]
    procedure RemovedField_RecordFieldNoAndFieldActive()
    var
        Row: Record "PW RM Removed";
    begin
        Observer.Observe('fieldactive_4', Format(Row.FieldActive(Last)));
        Observer.Expect('fieldactive_4', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure GeneralLedgerSetup_Field110_RecordRef()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        RecRef.Open(98);
        Observer.Observe('fieldexist_110', Format(RecRef.FieldExist(110)));
        asserterror FldRef := RecRef.Field(110);
        Observer.ObserveError('field_110');
        Observer.Expect('fieldexist_110', 'No');
        Observer.Expect('field_110|text', 'Field Acc. Sched. for Balance Sheet (110) of table General Ledger Setup (98) is obsoleted, reason: Financial Reporting is replacing Account Schedules for financial statements');
        Observer.Expect('field_110|code', 'MetadataObsolete');
        Observer.Verify();
    end;

    // ---- RecordRef keys ----

    [Test]
    procedure RecordRefKeys_SystemIdFieldName()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        FldNumber: Integer;
        FldType: FieldType;
    begin
        RecRef.Open(Database::"PW RM Plain");
        FldRef := RecRef.Field(RecRef.SystemIdNo);
        FldNumber := FldRef.Number();
        FldType := FldRef.Type();
        Observer.Observe('systemid_field_name', FldRef.Name());
        Observer.Observe('systemid_field_caption', FldRef.Caption());
        Observer.Observe('systemid_field_number', Format(FldNumber));
        Observer.Observe('systemid_field_type', Format(FldType));
        Observer.Expect('systemid_field_name', '$systemId');
        Observer.Expect('systemid_field_caption', 'System ID');
        Observer.Expect('systemid_field_number', '2000000000');
        Observer.Expect('systemid_field_type', 'GUID');
        Observer.Verify();
    end;

    // ---- temporary record and Variant ----

    local procedure CountThroughVariant(V: Variant): Integer
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(V);
        exit(RecRef.Count());
    end;

    local procedure CountThroughVarVariant(var V: Variant): Integer
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(V);
        exit(RecRef.Count());
    end;

    local procedure SeedTemp(var Tmp: Record "PW RM Plain" temporary)
    begin
        Tmp.Id := 1;
        Tmp.Insert();
        Tmp.Id := 2;
        Tmp.Insert();
        Tmp.Id := 3;
        Tmp.Insert();
    end;

    [Test]
    procedure TempRecord_PassedToVariantParameter_ByValue()
    var
        Tmp: Record "PW RM Plain" temporary;
    begin
        SeedTemp(Tmp);
        Observer.Observe('count_in_caller', Format(Tmp.Count()));
        Observer.Observe('count_through_variant_param', Format(CountThroughVariant(Tmp)));
        Observer.Expect('count_in_caller', '3');
        Observer.Expect('count_through_variant_param', '3');
        Observer.Verify();
    end;

    [Test]
    procedure TempRecord_AssignedToVariantVariable()
    var
        Tmp: Record "PW RM Plain" temporary;
        V: Variant;
    begin
        SeedTemp(Tmp);
        V := Tmp;
        Observer.Observe('count_through_assigned_variant', Format(CountThroughVarVariant(V)));
        Observer.Observe('isrecord', Format(V.IsRecord));
        Observer.Observe('istemporary_through_recref', Format(TempFlagOf(V)));
        Collect(V);
        Observer.Expect('count_through_assigned_variant', '0');
        Observer.Expect('isrecord', 'Yes');
        Observer.Expect('istemporary_through_recref', 'Yes');
        Observer.Expect('variant_back_into_temp_count_new_var', '0');
        Observer.Verify();
    end;

    local procedure TempFlagOf(V: Variant): Boolean
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(V);
        exit(RecRef.IsTemporary());
    end;

    local procedure Collect(V: Variant)
    var
        Back: Record "PW RM Plain" temporary;
    begin
        Back := V;
        Observer.Observe('variant_back_into_temp_count_new_var', Format(Back.Count()));
        Back := V;
    end;

    [Test]
    procedure TempRecord_VariantModifiedAfterAssign()
    var
        Tmp: Record "PW RM Plain" temporary;
        V: Variant;
    begin
        SeedTemp(Tmp);
        V := Tmp;
        Tmp.Id := 4;
        Tmp.Insert();
        Observer.Observe('caller_count_after_extra_insert', Format(Tmp.Count()));
        Observer.Observe('variant_count_after_extra_insert', Format(CountThroughVarVariant(V)));
        Observer.Expect('caller_count_after_extra_insert', '4');
        Observer.Expect('variant_count_after_extra_insert', '0');
        Observer.Verify();
    end;

    // ---- Companies: Delete(false) of a company that holds rows ----

}
