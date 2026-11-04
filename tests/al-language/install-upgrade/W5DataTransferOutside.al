// Batch 5, md:247 (DataTransfer outside install code): SetTables with odd pairs, and which refusal comes first for odd arguments.
// The corpus (install/TestDataTransferContracts.al) already pins: SetTables accepted for two compiled tables, a call before SetTables, a call after it.
// Open here: what SetTables does with the same table twice, a table that does not exist, id 0; and the order of the guards for a field that does not exist.
// Uses the table "W5 Tx Row" (runner/W5TxBoundary.al) as source and destination.

codeunit 67054 "W5 DataTransfer Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure SetTables_OddPairs()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := TrySetTables(Database::"W5 Tx Row", Database::"W5 Tx Row");
        Observer.Observe('same_table_ok', Format(Ok));
        Observer.ObserveError('same_table');
        Ok := TrySetTables(Database::"W5 Tx Row", 99999999);
        Observer.Observe('unknown_destination_ok', Format(Ok));
        Observer.ObserveError('unknown_destination');
        Ok := TrySetTables(99999999, Database::"W5 Tx Row");
        Observer.Observe('unknown_source_ok', Format(Ok));
        Observer.ObserveError('unknown_source');
        Ok := TrySetTables(0, 0);
        Observer.Observe('zero_ok', Format(Ok));
        Observer.ObserveError('zero');
        Observer.Expect('same_table_ok', 'Yes');
        Observer.Expect('same_table|text', '');
        Observer.Expect('same_table|code', '');
        Observer.Expect('unknown_destination_ok', 'No');
        Observer.Expect('unknown_destination|text', 'You tried to invoke the Table object with the ID 99999999 from the object W5 DataTransfer Tests. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('unknown_destination|code', 'AL:MetadataNotFound');
        Observer.Expect('unknown_source_ok', 'No');
        Observer.Expect('unknown_source|text', 'You tried to invoke the Table object with the ID 99999999 from the object W5 DataTransfer Tests. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('unknown_source|code', 'AL:MetadataNotFound');
        Observer.Expect('zero_ok', 'No');
        Observer.Expect('zero|text', 'You tried to invoke the Table object with the ID 0 from the object W5 DataTransfer Tests. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('zero|code', 'AL:MetadataNotFound');
        Observer.Verify();
    end;

    // After a valid SetTables: calls with a field number that does not exist. The question is which text comes: the field one or the upgrade-only one.
    [Test]
    procedure AfterSetTables_UnknownFieldNumbers()
    var
        Observer: Codeunit "Probe Observer";
        DT: DataTransfer;
        Ok: Boolean;
    begin
        DT.SetTables(Database::"W5 Tx Row", Database::"W5 SeqGuid Row");
        ClearLastError();
        Ok := TryAddFieldValue(DT, 99, 99);
        Observer.Observe('add_field_value_unknown_ok', Format(Ok));
        Observer.ObserveError('add_field_value_unknown');
        Ok := TryAddFieldValue(DT, 0, 0);
        Observer.Observe('add_field_value_zero_ok', Format(Ok));
        Observer.ObserveError('add_field_value_zero');
        Ok := TryAddConstant(DT, 99);
        Observer.Observe('add_constant_unknown_ok', Format(Ok));
        Observer.ObserveError('add_constant_unknown');
        Ok := TryCopyFields(DT);
        Observer.Observe('copy_fields_ok', Format(Ok));
        Observer.ObserveError('copy_fields');
        Ok := TryCopyRows(DT);
        Observer.Observe('copy_rows_ok', Format(Ok));
        Observer.ObserveError('copy_rows');
        Observer.Expect('add_field_value_unknown_ok', 'No');
        Observer.Expect('add_field_value_unknown|text', 'DataTransfer is only usable during upgrade and installation code.');
        Observer.Expect('add_field_value_unknown|code', 'DB:Ok');
        Observer.Expect('add_field_value_zero_ok', 'No');
        Observer.Expect('add_field_value_zero|text', 'DataTransfer is only usable during upgrade and installation code.');
        Observer.Expect('add_field_value_zero|code', 'DB:Ok');
        Observer.Expect('add_constant_unknown_ok', 'No');
        Observer.Expect('add_constant_unknown|text', 'DataTransfer is only usable during upgrade and installation code.');
        Observer.Expect('add_constant_unknown|code', 'DB:Ok');
        Observer.Expect('copy_fields_ok', 'No');
        Observer.Expect('copy_fields|text', 'DataTransfer is only usable during upgrade and installation code.');
        Observer.Expect('copy_fields|code', 'DB:Ok');
        Observer.Expect('copy_rows_ok', 'No');
        Observer.Expect('copy_rows|text', 'DataTransfer is only usable during upgrade and installation code.');
        Observer.Expect('copy_rows|code', 'DB:Ok');
        Observer.Verify();
    end;

    // SetTables twice on one variable, and UpdateAuditFields.
    [Test]
    procedure SetTables_Twice_AndUpdateAuditFields()
    var
        Observer: Codeunit "Probe Observer";
        DT: DataTransfer;
        Ok: Boolean;
    begin
        DT.SetTables(Database::"W5 Tx Row", Database::"W5 SeqGuid Row");
        ClearLastError();
        Ok := TrySetTablesOn(DT, Database::"W5 SeqGuid Row", Database::"W5 Tx Row");
        Observer.Observe('second_set_tables_ok', Format(Ok));
        Observer.ObserveError('second_set_tables');
        Ok := TryAudit(DT);
        Observer.Observe('update_audit_fields_ok', Format(Ok));
        Observer.ObserveError('update_audit_fields');
        Observer.Expect('second_set_tables_ok', 'Yes');
        Observer.Expect('second_set_tables|text', '');
        Observer.Expect('second_set_tables|code', '');
        Observer.Expect('update_audit_fields_ok', 'Yes');
        Observer.Expect('update_audit_fields|text', '');
        Observer.Expect('update_audit_fields|code', '');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TrySetTables(SourceId: Integer; DestinationId: Integer)
    var
        DT: DataTransfer;
    begin
        DT.SetTables(SourceId, DestinationId);
    end;

    [TryFunction]
    local procedure TrySetTablesOn(var DT: DataTransfer; SourceId: Integer; DestinationId: Integer)
    begin
        DT.SetTables(SourceId, DestinationId);
    end;

    [TryFunction]
    local procedure TryAddFieldValue(var DT: DataTransfer; SourceField: Integer; DestinationField: Integer)
    begin
        DT.AddFieldValue(SourceField, DestinationField);
    end;

    [TryFunction]
    local procedure TryAddConstant(var DT: DataTransfer; DestinationField: Integer)
    begin
        DT.AddConstantValue('x', DestinationField);
    end;

    [TryFunction]
    local procedure TryCopyFields(var DT: DataTransfer)
    begin
        DT.CopyFields();
    end;

    [TryFunction]
    local procedure TryCopyRows(var DT: DataTransfer)
    begin
        DT.CopyRows();
    end;

    [TryFunction]
    local procedure TryAudit(var DT: DataTransfer)
    begin
        DT.UpdateAuditFields := false;
    end;
}
