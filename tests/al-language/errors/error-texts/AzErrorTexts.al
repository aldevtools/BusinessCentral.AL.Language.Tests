// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/errorinfo/errorinfo-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); objects 80600-80606 below (self-contained)
// Probe: corpus issue 652 (test handlers, dialogs and error texts), items 10, 14 and 15 (items 11 and 13 are pinned in errors/W5ErrorInfoUntouched.al and misc/lt-probes-needed-6/PnF23DecimalToIntegerParam.al), writer AZ.
// BC versions: 27, 28, 29

codeunit 80600 "LT AZ Throw Codeunit"
{
    trigger OnRun()
    begin
        Error('az thrown');
    end;
}

table 80601 "LT AZ Err Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 80602 "LT AZ Err Card"
{
    PageType = Card;
    SourceTable = "LT AZ Err Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DbError)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Row: Record "LT AZ Err Row";
                begin
                    Row.Get(-77);
                end;
            }
            action(DupInsert)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Row: Record "LT AZ Err Row";
                begin
                    Row.Id := Rec.Id;
                    Row.Insert();
                end;
            }
            action(TestFieldError)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.TestField(Name);
                end;
            }
            action(PlainError)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Error('az plain');
                end;
            }
        }
    }
}

enum 80605 "LT AZ Color"
{
    Extensible = false;
    value(0; Red) { }
    value(1; Green) { }
}

codeunit 80606 "LT AZ Error Texts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    // ---- item 10: Codeunit.Run of a codeunit id that does not exist; the raw text (the Observer would scrub the emit version) ----

    [Test]
    // Codeunit.Run does not trap this error (its return value is never assigned); the error names the test runner as the caller.
    procedure CodeunitRun_MissingId_RawText()
    var
        Ok: Boolean;
        Prefix: Text;
        Txt: Text;
        Number: Text;
    begin
        ClearLastError();
        Ok := true;
        asserterror Ok := Codeunit.Run(80748);
        if not Ok then
            Error('Codeunit.Run assigned its return value');
        // Same code on BC 27.5, 28.5 and 29.0.
        if GetLastErrorCode() <> 'AL:MetadataNotFound' then
            Error('expected code [AL:MetadataNotFound] but was [%1]', GetLastErrorCode());
        // The emit version number changes with every BC build (seen: 27025 on 27.5, 28015 on 28.5, 29022 on 29.0), so it is masked:
        // the rest of the text is exact and a number must be there.
        Prefix := 'You tried to invoke the CodeUnit object with the ID 80748 from the object Test Runner - Mgt. An object with that ID does not exist in the current application compiled with emit version ';
        Txt := GetLastErrorText();
        if (StrLen(Txt) <= StrLen(Prefix) + 1) or (CopyStr(Txt, 1, StrLen(Prefix)) <> Prefix) or (CopyStr(Txt, StrLen(Txt), 1) <> '.') then
            Error('expected [%1<number>.] but was [%2]', Prefix, Txt);
        Number := CopyStr(Txt, StrLen(Prefix) + 1, StrLen(Txt) - StrLen(Prefix) - 1);
        if DelChr(Number, '=', '0123456789') <> '' then
            Error('expected a number after "emit version " but was [%1]', Number);
    end;

    // ---- item 14: GetLastErrorCode after asserterror TestPage action Invoke ----

    [Test]
    procedure PageAction_ErrorCodes()
    var
        Row: Record "LT AZ Err Row";
        Card: TestPage "LT AZ Err Card";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Commit();
        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror Card.DbError.Invoke();
        Observer.ObserveError('get_missing');
        asserterror Card.TestFieldError.Invoke();
        Observer.ObserveError('testfield');
        asserterror Card.PlainError.Invoke();
        Observer.ObserveError('plain');
        Card.Close();
        Observer.Expect('get_missing|text', 'The LT AZ Err Row does not exist. Identification fields and values: Id=''-77''');
        Observer.Expect('get_missing|code', 'TestWrapped:CSideRecordNotFound');
        Observer.Expect('testfield|text', 'Name must have a value in LT AZ Err Row: Id=1. It cannot be zero or empty.');
        Observer.Expect('testfield|code', 'TestWrapped:TestField');
        Observer.Expect('plain|text', 'az plain');
        Observer.Expect('plain|code', 'TestWrapped:Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure PageAction_DuplicateInsert()
    var
        Row: Record "LT AZ Err Row";
        Card: TestPage "LT AZ Err Card";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Commit();
        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror Card.DupInsert.Invoke();
        Observer.ObserveError('dup');
        Observer.Expect('dup|text', 'The record in table LT AZ Err Row already exists. Identification fields and values: Id=''1''');
        Observer.Expect('dup|code', 'TestWrapped:CSideDuplicateKey');
        Observer.Verify();
    end;

    // ---- item 15: a Variant holding a non-text value passed to a by-value Text or Code parameter, languages 1036 and 1031 ----

    local procedure TakeText(Value: Text): Text
    begin
        exit('T[' + Value + ']');
    end;

    local procedure TakeCode(Value: Code[20]): Text
    begin
        exit('C[' + Value + ']');
    end;

    [TryFunction]
    local procedure TryText(V: Variant; var R: Text)
    begin
        R := TakeText(V);
    end;

    [TryFunction]
    local procedure TryCode(V: Variant; var R: Text)
    begin
        R := TakeCode(V);
    end;

    local procedure One(V: Variant; Name: Text)
    var
        R: Text;
    begin
        R := '-';
        Observer.Observe(Name + '_text_ok', Format(TryText(V, R)));
        Observer.Observe(Name + '_text_r', R);
        Observer.ObserveError(Name + '_text');
        R := '-';
        Observer.Observe(Name + '_code_ok', Format(TryCode(V, R)));
        Observer.Observe(Name + '_code_r', R);
        Observer.ObserveError(Name + '_code');
    end;

    local procedure ProbeVariants(Lang: Integer; Prefix: Text; Part: Integer)
    var
        Color: Enum "LT AZ Color";
        Opt: Option Alpha,Beta;
    begin
        GlobalLanguage(Lang);
        case Part of
            1:
                begin
                    One(12, Prefix + 'int');
                    One(1.25, Prefix + 'dec');
                end;
            2:
                begin
                    One(true, Prefix + 'bool');
                    One(DMY2Date(3, 4, 2024), Prefix + 'date');
                end;
            3:
                begin
                    Color := Color::Green;
                    One(Color, Prefix + 'enum');
                    Opt := Opt::Beta;
                    One(Opt, Prefix + 'opt');
                end;
        end;
        GlobalLanguage(1033);
    end;

    [Test]
    procedure VariantToText_Language1033_IntDec()
    begin
        ProbeVariants(1033, 'en_', 1);
        Observer.Expect('en_int_text_ok', 'No');
        Observer.Expect('en_int_text_r', '-');
        Observer.Expect('en_int_text|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('en_int_text|code', 'TypeConversion');
        Observer.Expect('en_int_code_ok', 'No');
        Observer.Expect('en_int_code_r', '-');
        Observer.Expect('en_int_code|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.');
        Observer.Expect('en_int_code|code', 'TypeConversion');
        Observer.Expect('en_dec_text_ok', 'No');
        Observer.Expect('en_dec_text_r', '-');
        Observer.Expect('en_dec_text|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('en_dec_text|code', 'TypeConversion');
        Observer.Expect('en_dec_code_ok', 'No');
        Observer.Expect('en_dec_code_r', '-');
        Observer.Expect('en_dec_code|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.');
        Observer.Expect('en_dec_code|code', 'TypeConversion');
        Observer.Verify();
    end;

    [Test]
    procedure VariantToText_Language1033_BoolDate()
    begin
        ProbeVariants(1033, 'en_', 2);
        Observer.Expect('en_bool_text_ok', 'No');
        Observer.Expect('en_bool_text_r', '-');
        Observer.Expect('en_bool_text|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('en_bool_text|code', 'TypeConversion');
        Observer.Expect('en_bool_code_ok', 'No');
        Observer.Expect('en_bool_code_r', '-');
        Observer.Expect('en_bool_code|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.');
        Observer.Expect('en_bool_code|code', 'TypeConversion');
        Observer.Expect('en_date_text_ok', 'No');
        Observer.Expect('en_date_text_r', '-');
        Observer.Expect('en_date_text|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('en_date_text|code', 'TypeConversion');
        Observer.Expect('en_date_code_ok', 'No');
        Observer.Expect('en_date_code_r', '-');
        Observer.Expect('en_date_code|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.');
        Observer.Expect('en_date_code|code', 'TypeConversion');
        Observer.Verify();
    end;

    [Test]
    procedure VariantToText_Language1033_EnumOption()
    begin
        ProbeVariants(1033, 'en_', 3);
        Observer.Expect('en_enum_text_ok', 'No');
        Observer.Expect('en_enum_text_r', '-');
        Observer.Expect('en_enum_text|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('en_enum_text|code', 'TypeConversion');
        Observer.Expect('en_enum_code_ok', 'No');
        Observer.Expect('en_enum_code_r', '-');
        Observer.Expect('en_enum_code|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.');
        Observer.Expect('en_enum_code|code', 'TypeConversion');
        Observer.Expect('en_opt_text_ok', 'No');
        Observer.Expect('en_opt_text_r', '-');
        Observer.Expect('en_opt_text|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('en_opt_text|code', 'TypeConversion');
        Observer.Expect('en_opt_code_ok', 'No');
        Observer.Expect('en_opt_code_r', '-');
        Observer.Expect('en_opt_code|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.');
        Observer.Expect('en_opt_code|code', 'TypeConversion');
        Observer.Verify();
    end;

    [Test]
    procedure VariantToText_Language1036_IntDec()
    begin
        ProbeVariants(1036, 'fr_', 1);
        Observer.Expect('fr_int_text_ok', 'Non');
        Observer.Expect('fr_int_text_r', '-');
        Observer.Expect('fr_int_text|text', 'L''expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue ne peut pas être convertie vers une valeur de type Microsoft.Dynamics.Nav.Runtime.NavText.');
        Observer.Expect('fr_int_text|code', 'TypeConversion');
        Observer.Expect('fr_int_code_ok', 'Non');
        Observer.Expect('fr_int_code_r', '-');
        Observer.Expect('fr_int_code|text', 'L''expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue ne peut pas être convertie vers une valeur de type Microsoft.Dynamics.Nav.Runtime.NavCode.');
        Observer.Expect('fr_int_code|code', 'TypeConversion');
        Observer.Expect('fr_dec_text_ok', 'Non');
        Observer.Expect('fr_dec_text_r', '-');
        Observer.Expect('fr_dec_text|text', 'L''expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue ne peut pas être convertie vers une valeur de type Microsoft.Dynamics.Nav.Runtime.NavText.');
        Observer.Expect('fr_dec_text|code', 'TypeConversion');
        Observer.Expect('fr_dec_code_ok', 'Non');
        Observer.Expect('fr_dec_code_r', '-');
        Observer.Expect('fr_dec_code|text', 'L''expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue ne peut pas être convertie vers une valeur de type Microsoft.Dynamics.Nav.Runtime.NavCode.');
        Observer.Expect('fr_dec_code|code', 'TypeConversion');
        Observer.Verify();
    end;

    [Test]
    procedure VariantToText_Language1036_BoolDate()
    begin
        ProbeVariants(1036, 'fr_', 2);
        Observer.Expect('fr_bool_text_ok', 'Non');
        Observer.Expect('fr_bool_text_r', '-');
        Observer.Expect('fr_bool_text|text', 'L''expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue ne peut pas être convertie vers une valeur de type Microsoft.Dynamics.Nav.Runtime.NavText.');
        Observer.Expect('fr_bool_text|code', 'TypeConversion');
        Observer.Expect('fr_bool_code_ok', 'Non');
        Observer.Expect('fr_bool_code_r', '-');
        Observer.Expect('fr_bool_code|text', 'L''expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue ne peut pas être convertie vers une valeur de type Microsoft.Dynamics.Nav.Runtime.NavCode.');
        Observer.Expect('fr_bool_code|code', 'TypeConversion');
        Observer.Expect('fr_date_text_ok', 'Non');
        Observer.Expect('fr_date_text_r', '-');
        Observer.Expect('fr_date_text|text', 'L''expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue ne peut pas être convertie vers une valeur de type Microsoft.Dynamics.Nav.Runtime.NavText.');
        Observer.Expect('fr_date_text|code', 'TypeConversion');
        Observer.Expect('fr_date_code_ok', 'Non');
        Observer.Expect('fr_date_code_r', '-');
        Observer.Expect('fr_date_code|text', 'L''expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue ne peut pas être convertie vers une valeur de type Microsoft.Dynamics.Nav.Runtime.NavCode.');
        Observer.Expect('fr_date_code|code', 'TypeConversion');
        Observer.Verify();
    end;

    [Test]
    procedure VariantToText_Language1036_EnumOption()
    begin
        ProbeVariants(1036, 'fr_', 3);
        Observer.Expect('fr_enum_text_ok', 'Non');
        Observer.Expect('fr_enum_text_r', '-');
        Observer.Expect('fr_enum_text|text', 'L''expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue ne peut pas être convertie vers une valeur de type Microsoft.Dynamics.Nav.Runtime.NavText.');
        Observer.Expect('fr_enum_text|code', 'TypeConversion');
        Observer.Expect('fr_enum_code_ok', 'Non');
        Observer.Expect('fr_enum_code_r', '-');
        Observer.Expect('fr_enum_code|text', 'L''expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue ne peut pas être convertie vers une valeur de type Microsoft.Dynamics.Nav.Runtime.NavCode.');
        Observer.Expect('fr_enum_code|code', 'TypeConversion');
        Observer.Expect('fr_opt_text_ok', 'Non');
        Observer.Expect('fr_opt_text_r', '-');
        Observer.Expect('fr_opt_text|text', 'L''expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue ne peut pas être convertie vers une valeur de type Microsoft.Dynamics.Nav.Runtime.NavText.');
        Observer.Expect('fr_opt_text|code', 'TypeConversion');
        Observer.Expect('fr_opt_code_ok', 'Non');
        Observer.Expect('fr_opt_code_r', '-');
        Observer.Expect('fr_opt_code|text', 'L''expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue ne peut pas être convertie vers une valeur de type Microsoft.Dynamics.Nav.Runtime.NavCode.');
        Observer.Expect('fr_opt_code|code', 'TypeConversion');
        Observer.Verify();
    end;

    [Test]
    procedure VariantToText_Language1031_IntDec()
    begin
        ProbeVariants(1031, 'de_', 1);
        Observer.Expect('de_int_text_ok', 'Nein');
        Observer.Expect('de_int_text_r', '-');
        Observer.Expect('de_int_text|text', 'Der Ausdruck Microsoft.Dynamics.Nav.Runtime.NavIndirectValue kann nicht in einen Microsoft.Dynamics.Nav.Runtime.NavText-Wert typkonvertiert werden.');
        Observer.Expect('de_int_text|code', 'TypeConversion');
        Observer.Expect('de_int_code_ok', 'Nein');
        Observer.Expect('de_int_code_r', '-');
        Observer.Expect('de_int_code|text', 'Der Ausdruck Microsoft.Dynamics.Nav.Runtime.NavIndirectValue kann nicht in einen Microsoft.Dynamics.Nav.Runtime.NavCode-Wert typkonvertiert werden.');
        Observer.Expect('de_int_code|code', 'TypeConversion');
        Observer.Expect('de_dec_text_ok', 'Nein');
        Observer.Expect('de_dec_text_r', '-');
        Observer.Expect('de_dec_text|text', 'Der Ausdruck Microsoft.Dynamics.Nav.Runtime.NavIndirectValue kann nicht in einen Microsoft.Dynamics.Nav.Runtime.NavText-Wert typkonvertiert werden.');
        Observer.Expect('de_dec_text|code', 'TypeConversion');
        Observer.Expect('de_dec_code_ok', 'Nein');
        Observer.Expect('de_dec_code_r', '-');
        Observer.Expect('de_dec_code|text', 'Der Ausdruck Microsoft.Dynamics.Nav.Runtime.NavIndirectValue kann nicht in einen Microsoft.Dynamics.Nav.Runtime.NavCode-Wert typkonvertiert werden.');
        Observer.Expect('de_dec_code|code', 'TypeConversion');
        Observer.Verify();
    end;

    [Test]
    procedure VariantToText_Language1031_BoolDate()
    begin
        ProbeVariants(1031, 'de_', 2);
        Observer.Expect('de_bool_text_ok', 'Nein');
        Observer.Expect('de_bool_text_r', '-');
        Observer.Expect('de_bool_text|text', 'Der Ausdruck Microsoft.Dynamics.Nav.Runtime.NavIndirectValue kann nicht in einen Microsoft.Dynamics.Nav.Runtime.NavText-Wert typkonvertiert werden.');
        Observer.Expect('de_bool_text|code', 'TypeConversion');
        Observer.Expect('de_bool_code_ok', 'Nein');
        Observer.Expect('de_bool_code_r', '-');
        Observer.Expect('de_bool_code|text', 'Der Ausdruck Microsoft.Dynamics.Nav.Runtime.NavIndirectValue kann nicht in einen Microsoft.Dynamics.Nav.Runtime.NavCode-Wert typkonvertiert werden.');
        Observer.Expect('de_bool_code|code', 'TypeConversion');
        Observer.Expect('de_date_text_ok', 'Nein');
        Observer.Expect('de_date_text_r', '-');
        Observer.Expect('de_date_text|text', 'Der Ausdruck Microsoft.Dynamics.Nav.Runtime.NavIndirectValue kann nicht in einen Microsoft.Dynamics.Nav.Runtime.NavText-Wert typkonvertiert werden.');
        Observer.Expect('de_date_text|code', 'TypeConversion');
        Observer.Expect('de_date_code_ok', 'Nein');
        Observer.Expect('de_date_code_r', '-');
        Observer.Expect('de_date_code|text', 'Der Ausdruck Microsoft.Dynamics.Nav.Runtime.NavIndirectValue kann nicht in einen Microsoft.Dynamics.Nav.Runtime.NavCode-Wert typkonvertiert werden.');
        Observer.Expect('de_date_code|code', 'TypeConversion');
        Observer.Verify();
    end;

    [Test]
    procedure VariantToText_Language1031_EnumOption()
    begin
        ProbeVariants(1031, 'de_', 3);
        Observer.Expect('de_enum_text_ok', 'Nein');
        Observer.Expect('de_enum_text_r', '-');
        Observer.Expect('de_enum_text|text', 'Der Ausdruck Microsoft.Dynamics.Nav.Runtime.NavIndirectValue kann nicht in einen Microsoft.Dynamics.Nav.Runtime.NavText-Wert typkonvertiert werden.');
        Observer.Expect('de_enum_text|code', 'TypeConversion');
        Observer.Expect('de_enum_code_ok', 'Nein');
        Observer.Expect('de_enum_code_r', '-');
        Observer.Expect('de_enum_code|text', 'Der Ausdruck Microsoft.Dynamics.Nav.Runtime.NavIndirectValue kann nicht in einen Microsoft.Dynamics.Nav.Runtime.NavCode-Wert typkonvertiert werden.');
        Observer.Expect('de_enum_code|code', 'TypeConversion');
        Observer.Expect('de_opt_text_ok', 'Nein');
        Observer.Expect('de_opt_text_r', '-');
        Observer.Expect('de_opt_text|text', 'Der Ausdruck Microsoft.Dynamics.Nav.Runtime.NavIndirectValue kann nicht in einen Microsoft.Dynamics.Nav.Runtime.NavText-Wert typkonvertiert werden.');
        Observer.Expect('de_opt_text|code', 'TypeConversion');
        Observer.Expect('de_opt_code_ok', 'Nein');
        Observer.Expect('de_opt_code_r', '-');
        Observer.Expect('de_opt_code|text', 'Der Ausdruck Microsoft.Dynamics.Nav.Runtime.NavIndirectValue kann nicht in einen Microsoft.Dynamics.Nav.Runtime.NavCode-Wert typkonvertiert werden.');
        Observer.Expect('de_opt_code|code', 'TypeConversion');
        Observer.Verify();
    end;

    // ---- writer PY-D (2026-10-20): action error codes for other errors, and the missing-object caller ----

    [Test]
    procedure PYD_PageAction_OtherErrorCodes_1()
    var
        Row: Record "LT PYD Act Row";
        Card: TestPage "LT PYD Act Card";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Uniq := 7;
        Row.Insert();
        Commit();
        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror Card.ValidateRelation.Invoke();
        Observer.ObserveError('relation');
        asserterror Card.ValidateTrigger.Invoke();
        Observer.ObserveError('onvalidate');
        asserterror Card.FieldErr.Invoke();
        Observer.ObserveError('fielderror');
        Card.Close();
        Observer.Expect('relation|text', 'The field Ref of table LT PYD Act Row contains a value (999) that cannot be found in the related table (LT PYD Act Row).');
        Observer.Expect('relation|code', 'TestWrapped:CSideValidateTableRelation');
        Observer.Expect('onvalidate|text', 'pyd validate');
        Observer.Expect('onvalidate|code', 'TestWrapped:Dialog');
        Observer.Expect('fielderror|text', 'You must specify Name in LT PYD Act Row Id=''1''.');
        Observer.Expect('fielderror|code', 'TestWrapped:CSide');
        Observer.Verify();
    end;

    [Test]
    procedure PYD_PageAction_OtherErrorCodes_2()
    var
        Row: Record "LT PYD Act Row";
        Card: TestPage "LT PYD Act Card";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Uniq := 7;
        Row.Insert();
        Commit();
        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror Card.UniqueDup.Invoke();
        Observer.ObserveError('unique');
        Observer.Observe('rows', Format(Row.Count()));
        Card.Close();
        Observer.Expect('unique|text', 'There is already a record in table LT PYD Act Row that has the same values in a unique index for the following fields: Uniq=''7''');
        Observer.Expect('unique|code', 'TestWrapped:CSideDuplicateKey');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    procedure PYD_PageAction_OtherErrorCodes_3()
    var
        Row: Record "LT PYD Act Row";
        Card: TestPage "LT PYD Act Card";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Commit();
        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror Card.DivZero.Invoke();
        Observer.ObserveError('divzero');
        asserterror Card.DecDivZero.Invoke();
        Observer.ObserveError('decdivzero');
        asserterror Card.StrLen.Invoke();
        Observer.ObserveError('strlen');
        asserterror Card.ModifyMissing.Invoke();
        Observer.ObserveError('modify_missing');
        Card.Close();
        Observer.Expect('divzero|text', 'Attempted to divide by zero.');
        Observer.Expect('divzero|code', 'TestWrapped:AL');
        Observer.Expect('decdivzero|text', 'Attempted to divide by zero.');
        Observer.Expect('decdivzero|code', 'TestWrapped:AL');
        Observer.Expect('strlen|text', 'The length of the string is 16, but it must be less than or equal to 5 characters. Value: longer than five');
        Observer.Expect('strlen|code', 'TestWrapped:StringLengthExceeded');
        Observer.Expect('modify_missing|text', 'The LT PYD Act Row does not exist. Identification fields and values: Id=''555''');
        Observer.Expect('modify_missing|code', 'TestWrapped:CSideRecordNotFound');
        Observer.Verify();
    end;

    local procedure PydRunMissingCodeunit()
    begin
        Codeunit.Run(80748);
    end;

    [Test]
    procedure PYD_MissingCodeunit_FromLocalProcedure()
    begin
        asserterror PydRunMissingCodeunit();
        Observer.ObserveError('local');
        Observer.Expect('local|text', 'You tried to invoke the CodeUnit object with the ID 80748 from the object LT AZ Error Texts. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('local|code', 'AL:MetadataNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure PYD_MissingReport_OutsideTry()
    begin
        asserterror Report.Run(80748);
        Observer.ObserveError('report');
        Observer.Expect('report|text', 'You tried to invoke the Report object with the ID 80748 from the object Test Runner - Mgt. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('report|code', 'AL:MetadataNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure PYD_MissingXmlPort_OutsideTry()
    begin
        asserterror XmlPort.Run(80748);
        Observer.ObserveError('xmlport');
        Observer.Expect('xmlport|text', 'You tried to invoke the XmlPort object with the ID 80748 from the object Test Runner - Mgt. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('xmlport|code', 'AL:MetadataNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure PYD_MissingPage_OutsideTry()
    begin
        asserterror Page.Run(80748);
        Observer.ObserveError('page');
        Observer.Expect('page|text', 'You tried to invoke the Page object with the ID 80748 from the object Test Runner - Mgt. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('page|code', 'AL:MetadataNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure PYD_MissingCodeunit_TwoHelpersDeep()
    var
        Outer: Codeunit "LT PYD Missing Outer";
    begin
        asserterror Outer.ViaHelper();
        Observer.ObserveError('two_deep');
        Observer.Expect('two_deep|text', 'You tried to invoke the CodeUnit object with the ID 80748 from the object LT PYD Missing Outer. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('two_deep|code', 'AL:MetadataNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure PYD_MissingCodeunit_InOnRunOfRunCodeunit()
    begin
        asserterror Codeunit.Run(Codeunit::"LT PYD Missing Outer");
        Observer.ObserveError('onrun');
        Observer.Expect('onrun|text', 'You tried to invoke the CodeUnit object with the ID 80748 from the object LT AZ Error Texts. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('onrun|code', 'AL:MetadataNotFound');
        Observer.Verify();
    end;
}

// Writer PY-D (2026-10-20): objects 85227-85229 for the action error codes and the missing-object caller probes below.
table 85227 "LT PYD Act Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Ref; Integer) { TableRelation = "LT PYD Act Row".Id; }
        field(3; Name; Text[20])
        {
            trigger OnValidate()
            begin
                Error('pyd validate');
            end;
        }
        field(4; Uniq; Integer) { }
        field(5; Short; Code[5]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(UQ; Uniq) { Unique = true; }
    }
}

page 85228 "LT PYD Act Card"
{
    PageType = Card;
    SourceTable = "LT PYD Act Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Ref; Rec.Ref) { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ValidateRelation)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.Validate(Ref, 999);
                end;
            }
            action(ValidateTrigger)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.Validate(Name, 'x');
                end;
            }
            action(FieldErr)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.FieldError(Name);
                end;
            }
            action(UniqueDup)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Row: Record "LT PYD Act Row";
                begin
                    Row.Id := 2;
                    Row.Uniq := 7;
                    Row.Insert();
                end;
            }
            action(DivZero)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    I: Integer;
                    Zero: Integer;
                begin
                    I := 1 div Zero;
                    Rec.Ref := I;
                end;
            }
            action(DecDivZero)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    D: Decimal;
                    Zero: Decimal;
                begin
                    D := 1 / Zero;
                    Rec.Ref := D;
                end;
            }
            action(StrLen)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    T: Text;
                begin
                    T := 'longer than five';
                    Rec.Short := T;
                end;
            }
            action(ModifyMissing)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Row: Record "LT PYD Act Row";
                begin
                    Row.Id := 555;
                    Row.Modify();
                end;
            }
        }
    }
}

codeunit 85229 "LT PYD Missing Outer"
{
    trigger OnRun()
    begin
        Codeunit.Run(80748);
    end;

    procedure ViaHelper()
    var
        Caller: Codeunit "W5 Missing Caller";
    begin
        Caller.RunMissingCodeunit(80748);
    end;
}
