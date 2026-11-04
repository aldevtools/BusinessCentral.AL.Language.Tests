// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-testfield-method
// Scope: in-scope
// Fixtures used: TestFieldTypedFixture.al (table 70955 "LT TFT Rec", enum 70954 "LT TFT Kind")
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Record.TestField(Field, Value) called with a variable of exactly the named type, equal to the stored value (no error) and different (error text and code), and with an ErrorInfo (Message, Title, DetailedMessage set): are the texts in the error.
// Risky: TextConst variables may not compile in the cloud app (obsolete/OnPrem); own file.
// BC versions: 29 (27 and 28 by CI)

codeunit 70959 "LT TFT Rec TextConst"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P189_Rec_TextConst_Value()
    var
        Rec: Record "LT TFT Rec";
        V: TextConst ENU = 'Const value';
        D: TextConst ENU = 'Other const value';
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        Rec.Txt := V;
        Rec.TestField(Txt, V);
        Observer.Observe('equal_no_error', 'ok');
        asserterror Rec.TestField(Txt, D);
        Observer.ObserveError('different');
        Observer.Expect('equal_no_error', 'ok');
        Observer.Expect('different|text', 'Txt must be equal to ''Other const value''  in LT TFT Rec: Id=0. Current value is ''Const value''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure P189_Rec_TextConst_WithErrorInfo()
    var
        Rec: Record "LT TFT Rec";
        V: TextConst ENU = 'Const value';
        D: TextConst ENU = 'Other const value';
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
        Observer.Expect('different|text', 'Txt must be equal to ''Other const value''  in LT TFT Rec: Id=0. Current value is ''Const value''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;
}
