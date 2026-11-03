// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-testfield-method
// Scope: in-scope
// Fixtures used: TestFieldTypedFixture.al (table 70955 "LT TFT Rec", enum 70954 "LT TFT Kind")
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Record.TestField(Field, Value) called with a variable of exactly the named type, equal to the stored value (no error) and different (error text and code), and with an ErrorInfo (Message, Title, DetailedMessage set): are the texts in the error.
// BC versions: 29 (27 and 28 by CI)

codeunit 70958 "LT TFT Rec Other"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P189_Rec_Boolean_Value()
    var
        Rec: Record "LT TFT Rec";
        V: Boolean;
        D: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        V := true;
        Rec.Bool := V;
        D := false;
        Rec.TestField(Bool, V);
        Observer.Observe('equal_no_error', 'ok');
        asserterror Rec.TestField(Bool, D);
        Observer.ObserveError('different');
        Observer.Expect('equal_no_error', 'ok');
        Observer.Expect('different|text', 'Bool must be equal to ''No''  in LT TFT Rec: Id=0. Current value is ''Yes''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure P189_Rec_Boolean_WithErrorInfo()
    var
        Rec: Record "LT TFT Rec";
        V: Boolean;
        D: Boolean;
        Info: ErrorInfo;
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        V := true;
        Rec.Bool := V;
        D := false;
        Info.Message := 'TFT message';
        Info.Title := 'TFT title';
        Info.DetailedMessage := 'TFT detail';
        Rec.TestField(Bool, V, Info);
        Observer.Observe('equal_no_error', 'ok');
        asserterror Rec.TestField(Bool, D, Info);
        Observer.Observe('text_has_message', Format(GetLastErrorText().Contains('TFT message')));
        Observer.Observe('text_has_title', Format(GetLastErrorText().Contains('TFT title')));
        Observer.Observe('text_has_detail', Format(GetLastErrorText().Contains('TFT detail')));
        Observer.ObserveError('different');
        Observer.Expect('equal_no_error', 'ok');
        Observer.Expect('text_has_message', 'No');
        Observer.Expect('text_has_title', 'No');
        Observer.Expect('text_has_detail', 'No');
        Observer.Expect('different|text', 'Bool must be equal to ''No''  in LT TFT Rec: Id=0. Current value is ''Yes''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure P189_Rec_Enum_Value()
    var
        Rec: Record "LT TFT Rec";
        V: Enum "LT TFT Kind";
        D: Enum "LT TFT Kind";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        V := V::Two;
        Rec.Knd := V;
        D := D::One;
        Rec.TestField(Knd, V);
        Observer.Observe('equal_no_error', 'ok');
        asserterror Rec.TestField(Knd, D);
        Observer.ObserveError('different');
        Observer.Expect('equal_no_error', 'ok');
        Observer.Expect('different|text', 'Knd must be equal to ''One''  in LT TFT Rec: Id=0. Current value is ''Two''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure P189_Rec_Enum_WithErrorInfo()
    var
        Rec: Record "LT TFT Rec";
        V: Enum "LT TFT Kind";
        D: Enum "LT TFT Kind";
        Info: ErrorInfo;
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        V := V::Two;
        Rec.Knd := V;
        D := D::One;
        Info.Message := 'TFT message';
        Info.Title := 'TFT title';
        Info.DetailedMessage := 'TFT detail';
        Rec.TestField(Knd, V, Info);
        Observer.Observe('equal_no_error', 'ok');
        asserterror Rec.TestField(Knd, D, Info);
        Observer.Observe('text_has_message', Format(GetLastErrorText().Contains('TFT message')));
        Observer.Observe('text_has_title', Format(GetLastErrorText().Contains('TFT title')));
        Observer.Observe('text_has_detail', Format(GetLastErrorText().Contains('TFT detail')));
        Observer.ObserveError('different');
        Observer.Expect('equal_no_error', 'ok');
        Observer.Expect('text_has_message', 'No');
        Observer.Expect('text_has_title', 'No');
        Observer.Expect('text_has_detail', 'No');
        Observer.Expect('different|text', 'Knd must be equal to ''One''  in LT TFT Rec: Id=0. Current value is ''Two''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;

#if BC28PLUS
    [Test]
    procedure P189_Rec_Guid_Value()
    var
        Rec: Record "LT TFT Rec";
        V: Guid;
        D: Guid;
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        Evaluate(V, '{11111111-2222-3333-4444-555555555555}');
        Rec.Gd := V;
        Evaluate(D, '{11111111-2222-3333-4444-555555555556}');
        Rec.TestField(Gd, V);
        Observer.Observe('equal_no_error', 'ok');
        asserterror Rec.TestField(Gd, D);
        Observer.ObserveError('different');
        Observer.Expect('equal_no_error', 'ok');
#if BC28PLUS
        Observer.Expect('different|text', 'Gd must be equal to ''{11111111-2222-3333-4444-555555555556}''  in LT TFT Rec: Id=0. Current value is ''{11111111-2222-3333-4444-555555555555}''.');
#else
        Observer.Expect('different|text', 'Gd must be equal to ''11111111-2222-3333-4444-555555555556''  in LT TFT Rec: Id=0. Current value is ''{11111111-2222-3333-4444-555555555555}''.');
#endif
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;
#endif

#if BC28PLUS
    [Test]
    procedure P189_Rec_Guid_WithErrorInfo()
    var
        Rec: Record "LT TFT Rec";
        V: Guid;
        D: Guid;
        Info: ErrorInfo;
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        Evaluate(V, '{11111111-2222-3333-4444-555555555555}');
        Rec.Gd := V;
        Evaluate(D, '{11111111-2222-3333-4444-555555555556}');
        Info.Message := 'TFT message';
        Info.Title := 'TFT title';
        Info.DetailedMessage := 'TFT detail';
        Rec.TestField(Gd, V, Info);
        Observer.Observe('equal_no_error', 'ok');
        asserterror Rec.TestField(Gd, D, Info);
        Observer.Observe('text_has_message', Format(GetLastErrorText().Contains('TFT message')));
        Observer.Observe('text_has_title', Format(GetLastErrorText().Contains('TFT title')));
        Observer.Observe('text_has_detail', Format(GetLastErrorText().Contains('TFT detail')));
        Observer.ObserveError('different');
        Observer.Expect('equal_no_error', 'ok');
        Observer.Expect('text_has_message', 'No');
        Observer.Expect('text_has_title', 'No');
        Observer.Expect('text_has_detail', 'No');
#if BC28PLUS
        Observer.Expect('different|text', 'Gd must be equal to ''{11111111-2222-3333-4444-555555555556}''  in LT TFT Rec: Id=0. Current value is ''{11111111-2222-3333-4444-555555555555}''.');
#else
        Observer.Expect('different|text', 'Gd must be equal to ''11111111-2222-3333-4444-555555555556''  in LT TFT Rec: Id=0. Current value is ''{11111111-2222-3333-4444-555555555555}''.');
#endif
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;
#endif
}
