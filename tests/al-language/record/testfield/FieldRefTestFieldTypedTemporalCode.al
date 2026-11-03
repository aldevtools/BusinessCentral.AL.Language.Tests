// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-testfield-method
// Scope: in-scope
// Fixtures used: TestFieldTypedFixture.al (table 70955 "LT TFT Rec", enum 70954 "LT TFT Kind")
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: FieldRef.TestField(Value) called with a variable of exactly the named type, equal to the stored value (no error) and different (error text and code), and with an ErrorInfo (Message, Title, DetailedMessage set): are the texts in the error.
// BC versions: 29 (27 and 28 by CI)

codeunit 70961 "LT TFT FRef Temporal"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P189_FldRef_Code_Value()
    var
        Rec: Record "LT TFT Rec";
        RecRef: RecordRef;
        Fld: FieldRef;
        V: Code[20];
        D: Code[20];
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        V := 'ABC-1';
        Rec.Cod := V;
        RecRef.GetTable(Rec);
        Fld := RecRef.Field(Rec.FieldNo(Cod));
        D := 'ABC-2';
        Fld.TestField(V);
        Observer.Observe('equal_no_error', 'ok');
        asserterror Fld.TestField(D);
        Observer.ObserveError('different');
        Observer.Expect('equal_no_error', 'ok');
        Observer.Expect('different|text', 'Cod must be equal to ''ABC-2''  in LT TFT Rec: Id=0. Current value is ''ABC-1''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure P189_FldRef_Code_WithErrorInfo()
    var
        Rec: Record "LT TFT Rec";
        RecRef: RecordRef;
        Fld: FieldRef;
        V: Code[20];
        D: Code[20];
        Info: ErrorInfo;
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        V := 'ABC-1';
        Rec.Cod := V;
        RecRef.GetTable(Rec);
        Fld := RecRef.Field(Rec.FieldNo(Cod));
        D := 'ABC-2';
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
        Observer.Expect('different|text', 'Cod must be equal to ''ABC-2''  in LT TFT Rec: Id=0. Current value is ''ABC-1''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure P189_FldRef_Date_Value()
    var
        Rec: Record "LT TFT Rec";
        RecRef: RecordRef;
        Fld: FieldRef;
        V: Date;
        D: Date;
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        V := 20240315D;
        Rec.Dt := V;
        RecRef.GetTable(Rec);
        Fld := RecRef.Field(Rec.FieldNo(Dt));
        D := 20240316D;
        Fld.TestField(V);
        Observer.Observe('equal_no_error', 'ok');
        asserterror Fld.TestField(D);
        Observer.ObserveError('different');
        Observer.Expect('equal_no_error', 'ok');
        Observer.Expect('different|text', 'Dt must be equal to ''03/16/24''  in LT TFT Rec: Id=0. Current value is ''03/15/24''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure P189_FldRef_Date_WithErrorInfo()
    var
        Rec: Record "LT TFT Rec";
        RecRef: RecordRef;
        Fld: FieldRef;
        V: Date;
        D: Date;
        Info: ErrorInfo;
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        V := 20240315D;
        Rec.Dt := V;
        RecRef.GetTable(Rec);
        Fld := RecRef.Field(Rec.FieldNo(Dt));
        D := 20240316D;
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
        Observer.Expect('different|text', 'Dt must be equal to ''03/16/24''  in LT TFT Rec: Id=0. Current value is ''03/15/24''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure P189_FldRef_DateTime_Value()
    var
        Rec: Record "LT TFT Rec";
        RecRef: RecordRef;
        Fld: FieldRef;
        V: DateTime;
        D: DateTime;
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        V := CreateDateTime(20240315D, 120000T);
        Rec.DtTm := V;
        RecRef.GetTable(Rec);
        Fld := RecRef.Field(Rec.FieldNo(DtTm));
        D := CreateDateTime(20240315D, 120001T);
        Fld.TestField(V);
        Observer.Observe('equal_no_error', 'ok');
        asserterror Fld.TestField(D);
        Observer.ObserveError('different');
        Observer.Expect('equal_no_error', 'ok');
        Observer.Expect('different|text', 'DtTm must be equal to ''03/15/24 12:00 PM''  in LT TFT Rec: Id=0. Current value is ''03/15/24 12:00 PM''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure P189_FldRef_DateTime_WithErrorInfo()
    var
        Rec: Record "LT TFT Rec";
        RecRef: RecordRef;
        Fld: FieldRef;
        V: DateTime;
        D: DateTime;
        Info: ErrorInfo;
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        V := CreateDateTime(20240315D, 120000T);
        Rec.DtTm := V;
        RecRef.GetTable(Rec);
        Fld := RecRef.Field(Rec.FieldNo(DtTm));
        D := CreateDateTime(20240315D, 120001T);
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
        Observer.Expect('different|text', 'DtTm must be equal to ''03/15/24 12:00 PM''  in LT TFT Rec: Id=0. Current value is ''03/15/24 12:00 PM''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;
}
