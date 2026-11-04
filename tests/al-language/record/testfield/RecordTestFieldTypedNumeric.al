// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-testfield-method
// Scope: in-scope
// Fixtures used: TestFieldTypedFixture.al (table 70955 "LT TFT Rec", enum 70954 "LT TFT Kind")
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Record.TestField(Field, Value) called with a variable of exactly the named type, equal to the stored value (no error) and different (error text and code), and with an ErrorInfo (Message, Title, DetailedMessage set): are the texts in the error.
// BC versions: 29 (27 and 28 by CI)

codeunit 70956 "LT TFT Rec Numeric"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P189_Rec_BigInteger_Value()
    var
        Rec: Record "LT TFT Rec";
        V: BigInteger;
        D: BigInteger;
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        V := 2147483647;
        V := V * 2;
        Rec.Big := V;
        D := 2147483647;
        D := D * 2;
        D := D + 1;
        Rec.TestField(Big, V);
        Observer.Observe('equal_no_error', 'ok');
        asserterror Rec.TestField(Big, D);
        Observer.ObserveError('different');
        Observer.Expect('equal_no_error', 'ok');
        Observer.Expect('different|text', 'Big must be equal to ''4294967295''  in LT TFT Rec: Id=0. Current value is ''4294967294''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure P189_Rec_BigInteger_WithErrorInfo()
    var
        Rec: Record "LT TFT Rec";
        V: BigInteger;
        D: BigInteger;
        Info: ErrorInfo;
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        V := 2147483647;
        V := V * 2;
        Rec.Big := V;
        D := 2147483647;
        D := D * 2;
        D := D + 1;
        Info.Message := 'TFT message';
        Info.Title := 'TFT title';
        Info.DetailedMessage := 'TFT detail';
        Rec.TestField(Big, V, Info);
        Observer.Observe('equal_no_error', 'ok');
        asserterror Rec.TestField(Big, D, Info);
        Observer.Observe('text_has_message', Format(GetLastErrorText().Contains('TFT message')));
        Observer.Observe('text_has_title', Format(GetLastErrorText().Contains('TFT title')));
        Observer.Observe('text_has_detail', Format(GetLastErrorText().Contains('TFT detail')));
        Observer.ObserveError('different');
        Observer.Expect('equal_no_error', 'ok');
        Observer.Expect('text_has_message', 'No');
        Observer.Expect('text_has_title', 'No');
        Observer.Expect('text_has_detail', 'No');
        Observer.Expect('different|text', 'Big must be equal to ''4294967295''  in LT TFT Rec: Id=0. Current value is ''4294967294''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure P189_Rec_Decimal_Value()
    var
        Rec: Record "LT TFT Rec";
        V: Decimal;
        D: Decimal;
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        V := 12.345;
        Rec.Dec := V;
        D := 12.346;
        Rec.TestField(Dec, V);
        Observer.Observe('equal_no_error', 'ok');
        asserterror Rec.TestField(Dec, D);
        Observer.ObserveError('different');
        Observer.Expect('equal_no_error', 'ok');
        Observer.Expect('different|text', 'Dec must be equal to ''12.346''  in LT TFT Rec: Id=0. Current value is ''12.345''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure P189_Rec_Decimal_WithErrorInfo()
    var
        Rec: Record "LT TFT Rec";
        V: Decimal;
        D: Decimal;
        Info: ErrorInfo;
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        V := 12.345;
        Rec.Dec := V;
        D := 12.346;
        Info.Message := 'TFT message';
        Info.Title := 'TFT title';
        Info.DetailedMessage := 'TFT detail';
        Rec.TestField(Dec, V, Info);
        Observer.Observe('equal_no_error', 'ok');
        asserterror Rec.TestField(Dec, D, Info);
        Observer.Observe('text_has_message', Format(GetLastErrorText().Contains('TFT message')));
        Observer.Observe('text_has_title', Format(GetLastErrorText().Contains('TFT title')));
        Observer.Observe('text_has_detail', Format(GetLastErrorText().Contains('TFT detail')));
        Observer.ObserveError('different');
        Observer.Expect('equal_no_error', 'ok');
        Observer.Expect('text_has_message', 'No');
        Observer.Expect('text_has_title', 'No');
        Observer.Expect('text_has_detail', 'No');
        Observer.Expect('different|text', 'Dec must be equal to ''12.346''  in LT TFT Rec: Id=0. Current value is ''12.345''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure P189_Rec_Integer_Value()
    var
        Rec: Record "LT TFT Rec";
        V: Integer;
        D: Integer;
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        V := 42;
        Rec.Int := V;
        D := 43;
        Rec.TestField(Int, V);
        Observer.Observe('equal_no_error', 'ok');
        asserterror Rec.TestField(Int, D);
        Observer.ObserveError('different');
        Observer.Expect('equal_no_error', 'ok');
        Observer.Expect('different|text', 'Int must be equal to ''43''  in LT TFT Rec: Id=0. Current value is ''42''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure P189_Rec_Integer_WithErrorInfo()
    var
        Rec: Record "LT TFT Rec";
        V: Integer;
        D: Integer;
        Info: ErrorInfo;
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        V := 42;
        Rec.Int := V;
        D := 43;
        Info.Message := 'TFT message';
        Info.Title := 'TFT title';
        Info.DetailedMessage := 'TFT detail';
        Rec.TestField(Int, V, Info);
        Observer.Observe('equal_no_error', 'ok');
        asserterror Rec.TestField(Int, D, Info);
        Observer.Observe('text_has_message', Format(GetLastErrorText().Contains('TFT message')));
        Observer.Observe('text_has_title', Format(GetLastErrorText().Contains('TFT title')));
        Observer.Observe('text_has_detail', Format(GetLastErrorText().Contains('TFT detail')));
        Observer.ObserveError('different');
        Observer.Expect('equal_no_error', 'ok');
        Observer.Expect('text_has_message', 'No');
        Observer.Expect('text_has_title', 'No');
        Observer.Expect('text_has_detail', 'No');
        Observer.Expect('different|text', 'Int must be equal to ''43''  in LT TFT Rec: Id=0. Current value is ''42''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;
}
