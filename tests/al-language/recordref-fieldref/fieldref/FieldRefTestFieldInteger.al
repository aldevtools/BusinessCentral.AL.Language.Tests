// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-testfield-method
// Scope: in-scope
// Fixtures used: table 71717 and codeunit 71718 (FieldRefTestFieldFixture.al), Probe Observer
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: FieldRef.TestField(Value: Integer) and FieldRef.TestField(Value: Integer, ErrorInfo) with a variable of exactly that type: equal value, different value, error text and code, whether ErrorInfo Message/Title/DetailedMessage reach the error
// BC versions: 29 (27 and 28 by CI)

codeunit 71719 "LT FRTF Integer"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Integer_Plain_EqualAndDifferent()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT FRTF Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Info: ErrorInfo;
        Val: Integer;
    begin
        Helper.Seed();
        RecRef.Open(71717);
        RecRef.Field(1).SetRange('K1');
        RecRef.FindFirst();
        Fld := RecRef.Field(3);
        Val := 5;
        Fld.TestField(Val);
        Observer.Observe('equal', 'no error');
        Val := 6;
        asserterror Fld.TestField(Val);
        Observer.ObserveError('different');
        RecRef.Close();
        Observer.Expect('equal', 'no error');
        Observer.Expect('different|text', 'Num Cap must be equal to ''6''  in FRTF Row Caption: Code Cap=K1. Current value is ''5''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure Integer_ErrorInfo_EqualAndDifferent()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT FRTF Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
        Info: ErrorInfo;
        Val: Integer;
    begin
        Helper.Seed();
        RecRef.Open(71717);
        RecRef.Field(1).SetRange('K1');
        RecRef.FindFirst();
        Fld := RecRef.Field(3);
        Info.Message := 'info message';
        Info.Title := 'info title';
        Info.DetailedMessage := 'info detail';
        Val := 5;
        Fld.TestField(Val, Info);
        Observer.Observe('equal', 'no error');
        Val := 6;
        asserterror Fld.TestField(Val, Info);
        Observer.Observe('message_in_text', Format(StrPos(GetLastErrorText(), 'info message') > 0));
        Observer.Observe('title_in_text', Format(StrPos(GetLastErrorText(), 'info title') > 0));
        Observer.Observe('detail_in_text', Format(StrPos(GetLastErrorText(), 'info detail') > 0));
        Observer.ObserveError('different');
        Clear(Info);
        Val := 6;
        asserterror Fld.TestField(Val, Info);
        Observer.ObserveError('different_empty_info');
        RecRef.Close();
        Observer.Expect('equal', 'no error');
        Observer.Expect('message_in_text', 'No');
        Observer.Expect('title_in_text', 'No');
        Observer.Expect('detail_in_text', 'No');
        Observer.Expect('different|text', 'Num Cap must be equal to ''6''  in FRTF Row Caption: Code Cap=K1. Current value is ''5''.');
        Observer.Expect('different|code', 'TestField');
        Observer.Expect('different_empty_info|text', 'Num Cap must be equal to ''6''  in FRTF Row Caption: Code Cap=K1. Current value is ''5''.');
        Observer.Expect('different_empty_info|code', 'TestField');
        Observer.Verify();
    end;
}
