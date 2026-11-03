// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-fielderror-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained table 74852 and codeunit 74853
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: GetLastErrorText(true) (ExcludeCustomerContent) against GetLastErrorText(false) and GetLastErrorCode for FieldError(Field, TextVariable), FieldError(Field, CodeVariable), FieldError(Field, TextVariable with %1) on a filled field, and for FieldError(Field) and FieldError(Field, TextVariable) on a blank field of each type (the "You must specify" form of the text is pinned in record/lt-testfield-fielderror-typed/P96FieldError.al without the flag). The literal and Label forms are pinned in types/lt-evaluate-format-lasterror-setview/P86LastError.al and error-handling/lt-last-error-text-exclude/.
// BC versions: 29 (27 and 28 by CI)

table 74852 "LT FET Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
        field(4; Dt; Date) { }
        field(5; Amount; Decimal) { }
        field(6; Flag; Boolean) { }
    }

    keys { key(PK; Code) { Clustered = true; } }
}

codeunit 74853 "LT FET FieldError Text"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Forms(Name: Text; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe(Name + '_true', GetLastErrorText(true));
        Observer.Observe(Name + '_false', GetLastErrorText(false));
        Observer.Observe(Name + '_code', GetLastErrorCode());
        ClearLastError();
    end;

    [Test]
    procedure FieldErrorTextVariable_FilledField_ExcludeFlag()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT FET Row";
        Msg: Text;
        CodeVal: Code[20];
    begin
        Row.Code := 'FE1';
        Row.Name := 'Actual';
        Row.Qty := 5;
        Msg := 'text variable message';
        asserterror Row.FieldError(Name, Msg);
        Forms('textvar', Observer);
        Msg := 'percent %1 stays';
        asserterror Row.FieldError(Name, Msg);
        Forms('textvar_percent', Observer);
        asserterror Row.FieldError(Qty, Msg);
        Forms('textvar_int', Observer);
        CodeVal := 'CODEMSG';
        asserterror Row.FieldError(Name, CodeVal);
        Forms('codevar', Observer);
        Msg := '';
        asserterror Row.FieldError(Name, Msg);
        Forms('textvar_empty', Observer);
        asserterror Row.FieldError(Name, 'literal ' + Row.Name);
        Forms('concat', Observer);
        Observer.Expect('textvar_true', 'FieldError on field LT FET Row.Name, message: Use FIELDERROR with a text constant to improve Telemetry details.');
        Observer.Expect('textvar_false', 'Name text variable message in LT FET Row Code=''FE1''.');
        Observer.Expect('textvar_code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('textvar_percent_true', 'FieldError on field LT FET Row.Name, message: Use FIELDERROR with a text constant to improve Telemetry details.');
        Observer.Expect('textvar_percent_false', 'Name percent %1 stays in LT FET Row Code=''FE1''.');
        Observer.Expect('textvar_percent_code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('textvar_int_true', 'FieldError on field LT FET Row.Qty, message: Use FIELDERROR with a text constant to improve Telemetry details.');
        Observer.Expect('textvar_int_false', 'Qty percent %1 stays in LT FET Row Code=''FE1''.');
        Observer.Expect('textvar_int_code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('codevar_true', 'FieldError on field LT FET Row.Name, message: Use FIELDERROR with a text constant to improve Telemetry details.');
        Observer.Expect('codevar_false', 'Name CODEMSG in LT FET Row Code=''FE1''.');
        Observer.Expect('codevar_code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('textvar_empty_true', 'FieldError for incorrect value of LT FET Row.Name');
        Observer.Expect('textvar_empty_false', 'Name must not be Actual in LT FET Row Code=''FE1''.');
        Observer.Expect('textvar_empty_code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('concat_true', 'FieldError on field LT FET Row.Name, message: Use FIELDERROR with a text constant to improve Telemetry details.');
        Observer.Expect('concat_false', 'Name literal Actual in LT FET Row Code=''FE1''.');
        Observer.Expect('concat_code', 'NCLCSRTS:TableErrorStr');
        Observer.Verify();
    end;

    [Test]
    procedure FieldErrorBlank_NoMessage_ExcludeFlag()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT FET Row";
    begin
        Row.Code := 'FE2';
        asserterror Row.FieldError(Name);
        Forms('blank_text', Observer);
        asserterror Row.FieldError(Qty);
        Forms('blank_int', Observer);
        asserterror Row.FieldError(Dt);
        Forms('blank_date', Observer);
        asserterror Row.FieldError(Amount);
        Forms('blank_decimal', Observer);
        asserterror Row.FieldError(Flag);
        Forms('blank_boolean', Observer);
        Row.Code := '';
        asserterror Row.FieldError(Code);
        Forms('blank_code', Observer);
        Observer.Expect('blank_text_true', 'FieldError for unspecified value of LT FET Row.Name');
        Observer.Expect('blank_text_false', 'You must specify Name in LT FET Row Code=''FE2''.');
        Observer.Expect('blank_text_code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('blank_int_true', 'FieldError for incorrect value of LT FET Row.Qty');
        Observer.Expect('blank_int_false', 'Qty must not be 0 in LT FET Row Code=''FE2''.');
        Observer.Expect('blank_int_code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('blank_date_true', 'FieldError for unspecified value of LT FET Row.Dt');
        Observer.Expect('blank_date_false', 'You must specify Dt in LT FET Row Code=''FE2''.');
        Observer.Expect('blank_date_code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('blank_decimal_true', 'FieldError for incorrect value of LT FET Row.Amount');
        Observer.Expect('blank_decimal_false', 'Amount must not be 0 in LT FET Row Code=''FE2''.');
        Observer.Expect('blank_decimal_code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('blank_boolean_true', 'FieldError for incorrect value of LT FET Row.Flag');
        Observer.Expect('blank_boolean_false', 'Flag must not be No in LT FET Row Code=''FE2''.');
        Observer.Expect('blank_boolean_code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('blank_code_true', 'FieldError for unspecified value of LT FET Row.Code');
        Observer.Expect('blank_code_false', 'You must specify Code in LT FET Row Code=''''.');
        Observer.Expect('blank_code_code', 'NCLCSRTS:TableErrorStr');
        Observer.Verify();
    end;

    [Test]
    procedure FieldErrorBlank_TextVariable_ExcludeFlag()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT FET Row";
        Msg: Text;
    begin
        Row.Code := 'FE3';
        Msg := 'must be filled in by the clerk';
        asserterror Row.FieldError(Name, Msg);
        Forms('blank_text_var', Observer);
        asserterror Row.FieldError(Qty, Msg);
        Forms('blank_int_var', Observer);
        asserterror Row.FieldError(Dt, Msg);
        Forms('blank_date_var', Observer);
        Observer.Expect('blank_text_var_true', 'FieldError on field LT FET Row.Name, message: Use FIELDERROR with a text constant to improve Telemetry details.');
        Observer.Expect('blank_text_var_false', 'Name must be filled in by the clerk in LT FET Row Code=''FE3''.');
        Observer.Expect('blank_text_var_code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('blank_int_var_true', 'FieldError on field LT FET Row.Qty, message: Use FIELDERROR with a text constant to improve Telemetry details.');
        Observer.Expect('blank_int_var_false', 'Qty must be filled in by the clerk in LT FET Row Code=''FE3''.');
        Observer.Expect('blank_int_var_code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('blank_date_var_true', 'FieldError on field LT FET Row.Dt, message: Use FIELDERROR with a text constant to improve Telemetry details.');
        Observer.Expect('blank_date_var_false', 'Dt must be filled in by the clerk in LT FET Row Code=''FE3''.');
        Observer.Expect('blank_date_var_code', 'NCLCSRTS:TableErrorStr');
        Observer.Verify();
    end;
}
