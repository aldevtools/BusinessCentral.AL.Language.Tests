// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/getlasterrortext-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table 72065 (P70_01Table.al)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: GetLastErrorText(true/false/default) and GetLastErrorCode for runtime errors that carry a value (duplicate insert, modify missing, TestField, FieldError, Evaluate, overflow, Error with argument)
// BC versions: 29 (27 and 28 by CI)

codeunit 72067 "LT P70 LastErr Flag Rt"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Forms(Name: Text; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe(Name + '|true', GetLastErrorText(true));
        Observer.Observe(Name + '|false', GetLastErrorText(false));
        Observer.Observe(Name + '|default', GetLastErrorText());
        Observer.Observe(Name + '|code', GetLastErrorCode());
        ClearLastError();
    end;

    local procedure DupInsert()
    var
        Row: Record "LT P70 Row";
    begin
        Row.Code := 'DUP';
        Row.Name := 'first';
        Row.Insert();
        Row.Insert();
    end;

    local procedure ModifyMissing()
    var
        Row: Record "LT P70 Row";
    begin
        Row.Code := 'NOPE';
        Row.Modify();
    end;

    local procedure DeleteMissing()
    var
        Row: Record "LT P70 Row";
    begin
        Row.Code := 'NOPE';
        Row.Delete(true);
    end;

    local procedure GetMissingText()
    var
        Row: Record "LT P70 Row";
    begin
        Row.Get('NOPE');
    end;

    [Test]
    procedure Flag_ModifyDeleteGetMissing()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P70 Row";
    begin
        Row.DeleteAll();
        asserterror ModifyMissing();
        Observer.ObserveError('modify');
        asserterror ModifyMissing();
        Forms('modify', Observer);
        asserterror DeleteMissing();
        Observer.ObserveError('delete');
        asserterror DeleteMissing();
        Forms('delete', Observer);
        asserterror GetMissingText();
        Observer.ObserveError('get');
        asserterror GetMissingText();
        Forms('get', Observer);
        Observer.Expect('modify|text', 'The LT P70 Row does not exist. Identification fields and values: Code=''NOPE''');
        Observer.Expect('modify|code', 'DB:RecordNotFound');
        Observer.Expect('modify|true', 'The LT P70 Row does not exist. Identification fields and values: <redacted>');
        Observer.Expect('modify|false', 'The LT P70 Row does not exist. Identification fields and values: Code=''NOPE''');
        Observer.Expect('modify|default', 'The LT P70 Row does not exist. Identification fields and values: Code=''NOPE''');
        Observer.Expect('modify|code', 'DB:RecordNotFound');
        Observer.Expect('delete|text', 'The LT P70 Row does not exist. Identification fields and values: Code=''NOPE''');
        Observer.Expect('delete|code', 'DB:RecordNotFound');
        Observer.Expect('delete|true', 'The LT P70 Row does not exist. Identification fields and values: <redacted>');
        Observer.Expect('delete|false', 'The LT P70 Row does not exist. Identification fields and values: Code=''NOPE''');
        Observer.Expect('delete|default', 'The LT P70 Row does not exist. Identification fields and values: Code=''NOPE''');
        Observer.Expect('delete|code', 'DB:RecordNotFound');
        Observer.Expect('get|text', 'The LT P70 Row does not exist. Identification fields and values: Code=''NOPE''');
        Observer.Expect('get|code', 'DB:RecordNotFound');
        Observer.Expect('get|true', 'The LT P70 Row does not exist. Identification fields and values: <redacted>');
        Observer.Expect('get|false', 'The LT P70 Row does not exist. Identification fields and values: Code=''NOPE''');
        Observer.Expect('get|default', 'The LT P70 Row does not exist. Identification fields and values: Code=''NOPE''');
        Observer.Expect('get|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Flag_TestFieldForms()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P70 Row";
    begin
        Row.DeleteAll();
        Row.Code := 'TF';
        Row.Name := 'Actual';
        Row.Qty := 5;
        asserterror Row.TestField(Descr);
        Observer.ObserveError('tf_blank_text');
        asserterror Row.TestField(Descr);
        Forms('tf_blank_text', Observer);
        asserterror Row.TestField(Qty, 7);
        Observer.ObserveError('tf_value_int');
        asserterror Row.TestField(Qty, 7);
        Forms('tf_value_int', Observer);
        asserterror Row.TestField(Name, 'Expected');
        Observer.ObserveError('tf_value_text');
        asserterror Row.TestField(Name, 'Expected');
        Forms('tf_value_text', Observer);
        asserterror Row.TestField(Amount);
        Observer.ObserveError('tf_blank_dec');
        asserterror Row.TestField(Amount);
        Forms('tf_blank_dec', Observer);
        Observer.Expect('tf_blank_text|text', 'Descr must have a value in LT P70 Row: Code=TF. It cannot be zero or empty.');
        Observer.Expect('tf_blank_text|code', 'TestField');
        Observer.Expect('tf_blank_text|true', 'Descr must have a value in LT P70 Row: <redacted>. It cannot be zero or empty.');
        Observer.Expect('tf_blank_text|false', 'Descr must have a value in LT P70 Row: Code=TF. It cannot be zero or empty.');
        Observer.Expect('tf_blank_text|default', 'Descr must have a value in LT P70 Row: Code=TF. It cannot be zero or empty.');
        Observer.Expect('tf_blank_text|code', 'TestField');
        Observer.Expect('tf_value_int|text', 'Qty must be equal to ''7''  in LT P70 Row: Code=TF. Current value is ''5''.');
        Observer.Expect('tf_value_int|code', 'TestField');
        Observer.Expect('tf_value_int|true', 'Qty must be equal to ''<redacted>''  in LT P70 Row: <redacted>. Current value is ''<redacted>''.');
        Observer.Expect('tf_value_int|false', 'Qty must be equal to ''7''  in LT P70 Row: Code=TF. Current value is ''5''.');
        Observer.Expect('tf_value_int|default', 'Qty must be equal to ''7''  in LT P70 Row: Code=TF. Current value is ''5''.');
        Observer.Expect('tf_value_int|code', 'TestField');
        Observer.Expect('tf_value_text|text', 'Name must be equal to ''Expected''  in LT P70 Row: Code=TF. Current value is ''Actual''.');
        Observer.Expect('tf_value_text|code', 'TestField');
        Observer.Expect('tf_value_text|true', 'Name must be equal to ''<redacted>''  in LT P70 Row: <redacted>. Current value is ''<redacted>''.');
        Observer.Expect('tf_value_text|false', 'Name must be equal to ''Expected''  in LT P70 Row: Code=TF. Current value is ''Actual''.');
        Observer.Expect('tf_value_text|default', 'Name must be equal to ''Expected''  in LT P70 Row: Code=TF. Current value is ''Actual''.');
        Observer.Expect('tf_value_text|code', 'TestField');
        Observer.Expect('tf_blank_dec|text', 'Amount must have a value in LT P70 Row: Code=TF. It cannot be zero or empty.');
        Observer.Expect('tf_blank_dec|code', 'TestField');
        Observer.Expect('tf_blank_dec|true', 'Amount must have a value in LT P70 Row: <redacted>. It cannot be zero or empty.');
        Observer.Expect('tf_blank_dec|false', 'Amount must have a value in LT P70 Row: Code=TF. It cannot be zero or empty.');
        Observer.Expect('tf_blank_dec|default', 'Amount must have a value in LT P70 Row: Code=TF. It cannot be zero or empty.');
        Observer.Expect('tf_blank_dec|code', 'TestField');
        Observer.Verify();
    end;





    [Test]
    procedure Flag_FieldErrorForms()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P70 Row";
    begin
        Row.Code := 'FE';
        Row.Name := 'Actual';
        Row.Qty := 5;
        asserterror Row.FieldError(Name);
        Observer.ObserveError('fe_plain');
        asserterror Row.FieldError(Name);
        Forms('fe_plain', Observer);
        asserterror Row.FieldError(Name, 'custom text');
        Observer.ObserveError('fe_text');
        asserterror Row.FieldError(Name, 'custom text');
        Forms('fe_text', Observer);
        asserterror Row.FieldError(Qty);
        Observer.ObserveError('fe_int');
        asserterror Row.FieldError(Qty);
        Forms('fe_int', Observer);
        Observer.Expect('fe_plain|text', 'Name must not be Actual in LT P70 Row Code=''FE''.');
        Observer.Expect('fe_plain|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('fe_plain|true', 'FieldError for incorrect value of LT P70 Row.Name');
        Observer.Expect('fe_plain|false', 'Name must not be Actual in LT P70 Row Code=''FE''.');
        Observer.Expect('fe_plain|default', 'Name must not be Actual in LT P70 Row Code=''FE''.');
        Observer.Expect('fe_plain|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('fe_text|text', 'Name custom text in LT P70 Row Code=''FE''.');
        Observer.Expect('fe_text|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('fe_text|true', 'FieldError on field LT P70 Row.Name, message: Use FIELDERROR with a text constant to improve Telemetry details.');
        Observer.Expect('fe_text|false', 'Name custom text in LT P70 Row Code=''FE''.');
        Observer.Expect('fe_text|default', 'Name custom text in LT P70 Row Code=''FE''.');
        Observer.Expect('fe_text|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('fe_int|text', 'Qty must not be 5 in LT P70 Row Code=''FE''.');
        Observer.Expect('fe_int|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('fe_int|true', 'FieldError for incorrect value of LT P70 Row.Qty');
        Observer.Expect('fe_int|false', 'Qty must not be 5 in LT P70 Row Code=''FE''.');
        Observer.Expect('fe_int|default', 'Qty must not be 5 in LT P70 Row Code=''FE''.');
        Observer.Expect('fe_int|code', 'NCLCSRTS:TableErrorStr');
        Observer.Verify();
    end;

    [Test]
    procedure Flag_ErrorWithCustomerArgs()
    var
        Observer: Codeunit "Probe Observer";
        Cust: Text;
        Num: Integer;
    begin
        Cust := 'Contoso Ltd';
        Num := 42;
        asserterror Error('Customer %1', Cust);
        Observer.ObserveError('arg_text');
        asserterror Error('Customer %1', Cust);
        Forms('arg_text', Observer);
        asserterror Error('Customer %1 qty %2', Cust, Num);
        Observer.ObserveError('arg_two');
        asserterror Error('Customer %1 qty %2', Cust, Num);
        Forms('arg_two', Observer);
        asserterror Error('Customer ' + Cust);
        Observer.ObserveError('concat');
        asserterror Error('Customer ' + Cust);
        Forms('concat', Observer);
        asserterror Error('Only literal');
        Observer.ObserveError('literal');
        asserterror Error('Only literal');
        Forms('literal', Observer);
        asserterror Error('Value %1', '');
        Observer.ObserveError('arg_empty');
        asserterror Error('Value %1', '');
        Forms('arg_empty', Observer);
        asserterror Error('Num %1', Num);
        Observer.ObserveError('arg_int');
        asserterror Error('Num %1', Num);
        Forms('arg_int', Observer);
        Observer.Expect('arg_text|text', 'Customer Contoso Ltd');
        Observer.Expect('arg_text|code', 'Dialog');
        Observer.Expect('arg_text|true', 'Use ERROR with a text constant to improve telemetry details');
        Observer.Expect('arg_text|false', 'Customer Contoso Ltd');
        Observer.Expect('arg_text|default', 'Customer Contoso Ltd');
        Observer.Expect('arg_text|code', 'Dialog');
        Observer.Expect('arg_two|text', 'Customer Contoso Ltd qty 42');
        Observer.Expect('arg_two|code', 'Dialog');
        Observer.Expect('arg_two|true', 'Use ERROR with a text constant to improve telemetry details');
        Observer.Expect('arg_two|false', 'Customer Contoso Ltd qty 42');
        Observer.Expect('arg_two|default', 'Customer Contoso Ltd qty 42');
        Observer.Expect('arg_two|code', 'Dialog');
        Observer.Expect('concat|text', 'Customer Contoso Ltd');
        Observer.Expect('concat|code', 'Dialog');
        Observer.Expect('concat|true', 'Use ERROR with a text constant to improve telemetry details');
        Observer.Expect('concat|false', 'Customer Contoso Ltd');
        Observer.Expect('concat|default', 'Customer Contoso Ltd');
        Observer.Expect('concat|code', 'Dialog');
        Observer.Expect('literal|text', 'Only literal');
        Observer.Expect('literal|code', 'Dialog');
        Observer.Expect('literal|true', 'Use ERROR with a text constant to improve telemetry details');
        Observer.Expect('literal|false', 'Only literal');
        Observer.Expect('literal|default', 'Only literal');
        Observer.Expect('literal|code', 'Dialog');
        Observer.Expect('arg_empty|text', 'Value ');
        Observer.Expect('arg_empty|code', 'Dialog');
        Observer.Expect('arg_empty|true', 'Use ERROR with a text constant to improve telemetry details');
        Observer.Expect('arg_empty|false', 'Value ');
        Observer.Expect('arg_empty|default', 'Value ');
        Observer.Expect('arg_empty|code', 'Dialog');
        Observer.Expect('arg_int|text', 'Num 42');
        Observer.Expect('arg_int|code', 'Dialog');
        Observer.Expect('arg_int|true', 'Use ERROR with a text constant to improve telemetry details');
        Observer.Expect('arg_int|false', 'Num 42');
        Observer.Expect('arg_int|default', 'Num 42');
        Observer.Expect('arg_int|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Flag_EvaluateAndOverflow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P70 Row";
        Num: Integer;
        Dt: Date;
        Short: Text[5];
        Big: Text;
    begin
        asserterror Evaluate(Num, 'abc');
        Observer.ObserveError('eval_int');
        asserterror Evaluate(Num, 'abc');
        Forms('eval_int', Observer);
        Num := 0;
        Big := 'Secret999';
        asserterror Evaluate(Num, Big);
        Observer.ObserveError('eval_int_var');
        asserterror Evaluate(Num, Big);
        Forms('eval_int_var', Observer);
        asserterror Evaluate(Dt, 'notadate');
        Observer.ObserveError('eval_date');
        asserterror Evaluate(Dt, 'notadate');
        Forms('eval_date', Observer);
        asserterror Row.Name := 'This text is much too long';
        Observer.ObserveError('overflow_field');
        asserterror Row.Name := 'This text is much too long';
        Forms('overflow_field', Observer);
        asserterror Short := Big;
        Observer.ObserveError('overflow_var');
        asserterror Short := Big;
        Forms('overflow_var', Observer);
        Observer.Expect('eval_int|text', 'The value "abc" can''t be evaluated into type Integer.');
        Observer.Expect('eval_int|code', 'Evaluate');
        Observer.Expect('eval_int|true', 'The value "<redacted>" can''t be evaluated into type Integer.');
        Observer.Expect('eval_int|false', 'The value "abc" can''t be evaluated into type Integer.');
        Observer.Expect('eval_int|default', 'The value "abc" can''t be evaluated into type Integer.');
        Observer.Expect('eval_int|code', 'Evaluate');
        Observer.Expect('eval_int_var|text', 'The value "Secret999" can''t be evaluated into type Integer.');
        Observer.Expect('eval_int_var|code', 'Evaluate');
        Observer.Expect('eval_int_var|true', 'The value "<redacted>" can''t be evaluated into type Integer.');
        Observer.Expect('eval_int_var|false', 'The value "Secret999" can''t be evaluated into type Integer.');
        Observer.Expect('eval_int_var|default', 'The value "Secret999" can''t be evaluated into type Integer.');
        Observer.Expect('eval_int_var|code', 'Evaluate');
        Observer.Expect('eval_date|text', 'The format of the Date ''notadate'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('eval_date|code', 'Evaluate');
        Observer.Expect('eval_date|true', 'The format of the Date ''<redacted>'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('eval_date|false', 'The format of the Date ''notadate'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('eval_date|default', 'The format of the Date ''notadate'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('eval_date|code', 'Evaluate');
        Observer.Expect('overflow_field|text', 'The length of the string is 26, but it must be less than or equal to 10 characters. Value: This text is much too long');
        Observer.Expect('overflow_field|code', 'StringLengthExceeded');
        Observer.Expect('overflow_field|true', 'The length of the string is 26, but it must be less than or equal to 10 characters. Value: <redacted>');
        Observer.Expect('overflow_field|false', 'The length of the string is 26, but it must be less than or equal to 10 characters. Value: This text is much too long');
        Observer.Expect('overflow_field|default', 'The length of the string is 26, but it must be less than or equal to 10 characters. Value: This text is much too long');
        Observer.Expect('overflow_field|code', 'StringLengthExceeded');
        Observer.Expect('overflow_var|text', 'The length of the string is 9, but it must be less than or equal to 5 characters. Value: Secret999');
        Observer.Expect('overflow_var|code', 'StringLengthExceeded');
        Observer.Expect('overflow_var|true', 'The length of the string is 9, but it must be less than or equal to 5 characters. Value: <redacted>');
        Observer.Expect('overflow_var|false', 'The length of the string is 9, but it must be less than or equal to 5 characters. Value: Secret999');
        Observer.Expect('overflow_var|default', 'The length of the string is 9, but it must be less than or equal to 5 characters. Value: Secret999');
        Observer.Expect('overflow_var|code', 'StringLengthExceeded');
        Observer.Verify();
    end;





    [Test]
    procedure Flag_AfterClearAndSequence()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Error('Customer %1', 'First');
        Observer.Observe('before_clear_true', GetLastErrorText(true));
        ClearLastError();
        Observer.Observe('after_clear_true', GetLastErrorText(true));
        Observer.Observe('after_clear_false', GetLastErrorText(false));
        asserterror Error('Customer %1', 'Second');
        Observer.Observe('second_true', GetLastErrorText(true));
        Observer.Observe('first_read_false', GetLastErrorText(false));
        Observer.Observe('second_true_again', GetLastErrorText(true));
        Observer.Observe('second_default', GetLastErrorText());
        Observer.Expect('before_clear_true', 'Use ERROR with a text constant to improve telemetry details');
        Observer.Expect('after_clear_true', '');
        Observer.Expect('after_clear_false', '');
        Observer.Expect('second_true', 'Use ERROR with a text constant to improve telemetry details');
        Observer.Expect('first_read_false', 'Customer Second');
        Observer.Expect('second_true_again', 'Use ERROR with a text constant to improve telemetry details');
        Observer.Expect('second_default', 'Customer Second');
        Observer.Verify();
    end;
}
