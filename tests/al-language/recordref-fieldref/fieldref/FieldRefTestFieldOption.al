// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-testfield-method
// Scope: in-scope
// Fixtures used: table 71717 and codeunit 71718 (FieldRefTestFieldFixture.al), Probe Observer
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: FieldRef.TestField(Value: Option) and FieldRef.TestField(Value: Option, ErrorInfo) with a variable of exactly that type: equal value, different value, error text and code, whether ErrorInfo Message/Title/DetailedMessage reach the error
// BC versions: 29 (27 and 28 by CI)

codeunit 71722 "LT FRTF Option"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Option_Plain_EqualAndDifferent()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT FRTF Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Info: ErrorInfo;
        Val: Option Alpha,Beta,Gamma;
    begin
        Helper.Seed();
        RecRef.Open(71717);
        RecRef.Field(1).SetRange('K1');
        RecRef.FindFirst();
        Fld := RecRef.Field(4);
        Val := Val::Beta;
        Fld.TestField(Val);
        Observer.Observe('equal', 'no error');
        Val := Val::Gamma;
        asserterror Fld.TestField(Val);
        Observer.ObserveError('different');
        RecRef.Close();
        Observer.Expect('equal', 'no error');
        Observer.Expect('different|text', 'Opt Cap must be equal to ''Gamma''  in FRTF Row Caption: Code Cap=K1. Current value is ''Beta''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure Option_ErrorInfo_EqualAndDifferent()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT FRTF Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Info: ErrorInfo;
        Val: Option Alpha,Beta,Gamma;
    begin
        Helper.Seed();
        RecRef.Open(71717);
        RecRef.Field(1).SetRange('K1');
        RecRef.FindFirst();
        Fld := RecRef.Field(4);
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.DetailedMessage := 'info detail';
        Val := Val::Beta;
        Fld.TestField(Val, Info);
        Observer.Observe('equal', 'no error');
        Val := Val::Gamma;
        asserterror Fld.TestField(Val, Info);
        Observer.Observe('message_in_text', Format(StrPos(GetLastErrorText(), 'info message') > 0));
        Observer.Observe('title_in_text', Format(StrPos(GetLastErrorText(), 'info title') > 0));
        Observer.Observe('detail_in_text', Format(StrPos(GetLastErrorText(), 'info detail') > 0));
        Observer.ObserveError('different');
        Clear(Info);
        Val := Val::Gamma;
        asserterror Fld.TestField(Val, Info);
        Observer.ObserveError('different_empty_info');
        RecRef.Close();
        Observer.Expect('equal', 'no error');
        Observer.Expect('message_in_text', 'No');
        Observer.Expect('title_in_text', 'No');
        Observer.Expect('detail_in_text', 'No');
        Observer.Expect('different|text', 'Opt Cap must be equal to ''Gamma''  in FRTF Row Caption: Code Cap=K1. Current value is ''Beta''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Expect('different_empty_info|text', 'Opt Cap must be equal to ''Gamma''  in FRTF Row Caption: Code Cap=K1. Current value is ''Beta''.');
        Observer.Expect('different_empty_info|code', 'TestField');
        Observer.Verify();
    end;
}
