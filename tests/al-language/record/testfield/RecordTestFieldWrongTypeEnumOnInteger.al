// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-testfield-method
// Scope: in-scope
// Fixtures used: TestFieldTypedFixture.al (table 70955 "LT TFT Rec", enum 70954 "LT TFT Kind")
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Record.TestField with a variable of type Enum "LT TFT Kind" against a field of another type (Int): does it compile, the result and the error text and code, with and without ErrorInfo.
// Risky: the type mismatch may not compile; own file so only this file drops.
// BC versions: 29 (27 and 28 by CI)

codeunit 70967 "LT TFT Wrong Enum on Int"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryValueTf(var Rec: Record "LT TFT Rec"; V: Enum "LT TFT Kind")
    begin
        Rec.TestField(Int, V);
    end;

    [TryFunction]
    local procedure TryInfoTf(var Rec: Record "LT TFT Rec"; V: Enum "LT TFT Kind"; Info: ErrorInfo)
    begin
        Rec.TestField(Int, V, Info);
    end;

    [Test]
    procedure P189_RecWrongType_EnumOnInteger()
    var
        Rec: Record "LT TFT Rec";
        V: Enum "LT TFT Kind";
        D: Enum "LT TFT Kind";
        Info: ErrorInfo;
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        Rec.Int := 2;
        V := V::Two;
        D := D::One;
        Info.Message := 'TFT message';
        Info.Title := 'TFT title';
        Info.DetailedMessage := 'TFT detail';
        Observer.Observe('same_result', Format(TryValueTf(Rec, V)));
        Observer.ObserveError('same');
        Observer.Observe('different_result', Format(TryValueTf(Rec, D)));
        Observer.ObserveError('different');
        Observer.Observe('info_same_result', Format(TryInfoTf(Rec, V, Info)));
        Observer.ObserveError('info_same');
        Observer.Observe('info_different_result', Format(TryInfoTf(Rec, D, Info)));
        Observer.Observe('info_text_has_message', Format(GetLastErrorText().Contains('TFT message')));
        Observer.ObserveError('info_different');
        Observer.Expect('same_result', 'Yes');
        Observer.Expect('same|text', '');
        Observer.Expect('same|code', '');
        Observer.Expect('different_result', 'No');
        Observer.Expect('different|text', 'Int must be equal to ''One''  in LT TFT Rec: Id=0. Current value is ''2''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Expect('info_same_result', 'Yes');
        Observer.Expect('info_same|text', '');
        Observer.Expect('info_same|code', '');
        Observer.Expect('info_different_result', 'No');
        Observer.Expect('info_text_has_message', 'No');
        Observer.Expect('info_different|text', 'Int must be equal to ''One''  in LT TFT Rec: Id=0. Current value is ''2''.');
        Observer.Expect('info_different|code', 'TestField');
        Observer.Verify();
    end;
}
