// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-close-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), ALT Universal (table 60000), Data Type Management (Base Application codeunit 701)
// Probe: observation form. Every test ends in Finish(), so it fails on purpose and its message carries what BC produced.
// Facts: what a Variant that was assigned a RecordRef holds after the original RecordRef is closed, cleared or opened again
//   (Format of the Variant, IsRecordRef, and Number, IsEmpty, Find, Count and field values of the RecordRef taken back out with
//   R := V and with Data Type Management.GetRecordRef), what a Close of the taken-out RecordRef does to the Variant and to the
//   original, the same through a Variant parameter by value and by var, RecordRef := RecordRef followed by a Close of either
//   side, Variant := Record for contrast, and Format of a Variant that holds a Record (with a row, initialized, temporary) or a
//   RecordRef (positioned, open with no row, closed, never opened), with no Close after the assignment.
//   types/variant/CxVariants.al pins only that the two share the buffer while both are open.
// BC versions: 27, 28 and 29 by the corpus CI matrix

codeunit 99695 "RecordRef In Variant Close"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        KeptVariant: Variant;

    local procedure Seed()
    var
        Row: Record "ALT Universal";
    begin
        Row.DeleteAll();
        Row."Entry No." := 1;
        Row."Text Field" := 'one';
        Row.Insert();
        Row."Entry No." := 2;
        Row."Text Field" := 'two';
        Row.Insert();
    end;

    local procedure OpenOnFirst(var RR: RecordRef)
    begin
        RR.Open(Database::"ALT Universal");
        RR.FindFirst();
    end;

    [TryFunction]
    local procedure TryInfo(var RR: RecordRef; var Info: Text)
    begin
        Info := Format(RR.Number()) + '|' + Format(RR.Field(1).Value()) + '|' + Format(RR.Field(6).Value());
    end;

    // Table number, "Entry No." and "Text Field" of the RecordRef, or the error a read of them raises.
    local procedure RefInfo(var RR: RecordRef): Text
    var
        Info: Text;
    begin
        if TryInfo(RR, Info) then
            exit(Info);
        exit('error:' + GetLastErrorText());
    end;

    [TryFunction]
    local procedure TryTakeOut(V: Variant; var RR: RecordRef)
    begin
        RR := V;
    end;

    // What a RecordRef assigned from the Variant holds, or the error the assignment raises.
    local procedure TakenOutInfo(V: Variant): Text
    var
        RR: RecordRef;
    begin
        if not TryTakeOut(V, RR) then
            exit('assign error:' + GetLastErrorText());
        exit(RefInfo(RR));
    end;

    local procedure Kind(V: Variant): Text
    begin
        if V.IsRecordRef() then
            exit('RecordRef');
        if V.IsRecord() then
            exit('Record');
        exit('other');
    end;

    local procedure FormatIsEmpty(V: Variant): Text
    begin
        exit(Format(Format(V) = ''));
    end;

    local procedure DescribeByValue(V: Variant): Text
    begin
        exit(Kind(V) + '/' + FormatIsEmpty(V) + '/' + TakenOutInfo(V));
    end;

    local procedure DescribeByVar(var V: Variant): Text
    begin
        exit(Kind(V) + '/' + FormatIsEmpty(V) + '/' + TakenOutInfo(V));
    end;

    local procedure CloseTakenOutByValue(V: Variant)
    var
        RR: RecordRef;
    begin
        RR := V;
        RR.Close();
    end;

    local procedure CloseTakenOutByVar(var V: Variant)
    var
        RR: RecordRef;
    begin
        RR := V;
        RR.Close();
    end;

    local procedure KeepByValue(V: Variant)
    begin
        KeptVariant := V;
    end;

    [Test]
    procedure Variant_OriginalClosed_VariantItself()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        V: Variant;
        Before: Text;
    begin
        Seed();
        OpenOnFirst(RR);
        V := RR;
        Before := Format(V);
        Observer.Observe('format_is_empty_before_close', Format(Before = ''));
        RR.Close();
        Observer.Observe('kind_after_close', Kind(V));
        Observer.Observe('format_is_empty_after_close', FormatIsEmpty(V));
        Observer.Observe('format_same_as_before_close', Format(Format(V) = Before));
        Observer.Observe('original_after_close', RefInfo(RR));
        Observer.Finish();
    end;

    [Test]
    procedure Variant_OriginalClosed_TakenOutRecordRef()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Back: RecordRef;
        V: Variant;
    begin
        Seed();
        OpenOnFirst(RR);
        V := RR;
        RR.Close();
        Observer.Observe('taken_out', TakenOutInfo(V));
        if TryTakeOut(V, Back) then begin
            Observer.Observe('number', Format(Back.Number()));
            Observer.Observe('is_empty', Format(Back.IsEmpty()));
            Observer.Observe('count', Format(Back.Count()));
            Observer.Observe('find_same', Format(Back.Find('=')));
            Observer.Observe('entry_no', Format(Back.Field(1).Value()));
            Observer.Observe('text', Format(Back.Field(6).Value()));
            Observer.Observe('next', Format(Back.Next()));
            Observer.Observe('entry_no_after_next', Format(Back.Field(1).Value()));
        end else
            Observer.Observe('assign_error', GetLastErrorText());
        Observer.Finish();
    end;

    [Test]
    procedure Variant_OriginalClosed_TakenOutBeforeClose()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Back: RecordRef;
        V: Variant;
    begin
        Seed();
        OpenOnFirst(RR);
        V := RR;
        Back := V;
        RR.Close();
        Observer.Observe('taken_out_before_close', RefInfo(Back));
        Observer.Observe('taken_out_after_close', TakenOutInfo(V));
        Observer.Finish();
    end;

    [Test]
    procedure Variant_TakenOutClosed_VariantAndOriginal()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        Back: RecordRef;
        V: Variant;
    begin
        Seed();
        OpenOnFirst(RR);
        V := RR;
        Back := V;
        Back.Close();
        Observer.Observe('closed_one', RefInfo(Back));
        Observer.Observe('original', RefInfo(RR));
        Observer.Observe('variant_kind', Kind(V));
        Observer.Observe('variant_format_is_empty', FormatIsEmpty(V));
        Observer.Observe('taken_out_again', TakenOutInfo(V));
        Observer.Finish();
    end;

    [Test]
    procedure Variant_OriginalMoves_TakenOutRecordRef()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        V: Variant;
    begin
        Seed();
        OpenOnFirst(RR);
        V := RR;
        RR.Next();
        Observer.Observe('original_after_next', RefInfo(RR));
        Observer.Observe('taken_out_after_next', TakenOutInfo(V));
        RR.Field(6).Value := 'changed';
        Observer.Observe('taken_out_after_field_write', TakenOutInfo(V));
        RR.Field(1).SetRange(2);
        Observer.Observe('taken_out_filters', TakenOutFilters(V));
        Observer.Finish();
    end;

    local procedure TakenOutFilters(V: Variant): Text
    var
        RR: RecordRef;
    begin
        if not TryTakeOut(V, RR) then
            exit('assign error:' + GetLastErrorText());
        exit(RR.GetFilters());
    end;

    [Test]
    procedure Variant_OriginalOpenedAgain_TakenOutRecordRef()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        V: Variant;
    begin
        Seed();
        OpenOnFirst(RR);
        V := RR;
        RR.Close();
        RR.Open(Database::"ALT Universal");
        RR.FindLast();
        Observer.Observe('original_opened_again', RefInfo(RR));
        Observer.Observe('taken_out', TakenOutInfo(V));
        Observer.Finish();
    end;

    [Test]
    procedure Variant_OriginalCleared_TakenOutRecordRef()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        V: Variant;
    begin
        Seed();
        OpenOnFirst(RR);
        V := RR;
        Clear(RR);
        Observer.Observe('original_after_clear', RefInfo(RR));
        Observer.Observe('variant_kind', Kind(V));
        Observer.Observe('variant_format_is_empty', FormatIsEmpty(V));
        Observer.Observe('taken_out', TakenOutInfo(V));
        Observer.Finish();
    end;

    [Test]
    procedure Variant_AssignedBeforeOpen_TakenOutRecordRef()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        V: Variant;
    begin
        Seed();
        V := RR;
        Observer.Observe('variant_kind', Kind(V));
        Observer.Observe('format_is_empty_before_open', FormatIsEmpty(V));
        OpenOnFirst(RR);
        Observer.Observe('format_is_empty_after_open', FormatIsEmpty(V));
        Observer.Observe('taken_out_after_open', TakenOutInfo(V));
        Observer.Finish();
    end;

    [Test]
    procedure Variant_CopiedToVariant_OriginalClosed()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        V: Variant;
        V2: Variant;
    begin
        Seed();
        OpenOnFirst(RR);
        V := RR;
        V2 := V;
        RR.Close();
        Observer.Observe('second_variant', DescribeByValue(V2));
        CloseTakenOutByValue(V);
        Observer.Observe('second_variant_after_first_taken_out_closed', DescribeByValue(V2));
        Observer.Finish();
    end;

    [Test]
    procedure VariantByValue_OriginalClosed_Callee()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        V: Variant;
    begin
        Seed();
        OpenOnFirst(RR);
        V := RR;
        Observer.Observe('by_value_before_close', DescribeByValue(V));
        RR.Close();
        Observer.Observe('by_value_after_close', DescribeByValue(V));
        Observer.Finish();
    end;

    [Test]
    procedure VariantByValue_CalleeClosesTakenOut_Caller()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        V: Variant;
    begin
        Seed();
        OpenOnFirst(RR);
        V := RR;
        CloseTakenOutByValue(V);
        Observer.Observe('original', RefInfo(RR));
        Observer.Observe('variant', DescribeByValue(V));
        Observer.Finish();
    end;

    [Test]
    procedure VariantByVar_OriginalClosed_Callee()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        V: Variant;
    begin
        Seed();
        OpenOnFirst(RR);
        V := RR;
        Observer.Observe('by_var_before_close', DescribeByVar(V));
        RR.Close();
        Observer.Observe('by_var_after_close', DescribeByVar(V));
        Observer.Finish();
    end;

    [Test]
    procedure VariantByVar_CalleeClosesTakenOut_Caller()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        V: Variant;
    begin
        Seed();
        OpenOnFirst(RR);
        V := RR;
        CloseTakenOutByVar(V);
        Observer.Observe('original', RefInfo(RR));
        Observer.Observe('variant', DescribeByVar(V));
        Observer.Finish();
    end;

    [Test]
    procedure RecordRefArgument_VariantParameter_Close()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
    begin
        Seed();
        OpenOnFirst(RR);
        Observer.Observe('callee_sees', DescribeByValue(RR));
        CloseTakenOutByValue(RR);
        Observer.Observe('original_after_callee_closed_taken_out', RefInfo(RR));
        Clear(RR);
        OpenOnFirst(RR);
        KeepByValue(RR);
        RR.Close();
        Observer.Observe('kept_after_original_closed', DescribeByValue(KeptVariant));
        Clear(KeptVariant);
        Observer.Finish();
    end;

    [Test]
    procedure RecordRefAssign_OriginalClosed_Copy()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        RR2: RecordRef;
    begin
        Seed();
        OpenOnFirst(RR);
        RR2 := RR;
        RR.Close();
        Observer.Observe('original', RefInfo(RR));
        Observer.Observe('copy', RefInfo(RR2));
        Observer.Finish();
    end;

    [Test]
    procedure RecordRefAssign_CopyClosed_Original()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        RR2: RecordRef;
    begin
        Seed();
        OpenOnFirst(RR);
        RR2 := RR;
        RR2.Close();
        Observer.Observe('copy', RefInfo(RR2));
        Observer.Observe('original', RefInfo(RR));
        Observer.Finish();
    end;

    [Test]
    procedure RecordRefAssign_OriginalMoves_Copy()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        RR2: RecordRef;
    begin
        Seed();
        OpenOnFirst(RR);
        RR2 := RR;
        RR.Next();
        Observer.Observe('copy_after_next', RefInfo(RR2));
        RR.Field(6).Value := 'changed';
        Observer.Observe('copy_after_field_write', RefInfo(RR2));
        RR.Close();
        RR.Open(Database::"ALT Universal");
        RR.FindFirst();
        Observer.Observe('copy_after_original_opened_again', RefInfo(RR2));
        Observer.Finish();
    end;

    [Test]
    procedure RecordRefByValue_CalleeCloses_Caller()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
    begin
        Seed();
        OpenOnFirst(RR);
        CloseByValue(RR);
        Observer.Observe('original', RefInfo(RR));
        Observer.Finish();
    end;

    local procedure CloseByValue(RR: RecordRef)
    begin
        RR.Close();
    end;

    [Test]
    procedure VariantFromRecord_RecordChanges_Contrast()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "ALT Universal";
        Back: RecordRef;
        V: Variant;
    begin
        Seed();
        Row.FindFirst();
        V := Row;
        Row."Text Field" := 'changed';
        Row.Next();
        Observer.Observe('variant_kind', Kind(V));
        Observer.Observe('variant_format_is_empty', FormatIsEmpty(V));
        Back.GetTable(V);
        Observer.Observe('gettable', RefInfo(Back));
        Back.Close();
        Observer.Observe('variant_format_is_empty_after_close', FormatIsEmpty(V));
        Back.GetTable(V);
        Observer.Observe('gettable_again', RefInfo(Back));
        Observer.Finish();
    end;

    [Test]
    procedure DataTypeManagement_GetRecordRef_OriginalClosed()
    var
        Observer: Codeunit "Probe Observer";
        DataTypeManagement: Codeunit "Data Type Management";
        RR: RecordRef;
        Back: RecordRef;
        V: Variant;
        Ok: Boolean;
    begin
        Seed();
        OpenOnFirst(RR);
        V := RR;
        Ok := DataTypeManagement.GetRecordRef(V, Back);
        Observer.Observe('before_close_result', Format(Ok));
        Observer.Observe('before_close', RefInfo(Back));
        Clear(Back);
        RR.Close();
        Ok := DataTypeManagement.GetRecordRef(V, Back);
        Observer.Observe('after_close_result', Format(Ok));
        Observer.Observe('after_close', RefInfo(Back));
        Observer.Finish();
    end;

    [Test]
    procedure DataTypeManagement_GetRecordRef_Record()
    var
        Observer: Codeunit "Probe Observer";
        DataTypeManagement: Codeunit "Data Type Management";
        Row: Record "ALT Universal";
        Back: RecordRef;
        V: Variant;
        Ok: Boolean;
    begin
        Seed();
        Row.FindLast();
        V := Row;
        Ok := DataTypeManagement.GetRecordRef(V, Back);
        Observer.Observe('record_result', Format(Ok));
        Observer.Observe('record', RefInfo(Back));
        Observer.Finish();
    end;

    local procedure FormatCell(V: Variant; Expected: Text): Text
    begin
        exit('empty=' + Format(Format(V) = '') + ' same as record=' + Format(Format(V) = Expected));
    end;

    [Test]
    procedure VariantFormat_HoldsRecord_Cells()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "ALT Universal";
        Blank: Record "ALT Universal";
        Temp: Record "ALT Universal" temporary;
        V: Variant;
    begin
        Seed();
        Row.FindFirst();
        V := Row;
        Observer.Observe('record_with_row', FormatCell(V, Format(Row)));
        Observer.Observe('record_with_row_by_var', Format(FormatByVar(V) = Format(Row)));
        Blank.Init();
        V := Blank;
        Observer.Observe('record_initialized', FormatCell(V, Format(Blank)));
        Observer.Observe('record_initialized_format_is_empty', Format(Format(Blank) = ''));
        Temp."Entry No." := 3;
        Temp."Text Field" := 'temp';
        Temp.Insert();
        V := Temp;
        Observer.Observe('record_temporary', FormatCell(V, Format(Temp)));
        Temp.DeleteAll();
        V := Temp;
        Observer.Observe('record_temporary_no_rows', FormatCell(V, Format(Temp)));
        Observer.Finish();
    end;

    local procedure FormatByVar(var V: Variant): Text
    begin
        exit(Format(V));
    end;

    [Test]
    procedure VariantFormat_HoldsRecordRef_Cells()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "ALT Universal";
        Blank: Record "ALT Universal";
        Positioned: RecordRef;
        NoRow: RecordRef;
        Closed: RecordRef;
        NeverOpened: RecordRef;
        V: Variant;
    begin
        Seed();
        Row.FindFirst();
        Positioned.Open(Database::"ALT Universal");
        Positioned.FindFirst();
        V := Positioned;
        Observer.Observe('recordref_positioned', FormatCell(V, Format(Row)));
        Observer.Observe('recordref_positioned_by_var', Format(FormatByVar(V) = Format(Row)));
        NoRow.Open(Database::"ALT Universal");
        V := NoRow;
        Observer.Observe('recordref_open_no_row', FormatCell(V, Format(Blank)));
        Closed.Open(Database::"ALT Universal");
        Closed.FindFirst();
        Closed.Close();
        V := Closed;
        Observer.Observe('recordref_closed', FormatCell(V, Format(Row)));
        V := NeverOpened;
        Observer.Observe('recordref_never_opened', FormatCell(V, Format(Row)));
        Observer.Finish();
    end;
}
