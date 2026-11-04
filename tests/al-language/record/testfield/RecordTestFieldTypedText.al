// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-testfield-method
// Scope: in-scope
// Fixtures used: TestFieldTypedFixture.al (table 70955 "LT TFT Rec", enum 70954 "LT TFT Kind")
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Record.TestField(Field, Value) called with a variable of exactly the named type, equal to the stored value (no error) and different (error text and code), and with an ErrorInfo (Message, Title, DetailedMessage set): are the texts in the error.
// BC versions: 29 (27 and 28 by CI)

codeunit 70957 "LT TFT Rec Text"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P189_Rec_Code_Value()
    var
        Rec: Record "LT TFT Rec";
        V: Code[20];
        D: Code[20];
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        V := 'ABC-1';
        Rec.Cod := V;
        D := 'ABC-2';
        Rec.TestField(Cod, V);
        Observer.Observe('equal_no_error', 'ok');
        asserterror Rec.TestField(Cod, D);
        Observer.ObserveError('different');
        Observer.Expect('equal_no_error', 'ok');
        Observer.Expect('different|text', 'Cod must be equal to ''ABC-2''  in LT TFT Rec: Id=0. Current value is ''ABC-1''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure P189_Rec_Code_WithErrorInfo()
    var
        Rec: Record "LT TFT Rec";
        V: Code[20];
        D: Code[20];
        Info: ErrorInfo;
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        V := 'ABC-1';
        Rec.Cod := V;
        D := 'ABC-2';
        Info.Message := 'TFT message';
        Info.Title := 'TFT title';
        Info.DetailedMessage := 'TFT detail';
        Rec.TestField(Cod, V, Info);
        Observer.Observe('equal_no_error', 'ok');
        asserterror Rec.TestField(Cod, D, Info);
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
    procedure P189_Rec_Text_Value()
    var
        Rec: Record "LT TFT Rec";
        V: Text;
        D: Text;
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        V := 'Text value';
        Rec.Txt := V;
        D := 'Other text value';
        Rec.TestField(Txt, V);
        Observer.Observe('equal_no_error', 'ok');
        asserterror Rec.TestField(Txt, D);
        Observer.ObserveError('different');
        Observer.Expect('equal_no_error', 'ok');
        Observer.Expect('different|text', 'Txt must be equal to ''Other text value''  in LT TFT Rec: Id=0. Current value is ''Text value''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure P189_Rec_Text_WithErrorInfo()
    var
        Rec: Record "LT TFT Rec";
        V: Text;
        D: Text;
        Info: ErrorInfo;
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        V := 'Text value';
        Rec.Txt := V;
        D := 'Other text value';
        Info.Message := 'TFT message';
        Info.Title := 'TFT title';
        Info.DetailedMessage := 'TFT detail';
        Rec.TestField(Txt, V, Info);
        Observer.Observe('equal_no_error', 'ok');
        asserterror Rec.TestField(Txt, D, Info);
        Observer.Observe('text_has_message', Format(GetLastErrorText().Contains('TFT message')));
        Observer.Observe('text_has_title', Format(GetLastErrorText().Contains('TFT title')));
        Observer.Observe('text_has_detail', Format(GetLastErrorText().Contains('TFT detail')));
        Observer.ObserveError('different');
        Observer.Expect('equal_no_error', 'ok');
        Observer.Expect('text_has_message', 'No');
        Observer.Expect('text_has_title', 'No');
        Observer.Expect('text_has_detail', 'No');
        Observer.Expect('different|text', 'Txt must be equal to ''Other text value''  in LT TFT Rec: Id=0. Current value is ''Text value''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure P189_Rec_Label_Value()
    var
        Rec: Record "LT TFT Rec";
        V: Label 'Label value';
        D: Label 'Other label value';
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        Rec.Txt := V;
        Rec.TestField(Txt, V);
        Observer.Observe('equal_no_error', 'ok');
        asserterror Rec.TestField(Txt, D);
        Observer.ObserveError('different');
        Observer.Expect('equal_no_error', 'ok');
        Observer.Expect('different|text', 'Txt must be equal to ''Other label value''  in LT TFT Rec: Id=0. Current value is ''Label value''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure P189_Rec_Label_WithErrorInfo()
    var
        Rec: Record "LT TFT Rec";
        V: Label 'Label value';
        D: Label 'Other label value';
        Info: ErrorInfo;
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        Rec.Txt := V;
        Info.Message := 'TFT message';
        Info.Title := 'TFT title';
        Info.DetailedMessage := 'TFT detail';
        Rec.TestField(Txt, V, Info);
        Observer.Observe('equal_no_error', 'ok');
        asserterror Rec.TestField(Txt, D, Info);
        Observer.Observe('text_has_message', Format(GetLastErrorText().Contains('TFT message')));
        Observer.Observe('text_has_title', Format(GetLastErrorText().Contains('TFT title')));
        Observer.Observe('text_has_detail', Format(GetLastErrorText().Contains('TFT detail')));
        Observer.ObserveError('different');
        Observer.Expect('equal_no_error', 'ok');
        Observer.Expect('text_has_message', 'No');
        Observer.Expect('text_has_title', 'No');
        Observer.Expect('text_has_detail', 'No');
        Observer.Expect('different|text', 'Txt must be equal to ''Other label value''  in LT TFT Rec: Id=0. Current value is ''Label value''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;
}
