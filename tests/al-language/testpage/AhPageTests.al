// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testpage-class
// Scope: in-scope
// Fixtures used: Probe Observer (69160); AhPageObjects.al (tables 78610, 78616, 78617; pages 78611-78615, 78618, 78619); own codeunits 78620-78622
// Probe (corpus issue 636): item 5 TestPage Close after a refused SetValue (MinValue/MaxValue, failed number conversion, OnValidate, CharAllowed);
// item 6 GetValidationError() with three or more errors; item 7 CharAllowed with several ranges; item 4 a ShowAsTree repeater opened through
// Page.Run / a Page variable; item 8 a part edit when the host is a list over the same table and when it is a document page.
// BC versions: 27+

codeunit 78620 "LT AH Card Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT AH Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 'R1';
        Row.Txt := 'orig';
        Row.Qty := 5;
        Row.Dec := 1;
        Row.Name := 'n0';
        Row.Other := 'o0';
        Row.Insert();
        Commit();
    end;

    local procedure Stored(): Text
    var
        Row: Record "LT AH Row";
    begin
        if not Row.Get('R1') then
            exit('row missing');
        exit('Txt=' + Row.Txt + '|Qty=' + Format(Row.Qty) + '|Dec=' + Format(Row.Dec) + '|Name=' + Row.Name + '|Other=' + Row.Other + '|Guard=' + Row.Guard + '|Letters=' + Row.Letters);
    end;

    [TryFunction]
    local procedure TryClose(var P: TestPage "LT AH Card")
    begin
        P.Close();
    end;

    local procedure CloseObserved(var Observer: Codeunit "Probe Observer"; var P: TestPage "LT AH Card")
    begin
        Observer.Observe('close_ok', Format(TryClose(P)));
        if GetLastErrorText() <> '' then
            Observer.ObserveError('close_error');
        Observer.Observe('stored', Stored());
    end;

    [Test]
    procedure Close_AfterRefusedMaxValue_KeepsValidEdits()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        P.TxtCtl.SetValue('new');
        asserterror P.QtyCtl.SetValue(99);
        Observer.ObserveError('refused');
        P.OtherCtl.SetValue('o1');
        Observer.Observe('count_before_close', Format(P.ValidationErrorCount()));
        Observer.Observe('qty_value_on_page', P.QtyCtl.Value());
        CloseObserved(Observer, P);
        Observer.Expect('refused|text', 'Validation error for Field: QtyCtl,  Message = ''The value must be less than or equal to 10. Value: 99. (Select Refresh to discard errors)''');
        Observer.Expect('refused|code', 'TestValidation');
        Observer.Expect('count_before_close', '1');
        Observer.Expect('qty_value_on_page', '5');
        Observer.Expect('close_ok', 'Yes');
        Observer.Expect('stored', 'Txt=orig|Qty=5|Dec=1|Name=n0|Other=o0|Guard=|Letters=');
        Observer.Verify();
    end;

    [Test]
    procedure Close_AfterRefusedMinValueDecimal()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        P.NameCtl.SetValue('n1');
        asserterror P.DecCtl.SetValue(-5);
        Observer.ObserveError('refused');
        Observer.Observe('dec_value_on_page', P.DecCtl.Value());
        CloseObserved(Observer, P);
        Observer.Expect('refused|text', 'Validation error for Field: DecCtl,  Message = ''The value must be greater than or equal to 0. Value: -5.00. (Select Refresh to discard errors)''');
        Observer.Expect('refused|code', 'TestValidation');
        Observer.Expect('dec_value_on_page', '1.00');
        Observer.Expect('close_ok', 'Yes');
        Observer.Expect('stored', 'Txt=orig|Qty=5|Dec=1|Name=n0|Other=o0|Guard=|Letters=');
        Observer.Verify();
    end;

    [Test]
    procedure Close_AfterFailedIntegerConversion()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        P.TxtCtl.SetValue('new');
        asserterror P.QtyCtl.SetValue('abc');
        Observer.ObserveError('refused');
        P.OtherCtl.SetValue('o1');
        Observer.Observe('qty_value_on_page', P.QtyCtl.Value());
        CloseObserved(Observer, P);
        Observer.Expect('refused|text', 'Validation error for Field: QtyCtl,  Message = ''Your entry of ''abc'' is not an acceptable value for ''Qty''. The value "abc" can''t be evaluated into type Integer. (Select Refresh to discard errors)''');
        Observer.Expect('refused|code', 'TestValidation');
        Observer.Expect('qty_value_on_page', '5');
        Observer.Expect('close_ok', 'Yes');
        Observer.Expect('stored', 'Txt=orig|Qty=5|Dec=1|Name=n0|Other=o0|Guard=|Letters=');
        Observer.Verify();
    end;

    [Test]
    procedure Close_AfterFailedDecimalConversion()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        P.TxtCtl.SetValue('new');
        asserterror P.DecCtl.SetValue('x1');
        Observer.ObserveError('refused');
        Observer.Observe('dec_value_on_page', P.DecCtl.Value());
        CloseObserved(Observer, P);
        Observer.Expect('refused|text', 'Validation error for Field: DecCtl,  Message = ''Your entry of ''x1'' is not an acceptable value for ''Dec''. ''x1'' is not a part of a valid decimal expression. (Select Refresh to discard errors)''');
        Observer.Expect('refused|code', 'TestValidation');
        Observer.Expect('dec_value_on_page', '1.00');
        Observer.Expect('close_ok', 'Yes');
        Observer.Expect('stored', 'Txt=orig|Qty=5|Dec=1|Name=n0|Other=o0|Guard=|Letters=');
        Observer.Verify();
    end;

    [Test]
    procedure Close_AfterRefusedOnValidate()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        P.TxtCtl.SetValue('new');
        asserterror P.GuardCtl.SetValue('bad');
        Observer.ObserveError('refused');
        P.OtherCtl.SetValue('o1');
        CloseObserved(Observer, P);
        Observer.Expect('refused|text', 'Validation error for Field: GuardCtl,  Message = ''LT AH guard refused (Select Refresh to discard errors)''');
        Observer.Expect('refused|code', 'TestValidation');
        Observer.Expect('close_ok', 'Yes');
        Observer.Expect('close_error|text', 'LT AH guard refused');
        Observer.Expect('close_error|code', 'ClientValidateField:NSValidateField');
        Observer.Expect('stored', 'Txt=orig|Qty=5|Dec=1|Name=n0|Other=o0|Guard=|Letters=');
        Observer.Verify();
    end;

    [Test]
    procedure Close_AfterRefusedCharAllowed()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        P.TxtCtl.SetValue('new');
        asserterror P.LettersCtl.SetValue('a-b');
        Observer.ObserveError('refused');
        P.OtherCtl.SetValue('o1');
        CloseObserved(Observer, P);
        Observer.Expect('refused|text', 'Validation error for Field: LettersCtl,  Message = ''The character - is not valid in this field. You can specify the following characters: az,AZ,09. (Select Refresh to discard errors)''');
        Observer.Expect('refused|code', 'TestValidation');
        Observer.Expect('close_ok', 'Yes');
        Observer.Expect('stored', 'Txt=orig|Qty=5|Dec=1|Name=n0|Other=o0|Guard=|Letters=');
        Observer.Verify();
    end;

    [Test]
    procedure Close_AfterOnlyRefusedEdit()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        asserterror P.QtyCtl.SetValue(99);
        Observer.ObserveError('refused');
        CloseObserved(Observer, P);
        Observer.Expect('refused|text', 'Validation error for Field: QtyCtl,  Message = ''The value must be less than or equal to 10. Value: 99. (Select Refresh to discard errors)''');
        Observer.Expect('refused|code', 'TestValidation');
        Observer.Expect('close_ok', 'Yes');
        Observer.Expect('stored', 'Txt=orig|Qty=5|Dec=1|Name=n0|Other=o0|Guard=|Letters=');
        Observer.Verify();
    end;

    [Test]
    procedure Close_AfterRefusedThenValidOnSameField()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        asserterror P.QtyCtl.SetValue(99);
        Observer.ObserveError('refused');
        Observer.Observe('count_after_refusal', Format(P.ValidationErrorCount()));
        P.QtyCtl.SetValue(7);
        Observer.Observe('count_after_valid_retry', Format(P.ValidationErrorCount()));
        P.TxtCtl.SetValue('new');
        CloseObserved(Observer, P);
        Observer.Expect('refused|text', 'Validation error for Field: QtyCtl,  Message = ''The value must be less than or equal to 10. Value: 99. (Select Refresh to discard errors)''');
        Observer.Expect('refused|code', 'TestValidation');
        Observer.Expect('count_after_refusal', '1');
        Observer.Expect('count_after_valid_retry', '0');
        Observer.Expect('close_ok', 'Yes');
        Observer.Expect('stored', 'Txt=new|Qty=7|Dec=1|Name=n0|Other=o0|Guard=|Letters=');
        Observer.Verify();
    end;

    [Test]
    procedure Close_AfterTwoRefusalsOnDifferentFields()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        P.TxtCtl.SetValue('new');
        asserterror P.QtyCtl.SetValue(0);
        Observer.ObserveError('refused_qty');
        asserterror P.DecCtl.SetValue(101);
        Observer.ObserveError('refused_dec');
        P.NameCtl.SetValue('n1');
        CloseObserved(Observer, P);
        Observer.Expect('refused_qty|text', 'Validation error for Field: QtyCtl,  Message = ''The value must be greater than or equal to 1. Value: 0. (Select Refresh to discard errors)''');
        Observer.Expect('refused_qty|code', 'TestValidation');
        Observer.Expect('refused_dec|text', 'Validation error for Field: DecCtl,  Message = ''The value must be less than or equal to 100. Value: 101.00. (Select Refresh to discard errors)''');
        Observer.Expect('refused_dec|code', 'TestValidation');
        Observer.Expect('close_ok', 'Yes');
        Observer.Expect('stored', 'Txt=orig|Qty=5|Dec=1|Name=n0|Other=o0|Guard=|Letters=');
        Observer.Verify();
    end;

    [Test]
    procedure GVE_Three_page_count()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        asserterror P.QtyCtl.SetValue(99);
        asserterror P.DecCtl.SetValue(-5);
        asserterror P.LettersCtl.SetValue('a-b');
        Observer.Observe('page_count', Format(P.ValidationErrorCount()));
        Observer.Expect('page_count', '3');
        Observer.Verify();
    end;

    [Test]
    procedure GVE_Three_page_no_index()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        asserterror P.QtyCtl.SetValue(99);
        asserterror P.DecCtl.SetValue(-5);
        asserterror P.LettersCtl.SetValue('a-b');
        Observer.Observe('page_no_index', P.GetValidationError());
        Observer.Expect('page_no_index', 'The value must be less than or equal to 10. Value: 99. (Select Refresh to discard errors)\r\nThe value must be greater than or equal to 0. Value: -5.00. (Select Refresh to discard errors)\r\nThe character - is not valid in this field. You can specify the following characters: az,AZ,09. (Select Refresh to discard errors)');
        Observer.Verify();
    end;

    [Test]
    procedure GVE_Three_page_1()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        asserterror P.QtyCtl.SetValue(99);
        asserterror P.DecCtl.SetValue(-5);
        asserterror P.LettersCtl.SetValue('a-b');
        Observer.Observe('page_1', P.GetValidationError(1));
        Observer.Expect('page_1', 'The value must be less than or equal to 10. Value: 99. (Select Refresh to discard errors)');
        Observer.Verify();
    end;

    [Test]
    procedure GVE_Three_page_2()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        asserterror P.QtyCtl.SetValue(99);
        asserterror P.DecCtl.SetValue(-5);
        asserterror P.LettersCtl.SetValue('a-b');
        Observer.Observe('page_2', P.GetValidationError(2));
        Observer.Expect('page_2', 'The value must be greater than or equal to 0. Value: -5.00. (Select Refresh to discard errors)');
        Observer.Verify();
    end;

    [Test]
    procedure GVE_Three_page_3()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        asserterror P.QtyCtl.SetValue(99);
        asserterror P.DecCtl.SetValue(-5);
        asserterror P.LettersCtl.SetValue('a-b');
        Observer.Observe('page_3', P.GetValidationError(3));
        Observer.Expect('page_3', 'The character - is not valid in this field. You can specify the following characters: az,AZ,09. (Select Refresh to discard errors)');
        Observer.Verify();
    end;

    [Test]
    procedure GVE_Three_qty_count()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        asserterror P.QtyCtl.SetValue(99);
        asserterror P.DecCtl.SetValue(-5);
        asserterror P.LettersCtl.SetValue('a-b');
        Observer.Observe('qty_count', Format(P.QtyCtl.ValidationErrorCount()));
        Observer.Expect('qty_count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure GVE_Three_qty_1()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        asserterror P.QtyCtl.SetValue(99);
        asserterror P.DecCtl.SetValue(-5);
        asserterror P.LettersCtl.SetValue('a-b');
        Observer.Observe('qty_1', P.QtyCtl.GetValidationError(1));
        Observer.Expect('qty_1', 'The value must be less than or equal to 10. Value: 99. (Select Refresh to discard errors)');
        Observer.Verify();
    end;

    [Test]
    procedure GVE_Three_dec_count()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        asserterror P.QtyCtl.SetValue(99);
        asserterror P.DecCtl.SetValue(-5);
        asserterror P.LettersCtl.SetValue('a-b');
        Observer.Observe('dec_count', Format(P.DecCtl.ValidationErrorCount()));
        Observer.Expect('dec_count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure GVE_Three_dec_1()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        asserterror P.QtyCtl.SetValue(99);
        asserterror P.DecCtl.SetValue(-5);
        asserterror P.LettersCtl.SetValue('a-b');
        Observer.Observe('dec_1', P.DecCtl.GetValidationError(1));
        Observer.Expect('dec_1', 'The value must be greater than or equal to 0. Value: -5.00. (Select Refresh to discard errors)');
        Observer.Verify();
    end;

    [Test]
    procedure GVE_Three_letters_1()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        asserterror P.QtyCtl.SetValue(99);
        asserterror P.DecCtl.SetValue(-5);
        asserterror P.LettersCtl.SetValue('a-b');
        Observer.Observe('letters_1', P.LettersCtl.GetValidationError(1));
        Observer.Expect('letters_1', 'The character - is not valid in this field. You can specify the following characters: az,AZ,09. (Select Refresh to discard errors)');
        Observer.Verify();
    end;

    [Test]
    procedure GVE_Three_txt_count()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        asserterror P.QtyCtl.SetValue(99);
        asserterror P.DecCtl.SetValue(-5);
        asserterror P.LettersCtl.SetValue('a-b');
        Observer.Observe('txt_count', Format(P.TxtCtl.ValidationErrorCount()));
        Observer.Expect('txt_count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure GVE_Three_page_4()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        asserterror P.QtyCtl.SetValue(99);
        asserterror P.DecCtl.SetValue(-5);
        asserterror P.LettersCtl.SetValue('a-b');
        asserterror Observer.Observe('page_4', P.GetValidationError(4));
        Observer.ObserveError('page_4_error');
        Observer.Expect('page_4_error|text', 'Index out of bounds.');
        Observer.Expect('page_4_error|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure GVE_TwoOnOne_page_count()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        asserterror P.QtyCtl.SetValue(99);
        asserterror P.QtyCtl.SetValue('abc');
        asserterror P.DecCtl.SetValue(-5);
        Observer.Observe('page_count', Format(P.ValidationErrorCount()));
        Observer.Expect('page_count', '2');
        Observer.Verify();
    end;

    [Test]
    procedure GVE_TwoOnOne_page_no_index()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        asserterror P.QtyCtl.SetValue(99);
        asserterror P.QtyCtl.SetValue('abc');
        asserterror P.DecCtl.SetValue(-5);
        Observer.Observe('page_no_index', P.GetValidationError());
        Observer.Expect('page_no_index', 'Your entry of ''abc'' is not an acceptable value for ''Qty''. The value "abc" can''t be evaluated into type Integer. (Select Refresh to discard errors)\r\nThe value must be greater than or equal to 0. Value: -5.00. (Select Refresh to discard errors)');
        Observer.Verify();
    end;

    [Test]
    procedure GVE_TwoOnOne_page_1()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        asserterror P.QtyCtl.SetValue(99);
        asserterror P.QtyCtl.SetValue('abc');
        asserterror P.DecCtl.SetValue(-5);
        Observer.Observe('page_1', P.GetValidationError(1));
        Observer.Expect('page_1', 'Your entry of ''abc'' is not an acceptable value for ''Qty''. The value "abc" can''t be evaluated into type Integer. (Select Refresh to discard errors)');
        Observer.Verify();
    end;

    [Test]
    procedure GVE_TwoOnOne_page_2()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        asserterror P.QtyCtl.SetValue(99);
        asserterror P.QtyCtl.SetValue('abc');
        asserterror P.DecCtl.SetValue(-5);
        Observer.Observe('page_2', P.GetValidationError(2));
        Observer.Expect('page_2', 'The value must be greater than or equal to 0. Value: -5.00. (Select Refresh to discard errors)');
        Observer.Verify();
    end;

    [Test]
    procedure GVE_TwoOnOne_qty_count()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        asserterror P.QtyCtl.SetValue(99);
        asserterror P.QtyCtl.SetValue('abc');
        asserterror P.DecCtl.SetValue(-5);
        Observer.Observe('qty_count', Format(P.QtyCtl.ValidationErrorCount()));
        Observer.Expect('qty_count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure GVE_TwoOnOne_qty_1()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        asserterror P.QtyCtl.SetValue(99);
        asserterror P.QtyCtl.SetValue('abc');
        asserterror P.DecCtl.SetValue(-5);
        Observer.Observe('qty_1', P.QtyCtl.GetValidationError(1));
        Observer.Expect('qty_1', 'Your entry of ''abc'' is not an acceptable value for ''Qty''. The value "abc" can''t be evaluated into type Integer. (Select Refresh to discard errors)');
        Observer.Verify();
    end;

    [Test]
    procedure GVE_TwoOnOne_dec_count()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        asserterror P.QtyCtl.SetValue(99);
        asserterror P.QtyCtl.SetValue('abc');
        asserterror P.DecCtl.SetValue(-5);
        Observer.Observe('dec_count', Format(P.DecCtl.ValidationErrorCount()));
        Observer.Expect('dec_count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure GVE_TwoOnOne_dec_1()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        asserterror P.QtyCtl.SetValue(99);
        asserterror P.QtyCtl.SetValue('abc');
        asserterror P.DecCtl.SetValue(-5);
        Observer.Observe('dec_1', P.DecCtl.GetValidationError(1));
        Observer.Expect('dec_1', 'The value must be greater than or equal to 0. Value: -5.00. (Select Refresh to discard errors)');
        Observer.Verify();
    end;

    [Test]
    procedure GVE_One_page_count()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        asserterror P.QtyCtl.SetValue(99);
        Observer.Observe('page_count', Format(P.ValidationErrorCount()));
        Observer.Expect('page_count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure GVE_One_page_no_index()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        asserterror P.QtyCtl.SetValue(99);
        Observer.Observe('page_no_index', P.GetValidationError());
        Observer.Expect('page_no_index', 'The value must be less than or equal to 10. Value: 99. (Select Refresh to discard errors)');
        Observer.Verify();
    end;

    [Test]
    procedure GVE_One_page_1()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        asserterror P.QtyCtl.SetValue(99);
        Observer.Observe('page_1', P.GetValidationError(1));
        Observer.Expect('page_1', 'The value must be less than or equal to 10. Value: 99. (Select Refresh to discard errors)');
        Observer.Verify();
    end;

    [Test]
    procedure GVE_One_qty_1()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        asserterror P.QtyCtl.SetValue(99);
        Observer.Observe('qty_1', P.QtyCtl.GetValidationError(1));
        Observer.Expect('qty_1', 'The value must be less than or equal to 10. Value: 99. (Select Refresh to discard errors)');
        Observer.Verify();
    end;

    [Test]
    procedure GVE_Zero_page_count()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        Observer.Observe('page_count', Format(P.ValidationErrorCount()));
        Observer.Expect('page_count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure GVE_Zero_page_no_index()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        Observer.Observe('page_no_index', P.GetValidationError());
        Observer.Expect('page_no_index', '');
        Observer.Verify();
    end;

    [Test]
    procedure GVE_Zero_qty_count()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        Observer.Observe('qty_count', Format(P.QtyCtl.ValidationErrorCount()));
        Observer.Expect('qty_count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure GVE_Zero_qty_no_index()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        Observer.Observe('qty_no_index', P.QtyCtl.GetValidationError());
        Observer.Expect('qty_no_index', '');
        Observer.Verify();
    end;

    [Test]
    procedure GetValidationError_CountAfterCorrections()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH Card";
    begin
        Seed();
        P.OpenEdit();
        asserterror P.QtyCtl.SetValue(99);
        Observer.ObserveError('refused_qty');
        asserterror P.DecCtl.SetValue(-5);
        Observer.ObserveError('refused_dec');
        asserterror P.LettersCtl.SetValue('a-b');
        Observer.ObserveError('refused_letters');
        P.QtyCtl.SetValue(3);
        Observer.Observe('page_count_after_qty_fix', Format(P.ValidationErrorCount()));
        Observer.Observe('qty_count_after_qty_fix', Format(P.QtyCtl.ValidationErrorCount()));
        P.DecCtl.SetValue(3);
        P.LettersCtl.SetValue('abc');
        Observer.Observe('page_count_after_all_fixed', Format(P.ValidationErrorCount()));
        Observer.Expect('refused_qty|text', 'Validation error for Field: QtyCtl,  Message = ''The value must be less than or equal to 10. Value: 99. (Select Refresh to discard errors)''');
        Observer.Expect('refused_qty|code', 'TestValidation');
        Observer.Expect('refused_dec|text', 'Validation error for Field: DecCtl,  Message = ''The value must be greater than or equal to 0. Value: -5.00. (Select Refresh to discard errors)''');
        Observer.Expect('refused_dec|code', 'TestValidation');
        Observer.Expect('refused_letters|text', 'Validation error for Field: LettersCtl,  Message = ''The character - is not valid in this field. You can specify the following characters: az,AZ,09. (Select Refresh to discard errors)''');
        Observer.Expect('refused_letters|code', 'TestValidation');
        Observer.Expect('page_count_after_qty_fix', '2');
        Observer.Expect('qty_count_after_qty_fix', '0');
        Observer.Expect('page_count_after_all_fixed', '0');
        Observer.Verify();
    end;
}

codeunit 78623 "LT AH CharAllowed Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT AH Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 'R1';
        Row.Insert();
        Commit();
    end;

    [TryFunction]
    local procedure SetThree(var P: TestPage "LT AH CharAllowed Card"; Value: Text)
    begin
        P.ThreeRanges.SetValue(Value);
    end;

    [TryFunction]
    local procedure SetSingles(var P: TestPage "LT AH CharAllowed Card"; Value: Text)
    begin
        P.SinglesAndRange.SetValue(Value);
    end;

    [TryFunction]
    local procedure SetUnordered(var P: TestPage "LT AH CharAllowed Card"; Value: Text)
    begin
        P.Unordered.SetValue(Value);
    end;

    [TryFunction]
    local procedure SetNonAscii(var P: TestPage "LT AH CharAllowed Card"; Value: Text)
    begin
        P.NonAscii.SetValue(Value);
    end;

    [TryFunction]
    local procedure SetOneRangeMany(var P: TestPage "LT AH CharAllowed Card"; Value: Text)
    begin
        P.OneRangeMany.SetValue(Value);
    end;

    local procedure Candidates(): Text
    var
        Result: Text;
        C: Text[1];
        I: Integer;
        Extra: List of [Integer];
    begin
        for I := 33 to 126 do begin
            C[1] := I;
            Result += C;
        end;
        Extra.Add(196);
        Extra.Add(214);
        Extra.Add(220);
        Extra.Add(223);
        Extra.Add(228);
        Extra.Add(246);
        Extra.Add(252);
        Extra.Add(1040);
        foreach I in Extra do begin
            C[1] := I;
            Result += C;
        end;
        exit(Result);
    end;

    [Test]
    procedure ThreeRanges_AcceptedCharacters()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH CharAllowed Card";
        All: Text;
        Accepted: Text;
        I: Integer;
    begin
        Seed();
        P.OpenEdit();
        All := Candidates();
        for I := 1 to StrLen(All) do
            if SetThree(P, CopyStr(All, I, 1)) then
                Accepted += CopyStr(All, I, 1);
        Observer.Observe('accepted_single_characters', Accepted);
        Observer.Observe('mixed_ok', Format(SetThree(P, 'aZ9bY8')));
        Observer.Observe('mixed_value', P.ThreeRanges.Value());
        Observer.Observe('mixed_with_dash', Format(SetThree(P, 'aZ9-')));
        Observer.Observe('mixed_with_dash_value', P.ThreeRanges.Value());
        asserterror P.ThreeRanges.SetValue('a b');
        Observer.ObserveError('with_space');
        Observer.Expect('accepted_single_characters', '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz');
        Observer.Expect('mixed_ok', 'Yes');
        Observer.Expect('mixed_value', 'aZ9bY8');
        Observer.Expect('mixed_with_dash', 'No');
        Observer.Expect('mixed_with_dash_value', 'aZ9bY8');
        Observer.Expect('with_space|text', 'Validation error for Field: ThreeRanges,  Message = ''The character   is not valid in this field. You can specify the following characters: az,AZ,09. (Select Refresh to discard errors)''');
        Observer.Expect('with_space|code', 'TestValidation');
        Observer.Verify();
    end;

    [Test]
    procedure SinglesAndRange_AcceptedCharacters()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH CharAllowed Card";
        All: Text;
        Accepted: Text;
        I: Integer;
    begin
        Seed();
        P.OpenEdit();
        All := Candidates();
        for I := 1 to StrLen(All) do
            if SetSingles(P, CopyStr(All, I, 1)) then
                Accepted += CopyStr(All, I, 1);
        Observer.Observe('accepted_single_characters', Accepted);
        Observer.Observe('mixed_ok', Format(SetSingles(P, '12-_34')));
        Observer.Observe('mixed_value', P.SinglesAndRange.Value());
        asserterror P.SinglesAndRange.SetValue('12-_a');
        Observer.ObserveError('with_letter');
        Observer.Expect('accepted_single_characters', '-0123456789_');
        Observer.Expect('mixed_ok', 'Yes');
        Observer.Expect('mixed_value', '12-_34');
        Observer.Expect('with_letter|text', 'Validation error for Field: SinglesAndRange,  Message = ''The character a is not valid in this field. You can specify the following characters: 09,--,__. (Select Refresh to discard errors)''');
        Observer.Expect('with_letter|code', 'TestValidation');
        Observer.Verify();
    end;

    [Test]
    procedure UnorderedSingles_AcceptedCharacters()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH CharAllowed Card";
        All: Text;
        Accepted: Text;
        I: Integer;
    begin
        Seed();
        P.OpenEdit();
        All := Candidates();
        for I := 1 to StrLen(All) do
            if SetUnordered(P, CopyStr(All, I, 1)) then
                Accepted += CopyStr(All, I, 1);
        Observer.Observe('accepted_single_characters', Accepted);
        Observer.Expect('accepted_single_characters', '5az');
        Observer.Verify();
    end;

    [Test]
    procedure NonAsciiSingle_AcceptedCharacters()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH CharAllowed Card";
        All: Text;
        Accepted: Text;
        I: Integer;
    begin
        Seed();
        P.OpenEdit();
        All := Candidates();
        for I := 1 to StrLen(All) do
            if SetNonAscii(P, CopyStr(All, I, 1)) then
                Accepted += CopyStr(All, I, 1);
        Observer.Observe('accepted_single_characters', Accepted);
        Observer.Expect('accepted_single_characters', 'aÄ');
        Observer.Verify();
    end;

    [Test]
    procedure TwoRangesOfLetters_AcceptedCharacters()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT AH CharAllowed Card";
        All: Text;
        Accepted: Text;
        I: Integer;
    begin
        Seed();
        P.OpenEdit();
        All := Candidates();
        for I := 1 to StrLen(All) do
            if SetOneRangeMany(P, CopyStr(All, I, 1)) then
                Accepted += CopyStr(All, I, 1);
        Observer.Observe('accepted_single_characters', Accepted);
        Observer.Expect('accepted_single_characters', '0123456789ABCDEFabcdef');
        Observer.Verify();
    end;
}

codeunit 78621 "LT AH Tree Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Tag: Text;

    local procedure Seed()
    var
        Row: Record "LT AH Row";
    begin
        Row.DeleteAll();
        AddRow('T1', 0);
        AddRow('T2', 1);
        AddRow('T3', 2);
        AddRow('T4', 1);
        AddRow('T5', 0);
        Commit();
    end;

    local procedure AddRow(Id: Code[20]; Level: Integer)
    var
        Row: Record "LT AH Row";
    begin
        Row.Init();
        Row.Id := Id;
        Row.Txt := 'text ' + Id;
        Row.Lvl := Level;
        Row.Insert();
    end;

    local procedure Rows(var P: TestPage "LT AH Tree"): Text
    var
        Result: Text;
    begin
        if P.First() then
            repeat
                Result += P.IdCtl.Value() + ' ';
            until not P.Next();
        exit(Result);
    end;

    local procedure Walk(var P: TestPage "LT AH Tree")
    begin
        Observer.Observe(Tag + '_rows_initial', Rows(P));
        P.First();
        Observer.Observe(Tag + '_first', P.IdCtl.Value());
        Observer.Observe(Tag + '_first_expanded', Format(P.IsExpanded()));
        P.Expand(true);
        Observer.Observe(Tag + '_first_expanded_after_expand', Format(P.IsExpanded()));
        Observer.Observe(Tag + '_rows_after_expand', Rows(P));
        P.GoToKey('T1');
        P.Expand(false);
        Observer.Observe(Tag + '_rows_after_collapse', Rows(P));
        Observer.Observe(Tag + '_goto_child', Format(P.GoToKey('T2')));
        P.GoToKey('T5');
        Observer.Observe(Tag + '_last_root_expanded', Format(P.IsExpanded()));
    end;

    [PageHandler]
    procedure TreeHandler(var P: TestPage "LT AH Tree")
    begin
        Walk(P);
    end;

    [ModalPageHandler]
    procedure TreeModalHandler(var P: TestPage "LT AH Tree")
    begin
        Walk(P);
        P.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('TreeHandler')]
    procedure Tree_ThroughPageRun()
    begin
        Seed();
        Tag := 'page_run';
        Page.Run(Page::"LT AH Tree");
        Observer.Expect('page_run_rows_initial', 'T1 T5 ');
        Observer.Expect('page_run_first', 'T1');
        Observer.Expect('page_run_first_expanded', 'No');
        Observer.Expect('page_run_first_expanded_after_expand', 'Yes');
        Observer.Expect('page_run_rows_after_expand', 'T1 T2 T4 T5 ');
        Observer.Expect('page_run_rows_after_collapse', 'T1 T5 ');
        Observer.Expect('page_run_goto_child', 'No');
        Observer.Expect('page_run_last_root_expanded', 'No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TreeHandler')]
    procedure Tree_ThroughPageVariableRun()
    var
        Pg: Page "LT AH Tree";
    begin
        Seed();
        Tag := 'variable_run';
        Pg.Run();
        Observer.Expect('variable_run_rows_initial', 'T1 T5 ');
        Observer.Expect('variable_run_first', 'T1');
        Observer.Expect('variable_run_first_expanded', 'No');
        Observer.Expect('variable_run_first_expanded_after_expand', 'Yes');
        Observer.Expect('variable_run_rows_after_expand', 'T1 T2 T4 T5 ');
        Observer.Expect('variable_run_rows_after_collapse', 'T1 T5 ');
        Observer.Expect('variable_run_goto_child', 'No');
        Observer.Expect('variable_run_last_root_expanded', 'No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TreeModalHandler')]
    procedure Tree_ThroughPageVariableRunModal()
    var
        Pg: Page "LT AH Tree";
    begin
        Seed();
        Tag := 'variable_runmodal';
        Pg.RunModal();
        Observer.Expect('variable_runmodal_rows_initial', 'T1 T5 ');
        Observer.Expect('variable_runmodal_first', 'T1');
        Observer.Expect('variable_runmodal_first_expanded', 'No');
        Observer.Expect('variable_runmodal_first_expanded_after_expand', 'Yes');
        Observer.Expect('variable_runmodal_rows_after_expand', 'T1 T2 T4 T5 ');
        Observer.Expect('variable_runmodal_rows_after_collapse', 'T1 T5 ');
        Observer.Expect('variable_runmodal_goto_child', 'No');
        Observer.Expect('variable_runmodal_last_root_expanded', 'No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TreeModalHandler')]
    procedure Tree_ThroughPageRunModal()
    begin
        Seed();
        Tag := 'page_runmodal';
        Page.RunModal(Page::"LT AH Tree");
        Observer.Expect('page_runmodal_rows_initial', 'T1 T5 ');
        Observer.Expect('page_runmodal_first', 'T1');
        Observer.Expect('page_runmodal_first_expanded', 'No');
        Observer.Expect('page_runmodal_first_expanded_after_expand', 'Yes');
        Observer.Expect('page_runmodal_rows_after_expand', 'T1 T2 T4 T5 ');
        Observer.Expect('page_runmodal_rows_after_collapse', 'T1 T5 ');
        Observer.Expect('page_runmodal_goto_child', 'No');
        Observer.Expect('page_runmodal_last_root_expanded', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Tree_ThroughTestPageVariable()
    var
        P: TestPage "LT AH Tree";
    begin
        Seed();
        Tag := 'testpage';
        P.OpenView();
        Walk(P);
        P.Close();
        Observer.Expect('testpage_rows_initial', 'T1 T5 ');
        Observer.Expect('testpage_first', 'T1');
        Observer.Expect('testpage_first_expanded', 'No');
        Observer.Expect('testpage_first_expanded_after_expand', 'Yes');
        Observer.Expect('testpage_rows_after_expand', 'T1 T2 T4 T5 ');
        Observer.Expect('testpage_rows_after_collapse', 'T1 T5 ');
        Observer.Expect('testpage_goto_child', 'No');
        Observer.Expect('testpage_last_root_expanded', 'No');
        Observer.Verify();
    end;
}

codeunit 78622 "LT AH Part Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure SeedRows()
    var
        Row: Record "LT AH Row";
    begin
        Row.DeleteAll();
        AddRow('R1', 'a', 1);
        AddRow('R2', 'b', 2);
        AddRow('R3', 'c', 3);
        Commit();
    end;

    local procedure AddRow(Id: Code[20]; Txt: Text[30]; Qty: Integer)
    var
        Row: Record "LT AH Row";
    begin
        Row.Init();
        Row.Id := Id;
        Row.Txt := Txt;
        Row.Qty := Qty;
        Row.Insert();
    end;

    local procedure DumpRows(): Text
    var
        Row: Record "LT AH Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Row.Id + '=' + Row.Txt + '/' + Format(Row.Qty) + ' ';
            until Row.Next() = 0;
        exit(Result);
    end;

    local procedure PartRows(var Host: TestPage "LT AH Host List"): Text
    var
        Result: Text;
    begin
        if Host.SamePart.First() then
            repeat
                Result += Host.SamePart.IdCtl.Value() + '=' + Host.SamePart.TxtCtl.Value() + ' ';
            until not Host.SamePart.Next();
        exit(Result);
    end;

    [Test]
    procedure ListHost_PartEdit_SavedOnHostClose()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT AH Host List";
    begin
        SeedRows();
        Host.OpenEdit();
        Host.GoToKey('R2');
        Observer.Observe('part_rows', PartRows(Host));
        Host.SamePart.TxtCtl.SetValue('viaPart');
        Observer.Observe('part_value_after_edit', Host.SamePart.TxtCtl.Value());
        Observer.Observe('host_value_after_edit', Host.TxtCtl.Value());
        Observer.Observe('db_after_edit', DumpRows());
        Host.Close();
        Observer.Observe('db_after_close', DumpRows());
        Observer.Expect('part_rows', 'R2=b ');
        Observer.Expect('part_value_after_edit', 'viaPart');
        Observer.Expect('host_value_after_edit', 'b');
        Observer.Expect('db_after_edit', 'R1=a/1 R2=b/2 R3=c/3 ');
        Observer.Expect('db_after_close', 'R1=a/1 R2=b/2 R3=c/3 ');
        Observer.Verify();
    end;

    [Test]
    procedure ListHost_PartEdit_ThenHostRowChange()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT AH Host List";
    begin
        SeedRows();
        Host.OpenEdit();
        Host.GoToKey('R2');
        Host.SamePart.TxtCtl.SetValue('viaPart');
        Host.GoToKey('R3');
        Observer.Observe('db_after_row_change', DumpRows());
        Observer.Observe('part_rows_on_r3', PartRows(Host));
        Host.GoToKey('R2');
        Observer.Observe('host_value_back_on_r2', Host.TxtCtl.Value());
        Observer.Observe('part_value_back_on_r2', Host.SamePart.TxtCtl.Value());
        Host.Close();
        Observer.Observe('db_after_close', DumpRows());
        Observer.Expect('db_after_row_change', 'R1=a/1 R2=b/2 R3=c/3 ');
        Observer.Expect('part_rows_on_r3', 'R3=c ');
        Observer.Expect('host_value_back_on_r2', 'b');
        Observer.Expect('part_value_back_on_r2', 'b');
        Observer.Expect('db_after_close', 'R1=a/1 R2=b/2 R3=c/3 ');
        Observer.Verify();
    end;

    [Test]
    procedure ListHost_HostEditThenPartEditOfSameRow()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT AH Host List";
    begin
        SeedRows();
        Host.OpenEdit();
        Host.GoToKey('R2');
        Host.TxtCtl.SetValue('viaHost');
        Observer.Observe('part_value_after_host_edit', Host.SamePart.TxtCtl.Value());
        Host.SamePart.QtyCtl.SetValue(7);
        Observer.Observe('host_qty_after_part_edit', Host.QtyCtl.Value());
        Observer.Observe('host_txt_after_part_edit', Host.TxtCtl.Value());
        Host.Close();
        Observer.Observe('db_after_close', DumpRows());
        Observer.Expect('part_value_after_host_edit', 'b');
        Observer.Expect('host_qty_after_part_edit', '2');
        Observer.Expect('host_txt_after_part_edit', 'viaHost');
        Observer.Expect('db_after_close', 'R1=a/1 R2=viaHost/2 R3=c/3 ');
        Observer.Verify();
    end;

    [Test]
    procedure ListHost_PartEditRefused()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT AH Host List";
    begin
        SeedRows();
        Host.OpenEdit();
        Host.GoToKey('R2');
        Host.TxtCtl.SetValue('viaHost');
        asserterror Host.SamePart.QtyCtl.SetValue(99);
        Observer.ObserveError('part_refused');
        Observer.Observe('host_error_count', Format(Host.ValidationErrorCount()));
        Observer.Observe('part_error_count', Format(Host.SamePart.ValidationErrorCount()));
        Host.Close();
        Observer.Observe('db_after_close', DumpRows());
        Observer.Expect('part_refused|text', 'Validation error for Field: QtyCtl,  Message = ''The value must be less than or equal to 10. Value: 99.''');
        Observer.Expect('part_refused|code', 'TestValidation');
        Observer.Expect('host_error_count', '1');
        Observer.Expect('part_error_count', '1');
        Observer.Expect('db_after_close', 'R1=a/1 R2=b/2 R3=c/3 ');
        Observer.Verify();
    end;

    local procedure SeedDocument()
    var
        Head: Record "LT AH Head";
        Line: Record "LT AH Line";
    begin
        Line.DeleteAll();
        Head.DeleteAll();
        Head.Init();
        Head.Id := 'H1';
        Head.Descr := 'head';
        Head.Insert();
        AddLine(10, 'first', 1);
        AddLine(20, 'second', 2);
        Head.Id := 'H2';
        Head.Descr := 'other head';
        Head.Insert();
        Line.Init();
        Line.HeadId := 'H2';
        Line.LineNo := 10;
        Line.Descr := 'foreign';
        Line.Insert();
        Commit();
    end;

    local procedure AddLine(LineNo: Integer; Descr: Text[30]; Amount: Decimal)
    var
        Line: Record "LT AH Line";
    begin
        Line.Init();
        Line.HeadId := 'H1';
        Line.LineNo := LineNo;
        Line.Descr := Descr;
        Line.Amount := Amount;
        Line.Insert();
    end;

    local procedure DumpHeadsAndLines(): Text
    var
        Head: Record "LT AH Head";
        Line: Record "LT AH Line";
        Result: Text;
    begin
        if Head.FindSet() then
            repeat
                Result += 'H:' + Head.Id + '=' + Head.Descr + ' ';
            until Head.Next() = 0;
        if Line.FindSet() then
            repeat
                Result += 'L:' + Line.HeadId + '/' + Format(Line.LineNo) + '=' + Line.Descr + '/' + Format(Line.Amount) + ' ';
            until Line.Next() = 0;
        exit(Result);
    end;

    local procedure LinesOf(var Doc: TestPage "LT AH Document"): Text
    var
        Result: Text;
    begin
        if Doc.Lines.First() then
            repeat
                Result += Doc.Lines.LineNoCtl.Value() + '=' + Doc.Lines.DescrCtl.Value() + ' ';
            until not Doc.Lines.Next();
        exit(Result);
    end;

    [Test]
    procedure DocumentHost_PartEditExistingLine()
    var
        Observer: Codeunit "Probe Observer";
        Doc: TestPage "LT AH Document";
    begin
        SeedDocument();
        Doc.OpenEdit();
        Doc.GoToKey('H1');
        Observer.Observe('lines', LinesOf(Doc));
        Doc.Lines.GoToKey('H1', 10);
        Doc.Lines.DescrCtl.SetValue('edited');
        Observer.Observe('db_after_edit', DumpHeadsAndLines());
        Doc.Close();
        Observer.Observe('db_after_close', DumpHeadsAndLines());
        Observer.Expect('lines', '10=first 20=second 0= ');
        Observer.Expect('db_after_edit', 'H:H1=head H:H2=other head L:H1/10=first/1 L:H1/20=second/2 L:H2/10=foreign/0 ');
        Observer.Expect('db_after_close', 'H:H1=head H:H2=other head L:H1/10=edited/1 L:H1/20=second/2 L:H2/10=foreign/0 ');
        Observer.Verify();
    end;

    [Test]
    procedure DocumentHost_PartNewLine()
    var
        Observer: Codeunit "Probe Observer";
        Doc: TestPage "LT AH Document";
    begin
        SeedDocument();
        Doc.OpenEdit();
        Doc.GoToKey('H1');
        Doc.Lines.New();
        Doc.Lines.DescrCtl.SetValue('added');
        Doc.Lines.AmountCtl.SetValue(5);
        Observer.Observe('new_line_no', Doc.Lines.LineNoCtl.Value());
        Observer.Observe('db_after_new', DumpHeadsAndLines());
        Doc.Close();
        Observer.Observe('db_after_close', DumpHeadsAndLines());
        Observer.Expect('new_line_no', '15');
        Observer.Expect('db_after_new', 'H:H1=head H:H2=other head L:H1/10=first/1 L:H1/15=added/0 L:H1/20=second/2 L:H2/10=foreign/0 ');
        Observer.Expect('db_after_close', 'H:H1=head H:H2=other head L:H1/10=first/1 L:H1/15=added/5 L:H1/20=second/2 L:H2/10=foreign/0 ');
        Observer.Verify();
    end;

    [Test]
    procedure DocumentHost_HeaderEditAndPartEdit()
    var
        Observer: Codeunit "Probe Observer";
        Doc: TestPage "LT AH Document";
    begin
        SeedDocument();
        Doc.OpenEdit();
        Doc.GoToKey('H1');
        Doc.DescrCtl.SetValue('head edited');
        Doc.Lines.GoToKey('H1', 20);
        Doc.Lines.AmountCtl.SetValue(22);
        Doc.Lines.GoToKey('H1', 10);
        Observer.Observe('db_after_row_change', DumpHeadsAndLines());
        Doc.Close();
        Observer.Observe('db_after_close', DumpHeadsAndLines());
        Observer.Expect('db_after_row_change', 'H:H1=head edited H:H2=other head L:H1/10=first/1 L:H1/20=second/22 L:H2/10=foreign/0 ');
        Observer.Expect('db_after_close', 'H:H1=head edited H:H2=other head L:H1/10=first/1 L:H1/20=second/22 L:H2/10=foreign/0 ');
        Observer.Verify();
    end;

    [Test]
    procedure DocumentHost_PartEditRefused_ThenClose()
    var
        Observer: Codeunit "Probe Observer";
        Doc: TestPage "LT AH Document";
    begin
        SeedDocument();
        Doc.OpenEdit();
        Doc.GoToKey('H1');
        Doc.DescrCtl.SetValue('head edited');
        Doc.Lines.GoToKey('H1', 20);
        Doc.Lines.DescrCtl.SetValue('part edited');
        asserterror Doc.Lines.AmountCtl.SetValue('abc');
        Observer.ObserveError('part_refused');
        Observer.Observe('host_error_count', Format(Doc.ValidationErrorCount()));
        Observer.Observe('part_error_count', Format(Doc.Lines.ValidationErrorCount()));
        Doc.Close();
        Observer.Observe('db_after_close', DumpHeadsAndLines());
        Observer.Expect('part_refused|text', 'Validation error for Field: AmountCtl,  Message = ''Your entry of ''abc'' is not an acceptable value for ''Amount''. ''abc'' is not a part of a valid decimal expression.''');
        Observer.Expect('part_refused|code', 'TestValidation');
        Observer.Expect('host_error_count', '1');
        Observer.Expect('part_error_count', '1');
        Observer.Expect('db_after_close', 'H:H1=head H:H2=other head L:H1/10=first/1 L:H1/20=second/2 L:H2/10=foreign/0 ');
        Observer.Verify();
    end;
}
