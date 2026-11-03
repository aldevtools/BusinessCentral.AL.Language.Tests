// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-charallowed-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160), objects in XTableObjects.al
// Probe (issue 611): what a table field or a table extension modify() does at run time for CharAllowed, DateFormula, MaskType, OptionCaptionML,
// SignDisplacement, SQLDataType, SQLTimestamp, Width, BlankZero, CaptionClass, ClosingDates, OptionCaption, and what the table properties
// LinkedObject, ColumnStoreIndex, DataCaptionFields, DrillDownPageId and LookupPageId report and open. The compile results of the invalid
// values are pinned by the must-not-compile cases 0760-0775. Object id 75010.

codeunit 75010 "LT X Table Props Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        OpenedPage: Text;

    local procedure Seed()
    var
        Row: Record "LT X Props";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Insert();
    end;

    local procedure Check(var Observer: Codeunit "Probe Observer"; Name: Text; var Row: Record "LT X Props"; FieldNumber: Integer; Value: Text)
    begin
        ClearLastError();
        if TryValidate(Row, FieldNumber, Value) then
            Observer.Observe(Name, 'no error: ' + Value)
        else
            Observer.ObserveError(Name);
    end;

    [TryFunction]
    local procedure TryValidate(var Row: Record "LT X Props"; FieldNumber: Integer; Value: Text)
    begin
        case FieldNumber of
            Row.FieldNo(Digits):
                Row.Validate(Digits, CopyStr(Value, 1, 20));
            Row.FieldNo(Picky):
                Row.Validate(Picky, CopyStr(Value, 1, 20));
            Row.FieldNo(DateText):
                Row.Validate(DateText, CopyStr(Value, 1, 30));
        end;
    end;

    local procedure LinkedStep(var Observer: Codeunit "Probe Observer"; Name: Text; var Row: Record "LT X Props Linked"; Step: Integer)
    var
        Helper: Codeunit "LT X Linked Step";
    begin
        ClearLastError();
        Helper.SetStep(Step);
        if Helper.Run(Row) then
            Observer.Observe(Name, 'ok')
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure CharAllowed_Validate_AllowedAndDisallowed()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props";
    begin
        Row.Init();
        Row.Id := 1;
        Row.Validate(Digits, '123');
        Observer.Observe('digits_allowed', Row.Digits);
        Check(Observer, 'digits_disallowed', Row, Row.FieldNo(Digits), '12A');
        Row.Digits := '12A';
        Observer.Observe('digits_assigned_not_checked', Row.Digits);
        Row.Validate(Picky, 'abmpz');
        Observer.Observe('picky_allowed', Row.Picky);
        Check(Observer, 'picky_e_between_ranges', Row, Row.FieldNo(Picky), 'abe');
        Check(Observer, 'picky_uppercase', Row, Row.FieldNo(Picky), 'A');
        Check(Observer, 'picky_q', Row, Row.FieldNo(Picky), 'abq');
        Observer.Expect('digits_allowed', '123');
        Observer.Expect('digits_disallowed', 'no error: 12A');
        Observer.Expect('digits_assigned_not_checked', '12A');
        Observer.Expect('picky_allowed', 'abmpz');
        Observer.Expect('picky_e_between_ranges', 'no error: abe');
        Observer.Expect('picky_uppercase', 'no error: A');
        Observer.Expect('picky_q', 'no error: abq');
        Observer.Verify();
    end;

    [Test]
    procedure CharAllowed_TestPage_AllowedAndDisallowed()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT X Props Card";
    begin
        Card.OpenNew();
        Card.Id.SetValue(1);
        Card.Digits.SetValue('456');
        Observer.Observe('page_digits_allowed', Card.Digits.Value);
        asserterror Card.Digits.SetValue('4x6');
        Observer.ObserveError('page_digits_disallowed');
        Observer.Observe('page_digits_after_error', Card.Digits.Value);
        Card.Close();
        Observer.Expect('page_digits_allowed', '456');
        Observer.Expect('page_digits_disallowed|text', 'Validation error for Field: Digits,  Message = ''The character X is not valid in this field. You can specify the following characters: 09. (Select Refresh to discard errors)''');
        Observer.Expect('page_digits_disallowed|code', 'TestValidation');
        Observer.Expect('page_digits_after_error', '456');
        Observer.Verify();
    end;

    [Test]
    procedure DateFormula_TextField_AcceptsFormulaText()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props";
        Card: TestPage "LT X Props Card";
    begin
        Seed();
        Row.Get(1);
        Row.Validate(DateText, '1M');
        Observer.Observe('validate_1M', Row.DateText);
        Row.Validate(DateText, '<CM+1D>');
        Observer.Observe('validate_CM_1D', Row.DateText);
        Check(Observer, 'validate_garbage', Row, Row.FieldNo(DateText), 'not a formula');
        Row.DateText := 'not a formula';
        Row.Modify();
        Observer.Observe('assigned_garbage', Row.DateText);
        Card.OpenEdit();
        Card.DateText.SetValue('2W');
        Observer.Observe('page_2W', Card.DateText.Value);
        Card.DateText.SetValue('xyz');
        Observer.Observe('page_garbage_value', Card.DateText.Value);
        Card.Close();
        Observer.Expect('validate_1M', '1M');
        Observer.Expect('validate_CM_1D', '<CM+1D>');
        Observer.Expect('validate_garbage', 'no error: not a formula');
        Observer.Expect('assigned_garbage', 'not a formula');
        Observer.Expect('page_2W', '2W');
        Observer.Expect('page_garbage_value', 'xyz');
        Observer.Verify();
    end;

    [Test]
    procedure MaskType_ConcealedAndNone_ValueUnchanged()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props";
        Card: TestPage "LT X Props Card";
    begin
        Seed();
        Row.Get(1);
        Row.Secret := 'pw-1';
        Row.Plain := 'open-1';
        Row.Secret2 := 'pw-2';
        Row.Modify();
        Card.OpenEdit();
        Observer.Observe('page_concealed', Card.Secret.Value);
        Observer.Observe('page_none', Card.Plain.Value);
        Card.Secret.SetValue('pw-3');
        Observer.Observe('page_after_set', Card.Secret.Value);
        Card.Close();
        Row.Get(1);
        Observer.Observe('record_secret', Row.Secret);
        Observer.Observe('record_plain', Row.Plain);
        Observer.Observe('record_secret2', Row.Secret2);
        Observer.Expect('page_concealed', 'pw-1');
        Observer.Expect('page_none', 'open-1');
        Observer.Expect('page_after_set', 'pw-3');
        Observer.Expect('record_secret', 'pw-3');
        Observer.Expect('record_plain', 'open-1');
        Observer.Expect('record_secret2', 'pw-2');
        Observer.Verify();
    end;

    [Test]
    procedure OptionCaptionML_Field_CaptionPerLanguage()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props";
        Ref: FieldRef;
        RecRef: RecordRef;
        Card: TestPage "LT X Props Card";
        OldLanguage: Integer;
    begin
        Seed();
        Row.Get(1);
        Row.Op := Row.Op::B;
        Row.OptMl := Row.OptMl::C;
        Row.Modify();
        OldLanguage := GlobalLanguage();
        GlobalLanguage(1033);
        Observer.Observe('enu_format', Format(Row.Op));
        Observer.Observe('enu_format_modified_field', Format(Row.OptMl));
        RecRef.GetTable(Row);
        Ref := RecRef.Field(Row.FieldNo(Op));
        Observer.Observe('enu_optioncaption', Ref.OptionCaption);
        Observer.Observe('enu_optionmembers', Ref.OptionMembers);
        Ref := RecRef.Field(Row.FieldNo(OptMl));
        Observer.Observe('enu_optioncaption_modified', Ref.OptionCaption);
        GlobalLanguage(1031);
        Observer.Observe('deu_format', Format(Row.Op));
        Observer.Observe('deu_format_modified_field', Format(Row.OptMl));
        Ref := RecRef.Field(Row.FieldNo(Op));
        Observer.Observe('deu_optioncaption', Ref.OptionCaption);
        Ref := RecRef.Field(Row.FieldNo(OptMl));
        Observer.Observe('deu_optioncaption_modified', Ref.OptionCaption);
        GlobalLanguage(1036);
        Observer.Observe('fra_format_fallback', Format(Row.Op));
        Observer.Observe('fra_format_modified_fallback', Format(Row.OptMl));
        Ref := RecRef.Field(Row.FieldNo(Op));
        Observer.Observe('fra_optioncaption_fallback', Ref.OptionCaption);
        Ref := RecRef.Field(Row.FieldNo(OptMl));
        Observer.Observe('fra_optioncaption_modified_fallback', Ref.OptionCaption);
        GlobalLanguage(1031);
        Card.OpenEdit();
        Observer.Observe('deu_page_op', Card.Op.Value);
        Observer.Observe('deu_page_optml_modified', Card.OptMl.Value);
        Card.Close();
        GlobalLanguage(OldLanguage);
        Observer.Expect('enu_format', 'Beta');
        Observer.Expect('enu_format_modified_field', 'Yellow');
        Observer.Expect('enu_optioncaption', 'Alpha,Beta,Gamma');
        Observer.Expect('enu_optionmembers', 'A,B,C');
        Observer.Expect('enu_optioncaption_modified', 'Cyan,Magenta,Yellow');
        Observer.Expect('deu_format', 'Zwei');
        Observer.Expect('deu_format_modified_field', 'Gelb');
        Observer.Expect('deu_optioncaption', 'Eins,Zwei,Drei');
        Observer.Expect('deu_optioncaption_modified', 'Zyan,Magenta,Gelb');
        Observer.Expect('fra_format_fallback', 'Beta');
        Observer.Expect('fra_format_modified_fallback', 'Yellow');
        Observer.Expect('fra_optioncaption_fallback', 'Alpha,Beta,Gamma');
        Observer.Expect('fra_optioncaption_modified_fallback', 'Cyan,Magenta,Yellow');
        Observer.Expect('deu_page_op', 'Zwei');
        Observer.Expect('deu_page_optml_modified', 'Gelb');
        Observer.Verify();
    end;

    [Test]
    procedure SignDisplacement_Format_NegativeAndPositive()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props";
        Card: TestPage "LT X Props Card";
    begin
        Seed();
        Row.Get(1);
        Row.Disp := -1234.5;
        Row.Modify();
        Observer.Observe('format_negative', Format(Row.Disp));
        Row.Disp := 1234.5;
        Row.Modify();
        Observer.Observe('format_positive', Format(Row.Disp));
        Row.Disp := 0;
        Row.Modify();
        Observer.Observe('format_zero', Format(Row.Disp));
        Row.Disp := -1234.5;
        Row.Modify();
        Card.OpenEdit();
        Observer.Observe('page_negative', Card.Disp.Value);
        Card.Close();
        Observer.Expect('format_negative', '-1,234.5');
        Observer.Expect('format_positive', '1,234.5');
        Observer.Expect('format_zero', '0');
        Observer.Expect('page_negative', '-1,234.50');
        Observer.Verify();
    end;

    local procedure SeedSql(var Row: Record "LT X Props Sql")
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.AsInteger := '10';
        Row.AsVarchar := '10';
        Row.AsBigInteger := '10';
        Row.AsDefault := '10';
        Row.Insert();
        Row.Init();
        Row.Id := 2;
        Row.AsInteger := '9';
        Row.AsVarchar := '9';
        Row.AsBigInteger := '9';
        Row.AsDefault := '9';
        Row.Insert();
        Row.Init();
        Row.Id := 3;
        Row.AsVarchar := 'ABC';
        Row.AsDefault := 'ABC';
        Row.Insert();
    end;

    // A database error ends the transaction ("An error occurred and the transaction is stopped"), so each step that may fail is its own test.
    [Test]
    procedure SQLDataType_Code_ReadRowsAndKeys()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props Sql";
    begin
        SeedSql(Row);
        Row.Get(1);
        Observer.Observe('integer_value', Row.AsInteger);
        Observer.Observe('varchar_value', Row.AsVarchar);
        Observer.Observe('bigint_value', Row.AsBigInteger);
        Row.Get(3);
        Observer.Observe('integer_empty_on_row_3', Row.AsInteger);
        Observer.Observe('varchar_text_on_row_3', Row.AsVarchar);
        Row.SetCurrentKey(AsInteger);
        Row.FindFirst();
        Observer.Observe('first_by_integer_key', Format(Row.Id));
        Row.FindLast();
        Observer.Observe('last_by_integer_key', Format(Row.Id));
        Row.SetCurrentKey(AsVarchar);
        Row.FindFirst();
        Observer.Observe('first_by_varchar_key', Format(Row.Id));
        Row.FindLast();
        Observer.Observe('last_by_varchar_key', Format(Row.Id));
        Observer.Expect('integer_value', '10');
        Observer.Expect('varchar_value', '10');
        Observer.Expect('bigint_value', '10');
        Observer.Expect('integer_empty_on_row_3', '');
        Observer.Expect('varchar_text_on_row_3', 'ABC');
        Observer.Expect('first_by_integer_key', '3');
        Observer.Expect('last_by_integer_key', '1');
        Observer.Expect('first_by_varchar_key', '1');
        Observer.Expect('last_by_varchar_key', '3');
        Observer.Verify();
    end;

    [Test]
    procedure SQLDataType_Code_GetRowWithNine()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props Sql";
    begin
        SeedSql(Row);
        Row.Get(2);
        Observer.Observe('integer_nine', Row.AsInteger);
        Observer.Expect('integer_nine', '9');
        Observer.Verify();
    end;

    [Test]
    procedure SQLDataType_Code_ModifyToZeroErrors()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props Sql";
    begin
        SeedSql(Row);
        Row.Get(1);
        Row.AsInteger := '0';
        asserterror Row.Modify();
        Observer.ObserveError('modify_zero');
        Observer.Expect('modify_zero|text', 'The LT X Props Sql table contains a value that is not valid in an integer Code field:\\Id=''1''\Error code: 22928070');
        Observer.Expect('modify_zero|code', 'NDBCS:BadCSideCodeData');
        Observer.Verify();
    end;

    [Test]
    procedure SQLDataType_Code_ModifyToLeadingZeroErrors()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props Sql";
    begin
        SeedSql(Row);
        Row.Get(1);
        Row.AsInteger := '007';
        asserterror Row.Modify();
        Observer.ObserveError('modify_leading_zero');
        Observer.Expect('modify_leading_zero|text', 'The LT X Props Sql table contains a value that is not valid in an integer Code field:\\Id=''1''\Error code: 22928070');
        Observer.Expect('modify_leading_zero|code', 'NDBCS:BadCSideCodeData');
        Observer.Verify();
    end;

    [Test]
    procedure SQLDataType_Code_ModifyToText()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props Sql";
    begin
        SeedSql(Row);
        Row.Get(1);
        Row.AsInteger := 'ABC';
        asserterror Row.Modify();
        Observer.ObserveError('modify_text');
        Observer.Expect('modify_text|text', 'The LT X Props Sql table contains a value that is not valid in an integer Code field:\\Id=''1''\Error code: 22928072');
        Observer.Expect('modify_text|code', 'NDBCS:BadSqlIntCodeData');
        Observer.Verify();
    end;

    [Test]
    procedure SQLTimestamp_BigIntegerField_ReadsRowVersion()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props";
        First: BigInteger;
        Second: BigInteger;
    begin
        Seed();
        Row.Get(1);
        First := Row.Stamp;
        Observer.Observe('stamp_positive_after_insert', Format(First > 0));
        Row.DateText := '1D';
        Row.Modify();
        Row.Get(1);
        Second := Row.Stamp;
        Observer.Observe('stamp_grows_after_modify', Format(Second > First));
        Row.Get(1);
        Observer.Observe('stamp_stable_without_modify', Format(Row.Stamp = Second));
        Row.Stamp := 5;
        Row.Modify();
        Row.Get(1);
        Observer.Observe('stamp_assignment_ignored', Format(Row.Stamp <> 5));
        Observer.Expect('stamp_positive_after_insert', 'Yes');
        Observer.Expect('stamp_grows_after_modify', 'Yes');
        Observer.Expect('stamp_stable_without_modify', 'Yes');
        Observer.Expect('stamp_assignment_ignored', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Width_TextField_ValueNotTruncated()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props";
        Card: TestPage "LT X Props Card";
    begin
        Seed();
        Row.Get(1);
        Row.Wide := 'abcdefghijklmnopqrstuvwxyz';
        Row.Wide2 := 'abcdefghijklmnopqrstuvwxyz';
        Row.Modify();
        Row.Get(1);
        Observer.Observe('wide_value', Row.Wide);
        Observer.Observe('wide2_value_modified_to_5', Row.Wide2);
        Card.OpenEdit();
        Observer.Observe('page_wide', Card.Wide.Value);
        Card.Close();
        Observer.Expect('wide_value', 'abcdefghijklmnopqrstuvwxyz');
        Observer.Expect('wide2_value_modified_to_5', 'abcdefghijklmnopqrstuvwxyz');
        Observer.Expect('page_wide', 'abcdefghijklmnopqrstuvwxyz');
        Observer.Verify();
    end;

    [Test]
    procedure TableExt_ModifyBlankZero_FormatAndPage()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props";
        Card: TestPage "LT X Props Card";
    begin
        Seed();
        Row.Get(1);
        Observer.Observe('format_zero_blankzero_true_modified_false', Format(Row.Bz));
        Observer.Observe('format_zero_blankzero_false_modified_true', Format(Row.Bz2));
        Card.OpenEdit();
        Observer.Observe('page_zero_modified_false', Card.Bz.Value);
        Observer.Observe('page_zero_modified_true', Card.Bz2.Value);
        Card.Close();
        Row.Bz := 5;
        Row.Bz2 := 5;
        Row.Modify();
        Observer.Observe('format_five_modified_false', Format(Row.Bz));
        Observer.Observe('format_five_modified_true', Format(Row.Bz2));
        Observer.Expect('format_zero_blankzero_true_modified_false', '0');
        Observer.Expect('format_zero_blankzero_false_modified_true', '0');
        Observer.Expect('page_zero_modified_false', '0.00');
        Observer.Expect('page_zero_modified_true', '');
        Observer.Expect('format_five_modified_false', '5');
        Observer.Expect('format_five_modified_true', '5');
        Observer.Verify();
    end;

    [Test]
    procedure TableExt_ModifyCaptionClass_ResolvedCaption()
    var
        Observer: Codeunit "Probe Observer";
        Subscriber: Codeunit "LT X Caption Subscriber";
        Card: TestPage "LT X Props Card";
    begin
        Seed();
        Subscriber.Take();
        Card.OpenEdit();
        Observer.Observe('resolver_calls_at_open', Subscriber.Take());
        Observer.Observe('caption_base_modified', Card.CapCls.Caption());
        Observer.Observe('caption_second_modified', Card.CapCls2.Caption());
        Observer.Observe('caption_plain_field', Card.Id.Caption());
        Card.Close();
        Observer.Expect('resolver_calls_at_open', '');
        Observer.Expect('caption_base_modified', 'resolved:Modified');
        Observer.Expect('caption_second_modified', 'resolved:Modified2');
        Observer.Expect('caption_plain_field', 'Id');
        Observer.Verify();
    end;

    [Test]
    procedure TableExt_ModifyClosingDates_FormatAndValidate()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props";
        Card: TestPage "LT X Props Card";
        D: Date;
    begin
        Seed();
        Row.Get(1);
        D := ClosingDate(DMY2Date(31, 12, 2025));
        Row.Closing := D;
        Row.Closing2 := D;
        Observer.Observe('format_closing_modified_off', Format(Row.Closing));
        Observer.Observe('format_closing_modified_on', Format(Row.Closing2));
        Observer.Observe('is_closing_date', Format(D = ClosingDate(DMY2Date(31, 12, 2025))));
        Row.Modify();
        Row.Get(1);
        Observer.Observe('stored_modified_off', Format(Row.Closing));
        Observer.Observe('stored_modified_on', Format(Row.Closing2));
        Card.OpenEdit();
        Observer.Observe('page_modified_off', Card.Closing.Value);
        Observer.Observe('page_modified_on', Card.Closing2.Value);
        Card.Close();
        Observer.Expect('format_closing_modified_off', 'C12/31/25');
        Observer.Expect('format_closing_modified_on', 'C12/31/25');
        Observer.Expect('is_closing_date', 'Yes');
        Observer.Expect('stored_modified_off', 'C12/31/25');
        Observer.Expect('stored_modified_on', 'C12/31/25');
        Observer.Expect('page_modified_off', '12/31/2025');
        Observer.Expect('page_modified_on', 'C12/31/2025');
        Observer.Verify();
    end;

    [Test]
    procedure TableExt_ModifyOptionCaption_FormatAndPage()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props";
        RecRef: RecordRef;
        Ref: FieldRef;
        Card: TestPage "LT X Props Card";
    begin
        Seed();
        Row.Get(1);
        Row.OptCap := Row.OptCap::B;
        Row.Modify();
        Observer.Observe('format_modified', Format(Row.OptCap));
        RecRef.GetTable(Row);
        Ref := RecRef.Field(Row.FieldNo(OptCap));
        Observer.Observe('fieldref_optioncaption', Ref.OptionCaption);
        Observer.Observe('fieldref_optionmembers', Ref.OptionMembers);
        Card.OpenEdit();
        Observer.Observe('page_value', Card.OptCap.Value);
        Card.OptCap.SetValue('Tres');
        Observer.Observe('page_after_set_caption', Card.OptCap.Value);
        Card.Close();
        Row.Get(1);
        Observer.Observe('record_after_page', Format(Row.OptCap, 0, 2));
                Seed();
        Card.OpenEdit();
        asserterror Card.OptCap.SetValue('Two');
        Observer.ObserveError('page_set_replaced_base_caption');
        Card.Close();
Observer.Expect('format_modified', 'Dos');
Observer.Expect('fieldref_optioncaption', 'Uno,Dos,Tres');
Observer.Expect('fieldref_optionmembers', 'A,B,C');
Observer.Expect('page_value', 'Dos');
Observer.Expect('page_after_set_caption', 'Tres');
Observer.Expect('record_after_page', '2');
Observer.Expect('page_set_replaced_base_caption|text', 'Validation error for Field: OptCap,  Message = ''Your entry of ''Two'' is not an acceptable value for ''OptCap''. (Select Refresh to discard errors)''');
Observer.Expect('page_set_replaced_base_caption|code', 'TestValidation');
Observer.Verify();
    end;

    [Test]
    procedure TableProperties_Metadata_LookupDrillDownDataCaption()
    var
        Observer: Codeunit "Probe Observer";
        Meta: Record "Table Metadata";
    begin
        Meta.Get(Database::"LT X Props");
        Observer.Observe('props_lookup_page_is_target', Format(Meta.LookupPageID = Page::"LT X Lookup Target"));
        Observer.Observe('props_drilldown_page_is_target', Format(Meta.DrillDownPageId = Page::"LT X Drill Target"));
        Observer.Observe('props_data_caption_fields', Meta.DataCaptionFields);
        Observer.Observe('props_linked_object', Format(Meta.LinkedObject));
        Meta.Get(Database::"LT X Props Linked");
        Observer.Observe('linked_linked_object', Format(Meta.LinkedObject));
        Observer.Observe('linked_lookup_page', Format(Meta.LookupPageID));
        Meta.Get(Database::"LT X Props Column Store");
        Observer.Observe('columnstore_linked_object', Format(Meta.LinkedObject));
        Observer.Expect('props_lookup_page_is_target', 'Yes');
        Observer.Expect('props_drilldown_page_is_target', 'Yes');
        Observer.Expect('props_data_caption_fields', '1,4');
        Observer.Expect('props_linked_object', 'No');
        Observer.Expect('linked_linked_object', 'Yes');
        Observer.Expect('linked_lookup_page', '0');
        Observer.Expect('columnstore_linked_object', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure TableExt_DataCaptionFields_TestPageCaption()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props";
        Card: TestPage "LT X Props Card";
    begin
        Seed();
        Row.Get(1);
        Row.DateText := '1M';
        Row.Modify();
        Card.OpenEdit();
        Observer.Observe('page_caption', Card.Caption());
        Card.Close();
        Observer.Expect('page_caption', 'LT X Props Card - 1 ∙ 1M');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LookupTargetHandler')]
    procedure TableExt_LookupPageId_FieldLookupOpensIt()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props";
        Card: TestPage "LT X Props Card";
    begin
        Seed();
        Row.Init();
        Row.Id := 2;
        Row.Insert();
        OpenedPage := '';
        Card.OpenEdit();
        Card.Rel.Lookup();
        Observer.Observe('opened_page', OpenedPage);
        Observer.Observe('related_value_after_lookup', Card.Rel.Value);
        Card.Close();
        Observer.Expect('opened_page', 'LT X Lookup Target');
        Observer.Expect('related_value_after_lookup', '2');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure LookupTargetHandler(var Target: TestPage "LT X Lookup Target")
    begin
        OpenedPage := 'LT X Lookup Target';
        Target.GoToKey(2);
        Target.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('DrillTargetHandler')]
    procedure TableExt_DrillDownPageId_FlowFieldDrillDownOpensIt()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT X Props Card";
    begin
        Seed();
        OpenedPage := '';
        Card.OpenEdit();
        Card.Cnt.DrillDown();
        Observer.Observe('opened_page', OpenedPage);
        Card.Close();
        Observer.Expect('opened_page', 'LT X Drill Target');
        Observer.Verify();
    end;

    [PageHandler]
    procedure DrillTargetHandler(var Target: TestPage "LT X Drill Target")
    begin
        OpenedPage := 'LT X Drill Target';
        Target.Close();
    end;

    [Test]
    procedure AllowInCustomizations_Table_FieldsStillUsable()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props";
    begin
        Seed();
        Row.Get(1);
        Row.DateText := 'x';
        Row.Modify();
        Row.Get(1);
        Observer.Observe('base_never_field_id', Format(Row.Id));
        Observer.Observe('modified_field', Row.DateText);
        Observer.Expect('base_never_field_id', '1');
        Observer.Expect('modified_field', 'x');
        Observer.Verify();
    end;

    [Test]
    procedure ColumnStoreIndex_Table_ReadsUnchanged()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props Column Store";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Amount := 10.5;
        Row.Note := 'a';
        Row.Insert();
        Row.Id := 2;
        Row.Amount := 20;
        Row.Insert();
        Row.CalcSums(Amount);
        Observer.Observe('sum', Format(Row.Amount));
        Observer.Observe('count', Format(Row.Count()));
        Row.Get(2);
        Observer.Observe('row2_amount', Format(Row.Amount));
        Row.Amount := 21;
        Row.Modify();
        Row.Get(2);
        Observer.Observe('row2_amount_after_modify', Format(Row.Amount));
        Row.Delete();
        Observer.Observe('count_after_delete', Format(Row.Count()));
        Observer.Expect('sum', '30.5');
        Observer.Expect('count', '2');
        Observer.Expect('row2_amount', '20');
        Observer.Expect('row2_amount_after_modify', '21');
        Observer.Expect('count_after_delete', '1');
        Observer.Verify();
    end;

    [Test]
    procedure LinkedObject_Table_InsertAndReadBehavior()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props Linked";
    begin
        Row.Id := 1;
        Row.Note := 'a';
        LinkedStep(Observer, 'insert_1', Row, 1);
        LinkedStep(Observer, 'count', Row, 2);
        Row.Id := 2;
        LinkedStep(Observer, 'insert_2', Row, 1);
        Observer.Expect('insert_1|text', 'An unexpected error occurred after a database command was cancelled.');
        Observer.Expect('insert_1|code', 'Sql:Sql');
        Observer.Expect('count|text', 'An unexpected error occurred after a database command was cancelled.');
        Observer.Expect('count|code', 'Sql:Sql');
        Observer.Expect('insert_2|text', 'An unexpected error occurred after a database command was cancelled.');
        Observer.Expect('insert_2|code', 'Sql:Sql');
        Observer.Verify();
    end;

    [Test]
    procedure ReportColumn_OptionCaptionML_CaptionPerLanguage()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Line: Text;
        Result: Text;
        OldLanguage: Integer;
        Language: Integer;
        Name: Text;
    begin
        Seed();
        Row.Get(1);
        Row.Op := Row.Op::B;
        Row.Modify();
        OldLanguage := GlobalLanguage();
        foreach Language in LanguageList() do begin
            GlobalLanguage(Language);
            Clear(TempBlob);
            TempBlob.CreateOutStream(OutStr);
            Report.SaveAs(Report::"LT X Option Report", '', ReportFormat::Xml, OutStr);
            TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
            Result := '';
            while not InStr.EOS() do begin
                InStr.ReadText(Line);
                if Line.Trim().StartsWith('<Column ') then
                    Result += '[' + Line.Trim() + ']';
            end;
            case Language of
                1033:
                    Name := 'enu';
                1031:
                    Name := 'deu';
                else
                    Name := 'fra';
            end;
            Observer.Observe(Name + '_columns', Result);
        end;
        GlobalLanguage(OldLanguage);
        Observer.Expect('enu_columns', '[<Column name="Plain">Beta</Column>][<Column name="WithCaptionML">Col two</Column>][<Column name="EnuOnly">Only B</Column>]');
        Observer.Expect('deu_columns', '[<Column name="Plain">Zwei</Column>][<Column name="WithCaptionML">Spalte zwei</Column>][<Column name="EnuOnly">Only B</Column>]');
        Observer.Expect('fra_columns', '[<Column name="Plain">Beta</Column>][<Column name="WithCaptionML">Col two</Column>][<Column name="EnuOnly">Only B</Column>]');
        Observer.Verify();
    end;

    local procedure LanguageList() Languages: List of [Integer]
    begin
        Languages.Add(1033);
        Languages.Add(1031);
        Languages.Add(1036);
    end;

    // Writer PX (runtime probes-needed "Format of an Option member"): Format(Rec.Field::Member, Length[, FormatNumber]) other than (.., 0, 9),
    // on Op (OptionCaptionML ENU/DEU) and OptCap (OptionCaption changed by the table extension), in 1033 and 1031.
    [Test]
    procedure PX_Format_OptionMember_LengthAndFormatNumber()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props";
        OldLanguage: Integer;
        Lang: Integer;
    begin
        OldLanguage := GlobalLanguage();
        foreach Lang in PxLanguages() do begin
            GlobalLanguage(Lang);
            Observer.Observe(Format(Lang) + '_op_0_0', Format(Row.Op::B, 0, 0));
            Observer.Observe(Format(Lang) + '_op_0_1', Format(Row.Op::B, 0, 1));
            Observer.Observe(Format(Lang) + '_op_0_2', Format(Row.Op::B, 0, 2));
            Observer.Observe(Format(Lang) + '_op_1', Format(Row.Op::B, 1));
            Observer.Observe(Format(Lang) + '_op_3', Format(Row.Op::B, 3));
            Observer.Observe(Format(Lang) + '_op_10', Format(Row.Op::B, 10));
            Observer.Observe(Format(Lang) + '_op_3_9', Format(Row.Op::B, 3, 9));
            Observer.Observe(Format(Lang) + '_optcap_0_2', Format(Row.OptCap::C, 0, 2));
            Observer.Observe(Format(Lang) + '_optcap_2', Format(Row.OptCap::C, 2));
            Observer.Observe(Format(Lang) + '_optcap_8', Format(Row.OptCap::C, 8));
            Observer.Observe(Format(Lang) + '_optcap_0_1', Format(Row.OptCap::C, 0, 1));
        end;
        GlobalLanguage(OldLanguage);
        Observer.Expect('1033_op_0_0', 'Beta');
        Observer.Expect('1033_op_0_1', 'Beta');
        Observer.Expect('1033_op_0_2', '1');
        Observer.Expect('1033_op_1', 'B');
        Observer.Expect('1033_op_3', 'Bet');
        Observer.Expect('1033_op_10', 'Beta      ');
        Observer.Expect('1033_op_3_9', '1  ');
        Observer.Expect('1033_optcap_0_2', '2');
        Observer.Expect('1033_optcap_2', 'Tr');
        Observer.Expect('1033_optcap_8', 'Tres    ');
        Observer.Expect('1033_optcap_0_1', 'Tres');
        Observer.Expect('1031_op_0_0', 'Zwei');
        Observer.Expect('1031_op_0_1', 'Zwei');
        Observer.Expect('1031_op_0_2', '1');
        Observer.Expect('1031_op_1', 'Z');
        Observer.Expect('1031_op_3', 'Zwe');
        Observer.Expect('1031_op_10', 'Zwei      ');
        Observer.Expect('1031_op_3_9', '1  ');
        Observer.Expect('1031_optcap_0_2', '2');
        Observer.Expect('1031_optcap_2', 'Tr');
        Observer.Expect('1031_optcap_8', 'Tres    ');
        Observer.Expect('1031_optcap_0_1', 'Tres');
        Observer.Verify();
    end;

    local procedure PxLanguages() Languages: List of [Integer]
    begin
        Languages.Add(1033);
        Languages.Add(1031);
    end;

    // Writer PX (runtime probes-needed "OptionCaptionML"): Format and FieldRef.OptionCaption in 1040 (no ITA entry), Evaluate of captions
    // in 1031 and 1033, and GetFilter/GetFilters of the field in 1031 and 1033.
    [Test]
    procedure PX_OptionCaptionML_ItalianEvaluateGetFilter()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props";
        RecRef: RecordRef;
        OldLanguage: Integer;
        Ok: Boolean;
    begin
        Seed();
        Row.Get(1);
        Row.Op := Row.Op::B;
        Row.OptMl := Row.OptMl::C;
        OldLanguage := GlobalLanguage();
        GlobalLanguage(1040);
        Observer.Observe('ita_format', Format(Row.Op));
        Observer.Observe('ita_format_member', Format(Row.Op::C));
        Observer.Observe('ita_format_modified', Format(Row.OptMl));
        RecRef.GetTable(Row);
        Observer.Observe('ita_optioncaption', RecRef.Field(Row.FieldNo(Op)).OptionCaption);
        Observer.Observe('ita_optioncaption_modified', RecRef.Field(Row.FieldNo(OptMl)).OptionCaption);
        GlobalLanguage(1031);
        Ok := Evaluate(Row.Op, 'Drei');
        Observer.Observe('deu_eval_deu', Format(Ok) + '/' + Format(Row.Op, 0, 9));
        Ok := Evaluate(Row.Op, 'Alpha');
        Observer.Observe('deu_eval_enu', Format(Ok) + '/' + Format(Row.Op, 0, 9));
        Ok := Evaluate(Row.Op, 'B');
        Observer.Observe('deu_eval_member', Format(Ok) + '/' + Format(Row.Op, 0, 9));
        Ok := Evaluate(Row.OptMl, 'Gelb');
        Observer.Observe('deu_eval_modified', Format(Ok) + '/' + Format(Row.OptMl, 0, 9));
        Ok := Evaluate(Row.OptMl, 'Blau');
        Observer.Observe('deu_eval_base_caption_of_modified', Format(Ok) + '/' + Format(Row.OptMl, 0, 9));
        Row.SetRange(Op, Row.Op::B);
        Row.SetRange(OptMl, Row.OptMl::A, Row.OptMl::B);
        Observer.Observe('deu_getfilter', Row.GetFilter(Op));
        Observer.Observe('deu_getfilter_modified', Row.GetFilter(OptMl));
        Observer.Observe('deu_getfilters', Row.GetFilters());
        Row.SetFilter(Op, 'Drei');
        Observer.Observe('deu_setfilter_caption_count', Format(Row.Count()));
        Observer.Observe('deu_setfilter_caption_getfilter', Row.GetFilter(Op));
        GlobalLanguage(1033);
        Row.SetRange(Op, Row.Op::B);
        Observer.Observe('enu_getfilter', Row.GetFilter(Op));
        Observer.Observe('enu_getfilters', Row.GetFilters());
        Ok := Evaluate(Row.Op, 'Zwei');
        Observer.Observe('enu_eval_deu', Format(Ok) + '/' + Format(Row.Op, 0, 9));
        GlobalLanguage(1040);
        Observer.Observe('ita_getfilters', Row.GetFilters());
        GlobalLanguage(OldLanguage);
        Observer.Expect('ita_format', 'Beta');
        Observer.Expect('ita_format_member', 'Gamma');
        Observer.Expect('ita_format_modified', 'Yellow');
        Observer.Expect('ita_optioncaption', 'Alpha,Beta,Gamma');
        Observer.Expect('ita_optioncaption_modified', 'Cyan,Magenta,Yellow');
        Observer.Expect('deu_eval_deu', 'Ja/2');
        Observer.Expect('deu_eval_enu', 'Nein/2');
        Observer.Expect('deu_eval_member', 'Ja/1');
        Observer.Expect('deu_eval_modified', 'Ja/2');
        Observer.Expect('deu_eval_base_caption_of_modified', 'Nein/2');
        Observer.Expect('deu_getfilter', 'Zwei');
        Observer.Expect('deu_getfilter_modified', 'Zyan..Magenta');
        Observer.Expect('deu_getfilters', 'Op: Zwei, OptMl: Zyan..Magenta');
        Observer.Expect('deu_setfilter_caption_count', '0');
        Observer.Expect('deu_setfilter_caption_getfilter', 'Drei');
        Observer.Expect('enu_getfilter', 'Beta');
        Observer.Expect('enu_getfilters', 'Op: Beta, OptMl: Cyan..Magenta');
        Observer.Expect('enu_eval_deu', 'No/1');
        Observer.Expect('ita_getfilters', 'Op: Beta, OptMl: Cyan..Magenta');
        Observer.Verify();
    end;


    // Writer QZ: CharAllowed through SetValue on a List page (fixture page 87708 in QzCharAllowedList.al).
    [Test]
    procedure QZ_CharAllowed_TestPage_List()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT X Props";
        List: TestPage "LT QZ X Props List";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 2;
        Row.Insert();
        List.OpenEdit();
        List.GoToRecord(Row);
        List.Digits.SetValue('456');
        Observer.Observe('list_digits_allowed', List.Digits.Value);
        asserterror begin
            List.Digits.SetValue('4x6');
            Error('no error');
        end;
        Observer.ObserveError('list_digits_disallowed');
        Observer.Observe('list_digits_after_error', List.Digits.Value);
        asserterror begin
            List.Picky.SetValue('abq');
            Error('no error');
        end;
        Observer.ObserveError('list_picky_disallowed');
        Observer.Observe('list_picky_after_error', List.Picky.Value);
        List.Close();
        Observer.Expect('list_digits_allowed', '456');
        Observer.Expect('list_digits_disallowed|text', 'Validation error for Field: Digits,  Message = ''The character X is not valid in this field. You can specify the following characters: 09.''');
        Observer.Expect('list_digits_disallowed|code', 'TestValidation');
        Observer.Expect('list_digits_after_error', '456');
        Observer.Expect('list_picky_disallowed|text', 'Validation error for Field: Picky,  Message = ''The character q is not valid in this field. You can specify the following characters: ad,mp,zz.''');
        Observer.Expect('list_picky_disallowed|code', 'TestValidation');
        Observer.Expect('list_picky_after_error', '');
        Observer.Verify();
    end;
}
