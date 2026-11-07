// Batch 5, md:627 (Temporary record and Variant): what a Variant holds when a temporary record WITH ROWS is assigned or passed.

codeunit 67059 "W5 Temp Variant Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Assigned to a Variant: the Variant says it holds a record, and the rows seen through a RecordRef.
    [Test]
    procedure TempRecord_AssignedToVariant()
    var
        Observer: Codeunit "Probe Observer";
        Temp: Record "ALT Shape 06" temporary;
        V: Variant;
        RecRef: RecordRef;
    begin
        FillThree(Temp);
        V := Temp;
        Observer.Observe('variant_is_record', Format(V.IsRecord()));
        RecRef.GetTable(V);
        Observer.Observe('variant_ref_count', Format(RecRef.Count()));
        Observer.Observe('variant_ref_is_temporary', Format(RecRef.IsTemporary()));
        Temp.Id := 4;
        Temp.Insert();
        RecRef.GetTable(V);
        Observer.Observe('variant_ref_count_after_insert_into_original', Format(RecRef.Count()));
        Observer.Observe('original_count', Format(Temp.Count()));
        Observer.Expect('variant_is_record', 'Yes');
        Observer.Expect('variant_ref_count', '0');
        Observer.Expect('variant_ref_is_temporary', 'Yes');
        Observer.Expect('variant_ref_count_after_insert_into_original', '0');
        Observer.Expect('original_count', '4');
        Observer.Verify();
    end;

    // Passed to a Variant parameter, counted there.
    [Test]
    procedure TempRecord_PassedToVariantParameter()
    var
        Observer: Codeunit "Probe Observer";
        Temp: Record "ALT Shape 06" temporary;
    begin
        FillThree(Temp);
        Observer.Observe('count_through_variant_temp_3_rows', Format(CountThroughVariant(Temp)));
        Observer.Observe('count_through_variant_filtered_to_2', Format(CountFiltered(Temp)));
        Observer.Expect('count_through_variant_temp_3_rows', '3');
        Observer.Expect('count_through_variant_filtered_to_2', '2');
        Observer.Verify();
    end;

    // The same with a record of a real table, as the control.
    [Test]
    procedure RealRecord_PassedToVariantParameter()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "ALT Shape 06";
    begin
        Row.DeleteAll();
        FillThree(Row);
        Observer.Observe('count_through_variant_real_3_rows', Format(CountThroughVariant(Row)));
        Row.DeleteAll();
        Observer.Expect('count_through_variant_real_3_rows', '3');
        Observer.Verify();
    end;

    // Passed by var as a Variant, a row inserted through the RecordRef: does it reach the caller's temporary record?
    [Test]
    procedure TempRecord_InsertThroughVariantRecordRef()
    var
        Observer: Codeunit "Probe Observer";
        Temp: Record "ALT Shape 06" temporary;
        Real: Record "ALT Shape 06";
        V: Variant;
    begin
        Real.DeleteAll();
        FillThree(Temp);
        V := Temp;
        InsertThroughVariant(V);
        Observer.Observe('original_count_after_insert_through_variant', Format(Temp.Count()));
        Observer.Observe('original_has_row_9', Format(Temp.Get(9)));
        Observer.Observe('real_table_count_after', Format(Real.Count()));
        Real.DeleteAll();
        Observer.Expect('original_count_after_insert_through_variant', '3');
        Observer.Expect('original_has_row_9', 'No');
        Observer.Expect('real_table_count_after', '0');
        Observer.Verify();
    end;

    // The Variant converted back into a record variable (SetRecord-style): rows survive?
    [Test]
    procedure TempRecord_VariantBackIntoRecord()
    var
        Observer: Codeunit "Probe Observer";
        Temp: Record "ALT Shape 06" temporary;
        Back: Record "ALT Shape 06" temporary;
        V: Variant;
    begin
        FillThree(Temp);
        V := Temp;
        ClearLastError();
        Observer.Observe('assign_ok', Format(TryAssignBack(V, Back)));
        Observer.ObserveError('assign_back');
        Observer.Observe('back_count', Format(Back.Count()));
        Observer.Observe('back_id', Format(Back.Id));
        Observer.Expect('assign_ok', 'Yes');
        Observer.Expect('assign_back|text', '');
        Observer.Expect('assign_back|code', '');
        Observer.Expect('back_count', '0');
        Observer.Expect('back_id', '3');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryAssignBack(V: Variant; var Target: Record "ALT Shape 06")
    begin
        Target := V;
    end;

    local procedure FillThree(var Target: Record "ALT Shape 06")
    var
        i: Integer;
    begin
        for i := 1 to 3 do begin
            Target.Init();
            Target.Id := i;
            Target.Name := 'row ' + Format(i);
            Target.Insert();
        end;
    end;

    local procedure CountThroughVariant(V: Variant): Integer
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(V);
        exit(RecRef.Count());
    end;

    local procedure CountFiltered(var Source: Record "ALT Shape 06"): Integer
    begin
        Source.SetFilter(Id, '<3');
        exit(CountThroughVariant(Source));
    end;

    local procedure InsertThroughVariant(var V: Variant)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(V);
        RecRef.Init();
        RecRef.Field(1).Value := 9;
        RecRef.Insert();
    end;
}
