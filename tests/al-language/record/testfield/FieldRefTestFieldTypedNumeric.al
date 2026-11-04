// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-testfield-method
// Scope: in-scope
// Fixtures used: TestFieldTypedFixture.al (table 70955 "LT TFT Rec", enum 70954 "LT TFT Kind")
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: FieldRef.TestField(Value) called with a variable of exactly the named type, equal to the stored value (no error) and different (error text and code), and with an ErrorInfo (Message, Title, DetailedMessage set): are the texts in the error.
// BC versions: 29 (27 and 28 by CI)

codeunit 70960 "LT TFT FRef Numeric"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P189_FldRef_BigInteger_Value()
    var
        Rec: Record "LT TFT Rec";
        RecRef: RecordRef;
        Fld: FieldRef;
        V: BigInteger;
        D: BigInteger;
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        V := 2147483647;
        V := V * 2;
        Rec.Big := V;
        RecRef.GetTable(Rec);
        Fld := RecRef.Field(Rec.FieldNo(Big));
        D := 2147483647;
        D := D * 2;
        D := D + 1;
        Fld.TestField(V);
        Observer.Observe('equal_no_error', 'ok');
        asserterror Fld.TestField(D);
        Observer.ObserveError('different');
        Observer.Expect('equal_no_error', 'ok');
        Observer.Expect('different|text', 'Big must be equal to ''4294967295''  in LT TFT Rec: Id=0. Current value is ''4294967294''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure P189_FldRef_BigInteger_WithErrorInfo()
    var
        Rec: Record "LT TFT Rec";
        RecRef: RecordRef;
        Fld: FieldRef;
        V: BigInteger;
        D: BigInteger;
        Info: ErrorInfo;
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        V := 2147483647;
        V := V * 2;
        Rec.Big := V;
        RecRef.GetTable(Rec);
        Fld := RecRef.Field(Rec.FieldNo(Big));
        D := 2147483647;
        D := D * 2;
        D := D + 1;
        Info.Message := 'TFT message';
        Info.Title := 'TFT title';
        Info.DetailedMessage := 'TFT detail';
        Fld.TestField(V, Info);
        Observer.Observe('equal_no_error', 'ok');
        asserterror Fld.TestField(D, Info);
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
    procedure P189_FldRef_Decimal_Value()
    var
        Rec: Record "LT TFT Rec";
        RecRef: RecordRef;
        Fld: FieldRef;
        V: Decimal;
        D: Decimal;
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        V := 12.345;
        Rec.Dec := V;
        RecRef.GetTable(Rec);
        Fld := RecRef.Field(Rec.FieldNo(Dec));
        D := 12.346;
        Fld.TestField(V);
        Observer.Observe('equal_no_error', 'ok');
        asserterror Fld.TestField(D);
        Observer.ObserveError('different');
        Observer.Expect('equal_no_error', 'ok');
        Observer.Expect('different|text', 'Dec must be equal to ''12.346''  in LT TFT Rec: Id=0. Current value is ''12.345''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure P189_FldRef_Decimal_WithErrorInfo()
    var
        Rec: Record "LT TFT Rec";
        RecRef: RecordRef;
        Fld: FieldRef;
        V: Decimal;
        D: Decimal;
        Info: ErrorInfo;
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        V := 12.345;
        Rec.Dec := V;
        RecRef.GetTable(Rec);
        Fld := RecRef.Field(Rec.FieldNo(Dec));
        D := 12.346;
        Info.Message := 'TFT message';
        Info.Title := 'TFT title';
        Info.DetailedMessage := 'TFT detail';
        Fld.TestField(V, Info);
        Observer.Observe('equal_no_error', 'ok');
        asserterror Fld.TestField(D, Info);
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

#if BC28PLUS
    [Test]
    procedure P189_FldRef_Byte_Value()
    var
        Rec: Record "LT TFT Rec";
        RecRef: RecordRef;
        Fld: FieldRef;
        V: Byte;
        D: Byte;
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        V := 7;
        Rec.Int := 7;
        RecRef.GetTable(Rec);
        Fld := RecRef.Field(Rec.FieldNo(Int));
        D := 8;
        Fld.TestField(V);
        Observer.Observe('equal_no_error', 'ok');
        asserterror Fld.TestField(D);
        Observer.ObserveError('different');
        Observer.Expect('equal_no_error', 'ok');
#if BC28PLUS
        Observer.Expect('different|text', 'Int must be equal to ''\u0008''  in LT TFT Rec: Id=0. Current value is ''7''.');
#else
        Observer.Expect('different|text', 'Int must be equal to ''8''  in LT TFT Rec: Id=0. Current value is ''7''.');
#endif
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;
#endif

#if BC28PLUS
    [Test]
    procedure P189_FldRef_Byte_WithErrorInfo()
    var
        Rec: Record "LT TFT Rec";
        RecRef: RecordRef;
        Fld: FieldRef;
        V: Byte;
        D: Byte;
        Info: ErrorInfo;
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        V := 7;
        Rec.Int := 7;
        RecRef.GetTable(Rec);
        Fld := RecRef.Field(Rec.FieldNo(Int));
        D := 8;
        Info.Message := 'TFT message';
        Info.Title := 'TFT title';
        Info.DetailedMessage := 'TFT detail';
        Fld.TestField(V, Info);
        Observer.Observe('equal_no_error', 'ok');
        asserterror Fld.TestField(D, Info);
        Observer.Observe('text_has_message', Format(GetLastErrorText().Contains('TFT message')));
        Observer.Observe('text_has_title', Format(GetLastErrorText().Contains('TFT title')));
        Observer.Observe('text_has_detail', Format(GetLastErrorText().Contains('TFT detail')));
        Observer.ObserveError('different');
        Observer.Expect('equal_no_error', 'ok');
        Observer.Expect('text_has_message', 'No');
        Observer.Expect('text_has_title', 'No');
        Observer.Expect('text_has_detail', 'No');
#if BC28PLUS
        Observer.Expect('different|text', 'Int must be equal to ''\u0008''  in LT TFT Rec: Id=0. Current value is ''7''.');
#else
        Observer.Expect('different|text', 'Int must be equal to ''8''  in LT TFT Rec: Id=0. Current value is ''7''.');
#endif
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;
#endif

    [Test]
    procedure P189_FldRef_Char_Value()
    var
        Rec: Record "LT TFT Rec";
        RecRef: RecordRef;
        Fld: FieldRef;
        V: Char;
        D: Char;
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        V := 65;
        Rec.Int := 65;
        RecRef.GetTable(Rec);
        Fld := RecRef.Field(Rec.FieldNo(Int));
        D := 66;
        Fld.TestField(V);
        Observer.Observe('equal_no_error', 'ok');
        asserterror Fld.TestField(D);
        Observer.ObserveError('different');
        Observer.Expect('equal_no_error', 'ok');
        Observer.Expect('different|text', 'Int must be equal to ''66''  in LT TFT Rec: Id=0. Current value is ''65''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure P189_FldRef_Char_WithErrorInfo()
    var
        Rec: Record "LT TFT Rec";
        RecRef: RecordRef;
        Fld: FieldRef;
        V: Char;
        D: Char;
        Info: ErrorInfo;
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        V := 65;
        Rec.Int := 65;
        RecRef.GetTable(Rec);
        Fld := RecRef.Field(Rec.FieldNo(Int));
        D := 66;
        Info.Message := 'TFT message';
        Info.Title := 'TFT title';
        Info.DetailedMessage := 'TFT detail';
        Fld.TestField(V, Info);
        Observer.Observe('equal_no_error', 'ok');
        asserterror Fld.TestField(D, Info);
        Observer.Observe('text_has_message', Format(GetLastErrorText().Contains('TFT message')));
        Observer.Observe('text_has_title', Format(GetLastErrorText().Contains('TFT title')));
        Observer.Observe('text_has_detail', Format(GetLastErrorText().Contains('TFT detail')));
        Observer.ObserveError('different');
        Observer.Expect('equal_no_error', 'ok');
        Observer.Expect('text_has_message', 'No');
        Observer.Expect('text_has_title', 'No');
        Observer.Expect('text_has_detail', 'No');
        Observer.Expect('different|text', 'Int must be equal to ''66''  in LT TFT Rec: Id=0. Current value is ''65''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;
}
