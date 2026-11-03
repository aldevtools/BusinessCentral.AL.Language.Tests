// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-testfield-method
// Scope: in-scope
// Fixtures used: TestFieldTypedFixture.al (table 70955 "LT TFT Rec", enum 70954 "LT TFT Kind")
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Record.TestField with a variable of type Guid against a field of another type (Txt): does it compile, the result and the error text and code, with and without ErrorInfo.
// Risky: the type mismatch may not compile; own file so only this file drops.
// BC versions: 29 (27 and 28 by CI)
#if BC28PLUS

codeunit 70968 "LT TFT Wrong Guid on Text"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryValueTf(var Rec: Record "LT TFT Rec"; V: Guid)
    begin
        Rec.TestField(Txt, V);
    end;

    [TryFunction]
    local procedure TryInfoTf(var Rec: Record "LT TFT Rec"; V: Guid; Info: ErrorInfo)
    begin
        Rec.TestField(Txt, V, Info);
    end;

    [Test]
    procedure P189_RecWrongType_GuidOnText()
    var
        Rec: Record "LT TFT Rec";
        V: Guid;
        D: Guid;
        Info: ErrorInfo;
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        Rec.Txt := '{11111111-2222-3333-4444-555555555555}';
        Evaluate(V, '{11111111-2222-3333-4444-555555555555}');
        Evaluate(D, '{11111111-2222-3333-4444-555555555556}');
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
        Observer.Expect('same_result', 'No');
#if BC28PLUS
        Observer.Expect('same|text', 'Txt must be equal to ''{11111111-2222-3333-4444-555555555555}''  in LT TFT Rec: Id=0. Current value is ''{11111111-2222-3333-4444-555555555555}''.');
#else
        Observer.Expect('same|text', 'Txt must be equal to ''11111111-2222-3333-4444-555555555555''  in LT TFT Rec: Id=0. Current value is ''{11111111-2222-3333-4444-555555555555}''.');
#endif
        Observer.Expect('same|code', 'TestField');
        Observer.Expect('different_result', 'No');
#if BC28PLUS
        Observer.Expect('different|text', 'Txt must be equal to ''{11111111-2222-3333-4444-555555555556}''  in LT TFT Rec: Id=0. Current value is ''{11111111-2222-3333-4444-555555555555}''.');
#else
        Observer.Expect('different|text', 'Txt must be equal to ''11111111-2222-3333-4444-555555555556''  in LT TFT Rec: Id=0. Current value is ''{11111111-2222-3333-4444-555555555555}''.');
#endif
        Observer.Expect('different|code', 'TestField');
        Observer.Expect('info_same_result', 'No');
#if BC28PLUS
        Observer.Expect('info_same|text', 'Txt must be equal to ''{11111111-2222-3333-4444-555555555555}''  in LT TFT Rec: Id=0. Current value is ''{11111111-2222-3333-4444-555555555555}''.');
#else
        Observer.Expect('info_same|text', 'Txt must be equal to ''11111111-2222-3333-4444-555555555555''  in LT TFT Rec: Id=0. Current value is ''{11111111-2222-3333-4444-555555555555}''.');
#endif
        Observer.Expect('info_same|code', 'TestField');
        Observer.Expect('info_different_result', 'No');
        Observer.Expect('info_text_has_message', 'No');
#if BC28PLUS
        Observer.Expect('info_different|text', 'Txt must be equal to ''{11111111-2222-3333-4444-555555555556}''  in LT TFT Rec: Id=0. Current value is ''{11111111-2222-3333-4444-555555555555}''.');
#else
        Observer.Expect('info_different|text', 'Txt must be equal to ''11111111-2222-3333-4444-555555555556''  in LT TFT Rec: Id=0. Current value is ''{11111111-2222-3333-4444-555555555555}''.');
#endif
        Observer.Expect('info_different|code', 'TestField');
        Observer.Verify();
    end;
}
#endif
