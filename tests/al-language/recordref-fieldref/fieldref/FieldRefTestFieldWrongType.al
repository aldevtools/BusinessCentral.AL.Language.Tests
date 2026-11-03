// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-testfield-method
// Scope: in-scope
// Fixtures used: table 71717 and codeunit 71718 (FieldRefTestFieldFixture.al), Probe Observer
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: FieldRef.TestField with a typed variable whose type does not match the field (Integer on a Text field, Text on an Integer field, Option on a Text field, Time on an Integer field, Label on an Integer field, Variant of another type); outcome, error text and code. Own file: compile-risky.
// BC versions: 29 (27 and 28 by CI)

codeunit 71725 "LT FRTF WrongType"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryInteger(Fld: FieldRef; Value: Integer)
    begin
        Fld.TestField(Value);
    end;

    [TryFunction]
    local procedure TryText(Fld: FieldRef; Value: Text)
    begin
        Fld.TestField(Value);
    end;

    [TryFunction]
    local procedure TryOption(Fld: FieldRef; Value: Option Alpha,Beta,Gamma)
    begin
        Fld.TestField(Value);
    end;

    [TryFunction]
    local procedure TryTime(Fld: FieldRef; Value: Time)
    begin
        Fld.TestField(Value);
    end;

    [TryFunction]
    local procedure TryVariant(Fld: FieldRef; Value: Variant)
    begin
        Fld.TestField(Value);
    end;

    local procedure Report(var Observer: Codeunit "Probe Observer"; Name: Text; Ok: Boolean)
    begin
        Observer.Observe(Name + '_ok', Format(Ok));
        Observer.Observe(Name + '_text', GetLastErrorText());
        Observer.Observe(Name + '_code', GetLastErrorCode());
        ClearLastError();
    end;

    [Test]
    procedure WrongType_IntegerAndTextVariables()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT FRTF Helper";
        RecRef: RecordRef;
    begin
        Helper.Seed();
        RecRef.Open(71717);
        RecRef.Field(1).SetRange('K1');
        RecRef.FindFirst();
        Report(Observer, 'int_on_text', TryInteger(RecRef.Field(2), 5));
        Report(Observer, 'int_on_code', TryInteger(RecRef.Field(6), 5));
        Report(Observer, 'int_on_time', TryInteger(RecRef.Field(5), 120000));
        Report(Observer, 'int_on_option_match', TryInteger(RecRef.Field(4), 1));
        Report(Observer, 'int_on_option_diff', TryInteger(RecRef.Field(4), 2));
        Report(Observer, 'text_on_int_numeric', TryText(RecRef.Field(3), '5'));
        Report(Observer, 'text_on_int_other', TryText(RecRef.Field(3), '6'));
        Report(Observer, 'text_on_int_nonnumeric', TryText(RecRef.Field(3), 'abc'));
        Report(Observer, 'text_on_option_member', TryText(RecRef.Field(4), 'Beta'));
        Report(Observer, 'text_on_option_other', TryText(RecRef.Field(4), 'Gamma'));
        Report(Observer, 'text_on_time', TryText(RecRef.Field(5), '12:00:00'));
        RecRef.Close();
        Observer.Expect('int_on_text_ok', 'No');
        Observer.Expect('int_on_text_text', 'The input string ''Hello'' was not in a correct format.');
        Observer.Expect('int_on_text_code', 'AL:Format');
        Observer.Expect('int_on_code_ok', 'No');
        Observer.Expect('int_on_code_text', 'The input string ''ABC'' was not in a correct format.');
        Observer.Expect('int_on_code_code', 'AL:Format');
        Observer.Expect('int_on_time_ok', 'No');
        Observer.Expect('int_on_time_text', 'Tm Cap must be equal to ''120000''  in FRTF Row Caption: Code Cap=K1. Current value is ''12:00:00 PM''.');
        Observer.Expect('int_on_time_code', 'TestField');
        Observer.Expect('int_on_option_match_ok', 'Yes');
        Observer.Expect('int_on_option_match_text', '');
        Observer.Expect('int_on_option_match_code', '');
        Observer.Expect('int_on_option_diff_ok', 'No');
        Observer.Expect('int_on_option_diff_text', 'Opt Cap must be equal to ''Gamma''  in FRTF Row Caption: Code Cap=K1. Current value is ''Beta''.');
        Observer.Expect('int_on_option_diff_code', 'TestField');
        Observer.Expect('text_on_int_numeric_ok', 'Yes');
        Observer.Expect('text_on_int_numeric_text', '');
        Observer.Expect('text_on_int_numeric_code', '');
        Observer.Expect('text_on_int_other_ok', 'No');
        Observer.Expect('text_on_int_other_text', 'Num Cap must be equal to ''6''  in FRTF Row Caption: Code Cap=K1. Current value is ''5''.');
        Observer.Expect('text_on_int_other_code', 'TestField');
        Observer.Expect('text_on_int_nonnumeric_ok', 'No');
        Observer.Expect('text_on_int_nonnumeric_text', 'The input string ''abc'' was not in a correct format.');
        Observer.Expect('text_on_int_nonnumeric_code', 'AL:Format');
        Observer.Expect('text_on_option_member_ok', 'No');
        Observer.Expect('text_on_option_member_text', 'Opt Cap must be equal to ''Beta''  in FRTF Row Caption: Code Cap=K1. Current value is ''Beta''.');
        Observer.Expect('text_on_option_member_code', 'TestField');
        Observer.Expect('text_on_option_other_ok', 'No');
        Observer.Expect('text_on_option_other_text', 'Opt Cap must be equal to ''Gamma''  in FRTF Row Caption: Code Cap=K1. Current value is ''Beta''.');
        Observer.Expect('text_on_option_other_code', 'TestField');
        Observer.Expect('text_on_time_ok', 'No');
        Observer.Expect('text_on_time_text', 'Tm Cap must be equal to ''12:00:00''  in FRTF Row Caption: Code Cap=K1. Current value is ''12:00:00 PM''.');
        Observer.Expect('text_on_time_code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure WrongType_OptionTimeVariantVariables()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT FRTF Helper";
        RecRef: RecordRef;
        V: Variant;
        D: Date;
    begin
        Helper.Seed();
        RecRef.Open(71717);
        RecRef.Field(1).SetRange('K1');
        RecRef.FindFirst();
        Report(Observer, 'option_on_text', TryOption(RecRef.Field(2), 1));
        Report(Observer, 'option_on_integer_match', TryOption(RecRef.Field(3), 5));
        Report(Observer, 'option_on_integer_diff', TryOption(RecRef.Field(3), 1));
        Report(Observer, 'time_on_integer', TryTime(RecRef.Field(3), 120000T));
        Report(Observer, 'time_on_text', TryTime(RecRef.Field(2), 120000T));
        V := 5;
        Report(Observer, 'variant_int_on_text', TryVariant(RecRef.Field(2), V));
        V := 'Hello';
        Report(Observer, 'variant_text_on_int', TryVariant(RecRef.Field(3), V));
        V := 120000T;
        Report(Observer, 'variant_time_on_text', TryVariant(RecRef.Field(2), V));
        V := D;
        Report(Observer, 'variant_date_on_time', TryVariant(RecRef.Field(5), V));
        RecRef.Close();
        Observer.Expect('option_on_text_ok', 'No');
        Observer.Expect('option_on_text_text', 'The input string ''Hello'' was not in a correct format.');
        Observer.Expect('option_on_text_code', 'AL:Format');
        Observer.Expect('option_on_integer_match_ok', 'Yes');
        Observer.Expect('option_on_integer_match_text', '');
        Observer.Expect('option_on_integer_match_code', '');
        Observer.Expect('option_on_integer_diff_ok', 'No');
        Observer.Expect('option_on_integer_diff_text', 'Num Cap must be equal to ''1''  in FRTF Row Caption: Code Cap=K1. Current value is ''5''.');
        Observer.Expect('option_on_integer_diff_code', 'TestField');
        Observer.Expect('time_on_integer_ok', 'No');
        Observer.Expect('time_on_integer_text', 'Num Cap must be equal to ''12:00:00 PM''  in FRTF Row Caption: Code Cap=K1. Current value is ''5''.');
        Observer.Expect('time_on_integer_code', 'TestField');
        Observer.Expect('time_on_text_ok', 'No');
        Observer.Expect('time_on_text_text', 'Txt Cap must be equal to ''12:00:00 PM''  in FRTF Row Caption: Code Cap=K1. Current value is ''Hello''.');
        Observer.Expect('time_on_text_code', 'TestField');
        Observer.Expect('variant_int_on_text_ok', 'No');
        Observer.Expect('variant_int_on_text_text', 'Txt Cap must be equal to ''5''  in FRTF Row Caption: Code Cap=K1. Current value is ''Hello''.');
        Observer.Expect('variant_int_on_text_code', 'TestField');
        Observer.Expect('variant_text_on_int_ok', 'No');
        Observer.Expect('variant_text_on_int_text', 'The input string ''Hello'' was not in a correct format.');
        Observer.Expect('variant_text_on_int_code', 'AL:Format');
        Observer.Expect('variant_time_on_text_ok', 'No');
        Observer.Expect('variant_time_on_text_text', 'Txt Cap must be equal to ''12:00:00 PM''  in FRTF Row Caption: Code Cap=K1. Current value is ''Hello''.');
        Observer.Expect('variant_time_on_text_code', 'TestField');
        Observer.Expect('variant_date_on_time_ok', 'No');
        Observer.Expect('variant_date_on_time_text', 'Tm Cap must be equal to ''''  in FRTF Row Caption: Code Cap=K1. Current value is ''12:00:00 PM''.');
        Observer.Expect('variant_date_on_time_code', 'TestField');
        Observer.Verify();
    end;
}
